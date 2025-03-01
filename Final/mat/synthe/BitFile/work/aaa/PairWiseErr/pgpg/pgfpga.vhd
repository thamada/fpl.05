library ieee;
use ieee.std_logic_1164.all;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
LIBRARY altera;
USE altera.maxplus2.all;

entity pgfpga is 
  port(
-- for IO 
      e_clk,e_sysclk,e_rst: in std_logic;
      e_jpwe : in std_logic;
      e_pid: in std_logic_vector(9 downto 0);
      e_ipd : in std_logic_vector(35 downto 0);
      e_ipwe : in std_logic;
      e_fod: out std_logic_vector(35 downto 0);
      e_nd,e_vd,e_sts: out std_logic;
      e_wd : in std_logic;
      e_active : out std_logic;

-- for memory
      m_oe : out std_logic_vector(1 downto 0);
      m_we : out std_logic_vector(1 downto 0);
      m_al : out std_logic_vector(18 downto 0);
      m_ah : out std_logic_vector(18 downto 0);
      m_dl : inout std_logic_vector(35 downto 0);
      m_dh : inout std_logic_vector(35 downto 0);
      m_clk : out std_logic_vector(1 downto 0)
  );
end pgfpga;

architecture hierarchy of pgfpga is

  component ipw
    port( 
      i_ipwe: in std_logic;
      i_ipd : in std_logic_vector(35 downto 0);
      i_weca,i_wejp,i_wefo,i_wei: out std_logic;
      i_adri : out std_logic_vector(11 downto 0);
      i_adr : out std_logic_vector(3 downto 0);
      i_data: out std_logic_vector(31 downto 0);
      i_perr: out std_logic;
      clk,sysclk,rst : in std_logic );
  end component;

  component jpw
    port( 
      j_jpwe: in std_logic;
      j_jpd : in std_logic_vector(35 downto 0);
      j_physid : in std_logic_vector(9 downto 0);
      j_wejp: in std_logic;
      j_data: in std_logic_vector(19 downto 0);
      j_adr : in std_logic_vector(3 downto 0);
      j_mdl : out std_logic_vector(35 downto 0);
      j_mdh : out std_logic_vector(35 downto 0);
      j_mwe,j_moe : out std_logic_vector(1 downto 0);
      j_mal : out std_logic_vector(18 downto 0);
      j_mah : out std_logic_vector(18 downto 0);
      j_oel,j_oeh : out std_logic;
      j_clma : in std_logic_vector(18 downto 0);
      j_vcido : out std_logic_vector(9 downto 0);
      j_perr : out std_logic;
      clk,sysclk,rst : in std_logic);
  end component;

  component calc
    port(
      c_md : in std_logic_vector(71 downto 0);
      c_ma : out std_logic_vector(18 downto 0);
      c_weca: in std_logic;
      c_data: in std_logic_vector(19 downto 0);
      c_adr : in std_logic_vector(3 downto 0);
      c_jdata : out std_logic_vector(71 downto 0); 	        
      c_run : out std_logic;
      rst,clk : in std_logic);
  end component;

  component fo
    port(
      f_wefo : in std_logic;
      f_data: in std_logic_vector(31 downto 0);
      f_adr : in std_logic_vector(3 downto 0);
      f_pd : in std_logic_vector(31 downto 0);      
      f_pa : out std_logic_vector(11 downto 0);
      f_csts : in std_logic;
      f_fodata : out std_logic_vector(35 downto 0);
      f_sts,f_vd,f_nd : out std_logic;
      f_wd : in std_logic;
      f_active : out std_logic;
      f_vcid : in std_logic_vector(9 downto 0);
      rst,clk,sysclk : in std_logic );
  end component;

  component pg_pipe
    port(
      p_jdata: in std_logic_vector(71 downto 0);
      p_run : in std_logic;
      p_we : in std_logic;
      p_adri : in std_logic_vector(11 downto 0);      
      p_datai : in std_logic_vector(31 downto 0);
      p_adro : in std_logic_vector(11 downto 0);      
      p_datao : out std_logic_vector(31 downto 0);
      p_runret : out std_logic;
      rst,clk : in std_logic );
  end component;

 signal clk, iclk0, iclk1, iclk2, clk0, clk1:  std_logic;
 signal weca,wejp,wefo,wei: std_logic;
 signal adr: std_logic_vector(3 downto 0);
 signal adri: std_logic_vector(11 downto 0);
 signal data: std_logic_vector(31 downto 0);
 signal clma: std_logic_vector(18 downto 0);
 signal clsts: std_logic;
 signal jdata: std_logic_vector(71 downto 0);
 signal run: std_logic;
 signal padr: std_logic_vector(11 downto 0);
 signal pdata: std_logic_vector(31 downto 0);
 signal mdlh: std_logic_vector(71 downto 0);
 signal iperr,jperr: std_logic; 
 signal vcid: std_logic_vector(9 downto 0);

 signal mdoel,mdoeh: std_logic;
 signal m_dl0 : std_logic_vector(35 downto 0);
 signal m_dh0 : std_logic_vector(35 downto 0);

 signal sysclk0,sysclk1:  std_logic; 

begin

--  upll: altclklock generic map(inclock_period => 58823,
--                              clock0_boost => 1,clock1_boost => 2)
--                  port map(inclock=>e_clk, clock0=>clk, clock1=>iclk0);
 
--  process(iclk0) begin
--    if(iclk0'event and iclk0='1') then 
--      iclk1 <= not iclk1;
--    end if;
--  end process;

--  m_clk(1) <= iclk1;
--  m_clk(0) <= iclk1;

--  ulcell0: lcell PORT MAP(a_in=>e_sysclk, a_out=>sysclk0);
--  ulcell1: lcell PORT MAP(a_in=>sysclk0, a_out=>sysclk1);

  clk <= e_clk;
  m_clk(1) <= e_sysclk;
  m_clk(0) <= e_sysclk;

  uipw: ipw PORT MAP(i_ipwe=>e_ipwe,i_ipd=>e_ipd,
		   i_weca=>weca, i_wejp=>wejp, i_wefo=>wefo, i_wei=>wei, 
		   i_adr=>adr, i_adri=>adri, i_data=>data, i_perr=>iperr,
                   clk=>clk,sysclk=>e_sysclk,rst=>e_rst);

  ujpw: jpw PORT MAP(j_jpwe=>e_jpwe, j_jpd=>e_ipd, j_physid=>e_pid, 
                    j_wejp=>wejp, j_data=>data(19 downto 0), j_adr=>adr(3 downto 0), 
	            j_mdl=>m_dl0, j_mdh=>m_dh0, j_mwe=>m_we, j_moe=>m_oe,
                    j_oel=>mdoel, j_oeh=>mdoeh, 
	            j_mal=>m_al, j_mah=>m_ah,j_clma=>clma, j_perr=>jperr,
                    j_vcido=>vcid, clk=>clk,sysclk=>e_sysclk,rst=>e_rst);

   
  with mdoel select
    m_dl <= m_dl0 when '1',
            "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" when others;

  with mdoeh select
    m_dh <= m_dh0 when '1',
            "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" when others;

  mdlh <= m_dh & m_dl;
  ucalc: calc PORT MAP(c_md=>mdlh, c_ma=>clma, 
                     c_weca=>weca, c_data=>data(19 downto 0), c_adr=>adr(3 downto 0), 
	             c_jdata=>jdata, c_run=>run, 
                     clk=>clk,rst=>e_rst);

  ufo: fo PORT MAP(f_wefo=>wefo,f_data=>data, f_adr=>adr(3 downto 0),
                   f_pd=>pdata, f_pa=>padr, f_csts=>clsts,
		   f_fodata=>e_fod, f_sts=>e_sts,
	           f_vd=>e_vd, f_nd=>e_nd, f_wd=>e_wd, 
	           f_active=>e_active, f_vcid=>vcid,
                   rst=>e_rst,clk=>clk,sysclk=>e_sysclk);


  upipeline: pg_pipe PORT MAP(p_jdata=>jdata, p_run=>run,
	                p_we=>wei,p_adri=>adri,p_datai=>data,
	                p_adro=>padr,p_datao=>pdata, p_runret=>clsts,
                        rst=>e_rst,clk=>clk);
	                  
end hierarchy;
  

library ieee;
use ieee.std_logic_1164.all;

entity parity_check is
port(
   data: in std_logic_vector(35 downto 0);
   clk,rst,vd : in std_logic;
   perr: out std_logic
);
end parity_check;

architecture RTL of parity_check is
  signal perr0 : std_logic;
begin

  process(clk)
    variable tmp: std_logic_vector(3 downto 0);  
  begin
    if(clk'event and clk='1') then 
      if(rst = '1') then 
        perr0 <= '0';
      else
	if(vd = '1') then 
          tmp := "0000";
          for i in 0 to 7 loop
            tmp(0) := tmp(0) xor data(i);
            tmp(1) := tmp(1) xor data(i+8);
            tmp(2) := tmp(2) xor data(i+16);
            tmp(3) := tmp(3) xor data(i+24);
          end loop;
          if((tmp(0) /= data(32)) or (tmp(1) /= data(33)) 
            or (tmp(2) /= data(34)) or (tmp(3) /= data(35))) then 
            perr0 <= perr0 or '1';
          end if;
        end if;
      end if;
    end if;
  end process;
  perr <= perr0;

end RTL;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ipw is
    port( 
      i_ipwe: in std_logic;
      i_ipd : in std_logic_vector(35 downto 0);
      i_weca,i_wejp,i_wefo,i_wei: out std_logic;
      i_adri : out std_logic_vector(11 downto 0);
      i_adr : out std_logic_vector(3 downto 0);
      i_data: out std_logic_vector(31 downto 0);
      i_perr: out std_logic;
      clk,sysclk,rst : in std_logic );
end ipw;

architecture rtl of ipw is

  component parity_check
  port(
    data: in std_logic_vector(35 downto 0);
    clk,rst,vd: in std_logic;
    perr: out std_logic  );
  end component;

  signal ipd0,ipd1 : std_logic_vector(35 downto 0);
  signal sysclk0,sysclk1 : std_logic;
  signal ipwe0,ipwe1 : std_logic;
  signal vd : std_logic;
  signal cefp0,weiprg0,wejp0,wefo0,wecalc0 : std_logic;
  signal diprg: std_logic_vector(31 downto 0);
  signal aiprg : std_logic_vector(5 downto 0);
  signal com_dc : std_logic_vector(1 downto 0);
  signal word_dc : std_logic_vector(10 downto 0);
  signal adrdec : std_logic_vector(14 downto 0);
  signal radr_uc : std_logic_vector(3 downto 0);
  signal fadr_uc : std_logic_vector(11 downto 0);

begin

-- data latch at input port

  process(clk) begin
    if(clk'event and clk='1') then
      sysclk1 <= sysclk0;
      sysclk0 <= sysclk;
      ipwe1 <= ipwe0;
      ipwe0 <= i_ipwe;
      ipd1 <= ipd0;
      ipd0 <= i_ipd;	
    end if;
  end process;

-- check write enable

  process(sysclk0,sysclk1,ipwe1) begin
--    if(sysclk0='1' and sysclk1='0' and ipwe1='0') then  
    if(ipwe1='0') then  
      vd <= '1';
    else 
      vd <= '0';
    end if;
  end process;

-- command counter

  process(clk) begin
    if(clk'event and clk='1') then 
      if(rst='1') then 
        com_dc <= "00";
      elsif(vd='1') then
        if(com_dc = "00" and word_dc = "00000000000") then 
          com_dc <= "10";
	elsif(com_dc /=  "00") then 
          com_dc <= com_dc - "01";
        end if;
      end if;
    end if;
  end process;

-- word counter

  process(clk) begin
    if(clk'event and clk='1') then
      if(rst = '1') then 
        word_dc <= "00000000000";
      elsif(vd = '1') then 
        if(com_dc = "10") then 
           word_dc <= ipd1(10 downto 0);
        elsif(word_dc /= "00000000000") then
           word_dc <= word_dc - "00000000001";
        end if;
      end if;
    end if;
  end process;

-- address latch and decoder

  process(clk) begin
    if(clk'event and clk='1') then
      if(vd = '1') then 
        if(com_dc = "00" and word_dc = "00000000000") then 
          adrdec <= ipd1(14 downto 0);
        end if;
      end if;
    end if;
  end process;

  with adrdec(14 downto 12) select
    cefp0 <= '1' when "000",
             '0' when others;

  with adrdec(14 downto 12) select
    weiprg0 <= '1' when "001",
               '0' when others;

  with adrdec(14 downto 12) select
    wejp0 <= '1' when "010",
             '0' when others;

  with adrdec(14 downto 12) select
    wefo0 <= '1' when "011",
             '0' when others;

  with adrdec(14 downto 12) select
    wecalc0 <= '1' when "100",
               '0' when others;

-- register address counter 

  process(clk) begin   
    if(clk'event and clk='1') then
      if(vd ='1') then 
        if(com_dc = "00" and word_dc = "00000000000") then
          radr_uc <= ipd1(3 downto 0);
        elsif(word_dc /= "00000000000" and cefp0 = '0') then 
          radr_uc <=  radr_uc + "0001";
	end if;
      end if;
    end if;
  end process;

-- pipeline address counter 

  process(clk) begin   
    if(clk'event and clk='1') then
      if(vd ='1') then 
        if(com_dc = "00" and word_dc = "00000000000") then
          fadr_uc <= ipd1(11 downto 0);
        elsif(word_dc /= "00000000000" and cefp0 = '1') then 
          fadr_uc <=  fadr_uc + "000000000001";
	end if;
      end if;
    end if;
  end process;

-- parity checker

   pcheck: parity_check PORT MAP(data=>ipd1,clk=>clk,rst=>rst,vd=>vd,
				perr=>i_perr);

-- write enable signal

  process(clk) begin
    if(clk'event and clk='1') then 
      if(vd='1' and word_dc /= "00000000000") then
	i_adr <= radr_uc;
        i_data <= ipd1(31 downto 0);
        i_adri <= fadr_uc;
        i_wejp <= wejp0;
        i_weca <= wecalc0;
        i_wefo <= wefo0;
        i_wei <= cefp0;
      else
        i_wejp <= '0';
        i_wefo <= '0';
        i_weca <= '0';
        i_wei <= '0';
      end if;
    end if;
  end process;

-- write to command register in ipw

--  diprg <= ipd1(31 downto 0); 
--  aiprg <= radr_uc;
  process(clk) begin
    if(clk'event and clk='1') then 
      if(weiprg0='1') then 
      end if;	
    end if;
  end process;
     
end RTL;
  



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity jpw is
    port( 
      j_jpwe: in std_logic;
      j_jpd : in std_logic_vector(35 downto 0);
      j_physid : in std_logic_vector(9 downto 0);
      j_wejp: in std_logic;
      j_data: in std_logic_vector(19 downto 0);
      j_adr : in std_logic_vector(3 downto 0);
      j_mdl : out std_logic_vector(35 downto 0);
      j_mdh : out std_logic_vector(35 downto 0);
      j_mwe,j_moe : out std_logic_vector(1 downto 0);
      j_mal : out std_logic_vector(18 downto 0);
      j_mah : out std_logic_vector(18 downto 0);
      j_oel,j_oeh : out std_logic;
      j_clma : in std_logic_vector(18 downto 0);
      j_vcido : out std_logic_vector(9 downto 0);
      j_perr : out std_logic;
      clk,sysclk,rst : in std_logic);
end jpw;

architecture RTL of jpw is

  component parity_check
  port(
    data: in std_logic_vector(35 downto 0);
    clk,rst,vd: in std_logic;
    perr: out std_logic  );
  end component;

  signal sysclk0,sysclk1,jpwe0,jpwe1: std_logic;
  signal jpd0,jpd1: std_logic_vector(35 downto 0);
  signal vd : std_logic;
  signal com_dc: std_logic_vector(1 downto 0);
  signal word_dc: std_logic_vector(4 downto 0);
  signal word_uc: std_logic_vector(3 downto 0);
  signal selid : std_logic;
  signal reg1: std_logic_vector(31 downto 0);
  signal memadr0,memadr1,memadr2: std_logic_vector(18 downto 0);
  signal weregl,weregh: std_logic;
  signal nd : std_logic_vector(4 downto 0);
  signal vcid : std_logic_vector(9 downto 0);

begin

-- data latch at input port

  process(clk) begin
    if(clk'event and clk='1') then
      sysclk1 <= sysclk0;
      sysclk0 <= sysclk;
      jpwe1 <= jpwe0;
      jpwe0 <= j_jpwe;
      jpd1 <= jpd0;
      jpd0 <= j_jpd;	
    end if;
  end process;

-- check write enable (asyn)

  process(sysclk0,sysclk1,jpwe1) begin
--    if(sysclk0='1' and sysclk1='0' and jpwe1='0') then  
    if(jpwe1='0') then  
      vd <= '1';
    else 
      vd <= '0';
    end if;
  end process;

-- parity checker

  pcheck: parity_check PORT MAP(data=>jpd1,clk=>clk,rst=>rst,perr=>j_perr,vd=>vd);

-- command counter

  process(clk) begin
    if(clk'event and clk='1') then 
      if(rst = '1') then 
         com_dc <= "00"; 
      elsif(vd='1') then
        if(com_dc = "00" and word_dc = "00000") then
          com_dc <= "10";
	elsif(com_dc /= "00") then 
          com_dc <= com_dc -"01";
        end if;
      end if;
    end if;
  end process;

-- word counter 

  process(clk) begin
    if(clk'event and clk='1') then
      if(rst = '1') then 
        word_dc <= "00000";
      elsif(vd = '1') then 
        if(com_dc="10") then 
          word_dc <= nd;
          word_uc <= "0000";
        elsif(word_dc /= "00000") then
          word_dc <= word_dc - "00001";
          word_uc <= word_uc + "0001";
        end if;
      end if;
    end if;
  end process;

-- check ID

  process(clk) begin
    if(clk'event and clk='1') then 
      if(vd='1') then 
        if(com_dc = "00" and word_dc="00000") then
          if((jpd1(9 downto 0) and jpd1(19 downto 10)) = (vcid and jpd1(19 downto 10))) then 
            selid <= '1';
          else
            selid <= '0';
	  end if;
        end if;
      end if;
    end if;
  end process;

-- write to register 0 

  process(clk) begin
    if(clk'event and clk='1') then 
      if(vd='1') then 
        reg1 <= jpd1(31 downto 0);
      end if;
    end if;
  end process;

-- memory address latch and counter
 
  process(clk) begin   
    if(clk'event and clk='1') then
      if(vd ='1') then 
        if(com_dc = "10") then
          memadr0 <= jpd1(18 downto 0);
	else
          if(word_uc(0) = '1') then 
            memadr0 <= memadr0 + "000000000000000001";
          end if;
        end if;
      end if;
    end if;
  end process;

  process(clk) begin   
    if(clk'event and clk='1') then
      memadr1 <= memadr0;
--      memadr2 <= memadr1;
    end if;
  end process;

-- memory control timing signal

  process(clk) begin   
    if(clk'event and clk='1') then
      if(word_dc /= "00000" and selid = '1' and word_uc(0) = '0') then 
        weregl <= '1';
      else 
	weregl <= '0';
      end if;	
    end if;
  end process;

  process(clk) begin   
    if(clk'event and clk='1') then
      if(word_dc /= "00000" and selid = '1' and word_uc(0) = '1') then 
        weregh <= '1';
      else 
	weregh <= '0';
      end if;	
    end if;
  end process;

-- mema signal

  process(clk) begin   
    if(clk'event and clk='1') then
      if(weregl = '1') then 
	j_mal <= memadr1;
      else 
	j_mal <= j_clma;
      end if;	
    end if;
  end process;

  process(clk) begin   
    if(clk'event and clk='1') then
      if(weregh = '1') then 
--	j_mah <= memadr2;
	j_mah <= memadr1;
      else
	j_mah <= j_clma;
      end if;	
    end if;
  end process;

-- memd signal


  process(clk) begin   
    if(clk'event and clk='1') then
      j_mdl <= "0000" & reg1;
      j_mdh <= "0000" & reg1;
      j_oel <= weregl;	
      j_oeh <= weregh;	
    end if;
  end process;

--  process(clk) begin   
--    if(clk'event and clk='1') then
--      if(weregl = '1') then 	
--        j_mdl <= "0000" & reg1;
--      else
--        j_mdl <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
--      end if;	
--    end if;
--  end process;
--
--  process(clk) begin   
--    if(clk'event and clk='1') then
--      if(weregh = '1') then 	
--        j_mdh <= "0000" & reg1;
--      else
--        j_mdh <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
--      end if;	
--    end if;
--  end process;

-- memwe signal

  process(clk) begin   
    if(clk'event and clk='1') then
      j_mwe(0) <= not weregl;
      j_mwe(1) <= not weregh;
    end if;
  end process;

-- memoe signal

  process(clk) begin   
    if(clk'event and clk='1') then
      j_moe(0) <= weregl;
      j_moe(1) <= weregh;
    end if;
  end process;

-- write to command register in jpw

  process(clk) begin
    if(clk'event and clk='1') then 
      if(j_wejp='1') then 
        if(j_adr(3 downto 0) = "0000") then 
          nd <= j_data(4 downto 0);
        elsif(j_adr(3 downto 0)= "0001") then            
	  if(j_data(19 downto 10)=j_physid) then 
            vcid <= j_data(9 downto 0);
 	  end if;
        end if; 
      end if;	
    end if;
  end process;
  j_vcido <= vcid;
     
end RTL;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity calc is
    port(
      c_md : in std_logic_vector(71 downto 0);
      c_ma : out std_logic_vector(18 downto 0);
      c_weca: in std_logic;
      c_data: in std_logic_vector(19 downto 0);
      c_adr : in std_logic_vector(3 downto 0);
      c_jdata : out std_logic_vector(71 downto 0);             
      c_run : out std_logic;
      rst,clk : in std_logic);
end calc;

architecture RTL of calc is

  signal mema_dc: std_logic_vector(19 downto 0);
  signal adrvd00: std_logic;
  signal adrvd: std_logic_vector(5 downto 0);
  signal n: std_logic_vector(19 downto 0);
  signal start: std_logic;

begin

-- generate memory address 

  process(clk) begin
    if(clk'event and clk='1') then 
      if(rst = '1') then 
        mema_dc <= "00000000000000000000";
      else
        if(start='1') then 
          mema_dc <= n ;
        elsif(mema_dc /= "00000000000000000000") then 
          mema_dc <= mema_dc - "00000000000000000001";
        end if;	
      end if;
    end if;
  end process;

  c_ma <= mema_dc(18 downto 0);

-- address and data valid signal

  process(clk) begin
    if(clk'event and clk='1') then 
      if(rst = '1') then
        adrvd00 <= '0';
      elsif(start = '1') then 
	adrvd00 <= '1';
      elsif(mema_dc = "0000000000000000000001") then 
	adrvd00 <= '0';
      end if;
    end if;
  end process;

  process(clk) begin
    if(clk'event and clk='1') then 
      if(rst = '1') then  
        adrvd <= "000000";
      else
        adrvd(1) <= adrvd00;        
        adrvd(2) <= adrvd(1);        
        adrvd(3) <= adrvd(2);        
        adrvd(4) <= adrvd(3);        
        adrvd(5) <= adrvd(4);        
      end if; 
    end if;
  end process;

  c_run <= adrvd(4);

-- data from memory

  process(clk) begin
    if(clk'event and clk='1') then 
      c_jdata <= c_md(71 downto 68) & c_md(35 downto 32) & c_md(67 downto 36) & c_md(31 downto 0);
    end if;
  end process;

-- write to command register in calc

  process(clk) begin
    if(clk'event and clk='1') then 
      if(c_weca='1') then 
        if(c_adr = "0000") then 
	  n <= c_data;
        end if;
      end if;	
    end if;
  end process;
     
  process(clk) begin
    if(clk'event and clk='1') then 
      if(rst = '1') then 
        start <=  '0';
      elsif(c_weca='1' and c_adr = "0000") then 
        start <=  '1';
      else
	start <= '0';
      end if;	
    end if;
  end process;

end RTL;



  



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity fo is
    port(
      f_wefo : in std_logic;
      f_data: in std_logic_vector(31 downto 0);
      f_adr : in std_logic_vector(3 downto 0);
      f_pd : in std_logic_vector(31 downto 0);      
      f_pa : out std_logic_vector(11 downto 0);
      f_csts : in std_logic;
      f_fodata : out std_logic_vector(35 downto 0);
      f_sts,f_vd,f_nd : out std_logic;
      f_wd : in std_logic;
      f_active : out std_logic;
      f_vcid : in std_logic_vector(9 downto 0);	
      rst,clk,sysclk : in std_logic );
end fo;

architecture RTL of fo is

  signal sysclk0,sysclk1 : std_logic;
  signal scphase : std_logic;
  signal calcsts1 : std_logic;
  signal plstart_flag,rdstart_flag: std_logic;
  signal select_code: std_logic_vector(1 downto 0);
  signal al_dc,al_uc: std_logic_vector(3 downto 0);
  signal ah_dc,ah_uc: std_logic_vector(7 downto 0);
  signal address_pl : std_logic_vector(11 downto 0);
  signal vdflag_pl: std_logic;
  signal random_dc : std_logic_vector(1 downto 0);
  signal random_uc : std_logic_vector(11 downto 0);
  signal address_rd : std_logic_vector(11 downto 0);
  signal fodata0: std_logic_vector(31 downto 0);
  signal vdflag_rd: std_logic;
  signal vd0,vd1: std_logic;
  signal com0,com1: std_logic_vector(31 downto 0);
  signal ni : std_logic_vector(5 downto 0);
  signal ndata : std_logic_vector(3 downto 0);
  signal comstart: std_logic;

begin

  f_active <= '1';

-- make phase and wd from sysclk 

  process(clk) begin
    if(clk'event and clk='1') then
      sysclk1 <= sysclk0;
      sysclk0 <= sysclk;
    end if;
  end process;

  scphase <= '1';
	 
-- triger logic

  process(clk) begin
    if(clk'event and clk='1') then
      if(scphase = '1') then 
	calcsts1 <= f_csts;
      end if;	
    end if;
  end process;

  process(clk) begin
    if(clk'event and clk='1') then
      if(scphase = '1') then 
        if((f_csts = '0') and (calcsts1 = '1')) then 
          plstart_flag <= '1';
        else 
          plstart_flag <= '0';	
	end if;
      end if;
    end if;
  end process;

  process(clk) begin
    if(clk'event and clk='1') then
      if(scphase = '1') then 
        if((comstart = '1') and (com0(31 downto 30) = "00") 
 	    and ((com0(9 downto 0) and com0(19 downto 10)) 
		= (f_vcid and com0(19 downto 10))) and (ah_dc = "000000")) then 	
          rdstart_flag <= '1';
        else
          rdstart_flag <= '0';
	end if;
      end if;
    end if;
  end process;

  process(clk) begin
    if(clk'event and clk='1') then
      if(plstart_flag = '1') then 
        select_code <= "00";
      elsif(rdstart_flag = '1') then 
        select_code <= "10";
      end if;	
    end if;
  end process;

-- pipeline read counter

  process(clk) begin
    if(clk'event and clk='1') then
      if(scphase = '1') then 
        if(plstart_flag = '1' or (al_dc = "0001" and ah_dc /= "00000001")) then 
	  al_dc <= ndata;
	  al_uc <= "0000";
        elsif(al_dc /= "0000") then 
	  al_dc <= al_dc - "0001";
	  al_uc <= al_uc + "0001";
	end if;
      end if;
    end if;
  end process;

  process(clk) begin
    if(clk'event and clk='1') then
      if(rst='1') then  
	  ah_dc <= "00000000";
      elsif(scphase = '1') then 
        if(plstart_flag = '1') then 
	  ah_dc <= "00" & ni;
	  ah_uc <= "00000000";
        elsif(ah_dc /= "00000000" and al_dc = "0001") then 
	  ah_dc <= ah_dc - "00000001";
	  ah_uc <= ah_uc + "00000001";
	end if;
      end if;
    end if;
  end process;

  address_pl <= ah_uc & al_uc;

  with ah_dc select
    vdflag_pl <= '0' when "00000000",
                 '1' when others;

-- ramdom read counter

  process(clk) begin
    if(clk'event and clk='1') then
      if(rst = '1') then  
        random_dc <= "00";
      elsif(scphase = '1') then 
        if(rdstart_flag = '1') then 
          random_uc <= com1(11 downto 0); 
          random_dc <= "10";
        elsif(random_dc /= "00") then 
          random_uc <= random_uc + "000000000001";
          random_dc <= random_dc - "01";
	end if;
      end if;
    end if;
  end process;

  address_rd <= random_uc;
 
  with random_dc select 
    vdflag_rd <= '0' when "00",
	         '1' when others;

-- address selector

  with select_code select
    f_pa <= address_rd when "10",
	    address_pl when others;

-- data selector

   fodata0 <= f_pd;

-- add parity

  process(clk) 
    variable tmp: std_logic_vector(3 downto 0);  
  begin
    if(clk'event and clk='1') then
      if(scphase = '1') then 
        tmp := "0000";
        for i in 0 to 7 loop
          tmp(0) := tmp(0) xor fodata0(i);
          tmp(1) := tmp(1) xor fodata0(i+8);
          tmp(2) := tmp(2) xor fodata0(i+16);
          tmp(3) := tmp(3) xor fodata0(i+24);
        end loop;
        f_fodata <= tmp & fodata0;
      end if;
    end if;
  end process;
 
-- output logic

  with select_code select
    vd0 <= vdflag_rd when "10",
	   vdflag_pl when others;

  process(clk) begin
    if(clk'event and clk='1') then 
      if(scphase = '1') then 
	vd1 <= vd0;
        f_vd <= not vd1;
        f_sts <= not f_csts;
        f_nd <= not vd1;
      end if;      	      
    end if;
  end process;

-- write to command register in fo

  process(clk) begin
    if(clk'event and clk='1') then 
      if(f_wefo='1') then 
        if(f_adr = "0000") then 
          com0 <= f_data;
        elsif(f_adr = "0001") then 
          com1 <= f_data;
        elsif(f_adr = "0010") then            
          ni <= f_data(5 downto 0);
        elsif(f_adr = "0011") then            
          ndata <= f_data(3 downto 0);
        end if; 
      end if;	
    end if;
  end process;

  process(clk) begin
    if(clk'event and clk='1') then 
      if(f_wefo='1' and f_adr = "0001") then 
        comstart <= '1';
      elsif(scphase = '1') then 
	comstart <= '0';	
      end if;
    end if;
  end process;
    
end RTL;
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
                                                                    
  component pg_fix_sub_32_2
    port(x,y : in std_logic_vector(31 downto 0);
         z : out std_logic_vector(31 downto 0);
         clk : in std_logic);
  end component;

  component pg_conv_ftol_32_17_8_4
    port(fixdata : in std_logic_vector(31 downto 0);
         logdata : out std_logic_vector(16 downto 0);
         clk : in std_logic);
  end component;

  component pg_pdelay_12
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
                                                           
  component pg_pdelay_6
    generic (PG_WIDTH: integer);
    port( x : in std_logic_vector(PG_WIDTH-1 downto 0);
	     y : out std_logic_vector(PG_WIDTH-1 downto 0);
	     clk: in std_logic);
  end component;

  component pg_log_unsigned_add_itp_17_8_6_5
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

  component pg_pdelay_17
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

-- pg_rundelay(25)
  signal run: std_logic_vector(26 downto 0);
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
      for i in 0 to 25 loop
        run(i+1) <= run(i);
      end loop;
      p_runret <= run(26);
    end if;
  end process;

  u0: pg_fix_sub_32_2
       port map (x=>xi,y=>xj,z=>xij,clk=>pclk);

  u1: pg_fix_sub_32_2
       port map (x=>yi,y=>yj,z=>yij,clk=>pclk);

  u2: pg_fix_sub_32_2
       port map (x=>zi,y=>zj,z=>zij,clk=>pclk);

  u3: pg_conv_ftol_32_17_8_4 port map (fixdata=>xij,logdata=>dx,clk=>pclk);

  u4: pg_conv_ftol_32_17_8_4 port map (fixdata=>yij,logdata=>dy,clk=>pclk);

  u5: pg_conv_ftol_32_17_8_4 port map (fixdata=>zij,logdata=>dz,clk=>pclk);

  u6: pg_pdelay_12 generic map(PG_WIDTH=>17) port map(x=>dx,y=>dxr,clk=>pclk);

  u7: pg_pdelay_12 generic map(PG_WIDTH=>17) port map(x=>dy,y=>dyr,clk=>pclk);

  u8: pg_pdelay_12 generic map(PG_WIDTH=>17) port map(x=>dz,y=>dzr,clk=>pclk);

  u9: pg_log_shift_1 generic map(PG_WIDTH=>17)       
                    port map(x=>dx,y=>x2,clk=>pclk);         
                                                                  
  u10: pg_log_shift_1 generic map(PG_WIDTH=>17)       
                    port map(x=>dy,y=>y2,clk=>pclk);         
                                                                  
  u11: pg_log_shift_1 generic map(PG_WIDTH=>17)       
                    port map(x=>dz,y=>z2,clk=>pclk);         
                                                                  
  u12: pg_pdelay_6 generic map(PG_WIDTH=>17) port map(x=>ieps2,y=>ieps2r,clk=>pclk);

  u13: pg_log_unsigned_add_itp_17_8_6_5
            port map(x=>x2,y=>y2,z=>x2y2,clock=>pclk);

  u14: pg_log_unsigned_add_itp_17_8_6_5
            port map(x=>z2,y=>ieps2r,z=>z2e2,clock=>pclk);

  u15: pg_log_unsigned_add_itp_17_8_6_5
            port map(x=>x2y2,y=>z2e2,z=>r2,clock=>pclk);

  u16: pg_log_shift_m1 generic map(PG_WIDTH=>17)       
                    port map(x=>r2,y=>r1,clk=>pclk);         
                                                                  
  u17: pg_log_mul_17_1 port map(x=>r2,y=>r1,z=>r3,clk=>pclk);

  u18: pg_pdelay_17 generic map(PG_WIDTH=>17) port map(x=>mj,y=>mjr,clk=>pclk);

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

  u29: pg_fix_accum_57_64_3 port map(fdata=>ffx,sdata=>sx,run=>run(21),clk=>pclk);

  u30: pg_fix_accum_57_64_3 port map(fdata=>ffy,sdata=>sy,run=>run(21),clk=>pclk);

  u31: pg_fix_accum_57_64_3 port map(fdata=>ffz,sdata=>sz,run=>run(21),clk=>pclk);

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
                                                                   
  component lcell_rom_8408_10_8_1                      
   port (indata: in std_logic_vector(9 downto 0);    
         clk: in std_logic;                           
         outdata: out std_logic_vector(7 downto 0)); 
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
                                                                 
  u4: lcell_rom_8408_10_8_1
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
                                   
-- ROM using Lcell not ESB         
-- Author: Tsuyoshi Hamada         
-- Last Modified at May 29,2003    
-- In 10 Out 8 Stage 1 Type"8408"
library ieee;                      
use ieee.std_logic_1164.all;       
                                   
entity lcell_rom_8408_10_8_1 is
  port( indata : in std_logic_vector(9 downto 0);
        clk : in std_logic;
        outdata : out std_logic_vector(7 downto 0));
end lcell_rom_8408_10_8_1;

architecture rtl of lcell_rom_8408_10_8_1 is

  component pg_lcell
    generic (MASK : bit_vector  := X"ffff";
             FF   : integer :=0);
    port (x   : in  std_logic_vector(3 downto 0);
          z   : out std_logic;
          clk : in  std_logic);
  end component;

  signal adr0 : std_logic_vector(9 downto 0);
  signal adr1 : std_logic_vector(9 downto 0);
  signal adr2 : std_logic_vector(9 downto 0);
  signal adr3 : std_logic_vector(9 downto 0);
  signal adr4 : std_logic_vector(9 downto 0);
  signal adr5 : std_logic_vector(9 downto 0);
  signal adr6 : std_logic_vector(9 downto 0);
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
  signal lc_4_10 : std_logic_vector(7 downto 0);
  signal lc_4_11 : std_logic_vector(7 downto 0);
  signal lc_4_12 : std_logic_vector(7 downto 0);
  signal lc_4_13 : std_logic_vector(7 downto 0);
  signal lc_4_14 : std_logic_vector(7 downto 0);
  signal lc_4_15 : std_logic_vector(7 downto 0);
  signal lc_4_16 : std_logic_vector(7 downto 0);
  signal lc_4_17 : std_logic_vector(7 downto 0);
  signal lc_4_18 : std_logic_vector(7 downto 0);
  signal lc_4_19 : std_logic_vector(7 downto 0);
  signal lc_4_1a : std_logic_vector(7 downto 0);
  signal lc_4_1b : std_logic_vector(7 downto 0);
  signal lc_4_1c : std_logic_vector(7 downto 0);
  signal lc_4_1d : std_logic_vector(7 downto 0);
  signal lc_4_1e : std_logic_vector(7 downto 0);
  signal lc_4_1f : std_logic_vector(7 downto 0);
  signal lc_4_20 : std_logic_vector(7 downto 0);
  signal lc_4_21 : std_logic_vector(7 downto 0);
  signal lc_4_22 : std_logic_vector(7 downto 0);
  signal lc_4_23 : std_logic_vector(7 downto 0);
  signal lc_4_24 : std_logic_vector(7 downto 0);
  signal lc_4_25 : std_logic_vector(7 downto 0);
  signal lc_4_26 : std_logic_vector(7 downto 0);
  signal lc_4_27 : std_logic_vector(7 downto 0);
  signal lc_4_28 : std_logic_vector(7 downto 0);
  signal lc_4_29 : std_logic_vector(7 downto 0);
  signal lc_4_2a : std_logic_vector(7 downto 0);
  signal lc_4_2b : std_logic_vector(7 downto 0);
  signal lc_4_2c : std_logic_vector(7 downto 0);
  signal lc_4_2d : std_logic_vector(7 downto 0);
  signal lc_4_2e : std_logic_vector(7 downto 0);
  signal lc_4_2f : std_logic_vector(7 downto 0);
  signal lc_4_30 : std_logic_vector(7 downto 0);
  signal lc_4_31 : std_logic_vector(7 downto 0);
  signal lc_4_32 : std_logic_vector(7 downto 0);
  signal lc_4_33 : std_logic_vector(7 downto 0);
  signal lc_4_34 : std_logic_vector(7 downto 0);
  signal lc_4_35 : std_logic_vector(7 downto 0);
  signal lc_4_36 : std_logic_vector(7 downto 0);
  signal lc_4_37 : std_logic_vector(7 downto 0);
  signal lc_4_38 : std_logic_vector(7 downto 0);
  signal lc_4_39 : std_logic_vector(7 downto 0);
  signal lc_4_3a : std_logic_vector(7 downto 0);
  signal lc_4_3b : std_logic_vector(7 downto 0);
  signal lc_4_3c : std_logic_vector(7 downto 0);
  signal lc_4_3d : std_logic_vector(7 downto 0);
  signal lc_4_3e : std_logic_vector(7 downto 0);
  signal lc_4_3f : std_logic_vector(7 downto 0);
  signal lut_5_0,lc_5_0 : std_logic_vector(7 downto 0);
  signal lut_5_1,lc_5_1 : std_logic_vector(7 downto 0);
  signal lut_5_2,lc_5_2 : std_logic_vector(7 downto 0);
  signal lut_5_3,lc_5_3 : std_logic_vector(7 downto 0);
  signal lut_5_4,lc_5_4 : std_logic_vector(7 downto 0);
  signal lut_5_5,lc_5_5 : std_logic_vector(7 downto 0);
  signal lut_5_6,lc_5_6 : std_logic_vector(7 downto 0);
  signal lut_5_7,lc_5_7 : std_logic_vector(7 downto 0);
  signal lut_5_8,lc_5_8 : std_logic_vector(7 downto 0);
  signal lut_5_9,lc_5_9 : std_logic_vector(7 downto 0);
  signal lut_5_a,lc_5_a : std_logic_vector(7 downto 0);
  signal lut_5_b,lc_5_b : std_logic_vector(7 downto 0);
  signal lut_5_c,lc_5_c : std_logic_vector(7 downto 0);
  signal lut_5_d,lc_5_d : std_logic_vector(7 downto 0);
  signal lut_5_e,lc_5_e : std_logic_vector(7 downto 0);
  signal lut_5_f,lc_5_f : std_logic_vector(7 downto 0);
  signal lut_5_10,lc_5_10 : std_logic_vector(7 downto 0);
  signal lut_5_11,lc_5_11 : std_logic_vector(7 downto 0);
  signal lut_5_12,lc_5_12 : std_logic_vector(7 downto 0);
  signal lut_5_13,lc_5_13 : std_logic_vector(7 downto 0);
  signal lut_5_14,lc_5_14 : std_logic_vector(7 downto 0);
  signal lut_5_15,lc_5_15 : std_logic_vector(7 downto 0);
  signal lut_5_16,lc_5_16 : std_logic_vector(7 downto 0);
  signal lut_5_17,lc_5_17 : std_logic_vector(7 downto 0);
  signal lut_5_18,lc_5_18 : std_logic_vector(7 downto 0);
  signal lut_5_19,lc_5_19 : std_logic_vector(7 downto 0);
  signal lut_5_1a,lc_5_1a : std_logic_vector(7 downto 0);
  signal lut_5_1b,lc_5_1b : std_logic_vector(7 downto 0);
  signal lut_5_1c,lc_5_1c : std_logic_vector(7 downto 0);
  signal lut_5_1d,lc_5_1d : std_logic_vector(7 downto 0);
  signal lut_5_1e,lc_5_1e : std_logic_vector(7 downto 0);
  signal lut_5_1f,lc_5_1f : std_logic_vector(7 downto 0);
  signal lut_6_0,lc_6_0 : std_logic_vector(7 downto 0);
  signal lut_6_1,lc_6_1 : std_logic_vector(7 downto 0);
  signal lut_6_2,lc_6_2 : std_logic_vector(7 downto 0);
  signal lut_6_3,lc_6_3 : std_logic_vector(7 downto 0);
  signal lut_6_4,lc_6_4 : std_logic_vector(7 downto 0);
  signal lut_6_5,lc_6_5 : std_logic_vector(7 downto 0);
  signal lut_6_6,lc_6_6 : std_logic_vector(7 downto 0);
  signal lut_6_7,lc_6_7 : std_logic_vector(7 downto 0);
  signal lut_6_8,lc_6_8 : std_logic_vector(7 downto 0);
  signal lut_6_9,lc_6_9 : std_logic_vector(7 downto 0);
  signal lut_6_a,lc_6_a : std_logic_vector(7 downto 0);
  signal lut_6_b,lc_6_b : std_logic_vector(7 downto 0);
  signal lut_6_c,lc_6_c : std_logic_vector(7 downto 0);
  signal lut_6_d,lc_6_d : std_logic_vector(7 downto 0);
  signal lut_6_e,lc_6_e : std_logic_vector(7 downto 0);
  signal lut_6_f,lc_6_f : std_logic_vector(7 downto 0);
  signal lut_7_0,lc_7_0 : std_logic_vector(7 downto 0);
  signal lut_7_1,lc_7_1 : std_logic_vector(7 downto 0);
  signal lut_7_2,lc_7_2 : std_logic_vector(7 downto 0);
  signal lut_7_3,lc_7_3 : std_logic_vector(7 downto 0);
  signal lut_7_4,lc_7_4 : std_logic_vector(7 downto 0);
  signal lut_7_5,lc_7_5 : std_logic_vector(7 downto 0);
  signal lut_7_6,lc_7_6 : std_logic_vector(7 downto 0);
  signal lut_7_7,lc_7_7 : std_logic_vector(7 downto 0);
  signal lut_8_0,lc_8_0 : std_logic_vector(7 downto 0);
  signal lut_8_1,lc_8_1 : std_logic_vector(7 downto 0);
  signal lut_8_2,lc_8_2 : std_logic_vector(7 downto 0);
  signal lut_8_3,lc_8_3 : std_logic_vector(7 downto 0);
  signal lut_9_0,lc_9_0 : std_logic_vector(7 downto 0);
  signal lut_9_1,lc_9_1 : std_logic_vector(7 downto 0);
  signal lut_a_0,lc_a_0 : std_logic_vector(7 downto 0);

begin

  LC_000_00 : pg_lcell
  generic map(MASK=>X"638E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(0));

  LC_000_01 : pg_lcell
  generic map(MASK=>X"83F0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(1));

  LC_000_02 : pg_lcell
  generic map(MASK=>X"FC00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_0(2));

--LC_000_03 
  lc_4_0(3) <= '0';

--LC_000_04 
  lc_4_0(4) <= '0';

--LC_000_05 
  lc_4_0(5) <= '0';

--LC_000_06 
  lc_4_0(6) <= '0';

--LC_000_07 
  lc_4_0(7) <= '0';

  LC_001_00 : pg_lcell
  generic map(MASK=>X"C71C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(0));

  LC_001_01 : pg_lcell
  generic map(MASK=>X"F81F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(1));

  LC_001_02 : pg_lcell
  generic map(MASK=>X"001F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(2));

  LC_001_03 : pg_lcell
  generic map(MASK=>X"FFE0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1(3));

--LC_001_04 
  lc_4_1(4) <= '0';

--LC_001_05 
  lc_4_1(5) <= '0';

--LC_001_06 
  lc_4_1(6) <= '0';

--LC_001_07 
  lc_4_1(7) <= '0';

  LC_002_00 : pg_lcell
  generic map(MASK=>X"8E38",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(0));

  LC_002_01 : pg_lcell
  generic map(MASK=>X"0FC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(1));

  LC_002_02 : pg_lcell
  generic map(MASK=>X"0FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(2));

  LC_002_03 : pg_lcell
  generic map(MASK=>X"0FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(3));

  LC_002_04 : pg_lcell
  generic map(MASK=>X"F000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2(4));

--LC_002_05 
  lc_4_2(5) <= '0';

--LC_002_06 
  lc_4_2(6) <= '0';

--LC_002_07 
  lc_4_2(7) <= '0';

  LC_003_00 : pg_lcell
  generic map(MASK=>X"1CE3",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(0));

  LC_003_01 : pg_lcell
  generic map(MASK=>X"E0FC",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(1));

  LC_003_02 : pg_lcell
  generic map(MASK=>X"FF00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3(2));

--LC_003_03 
  lc_4_3(3) <= '0';

--LC_003_04 
  lc_4_3(4) <= '1';

--LC_003_05 
  lc_4_3(5) <= '0';

--LC_003_06 
  lc_4_3(6) <= '0';

--LC_003_07 
  lc_4_3(7) <= '0';

  LC_004_00 : pg_lcell
  generic map(MASK=>X"71C7",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(0));

  LC_004_01 : pg_lcell
  generic map(MASK=>X"7E07",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(1));

  LC_004_02 : pg_lcell
  generic map(MASK=>X"8007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(2));

  LC_004_03 : pg_lcell
  generic map(MASK=>X"FFF8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_4(3));

--LC_004_04 
  lc_4_4(4) <= '1';

--LC_004_05 
  lc_4_4(5) <= '0';

--LC_004_06 
  lc_4_4(6) <= '0';

--LC_004_07 
  lc_4_4(7) <= '0';

  LC_005_00 : pg_lcell
  generic map(MASK=>X"C71C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(0));

  LC_005_01 : pg_lcell
  generic map(MASK=>X"07E0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(1));

  LC_005_02 : pg_lcell
  generic map(MASK=>X"07FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(2));

  LC_005_03 : pg_lcell
  generic map(MASK=>X"07FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(3));

  LC_005_04 : pg_lcell
  generic map(MASK=>X"07FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(4));

  LC_005_05 : pg_lcell
  generic map(MASK=>X"F800",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_5(5));

--LC_005_06 
  lc_4_5(6) <= '0';

--LC_005_07 
  lc_4_5(7) <= '0';

  LC_006_00 : pg_lcell
  generic map(MASK=>X"1C71",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_6(0));

  LC_006_01 : pg_lcell
  generic map(MASK=>X"E07E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_6(1));

  LC_006_02 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_6(2));

--LC_006_03 
  lc_4_6(3) <= '0';

--LC_006_04 
  lc_4_6(4) <= '0';

--LC_006_05 
  lc_4_6(5) <= '1';

--LC_006_06 
  lc_4_6(6) <= '0';

--LC_006_07 
  lc_4_6(7) <= '0';

  LC_007_00 : pg_lcell
  generic map(MASK=>X"E38E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(0));

  LC_007_01 : pg_lcell
  generic map(MASK=>X"FC0F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(1));

  LC_007_02 : pg_lcell
  generic map(MASK=>X"000F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(2));

  LC_007_03 : pg_lcell
  generic map(MASK=>X"FFF0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_7(3));

--LC_007_04 
  lc_4_7(4) <= '0';

--LC_007_05 
  lc_4_7(5) <= '1';

--LC_007_06 
  lc_4_7(6) <= '0';

--LC_007_07 
  lc_4_7(7) <= '0';

  LC_008_00 : pg_lcell
  generic map(MASK=>X"1E38",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(0));

  LC_008_01 : pg_lcell
  generic map(MASK=>X"1FC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(1));

  LC_008_02 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(2));

  LC_008_03 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(3));

  LC_008_04 : pg_lcell
  generic map(MASK=>X"E000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_8(4));

--LC_008_05 
  lc_4_8(5) <= '1';

--LC_008_06 
  lc_4_8(6) <= '0';

--LC_008_07 
  lc_4_8(7) <= '0';

  LC_009_00 : pg_lcell
  generic map(MASK=>X"F1C7",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(0));

  LC_009_01 : pg_lcell
  generic map(MASK=>X"01F8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(1));

  LC_009_02 : pg_lcell
  generic map(MASK=>X"FE00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_9(2));

--LC_009_03 
  lc_4_9(3) <= '0';

--LC_009_04 
  lc_4_9(4) <= '1';

--LC_009_05 
  lc_4_9(5) <= '1';

--LC_009_06 
  lc_4_9(6) <= '0';

--LC_009_07 
  lc_4_9(7) <= '0';

  LC_00A_00 : pg_lcell
  generic map(MASK=>X"1E38",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_a(0));

  LC_00A_01 : pg_lcell
  generic map(MASK=>X"E03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_a(1));

  LC_00A_02 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_a(2));

  LC_00A_03 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_a(3));

--LC_00A_04 
  lc_4_a(4) <= '1';

--LC_00A_05 
  lc_4_a(5) <= '1';

--LC_00A_06 
  lc_4_a(6) <= '0';

--LC_00A_07 
  lc_4_a(7) <= '0';

  LC_00B_00 : pg_lcell
  generic map(MASK=>X"E3C7",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_b(0));

  LC_00B_01 : pg_lcell
  generic map(MASK=>X"FC07",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_b(1));

  LC_00B_02 : pg_lcell
  generic map(MASK=>X"FFF8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_b(2));

--LC_00B_03 
  lc_4_b(3) <= '1';

--LC_00B_04 
  lc_4_b(4) <= '1';

--LC_00B_05 
  lc_4_b(5) <= '1';

--LC_00B_06 
  lc_4_b(6) <= '0';

--LC_00B_07 
  lc_4_b(7) <= '0';

  LC_00C_00 : pg_lcell
  generic map(MASK=>X"1C78",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(0));

  LC_00C_01 : pg_lcell
  generic map(MASK=>X"1F80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(1));

  LC_00C_02 : pg_lcell
  generic map(MASK=>X"E000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_c(2));

--LC_00C_03 
  lc_4_c(3) <= '0';

--LC_00C_04 
  lc_4_c(4) <= '0';

--LC_00C_05 
  lc_4_c(5) <= '0';

--LC_00C_06 
  lc_4_c(6) <= '1';

--LC_00C_07 
  lc_4_c(7) <= '0';

  LC_00D_00 : pg_lcell
  generic map(MASK=>X"C78E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(0));

  LC_00D_01 : pg_lcell
  generic map(MASK=>X"07F0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(1));

  LC_00D_02 : pg_lcell
  generic map(MASK=>X"07FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(2));

  LC_00D_03 : pg_lcell
  generic map(MASK=>X"F800",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_d(3));

--LC_00D_04 
  lc_4_d(4) <= '0';

--LC_00D_05 
  lc_4_d(5) <= '0';

--LC_00D_06 
  lc_4_d(6) <= '1';

--LC_00D_07 
  lc_4_d(7) <= '0';

  LC_00E_00 : pg_lcell
  generic map(MASK=>X"70E1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_e(0));

  LC_00E_01 : pg_lcell
  generic map(MASK=>X"80FE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_e(1));

  LC_00E_02 : pg_lcell
  generic map(MASK=>X"FF00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_e(2));

--LC_00E_03 
  lc_4_e(3) <= '1';

--LC_00E_04 
  lc_4_e(4) <= '0';

--LC_00E_05 
  lc_4_e(5) <= '0';

--LC_00E_06 
  lc_4_e(6) <= '1';

--LC_00E_07 
  lc_4_e(7) <= '0';

  LC_00F_00 : pg_lcell
  generic map(MASK=>X"1E38",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(0));

  LC_00F_01 : pg_lcell
  generic map(MASK=>X"E03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(1));

  LC_00F_02 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(2));

  LC_00F_03 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(3));

  LC_00F_04 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_f(4));

--LC_00F_05 
  lc_4_f(5) <= '0';

--LC_00F_06 
  lc_4_f(6) <= '1';

--LC_00F_07 
  lc_4_f(7) <= '0';

  LC_010_00 : pg_lcell
  generic map(MASK=>X"C78F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_10(0));

  LC_010_01 : pg_lcell
  generic map(MASK=>X"F80F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_10(1));

  LC_010_02 : pg_lcell
  generic map(MASK=>X"FFF0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_10(2));

--LC_010_03 
  lc_4_10(3) <= '0';

--LC_010_04 
  lc_4_10(4) <= '1';

--LC_010_05 
  lc_4_10(5) <= '0';

--LC_010_06 
  lc_4_10(6) <= '1';

--LC_010_07 
  lc_4_10(7) <= '0';

  LC_011_00 : pg_lcell
  generic map(MASK=>X"F1E3",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_11(0));

  LC_011_01 : pg_lcell
  generic map(MASK=>X"FE03",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_11(1));

  LC_011_02 : pg_lcell
  generic map(MASK=>X"0003",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_11(2));

  LC_011_03 : pg_lcell
  generic map(MASK=>X"FFFC",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_11(3));

--LC_011_04 
  lc_4_11(4) <= '1';

--LC_011_05 
  lc_4_11(5) <= '0';

--LC_011_06 
  lc_4_11(6) <= '1';

--LC_011_07 
  lc_4_11(7) <= '0';

  LC_012_00 : pg_lcell
  generic map(MASK=>X"3878",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_12(0));

  LC_012_01 : pg_lcell
  generic map(MASK=>X"3F80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_12(1));

  LC_012_02 : pg_lcell
  generic map(MASK=>X"3FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_12(2));

  LC_012_03 : pg_lcell
  generic map(MASK=>X"3FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_12(3));

  LC_012_04 : pg_lcell
  generic map(MASK=>X"3FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_12(4));

  LC_012_05 : pg_lcell
  generic map(MASK=>X"C000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_12(5));

--LC_012_06 
  lc_4_12(6) <= '1';

--LC_012_07 
  lc_4_12(7) <= '0';

  LC_013_00 : pg_lcell
  generic map(MASK=>X"1E1C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_13(0));

  LC_013_01 : pg_lcell
  generic map(MASK=>X"1FE0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_13(1));

  LC_013_02 : pg_lcell
  generic map(MASK=>X"E000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_13(2));

--LC_013_03 
  lc_4_13(3) <= '0';

--LC_013_04 
  lc_4_13(4) <= '0';

--LC_013_05 
  lc_4_13(5) <= '1';

--LC_013_06 
  lc_4_13(6) <= '1';

--LC_013_07 
  lc_4_13(7) <= '0';

  LC_014_00 : pg_lcell
  generic map(MASK=>X"870F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_14(0));

  LC_014_01 : pg_lcell
  generic map(MASK=>X"07F0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_14(1));

  LC_014_02 : pg_lcell
  generic map(MASK=>X"07FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_14(2));

  LC_014_03 : pg_lcell
  generic map(MASK=>X"F800",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_14(3));

--LC_014_04 
  lc_4_14(4) <= '0';

--LC_014_05 
  lc_4_14(5) <= '1';

--LC_014_06 
  lc_4_14(6) <= '1';

--LC_014_07 
  lc_4_14(7) <= '0';

  LC_015_00 : pg_lcell
  generic map(MASK=>X"C3C7",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_15(0));

  LC_015_01 : pg_lcell
  generic map(MASK=>X"03F8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_15(1));

  LC_015_02 : pg_lcell
  generic map(MASK=>X"FC00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_15(2));

--LC_015_03 
  lc_4_15(3) <= '1';

--LC_015_04 
  lc_4_15(4) <= '0';

--LC_015_05 
  lc_4_15(5) <= '1';

--LC_015_06 
  lc_4_15(6) <= '1';

--LC_015_07 
  lc_4_15(7) <= '0';

  LC_016_00 : pg_lcell
  generic map(MASK=>X"E1E1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_16(0));

  LC_016_01 : pg_lcell
  generic map(MASK=>X"01FE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_16(1));

  LC_016_02 : pg_lcell
  generic map(MASK=>X"01FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_16(2));

  LC_016_03 : pg_lcell
  generic map(MASK=>X"01FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_16(3));

  LC_016_04 : pg_lcell
  generic map(MASK=>X"FE00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_16(4));

--LC_016_05 
  lc_4_16(5) <= '1';

--LC_016_06 
  lc_4_16(6) <= '1';

--LC_016_07 
  lc_4_16(7) <= '0';

  LC_017_00 : pg_lcell
  generic map(MASK=>X"F0F0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_17(0));

  LC_017_01 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_17(1));

  LC_017_02 : pg_lcell
  generic map(MASK=>X"FF00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_17(2));

--LC_017_03 
  lc_4_17(3) <= '0';

--LC_017_04 
  lc_4_17(4) <= '1';

--LC_017_05 
  lc_4_17(5) <= '1';

--LC_017_06 
  lc_4_17(6) <= '1';

--LC_017_07 
  lc_4_17(7) <= '0';

  LC_018_00 : pg_lcell
  generic map(MASK=>X"7878",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_18(0));

  LC_018_01 : pg_lcell
  generic map(MASK=>X"807F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_18(1));

  LC_018_02 : pg_lcell
  generic map(MASK=>X"007F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_18(2));

  LC_018_03 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_18(3));

--LC_018_04 
  lc_4_18(4) <= '1';

--LC_018_05 
  lc_4_18(5) <= '1';

--LC_018_06 
  lc_4_18(6) <= '1';

--LC_018_07 
  lc_4_18(7) <= '0';

  LC_019_00 : pg_lcell
  generic map(MASK=>X"3C78",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_19(0));

  LC_019_01 : pg_lcell
  generic map(MASK=>X"C07F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_19(1));

  LC_019_02 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_19(2));

--LC_019_03 
  lc_4_19(3) <= '1';

--LC_019_04 
  lc_4_19(4) <= '1';

--LC_019_05 
  lc_4_19(5) <= '1';

--LC_019_06 
  lc_4_19(6) <= '1';

--LC_019_07 
  lc_4_19(7) <= '0';

  LC_01A_00 : pg_lcell
  generic map(MASK=>X"3C3C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1a(0));

  LC_01A_01 : pg_lcell
  generic map(MASK=>X"C03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1a(1));

  LC_01A_02 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1a(2));

  LC_01A_03 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1a(3));

  LC_01A_04 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1a(4));

  LC_01A_05 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1a(5));

  LC_01A_06 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1a(6));

  LC_01A_07 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1a(7));

  LC_01B_00 : pg_lcell
  generic map(MASK=>X"3C3C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1b(0));

  LC_01B_01 : pg_lcell
  generic map(MASK=>X"C03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1b(1));

  LC_01B_02 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1b(2));

--LC_01B_03 
  lc_4_1b(3) <= '0';

--LC_01B_04 
  lc_4_1b(4) <= '0';

--LC_01B_05 
  lc_4_1b(5) <= '0';

--LC_01B_06 
  lc_4_1b(6) <= '0';

--LC_01B_07 
  lc_4_1b(7) <= '1';

  LC_01C_00 : pg_lcell
  generic map(MASK=>X"3C3C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1c(0));

  LC_01C_01 : pg_lcell
  generic map(MASK=>X"C03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1c(1));

  LC_01C_02 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1c(2));

  LC_01C_03 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1c(3));

--LC_01C_04 
  lc_4_1c(4) <= '0';

--LC_01C_05 
  lc_4_1c(5) <= '0';

--LC_01C_06 
  lc_4_1c(6) <= '0';

--LC_01C_07 
  lc_4_1c(7) <= '1';

  LC_01D_00 : pg_lcell
  generic map(MASK=>X"3C3C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1d(0));

  LC_01D_01 : pg_lcell
  generic map(MASK=>X"C03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1d(1));

  LC_01D_02 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1d(2));

--LC_01D_03 
  lc_4_1d(3) <= '1';

--LC_01D_04 
  lc_4_1d(4) <= '0';

--LC_01D_05 
  lc_4_1d(5) <= '0';

--LC_01D_06 
  lc_4_1d(6) <= '0';

--LC_01D_07 
  lc_4_1d(7) <= '1';

  LC_01E_00 : pg_lcell
  generic map(MASK=>X"3C3C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1e(0));

  LC_01E_01 : pg_lcell
  generic map(MASK=>X"C03F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1e(1));

  LC_01E_02 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1e(2));

  LC_01E_03 : pg_lcell
  generic map(MASK=>X"003F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1e(3));

  LC_01E_04 : pg_lcell
  generic map(MASK=>X"FFC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1e(4));

--LC_01E_05 
  lc_4_1e(5) <= '0';

--LC_01E_06 
  lc_4_1e(6) <= '0';

--LC_01E_07 
  lc_4_1e(7) <= '1';

  LC_01F_00 : pg_lcell
  generic map(MASK=>X"7878",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1f(0));

  LC_01F_01 : pg_lcell
  generic map(MASK=>X"807F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1f(1));

  LC_01F_02 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_1f(2));

--LC_01F_03 
  lc_4_1f(3) <= '0';

--LC_01F_04 
  lc_4_1f(4) <= '1';

--LC_01F_05 
  lc_4_1f(5) <= '0';

--LC_01F_06 
  lc_4_1f(6) <= '0';

--LC_01F_07 
  lc_4_1f(7) <= '1';

  LC_020_00 : pg_lcell
  generic map(MASK=>X"F878",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_20(0));

  LC_020_01 : pg_lcell
  generic map(MASK=>X"007F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_20(1));

  LC_020_02 : pg_lcell
  generic map(MASK=>X"007F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_20(2));

  LC_020_03 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_20(3));

--LC_020_04 
  lc_4_20(4) <= '1';

--LC_020_05 
  lc_4_20(5) <= '0';

--LC_020_06 
  lc_4_20(6) <= '0';

--LC_020_07 
  lc_4_20(7) <= '1';

  LC_021_00 : pg_lcell
  generic map(MASK=>X"F0F0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_21(0));

  LC_021_01 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_21(1));

  LC_021_02 : pg_lcell
  generic map(MASK=>X"FF00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_21(2));

--LC_021_03 
  lc_4_21(3) <= '1';

--LC_021_04 
  lc_4_21(4) <= '1';

--LC_021_05 
  lc_4_21(5) <= '0';

--LC_021_06 
  lc_4_21(6) <= '0';

--LC_021_07 
  lc_4_21(7) <= '1';

  LC_022_00 : pg_lcell
  generic map(MASK=>X"E1E1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_22(0));

  LC_022_01 : pg_lcell
  generic map(MASK=>X"01FE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_22(1));

  LC_022_02 : pg_lcell
  generic map(MASK=>X"01FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_22(2));

  LC_022_03 : pg_lcell
  generic map(MASK=>X"01FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_22(3));

  LC_022_04 : pg_lcell
  generic map(MASK=>X"01FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_22(4));

  LC_022_05 : pg_lcell
  generic map(MASK=>X"FE00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_22(5));

--LC_022_06 
  lc_4_22(6) <= '0';

--LC_022_07 
  lc_4_22(7) <= '1';

  LC_023_00 : pg_lcell
  generic map(MASK=>X"83C3",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_23(0));

  LC_023_01 : pg_lcell
  generic map(MASK=>X"03FC",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_23(1));

  LC_023_02 : pg_lcell
  generic map(MASK=>X"FC00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_23(2));

--LC_023_03 
  lc_4_23(3) <= '0';

--LC_023_04 
  lc_4_23(4) <= '0';

--LC_023_05 
  lc_4_23(5) <= '1';

--LC_023_06 
  lc_4_23(6) <= '0';

--LC_023_07 
  lc_4_23(7) <= '1';

  LC_024_00 : pg_lcell
  generic map(MASK=>X"0F87",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_24(0));

  LC_024_01 : pg_lcell
  generic map(MASK=>X"0FF8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_24(1));

  LC_024_02 : pg_lcell
  generic map(MASK=>X"0FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_24(2));

  LC_024_03 : pg_lcell
  generic map(MASK=>X"F000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_24(3));

--LC_024_04 
  lc_4_24(4) <= '0';

--LC_024_05 
  lc_4_24(5) <= '1';

--LC_024_06 
  lc_4_24(6) <= '0';

--LC_024_07 
  lc_4_24(7) <= '1';

  LC_025_00 : pg_lcell
  generic map(MASK=>X"1E0F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_25(0));

  LC_025_01 : pg_lcell
  generic map(MASK=>X"1FF0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_25(1));

  LC_025_02 : pg_lcell
  generic map(MASK=>X"E000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_25(2));

--LC_025_03 
  lc_4_25(3) <= '1';

--LC_025_04 
  lc_4_25(4) <= '0';

--LC_025_05 
  lc_4_25(5) <= '1';

--LC_025_06 
  lc_4_25(6) <= '0';

--LC_025_07 
  lc_4_25(7) <= '1';

  LC_026_00 : pg_lcell
  generic map(MASK=>X"7C3C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_26(0));

  LC_026_01 : pg_lcell
  generic map(MASK=>X"7FC0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_26(1));

  LC_026_02 : pg_lcell
  generic map(MASK=>X"7FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_26(2));

  LC_026_03 : pg_lcell
  generic map(MASK=>X"7FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_26(3));

  LC_026_04 : pg_lcell
  generic map(MASK=>X"8000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_26(4));

--LC_026_05 
  lc_4_26(5) <= '1';

--LC_026_06 
  lc_4_26(6) <= '0';

--LC_026_07 
  lc_4_26(7) <= '1';

  LC_027_00 : pg_lcell
  generic map(MASK=>X"F0F8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_27(0));

  LC_027_01 : pg_lcell
  generic map(MASK=>X"FF00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_27(1));

--LC_027_02 
  lc_4_27(2) <= '0';

--LC_027_03 
  lc_4_27(3) <= '0';

--LC_027_04 
  lc_4_27(4) <= '1';

--LC_027_05 
  lc_4_27(5) <= '1';

--LC_027_06 
  lc_4_27(6) <= '0';

--LC_027_07 
  lc_4_27(7) <= '1';

  LC_028_00 : pg_lcell
  generic map(MASK=>X"C3E1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_28(0));

  LC_028_01 : pg_lcell
  generic map(MASK=>X"FC01",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_28(1));

  LC_028_02 : pg_lcell
  generic map(MASK=>X"FFFE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_28(2));

--LC_028_03 
  lc_4_28(3) <= '0';

--LC_028_04 
  lc_4_28(4) <= '1';

--LC_028_05 
  lc_4_28(5) <= '1';

--LC_028_06 
  lc_4_28(6) <= '0';

--LC_028_07 
  lc_4_28(7) <= '1';

  LC_029_00 : pg_lcell
  generic map(MASK=>X"0F07",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_29(0));

  LC_029_01 : pg_lcell
  generic map(MASK=>X"F007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_29(1));

  LC_029_02 : pg_lcell
  generic map(MASK=>X"0007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_29(2));

  LC_029_03 : pg_lcell
  generic map(MASK=>X"FFF8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_29(3));

--LC_029_04 
  lc_4_29(4) <= '1';

--LC_029_05 
  lc_4_29(5) <= '1';

--LC_029_06 
  lc_4_29(6) <= '0';

--LC_029_07 
  lc_4_29(7) <= '1';

  LC_02A_00 : pg_lcell
  generic map(MASK=>X"7C1E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2a(0));

  LC_02A_01 : pg_lcell
  generic map(MASK=>X"801F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2a(1));

  LC_02A_02 : pg_lcell
  generic map(MASK=>X"FFE0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2a(2));

--LC_02A_03 
  lc_4_2a(3) <= '1';

--LC_02A_04 
  lc_4_2a(4) <= '1';

--LC_02A_05 
  lc_4_2a(5) <= '1';

--LC_02A_06 
  lc_4_2a(6) <= '0';

--LC_02A_07 
  lc_4_2a(7) <= '1';

  LC_02B_00 : pg_lcell
  generic map(MASK=>X"F0F8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2b(0));

  LC_02B_01 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2b(1));

  LC_02B_02 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2b(2));

  LC_02B_03 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2b(3));

  LC_02B_04 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2b(4));

  LC_02B_05 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2b(5));

  LC_02B_06 : pg_lcell
  generic map(MASK=>X"FF00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2b(6));

--LC_02B_07 
  lc_4_2b(7) <= '1';

  LC_02C_00 : pg_lcell
  generic map(MASK=>X"87C1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2c(0));

  LC_02C_01 : pg_lcell
  generic map(MASK=>X"07FE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2c(1));

  LC_02C_02 : pg_lcell
  generic map(MASK=>X"F800",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2c(2));

--LC_02C_03 
  lc_4_2c(3) <= '0';

--LC_02C_04 
  lc_4_2c(4) <= '0';

--LC_02C_05 
  lc_4_2c(5) <= '0';

--LC_02C_06 
  lc_4_2c(6) <= '1';

--LC_02C_07 
  lc_4_2c(7) <= '1';

  LC_02D_00 : pg_lcell
  generic map(MASK=>X"1E0F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2d(0));

  LC_02D_01 : pg_lcell
  generic map(MASK=>X"1FF0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2d(1));

  LC_02D_02 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2d(2));

  LC_02D_03 : pg_lcell
  generic map(MASK=>X"E000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2d(3));

--LC_02D_04 
  lc_4_2d(4) <= '0';

--LC_02D_05 
  lc_4_2d(5) <= '0';

--LC_02D_06 
  lc_4_2d(6) <= '1';

--LC_02D_07 
  lc_4_2d(7) <= '1';

  LC_02E_00 : pg_lcell
  generic map(MASK=>X"F07C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2e(0));

  LC_02E_01 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2e(1));

--LC_02E_02 
  lc_4_2e(2) <= '0';

--LC_02E_03 
  lc_4_2e(3) <= '1';

--LC_02E_04 
  lc_4_2e(4) <= '0';

--LC_02E_05 
  lc_4_2e(5) <= '0';

--LC_02E_06 
  lc_4_2e(6) <= '1';

--LC_02E_07 
  lc_4_2e(7) <= '1';

  LC_02F_00 : pg_lcell
  generic map(MASK=>X"83E1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2f(0));

  LC_02F_01 : pg_lcell
  generic map(MASK=>X"FC01",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2f(1));

  LC_02F_02 : pg_lcell
  generic map(MASK=>X"FFFE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_2f(2));

--LC_02F_03 
  lc_4_2f(3) <= '1';

--LC_02F_04 
  lc_4_2f(4) <= '0';

--LC_02F_05 
  lc_4_2f(5) <= '0';

--LC_02F_06 
  lc_4_2f(6) <= '1';

--LC_02F_07 
  lc_4_2f(7) <= '1';

  LC_030_00 : pg_lcell
  generic map(MASK=>X"3E0F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_30(0));

  LC_030_01 : pg_lcell
  generic map(MASK=>X"C00F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_30(1));

  LC_030_02 : pg_lcell
  generic map(MASK=>X"000F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_30(2));

  LC_030_03 : pg_lcell
  generic map(MASK=>X"000F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_30(3));

  LC_030_04 : pg_lcell
  generic map(MASK=>X"FFF0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_30(4));

--LC_030_05 
  lc_4_30(5) <= '0';

--LC_030_06 
  lc_4_30(6) <= '1';

--LC_030_07 
  lc_4_30(7) <= '1';

  LC_031_00 : pg_lcell
  generic map(MASK=>X"F0F8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_31(0));

  LC_031_01 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_31(1));

  LC_031_02 : pg_lcell
  generic map(MASK=>X"FF00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_31(2));

--LC_031_03 
  lc_4_31(3) <= '0';

--LC_031_04 
  lc_4_31(4) <= '1';

--LC_031_05 
  lc_4_31(5) <= '0';

--LC_031_06 
  lc_4_31(6) <= '1';

--LC_031_07 
  lc_4_31(7) <= '1';

  LC_032_00 : pg_lcell
  generic map(MASK=>X"07C1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_32(0));

  LC_032_01 : pg_lcell
  generic map(MASK=>X"07FE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_32(1));

  LC_032_02 : pg_lcell
  generic map(MASK=>X"07FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_32(2));

  LC_032_03 : pg_lcell
  generic map(MASK=>X"F800",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_32(3));

--LC_032_04 
  lc_4_32(4) <= '1';

--LC_032_05 
  lc_4_32(5) <= '0';

--LC_032_06 
  lc_4_32(6) <= '1';

--LC_032_07 
  lc_4_32(7) <= '1';

  LC_033_00 : pg_lcell
  generic map(MASK=>X"7C1F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_33(0));

  LC_033_01 : pg_lcell
  generic map(MASK=>X"7FE0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_33(1));

  LC_033_02 : pg_lcell
  generic map(MASK=>X"8000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_33(2));

--LC_033_03 
  lc_4_33(3) <= '1';

--LC_033_04 
  lc_4_33(4) <= '1';

--LC_033_05 
  lc_4_33(5) <= '0';

--LC_033_06 
  lc_4_33(6) <= '1';

--LC_033_07 
  lc_4_33(7) <= '1';

  LC_034_00 : pg_lcell
  generic map(MASK=>X"C1F0",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_34(0));

  LC_034_01 : pg_lcell
  generic map(MASK=>X"FE00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_34(1));

--LC_034_02 
  lc_4_34(2) <= '1';

--LC_034_03 
  lc_4_34(3) <= '1';

--LC_034_04 
  lc_4_34(4) <= '1';

--LC_034_05 
  lc_4_34(5) <= '0';

--LC_034_06 
  lc_4_34(6) <= '1';

--LC_034_07 
  lc_4_34(7) <= '1';

  LC_035_00 : pg_lcell
  generic map(MASK=>X"3E07",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_35(0));

  LC_035_01 : pg_lcell
  generic map(MASK=>X"C007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_35(1));

  LC_035_02 : pg_lcell
  generic map(MASK=>X"0007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_35(2));

  LC_035_03 : pg_lcell
  generic map(MASK=>X"0007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_35(3));

  LC_035_04 : pg_lcell
  generic map(MASK=>X"0007",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_35(4));

  LC_035_05 : pg_lcell
  generic map(MASK=>X"FFF8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_35(5));

--LC_035_06 
  lc_4_35(6) <= '1';

--LC_035_07 
  lc_4_35(7) <= '1';

  LC_036_00 : pg_lcell
  generic map(MASK=>X"E0F8",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_36(0));

  LC_036_01 : pg_lcell
  generic map(MASK=>X"00FF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_36(1));

  LC_036_02 : pg_lcell
  generic map(MASK=>X"FF00",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_36(2));

--LC_036_03 
  lc_4_36(3) <= '0';

--LC_036_04 
  lc_4_36(4) <= '0';

--LC_036_05 
  lc_4_36(5) <= '1';

--LC_036_06 
  lc_4_36(6) <= '1';

--LC_036_07 
  lc_4_36(7) <= '1';

  LC_037_00 : pg_lcell
  generic map(MASK=>X"1F83",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_37(0));

  LC_037_01 : pg_lcell
  generic map(MASK=>X"1FFC",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_37(1));

  LC_037_02 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_37(2));

  LC_037_03 : pg_lcell
  generic map(MASK=>X"E000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_37(3));

--LC_037_04 
  lc_4_37(4) <= '0';

--LC_037_05 
  lc_4_37(5) <= '1';

--LC_037_06 
  lc_4_37(6) <= '1';

--LC_037_07 
  lc_4_37(7) <= '1';

  LC_038_00 : pg_lcell
  generic map(MASK=>X"F07C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_38(0));

  LC_038_01 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_38(1));

--LC_038_02 
  lc_4_38(2) <= '0';

--LC_038_03 
  lc_4_38(3) <= '1';

--LC_038_04 
  lc_4_38(4) <= '0';

--LC_038_05 
  lc_4_38(5) <= '1';

--LC_038_06 
  lc_4_38(6) <= '1';

--LC_038_07 
  lc_4_38(7) <= '1';

  LC_039_00 : pg_lcell
  generic map(MASK=>X"0F81",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_39(0));

  LC_039_01 : pg_lcell
  generic map(MASK=>X"F001",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_39(1));

  LC_039_02 : pg_lcell
  generic map(MASK=>X"FFFE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_39(2));

--LC_039_03 
  lc_4_39(3) <= '1';

--LC_039_04 
  lc_4_39(4) <= '0';

--LC_039_05 
  lc_4_39(5) <= '1';

--LC_039_06 
  lc_4_39(6) <= '1';

--LC_039_07 
  lc_4_39(7) <= '1';

  LC_03A_00 : pg_lcell
  generic map(MASK=>X"F07E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3a(0));

  LC_03A_01 : pg_lcell
  generic map(MASK=>X"007F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3a(1));

  LC_03A_02 : pg_lcell
  generic map(MASK=>X"007F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3a(2));

  LC_03A_03 : pg_lcell
  generic map(MASK=>X"007F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3a(3));

  LC_03A_04 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3a(4));

--LC_03A_05 
  lc_4_3a(5) <= '1';

--LC_03A_06 
  lc_4_3a(6) <= '1';

--LC_03A_07 
  lc_4_3a(7) <= '1';

  LC_03B_00 : pg_lcell
  generic map(MASK=>X"0FC1",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3b(0));

  LC_03B_01 : pg_lcell
  generic map(MASK=>X"0FFE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3b(1));

  LC_03B_02 : pg_lcell
  generic map(MASK=>X"F000",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3b(2));

--LC_03B_03 
  lc_4_3b(3) <= '0';

--LC_03B_04 
  lc_4_3b(4) <= '1';

--LC_03B_05 
  lc_4_3b(5) <= '1';

--LC_03B_06 
  lc_4_3b(6) <= '1';

--LC_03B_07 
  lc_4_3b(7) <= '1';

  LC_03C_00 : pg_lcell
  generic map(MASK=>X"F07E",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3c(0));

  LC_03C_01 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3c(1));

--LC_03C_02 
  lc_4_3c(2) <= '1';

--LC_03C_03 
  lc_4_3c(3) <= '0';

--LC_03C_04 
  lc_4_3c(4) <= '1';

--LC_03C_05 
  lc_4_3c(5) <= '1';

--LC_03C_06 
  lc_4_3c(6) <= '1';

--LC_03C_07 
  lc_4_3c(7) <= '1';

  LC_03D_00 : pg_lcell
  generic map(MASK=>X"0F81",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3d(0));

  LC_03D_01 : pg_lcell
  generic map(MASK=>X"F001",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3d(1));

  LC_03D_02 : pg_lcell
  generic map(MASK=>X"0001",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3d(2));

  LC_03D_03 : pg_lcell
  generic map(MASK=>X"FFFE",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3d(3));

--LC_03D_04 
  lc_4_3d(4) <= '1';

--LC_03D_05 
  lc_4_3d(5) <= '1';

--LC_03D_06 
  lc_4_3d(6) <= '1';

--LC_03D_07 
  lc_4_3d(7) <= '1';

  LC_03E_00 : pg_lcell
  generic map(MASK=>X"E07C",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3e(0));

  LC_03E_01 : pg_lcell
  generic map(MASK=>X"007F",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3e(1));

  LC_03E_02 : pg_lcell
  generic map(MASK=>X"FF80",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3e(2));

--LC_03E_03 
  lc_4_3e(3) <= '1';

--LC_03E_04 
  lc_4_3e(4) <= '1';

--LC_03E_05 
  lc_4_3e(5) <= '1';

--LC_03E_06 
  lc_4_3e(6) <= '1';

--LC_03E_07 
  lc_4_3e(7) <= '1';

  LC_03F_00 : pg_lcell
  generic map(MASK=>X"1F03",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3f(0));

  LC_03F_01 : pg_lcell
  generic map(MASK=>X"1FFC",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3f(1));

  LC_03F_02 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3f(2));

  LC_03F_03 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3f(3));

  LC_03F_04 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3f(4));

  LC_03F_05 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3f(5));

  LC_03F_06 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3f(6));

  LC_03F_07 : pg_lcell
  generic map(MASK=>X"1FFF",FF=>0)
  port map( x=>adr0(3 downto 0),clk=>clk,
            z=>lc_4_3f(7));

  adr0 <= indata;
  adr1(9 downto 4) <= adr0(9 downto 4);
  adr2(9 downto 5) <= adr1(9 downto 5);
  adr3(9 downto 6) <= adr2(9 downto 6);
  adr4(9 downto 7) <= adr3(9 downto 7);
  adr5(9 downto 8) <= adr4(9 downto 8);
  process(clk) begin
    if(clk'event and clk='1') then
      adr6(9) <= adr5(9);
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

  with adr1(4) select
    lut_5_8 <= lc_4_10 when '0',
              lc_4_11 when others;

  with adr1(4) select
    lut_5_9 <= lc_4_12 when '0',
              lc_4_13 when others;

  with adr1(4) select
    lut_5_a <= lc_4_14 when '0',
              lc_4_15 when others;

  with adr1(4) select
    lut_5_b <= lc_4_16 when '0',
              lc_4_17 when others;

  with adr1(4) select
    lut_5_c <= lc_4_18 when '0',
              lc_4_19 when others;

  with adr1(4) select
    lut_5_d <= lc_4_1a when '0',
              lc_4_1b when others;

  with adr1(4) select
    lut_5_e <= lc_4_1c when '0',
              lc_4_1d when others;

  with adr1(4) select
    lut_5_f <= lc_4_1e when '0',
              lc_4_1f when others;

  with adr1(4) select
    lut_5_10 <= lc_4_20 when '0',
              lc_4_21 when others;

  with adr1(4) select
    lut_5_11 <= lc_4_22 when '0',
              lc_4_23 when others;

  with adr1(4) select
    lut_5_12 <= lc_4_24 when '0',
              lc_4_25 when others;

  with adr1(4) select
    lut_5_13 <= lc_4_26 when '0',
              lc_4_27 when others;

  with adr1(4) select
    lut_5_14 <= lc_4_28 when '0',
              lc_4_29 when others;

  with adr1(4) select
    lut_5_15 <= lc_4_2a when '0',
              lc_4_2b when others;

  with adr1(4) select
    lut_5_16 <= lc_4_2c when '0',
              lc_4_2d when others;

  with adr1(4) select
    lut_5_17 <= lc_4_2e when '0',
              lc_4_2f when others;

  with adr1(4) select
    lut_5_18 <= lc_4_30 when '0',
              lc_4_31 when others;

  with adr1(4) select
    lut_5_19 <= lc_4_32 when '0',
              lc_4_33 when others;

  with adr1(4) select
    lut_5_1a <= lc_4_34 when '0',
              lc_4_35 when others;

  with adr1(4) select
    lut_5_1b <= lc_4_36 when '0',
              lc_4_37 when others;

  with adr1(4) select
    lut_5_1c <= lc_4_38 when '0',
              lc_4_39 when others;

  with adr1(4) select
    lut_5_1d <= lc_4_3a when '0',
              lc_4_3b when others;

  with adr1(4) select
    lut_5_1e <= lc_4_3c when '0',
              lc_4_3d when others;

  with adr1(4) select
    lut_5_1f <= lc_4_3e when '0',
              lc_4_3f when others;

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

  with adr2(5) select
    lut_6_4 <= lc_5_8 when '0',
              lc_5_9 when others;

  with adr2(5) select
    lut_6_5 <= lc_5_a when '0',
              lc_5_b when others;

  with adr2(5) select
    lut_6_6 <= lc_5_c when '0',
              lc_5_d when others;

  with adr2(5) select
    lut_6_7 <= lc_5_e when '0',
              lc_5_f when others;

  with adr2(5) select
    lut_6_8 <= lc_5_10 when '0',
              lc_5_11 when others;

  with adr2(5) select
    lut_6_9 <= lc_5_12 when '0',
              lc_5_13 when others;

  with adr2(5) select
    lut_6_a <= lc_5_14 when '0',
              lc_5_15 when others;

  with adr2(5) select
    lut_6_b <= lc_5_16 when '0',
              lc_5_17 when others;

  with adr2(5) select
    lut_6_c <= lc_5_18 when '0',
              lc_5_19 when others;

  with adr2(5) select
    lut_6_d <= lc_5_1a when '0',
              lc_5_1b when others;

  with adr2(5) select
    lut_6_e <= lc_5_1c when '0',
              lc_5_1d when others;

  with adr2(5) select
    lut_6_f <= lc_5_1e when '0',
              lc_5_1f when others;

--  =================================
  with adr3(6) select
    lut_7_0 <= lc_6_0 when '0',
              lc_6_1 when others;

  with adr3(6) select
    lut_7_1 <= lc_6_2 when '0',
              lc_6_3 when others;

  with adr3(6) select
    lut_7_2 <= lc_6_4 when '0',
              lc_6_5 when others;

  with adr3(6) select
    lut_7_3 <= lc_6_6 when '0',
              lc_6_7 when others;

  with adr3(6) select
    lut_7_4 <= lc_6_8 when '0',
              lc_6_9 when others;

  with adr3(6) select
    lut_7_5 <= lc_6_a when '0',
              lc_6_b when others;

  with adr3(6) select
    lut_7_6 <= lc_6_c when '0',
              lc_6_d when others;

  with adr3(6) select
    lut_7_7 <= lc_6_e when '0',
              lc_6_f when others;

--  =================================
  with adr4(7) select
    lut_8_0 <= lc_7_0 when '0',
              lc_7_1 when others;

  with adr4(7) select
    lut_8_1 <= lc_7_2 when '0',
              lc_7_3 when others;

  with adr4(7) select
    lut_8_2 <= lc_7_4 when '0',
              lc_7_5 when others;

  with adr4(7) select
    lut_8_3 <= lc_7_6 when '0',
              lc_7_7 when others;

--  =================================
  with adr5(8) select
    lut_9_0 <= lc_8_0 when '0',
              lc_8_1 when others;

  with adr5(8) select
    lut_9_1 <= lc_8_2 when '0',
              lc_8_3 when others;

--  =================================
  with adr6(9) select
    lut_a_0 <= lc_9_0 when '0',
              lc_9_1 when others;


--  =================================
    lc_5_0 <= lut_5_0;
    lc_5_1 <= lut_5_1;
    lc_5_2 <= lut_5_2;
    lc_5_3 <= lut_5_3;
    lc_5_4 <= lut_5_4;
    lc_5_5 <= lut_5_5;
    lc_5_6 <= lut_5_6;
    lc_5_7 <= lut_5_7;
    lc_5_8 <= lut_5_8;
    lc_5_9 <= lut_5_9;
    lc_5_a <= lut_5_a;
    lc_5_b <= lut_5_b;
    lc_5_c <= lut_5_c;
    lc_5_d <= lut_5_d;
    lc_5_e <= lut_5_e;
    lc_5_f <= lut_5_f;
    lc_5_10 <= lut_5_10;
    lc_5_11 <= lut_5_11;
    lc_5_12 <= lut_5_12;
    lc_5_13 <= lut_5_13;
    lc_5_14 <= lut_5_14;
    lc_5_15 <= lut_5_15;
    lc_5_16 <= lut_5_16;
    lc_5_17 <= lut_5_17;
    lc_5_18 <= lut_5_18;
    lc_5_19 <= lut_5_19;
    lc_5_1a <= lut_5_1a;
    lc_5_1b <= lut_5_1b;
    lc_5_1c <= lut_5_1c;
    lc_5_1d <= lut_5_1d;
    lc_5_1e <= lut_5_1e;
    lc_5_1f <= lut_5_1f;
--  =================================
    lc_6_0 <= lut_6_0;
    lc_6_1 <= lut_6_1;
    lc_6_2 <= lut_6_2;
    lc_6_3 <= lut_6_3;
    lc_6_4 <= lut_6_4;
    lc_6_5 <= lut_6_5;
    lc_6_6 <= lut_6_6;
    lc_6_7 <= lut_6_7;
    lc_6_8 <= lut_6_8;
    lc_6_9 <= lut_6_9;
    lc_6_a <= lut_6_a;
    lc_6_b <= lut_6_b;
    lc_6_c <= lut_6_c;
    lc_6_d <= lut_6_d;
    lc_6_e <= lut_6_e;
    lc_6_f <= lut_6_f;
--  =================================
    lc_7_0 <= lut_7_0;
    lc_7_1 <= lut_7_1;
    lc_7_2 <= lut_7_2;
    lc_7_3 <= lut_7_3;
    lc_7_4 <= lut_7_4;
    lc_7_5 <= lut_7_5;
    lc_7_6 <= lut_7_6;
    lc_7_7 <= lut_7_7;
--  =================================
    lc_8_0 <= lut_8_0;
    lc_8_1 <= lut_8_1;
    lc_8_2 <= lut_8_2;
    lc_8_3 <= lut_8_3;
--  =================================
  process(clk) begin
    if(clk'event and clk='1') then
      lc_9_0 <= lut_9_0;
      lc_9_1 <= lut_9_1;
    end if;
  end process;
--  =================================
    lc_a_0 <= lut_a_0;
  outdata <= lc_a_0;
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

