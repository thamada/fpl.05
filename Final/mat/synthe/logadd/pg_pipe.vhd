--
-- pgpg2.0 by Hamada Tsuyoshi
-- Generated from 'list.pgpp'
-- NPIPE : 1
-- NVMP  : 1
-- for Bioler3 64/66 PCI DMA version
library ieee;
use ieee.std_logic_1164.all;

entity pg_pipe is
  generic(JDATA_WIDTH : integer := 0;
          IDATA_WIDTH : integer := 64);
  port(
    p_jdata : in std_logic_vector(JDATA_WIDTH-1 downto 0);
    p_run : in std_logic;
    p_we :  in std_logic;
    p_adri : in std_logic_vector(11 downto 0);
    p_datai : in std_logic_vector(IDATA_WIDTH-1 downto 0);
    p_adro : in std_logic_vector(11 downto 0);
    p_datao : out std_logic_vector(IDATA_WIDTH-1 downto 0);
    p_runret : out std_logic;
    rst,clk : in std_logic
  );
end pg_pipe;

architecture std of pg_pipe is

  component pipe
    generic(JDATA_WIDTH : integer;
            IDATA_WIDTH : integer);
    port(
      p_jdata: in std_logic_vector(JDATA_WIDTH-1 downto 0);
      p_run : in std_logic;
      p_we : in std_logic;
      p_adri : in std_logic_vector(3 downto 0);
      p_adrivp : in std_logic_vector(3 downto 0);
      p_datai : in std_logic_vector(IDATA_WIDTH-1 downto 0);
      p_adro : in std_logic_vector(3 downto 0);
      p_adrovp : in std_logic_vector(3 downto 0);
      p_datao : out std_logic_vector(IDATA_WIDTH-1 downto 0);
      p_runret : out std_logic;
      rst,pclk : in std_logic );
  end component;

  signal u_adri,u_adro: std_logic_vector(7 downto 0);
  signal adrivp,adrovp: std_logic_vector(3 downto 0);
  signal we,runret: std_logic_vector(1 downto 0);
  signal datao: std_logic_vector(63 downto 0);
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
    upipe: pipe GENERIC MAP(JDATA_WIDTH=>JDATA_WIDTH,
                            IDATA_WIDTH=>IDATA_WIDTH)
	      PORT MAP(p_jdata=>p_jdata, p_run=>p_run,
                 p_we=>we(i),p_adri=>p_adri(3 downto 0),p_adrivp=>adrivp,
	               p_datai=>p_datai,p_adro=>l_adro,p_adrovp=>adrovp, 
	               p_datao=>datao(IDATA_WIDTH*(i+1)-1 downto IDATA_WIDTH*i), p_runret=>runret(i), 
		       rst=>rst,pclk=>clk);
  end generate forgen1;

  p_runret <= runret(0);

  with u_adro select
    p_datao <= datao(IDATA_WIDTH-1 downto 0) when "00000000", 
               datao(IDATA_WIDTH-1 downto 0) when others;

end std;

library ieee;
use ieee.std_logic_1164.all;

entity pipe is
  generic(JDATA_WIDTH : integer := 312;
          IDATA_WIDTH : integer := 64);
port(p_jdata : in std_logic_vector(JDATA_WIDTH-1 downto 0);
     p_run : in std_logic;
     p_we :  in std_logic;
     p_adri : in std_logic_vector(3 downto 0);
     p_adrivp : in std_logic_vector(3 downto 0);
     p_datai : in std_logic_vector(IDATA_WIDTH-1 downto 0);
     p_adro : in std_logic_vector(3 downto 0);
     p_adrovp : in std_logic_vector(3 downto 0);
     p_datao : out std_logic_vector(IDATA_WIDTH-1 downto 0);
     p_runret : out std_logic;
     rst,pclk : in std_logic);
end pipe;

architecture std of pipe is

  component pg_log_unsigned_add_itp_18_9_7_4
    port( x,y : in std_logic_vector(17 downto 0);
          z : out std_logic_vector(17 downto 0);
          clock : in std_logic);
  end component;

  signal x: std_logic_vector(17 downto 0);
  signal y: std_logic_vector(17 downto 0);
-- pg_rundelay(4)
  signal run: std_logic_vector(5 downto 0);

begin

  process(pclk) begin
    if(pclk'event and pclk='1') then
      if(p_we ='1') then
        end if;
      end if;
    end if;
  end process;

  u0: pg_log_unsigned_add_itp_18_9_7_4
            port map(x=>x,y=>y,z=>z,clock=>pclk);

  process(pclk) begin
    if(pclk'event and pclk='1') then
      run(0) <= p_run;
      for i in 0 to 4 loop
        run(i+1) <= run(i);
      end loop;
      p_runret <= run(5);
    end if;
  end process;

  process(pclk) begin
    if(pclk'event and pclk='1') then
      else
        p_datao <= (others=>'0');
      end if;
    end if;
  end process;

end std;

