--
-- pgpg1.0 by Hamada Tsuyoshi 
-- Generated from 'list.g5.bio3.cpp'
-- NPIPE : 1
-- NVMP  : 1
library ieee;                                                  
use ieee.std_logic_1164.all;                                   
                                                               
entity pg_pipe is                                              
  generic(JDATA_WIDTH : integer := 113);                        
  port(                                                        
    p_jdata : in std_logic_vector(JDATA_WIDTH-1 downto 0);     
    p_run : in std_logic;                                      
    p_we :  in std_logic;                                      
    p_adri : in std_logic_vector(11 downto 0);                 
    p_datai : in std_logic_vector(31 downto 0);                
    p_adro : in std_logic_vector(11 downto 0);                 
    p_datao : out std_logic_vector(31 downto 0);               
    p_runret : out std_logic;                                  
    rst,clk : in std_logic                                     
  );                                                           
end pg_pipe;                                                   
                                                               
architecture std of pg_pipe is                                 
                                                               
  component pipe                                               
    generic(JDATA_WIDTH : integer );                           
    port(                                                      
      p_jdata: in std_logic_vector(JDATA_WIDTH-1 downto 0);    
      p_run : in std_logic;                                    
      p_we : in std_logic;                                     
      p_adri : in std_logic_vector(3 downto 0);                
      p_adrivp : in std_logic_vector(3 downto 0);              
      p_datai : in std_logic_vector(31 downto 0);              
      p_adro : in std_logic_vector(3 downto 0);                
      p_adrovp : in std_logic_vector(3 downto 0);              
      p_datao : out std_logic_vector(31 downto 0);             
      p_runret : out std_logic;                                
      rst,pclk : in std_logic );                                
  end component;                                               
                                                               
  signal u_adri,u_adro: std_logic_vector(7 downto 0);          
  signal adrivp,adrovp: std_logic_vector(3 downto 0);          
  signal we,runret: std_logic_vector(0 downto 0);
  signal datao: std_logic_vector(31 downto 0);
  signal l_adro: std_logic_vector(3 downto 0);                 
                                                               
begin                                                          
                                                               
  u_adri <= p_adri(11 downto 4);                               
                                                               
  u_adro <= p_adro(11 downto 4);                               
  l_adro <= p_adro(3 downto 0);                                
                                                               
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00000000" ) then
        we(0) <= '1';                                    
      else                                                   
        we(0) <= '0';                                    
      end if;                                                
    else                                                     
      we(0) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  with u_adri select                                           
    adrivp <= "0000" when "00000000", 
              "0000" when others;                            
                                                               
  with u_adro select                                           
    adrovp <= "0000" when "00000000", 
              "0000" when others;                            
                                                               
  forgen1: for i in 0 to 0 generate           
    upipe: pipe GENERIC MAP(JDATA_WIDTH=>JDATA_WIDTH)          
	      PORT MAP(p_jdata=>p_jdata, p_run=>p_run,               
                 p_we=>we(i),p_adri=>p_adri(3 downto 0),p_adrivp=>adrivp,
	               p_datai=>p_datai,p_adro=>l_adro,p_adrovp=>adrovp, 
	               p_datao=>datao(32*(i+1)-1 downto 32*i), p_runret=>runret(i), 
		       rst=>rst,pclk=>clk);                           
  end generate forgen1;                                        
                                                               
  p_runret <= runret(0);                                       
                                                               
  with u_adro select                                           
    p_datao <= datao(31 downto 0) when "00000000", 
               datao(31 downto 0) when others;                  
                                                               
end std;                                               

library ieee;                                                       
use ieee.std_logic_1164.all;                                        
                                                                    
entity pipe is                                                      
  generic(JDATA_WIDTH : integer :=72);
port(p_jdata : in std_logic_vector(JDATA_WIDTH-1 downto 0);         
     p_run : in std_logic;                                          
     p_we :  in std_logic;                                          
     p_adri : in std_logic_vector(3 downto 0);                      
     p_adrivp : in std_logic_vector(3 downto 0);                    
     p_datai : in std_logic_vector(31 downto 0);                    
     p_adro : in std_logic_vector(3 downto 0);                      
     p_adrovp : in std_logic_vector(3 downto 0);                    
     p_datao : out std_logic_vector(31 downto 0);                   
     p_runret : out std_logic;                                      
     rst,pclk : in std_logic);                                      
end pipe;                                                           
                                                                    
architecture std of pipe is                                         
                                                                    
  component pg_conv_ftol_32_17_8_4
    port(fixdata : in std_logic_vector(31 downto 0);
         logdata : out std_logic_vector(16 downto 0);
         clk : in std_logic);
  end component;

  signal xij: std_logic_vector(31 downto 0);
                                                                    
begin                                                               
                                                                    
  fx_ofst(16 downto 0) <= "01001011100000000";
  fy_ofst(16 downto 0) <= "01001011100000000";
  fz_ofst(16 downto 0) <= "01001011100000000";

  xj(31 downto 0) <= p_jdata(31 downto 0);
  yj(31 downto 0) <= p_jdata(63 downto 32);
  zj(31 downto 0) <= p_jdata(95 downto 64);
  mj(16 downto 0) <= p_jdata(112 downto 96);

  process(pclk) begin
    if(pclk'event and pclk='1') then
      if(p_we ='1') then
        if(p_adri = "0000") then
          xi <=  p_datai(31 downto 0);
        elsif(p_adri = "0001") then
          yi <=  p_datai(31 downto 0);
        elsif(p_adri = "0010") then
          zi <=  p_datai(31 downto 0);
        elsif(p_adri = "0011") then
          ieps2 <=  p_datai(16 downto 0);
        end if;
      end if;
    end if;
  end process;

  u0: pg_conv_ftol_32_17_8_4 port map (fixdata=>xij,logdata=>dx,clk=>pclk);

  process(pclk) begin
    if(pclk'event and pclk='1') then
      if(p_adro = "0000") then
        p_datao <=  sx(31 downto 0);
      elsif(p_adro = "0001") then
        p_datao <=  sx(63 downto 32);
      elsif(p_adro = "0010") then
        p_datao <=  sy(31 downto 0);
      elsif(p_adro = "0011") then
        p_datao <=  sy(63 downto 32);
      elsif(p_adro = "0100") then
        p_datao <=  sz(31 downto 0);
      elsif(p_adro = "0101") then
        p_datao <=  sz(63 downto 32);
      else
        p_datao <= "00000000000000000000000000000000";
      end if;
    end if;
  end process;

end std;                                                            
                                                                    
