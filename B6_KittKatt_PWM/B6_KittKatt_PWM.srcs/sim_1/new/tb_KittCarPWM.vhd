---------- DEFAULT LIBRARY ---------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
------------------------------------


entity tb_KittCarPWM is
end tb_KittCarPWM;

architecture Behavioral of tb_KittCarPWM is

  constant CLK_PERIOD                   :	TIME	                                := 10 ns;
  constant RESET_WND	                :	TIME	                                := 10*CLK_PERIOD;
  constant CLK_PERIOD_NS                :       POSITIVE RANGE	1 to 100                := 10;	-- clk period in nanoseconds
  
  constant TB_CLK_INIT		        :	STD_LOGIC	                        := '0';
  constant TB_RESET_INIT                :	STD_LOGIC	                        := '1';
  
  constant DUT_T_ON_INIT	        :	POSITIVE	                        := 8;	-- Init of Ton
  constant DUT_BIT_LENGTH		:	INTEGER         RANGE	1 TO 16         := 2;	-- Leds used  over the 16 in Basys3
  constant DUT_MIN_KITT_CAR_STEP_MS     :	POSITIVE	RANGE	1 to 2000       := 1;
  
  constant DUT_NUM_OF_SWS		:	INTEGER	        RANGE	1 TO 16         := 16;	-- Number of input switches
  constant DUT_NUM_OF_LEDS		:	INTEGER	        RANGE	1 TO 16         := 16;	-- Number of output LEDs
  constant DUT_TAIL_LENGTH		:	INTEGER	        RANGE	1 TO 16	        := 4;	-- Tail length
  
  component KittCarPWM

    Generic (

      CLK_PERIOD_NS	                :	POSITIVE	RANGE	1 to 100        := 10;	-- clk period in nanoseconds
      MIN_KITT_CAR_STEP_MS	        :	POSITIVE	RANGE	1 to 2000       := 1;
      -- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

      NUM_OF_SWS	        	:	INTEGER	        RANGE	1 TO 16         := 16;	-- Number of input switches
      NUM_OF_LEDS		        :	INTEGER	        RANGE	1 TO 16         := 16;	-- Number of output LEDs

      TAIL_LENGTH	        	:	INTEGER	        RANGE	1 TO 16	        := 4	-- Tail length

      );

    Port (

      reset	:	IN	STD_LOGIC;
      clk	:	IN	STD_LOGIC;
            
      sw	:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
      leds	:	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Basys3
      
      );
    
  end component;

  signal reset	        :	STD_LOGIC	:= TB_RESET_INIT;
  signal clk		:	STD_LOGIC	:= TB_CLK_INIT;
  signal dut_sw	        :	STD_LOGIC_VECTOR(DUT_NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
  signal dut_leds	:	STD_LOGIC_VECTOR(DUT_NUM_OF_LEDS-1 downto 0);	-- LEDs avaiable on Basys3

begin

  dut_KittCarPWM	:	KittCarPWM

    Generic Map(

      CLK_PERIOD_NS			=> CLK_PERIOD_NS,
      MIN_KITT_CAR_STEP_MS	        => DUT_MIN_KITT_CAR_STEP_MS,

      NUM_OF_SWS			=> DUT_NUM_OF_SWS,
      NUM_OF_LEDS			=> DUT_NUM_OF_LEDS,

      TAIL_LENGTH			=> DUT_TAIL_LENGTH
      
      )

    Port Map(

      reset	=> reset,
      clk	=> clk,
      
      sw	=> dut_sw,      -- Switches avaiable on Basys3
      leds	=> dut_leds	-- LEDs avaiable on Basys3
      
      );
  
  reset_wave :process

  begin

    reset <= TB_RESET_INIT;
    wait for RESET_WND;

    reset <= not reset;
    wait;

  end process;
  
  stim_proc: process
    
  begin
    
    dut_sw <= (others => '0');
    wait for RESET_WND;

    --		for I in 0 to 2**DUT_NUM_OF_SWS-1 loop
    --			dut_sw <= std_logic_vector(to_unsigned(I,DUT_NUM_OF_SWS));
    --			wait for 500 ms;
    --		end loop;
    wait;
    wait;
    
  end process;

end;
