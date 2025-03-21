
--+-------------------------+
--| PGPG Fixed-Point Sub    |
--|      by Tsuyoshi Hamada |
--+-------------------------+
library ieee;
use ieee.std_logic_1164.all;

entity pg_fix_sub_32_2 is
  port(x,y : in std_logic_vector(31 downto 0);
       z : out std_logic_vector(31 downto 0);
       clk : in std_logic);
end pg_fix_sub_32_2;
architecture rtl of pg_fix_sub_32_2 is
  component pg_adder_RCA_SUB_32_2
    port (x,y: in std_logic_vector(31 downto 0);
          z:  out std_logic_vector(31 downto 0);
          clk: in std_logic);
  end component;
begin
  u0: pg_adder_RCA_SUB_32_2
      port map(x=>x,y=>y,z=>z,clk=>clk);
end rtl;

--+--------------------------------+
--| PGPG Ripple-Carry Adder        |
--|  2004/02/12 for Xilinx Devices |
--|      by Tsuyoshi Hamada        |
--+--------------------------------+
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pg_adder_RCA_SUB_32_2 is
  port(x,y : in std_logic_vector(31 downto 0);
       z : out std_logic_vector(31 downto 0);
       clk : in std_logic);
end pg_adder_RCA_SUB_32_2;

architecture rtl of pg_adder_RCA_SUB_32_2 is

  --                             
  --  <-MSB               LSB->  
  --  x1_1| |y1_0   x0_0| |y0_0  
  --      | |       +---ADD(FF)  
  --     FF FF     FF    |z0_0   
  --  x1_1| |y1_1   |    |       
  --      ADD(FF)---+    FF      
  --       |z1_1         |z0_1   
  --                             
  signal x0_0      : std_logic_vector(15 downto 0);
  signal y0_0      : std_logic_vector(15 downto 0);
  signal z0_0,z0_1 : std_logic_vector(16 downto 0);
  signal x1_0,x1_1 : std_logic_vector(15 downto 0);
  signal y1_0,y1_1 : std_logic_vector(15 downto 0);
  signal      z1_1 : std_logic_vector(15 downto 0);
begin
  x0_0<=x(15 downto 0);
  y0_0<=y(15 downto 0);
  x1_0<=x(31 downto 16);
  y1_0<=y(31 downto 16);
  process(clk) begin
    if(clk'event and clk='1') then
      x1_1 <= x1_0;
      y1_1 <= y1_0;
    end if;
  end process;
  process(clk) begin
    if(clk'event and clk='1') then
      z0_1 <= z0_0;
    end if;
  end process;
  z0_0 <= ('0'&x0_0) - ('0'&y0_0);
  z1_1 <= x1_1 - y1_1 - ("000000000000000"&z0_1(16));

  process(clk) begin
    if(clk'event and clk='1') then
      z(15 downto 0)  <= z0_1(15 downto 0);
      z(31 downto 16) <= z1_1;
    end if;
  end process;
end rtl;
-- *************************************************************** 
-- * PGPG FIXED-POINT TO LOGARITHMIC FORMAT CONVERTER            * 
-- *  For Xilinx Devices                                         * 
-- *  AUTHOR: Tsuyoshi Hamada                                    * 
-- *  VERSION: 2.01                                              * 
-- *  LAST MODIFIED AT Fri Feb 06 20:04:00 JST 2004              * 
-- *************************************************************** 
library ieee;                                                      
use ieee.std_logic_1164.all;                                       
                                                                   
entity pg_conv_ftol_32_17_8_4 is         
  port(fixdata : in std_logic_vector(31 downto 0);      
       logdata : out std_logic_vector(16 downto 0);     
       clk : in std_logic);                                        
end pg_conv_ftol_32_17_8_4;              
                                                                   
architecture rtl of pg_conv_ftol_32_17_8_4 is 
                                                                   
  component table                                                  
  generic (IN_WIDTH: integer ;                                     
           OUT_WIDTH: integer ;                                    
           TABLE_FILE: string);                                    
  port(indata : in std_logic_vector(IN_WIDTH-1 downto 0);          
      outdata : out std_logic_vector(OUT_WIDTH-1 downto 0);        
      clk : in std_logic);                                         
  end component;                                                   

  component unreg_add_sub
    generic (WIDTH: integer;
             DIRECTION: string);
    port (dataa,datab: in std_logic_vector(WIDTH-1 downto 0);
          result: out std_logic_vector(WIDTH-1 downto 0));
  end component;

  component penc_31_5                        
    port( a : in std_logic_vector(30 downto 0);        
          c : out std_logic_vector(4 downto 0));      
  end component;                                                   
                                                                   
  component unreg_shift_ftol_30_10
    port( indata : in std_logic_vector(29 downto 0);   
          control : in std_logic_vector(4 downto 0);  
          outdata : out std_logic_vector(9 downto 0));
  end component;

  signal d1,d0: std_logic_vector(30 downto 0);         
  signal d2: std_logic_vector(30 downto 0);            
  signal d3,d3r: std_logic_vector(30 downto 0);        
  signal one: std_logic_vector(30 downto 0);           
  signal sign: std_logic;                                          
  signal c1: std_logic_vector(4 downto 0);            
  signal d4: std_logic_vector(29 downto 0);            
  signal c2,c3,c4,add: std_logic_vector(4 downto 0);  
  signal d5,d6: std_logic_vector(9 downto 0);         
  signal sign0,sign0r,sign1,sign2,sign3: std_logic;                
  signal nz0,nz1,nz2: std_logic;                                   
                                                                   
begin                                                              
                                                                   
  d1 <=  NOT fixdata(30 downto 0);                     
  one <= "0000000000000000000000000000001";                                              
  u1: unreg_add_sub generic map (WIDTH=>31,DIRECTION=>"ADD")
                  port map(result=>d2,dataa=>d1,datab=>one);
  d0 <= fixdata(30 downto 0);                        
  sign0 <= fixdata(31);                              
                                                                 
  with sign0 select                                              
    d3 <= d0 when '0',                                           
    d2 when others;                                              
                                                                 
  process(clk) begin                                             
    if(clk'event and clk='1') then                               
      d3r <= d3;                                                 
      sign1 <= sign0;                                            
    end if;                                                      
  end process;                                                   
                                                                 
  u2: penc_31_5 port map (a=>d3r,c=>c1);   
  with d3r select                                                
    nz0 <= '0' when "0000000000000000000000000000000",                                  
           '1' when others;                                      
                                                                 
  process(clk) begin                                             
    if(clk'event and clk='1') then                               
      d4 <= d3r(29 downto 0);                        
      c2 <= c1;                                                  
      sign2 <= sign1;                                            
      nz1 <= nz0;                                                
    end if;                                                      
  end process;                                                   
                                                                 
  u3: unreg_shift_ftol_30_10
            port map (indata=>d4,control=>c2,outdata=>d5);

  process(clk) begin                                             
    if(clk'event and clk='1') then                               
      d6 <= d5;                                                  
      sign3 <= sign2;                                            
      nz2 <= nz1;                                                
      c3 <= c2;                                                  
    end if;                                                      
  end process;                                                   
                                                                 
  u4: table generic map(IN_WIDTH=>10,OUT_WIDTH=>8,TABLE_FILE=>"ftl0.mif") 
            port map(indata=>d6,outdata=>logdata(7 downto 0),clk=>clk);

  with d6 select                                                 
    add <= "00001" when "1111111111",                          
           "00001" when "1111111110",                        
           "00001" when "1111111101",                        
           "00000" when others;                               
                                                                 
  u5: unreg_add_sub generic map (WIDTH=>5,DIRECTION=>"ADD")
                  port map(result=>c4,dataa=>c3,datab=>add);

  logdata(14 downto 13) <= "00";                    
                                                                 
  process(clk) begin                                             
    if(clk'event and clk='1') then                               
      logdata(16) <= sign3 ;                          
      logdata(15) <= nz2;                             
      logdata(12 downto 8) <= c4;                    
    end if;                                                      
  end process;                                                   

end rtl;

-- The Unregisterd Add/Sub
-- For Xilinx devices
-- Author: Tsuyoshi Hamada
-- Last Modified at Feb 06,2004
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity unreg_add_sub is
  generic(WIDTH : integer :=4; DIRECTION: string :="ADD");
    port (dataa,datab: in std_logic_vector(WIDTH-1 downto 0);
          result: out std_logic_vector(WIDTH-1 downto 0));
end unreg_add_sub;
architecture rtl of unreg_add_sub is
begin
ifgen0 : if (DIRECTION="ADD") generate
  result <= dataa + datab;
end generate;
ifgen1 : if (DIRECTION="SUB") generate
  result <= dataa - datab;
end generate;
end rtl;

                                                                    
library ieee;                                                       
use ieee.std_logic_1164.all;                                        
                                                                    
entity penc_31_5 is                             
port( a : in std_logic_vector(30 downto 0);              
      c : out std_logic_vector(4 downto 0));           
end penc_31_5;                                  
                                                                    
architecture rtl of penc_31_5 is                
begin                                                               
                                                                    
  process(a) begin                                                  
    if(a(30)='1') then                                    
      c <= "11110";                                              
    elsif(a(29)='1') then                                      
      c <= "11101";                                             
    elsif(a(28)='1') then                                      
      c <= "11100";                                             
    elsif(a(27)='1') then                                      
      c <= "11011";                                             
    elsif(a(26)='1') then                                      
      c <= "11010";                                             
    elsif(a(25)='1') then                                      
      c <= "11001";                                             
    elsif(a(24)='1') then                                      
      c <= "11000";                                             
    elsif(a(23)='1') then                                      
      c <= "10111";                                             
    elsif(a(22)='1') then                                      
      c <= "10110";                                             
    elsif(a(21)='1') then                                      
      c <= "10101";                                             
    elsif(a(20)='1') then                                      
      c <= "10100";                                             
    elsif(a(19)='1') then                                      
      c <= "10011";                                             
    elsif(a(18)='1') then                                      
      c <= "10010";                                             
    elsif(a(17)='1') then                                      
      c <= "10001";                                             
    elsif(a(16)='1') then                                      
      c <= "10000";                                             
    elsif(a(15)='1') then                                      
      c <= "01111";                                             
    elsif(a(14)='1') then                                      
      c <= "01110";                                             
    elsif(a(13)='1') then                                      
      c <= "01101";                                             
    elsif(a(12)='1') then                                      
      c <= "01100";                                             
    elsif(a(11)='1') then                                      
      c <= "01011";                                             
    elsif(a(10)='1') then                                      
      c <= "01010";                                             
    elsif(a(9)='1') then                                      
      c <= "01001";                                             
    elsif(a(8)='1') then                                      
      c <= "01000";                                             
    elsif(a(7)='1') then                                      
      c <= "00111";                                             
    elsif(a(6)='1') then                                      
      c <= "00110";                                             
    elsif(a(5)='1') then                                      
      c <= "00101";                                             
    elsif(a(4)='1') then                                      
      c <= "00100";                                             
    elsif(a(3)='1') then                                      
      c <= "00011";                                             
    elsif(a(2)='1') then                                      
      c <= "00010";                                             
    elsif(a(1)='1') then                                      
      c <= "00001";                                             
    else                                                            
      c <= "00000";                                               
    end if;                                                         
  end process;                                                      
                                                                    
end rtl;                                                            

-- The barrel shifter for Fix to Log Converter
-- Author: Tsuyoshi Hamada
-- Last Modified at Feb 6,2003
library ieee;
use ieee.std_logic_1164.all;

entity unreg_shift_ftol_30_10 is
  port( indata : in std_logic_vector(29 downto 0);
        control : in std_logic_vector(4 downto 0);
        outdata : out std_logic_vector(9 downto 0));
end unreg_shift_ftol_30_10;

architecture rtl of unreg_shift_ftol_30_10 is

  signal cntd_4 : std_logic;
  signal d0 : std_logic_vector(39 downto 0);
  signal s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s16,s17,s18,s19,s20,s21,s22,s23,s24,s25,s26,s27,s28,s29,s30,s31 : std_logic_vector(9 downto 0);
  signal c0xxxx, c1xxxx : std_logic_vector(9 downto 0);
  signal c0xxxxd,c1xxxxd : std_logic_vector(9 downto 0);

begin

  with cntd_4 select               
    outdata <= c0xxxxd when '0',   
               c1xxxxd when others;

  cntd_4 <= control(4);
  c0xxxxd <= c0xxxx;
  c1xxxxd <= c1xxxx;

  d0 <= indata & "0000000000";

  s0 <= d0(9 downto 0);
  s1 <= d0(10 downto 1);
  s2 <= d0(11 downto 2);
  s3 <= d0(12 downto 3);
  s4 <= d0(13 downto 4);
  s5 <= d0(14 downto 5);
  s6 <= d0(15 downto 6);
  s7 <= d0(16 downto 7);
  s8 <= d0(17 downto 8);
  s9 <= d0(18 downto 9);
  s10 <= d0(19 downto 10);
  s11 <= d0(20 downto 11);
  s12 <= d0(21 downto 12);
  s13 <= d0(22 downto 13);
  s14 <= d0(23 downto 14);
  s15 <= d0(24 downto 15);
  s16 <= d0(25 downto 16);
  s17 <= d0(26 downto 17);
  s18 <= d0(27 downto 18);
  s19 <= d0(28 downto 19);
  s20 <= d0(29 downto 20);
  s21 <= d0(30 downto 21);
  s22 <= d0(31 downto 22);
  s23 <= d0(32 downto 23);
  s24 <= d0(33 downto 24);
  s25 <= d0(34 downto 25);
  s26 <= d0(35 downto 26);
  s27 <= d0(36 downto 27);
  s28 <= d0(37 downto 28);
  s29 <= d0(38 downto 29);
  s30 <= d0(39 downto 30);
  s31 <= '0' & d0(39 downto 31);

-- Specified to LCELL 4-bit inputs.
  with control(3 downto 0) select
    c0xxxx <= s0 when "0000",  
           s1 when "0001",     
           s2 when "0010",     
           s3 when "0011",     
           s4 when "0100",     
           s5 when "0101",     
           s6 when "0110",     
           s7 when "0111",     
           s8 when "1000",     
           s9 when "1001",     
           s10 when "1010",    
           s11 when "1011",    
           s12 when "1100",    
           s13 when "1101",    
           s14 when "1110",    
           s15 when others;      

  with control(3 downto 0) select
    c1xxxx <= s16 when "0000", 
           s17 when "0001",    
           s18 when "0010",    
           s19 when "0011",    
           s20 when "0100",    
           s21 when "0101",    
           s22 when "0110",    
           s23 when "0111",    
           s24 when "1000",    
           s25 when "1001",    
           s26 when "1010",    
           s27 when "1011",    
           s28 when "1100",    
           s29 when "1101",    
           s30 when "1110",    
           s31 when others;      

end rtl;
                                                                    
library ieee;                                                       
use ieee.std_logic_1164.all;                                        
                                                                    
entity table is                                                     
  generic(IN_WIDTH: integer := 7;                                   
       OUT_WIDTH: integer := 5;                                     
       TABLE_FILE: string := "ftol.mif");                         
  port(indata : in std_logic_vector(IN_WIDTH-1 downto 0);           
       outdata : out std_logic_vector(OUT_WIDTH-1 downto 0);        
       clk : in std_logic);                                         
end table;                                                          
                                                                    
architecture rtl of table is                                        
                                                                    
  component lpm_rom                                                 
    generic (LPM_WIDTH: POSITIVE;                                   
             LPM_WIDTHAD: POSITIVE;                                 
          LPM_ADDRESS_CONTROL: STRING;                              
          LPM_FILE: STRING);                                        
   port (address: in std_logic_vector(LPM_WIDTHAD-1 downto 0);      
         outclock: in std_logic;                                    
         q: out std_logic_vector(LPM_WIDTH-1 downto 0));            
  end component;                                                    
                                                                    
begin                                                               
                                                                    
  u1: lpm_rom generic map (LPM_WIDTH=>OUT_WIDTH,                    
                           LPM_WIDTHAD=>IN_WIDTH,                   
                           LPM_ADDRESS_CONTROL=>"UNREGISTERED",   
                           LPM_FILE=>TABLE_FILE)                    
  port map(address=>indata,outclock=>clk,q=>outdata);               
                                                                    
end rtl;                                                            
                                                                    

library ieee;
use ieee.std_logic_1164.all;

entity pg_pdelay_12 is
  generic (PG_WIDTH: integer);
  port( x : in std_logic_vector(PG_WIDTH-1 downto 0);
	   y : out std_logic_vector(PG_WIDTH-1 downto 0);
	   clk : in std_logic);
end pg_pdelay_12;

architecture rtl of pg_pdelay_12 is

  signal x0 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x1 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x2 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x3 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x4 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x5 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x6 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x7 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x8 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x9 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x10 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x11 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x12 : std_logic_vector(PG_WIDTH-1 downto 0);   

begin

  x0 <= x;

  process(clk) begin
    if(clk'event and clk='1') then
      x12 <= x11;
      x11 <= x10;
      x10 <= x9;
      x9 <= x8;
      x8 <= x7;
      x7 <= x6;
      x6 <= x5;
      x5 <= x4;
      x4 <= x3;
      x3 <= x2;
      x2 <= x1;
      x1 <= x0;
    end if;
  end process;

  y <= x12;

end rtl;
                                                           
library ieee;                                              
use ieee.std_logic_1164.all;                               
                                                           
entity pg_log_shift_1 is                          
  generic (PG_WIDTH: integer);                             
  port( x : in std_logic_vector(PG_WIDTH-1 downto 0);      
	   y : out std_logic_vector(PG_WIDTH-1 downto 0);    
	   clk : in std_logic);                              
end pg_log_shift_1;                               
                                                           
architecture rtl of pg_log_shift_1 is             
                                                           
begin                                                      
                                                           
  y <= '0' & x(PG_WIDTH-2) & x(PG_WIDTH-4 downto 0) & '0';     
                                                           
end rtl;                                                   

library ieee;
use ieee.std_logic_1164.all;

entity pg_pdelay_6 is
  generic (PG_WIDTH: integer);
  port( x : in std_logic_vector(PG_WIDTH-1 downto 0);
	   y : out std_logic_vector(PG_WIDTH-1 downto 0);
	   clk : in std_logic);
end pg_pdelay_6;

architecture rtl of pg_pdelay_6 is

  signal x0 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x1 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x2 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x3 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x4 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x5 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x6 : std_logic_vector(PG_WIDTH-1 downto 0);   

begin

  x0 <= x;

  process(clk) begin
    if(clk'event and clk='1') then
      x6 <= x5;
      x5 <= x4;
      x4 <= x3;
      x3 <= x2;
      x2 <= x1;
      x1 <= x0;
    end if;
  end process;

  y <= x6;

end rtl;

-- *************************************************************** 
-- * PGPG UNSIGNED LOGARITHMIC ADDER(INTERPOLATED) MODULE        * 
-- *  AUTHOR: Tsuyoshi Hamada                                    * 
-- *  VERSION: 1.03                                              * 
-- *  LAST MODIFIED AT Tue Mar 25 10:52:09 JST 2003              * 
-- *************************************************************** 
-- Nman	8-bit
-- Ncut	6-bit
-- Npipe	5
-- rom_c0(address)	6-bit
-- rom_c1(address)	6-bit
-- rom_c0(data)	10-bit
-- rom_c1(data)	9-bit

library ieee;
use ieee.std_logic_1164.all;

entity pg_log_unsigned_add_itp_17_8_6_5 is
  port( x,y : in std_logic_vector(16 downto 0);
        z : out std_logic_vector(16 downto 0);
        clock : in std_logic);
end pg_log_unsigned_add_itp_17_8_6_5;

architecture rtl of pg_log_unsigned_add_itp_17_8_6_5 is

  component pg_umult_6_9_2
  port (
    clk : in std_logic; 
    x : in std_logic_vector(5 downto 0); 
    y : in std_logic_vector(8 downto 0); 
    z : out std_logic_vector(14 downto 0));
  end component;

-- This part has a bug potentially.
-- The MULTIPLE DECLARATION will be occure!!
-- But I don't have time to fix it today. (2004/02/19)
-- I will kill the bug for future.
-- If your VHDL code bumps this MULTIPLE DECLARATION error at synthesis,
-- Please contact me(hamada@provence.c.u-tokyo.ac.jp).
  -- u1 --
  component pg_adder_RCA_SUB_17_0
    port (x,y: in std_logic_vector(16 downto 0);
          clk: in std_logic;
          z: out std_logic_vector(16 downto 0));
  end component;

  -- u2 --
  component pg_adder_RCA_SUB_16_0
    port (x,y: in std_logic_vector(15 downto 0);
          clk: in std_logic;
          z: out std_logic_vector(15 downto 0));
  end component;

  -- itp_sub --
  component pg_adder_RCA_SUB_11_0
    port (x,y: in std_logic_vector(10 downto 0);
          clk: in std_logic;
          z: out std_logic_vector(10 downto 0));
  end component;

  -- u4 --
  component pg_adder_RCA_ADD_16_0
    port (x,y: in std_logic_vector(15 downto 0);
          clk: in std_logic;
          z: out std_logic_vector(15 downto 0));
  end component;

  component lcell_rom_a106_6_10_0                      
   port (indata: in std_logic_vector(5 downto 0);    
         clk: in std_logic;                           
         outdata: out std_logic_vector(9 downto 0)); 
  end component;                                      

  component lcell_rom_a906_6_9_0                      
   port (indata: in std_logic_vector(5 downto 0);    
         clk: in std_logic;                           
         outdata: out std_logic_vector(8 downto 0)); 
  end component;                                      

                                                                   
  signal x1,y1,xy : std_logic_vector(16 downto 0);     
  signal yx : std_logic_vector(15 downto 0);           
  signal xd,yd : std_logic_vector(15 downto 0);        
  signal x2,x3,x4,x5,x6,x7,x8 : std_logic_vector(15 downto 0);
  signal d0,d1,d4 : std_logic_vector(15 downto 0);     
  signal z0 : std_logic_vector(15 downto 0);           
  signal sign0,sign1,sign2,sign3,sign4,sign5,sign6,sign7,sign8 : std_logic;
  signal signxy : std_logic_vector(1 downto 0);        
  -- FOR TABLE SUB LOGIC
  signal df0,df1,df2,df3,df4,df5 : std_logic;                  
  signal d_isz0,d_isz1,d_isz2,d_isz3,d_isz4,d_isz5 : std_logic;
  signal d2 : std_logic_vector(8 downto 0);           
  signal itp_x  : std_logic_vector(5 downto 0);
  signal itp_dx0,itp_dx1 : std_logic_vector(5 downto 0);
  signal itp_c0,itp_c0d0,itp_c0d1,itp_c0d2 : std_logic_vector(9 downto 0);
  signal itp_c1 : std_logic_vector(8 downto 0);
  signal itp_c1dx : std_logic_vector(14 downto 0);
  signal itp_c1dx_shift : std_logic_vector(9 downto 0);
  signal itp_c1dx2: std_logic_vector(9 downto 0);
  signal itp_subx,itp_suby,itp_subz: std_logic_vector(10 downto 0);
  signal itp_c0_c1dx: std_logic_vector(7 downto 0);
  signal itp_out0,itp_out1: std_logic_vector(7 downto 0);
                                                                   
begin                                                              
                                                                   
  x1 <= '0' & x(15 downto 0);                          
  y1 <= '0' & y(15 downto 0);                          
                                                                   
  --- PIPELINE 1(OFF) ---
  u1: pg_adder_RCA_SUB_17_0  port map(x=>x1,y=>y1,z=>xy,clk=>clock);
  u2: pg_adder_RCA_SUB_16_0  port map(x=>y(15 downto 0),y=>x(15 downto 0),z=>yx,clk=>clock);
  xd <= x(15 downto 0);
  yd <= y(15 downto 0);
  sign1 <= sign0;
  ------------------.


  x2 <= xd when xy(16)='0' else yd;
  d0 <= xy(15 downto 0) when xy(16)='0' else yx;
                                                                   
  signxy <= x(16)&y(16);                    
  with signxy select                                               
    sign0 <= y(16) when "01",                        
             x(16) when others;                        
                                                                   
  --- PIPELINE 2 ---
  process(clock) begin                                             
    if(clock'event and clock='1') then                             
      x3 <= x2;                                                    
      d1 <= d0;                                                    
      sign2 <= sign1;                                             
    end if;                                                        
  end process;                                                     
  ------------------.


-- TABLE PART (START) ---------------------------------------------
-- INPUT  d1 : 16-bit
-- OUTPUT d4 : 16-bit
  df0 <= '1' when d1(15 downto 12)="0000" else '0';
  
  -- ALL OR -> NOT (PLUS) --
  d_isz0 <= '1' when d1(11 downto 0)="000000000000" else '0';

-- TABLE (INTERPOLATION) --
-- *************************************************************** 
-- * PGPG UNSIGNED LOGARITHMIC ADDER MODULE OF                   * 
-- * INTERPORATED TABLE LOGIC : f(x+dx) ~= c0(x) + c1(x)dx       * 
-- *  c0(x) and c1(x) are chebyshev coefficients.                * 
-- *************************************************************** 
  itp_x   <= d1(11 downto 6);
  itp_dx0 <= d1(5 downto 0);

  --- PIPELINE 3(OFF) ---

  -- UNREGISTERED TABLE --                            
  -- c0(x) --                                         
  itp_c0_rom: lcell_rom_a106_6_10_0
  port map(indata=>itp_x,outdata=>itp_c0,clk=>clock);

  -- c1(x) --                                         
  itp_c1_rom: lcell_rom_a906_6_9_0
  port map(indata=>itp_x,outdata=>itp_c1,clk=>clock);


  df1 <= df0;
  d_isz1 <= d_isz0;
  itp_dx1 <= itp_dx0;
  ------------------.


  --- PIPELINE 4,5 ---
  -- ITP MULT --  6-bit * 9-bit -> 15-bit
  itp_mult: pg_umult_6_9_2
    port map (       
    clk  => clock,   
    x  => itp_dx1,   
    y  => itp_c1,    
    z  => itp_c1dx); 
  ------------------.
  --- PIPELINE 4 ---
  process(clock) begin
    if(clock'event and clock='1') then
      df2 <= df1;
      d_isz2 <= d_isz1;
      itp_c0d0 <= itp_c0;
    end if;
  end process;
  ------------------.
  --- PIPELINE 5 ---
  process(clock) begin
    if(clock'event and clock='1') then
      df3 <= df2;
      d_isz3 <= d_isz2;
      itp_c0d1 <= itp_c0d0;
    end if;
  end process;
  ------------------.


  -- SHIFT >> 8-bit , JOINE ZERO-VECTORS TO THE UPPER-BIT
  itp_c1dx_shift <= "000" & itp_c1dx(14 downto 8);

  --- PIPELINE 6(OFF) ---
      df4 <= df3;
      d_isz4 <= d_isz3;
      itp_c0d2 <= itp_c0d1;
      itp_c1dx2 <= itp_c1dx_shift;
  ------------------.


  itp_subx <= '0' & itp_c0d2;
  itp_suby <= '0' & itp_c1dx2;
  itp_sub: pg_adder_RCA_SUB_11_0  port map(x=>itp_subx,y=>itp_suby,z=>itp_subz,clk=>clock);

  -- IF [f(x+dx)=c0(x)-c1(x)dx<0] THEN [f(x+dx) := 0] ELSE SHIFT >> 2-bit
  itp_c0_c1dx <= "00000000" when (itp_subz(10)='1') else itp_subz(9 downto 2);


  itp_out0 <= itp_c0_c1dx when (d_isz4='0') else "00000000";


  --- PIPELINE 7 ---
  process(clock) begin
    if(clock'event and clock='1') then
      df5 <= df4;
      d_isz5 <= d_isz4;
      itp_out1 <= itp_out0;
    end if;
  end process;
  ------------------.

  d2(8) <= d_isz5;
  d2(7 downto 0) <= itp_out1;
  d4(8 downto 0) <= d2 when (df5 = '1') else "000000000";
  d4(15 downto 9) <= "0000000";

-- TABLE PART (END) ---------------------------------------------


  --- PIPELINE 3(OFF) ---
  x4 <= x3;
  sign3 <= sign2;
  ------------------.

  --- PIPELINE 4 ---
  process(clock) begin
    if(clock'event and clock='1') then
      x5 <= x4;
      sign4 <= sign3;
    end if;
  end process;
  ------------------.

  --- PIPELINE 5 ---
  process(clock) begin
    if(clock'event and clock='1') then
      x6 <= x5;
      sign5 <= sign4;
    end if;
  end process;
  ------------------.

  --- PIPELINE 6(OFF) ---
  x7 <= x6;
  sign6 <= sign5;
  ------------------.

  --- PIPELINE 7 ---
  process(clock) begin
    if(clock'event and clock='1') then
      x8 <= x7;
      sign7 <= sign6;
    end if;
  end process;
  ------------------.

  --- PIPELINE 8(OFF) ---
  u4: pg_adder_RCA_ADD_16_0  port map(x=>x8,y=>d4,z=>z0,clk=>clock);

  sign8 <= sign7;
  ------------------.

  --- PIPELINE 9 ---
  process(clock) begin
    if(clock'event and clock='1') then
      z(15 downto 0) <= z0;
      z(16) <= sign8;
    end if;
  end process;
  ------------------.

end rtl;
-- ============= END  pg_log_unsigned_add interporation version    
                                   
-- ROM using Lcell not ESB         
-- Author: Tsuyoshi Hamada         
-- Last Modified at May 29,2003    
-- In 6 Out 10 Stage 0 Type"a106"
library ieee;                      
use ieee.std_logic_1164.all;       
                                   
entity lcell_rom_a106_6_10_0 is
  port( indata : in std_logic_vector(5 downto 0);
        clk : in std_logic;
        outdata : out std_logic_vector(9 downto 0));
end lcell_rom_a106_6_10_0;

architecture rtl of lcell_rom_a106_6_10_0 is

  component pg_lcell
    generic (MASK : bit_vector  := X"ffff";
             FF   : integer :=0);
    port (x   : in  std_logic_vector(3 downto 0);
          z   : out std_logic;
          clk : in  std_logic);
  end component;

  signal adr0 : std_logic_vector(5 downto 0);
  signal adr1 : std_logic_vector(5 downto 0);
  signal adr2 : std_logic_vector(5 downto 0);
  signal lc_4_0 : std_logic_vector(9 downto 0);
  signal lc_4_1 : std_logic_vector(9 downto 0);
  signal lc_4_2 : std_logic_vector(9 downto 0);
  signal lc_4_3 : std_logic_vector(9 downto 0);
  signal lut_5_0,lc_5_0 : std_logic_vector(9 downto 0);
  signal lut_5_1,lc_5_1 : std_logic_vector(9 downto 0);
  signal lut_6_0,lc_6_0 : std_logic_vector(9 downto 0);

begin

  LC_000_00 : pg_lcell
  generic map(MASK=>X"6305",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(0));

  LC_000_01 : pg_lcell
  generic map(MASK=>X"B071",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(1));

  LC_000_02 : pg_lcell
  generic map(MASK=>X"5877",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(2));

  LC_000_03 : pg_lcell
  generic map(MASK=>X"DB41",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(3));

  LC_000_04 : pg_lcell
  generic map(MASK=>X"665D",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(4));

  LC_000_05 : pg_lcell
  generic map(MASK=>X"D449",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(5));

  LC_000_06 : pg_lcell
  generic map(MASK=>X"CD11",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(6));

  LC_000_07 : pg_lcell
  generic map(MASK=>X"3CCB",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(7));

  LC_000_08 : pg_lcell
  generic map(MASK=>X"03C7",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(8));

  LC_000_09 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(9));

  LC_001_00 : pg_lcell
  generic map(MASK=>X"9393",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(0));

  LC_001_01 : pg_lcell
  generic map(MASK=>X"BBAA",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(1));

  LC_001_02 : pg_lcell
  generic map(MASK=>X"8938",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(2));

  LC_001_03 : pg_lcell
  generic map(MASK=>X"7893",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(3));

  LC_001_04 : pg_lcell
  generic map(MASK=>X"0789",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(4));

  LC_001_05 : pg_lcell
  generic map(MASK=>X"0078",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(5));

  LC_001_06 : pg_lcell
  generic map(MASK=>X"0007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(6));

--LC_001_07 
  lc_4_1(7) <= '0';

--LC_001_08 
  lc_4_1(8) <= '0';

--LC_001_09 
  lc_4_1(9) <= '0';

  LC_002_00 : pg_lcell
  generic map(MASK=>X"001A",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(0));

  LC_002_01 : pg_lcell
  generic map(MASK=>X"0079",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(1));

  LC_002_02 : pg_lcell
  generic map(MASK=>X"0007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(2));

--LC_002_03 
  lc_4_2(3) <= '0';

--LC_002_04 
  lc_4_2(4) <= '0';

--LC_002_05 
  lc_4_2(5) <= '0';

--LC_002_06 
  lc_4_2(6) <= '0';

--LC_002_07 
  lc_4_2(7) <= '0';

--LC_002_08 
  lc_4_2(8) <= '0';

--LC_002_09 
  lc_4_2(9) <= '0';

--LC_003_00 
  lc_4_3(0) <= '0';

--LC_003_01 
  lc_4_3(1) <= '0';

--LC_003_02 
  lc_4_3(2) <= '0';

--LC_003_03 
  lc_4_3(3) <= '0';

--LC_003_04 
  lc_4_3(4) <= '0';

--LC_003_05 
  lc_4_3(5) <= '0';

--LC_003_06 
  lc_4_3(6) <= '0';

--LC_003_07 
  lc_4_3(7) <= '0';

--LC_003_08 
  lc_4_3(8) <= '0';

--LC_003_09 
  lc_4_3(9) <= '0';

  adr0 <= indata;
  adr1(5 downto 4) <= adr0(5 downto 4);
  adr2(5) <= adr1(5);

--  =================================
  with adr1(4) select
    lut_5_0 <= lc_4_0 when '0',
              lc_4_1 when others;

  with adr1(4) select
    lut_5_1 <= lc_4_2 when '0',
              lc_4_3 when others;

--  =================================
  with adr2(5) select
    lut_6_0 <= lc_5_0 when '0',
              lc_5_1 when others;


--  =================================
    lc_5_0 <= lut_5_0;
    lc_5_1 <= lut_5_1;
--  =================================
    lc_6_0 <= lut_6_0;
  outdata <= lc_6_0;
end rtl;
                                   
-- ROM using Lcell not ESB         
-- Author: Tsuyoshi Hamada         
-- Last Modified at May 29,2003    
-- In 6 Out 9 Stage 0 Type"a906"
library ieee;                      
use ieee.std_logic_1164.all;       
                                   
entity lcell_rom_a906_6_9_0 is
  port( indata : in std_logic_vector(5 downto 0);
        clk : in std_logic;
        outdata : out std_logic_vector(8 downto 0));
end lcell_rom_a906_6_9_0;

architecture rtl of lcell_rom_a906_6_9_0 is

  component pg_lcell
    generic (MASK : bit_vector  := X"ffff";
             FF   : integer :=0);
    port (x   : in  std_logic_vector(3 downto 0);
          z   : out std_logic;
          clk : in  std_logic);
  end component;

  signal adr0 : std_logic_vector(5 downto 0);
  signal adr1 : std_logic_vector(5 downto 0);
  signal adr2 : std_logic_vector(5 downto 0);
  signal lc_4_0 : std_logic_vector(8 downto 0);
  signal lc_4_1 : std_logic_vector(8 downto 0);
  signal lc_4_2 : std_logic_vector(8 downto 0);
  signal lc_4_3 : std_logic_vector(8 downto 0);
  signal lut_5_0,lc_5_0 : std_logic_vector(8 downto 0);
  signal lut_5_1,lc_5_1 : std_logic_vector(8 downto 0);
  signal lut_6_0,lc_6_0 : std_logic_vector(8 downto 0);

begin

  LC_000_00 : pg_lcell
  generic map(MASK=>X"DD64",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(0));

  LC_000_01 : pg_lcell
  generic map(MASK=>X"2F5F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(1));

  LC_000_02 : pg_lcell
  generic map(MASK=>X"47A2",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(2));

  LC_000_03 : pg_lcell
  generic map(MASK=>X"7DEB",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(3));

  LC_000_04 : pg_lcell
  generic map(MASK=>X"29E6",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(4));

  LC_000_05 : pg_lcell
  generic map(MASK=>X"1B4B",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(5));

  LC_000_06 : pg_lcell
  generic map(MASK=>X"F8D9",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(6));

  LC_000_07 : pg_lcell
  generic map(MASK=>X"07C7",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(7));

  LC_000_08 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(8));

  LC_001_00 : pg_lcell
  generic map(MASK=>X"5892",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(0));

  LC_001_01 : pg_lcell
  generic map(MASK=>X"350A",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(1));

  LC_001_02 : pg_lcell
  generic map(MASK=>X"F352",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(2));

  LC_001_03 : pg_lcell
  generic map(MASK=>X"0F37",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(3));

  LC_001_04 : pg_lcell
  generic map(MASK=>X"00F1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(4));

  LC_001_05 : pg_lcell
  generic map(MASK=>X"000F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(5));

--LC_001_06 
  lc_4_1(6) <= '0';

--LC_001_07 
  lc_4_1(7) <= '0';

--LC_001_08 
  lc_4_1(8) <= '0';

  LC_002_00 : pg_lcell
  generic map(MASK=>X"0046",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(0));

  LC_002_01 : pg_lcell
  generic map(MASK=>X"003E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(1));

  LC_002_02 : pg_lcell
  generic map(MASK=>X"0001",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(2));

--LC_002_03 
  lc_4_2(3) <= '0';

--LC_002_04 
  lc_4_2(4) <= '0';

--LC_002_05 
  lc_4_2(5) <= '0';

--LC_002_06 
  lc_4_2(6) <= '0';

--LC_002_07 
  lc_4_2(7) <= '0';

--LC_002_08 
  lc_4_2(8) <= '0';

--LC_003_00 
  lc_4_3(0) <= '0';

--LC_003_01 
  lc_4_3(1) <= '0';

--LC_003_02 
  lc_4_3(2) <= '0';

--LC_003_03 
  lc_4_3(3) <= '0';

--LC_003_04 
  lc_4_3(4) <= '0';

--LC_003_05 
  lc_4_3(5) <= '0';

--LC_003_06 
  lc_4_3(6) <= '0';

--LC_003_07 
  lc_4_3(7) <= '0';

--LC_003_08 
  lc_4_3(8) <= '0';

  adr0 <= indata;
  adr1(5 downto 4) <= adr0(5 downto 4);
  adr2(5) <= adr1(5);

--  =================================
  with adr1(4) select
    lut_5_0 <= lc_4_0 when '0',
              lc_4_1 when others;

  with adr1(4) select
    lut_5_1 <= lc_4_2 when '0',
              lc_4_3 when others;

--  =================================
  with adr2(5) select
    lut_6_0 <= lc_5_0 when '0',
              lc_5_1 when others;


--  =================================
    lc_5_0 <= lut_5_0;
    lc_5_1 <= lut_5_1;
--  =================================
    lc_6_0 <= lut_6_0;
  outdata <= lc_6_0;
end rtl;

--+--------------------------------+
--| PGPG unsigned multiplier       |
--|  2004/02/16 for Xilinx Devices |
--|      by Tsuyoshi Hamada        |
--+--------------------------------+
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pg_umult_6_9_2 is
  port(x : in std_logic_vector(5 downto 0);
       y : in std_logic_vector(8 downto 0);
       z : out std_logic_vector(14 downto 0);
     clk : in std_logic);
end pg_umult_6_9_2;

architecture rtl of pg_umult_6_9_2 is

  signal y0 : std_logic_vector(4 downto 0);
  signal y1 : std_logic_vector(3 downto 0);
  signal s0,s0d : std_logic_vector(11 downto 0);
  signal s1,s1d : std_logic_vector(9 downto 0);
  signal s : std_logic_vector(14 downto 0);
begin
  y0 <= y(4 downto 0);
  y1 <= y(8 downto 5);

  s0 <= x * ('0'&y0); -- 12-bit
  s1 <= x * y1;       -- 10-bit
  s <=(s1d & "00000")+("000" & s0d);

  process(clk) begin
    if(clk'event and clk='1') then
      s0d <= s0;
      s1d <= s1;
      z <= s;
    end if;
  end process;
end rtl;

--+--------------------------------+
--| PGPG Ripple-Carry Adder        |
--|  2004/02/12 for Xilinx Devices |
--|      by Tsuyoshi Hamada        |
--+--------------------------------+
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pg_adder_RCA_SUB_17_0 is
  port(x,y : in std_logic_vector(16 downto 0);
       z : out std_logic_vector(16 downto 0);
       clk : in std_logic);
end pg_adder_RCA_SUB_17_0;

architecture rtl of pg_adder_RCA_SUB_17_0 is

  signal sum : std_logic_vector(16 downto 0);
begin
  sum <= x - y;
  z <= sum;
end rtl;

--+--------------------------------+
--| PGPG Ripple-Carry Adder        |
--|  2004/02/12 for Xilinx Devices |
--|      by Tsuyoshi Hamada        |
--+--------------------------------+
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pg_adder_RCA_SUB_16_0 is
  port(x,y : in std_logic_vector(15 downto 0);
       z : out std_logic_vector(15 downto 0);
       clk : in std_logic);
end pg_adder_RCA_SUB_16_0;

architecture rtl of pg_adder_RCA_SUB_16_0 is

  signal sum : std_logic_vector(15 downto 0);
begin
  sum <= x - y;
  z <= sum;
end rtl;

--+--------------------------------+
--| PGPG Ripple-Carry Adder        |
--|  2004/02/12 for Xilinx Devices |
--|      by Tsuyoshi Hamada        |
--+--------------------------------+
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pg_adder_RCA_SUB_11_0 is
  port(x,y : in std_logic_vector(10 downto 0);
       z : out std_logic_vector(10 downto 0);
       clk : in std_logic);
end pg_adder_RCA_SUB_11_0;

architecture rtl of pg_adder_RCA_SUB_11_0 is

  signal sum : std_logic_vector(10 downto 0);
begin
  sum <= x - y;
  z <= sum;
end rtl;

--+--------------------------------+
--| PGPG Ripple-Carry Adder        |
--|  2004/02/12 for Xilinx Devices |
--|      by Tsuyoshi Hamada        |
--+--------------------------------+
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pg_adder_RCA_ADD_16_0 is
  port(x,y : in std_logic_vector(15 downto 0);
       z : out std_logic_vector(15 downto 0);
       clk : in std_logic);
end pg_adder_RCA_ADD_16_0;

architecture rtl of pg_adder_RCA_ADD_16_0 is

  signal sum : std_logic_vector(15 downto 0);
begin
  sum <= x + y;
  z <= sum;
end rtl;
                                                           
library ieee;                                              
use ieee.std_logic_1164.all;                               
                                                           
entity pg_log_shift_m1 is                          
  generic (PG_WIDTH: integer);                             
  port( x : in std_logic_vector(PG_WIDTH-1 downto 0);      
	   y : out std_logic_vector(PG_WIDTH-1 downto 0);    
	   clk : in std_logic);                              
end pg_log_shift_m1;                               
                                                           
architecture rtl of pg_log_shift_m1 is             
                                                           
begin                                                      
                                                           
  y <= '0' & x(PG_WIDTH-2) & '0' & x(PG_WIDTH-3 downto 1);   
                                                           
end rtl;                                                   

library ieee;
use ieee.std_logic_1164.all;

entity pg_log_mul_17_1 is
  port( x,y : in std_logic_vector(16 downto 0);
          z : out std_logic_vector(16 downto 0);
        clk : in std_logic);
end pg_log_mul_17_1;

architecture rtl of pg_log_mul_17_1 is

  component pg_adder_RCA_ADD_15_1
    port (x,y: in std_logic_vector(14 downto 0);
          clk: in std_logic;
          z: out std_logic_vector(14 downto 0));
  end component;

 signal addx,addy,addz: std_logic_vector(14 downto 0); 

begin

  process(clk) begin
    if(clk'event and clk='1') then
      z(16) <= x(16) xor y(16);
      z(15) <= x(15) and y(15);
    end if;
  end process;
  addx <= x(14 downto 0);
  addy <= y(14 downto 0);

  u1: pg_adder_RCA_ADD_15_1  port map(x=>addx,y=>addy,clk=>clk,z=>addz);
  z(14 downto 0) <= addz;

end rtl;

--+--------------------------------+
--| PGPG Ripple-Carry Adder        |
--|  2004/02/12 for Xilinx Devices |
--|      by Tsuyoshi Hamada        |
--+--------------------------------+
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pg_adder_RCA_ADD_15_1 is
  port(x,y : in std_logic_vector(14 downto 0);
       z : out std_logic_vector(14 downto 0);
       clk : in std_logic);
end pg_adder_RCA_ADD_15_1;

architecture rtl of pg_adder_RCA_ADD_15_1 is

  signal sum : std_logic_vector(14 downto 0);
begin
  sum <= x + y;
  process(clk) begin
    if(clk'event and clk='1') then
      z <= sum;
    end if;
  end process;
end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity pg_pdelay_17 is
  generic (PG_WIDTH: integer);
  port( x : in std_logic_vector(PG_WIDTH-1 downto 0);
	   y : out std_logic_vector(PG_WIDTH-1 downto 0);
	   clk : in std_logic);
end pg_pdelay_17;

architecture rtl of pg_pdelay_17 is

  signal x0 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x1 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x2 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x3 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x4 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x5 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x6 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x7 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x8 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x9 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x10 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x11 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x12 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x13 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x14 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x15 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x16 : std_logic_vector(PG_WIDTH-1 downto 0);   
  signal x17 : std_logic_vector(PG_WIDTH-1 downto 0);   

begin

  x0 <= x;

  process(clk) begin
    if(clk'event and clk='1') then
      x17 <= x16;
      x16 <= x15;
      x15 <= x14;
      x14 <= x13;
      x13 <= x12;
      x12 <= x11;
      x11 <= x10;
      x10 <= x9;
      x9 <= x8;
      x8 <= x7;
      x7 <= x6;
      x6 <= x5;
      x5 <= x4;
      x4 <= x3;
      x3 <= x2;
      x2 <= x1;
      x1 <= x0;
    end if;
  end process;

  y <= x17;

end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity pg_log_div_17_1 is
  port( x,y : in std_logic_vector(16 downto 0);
          z : out std_logic_vector(16 downto 0);
        clk : in std_logic);
end pg_log_div_17_1;

architecture rtl of pg_log_div_17_1 is

  component pg_adder_RCA_SUB_15_1
    port (x,y: in std_logic_vector(14 downto 0);
          clk: in std_logic;
          z: out std_logic_vector(14 downto 0));
  end component;

 signal addx,addy,addz: std_logic_vector(14 downto 0); 

begin

  process(clk) begin
    if(clk'event and clk='1') then
      z(16) <= x(16) xor y(16);
      z(15) <= x(15) and y(15);
    end if;
  end process;
  addx <= x(14 downto 0);
  addy <= y(14 downto 0);

  u1: pg_adder_RCA_SUB_15_1  port map(x=>addx,y=>addy,clk=>clk,z=>addz);
  z(14 downto 0) <= addz;

end rtl;

--+--------------------------------+
--| PGPG Ripple-Carry Adder        |
--|  2004/02/12 for Xilinx Devices |
--|      by Tsuyoshi Hamada        |
--+--------------------------------+
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pg_adder_RCA_SUB_15_1 is
  port(x,y : in std_logic_vector(14 downto 0);
       z : out std_logic_vector(14 downto 0);
       clk : in std_logic);
end pg_adder_RCA_SUB_15_1;

architecture rtl of pg_adder_RCA_SUB_15_1 is

  signal sum : std_logic_vector(14 downto 0);
begin
  sum <= x - y;
  process(clk) begin
    if(clk'event and clk='1') then
      z <= sum;
    end if;
  end process;
end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity pg_log_sdiv_17_1 is
  port( x,y : in std_logic_vector(16 downto 0);
          z : out std_logic_vector(16 downto 0);
        clk : in std_logic);
end pg_log_sdiv_17_1;

architecture rtl of pg_log_sdiv_17_1 is

  component pg_adder_RCA_SUB_16_1
    port (x,y: in std_logic_vector(15 downto 0);
          clk: in std_logic;
          z: out std_logic_vector(15 downto 0));
  end component;

 signal addx,addy,addz: std_logic_vector(15 downto 0);

begin

  process(clk) begin
    if(clk'event and clk='1') then
      z(16) <= x(16) xor y(16);
      z(15) <= x(15) and y(15);
    end if;
  end process;
  addx <= '0' & x(14 downto 0);
  addy <= '0' & y(14 downto 0);

  u1: pg_adder_RCA_SUB_16_1  port map(x=>addx,y=>addy,clk=>clk,z=>addz);
  with addz(15) select
    z(14 downto 0) <= "000000000000000" when '1',
    addz(14 downto 0) when others;

end rtl;

--+--------------------------------+
--| PGPG Ripple-Carry Adder        |
--|  2004/02/12 for Xilinx Devices |
--|      by Tsuyoshi Hamada        |
--+--------------------------------+
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pg_adder_RCA_SUB_16_1 is
  port(x,y : in std_logic_vector(15 downto 0);
       z : out std_logic_vector(15 downto 0);
       clk : in std_logic);
end pg_adder_RCA_SUB_16_1;

architecture rtl of pg_adder_RCA_SUB_16_1 is

  signal sum : std_logic_vector(15 downto 0);
begin
  sum <= x - y;
  process(clk) begin
    if(clk'event and clk='1') then
      z <= sum;
    end if;
  end process;
end rtl;
-- ***************************************************************
-- * PGPG LOGARITHMIC TO FIXED-POINT FORMAT CONVERTER            *
-- *  AUTHOR: Tsuyoshi Hamada                                    *
-- *  VERSION: 2.00                                              *
-- *  LAST MODIFIED AT Tue Jun 03 22:52:01 JST 2003              *
-- ***************************************************************
library ieee;
use ieee.std_logic_1164.all;

entity pg_conv_ltof_17_8_57_2 is
  port(logdata : in std_logic_vector(16 downto 0);
       fixdata : out std_logic_vector(56 downto 0);
       clk : in std_logic);
end pg_conv_ltof_17_8_57_2;

architecture rtl of pg_conv_ltof_17_8_57_2 is

  component lcell_rom_8f28_8_8_1
    port(indata : in std_logic_vector(7 downto 0);
         outdata : out std_logic_vector(7 downto 0);
         clk : in std_logic);
  end component;

  component unreg_shift_ltof_9_7_56
    port( indata : in std_logic_vector(8 downto 0);
          control : in std_logic_vector(6 downto 0);
          outdata : out std_logic_vector(55 downto 0)); 
  end component;

  signal frac1 : std_logic_vector(7 downto 0);
  signal frac2 : std_logic_vector(8 downto 0);
  signal sign1 : std_logic;
  signal sign2 : std_logic;
  signal sign3 : std_logic;
  signal sign4 : std_logic;
  signal nz1 : std_logic;
  signal exp1 : std_logic_vector(6 downto 0);
  signal fix1 : std_logic_vector(55 downto 0);

begin

  process(clk) begin
    if(clk'event and clk='1') then
      sign1 <= logdata(16);
      nz1 <= logdata(15);
      exp1 <= logdata(14 downto 8);
    end if;
  end process;

  u1: lcell_rom_8f28_8_8_1
          port map(indata=>logdata(7 downto 0),outdata=>frac1,clk=>clk);

  with nz1 select
    frac2 <= '1' & frac1 when '1',
             "000000000" when others;

  -------------------------------------------------------------------
  -- PIPELINE 3,4,5 STAGES
  u3: unreg_shift_ltof_9_7_56
            port map (indata=>frac2,control=>exp1,outdata=>fix1);
  sign4 <= sign3;
  sign3 <= sign2;
  sign2 <= sign1;
  -------------------------------------------------------------------

  process(clk) begin                
    if(clk'event and clk='1') then  
      fixdata(56) <= sign4;         
      fixdata(55 downto 0) <= fix1; 
    end if;                         
  end process;                      

end rtl;
-- Pipelined Shifter for Log to Fix Converter
-- for Xilinx Devices                        
-- Author: Tsuyoshi Hamada                   
-- Last Modified at Feb 14,2003              
                                             
library ieee;                                
use ieee.std_logic_1164.all;                 

entity unreg_shift_ltof_9_7_56 is
  port( indata : in std_logic_vector(8 downto 0);       
        control : in std_logic_vector(6 downto 0);     
        outdata : out std_logic_vector(55 downto 0));   
end unreg_shift_ltof_9_7_56;

architecture rtl of unreg_shift_ltof_9_7_56 is
                                                                    
  signal c0 : std_logic_vector(5 downto 0);
  signal c1 : std_logic_vector(5 downto 0);
  signal c2 : std_logic_vector(5 downto 0);
  signal c3 : std_logic_vector(5 downto 0);
  signal c4 : std_logic_vector(5 downto 0);
  signal c5 : std_logic_vector(5 downto 0);
  signal o0,o0d : std_logic_vector(8 downto 0);
  signal o1,o1d : std_logic_vector(9 downto 0);
  signal o2,o2d : std_logic_vector(11 downto 0);
  signal o3,o3d : std_logic_vector(15 downto 0);
  signal o4,o4d : std_logic_vector(23 downto 0);
  signal o5,o5d : std_logic_vector(39 downto 0);
  signal o6,o6d : std_logic_vector(71 downto 0);
                                                                    
begin                                                               
                                                                    
  c0 <= control(5 downto 0);
  outdata <= o6(63 downto 8);

  o0d <= indata;
  with c0(0) select
    o1 <= o0d & '0' when '1',
          '0' & o0d when others;

  with c1(1) select
    o2 <= o1d & "00" when '1',
          "00" & o1d when others;

  with c2(2) select
    o3 <= o2d & "0000" when '1',
          "0000" & o2d when others;

  with c3(3) select
    o4 <= o3d & "00000000" when '1',
          "00000000" & o3d when others;

  with c4(4) select
    o5 <= o4d & "0000000000000000" when '1',
          "0000000000000000" & o4d when others;

  with c5(5) select
    o6 <= o5d & "00000000000000000000000000000000" when '1',
          "00000000000000000000000000000000" & o5d when others;

--  process(clk) begin
--    if(clk'event and clk='1') then 
      o1d <= o1;
      c1 <= c0;
--    end if;
--  end process;

--  process(clk) begin
--    if(clk'event and clk='1') then 
      o2d <= o2;
      c2 <= c1;
--    end if;
--  end process;

--  process(clk) begin
--    if(clk'event and clk='1') then 
      o3d <= o3;
      c3 <= c2;
--    end if;
--  end process;

--  process(clk) begin
--    if(clk'event and clk='1') then 
      o4d <= o4;
      c4 <= c3;
--    end if;
--  end process;

--  process(clk) begin
--    if(clk'event and clk='1') then 
      o5d <= o5;
      c5 <= c4;
--    end if;
--  end process;

                                                                    
end rtl;                                                            
                                   
-- ROM using Lcell not ESB         
-- Author: Tsuyoshi Hamada         
-- Last Modified at May 29,2003    
-- In 8 Out 8 Stage 1 Type"8f28"
library ieee;                      
use ieee.std_logic_1164.all;       
                                   
entity lcell_rom_8f28_8_8_1 is
  port( indata : in std_logic_vector(7 downto 0);
        clk : in std_logic;
        outdata : out std_logic_vector(7 downto 0));
end lcell_rom_8f28_8_8_1;

architecture rtl of lcell_rom_8f28_8_8_1 is

  component pg_lcell
    generic (MASK : bit_vector  := X"ffff";
             FF   : integer :=0);
    port (x   : in  std_logic_vector(3 downto 0);
          z   : out std_logic;
          clk : in  std_logic);
  end component;

  signal adr0 : std_logic_vector(7 downto 0);
  signal adr1 : std_logic_vector(7 downto 0);
  signal adr2 : std_logic_vector(7 downto 0);
  signal adr3 : std_logic_vector(7 downto 0);
  signal adr4 : std_logic_vector(7 downto 0);
  signal lc_4_0 : std_logic_vector(7 downto 0);
  signal lc_4_1 : std_logic_vector(7 downto 0);
  signal lc_4_2 : std_logic_vector(7 downto 0);
  signal lc_4_3 : std_logic_vector(7 downto 0);
  signal lc_4_4 : std_logic_vector(7 downto 0);
  signal lc_4_5 : std_logic_vector(7 downto 0);
  signal lc_4_6 : std_logic_vector(7 downto 0);
  signal lc_4_7 : std_logic_vector(7 downto 0);
  signal lc_4_8 : std_logic_vector(7 downto 0);
  signal lc_4_9 : std_logic_vector(7 downto 0);
  signal lc_4_a : std_logic_vector(7 downto 0);
  signal lc_4_b : std_logic_vector(7 downto 0);
  signal lc_4_c : std_logic_vector(7 downto 0);
  signal lc_4_d : std_logic_vector(7 downto 0);
  signal lc_4_e : std_logic_vector(7 downto 0);
  signal lc_4_f : std_logic_vector(7 downto 0);
  signal lut_5_0,lc_5_0 : std_logic_vector(7 downto 0);
  signal lut_5_1,lc_5_1 : std_logic_vector(7 downto 0);
  signal lut_5_2,lc_5_2 : std_logic_vector(7 downto 0);
  signal lut_5_3,lc_5_3 : std_logic_vector(7 downto 0);
  signal lut_5_4,lc_5_4 : std_logic_vector(7 downto 0);
  signal lut_5_5,lc_5_5 : std_logic_vector(7 downto 0);
  signal lut_5_6,lc_5_6 : std_logic_vector(7 downto 0);
  signal lut_5_7,lc_5_7 : std_logic_vector(7 downto 0);
  signal lut_6_0,lc_6_0 : std_logic_vector(7 downto 0);
  signal lut_6_1,lc_6_1 : std_logic_vector(7 downto 0);
  signal lut_6_2,lc_6_2 : std_logic_vector(7 downto 0);
  signal lut_6_3,lc_6_3 : std_logic_vector(7 downto 0);
  signal lut_7_0,lc_7_0 : std_logic_vector(7 downto 0);
  signal lut_7_1,lc_7_1 : std_logic_vector(7 downto 0);
  signal lut_8_0,lc_8_0 : std_logic_vector(7 downto 0);

begin

  LC_000_00 : pg_lcell
  generic map(MASK=>X"A4B6",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(0));

  LC_000_01 : pg_lcell
  generic map(MASK=>X"C738",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(1));

  LC_000_02 : pg_lcell
  generic map(MASK=>X"07C0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(2));

  LC_000_03 : pg_lcell
  generic map(MASK=>X"F800",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(3));

--LC_000_04 
  lc_4_0(4) <= '0';

--LC_000_05 
  lc_4_0(5) <= '0';

--LC_000_06 
  lc_4_0(6) <= '0';

--LC_000_07 
  lc_4_0(7) <= '0';

  LC_001_00 : pg_lcell
  generic map(MASK=>X"2D25",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(0));

  LC_001_01 : pg_lcell
  generic map(MASK=>X"CE39",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(1));

  LC_001_02 : pg_lcell
  generic map(MASK=>X"F03E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(2));

  LC_001_03 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(3));

  LC_001_04 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(4));

--LC_001_05 
  lc_4_1(5) <= '0';

--LC_001_06 
  lc_4_1(6) <= '0';

--LC_001_07 
  lc_4_1(7) <= '0';

  LC_002_00 : pg_lcell
  generic map(MASK=>X"A5AD",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(0));

  LC_002_01 : pg_lcell
  generic map(MASK=>X"C631",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(1));

  LC_002_02 : pg_lcell
  generic map(MASK=>X"07C1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(2));

  LC_002_03 : pg_lcell
  generic map(MASK=>X"07FE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(3));

  LC_002_04 : pg_lcell
  generic map(MASK=>X"07FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(4));

  LC_002_05 : pg_lcell
  generic map(MASK=>X"F800",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(5));

--LC_002_06 
  lc_4_2(6) <= '0';

--LC_002_07 
  lc_4_2(7) <= '0';

  LC_003_00 : pg_lcell
  generic map(MASK=>X"5294",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(0));

  LC_003_01 : pg_lcell
  generic map(MASK=>X"6318",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(1));

  LC_003_02 : pg_lcell
  generic map(MASK=>X"7C1F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(2));

  LC_003_03 : pg_lcell
  generic map(MASK=>X"7FE0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(3));

  LC_003_04 : pg_lcell
  generic map(MASK=>X"8000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(4));

--LC_003_05 
  lc_4_3(5) <= '1';

--LC_003_06 
  lc_4_3(6) <= '0';

--LC_003_07 
  lc_4_3(7) <= '0';

  LC_004_00 : pg_lcell
  generic map(MASK=>X"A56A",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(0));

  LC_004_01 : pg_lcell
  generic map(MASK=>X"398C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(1));

  LC_004_02 : pg_lcell
  generic map(MASK=>X"C1F0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(2));

  LC_004_03 : pg_lcell
  generic map(MASK=>X"FE00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(3));

--LC_004_04 
  lc_4_4(4) <= '1';

--LC_004_05 
  lc_4_4(5) <= '1';

--LC_004_06 
  lc_4_4(6) <= '0';

--LC_004_07 
  lc_4_4(7) <= '0';

  LC_005_00 : pg_lcell
  generic map(MASK=>X"A55A",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(0));

  LC_005_01 : pg_lcell
  generic map(MASK=>X"C663",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(1));

  LC_005_02 : pg_lcell
  generic map(MASK=>X"0783",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(2));

  LC_005_03 : pg_lcell
  generic map(MASK=>X"F803",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(3));

  LC_005_04 : pg_lcell
  generic map(MASK=>X"0003",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(4));

  LC_005_05 : pg_lcell
  generic map(MASK=>X"0003",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(5));

  LC_005_06 : pg_lcell
  generic map(MASK=>X"FFFC",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(6));

--LC_005_07 
  lc_4_5(7) <= '0';

  LC_006_00 : pg_lcell
  generic map(MASK=>X"556A",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_6(0));

  LC_006_01 : pg_lcell
  generic map(MASK=>X"998C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_6(1));

  LC_006_02 : pg_lcell
  generic map(MASK=>X"1E0F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_6(2));

  LC_006_03 : pg_lcell
  generic map(MASK=>X"E00F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_6(3));

  LC_006_04 : pg_lcell
  generic map(MASK=>X"FFF0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_6(4));

--LC_006_05 
  lc_4_6(5) <= '0';

--LC_006_06 
  lc_4_6(6) <= '1';

--LC_006_07 
  lc_4_6(7) <= '0';

  LC_007_00 : pg_lcell
  generic map(MASK=>X"AAA5",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(0));

  LC_007_01 : pg_lcell
  generic map(MASK=>X"3339",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(1));

  LC_007_02 : pg_lcell
  generic map(MASK=>X"3C3E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(2));

  LC_007_03 : pg_lcell
  generic map(MASK=>X"C03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(3));

  LC_007_04 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(4));

  LC_007_05 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(5));

--LC_007_06 
  lc_4_7(6) <= '1';

--LC_007_07 
  lc_4_7(7) <= '0';

  LC_008_00 : pg_lcell
  generic map(MASK=>X"AAAA",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(0));

  LC_008_01 : pg_lcell
  generic map(MASK=>X"3333",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(1));

  LC_008_02 : pg_lcell
  generic map(MASK=>X"3C3C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(2));

  LC_008_03 : pg_lcell
  generic map(MASK=>X"C03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(3));

  LC_008_04 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(4));

--LC_008_05 
  lc_4_8(5) <= '1';

--LC_008_06 
  lc_4_8(6) <= '1';

--LC_008_07 
  lc_4_8(7) <= '0';

  LC_009_00 : pg_lcell
  generic map(MASK=>X"5AAA",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(0));

  LC_009_01 : pg_lcell
  generic map(MASK=>X"9333",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(1));

  LC_009_02 : pg_lcell
  generic map(MASK=>X"1C3C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(2));

  LC_009_03 : pg_lcell
  generic map(MASK=>X"E03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(3));

  LC_009_04 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(4));

  LC_009_05 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(5));

  LC_009_06 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(6));

  LC_009_07 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(7));

  LC_00A_00 : pg_lcell
  generic map(MASK=>X"AB55",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_a(0));

  LC_00A_01 : pg_lcell
  generic map(MASK=>X"CD99",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_a(1));

  LC_00A_02 : pg_lcell
  generic map(MASK=>X"0E1E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_a(2));

  LC_00A_03 : pg_lcell
  generic map(MASK=>X"F01F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_a(3));

  LC_00A_04 : pg_lcell
  generic map(MASK=>X"FFE0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_a(4));

--LC_00A_05 
  lc_4_a(5) <= '0';

--LC_00A_06 
  lc_4_a(6) <= '0';

--LC_00A_07 
  lc_4_a(7) <= '1';

  LC_00B_00 : pg_lcell
  generic map(MASK=>X"A956",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_b(0));

  LC_00B_01 : pg_lcell
  generic map(MASK=>X"3264",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_b(1));

  LC_00B_02 : pg_lcell
  generic map(MASK=>X"C387",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_b(2));

  LC_00B_03 : pg_lcell
  generic map(MASK=>X"FC07",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_b(3));

  LC_00B_04 : pg_lcell
  generic map(MASK=>X"0007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_b(4));

  LC_00B_05 : pg_lcell
  generic map(MASK=>X"FFF8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_b(5));

--LC_00B_06 
  lc_4_b(6) <= '0';

--LC_00B_07 
  lc_4_b(7) <= '1';

  LC_00C_00 : pg_lcell
  generic map(MASK=>X"5295",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(0));

  LC_00C_01 : pg_lcell
  generic map(MASK=>X"64D9",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(1));

  LC_00C_02 : pg_lcell
  generic map(MASK=>X"78E1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(2));

  LC_00C_03 : pg_lcell
  generic map(MASK=>X"7F01",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(3));

  LC_00C_04 : pg_lcell
  generic map(MASK=>X"7FFE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(4));

  LC_00C_05 : pg_lcell
  generic map(MASK=>X"7FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(5));

  LC_00C_06 : pg_lcell
  generic map(MASK=>X"8000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(6));

--LC_00C_07 
  lc_4_c(7) <= '1';

  LC_00D_00 : pg_lcell
  generic map(MASK=>X"4B4A",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(0));

  LC_00D_01 : pg_lcell
  generic map(MASK=>X"6D93",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(1));

  LC_00D_02 : pg_lcell
  generic map(MASK=>X"8E1C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(2));

  LC_00D_03 : pg_lcell
  generic map(MASK=>X"0FE0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(3));

  LC_00D_04 : pg_lcell
  generic map(MASK=>X"F000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(4));

--LC_00D_05 
  lc_4_d(5) <= '0';

--LC_00D_06 
  lc_4_d(6) <= '1';

--LC_00D_07 
  lc_4_d(7) <= '1';

  LC_00E_00 : pg_lcell
  generic map(MASK=>X"925A",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_e(0));

  LC_00E_01 : pg_lcell
  generic map(MASK=>X"2493",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_e(1));

  LC_00E_02 : pg_lcell
  generic map(MASK=>X"38E3",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_e(2));

  LC_00E_03 : pg_lcell
  generic map(MASK=>X"C0FC",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_e(3));

  LC_00E_04 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_e(4));

  LC_00E_05 : pg_lcell
  generic map(MASK=>X"FF00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_e(5));

--LC_00E_06 
  lc_4_e(6) <= '1';

--LC_00E_07 
  lc_4_e(7) <= '1';

  LC_00F_00 : pg_lcell
  generic map(MASK=>X"C924",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(0));

  LC_00F_01 : pg_lcell
  generic map(MASK=>X"9249",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(1));

  LC_00F_02 : pg_lcell
  generic map(MASK=>X"E38E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(2));

  LC_00F_03 : pg_lcell
  generic map(MASK=>X"FC0F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(3));

  LC_00F_04 : pg_lcell
  generic map(MASK=>X"FFF0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(4));

--LC_00F_05 
  lc_4_f(5) <= '1';

--LC_00F_06 
  lc_4_f(6) <= '1';

--LC_00F_07 
  lc_4_f(7) <= '1';

  adr0 <= indata;
  adr1(7 downto 4) <= adr0(7 downto 4);
  adr2(7 downto 5) <= adr1(7 downto 5);
  adr3(7 downto 6) <= adr2(7 downto 6);
  process(clk) begin
    if(clk'event and clk='1') then
      adr4(7) <= adr3(7);
    end if;
  end process;

--  =================================
  with adr1(4) select
    lut_5_0 <= lc_4_0 when '0',
              lc_4_1 when others;

  with adr1(4) select
    lut_5_1 <= lc_4_2 when '0',
              lc_4_3 when others;

  with adr1(4) select
    lut_5_2 <= lc_4_4 when '0',
              lc_4_5 when others;

  with adr1(4) select
    lut_5_3 <= lc_4_6 when '0',
              lc_4_7 when others;

  with adr1(4) select
    lut_5_4 <= lc_4_8 when '0',
              lc_4_9 when others;

  with adr1(4) select
    lut_5_5 <= lc_4_a when '0',
              lc_4_b when others;

  with adr1(4) select
    lut_5_6 <= lc_4_c when '0',
              lc_4_d when others;

  with adr1(4) select
    lut_5_7 <= lc_4_e when '0',
              lc_4_f when others;

--  =================================
  with adr2(5) select
    lut_6_0 <= lc_5_0 when '0',
              lc_5_1 when others;

  with adr2(5) select
    lut_6_1 <= lc_5_2 when '0',
              lc_5_3 when others;

  with adr2(5) select
    lut_6_2 <= lc_5_4 when '0',
              lc_5_5 when others;

  with adr2(5) select
    lut_6_3 <= lc_5_6 when '0',
              lc_5_7 when others;

--  =================================
  with adr3(6) select
    lut_7_0 <= lc_6_0 when '0',
              lc_6_1 when others;

  with adr3(6) select
    lut_7_1 <= lc_6_2 when '0',
              lc_6_3 when others;

--  =================================
  with adr4(7) select
    lut_8_0 <= lc_7_0 when '0',
              lc_7_1 when others;


--  =================================
    lc_5_0 <= lut_5_0;
    lc_5_1 <= lut_5_1;
    lc_5_2 <= lut_5_2;
    lc_5_3 <= lut_5_3;
    lc_5_4 <= lut_5_4;
    lc_5_5 <= lut_5_5;
    lc_5_6 <= lut_5_6;
    lc_5_7 <= lut_5_7;
--  =================================
    lc_6_0 <= lut_6_0;
    lc_6_1 <= lut_6_1;
    lc_6_2 <= lut_6_2;
    lc_6_3 <= lut_6_3;
--  =================================
  process(clk) begin
    if(clk'event and clk='1') then
      lc_7_0 <= lut_7_0;
      lc_7_1 <= lut_7_1;
    end if;
  end process;
--  =================================
    lc_8_0 <= lut_8_0;
  outdata <= lc_8_0;
end rtl;

-- pg_fix_accum
-- Pipelined, Virtual Multiple Pipelined Fixed-Point Accumulator for Programmable GRAPE
-- Author: Tsuyoshi Hamada
-- Last Modified at May 9 13:33:33
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pg_fix_accum_57_64_3 is
  port (fdata: in std_logic_vector(56 downto 0);
        sdata: out std_logic_vector(63 downto 0);
        run : in std_logic;
        clk : in std_logic);
end pg_fix_accum_57_64_3;

architecture rtl of pg_fix_accum_57_64_3 is

  component fix_accum_reg_1
    generic (WIDTH: integer);
    port (indata: in std_logic_vector(WIDTH-1 downto 0);
          cin : in std_logic;
          run : in std_logic;
          addsub : in std_logic;
          addsubd : out std_logic;
          rund : out std_logic;
          cout : out std_logic;
          reg0 : out std_logic_vector(WIDTH-1 downto 0);
          clk : in std_logic);
  end component;

  component fix_accum_reg_last_1
    generic (WIDTH: integer);
    port (indata: in std_logic_vector(WIDTH-1 downto 0);
          cin : in std_logic;
          run : in std_logic;
          addsub : in std_logic;
--        countd : out std_logic_vector(-1 downto 0);
--        addsubd : out std_logic;
--        rund : out std_logic;
--        cout : out std_logic;
          reg0 : out std_logic_vector(WIDTH-1 downto 0);
          clk : in std_logic);
  end component;

  signal fx: std_logic_vector(63 downto 0);
  signal fx_0_0: std_logic_vector(20 downto 0);
  signal fx_1_0: std_logic_vector(21 downto 0);
  signal fx_1_1: std_logic_vector(21 downto 0);
  signal fx_2_0: std_logic_vector(20 downto 0);
  signal fx_2_1: std_logic_vector(20 downto 0);
  signal fx_2_2: std_logic_vector(20 downto 0);
  signal rsig : std_logic_vector(2 downto 0);
  signal addsub : std_logic_vector(2 downto 0);
  signal carry : std_logic_vector(2 downto 0);

begin

  fx <= "00000000" & fdata(55 downto 0);

  fx_0_0 <= fx(20 downto 0);
  fx_1_0 <= fx(42 downto 21);
  fx_2_0 <= fx(63 downto 43);
  addsub(0) <= not fdata(56);
  carry(0) <= fdata(56);
  rsig(0)  <= run;


  process(clk) begin              
    if(clk'event and clk='1') then
      fx_1_1 <= fx_1_0;       
    end if;                       
  end process;                    

  process(clk) begin              
    if(clk'event and clk='1') then
      fx_2_1 <= fx_2_0;       
    end if;                       
  end process;                    

  process(clk) begin              
    if(clk'event and clk='1') then
      fx_2_2 <= fx_2_1;       
    end if;                       
  end process;                    

  u0: fix_accum_reg_1             
    generic map(WIDTH=>21)                
    port map(indata=>fx_0_0,            
             cin=>'0',                
             run=>rsig(0),               
             addsub=>addsub(0),          
             addsubd=>addsub(1),       
             rund=>rsig(1),            
             cout=>carry(1),           
             reg0=>sdata(20 downto 0),
             clk=>clk);                   
                                          
  u1: fix_accum_reg_1             
    generic map(WIDTH=>22)                
    port map(indata=>fx_1_1,            
             cin=>carry(1),              
             run=>rsig(1),               
             addsub=>addsub(1),          
             addsubd=>addsub(2),       
             rund=>rsig(2),            
             cout=>carry(2),           
             reg0=>sdata(42 downto 21),
             clk=>clk);                   
                                          
  u2: fix_accum_reg_last_1        
    generic map(WIDTH=>21)                
    port map(indata=>fx_2_2,            
             cin=>carry(2),              
             run=>rsig(2),               
             addsub=>addsub(2),          
--           countd=>count3,           
--           addsubd=>addsub(3),       
--           rund=>rsig(3),            
--           cout=>carry(3),           
             reg0=>sdata(63 downto 43),
             clk=>clk);                   
                                          
end rtl;                                                            
                                                                    
library ieee;                                                       
use ieee.std_logic_1164.all;                                        
use ieee.std_logic_arith.all;                                        
use ieee.std_logic_unsigned.all;                                    
                                                                    
entity fix_accum_reg_1 is
  generic(WIDTH: integer := 28);                                    
  port(indata : in std_logic_vector(WIDTH-1 downto 0);              
       cin : in std_logic;     
       run : in std_logic;     
       addsub : in std_logic;  
       addsubd : out std_logic;
       rund : out std_logic;   
       cout : out std_logic;   
       reg0 : out std_logic_vector(WIDTH-1 downto 0);
       clk : in std_logic);    
end fix_accum_reg_1;
                                                                    
architecture rtl of fix_accum_reg_1 is                                           
                                                                    
                                                                    
signal sum : std_logic_vector(WIDTH downto 0);
signal zeros : std_logic_vector(WIDTH-1 downto 0);
signal sx : std_logic_vector(WIDTH-1 downto 0);                     
signal zero : std_logic_vector(WIDTH-1 downto 0);                   
signal addout : std_logic_vector(WIDTH-1 downto 0);                 
signal run1 : std_logic;                                            
signal cout0 : std_logic;                                         
signal reg_vmp0 : std_logic_vector(WIDTH-1 downto 0);            

begin                                                               

  forgen1 : for i in 0 to WIDTH-1 generate
    zero(i) <= '0';                       
  end generate;                           

  process(clk) begin                                              
    if(clk'event and clk='1') then                                
      if(run1 = '1') then                                         
        reg_vmp0 <= addout;                                       
      else                                                        
        if(run = '1') then                                        
          reg_vmp0 <= zero;                                       
        end if;                                                   
      end if;                                                     
    end if;                                                       
  end process;                                                    
  reg0 <= reg_vmp0;                                               

    sx <= reg_vmp0;

  forgen2 : for i in 0 to WIDTH-1 generate
    zeros(i) <= '0';                      
  end generate;                           

  process(sx,cin,addsub,indata) begin
    if(addsub='1') then
      sum <= ('0'&sx)+('0'&indata)+(zeros&cin);
    else
      sum <= ('0'&sx)-('0'&indata)-(zeros&cin);
    end if;
  end process;
  addout <= sum(WIDTH-1 downto 0);
  cout0  <= sum(WIDTH);

  process(clk) begin              
    if(clk'event and clk='1') then
      run1 <= run;                
    end if;                       
  end process;                    

  process(clk) begin              
    if(clk'event and clk='1') then
      addsubd <= addsub;          
      cout <= cout0;              
    end if;                       
  end process;                    

  rund <= run1;

end rtl;                            
                                    
                                                                    
library ieee;                                                       
use ieee.std_logic_1164.all;                                        
use ieee.std_logic_arith.all;                                        
use ieee.std_logic_unsigned.all;                                    
                                                                    
entity fix_accum_reg_last_1 is
  generic(WIDTH: integer := 28);                                    
  port(indata : in std_logic_vector(WIDTH-1 downto 0);              
       cin : in std_logic;     
       run : in std_logic;     
       addsub : in std_logic;  
--     countd : out std_logic_vector(-1 downto 0);
--     addsubd : out std_logic;
--     rund : out std_logic;   
--     cout : out std_logic;   
       reg0 : out std_logic_vector(WIDTH-1 downto 0);
       clk : in std_logic);    
end fix_accum_reg_last_1;
                                                                    
architecture rtl of fix_accum_reg_last_1 is                                           
                                                                    
                                                                    
signal sum : std_logic_vector(WIDTH-1 downto 0);
signal zeros : std_logic_vector(WIDTH-2 downto 0);
signal sx : std_logic_vector(WIDTH-1 downto 0);                     
signal zero : std_logic_vector(WIDTH-1 downto 0);                   
signal addout : std_logic_vector(WIDTH-1 downto 0);                 
signal run1 : std_logic;                                            
--signal cout0 : std_logic;                                       
signal reg_vmp0 : std_logic_vector(WIDTH-1 downto 0);            

begin                                                               

  forgen1 : for i in 0 to WIDTH-1 generate
    zero(i) <= '0';                       
  end generate;                           

  process(clk) begin                                              
    if(clk'event and clk='1') then                                
      if(run1 = '1') then                                         
        reg_vmp0 <= addout;                                       
      else                                                        
        if(run = '1') then                                        
          reg_vmp0 <= zero;                                       
        end if;                                                   
      end if;                                                     
    end if;                                                       
  end process;                                                    
  reg0 <= reg_vmp0;                                               

    sx <= reg_vmp0;

  forgen2 : for i in 0 to WIDTH-2 generate
    zeros(i) <= '0';                      
  end generate;                           

  process(sx,cin,addsub,indata) begin
    if(addsub='1') then
      sum <= sx+indata+(zeros&cin);
    else
      sum <= sx-indata-(zeros&cin);
    end if;
  end process;
  addout <= sum;

  process(clk) begin              
    if(clk'event and clk='1') then
      run1 <= run;                
    end if;                       
  end process;                    

--process(clk) begin              
--  if(clk'event and clk='1') then
--    addsubd <= addsub;          
--    cout <= cout0;              
--    countd <= count;            
--  end if;                       
--end process;                    

--rund <= run1;

end rtl;                            
                                    

--+-------------------------------+
--| PG_LCELL/PG_LCELL_ARI         |
--| For Xilinx Devices            |
--| Multidevice Logic Cell Module |.GKey:hYj8zgUkjgdkfhB3ozXM
--| 2004/02/06                    |
--|            by Tsuyoshi Hamada |
--+-------------------------------+
--+-------------+----------+
--| x3,x2,x1,x0 |    z     |
--+-------------+----------+
--|  0, 0, 0, 0 | MASK(0)  |
--|  0, 0, 0, 1 | MASK(1)  |
--|  0, 0, 1, 0 | MASK(2)  |
--|  0, 0, 1, 1 | MASK(3)  |
--|  0, 1, 0, 0 | MASK(4)  |
--|  0, 1, 0, 1 | MASK(5)  |
--|  .......... | .......  |
--|  1, 1, 1, 1 | MASK(16) |
--+-------------+----------+
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY UNISIM;
USE UNISIM.Vcomponents.ALL;
entity pg_lcell is
  generic(MASK: bit_vector  := X"ffff";
            FF: integer := 0);
    port(x : in std_logic_vector(3 downto 0);
         z : out std_logic;
         clk : in std_logic);
end pg_lcell;

architecture schematic of pg_lcell is
   ATTRIBUTE BOX_TYPE : STRING;
   ATTRIBUTE INIT : STRING ;
   COMPONENT LUT4
   GENERIC( INIT : BIT_VECTOR := X"0000");
      PORT ( I0	:	IN	STD_LOGIC;
             I1	:	IN	STD_LOGIC;
             I2	:	IN	STD_LOGIC;
             I3	:	IN	STD_LOGIC;
             O	:	OUT	STD_LOGIC);
   END COMPONENT;
   ATTRIBUTE BOX_TYPE OF LUT4 : COMPONENT IS "BLACK_BOX";

   signal z0 : std_logic;

BEGIN

   xlcell : LUT4 GENERIC MAP (INIT => MASK)
      PORT MAP (I0=>x(0), I1=>x(1), I2=>x(2), I3=>x(3), O=>z0);

-- unreged output
ifgen0: if (FF=0) generate
  z <= z0;
end generate;

-- reged output
ifgen1: if (FF>0) generate
  process(clk) begin
    if(clk'event and clk='1') then
      z <= z0;
    end if;
  end process;
end generate;

end schematic;

