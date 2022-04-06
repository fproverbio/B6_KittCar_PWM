---------- DEFAULT LIBRARY ---------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity KittCarPWM is
  Generic (

    CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100     := 10;
    -- clk period in nanoseconds
    MIN_KITT_CAR_STEP_MS	        :	POSITIVE	RANGE	1	TO	2000    := 1;
    -- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

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
      
      BIT_LENGTH	:	INTEGER	RANGE	1 TO 16 := TAIL_LENGTH;	-- Bit used  inside PWM
      
      T_ON_INIT	:	POSITIVE	:= 64;				-- Init of Ton
      PERIOD_INIT	:	POSITIVE	:= 128;				-- Init of Period
      
      PWM_INIT	:	STD_LOGIC:= '1'					-- Init of PWM
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
  
  

  signal STEP 		: UNSIGNED (63 DOWNTO 0):= to_unsigned(MIN_KITT_CAR_STEP_MS, 32)*to_unsigned(1000000, 32);
  signal counter_ns  	: unsigned (63 downto 0) := (Others => '0');
  
  signal Period		: std_logic_vector(TAIL_LENGTH-1 DOWNTO 0):= std_logic_vector(to_unsigned(TAIL_LENGTH, TAIL_LENGTH));

  
  type Ton_mat is array(NUM_OF_LEDS-1 DOWNTO 0) of unsigned(TAIL_LENGTH-1 DOWNTO 0);
  signal Ton : Ton_mat:= (Others =>(Others => '0'));
  
  signal KITT_REG	:   std_logic_vector(NUM_OF_LEDS-1 DOWNTO 0):=(OTHERS =>'0');
  signal zeros : unsigned(TAIL_LENGTH-1 DOWNTO 0) := (OTHERS => '0');
  signal LEDS_REG : std_logic_vector(NUM_OF_LEDS-1 DOWNTO 0) := KITT_REG;

begin

  --create pwm--
  PWM_loop: for I in 0 to NUM_OF_LEDS-1 generate
    
    PWM_inst: PulseWidthModulator
      Port Map ( 
        
        ------- Reset/Clock --------
        reset	=> reset,
        clk		=> clk,
        ----------------------------		

        -------- Duty Cycle ----------
        Ton		=> std_logic_vector(Ton(I)),			
        Period	=> Period,	
        
        PWM		=> KITT_REG(I)		
        ----------------------------		
        
        );
    
  end generate;

  LEDS <= KITT_REG;
  
  
  STEP <= UNSIGNED(SW)*to_unsigned(MIN_KITT_CAR_STEP_MS, 24)*to_unsigned(1000000, 24);
  

  
  ---- Combination logic to switch the LED  ----
  process(clk)
    
    variable direction : std_logic_vector(NUM_OF_LEDS-1 DOWNTO 0) := (Others => '0'); ---- IF '0' => MOVE LEFT || IF '1' => MOVE RIGHT ----
    
  begin
    if rising_edge(clk) then
      
      counter_ns <= counter_ns+CLK_PERIOD_NS;
      
      
      if reset = '1' then
        
        direction := (Others => '0');
        counter_ns <= (Others => '0');
        
        for I in 0 to NUM_OF_LEDS-1 loop
          if (I<TAIL_LENGTH) then
            Ton(I) <= to_unsigned(I+1, TAIL_LENGTH);
          else
            Ton(I)<= (Others => '0');
          end if;
          
        end loop;
        
        ---- Logic that decide what direction has to be taken ----
        
      else
        
        if counter_ns >= STEP then
          
          counter_ns <= (Others => '0');
          
          for j in 0 to NUM_OF_LEDS-2 loop
            
            if direction(j) = '0' then
              
              Ton(j+1)<=Ton(j);

              Ton(0)<= (Others => '0');
              
              if Ton(NUM_OF_LEDS-1)=TAIL_LENGTH then
              --direction(j):= not direction(j);
              --logic that changes directions of ton on the left
              end if;
              
              
            elsif direction(j) = '1' then
              
              Ton(j)<= Ton(j+1);

              Ton(NUM_OF_LEDS-1) <= (Others =>'0');
              
              if Ton(0)=TAIL_LENGTH then
                                        --direction(j):= not direction(j); 	--logic that changes directions of ton on the right
              end if;
              
            end if;
            
          end loop;
          
        end if;	

      end if;

    end if;

  end process;

end Behavioral;
