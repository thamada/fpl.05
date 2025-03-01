--
-- pgpg1.0 by Hamada Tsuyoshi 
-- Generated from 'list.22.cpp'
-- NPIPE : 19
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
  signal we,runret: std_logic_vector(18 downto 0);
  signal datao: std_logic_vector(607 downto 0);
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
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00000001" ) then
        we(1) <= '1';                                    
      else                                                   
        we(1) <= '0';                                    
      end if;                                                
    else                                                     
      we(1) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00000010" ) then
        we(2) <= '1';                                    
      else                                                   
        we(2) <= '0';                                    
      end if;                                                
    else                                                     
      we(2) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00000011" ) then
        we(3) <= '1';                                    
      else                                                   
        we(3) <= '0';                                    
      end if;                                                
    else                                                     
      we(3) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00000100" ) then
        we(4) <= '1';                                    
      else                                                   
        we(4) <= '0';                                    
      end if;                                                
    else                                                     
      we(4) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00000101" ) then
        we(5) <= '1';                                    
      else                                                   
        we(5) <= '0';                                    
      end if;                                                
    else                                                     
      we(5) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00000110" ) then
        we(6) <= '1';                                    
      else                                                   
        we(6) <= '0';                                    
      end if;                                                
    else                                                     
      we(6) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00000111" ) then
        we(7) <= '1';                                    
      else                                                   
        we(7) <= '0';                                    
      end if;                                                
    else                                                     
      we(7) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00001000" ) then
        we(8) <= '1';                                    
      else                                                   
        we(8) <= '0';                                    
      end if;                                                
    else                                                     
      we(8) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00001001" ) then
        we(9) <= '1';                                    
      else                                                   
        we(9) <= '0';                                    
      end if;                                                
    else                                                     
      we(9) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00001010" ) then
        we(10) <= '1';                                    
      else                                                   
        we(10) <= '0';                                    
      end if;                                                
    else                                                     
      we(10) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00001011" ) then
        we(11) <= '1';                                    
      else                                                   
        we(11) <= '0';                                    
      end if;                                                
    else                                                     
      we(11) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00001100" ) then
        we(12) <= '1';                                    
      else                                                   
        we(12) <= '0';                                    
      end if;                                                
    else                                                     
      we(12) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00001101" ) then
        we(13) <= '1';                                    
      else                                                   
        we(13) <= '0';                                    
      end if;                                                
    else                                                     
      we(13) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00001110" ) then
        we(14) <= '1';                                    
      else                                                   
        we(14) <= '0';                                    
      end if;                                                
    else                                                     
      we(14) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00001111" ) then
        we(15) <= '1';                                    
      else                                                   
        we(15) <= '0';                                    
      end if;                                                
    else                                                     
      we(15) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00010000" ) then
        we(16) <= '1';                                    
      else                                                   
        we(16) <= '0';                                    
      end if;                                                
    else                                                     
      we(16) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00010001" ) then
        we(17) <= '1';                                    
      else                                                   
        we(17) <= '0';                                    
      end if;                                                
    else                                                     
      we(17) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  process(u_adri,p_we) begin                                 
    if(p_we = '1') then                                      
     if(u_adri = "00010010" ) then
        we(18) <= '1';                                    
      else                                                   
        we(18) <= '0';                                    
      end if;                                                
    else                                                     
      we(18) <= '0';                                      
    end if;                                                  
  end process;                                               
                                                             
  with u_adri select                                           
    adrivp <= "0000" when "00000000", 
              "0000" when "00000001", 
              "0000" when "00000010", 
              "0000" when "00000011", 
              "0000" when "00000100", 
              "0000" when "00000101", 
              "0000" when "00000110", 
              "0000" when "00000111", 
              "0000" when "00001000", 
              "0000" when "00001001", 
              "0000" when "00001010", 
              "0000" when "00001011", 
              "0000" when "00001100", 
              "0000" when "00001101", 
              "0000" when "00001110", 
              "0000" when "00001111", 
              "0000" when "00010000", 
              "0000" when "00010001", 
              "0000" when "00010010", 
              "0000" when others;                            
                                                               
  with u_adro select                                           
    adrovp <= "0000" when "00000000", 
              "0000" when "00000001", 
              "0000" when "00000010", 
              "0000" when "00000011", 
              "0000" when "00000100", 
              "0000" when "00000101", 
              "0000" when "00000110", 
              "0000" when "00000111", 
              "0000" when "00001000", 
              "0000" when "00001001", 
              "0000" when "00001010", 
              "0000" when "00001011", 
              "0000" when "00001100", 
              "0000" when "00001101", 
              "0000" when "00001110", 
              "0000" when "00001111", 
              "0000" when "00010000", 
              "0000" when "00010001", 
              "0000" when "00010010", 
              "0000" when others;                            
                                                               
  forgen1: for i in 0 to 18 generate           
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
               datao(63 downto 32) when "00000001", 
               datao(95 downto 64) when "00000010", 
               datao(127 downto 96) when "00000011", 
               datao(159 downto 128) when "00000100", 
               datao(191 downto 160) when "00000101", 
               datao(223 downto 192) when "00000110", 
               datao(255 downto 224) when "00000111", 
               datao(287 downto 256) when "00001000", 
               datao(319 downto 288) when "00001001", 
               datao(351 downto 320) when "00001010", 
               datao(383 downto 352) when "00001011", 
               datao(415 downto 384) when "00001100", 
               datao(447 downto 416) when "00001101", 
               datao(479 downto 448) when "00001110", 
               datao(511 downto 480) when "00001111", 
               datao(543 downto 512) when "00010000", 
               datao(575 downto 544) when "00010001", 
               datao(607 downto 576) when "00010010", 
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
                                                                    
  component pg_fix_sub_32_1
    port(x,y : in std_logic_vector(31 downto 0);
         z : out std_logic_vector(31 downto 0);
         clk : in std_logic);
  end component;

  component pg_conv_ftol_32_17_8_4
    port(fixdata : in std_logic_vector(31 downto 0);
         logdata : out std_logic_vector(16 downto 0);
         clk : in std_logic);
  end component;

  component pg_pdelay_10
    generic (PG_WIDTH: integer);
    port( x : in std_logic_vector(PG_WIDTH-1 downto 0);
	     y : out std_logic_vector(PG_WIDTH-1 downto 0);
	     clk: in std_logic);
  end component;

  component pg_log_shift_1                        
    generic (PG_WIDTH: integer);                           
    port( x : in std_logic_vector(PG_WIDTH-1 downto 0);    
	     y : out std_logic_vector(PG_WIDTH-1 downto 0);  
	     clk: in std_logic);                             
  end component;                                           
                                                           
  component pg_pdelay_5
    generic (PG_WIDTH: integer);
    port( x : in std_logic_vector(PG_WIDTH-1 downto 0);
	     y : out std_logic_vector(PG_WIDTH-1 downto 0);
	     clk: in std_logic);
  end component;

  component pg_log_unsigned_add_itp_17_8_6_4
    port( x,y : in std_logic_vector(16 downto 0);
          z : out std_logic_vector(16 downto 0);
          clock : in std_logic);
  end component;

  component pg_log_shift_m1                        
    generic (PG_WIDTH: integer);                           
    port( x : in std_logic_vector(PG_WIDTH-1 downto 0);    
	     y : out std_logic_vector(PG_WIDTH-1 downto 0);  
	     clk: in std_logic);                             
  end component;                                           
                                                           
  component pg_log_mul_17_1
    port( x,y : in std_logic_vector(16 downto 0);
            z : out std_logic_vector(16 downto 0);  
          clk : in std_logic);
  end component;

  component pg_pdelay_14
    generic (PG_WIDTH: integer);
    port( x : in std_logic_vector(PG_WIDTH-1 downto 0);
	     y : out std_logic_vector(PG_WIDTH-1 downto 0);
	     clk: in std_logic);
  end component;

  component pg_log_div_17_1
    port( x,y : in std_logic_vector(16 downto 0);
            z : out std_logic_vector(16 downto 0);  
          clk : in std_logic);
  end component;

  component pg_log_sdiv_17_1
    port( x,y : in std_logic_vector(16 downto 0);
            z : out std_logic_vector(16 downto 0);  
          clk : in std_logic);
  end component;

  component pg_conv_ltof_17_8_57_2      
    port(logdata : in std_logic_vector(16 downto 0);
	     fixdata : out std_logic_vector(56 downto 0);
	     clk : in std_logic);
  end component;
                                                                  
  component pg_fix_accum_57_64_3
    port (fdata: in std_logic_vector(56 downto 0);
          sdata: out std_logic_vector(63 downto 0);
          run: in std_logic;
          clk: in std_logic);
  end component;

-- pg_rundelay(22)
  signal run: std_logic_vector(23 downto 0);
  signal xi: std_logic_vector(31 downto 0);
  signal xj: std_logic_vector(31 downto 0);
  signal yi: std_logic_vector(31 downto 0);
  signal yj: std_logic_vector(31 downto 0);
  signal zi: std_logic_vector(31 downto 0);
  signal zj: std_logic_vector(31 downto 0);
  signal xij: std_logic_vector(31 downto 0);
  signal yij: std_logic_vector(31 downto 0);
  signal zij: std_logic_vector(31 downto 0);
  signal dx: std_logic_vector(16 downto 0);
  signal dy: std_logic_vector(16 downto 0);
  signal dz: std_logic_vector(16 downto 0);
  signal ieps2: std_logic_vector(16 downto 0);
  signal x2: std_logic_vector(16 downto 0);
  signal y2: std_logic_vector(16 downto 0);
  signal z2: std_logic_vector(16 downto 0);
  signal ieps2r: std_logic_vector(16 downto 0);
  signal x2y2: std_logic_vector(16 downto 0);
  signal z2e2: std_logic_vector(16 downto 0);
  signal r2: std_logic_vector(16 downto 0);
  signal r1: std_logic_vector(16 downto 0);
  signal mj: std_logic_vector(16 downto 0);
  signal mjr: std_logic_vector(16 downto 0);
  signal r3: std_logic_vector(16 downto 0);
  signal mf: std_logic_vector(16 downto 0);
  signal dxr: std_logic_vector(16 downto 0);
  signal dyr: std_logic_vector(16 downto 0);
  signal dzr: std_logic_vector(16 downto 0);
  signal fx: std_logic_vector(16 downto 0);
  signal fx_ofst: std_logic_vector(16 downto 0);
  signal fy: std_logic_vector(16 downto 0);
  signal fy_ofst: std_logic_vector(16 downto 0);
  signal fz: std_logic_vector(16 downto 0);
  signal fz_ofst: std_logic_vector(16 downto 0);
  signal fxo: std_logic_vector(16 downto 0);    
  signal fyo: std_logic_vector(16 downto 0);    
  signal fzo: std_logic_vector(16 downto 0);    
  signal ffx: std_logic_vector(56 downto 0);
  signal sx: std_logic_vector(63 downto 0);
  signal ffy: std_logic_vector(56 downto 0);
  signal sy: std_logic_vector(63 downto 0);
  signal ffz: std_logic_vector(56 downto 0);
  signal sz: std_logic_vector(63 downto 0);
                                                                    
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

  process(pclk) begin
    if(pclk'event and pclk='1') then
      run(0) <= p_run;
      for i in 0 to 22 loop
        run(i+1) <= run(i);
      end loop;
      p_runret <= run(23);
    end if;
  end process;

  u0: pg_fix_sub_32_1
       port map (x=>xi,y=>xj,z=>xij,clk=>pclk);

  u1: pg_fix_sub_32_1
       port map (x=>yi,y=>yj,z=>yij,clk=>pclk);

  u2: pg_fix_sub_32_1
       port map (x=>zi,y=>zj,z=>zij,clk=>pclk);

  u3: pg_conv_ftol_32_17_8_4 port map (fixdata=>xij,logdata=>dx,clk=>pclk);

  u4: pg_conv_ftol_32_17_8_4 port map (fixdata=>yij,logdata=>dy,clk=>pclk);

  u5: pg_conv_ftol_32_17_8_4 port map (fixdata=>zij,logdata=>dz,clk=>pclk);

  u6: pg_pdelay_10 generic map(PG_WIDTH=>17) port map(x=>dx,y=>dxr,clk=>pclk);

  u7: pg_pdelay_10 generic map(PG_WIDTH=>17) port map(x=>dy,y=>dyr,clk=>pclk);

  u8: pg_pdelay_10 generic map(PG_WIDTH=>17) port map(x=>dz,y=>dzr,clk=>pclk);

  u9: pg_log_shift_1 generic map(PG_WIDTH=>17)       
                    port map(x=>dx,y=>x2,clk=>pclk);         
                                                                  
  u10: pg_log_shift_1 generic map(PG_WIDTH=>17)       
                    port map(x=>dy,y=>y2,clk=>pclk);         
                                                                  
  u11: pg_log_shift_1 generic map(PG_WIDTH=>17)       
                    port map(x=>dz,y=>z2,clk=>pclk);         
                                                                  
  u12: pg_pdelay_5 generic map(PG_WIDTH=>17) port map(x=>ieps2,y=>ieps2r,clk=>pclk);

  u13: pg_log_unsigned_add_itp_17_8_6_4
            port map(x=>x2,y=>y2,z=>x2y2,clock=>pclk);

  u14: pg_log_unsigned_add_itp_17_8_6_4
            port map(x=>z2,y=>ieps2r,z=>z2e2,clock=>pclk);

  u15: pg_log_unsigned_add_itp_17_8_6_4
            port map(x=>x2y2,y=>z2e2,z=>r2,clock=>pclk);

  u16: pg_log_shift_m1 generic map(PG_WIDTH=>17)       
                    port map(x=>r2,y=>r1,clk=>pclk);         
                                                                  
  u17: pg_log_mul_17_1 port map(x=>r2,y=>r1,z=>r3,clk=>pclk);

  u18: pg_pdelay_14 generic map(PG_WIDTH=>17) port map(x=>mj,y=>mjr,clk=>pclk);

  u19: pg_log_div_17_1 port map(x=>mjr,y=>r3,z=>mf,clk=>pclk);

  u20: pg_log_mul_17_1 port map(x=>mf,y=>dxr,z=>fx,clk=>pclk);

  u21: pg_log_mul_17_1 port map(x=>mf,y=>dyr,z=>fy,clk=>pclk);

  u22: pg_log_mul_17_1 port map(x=>mf,y=>dzr,z=>fz,clk=>pclk);

  u23: pg_log_sdiv_17_1 port map(x=>fx,y=>fx_ofst,z=>fxo,clk=>pclk);

  u24: pg_log_sdiv_17_1 port map(x=>fy,y=>fy_ofst,z=>fyo,clk=>pclk);

  u25: pg_log_sdiv_17_1 port map(x=>fz,y=>fz_ofst,z=>fzo,clk=>pclk);

  u26: pg_conv_ltof_17_8_57_2 port map (logdata=>fxo,fixdata=>ffx,clk=>pclk);

  u27: pg_conv_ltof_17_8_57_2 port map (logdata=>fyo,fixdata=>ffy,clk=>pclk);

  u28: pg_conv_ltof_17_8_57_2 port map (logdata=>fzo,fixdata=>ffz,clk=>pclk);

  u29: pg_fix_accum_57_64_3 port map(fdata=>ffx,sdata=>sx,run=>run(18),clk=>pclk);

  u30: pg_fix_accum_57_64_3 port map(fdata=>ffy,sdata=>sy,run=>run(18),clk=>pclk);

  u31: pg_fix_accum_57_64_3 port map(fdata=>ffz,sdata=>sz,run=>run(18),clk=>pclk);

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
                                                                    
