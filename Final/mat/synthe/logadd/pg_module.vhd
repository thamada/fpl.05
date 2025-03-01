                                                                   
-- *************************************************************** 
-- * PGPG UNSIGNED LOGARITHMIC ADDER MODULE                      * 
-- *  AUTHOR: Tsuyoshi Hamada                                    * 
-- *  VERSION: 3.00                                              * 
-- *  LAST MODIFIED AT Tue Jun 03 10:52:01 JST 2003              * 
-- *************************************************************** 
library ieee;
use ieee.std_logic_1164.all;

entity pg_log_unsigned_add_14_5_3 is
  port( x,y : in std_logic_vector(13 downto 0);
        z : out std_logic_vector(13 downto 0);
        clock : in std_logic);
end pg_log_unsigned_add_14_5_3;

architecture rtl of pg_log_unsigned_add_14_5_3 is

  component pg_adder_RCA_SUB_14_0
    port (x,y: in std_logic_vector(13 downto 0);
          clk: in std_logic;
          z: out std_logic_vector(13 downto 0));
  end component;

  component pg_adder_RCA_ADD_13_0
    port (x,y: in std_logic_vector(12 downto 0);
          clk: in std_logic;
          z: out std_logic_vector(12 downto 0));
  end component;

  component lcell_rom_98a0_8_5_1                      
   port (indata: in std_logic_vector(7 downto 0);    
         clk: in std_logic;                           
         outdata: out std_logic_vector(4 downto 0)); 
  end component;                                    

  signal x1,y1,xy,yx : std_logic_vector(13 downto 0);  
  signal x2,x3,x4 : std_logic_vector(12 downto 0);     
  signal d0,d1,d4 : std_logic_vector(12 downto 0);     
  signal df0,df1 : std_logic;                                      
  signal z0 : std_logic_vector(12 downto 0);           
  signal d2r_msb : std_logic;                         
  signal d2 : std_logic_vector(5 downto 0);          
  signal sign0,sign1,sign2 : std_logic;                            
  signal signxy : std_logic_vector(1 downto 0);                    
                                                                   
begin                                                              
                                                                   
  x1 <= '0' & x(12 downto 0);                          
  y1 <= '0' & y(12 downto 0);                          
  u1: pg_adder_RCA_SUB_14_0
       port map(x=>x1,y=>y1,z=>xy,clk=>clock);
  u2: pg_adder_RCA_SUB_14_0
       port map(x=>y1,y=>x1,z=>yx,clk=>clock);

  x2 <= x(12 downto 0) when yx(13)='1' else y(12 downto 0);
  d0 <= xy(12 downto 0) when yx(13)='1' else yx(12 downto 0);
                                                                   
  signxy <= x(13)&y(13);                    
  with signxy select                                               
    sign0 <= y(13) when "01",                        
             x(13) when others;                        
                                                                   
  process(clock) begin                                             
    if(clock'event and clock='1') then                             
      x3 <= x2;                                                    
      d1 <= d0;                                                    
      sign1 <= sign0;                                              
    end if;                                                        
  end process;                                                     
                                                                   
  df0 <= '1' when d1(12 downto 8)="00000" else '0';
  
  -- ALL OR -> NOT (PLUS) --
  d2r_msb <= '1' when d1(7 downto 0)="00000000" else '0';

  u3: lcell_rom_98a0_8_5_1
            port map(indata=>d1(7 downto 0),outdata=>d2(4 downto 0),clk=>clock);
                                                                   
  process(clock) begin                                             
    if(clock'event and clock='1') then                             
      df1 <= df0;                                                  
      x4 <= x3;                                                    
      d2(5) <= d2r_msb;                                           
      sign2 <= sign1;                                              
    end if;                                                        
  end process;                                                     
                                                                   
  d4(5 downto 0) <= d2 when (df1 = '1') else "000000";
  d4(12 downto 6) <= "0000000";           
                                                                   
  u4: pg_adder_RCA_ADD_13_0
       port map(x=>x4,y=>d4,z=>z0,clk=>clock);

  process(clock) begin                                             
    if(clock'event and clock='1') then                             
      z(12 downto 0) <= z0;                            
      z(13) <= sign2;                                  
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

entity pg_adder_RCA_SUB_14_0 is
  port(x,y : in std_logic_vector(13 downto 0);
       z : out std_logic_vector(13 downto 0);
       clk : in std_logic);
end pg_adder_RCA_SUB_14_0;

architecture rtl of pg_adder_RCA_SUB_14_0 is

  signal sum : std_logic_vector(13 downto 0);
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

entity pg_adder_RCA_ADD_13_0 is
  port(x,y : in std_logic_vector(12 downto 0);
       z : out std_logic_vector(12 downto 0);
       clk : in std_logic);
end pg_adder_RCA_ADD_13_0;

architecture rtl of pg_adder_RCA_ADD_13_0 is

  signal sum : std_logic_vector(12 downto 0);
begin
  sum <= x + y;
  z <= sum;
end rtl;
                                   
-- ROM using Lcell not ESB         
-- Author: Tsuyoshi Hamada         
-- Last Modified at May 29,2003    
-- In 8 Out 5 Stage 1 Type"98a0"
library ieee;                      
use ieee.std_logic_1164.all;       
                                   
entity lcell_rom_98a0_8_5_1 is
  port( indata : in std_logic_vector(7 downto 0);
        clk : in std_logic;
        outdata : out std_logic_vector(4 downto 0));
end lcell_rom_98a0_8_5_1;

architecture rtl of lcell_rom_98a0_8_5_1 is

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
  signal lc_4_0 : std_logic_vector(4 downto 0);
  signal lc_4_1 : std_logic_vector(4 downto 0);
  signal lc_4_2 : std_logic_vector(4 downto 0);
  signal lc_4_3 : std_logic_vector(4 downto 0);
  signal lc_4_4 : std_logic_vector(4 downto 0);
  signal lc_4_5 : std_logic_vector(4 downto 0);
  signal lc_4_6 : std_logic_vector(4 downto 0);
  signal lc_4_7 : std_logic_vector(4 downto 0);
  signal lc_4_8 : std_logic_vector(4 downto 0);
  signal lc_4_9 : std_logic_vector(4 downto 0);
  signal lc_4_a : std_logic_vector(4 downto 0);
  signal lc_4_b : std_logic_vector(4 downto 0);
  signal lc_4_c : std_logic_vector(4 downto 0);
  signal lc_4_d : std_logic_vector(4 downto 0);
  signal lc_4_e : std_logic_vector(4 downto 0);
  signal lc_4_f : std_logic_vector(4 downto 0);
  signal lut_5_0,lc_5_0 : std_logic_vector(4 downto 0);
  signal lut_5_1,lc_5_1 : std_logic_vector(4 downto 0);
  signal lut_5_2,lc_5_2 : std_logic_vector(4 downto 0);
  signal lut_5_3,lc_5_3 : std_logic_vector(4 downto 0);
  signal lut_5_4,lc_5_4 : std_logic_vector(4 downto 0);
  signal lut_5_5,lc_5_5 : std_logic_vector(4 downto 0);
  signal lut_5_6,lc_5_6 : std_logic_vector(4 downto 0);
  signal lut_5_7,lc_5_7 : std_logic_vector(4 downto 0);
  signal lut_6_0,lc_6_0 : std_logic_vector(4 downto 0);
  signal lut_6_1,lc_6_1 : std_logic_vector(4 downto 0);
  signal lut_6_2,lc_6_2 : std_logic_vector(4 downto 0);
  signal lut_6_3,lc_6_3 : std_logic_vector(4 downto 0);
  signal lut_7_0,lc_7_0 : std_logic_vector(4 downto 0);
  signal lut_7_1,lc_7_1 : std_logic_vector(4 downto 0);
  signal lut_8_0,lc_8_0 : std_logic_vector(4 downto 0);

begin

  LC_000_00 : pg_lcell
  generic map(MASK=>X"CCE6",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(0));

  LC_000_01 : pg_lcell
  generic map(MASK=>X"3C1E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(1));

  LC_000_02 : pg_lcell
  generic map(MASK=>X"03FE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(2));

  LC_000_03 : pg_lcell
  generic map(MASK=>X"FFFE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(3));

  LC_000_04 : pg_lcell
  generic map(MASK=>X"FFFE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(4));

  LC_001_00 : pg_lcell
  generic map(MASK=>X"C739",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(0));

  LC_001_01 : pg_lcell
  generic map(MASK=>X"C0F8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(1));

  LC_001_02 : pg_lcell
  generic map(MASK=>X"3FF8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(2));

  LC_001_03 : pg_lcell
  generic map(MASK=>X"0007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(3));

--LC_001_04 
  lc_4_1(4) <= '1';

  LC_002_00 : pg_lcell
  generic map(MASK=>X"3871",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(0));

  LC_002_01 : pg_lcell
  generic map(MASK=>X"F80F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(1));

  LC_002_02 : pg_lcell
  generic map(MASK=>X"F800",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(2));

  LC_002_03 : pg_lcell
  generic map(MASK=>X"F800",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(3));

  LC_002_04 : pg_lcell
  generic map(MASK=>X"07FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(4));

  LC_003_00 : pg_lcell
  generic map(MASK=>X"783C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(0));

  LC_003_01 : pg_lcell
  generic map(MASK=>X"F803",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(1));

  LC_003_02 : pg_lcell
  generic map(MASK=>X"07FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(2));

--LC_003_03 
  lc_4_3(3) <= '1';

--LC_003_04 
  lc_4_3(4) <= '0';

  LC_004_00 : pg_lcell
  generic map(MASK=>X"03F0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(0));

  LC_004_01 : pg_lcell
  generic map(MASK=>X"000F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(1));

--LC_004_02 
  lc_4_4(2) <= '0';

--LC_004_03 
  lc_4_4(3) <= '1';

--LC_004_04 
  lc_4_4(4) <= '0';

  LC_005_00 : pg_lcell
  generic map(MASK=>X"007F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(0));

--LC_005_01 
  lc_4_5(1) <= '1';

--LC_005_02 
  lc_4_5(2) <= '1';

--LC_005_03 
  lc_4_5(3) <= '0';

--LC_005_04 
  lc_4_5(4) <= '0';

  LC_006_00 : pg_lcell
  generic map(MASK=>X"01FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_6(0));

--LC_006_01 
  lc_4_6(1) <= '0';

--LC_006_02 
  lc_4_6(2) <= '1';

--LC_006_03 
  lc_4_6(3) <= '0';

--LC_006_04 
  lc_4_6(4) <= '0';

  LC_007_00 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(0));

  LC_007_01 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(1));

  LC_007_02 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(2));

--LC_007_03 
  lc_4_7(3) <= '0';

--LC_007_04 
  lc_4_7(4) <= '0';

  LC_008_00 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(0));

--LC_008_01 
  lc_4_8(1) <= '1';

--LC_008_02 
  lc_4_8(2) <= '0';

--LC_008_03 
  lc_4_8(3) <= '0';

--LC_008_04 
  lc_4_8(4) <= '0';

  LC_009_00 : pg_lcell
  generic map(MASK=>X"C000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(0));

  LC_009_01 : pg_lcell
  generic map(MASK=>X"3FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(1));

--LC_009_02 
  lc_4_9(2) <= '0';

--LC_009_03 
  lc_4_9(3) <= '0';

--LC_009_04 
  lc_4_9(4) <= '0';

--LC_00A_00 
  lc_4_a(0) <= '1';

--LC_00A_01 
  lc_4_a(1) <= '0';

--LC_00A_02 
  lc_4_a(2) <= '0';

--LC_00A_03 
  lc_4_a(3) <= '0';

--LC_00A_04 
  lc_4_a(4) <= '0';

--LC_00B_00 
  lc_4_b(0) <= '1';

--LC_00B_01 
  lc_4_b(1) <= '0';

--LC_00B_02 
  lc_4_b(2) <= '0';

--LC_00B_03 
  lc_4_b(3) <= '0';

--LC_00B_04 
  lc_4_b(4) <= '0';

--LC_00C_00 
  lc_4_c(0) <= '1';

--LC_00C_01 
  lc_4_c(1) <= '0';

--LC_00C_02 
  lc_4_c(2) <= '0';

--LC_00C_03 
  lc_4_c(3) <= '0';

--LC_00C_04 
  lc_4_c(4) <= '0';

  LC_00D_00 : pg_lcell
  generic map(MASK=>X"0001",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(0));

--LC_00D_01 
  lc_4_d(1) <= '0';

--LC_00D_02 
  lc_4_d(2) <= '0';

--LC_00D_03 
  lc_4_d(3) <= '0';

--LC_00D_04 
  lc_4_d(4) <= '0';

--LC_00E_00 
  lc_4_e(0) <= '0';

--LC_00E_01 
  lc_4_e(1) <= '0';

--LC_00E_02 
  lc_4_e(2) <= '0';

--LC_00E_03 
  lc_4_e(3) <= '0';

--LC_00E_04 
  lc_4_e(4) <= '0';

--LC_00F_00 
  lc_4_f(0) <= '0';

--LC_00F_01 
  lc_4_f(1) <= '0';

--LC_00F_02 
  lc_4_f(2) <= '0';

--LC_00F_03 
  lc_4_f(3) <= '0';

--LC_00F_04 
  lc_4_f(4) <= '0';

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

