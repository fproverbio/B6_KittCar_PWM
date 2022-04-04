---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity KittCarPWM is
	Generic (

		CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100     := 10;	-- clk period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1	TO	2000    := 1;	-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

		NUM_OF_SWS				:	INTEGER	RANGE	1 TO 16 := 16;	-- Number of input switches
		NUM_OF_LEDS				:	INTEGER	RANGE	1 TO 16 := 16;	-- Number of output LEDs

		TAIL_LENGTH				:	INTEGER	RANGE	1 TO 16	:= 4	-- Tail length
	);
	Port (

		------- Reset/Clock --------
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		----------------------------

		-------- LEDs/SWs ----------
		sw		:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
		leds	:	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Basys3
		----------------------------

	);
end KittCarPWM;

architecture Behavioral of KittCarPWM is

	component PulseWidthModulator is
	Generic(
						
		BIT_LENGTH	:	INTEGER	RANGE	1 TO 16 := 8;	-- Bit used  inside PWM
		
		T_ON_INIT	:	POSITIVE	:= 64;				-- Init of Ton
		PERIOD_INIT	:	POSITIVE	:= 128;				-- Init of Period
		
		PWM_INIT	:	STD_LOGIC:= '0'					-- Init of PWM
	);
	Port ( 
	
		------- Reset/Clock --------
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		----------------------------		

		-------- Duty Cycle ----------
		Ton		:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	-- clk at PWM = '1'
		Period	:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	-- clk per period of PWM
		
		PWM		:	OUT	STD_LOGIC		-- PWM signal
		----------------------------		
		
	);
    end component;
	
	signal LEDS_REG : std_logic_vector(NUM_OF_LEDS-1 DOWNTO 0) := (0 => '1', Others => '0');
	signal STEP 	: UNSIGNED (63 DOWNTO 0):= to_unsigned(MIN_KITT_CAR_STEP_MS, 32)*to_unsigned(1000000, 32);
	
	signal counter_ns  : unsigned (63 downto 0) := (Others => '0');
	--signal counter_us  : NATURAL RANGE 0 TO 1000 := 0;
	--signal counter_ms  : NATURAL RANGE 0 TO 32000 := 0;

begin
	
	LEDS <= LEDS_REG;
	
	STEP <= UNSIGNED(SW)*to_unsigned(MIN_KITT_CAR_STEP_MS, 24)*to_unsigned(1000000, 24);
	
	
	---- Combination logic to switch the LED  ----
	process(clk)
	
		variable direction : std_logic := '0'; ---- IF '0' => MOVE LEFT || IF '1' => MOVE RIGHT ----
	
	begin
		if rising_edge(clk) then
		
			counter_ns <= counter_ns+CLK_PERIOD_NS;
		
		
			if reset = '1' then
			
				LEDS_REG <= (0 => '1', Others => '0');
				direction := '0';
			
			---- Logic that decide what direction has to be taken ----
			
			else
			
				if counter_ns >= STEP then
					
					counter_ns <= (Others => '0');
				
					if LEDS_REG(NUM_OF_LEDS-1)='1' AND direction='0' then
				
						direction := '1';
					
					elsif LEDS_REG(0)='1' AND direction='1' then
				
						direction := '0';
					
					end if;
				
				-----------------------------------------------------------
				
				---- Moving the LED ----
				
					if direction='1' then
				
						LEDS_REG <= '0'&LEDS_REG(NUM_OF_LEDS-1 DOWNTO 1);
					
					elsif direction='0' then
				
						LEDS_REG <= LEDS_REG(NUM_OF_LEDS-2 DOWNTO 0)&'0';
					
					end if;
					
				end if;
			end if;
			------------------------
			
		end if;
	end process;
	-----------------------------------------------------

end Behavioral;
