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
                                                                   
  component bram_rom_8408_10_8_1                      
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
                                                                 
  u4: bram_rom_8408_10_8_1
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

-- ROM using Xilinx BlockRAM       
-- Author: Tsuyoshi Hamada         
-- Last Modified at Jun 2, 2004    
-- In 10 Out 8 Stage 1 Type"8408"
library ieee;                      
use ieee.std_logic_1164.all;       
use ieee.std_logic_arith.all;      
use ieee.std_logic_unsigned.all;   

entity bram_rom_8408_10_8_1 is
  port( indata : in std_logic_vector(9 downto 0);
        clk : in std_logic;
        outdata : out std_logic_vector(7 downto 0));
end bram_rom_8408_10_8_1;

architecture rtl of bram_rom_8408_10_8_1 is

  type romarray is array(0 to 1023) of std_logic_vector(7 downto 0);
  signal brom : romarray :=(
    "00000000",   -- 0x0 : 0x0
    "00000001",   -- 0x1 : 0x1
    "00000001",   -- 0x2 : 0x1
    "00000001",   -- 0x3 : 0x1
    "00000010",   -- 0x4 : 0x2
    "00000010",   -- 0x5 : 0x2
    "00000010",   -- 0x6 : 0x2
    "00000011",   -- 0x7 : 0x3
    "00000011",   -- 0x8 : 0x3
    "00000011",   -- 0x9 : 0x3
    "00000100",   -- 0xA : 0x4
    "00000100",   -- 0xB : 0x4
    "00000100",   -- 0xC : 0x4
    "00000101",   -- 0xD : 0x5
    "00000101",   -- 0xE : 0x5
    "00000110",   -- 0xF : 0x6
    "00000110",   -- 0x10 : 0x6
    "00000110",   -- 0x11 : 0x6
    "00000111",   -- 0x12 : 0x7
    "00000111",   -- 0x13 : 0x7
    "00000111",   -- 0x14 : 0x7
    "00001000",   -- 0x15 : 0x8
    "00001000",   -- 0x16 : 0x8
    "00001000",   -- 0x17 : 0x8
    "00001001",   -- 0x18 : 0x9
    "00001001",   -- 0x19 : 0x9
    "00001001",   -- 0x1A : 0x9
    "00001010",   -- 0x1B : 0xA
    "00001010",   -- 0x1C : 0xA
    "00001010",   -- 0x1D : 0xA
    "00001011",   -- 0x1E : 0xB
    "00001011",   -- 0x1F : 0xB
    "00001100",   -- 0x20 : 0xC
    "00001100",   -- 0x21 : 0xC
    "00001100",   -- 0x22 : 0xC
    "00001101",   -- 0x23 : 0xD
    "00001101",   -- 0x24 : 0xD
    "00001101",   -- 0x25 : 0xD
    "00001110",   -- 0x26 : 0xE
    "00001110",   -- 0x27 : 0xE
    "00001110",   -- 0x28 : 0xE
    "00001111",   -- 0x29 : 0xF
    "00001111",   -- 0x2A : 0xF
    "00001111",   -- 0x2B : 0xF
    "00010000",   -- 0x2C : 0x10
    "00010000",   -- 0x2D : 0x10
    "00010000",   -- 0x2E : 0x10
    "00010001",   -- 0x2F : 0x11
    "00010001",   -- 0x30 : 0x11
    "00010001",   -- 0x31 : 0x11
    "00010010",   -- 0x32 : 0x12
    "00010010",   -- 0x33 : 0x12
    "00010010",   -- 0x34 : 0x12
    "00010011",   -- 0x35 : 0x13
    "00010011",   -- 0x36 : 0x13
    "00010011",   -- 0x37 : 0x13
    "00010100",   -- 0x38 : 0x14
    "00010100",   -- 0x39 : 0x14
    "00010101",   -- 0x3A : 0x15
    "00010101",   -- 0x3B : 0x15
    "00010101",   -- 0x3C : 0x15
    "00010110",   -- 0x3D : 0x16
    "00010110",   -- 0x3E : 0x16
    "00010110",   -- 0x3F : 0x16
    "00010111",   -- 0x40 : 0x17
    "00010111",   -- 0x41 : 0x17
    "00010111",   -- 0x42 : 0x17
    "00011000",   -- 0x43 : 0x18
    "00011000",   -- 0x44 : 0x18
    "00011000",   -- 0x45 : 0x18
    "00011001",   -- 0x46 : 0x19
    "00011001",   -- 0x47 : 0x19
    "00011001",   -- 0x48 : 0x19
    "00011010",   -- 0x49 : 0x1A
    "00011010",   -- 0x4A : 0x1A
    "00011010",   -- 0x4B : 0x1A
    "00011011",   -- 0x4C : 0x1B
    "00011011",   -- 0x4D : 0x1B
    "00011011",   -- 0x4E : 0x1B
    "00011100",   -- 0x4F : 0x1C
    "00011100",   -- 0x50 : 0x1C
    "00011100",   -- 0x51 : 0x1C
    "00011101",   -- 0x52 : 0x1D
    "00011101",   -- 0x53 : 0x1D
    "00011101",   -- 0x54 : 0x1D
    "00011110",   -- 0x55 : 0x1E
    "00011110",   -- 0x56 : 0x1E
    "00011110",   -- 0x57 : 0x1E
    "00011111",   -- 0x58 : 0x1F
    "00011111",   -- 0x59 : 0x1F
    "00011111",   -- 0x5A : 0x1F
    "00100000",   -- 0x5B : 0x20
    "00100000",   -- 0x5C : 0x20
    "00100000",   -- 0x5D : 0x20
    "00100001",   -- 0x5E : 0x21
    "00100001",   -- 0x5F : 0x21
    "00100001",   -- 0x60 : 0x21
    "00100010",   -- 0x61 : 0x22
    "00100010",   -- 0x62 : 0x22
    "00100010",   -- 0x63 : 0x22
    "00100011",   -- 0x64 : 0x23
    "00100011",   -- 0x65 : 0x23
    "00100011",   -- 0x66 : 0x23
    "00100100",   -- 0x67 : 0x24
    "00100100",   -- 0x68 : 0x24
    "00100100",   -- 0x69 : 0x24
    "00100101",   -- 0x6A : 0x25
    "00100101",   -- 0x6B : 0x25
    "00100101",   -- 0x6C : 0x25
    "00100110",   -- 0x6D : 0x26
    "00100110",   -- 0x6E : 0x26
    "00100110",   -- 0x6F : 0x26
    "00100110",   -- 0x70 : 0x26
    "00100111",   -- 0x71 : 0x27
    "00100111",   -- 0x72 : 0x27
    "00100111",   -- 0x73 : 0x27
    "00101000",   -- 0x74 : 0x28
    "00101000",   -- 0x75 : 0x28
    "00101000",   -- 0x76 : 0x28
    "00101001",   -- 0x77 : 0x29
    "00101001",   -- 0x78 : 0x29
    "00101001",   -- 0x79 : 0x29
    "00101010",   -- 0x7A : 0x2A
    "00101010",   -- 0x7B : 0x2A
    "00101010",   -- 0x7C : 0x2A
    "00101011",   -- 0x7D : 0x2B
    "00101011",   -- 0x7E : 0x2B
    "00101011",   -- 0x7F : 0x2B
    "00101100",   -- 0x80 : 0x2C
    "00101100",   -- 0x81 : 0x2C
    "00101100",   -- 0x82 : 0x2C
    "00101101",   -- 0x83 : 0x2D
    "00101101",   -- 0x84 : 0x2D
    "00101101",   -- 0x85 : 0x2D
    "00101110",   -- 0x86 : 0x2E
    "00101110",   -- 0x87 : 0x2E
    "00101110",   -- 0x88 : 0x2E
    "00101111",   -- 0x89 : 0x2F
    "00101111",   -- 0x8A : 0x2F
    "00101111",   -- 0x8B : 0x2F
    "00101111",   -- 0x8C : 0x2F
    "00110000",   -- 0x8D : 0x30
    "00110000",   -- 0x8E : 0x30
    "00110000",   -- 0x8F : 0x30
    "00110001",   -- 0x90 : 0x31
    "00110001",   -- 0x91 : 0x31
    "00110001",   -- 0x92 : 0x31
    "00110010",   -- 0x93 : 0x32
    "00110010",   -- 0x94 : 0x32
    "00110010",   -- 0x95 : 0x32
    "00110011",   -- 0x96 : 0x33
    "00110011",   -- 0x97 : 0x33
    "00110011",   -- 0x98 : 0x33
    "00110100",   -- 0x99 : 0x34
    "00110100",   -- 0x9A : 0x34
    "00110100",   -- 0x9B : 0x34
    "00110101",   -- 0x9C : 0x35
    "00110101",   -- 0x9D : 0x35
    "00110101",   -- 0x9E : 0x35
    "00110101",   -- 0x9F : 0x35
    "00110110",   -- 0xA0 : 0x36
    "00110110",   -- 0xA1 : 0x36
    "00110110",   -- 0xA2 : 0x36
    "00110111",   -- 0xA3 : 0x37
    "00110111",   -- 0xA4 : 0x37
    "00110111",   -- 0xA5 : 0x37
    "00111000",   -- 0xA6 : 0x38
    "00111000",   -- 0xA7 : 0x38
    "00111000",   -- 0xA8 : 0x38
    "00111001",   -- 0xA9 : 0x39
    "00111001",   -- 0xAA : 0x39
    "00111001",   -- 0xAB : 0x39
    "00111001",   -- 0xAC : 0x39
    "00111010",   -- 0xAD : 0x3A
    "00111010",   -- 0xAE : 0x3A
    "00111010",   -- 0xAF : 0x3A
    "00111011",   -- 0xB0 : 0x3B
    "00111011",   -- 0xB1 : 0x3B
    "00111011",   -- 0xB2 : 0x3B
    "00111100",   -- 0xB3 : 0x3C
    "00111100",   -- 0xB4 : 0x3C
    "00111100",   -- 0xB5 : 0x3C
    "00111101",   -- 0xB6 : 0x3D
    "00111101",   -- 0xB7 : 0x3D
    "00111101",   -- 0xB8 : 0x3D
    "00111101",   -- 0xB9 : 0x3D
    "00111110",   -- 0xBA : 0x3E
    "00111110",   -- 0xBB : 0x3E
    "00111110",   -- 0xBC : 0x3E
    "00111111",   -- 0xBD : 0x3F
    "00111111",   -- 0xBE : 0x3F
    "00111111",   -- 0xBF : 0x3F
    "01000000",   -- 0xC0 : 0x40
    "01000000",   -- 0xC1 : 0x40
    "01000000",   -- 0xC2 : 0x40
    "01000001",   -- 0xC3 : 0x41
    "01000001",   -- 0xC4 : 0x41
    "01000001",   -- 0xC5 : 0x41
    "01000001",   -- 0xC6 : 0x41
    "01000010",   -- 0xC7 : 0x42
    "01000010",   -- 0xC8 : 0x42
    "01000010",   -- 0xC9 : 0x42
    "01000011",   -- 0xCA : 0x43
    "01000011",   -- 0xCB : 0x43
    "01000011",   -- 0xCC : 0x43
    "01000100",   -- 0xCD : 0x44
    "01000100",   -- 0xCE : 0x44
    "01000100",   -- 0xCF : 0x44
    "01000100",   -- 0xD0 : 0x44
    "01000101",   -- 0xD1 : 0x45
    "01000101",   -- 0xD2 : 0x45
    "01000101",   -- 0xD3 : 0x45
    "01000110",   -- 0xD4 : 0x46
    "01000110",   -- 0xD5 : 0x46
    "01000110",   -- 0xD6 : 0x46
    "01000111",   -- 0xD7 : 0x47
    "01000111",   -- 0xD8 : 0x47
    "01000111",   -- 0xD9 : 0x47
    "01000111",   -- 0xDA : 0x47
    "01001000",   -- 0xDB : 0x48
    "01001000",   -- 0xDC : 0x48
    "01001000",   -- 0xDD : 0x48
    "01001001",   -- 0xDE : 0x49
    "01001001",   -- 0xDF : 0x49
    "01001001",   -- 0xE0 : 0x49
    "01001010",   -- 0xE1 : 0x4A
    "01001010",   -- 0xE2 : 0x4A
    "01001010",   -- 0xE3 : 0x4A
    "01001010",   -- 0xE4 : 0x4A
    "01001011",   -- 0xE5 : 0x4B
    "01001011",   -- 0xE6 : 0x4B
    "01001011",   -- 0xE7 : 0x4B
    "01001100",   -- 0xE8 : 0x4C
    "01001100",   -- 0xE9 : 0x4C
    "01001100",   -- 0xEA : 0x4C
    "01001100",   -- 0xEB : 0x4C
    "01001101",   -- 0xEC : 0x4D
    "01001101",   -- 0xED : 0x4D
    "01001101",   -- 0xEE : 0x4D
    "01001110",   -- 0xEF : 0x4E
    "01001110",   -- 0xF0 : 0x4E
    "01001110",   -- 0xF1 : 0x4E
    "01001110",   -- 0xF2 : 0x4E
    "01001111",   -- 0xF3 : 0x4F
    "01001111",   -- 0xF4 : 0x4F
    "01001111",   -- 0xF5 : 0x4F
    "01010000",   -- 0xF6 : 0x50
    "01010000",   -- 0xF7 : 0x50
    "01010000",   -- 0xF8 : 0x50
    "01010001",   -- 0xF9 : 0x51
    "01010001",   -- 0xFA : 0x51
    "01010001",   -- 0xFB : 0x51
    "01010001",   -- 0xFC : 0x51
    "01010010",   -- 0xFD : 0x52
    "01010010",   -- 0xFE : 0x52
    "01010010",   -- 0xFF : 0x52
    "01010011",   -- 0x100 : 0x53
    "01010011",   -- 0x101 : 0x53
    "01010011",   -- 0x102 : 0x53
    "01010011",   -- 0x103 : 0x53
    "01010100",   -- 0x104 : 0x54
    "01010100",   -- 0x105 : 0x54
    "01010100",   -- 0x106 : 0x54
    "01010101",   -- 0x107 : 0x55
    "01010101",   -- 0x108 : 0x55
    "01010101",   -- 0x109 : 0x55
    "01010101",   -- 0x10A : 0x55
    "01010110",   -- 0x10B : 0x56
    "01010110",   -- 0x10C : 0x56
    "01010110",   -- 0x10D : 0x56
    "01010111",   -- 0x10E : 0x57
    "01010111",   -- 0x10F : 0x57
    "01010111",   -- 0x110 : 0x57
    "01010111",   -- 0x111 : 0x57
    "01011000",   -- 0x112 : 0x58
    "01011000",   -- 0x113 : 0x58
    "01011000",   -- 0x114 : 0x58
    "01011001",   -- 0x115 : 0x59
    "01011001",   -- 0x116 : 0x59
    "01011001",   -- 0x117 : 0x59
    "01011001",   -- 0x118 : 0x59
    "01011010",   -- 0x119 : 0x5A
    "01011010",   -- 0x11A : 0x5A
    "01011010",   -- 0x11B : 0x5A
    "01011011",   -- 0x11C : 0x5B
    "01011011",   -- 0x11D : 0x5B
    "01011011",   -- 0x11E : 0x5B
    "01011011",   -- 0x11F : 0x5B
    "01011100",   -- 0x120 : 0x5C
    "01011100",   -- 0x121 : 0x5C
    "01011100",   -- 0x122 : 0x5C
    "01011101",   -- 0x123 : 0x5D
    "01011101",   -- 0x124 : 0x5D
    "01011101",   -- 0x125 : 0x5D
    "01011101",   -- 0x126 : 0x5D
    "01011110",   -- 0x127 : 0x5E
    "01011110",   -- 0x128 : 0x5E
    "01011110",   -- 0x129 : 0x5E
    "01011110",   -- 0x12A : 0x5E
    "01011111",   -- 0x12B : 0x5F
    "01011111",   -- 0x12C : 0x5F
    "01011111",   -- 0x12D : 0x5F
    "01100000",   -- 0x12E : 0x60
    "01100000",   -- 0x12F : 0x60
    "01100000",   -- 0x130 : 0x60
    "01100000",   -- 0x131 : 0x60
    "01100001",   -- 0x132 : 0x61
    "01100001",   -- 0x133 : 0x61
    "01100001",   -- 0x134 : 0x61
    "01100010",   -- 0x135 : 0x62
    "01100010",   -- 0x136 : 0x62
    "01100010",   -- 0x137 : 0x62
    "01100010",   -- 0x138 : 0x62
    "01100011",   -- 0x139 : 0x63
    "01100011",   -- 0x13A : 0x63
    "01100011",   -- 0x13B : 0x63
    "01100011",   -- 0x13C : 0x63
    "01100100",   -- 0x13D : 0x64
    "01100100",   -- 0x13E : 0x64
    "01100100",   -- 0x13F : 0x64
    "01100101",   -- 0x140 : 0x65
    "01100101",   -- 0x141 : 0x65
    "01100101",   -- 0x142 : 0x65
    "01100101",   -- 0x143 : 0x65
    "01100110",   -- 0x144 : 0x66
    "01100110",   -- 0x145 : 0x66
    "01100110",   -- 0x146 : 0x66
    "01100110",   -- 0x147 : 0x66
    "01100111",   -- 0x148 : 0x67
    "01100111",   -- 0x149 : 0x67
    "01100111",   -- 0x14A : 0x67
    "01101000",   -- 0x14B : 0x68
    "01101000",   -- 0x14C : 0x68
    "01101000",   -- 0x14D : 0x68
    "01101000",   -- 0x14E : 0x68
    "01101001",   -- 0x14F : 0x69
    "01101001",   -- 0x150 : 0x69
    "01101001",   -- 0x151 : 0x69
    "01101001",   -- 0x152 : 0x69
    "01101010",   -- 0x153 : 0x6A
    "01101010",   -- 0x154 : 0x6A
    "01101010",   -- 0x155 : 0x6A
    "01101011",   -- 0x156 : 0x6B
    "01101011",   -- 0x157 : 0x6B
    "01101011",   -- 0x158 : 0x6B
    "01101011",   -- 0x159 : 0x6B
    "01101100",   -- 0x15A : 0x6C
    "01101100",   -- 0x15B : 0x6C
    "01101100",   -- 0x15C : 0x6C
    "01101100",   -- 0x15D : 0x6C
    "01101101",   -- 0x15E : 0x6D
    "01101101",   -- 0x15F : 0x6D
    "01101101",   -- 0x160 : 0x6D
    "01101110",   -- 0x161 : 0x6E
    "01101110",   -- 0x162 : 0x6E
    "01101110",   -- 0x163 : 0x6E
    "01101110",   -- 0x164 : 0x6E
    "01101111",   -- 0x165 : 0x6F
    "01101111",   -- 0x166 : 0x6F
    "01101111",   -- 0x167 : 0x6F
    "01101111",   -- 0x168 : 0x6F
    "01110000",   -- 0x169 : 0x70
    "01110000",   -- 0x16A : 0x70
    "01110000",   -- 0x16B : 0x70
    "01110000",   -- 0x16C : 0x70
    "01110001",   -- 0x16D : 0x71
    "01110001",   -- 0x16E : 0x71
    "01110001",   -- 0x16F : 0x71
    "01110010",   -- 0x170 : 0x72
    "01110010",   -- 0x171 : 0x72
    "01110010",   -- 0x172 : 0x72
    "01110010",   -- 0x173 : 0x72
    "01110011",   -- 0x174 : 0x73
    "01110011",   -- 0x175 : 0x73
    "01110011",   -- 0x176 : 0x73
    "01110011",   -- 0x177 : 0x73
    "01110100",   -- 0x178 : 0x74
    "01110100",   -- 0x179 : 0x74
    "01110100",   -- 0x17A : 0x74
    "01110100",   -- 0x17B : 0x74
    "01110101",   -- 0x17C : 0x75
    "01110101",   -- 0x17D : 0x75
    "01110101",   -- 0x17E : 0x75
    "01110101",   -- 0x17F : 0x75
    "01110110",   -- 0x180 : 0x76
    "01110110",   -- 0x181 : 0x76
    "01110110",   -- 0x182 : 0x76
    "01110111",   -- 0x183 : 0x77
    "01110111",   -- 0x184 : 0x77
    "01110111",   -- 0x185 : 0x77
    "01110111",   -- 0x186 : 0x77
    "01111000",   -- 0x187 : 0x78
    "01111000",   -- 0x188 : 0x78
    "01111000",   -- 0x189 : 0x78
    "01111000",   -- 0x18A : 0x78
    "01111001",   -- 0x18B : 0x79
    "01111001",   -- 0x18C : 0x79
    "01111001",   -- 0x18D : 0x79
    "01111001",   -- 0x18E : 0x79
    "01111010",   -- 0x18F : 0x7A
    "01111010",   -- 0x190 : 0x7A
    "01111010",   -- 0x191 : 0x7A
    "01111010",   -- 0x192 : 0x7A
    "01111011",   -- 0x193 : 0x7B
    "01111011",   -- 0x194 : 0x7B
    "01111011",   -- 0x195 : 0x7B
    "01111011",   -- 0x196 : 0x7B
    "01111100",   -- 0x197 : 0x7C
    "01111100",   -- 0x198 : 0x7C
    "01111100",   -- 0x199 : 0x7C
    "01111101",   -- 0x19A : 0x7D
    "01111101",   -- 0x19B : 0x7D
    "01111101",   -- 0x19C : 0x7D
    "01111101",   -- 0x19D : 0x7D
    "01111110",   -- 0x19E : 0x7E
    "01111110",   -- 0x19F : 0x7E
    "01111110",   -- 0x1A0 : 0x7E
    "01111110",   -- 0x1A1 : 0x7E
    "01111111",   -- 0x1A2 : 0x7F
    "01111111",   -- 0x1A3 : 0x7F
    "01111111",   -- 0x1A4 : 0x7F
    "01111111",   -- 0x1A5 : 0x7F
    "10000000",   -- 0x1A6 : 0x80
    "10000000",   -- 0x1A7 : 0x80
    "10000000",   -- 0x1A8 : 0x80
    "10000000",   -- 0x1A9 : 0x80
    "10000001",   -- 0x1AA : 0x81
    "10000001",   -- 0x1AB : 0x81
    "10000001",   -- 0x1AC : 0x81
    "10000001",   -- 0x1AD : 0x81
    "10000010",   -- 0x1AE : 0x82
    "10000010",   -- 0x1AF : 0x82
    "10000010",   -- 0x1B0 : 0x82
    "10000010",   -- 0x1B1 : 0x82
    "10000011",   -- 0x1B2 : 0x83
    "10000011",   -- 0x1B3 : 0x83
    "10000011",   -- 0x1B4 : 0x83
    "10000011",   -- 0x1B5 : 0x83
    "10000100",   -- 0x1B6 : 0x84
    "10000100",   -- 0x1B7 : 0x84
    "10000100",   -- 0x1B8 : 0x84
    "10000100",   -- 0x1B9 : 0x84
    "10000101",   -- 0x1BA : 0x85
    "10000101",   -- 0x1BB : 0x85
    "10000101",   -- 0x1BC : 0x85
    "10000101",   -- 0x1BD : 0x85
    "10000110",   -- 0x1BE : 0x86
    "10000110",   -- 0x1BF : 0x86
    "10000110",   -- 0x1C0 : 0x86
    "10000110",   -- 0x1C1 : 0x86
    "10000111",   -- 0x1C2 : 0x87
    "10000111",   -- 0x1C3 : 0x87
    "10000111",   -- 0x1C4 : 0x87
    "10000111",   -- 0x1C5 : 0x87
    "10001000",   -- 0x1C6 : 0x88
    "10001000",   -- 0x1C7 : 0x88
    "10001000",   -- 0x1C8 : 0x88
    "10001000",   -- 0x1C9 : 0x88
    "10001001",   -- 0x1CA : 0x89
    "10001001",   -- 0x1CB : 0x89
    "10001001",   -- 0x1CC : 0x89
    "10001001",   -- 0x1CD : 0x89
    "10001010",   -- 0x1CE : 0x8A
    "10001010",   -- 0x1CF : 0x8A
    "10001010",   -- 0x1D0 : 0x8A
    "10001010",   -- 0x1D1 : 0x8A
    "10001011",   -- 0x1D2 : 0x8B
    "10001011",   -- 0x1D3 : 0x8B
    "10001011",   -- 0x1D4 : 0x8B
    "10001011",   -- 0x1D5 : 0x8B
    "10001100",   -- 0x1D6 : 0x8C
    "10001100",   -- 0x1D7 : 0x8C
    "10001100",   -- 0x1D8 : 0x8C
    "10001100",   -- 0x1D9 : 0x8C
    "10001101",   -- 0x1DA : 0x8D
    "10001101",   -- 0x1DB : 0x8D
    "10001101",   -- 0x1DC : 0x8D
    "10001101",   -- 0x1DD : 0x8D
    "10001110",   -- 0x1DE : 0x8E
    "10001110",   -- 0x1DF : 0x8E
    "10001110",   -- 0x1E0 : 0x8E
    "10001110",   -- 0x1E1 : 0x8E
    "10001111",   -- 0x1E2 : 0x8F
    "10001111",   -- 0x1E3 : 0x8F
    "10001111",   -- 0x1E4 : 0x8F
    "10001111",   -- 0x1E5 : 0x8F
    "10010000",   -- 0x1E6 : 0x90
    "10010000",   -- 0x1E7 : 0x90
    "10010000",   -- 0x1E8 : 0x90
    "10010000",   -- 0x1E9 : 0x90
    "10010001",   -- 0x1EA : 0x91
    "10010001",   -- 0x1EB : 0x91
    "10010001",   -- 0x1EC : 0x91
    "10010001",   -- 0x1ED : 0x91
    "10010010",   -- 0x1EE : 0x92
    "10010010",   -- 0x1EF : 0x92
    "10010010",   -- 0x1F0 : 0x92
    "10010010",   -- 0x1F1 : 0x92
    "10010010",   -- 0x1F2 : 0x92
    "10010011",   -- 0x1F3 : 0x93
    "10010011",   -- 0x1F4 : 0x93
    "10010011",   -- 0x1F5 : 0x93
    "10010011",   -- 0x1F6 : 0x93
    "10010100",   -- 0x1F7 : 0x94
    "10010100",   -- 0x1F8 : 0x94
    "10010100",   -- 0x1F9 : 0x94
    "10010100",   -- 0x1FA : 0x94
    "10010101",   -- 0x1FB : 0x95
    "10010101",   -- 0x1FC : 0x95
    "10010101",   -- 0x1FD : 0x95
    "10010101",   -- 0x1FE : 0x95
    "10010110",   -- 0x1FF : 0x96
    "10010110",   -- 0x200 : 0x96
    "10010110",   -- 0x201 : 0x96
    "10010110",   -- 0x202 : 0x96
    "10010111",   -- 0x203 : 0x97
    "10010111",   -- 0x204 : 0x97
    "10010111",   -- 0x205 : 0x97
    "10010111",   -- 0x206 : 0x97
    "10011000",   -- 0x207 : 0x98
    "10011000",   -- 0x208 : 0x98
    "10011000",   -- 0x209 : 0x98
    "10011000",   -- 0x20A : 0x98
    "10011001",   -- 0x20B : 0x99
    "10011001",   -- 0x20C : 0x99
    "10011001",   -- 0x20D : 0x99
    "10011001",   -- 0x20E : 0x99
    "10011001",   -- 0x20F : 0x99
    "10011010",   -- 0x210 : 0x9A
    "10011010",   -- 0x211 : 0x9A
    "10011010",   -- 0x212 : 0x9A
    "10011010",   -- 0x213 : 0x9A
    "10011011",   -- 0x214 : 0x9B
    "10011011",   -- 0x215 : 0x9B
    "10011011",   -- 0x216 : 0x9B
    "10011011",   -- 0x217 : 0x9B
    "10011100",   -- 0x218 : 0x9C
    "10011100",   -- 0x219 : 0x9C
    "10011100",   -- 0x21A : 0x9C
    "10011100",   -- 0x21B : 0x9C
    "10011101",   -- 0x21C : 0x9D
    "10011101",   -- 0x21D : 0x9D
    "10011101",   -- 0x21E : 0x9D
    "10011101",   -- 0x21F : 0x9D
    "10011101",   -- 0x220 : 0x9D
    "10011110",   -- 0x221 : 0x9E
    "10011110",   -- 0x222 : 0x9E
    "10011110",   -- 0x223 : 0x9E
    "10011110",   -- 0x224 : 0x9E
    "10011111",   -- 0x225 : 0x9F
    "10011111",   -- 0x226 : 0x9F
    "10011111",   -- 0x227 : 0x9F
    "10011111",   -- 0x228 : 0x9F
    "10100000",   -- 0x229 : 0xA0
    "10100000",   -- 0x22A : 0xA0
    "10100000",   -- 0x22B : 0xA0
    "10100000",   -- 0x22C : 0xA0
    "10100001",   -- 0x22D : 0xA1
    "10100001",   -- 0x22E : 0xA1
    "10100001",   -- 0x22F : 0xA1
    "10100001",   -- 0x230 : 0xA1
    "10100001",   -- 0x231 : 0xA1
    "10100010",   -- 0x232 : 0xA2
    "10100010",   -- 0x233 : 0xA2
    "10100010",   -- 0x234 : 0xA2
    "10100010",   -- 0x235 : 0xA2
    "10100011",   -- 0x236 : 0xA3
    "10100011",   -- 0x237 : 0xA3
    "10100011",   -- 0x238 : 0xA3
    "10100011",   -- 0x239 : 0xA3
    "10100100",   -- 0x23A : 0xA4
    "10100100",   -- 0x23B : 0xA4
    "10100100",   -- 0x23C : 0xA4
    "10100100",   -- 0x23D : 0xA4
    "10100100",   -- 0x23E : 0xA4
    "10100101",   -- 0x23F : 0xA5
    "10100101",   -- 0x240 : 0xA5
    "10100101",   -- 0x241 : 0xA5
    "10100101",   -- 0x242 : 0xA5
    "10100110",   -- 0x243 : 0xA6
    "10100110",   -- 0x244 : 0xA6
    "10100110",   -- 0x245 : 0xA6
    "10100110",   -- 0x246 : 0xA6
    "10100111",   -- 0x247 : 0xA7
    "10100111",   -- 0x248 : 0xA7
    "10100111",   -- 0x249 : 0xA7
    "10100111",   -- 0x24A : 0xA7
    "10100111",   -- 0x24B : 0xA7
    "10101000",   -- 0x24C : 0xA8
    "10101000",   -- 0x24D : 0xA8
    "10101000",   -- 0x24E : 0xA8
    "10101000",   -- 0x24F : 0xA8
    "10101001",   -- 0x250 : 0xA9
    "10101001",   -- 0x251 : 0xA9
    "10101001",   -- 0x252 : 0xA9
    "10101001",   -- 0x253 : 0xA9
    "10101010",   -- 0x254 : 0xAA
    "10101010",   -- 0x255 : 0xAA
    "10101010",   -- 0x256 : 0xAA
    "10101010",   -- 0x257 : 0xAA
    "10101010",   -- 0x258 : 0xAA
    "10101011",   -- 0x259 : 0xAB
    "10101011",   -- 0x25A : 0xAB
    "10101011",   -- 0x25B : 0xAB
    "10101011",   -- 0x25C : 0xAB
    "10101100",   -- 0x25D : 0xAC
    "10101100",   -- 0x25E : 0xAC
    "10101100",   -- 0x25F : 0xAC
    "10101100",   -- 0x260 : 0xAC
    "10101100",   -- 0x261 : 0xAC
    "10101101",   -- 0x262 : 0xAD
    "10101101",   -- 0x263 : 0xAD
    "10101101",   -- 0x264 : 0xAD
    "10101101",   -- 0x265 : 0xAD
    "10101110",   -- 0x266 : 0xAE
    "10101110",   -- 0x267 : 0xAE
    "10101110",   -- 0x268 : 0xAE
    "10101110",   -- 0x269 : 0xAE
    "10101111",   -- 0x26A : 0xAF
    "10101111",   -- 0x26B : 0xAF
    "10101111",   -- 0x26C : 0xAF
    "10101111",   -- 0x26D : 0xAF
    "10101111",   -- 0x26E : 0xAF
    "10110000",   -- 0x26F : 0xB0
    "10110000",   -- 0x270 : 0xB0
    "10110000",   -- 0x271 : 0xB0
    "10110000",   -- 0x272 : 0xB0
    "10110001",   -- 0x273 : 0xB1
    "10110001",   -- 0x274 : 0xB1
    "10110001",   -- 0x275 : 0xB1
    "10110001",   -- 0x276 : 0xB1
    "10110001",   -- 0x277 : 0xB1
    "10110010",   -- 0x278 : 0xB2
    "10110010",   -- 0x279 : 0xB2
    "10110010",   -- 0x27A : 0xB2
    "10110010",   -- 0x27B : 0xB2
    "10110011",   -- 0x27C : 0xB3
    "10110011",   -- 0x27D : 0xB3
    "10110011",   -- 0x27E : 0xB3
    "10110011",   -- 0x27F : 0xB3
    "10110011",   -- 0x280 : 0xB3
    "10110100",   -- 0x281 : 0xB4
    "10110100",   -- 0x282 : 0xB4
    "10110100",   -- 0x283 : 0xB4
    "10110100",   -- 0x284 : 0xB4
    "10110101",   -- 0x285 : 0xB5
    "10110101",   -- 0x286 : 0xB5
    "10110101",   -- 0x287 : 0xB5
    "10110101",   -- 0x288 : 0xB5
    "10110101",   -- 0x289 : 0xB5
    "10110110",   -- 0x28A : 0xB6
    "10110110",   -- 0x28B : 0xB6
    "10110110",   -- 0x28C : 0xB6
    "10110110",   -- 0x28D : 0xB6
    "10110111",   -- 0x28E : 0xB7
    "10110111",   -- 0x28F : 0xB7
    "10110111",   -- 0x290 : 0xB7
    "10110111",   -- 0x291 : 0xB7
    "10110111",   -- 0x292 : 0xB7
    "10111000",   -- 0x293 : 0xB8
    "10111000",   -- 0x294 : 0xB8
    "10111000",   -- 0x295 : 0xB8
    "10111000",   -- 0x296 : 0xB8
    "10111000",   -- 0x297 : 0xB8
    "10111001",   -- 0x298 : 0xB9
    "10111001",   -- 0x299 : 0xB9
    "10111001",   -- 0x29A : 0xB9
    "10111001",   -- 0x29B : 0xB9
    "10111010",   -- 0x29C : 0xBA
    "10111010",   -- 0x29D : 0xBA
    "10111010",   -- 0x29E : 0xBA
    "10111010",   -- 0x29F : 0xBA
    "10111010",   -- 0x2A0 : 0xBA
    "10111011",   -- 0x2A1 : 0xBB
    "10111011",   -- 0x2A2 : 0xBB
    "10111011",   -- 0x2A3 : 0xBB
    "10111011",   -- 0x2A4 : 0xBB
    "10111100",   -- 0x2A5 : 0xBC
    "10111100",   -- 0x2A6 : 0xBC
    "10111100",   -- 0x2A7 : 0xBC
    "10111100",   -- 0x2A8 : 0xBC
    "10111100",   -- 0x2A9 : 0xBC
    "10111101",   -- 0x2AA : 0xBD
    "10111101",   -- 0x2AB : 0xBD
    "10111101",   -- 0x2AC : 0xBD
    "10111101",   -- 0x2AD : 0xBD
    "10111101",   -- 0x2AE : 0xBD
    "10111110",   -- 0x2AF : 0xBE
    "10111110",   -- 0x2B0 : 0xBE
    "10111110",   -- 0x2B1 : 0xBE
    "10111110",   -- 0x2B2 : 0xBE
    "10111111",   -- 0x2B3 : 0xBF
    "10111111",   -- 0x2B4 : 0xBF
    "10111111",   -- 0x2B5 : 0xBF
    "10111111",   -- 0x2B6 : 0xBF
    "10111111",   -- 0x2B7 : 0xBF
    "11000000",   -- 0x2B8 : 0xC0
    "11000000",   -- 0x2B9 : 0xC0
    "11000000",   -- 0x2BA : 0xC0
    "11000000",   -- 0x2BB : 0xC0
    "11000001",   -- 0x2BC : 0xC1
    "11000001",   -- 0x2BD : 0xC1
    "11000001",   -- 0x2BE : 0xC1
    "11000001",   -- 0x2BF : 0xC1
    "11000001",   -- 0x2C0 : 0xC1
    "11000010",   -- 0x2C1 : 0xC2
    "11000010",   -- 0x2C2 : 0xC2
    "11000010",   -- 0x2C3 : 0xC2
    "11000010",   -- 0x2C4 : 0xC2
    "11000010",   -- 0x2C5 : 0xC2
    "11000011",   -- 0x2C6 : 0xC3
    "11000011",   -- 0x2C7 : 0xC3
    "11000011",   -- 0x2C8 : 0xC3
    "11000011",   -- 0x2C9 : 0xC3
    "11000011",   -- 0x2CA : 0xC3
    "11000100",   -- 0x2CB : 0xC4
    "11000100",   -- 0x2CC : 0xC4
    "11000100",   -- 0x2CD : 0xC4
    "11000100",   -- 0x2CE : 0xC4
    "11000101",   -- 0x2CF : 0xC5
    "11000101",   -- 0x2D0 : 0xC5
    "11000101",   -- 0x2D1 : 0xC5
    "11000101",   -- 0x2D2 : 0xC5
    "11000101",   -- 0x2D3 : 0xC5
    "11000110",   -- 0x2D4 : 0xC6
    "11000110",   -- 0x2D5 : 0xC6
    "11000110",   -- 0x2D6 : 0xC6
    "11000110",   -- 0x2D7 : 0xC6
    "11000110",   -- 0x2D8 : 0xC6
    "11000111",   -- 0x2D9 : 0xC7
    "11000111",   -- 0x2DA : 0xC7
    "11000111",   -- 0x2DB : 0xC7
    "11000111",   -- 0x2DC : 0xC7
    "11001000",   -- 0x2DD : 0xC8
    "11001000",   -- 0x2DE : 0xC8
    "11001000",   -- 0x2DF : 0xC8
    "11001000",   -- 0x2E0 : 0xC8
    "11001000",   -- 0x2E1 : 0xC8
    "11001001",   -- 0x2E2 : 0xC9
    "11001001",   -- 0x2E3 : 0xC9
    "11001001",   -- 0x2E4 : 0xC9
    "11001001",   -- 0x2E5 : 0xC9
    "11001001",   -- 0x2E6 : 0xC9
    "11001010",   -- 0x2E7 : 0xCA
    "11001010",   -- 0x2E8 : 0xCA
    "11001010",   -- 0x2E9 : 0xCA
    "11001010",   -- 0x2EA : 0xCA
    "11001010",   -- 0x2EB : 0xCA
    "11001011",   -- 0x2EC : 0xCB
    "11001011",   -- 0x2ED : 0xCB
    "11001011",   -- 0x2EE : 0xCB
    "11001011",   -- 0x2EF : 0xCB
    "11001011",   -- 0x2F0 : 0xCB
    "11001100",   -- 0x2F1 : 0xCC
    "11001100",   -- 0x2F2 : 0xCC
    "11001100",   -- 0x2F3 : 0xCC
    "11001100",   -- 0x2F4 : 0xCC
    "11001101",   -- 0x2F5 : 0xCD
    "11001101",   -- 0x2F6 : 0xCD
    "11001101",   -- 0x2F7 : 0xCD
    "11001101",   -- 0x2F8 : 0xCD
    "11001101",   -- 0x2F9 : 0xCD
    "11001110",   -- 0x2FA : 0xCE
    "11001110",   -- 0x2FB : 0xCE
    "11001110",   -- 0x2FC : 0xCE
    "11001110",   -- 0x2FD : 0xCE
    "11001110",   -- 0x2FE : 0xCE
    "11001111",   -- 0x2FF : 0xCF
    "11001111",   -- 0x300 : 0xCF
    "11001111",   -- 0x301 : 0xCF
    "11001111",   -- 0x302 : 0xCF
    "11001111",   -- 0x303 : 0xCF
    "11010000",   -- 0x304 : 0xD0
    "11010000",   -- 0x305 : 0xD0
    "11010000",   -- 0x306 : 0xD0
    "11010000",   -- 0x307 : 0xD0
    "11010000",   -- 0x308 : 0xD0
    "11010001",   -- 0x309 : 0xD1
    "11010001",   -- 0x30A : 0xD1
    "11010001",   -- 0x30B : 0xD1
    "11010001",   -- 0x30C : 0xD1
    "11010001",   -- 0x30D : 0xD1
    "11010010",   -- 0x30E : 0xD2
    "11010010",   -- 0x30F : 0xD2
    "11010010",   -- 0x310 : 0xD2
    "11010010",   -- 0x311 : 0xD2
    "11010010",   -- 0x312 : 0xD2
    "11010011",   -- 0x313 : 0xD3
    "11010011",   -- 0x314 : 0xD3
    "11010011",   -- 0x315 : 0xD3
    "11010011",   -- 0x316 : 0xD3
    "11010011",   -- 0x317 : 0xD3
    "11010100",   -- 0x318 : 0xD4
    "11010100",   -- 0x319 : 0xD4
    "11010100",   -- 0x31A : 0xD4
    "11010100",   -- 0x31B : 0xD4
    "11010101",   -- 0x31C : 0xD5
    "11010101",   -- 0x31D : 0xD5
    "11010101",   -- 0x31E : 0xD5
    "11010101",   -- 0x31F : 0xD5
    "11010101",   -- 0x320 : 0xD5
    "11010110",   -- 0x321 : 0xD6
    "11010110",   -- 0x322 : 0xD6
    "11010110",   -- 0x323 : 0xD6
    "11010110",   -- 0x324 : 0xD6
    "11010110",   -- 0x325 : 0xD6
    "11010111",   -- 0x326 : 0xD7
    "11010111",   -- 0x327 : 0xD7
    "11010111",   -- 0x328 : 0xD7
    "11010111",   -- 0x329 : 0xD7
    "11010111",   -- 0x32A : 0xD7
    "11011000",   -- 0x32B : 0xD8
    "11011000",   -- 0x32C : 0xD8
    "11011000",   -- 0x32D : 0xD8
    "11011000",   -- 0x32E : 0xD8
    "11011000",   -- 0x32F : 0xD8
    "11011001",   -- 0x330 : 0xD9
    "11011001",   -- 0x331 : 0xD9
    "11011001",   -- 0x332 : 0xD9
    "11011001",   -- 0x333 : 0xD9
    "11011001",   -- 0x334 : 0xD9
    "11011010",   -- 0x335 : 0xDA
    "11011010",   -- 0x336 : 0xDA
    "11011010",   -- 0x337 : 0xDA
    "11011010",   -- 0x338 : 0xDA
    "11011010",   -- 0x339 : 0xDA
    "11011011",   -- 0x33A : 0xDB
    "11011011",   -- 0x33B : 0xDB
    "11011011",   -- 0x33C : 0xDB
    "11011011",   -- 0x33D : 0xDB
    "11011011",   -- 0x33E : 0xDB
    "11011100",   -- 0x33F : 0xDC
    "11011100",   -- 0x340 : 0xDC
    "11011100",   -- 0x341 : 0xDC
    "11011100",   -- 0x342 : 0xDC
    "11011100",   -- 0x343 : 0xDC
    "11011101",   -- 0x344 : 0xDD
    "11011101",   -- 0x345 : 0xDD
    "11011101",   -- 0x346 : 0xDD
    "11011101",   -- 0x347 : 0xDD
    "11011101",   -- 0x348 : 0xDD
    "11011110",   -- 0x349 : 0xDE
    "11011110",   -- 0x34A : 0xDE
    "11011110",   -- 0x34B : 0xDE
    "11011110",   -- 0x34C : 0xDE
    "11011110",   -- 0x34D : 0xDE
    "11011111",   -- 0x34E : 0xDF
    "11011111",   -- 0x34F : 0xDF
    "11011111",   -- 0x350 : 0xDF
    "11011111",   -- 0x351 : 0xDF
    "11011111",   -- 0x352 : 0xDF
    "11100000",   -- 0x353 : 0xE0
    "11100000",   -- 0x354 : 0xE0
    "11100000",   -- 0x355 : 0xE0
    "11100000",   -- 0x356 : 0xE0
    "11100000",   -- 0x357 : 0xE0
    "11100000",   -- 0x358 : 0xE0
    "11100001",   -- 0x359 : 0xE1
    "11100001",   -- 0x35A : 0xE1
    "11100001",   -- 0x35B : 0xE1
    "11100001",   -- 0x35C : 0xE1
    "11100001",   -- 0x35D : 0xE1
    "11100010",   -- 0x35E : 0xE2
    "11100010",   -- 0x35F : 0xE2
    "11100010",   -- 0x360 : 0xE2
    "11100010",   -- 0x361 : 0xE2
    "11100010",   -- 0x362 : 0xE2
    "11100011",   -- 0x363 : 0xE3
    "11100011",   -- 0x364 : 0xE3
    "11100011",   -- 0x365 : 0xE3
    "11100011",   -- 0x366 : 0xE3
    "11100011",   -- 0x367 : 0xE3
    "11100100",   -- 0x368 : 0xE4
    "11100100",   -- 0x369 : 0xE4
    "11100100",   -- 0x36A : 0xE4
    "11100100",   -- 0x36B : 0xE4
    "11100100",   -- 0x36C : 0xE4
    "11100101",   -- 0x36D : 0xE5
    "11100101",   -- 0x36E : 0xE5
    "11100101",   -- 0x36F : 0xE5
    "11100101",   -- 0x370 : 0xE5
    "11100101",   -- 0x371 : 0xE5
    "11100110",   -- 0x372 : 0xE6
    "11100110",   -- 0x373 : 0xE6
    "11100110",   -- 0x374 : 0xE6
    "11100110",   -- 0x375 : 0xE6
    "11100110",   -- 0x376 : 0xE6
    "11100111",   -- 0x377 : 0xE7
    "11100111",   -- 0x378 : 0xE7
    "11100111",   -- 0x379 : 0xE7
    "11100111",   -- 0x37A : 0xE7
    "11100111",   -- 0x37B : 0xE7
    "11100111",   -- 0x37C : 0xE7
    "11101000",   -- 0x37D : 0xE8
    "11101000",   -- 0x37E : 0xE8
    "11101000",   -- 0x37F : 0xE8
    "11101000",   -- 0x380 : 0xE8
    "11101000",   -- 0x381 : 0xE8
    "11101001",   -- 0x382 : 0xE9
    "11101001",   -- 0x383 : 0xE9
    "11101001",   -- 0x384 : 0xE9
    "11101001",   -- 0x385 : 0xE9
    "11101001",   -- 0x386 : 0xE9
    "11101010",   -- 0x387 : 0xEA
    "11101010",   -- 0x388 : 0xEA
    "11101010",   -- 0x389 : 0xEA
    "11101010",   -- 0x38A : 0xEA
    "11101010",   -- 0x38B : 0xEA
    "11101011",   -- 0x38C : 0xEB
    "11101011",   -- 0x38D : 0xEB
    "11101011",   -- 0x38E : 0xEB
    "11101011",   -- 0x38F : 0xEB
    "11101011",   -- 0x390 : 0xEB
    "11101100",   -- 0x391 : 0xEC
    "11101100",   -- 0x392 : 0xEC
    "11101100",   -- 0x393 : 0xEC
    "11101100",   -- 0x394 : 0xEC
    "11101100",   -- 0x395 : 0xEC
    "11101100",   -- 0x396 : 0xEC
    "11101101",   -- 0x397 : 0xED
    "11101101",   -- 0x398 : 0xED
    "11101101",   -- 0x399 : 0xED
    "11101101",   -- 0x39A : 0xED
    "11101101",   -- 0x39B : 0xED
    "11101110",   -- 0x39C : 0xEE
    "11101110",   -- 0x39D : 0xEE
    "11101110",   -- 0x39E : 0xEE
    "11101110",   -- 0x39F : 0xEE
    "11101110",   -- 0x3A0 : 0xEE
    "11101111",   -- 0x3A1 : 0xEF
    "11101111",   -- 0x3A2 : 0xEF
    "11101111",   -- 0x3A3 : 0xEF
    "11101111",   -- 0x3A4 : 0xEF
    "11101111",   -- 0x3A5 : 0xEF
    "11101111",   -- 0x3A6 : 0xEF
    "11110000",   -- 0x3A7 : 0xF0
    "11110000",   -- 0x3A8 : 0xF0
    "11110000",   -- 0x3A9 : 0xF0
    "11110000",   -- 0x3AA : 0xF0
    "11110000",   -- 0x3AB : 0xF0
    "11110001",   -- 0x3AC : 0xF1
    "11110001",   -- 0x3AD : 0xF1
    "11110001",   -- 0x3AE : 0xF1
    "11110001",   -- 0x3AF : 0xF1
    "11110001",   -- 0x3B0 : 0xF1
    "11110010",   -- 0x3B1 : 0xF2
    "11110010",   -- 0x3B2 : 0xF2
    "11110010",   -- 0x3B3 : 0xF2
    "11110010",   -- 0x3B4 : 0xF2
    "11110010",   -- 0x3B5 : 0xF2
    "11110011",   -- 0x3B6 : 0xF3
    "11110011",   -- 0x3B7 : 0xF3
    "11110011",   -- 0x3B8 : 0xF3
    "11110011",   -- 0x3B9 : 0xF3
    "11110011",   -- 0x3BA : 0xF3
    "11110011",   -- 0x3BB : 0xF3
    "11110100",   -- 0x3BC : 0xF4
    "11110100",   -- 0x3BD : 0xF4
    "11110100",   -- 0x3BE : 0xF4
    "11110100",   -- 0x3BF : 0xF4
    "11110100",   -- 0x3C0 : 0xF4
    "11110101",   -- 0x3C1 : 0xF5
    "11110101",   -- 0x3C2 : 0xF5
    "11110101",   -- 0x3C3 : 0xF5
    "11110101",   -- 0x3C4 : 0xF5
    "11110101",   -- 0x3C5 : 0xF5
    "11110101",   -- 0x3C6 : 0xF5
    "11110110",   -- 0x3C7 : 0xF6
    "11110110",   -- 0x3C8 : 0xF6
    "11110110",   -- 0x3C9 : 0xF6
    "11110110",   -- 0x3CA : 0xF6
    "11110110",   -- 0x3CB : 0xF6
    "11110111",   -- 0x3CC : 0xF7
    "11110111",   -- 0x3CD : 0xF7
    "11110111",   -- 0x3CE : 0xF7
    "11110111",   -- 0x3CF : 0xF7
    "11110111",   -- 0x3D0 : 0xF7
    "11111000",   -- 0x3D1 : 0xF8
    "11111000",   -- 0x3D2 : 0xF8
    "11111000",   -- 0x3D3 : 0xF8
    "11111000",   -- 0x3D4 : 0xF8
    "11111000",   -- 0x3D5 : 0xF8
    "11111000",   -- 0x3D6 : 0xF8
    "11111001",   -- 0x3D7 : 0xF9
    "11111001",   -- 0x3D8 : 0xF9
    "11111001",   -- 0x3D9 : 0xF9
    "11111001",   -- 0x3DA : 0xF9
    "11111001",   -- 0x3DB : 0xF9
    "11111010",   -- 0x3DC : 0xFA
    "11111010",   -- 0x3DD : 0xFA
    "11111010",   -- 0x3DE : 0xFA
    "11111010",   -- 0x3DF : 0xFA
    "11111010",   -- 0x3E0 : 0xFA
    "11111010",   -- 0x3E1 : 0xFA
    "11111011",   -- 0x3E2 : 0xFB
    "11111011",   -- 0x3E3 : 0xFB
    "11111011",   -- 0x3E4 : 0xFB
    "11111011",   -- 0x3E5 : 0xFB
    "11111011",   -- 0x3E6 : 0xFB
    "11111100",   -- 0x3E7 : 0xFC
    "11111100",   -- 0x3E8 : 0xFC
    "11111100",   -- 0x3E9 : 0xFC
    "11111100",   -- 0x3EA : 0xFC
    "11111100",   -- 0x3EB : 0xFC
    "11111100",   -- 0x3EC : 0xFC
    "11111101",   -- 0x3ED : 0xFD
    "11111101",   -- 0x3EE : 0xFD
    "11111101",   -- 0x3EF : 0xFD
    "11111101",   -- 0x3F0 : 0xFD
    "11111101",   -- 0x3F1 : 0xFD
    "11111110",   -- 0x3F2 : 0xFE
    "11111110",   -- 0x3F3 : 0xFE
    "11111110",   -- 0x3F4 : 0xFE
    "11111110",   -- 0x3F5 : 0xFE
    "11111110",   -- 0x3F6 : 0xFE
    "11111110",   -- 0x3F7 : 0xFE
    "11111111",   -- 0x3F8 : 0xFF
    "11111111",   -- 0x3F9 : 0xFF
    "11111111",   -- 0x3FA : 0xFF
    "11111111",   -- 0x3FB : 0xFF
    "11111111",   -- 0x3FC : 0xFF
    "00000000",   -- 0x3FD : 0x0
    "00000000",   -- 0x3FE : 0x0
    "00000000");  -- 0x3FF : 0x0

begin
  process(clk) begin
    if(clk'event and clk='1') then
      outdata <= brom(CONV_INTEGER(indata));
    end if;
  end process;
enc rtl

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

