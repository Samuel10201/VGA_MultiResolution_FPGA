--------------------------------------------------------------------------------
-- FileName:        lcd_controller.vhd
-- Description:     Driver for the 16x2 LCD on the DE2-115 board.
--                  Updates display in real-time with protected counters.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY lcd_controller IS
    PORT(
        clk          : IN  STD_LOGIC;  -- 50 MHz clock
        reset_n      : IN  STD_LOGIC;  -- Active low reset
        lcd_mode     : IN  STD_LOGIC;  -- '1' = Picture Mode, '0' = Black Screen
        lcd_data     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        lcd_rs       : OUT STD_LOGIC;  
        lcd_rw       : OUT STD_LOGIC;  
        lcd_en       : OUT STD_LOGIC;  
        lcd_on       : OUT STD_LOGIC;  
        lcd_blon     : OUT STD_LOGIC   
    );
END lcd_controller;

ARCHITECTURE behavior OF lcd_controller IS

    CONSTANT CLK_FREQ : INTEGER := 50_000_000; 
    
    TYPE state_type IS (POWER_UP, INIT_DISPLAY, CLEAR_DISPLAY, WRITE_CHAR, IDLE);
    SIGNAL state : state_type := POWER_UP;
    
    SIGNAL delay_cnt  : INTEGER RANGE 0 TO CLK_FREQ := 0; 
    SIGNAL char_index : INTEGER RANGE 0 TO 15 := 0;
    SIGNAL prev_mode  : STD_LOGIC := '1';

    TYPE char_array IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    CONSTANT msg_picture : char_array := (
        x"50", x"49", x"43", x"54", x"55", x"52", x"45", x"20", 
        x"4D", x"4F", x"44", x"45", x"20", x"20", x"20", x"20"
    );
    
    CONSTANT msg_black : char_array := (
        x"42", x"4C", x"41", x"43", x"4B", x"20", x"53", x"43", 
        x"52", x"45", x"45", x"4E", x"20", x"20", x"20", x"20"
    );

BEGIN

    lcd_on   <= '1'; 
    lcd_blon <= '1'; 
    lcd_rw   <= '0'; 

    PROCESS(clk, reset_n)
    BEGIN
        IF (reset_n = '0') THEN
            state      <= POWER_UP;
            delay_cnt  <= 0;
            char_index <= 0;
            lcd_en     <= '0';
            lcd_rs     <= '0';
            lcd_data   <= (OTHERS => '0');
            prev_mode  <= '1';
            
        ELSIF rising_edge(clk) THEN
            
            CASE state IS
                
                WHEN POWER_UP =>
                    IF (delay_cnt < 1_000_000) THEN
                        delay_cnt <= delay_cnt + 1;
                    ELSE
                        delay_cnt <= 0;
                        state     <= INIT_DISPLAY;
                    END IF;
                
                WHEN INIT_DISPLAY =>
                    lcd_rs   <= '0'; 
                    lcd_data <= x"38";
                    
                    IF (delay_cnt = 10) THEN
                        lcd_en <= '1';
                    ELSIF (delay_cnt = 20) THEN
                        lcd_en <= '0';
                    END IF;
                    
     
                    IF (delay_cnt = 100_000) THEN 
                        delay_cnt <= 0;
                        state     <= CLEAR_DISPLAY;
                    ELSE
                        delay_cnt <= delay_cnt + 1;
                    END IF;

                WHEN CLEAR_DISPLAY =>
                    lcd_rs   <= '0';
                    lcd_data <= x"01";
                    
                    IF (delay_cnt = 10) THEN
                        lcd_en <= '1';
                    ELSIF (delay_cnt = 20) THEN
                        lcd_en <= '0';
                    END IF;
                    
                    IF (delay_cnt = 100_000) THEN 
                        delay_cnt  <= 0;
                        char_index <= 0;
                        state      <= WRITE_CHAR;
                    ELSE
                        delay_cnt <= delay_cnt + 1;
                    END IF;

                WHEN WRITE_CHAR =>
                    lcd_rs <= '1'; 
                    
                    IF (lcd_mode = '1') THEN
                        lcd_data <= msg_picture(char_index);
                    ELSE
                        lcd_data <= msg_black(char_index);
                    END IF;
                    
                    IF (delay_cnt = 10) THEN
                        lcd_en <= '1';
                    ELSIF (delay_cnt = 20) THEN
                        lcd_en <= '0';
                    END IF;
                    
                    IF (delay_cnt = 5_000) THEN 
                        delay_cnt <= 0;
                        IF (char_index < 15) THEN
                            char_index <= char_index + 1;
                        ELSE
                            state     <= IDLE;
                            prev_mode <= lcd_mode; 
                        END IF;
                    ELSE
                        delay_cnt <= delay_cnt + 1;
                    END IF;

                WHEN IDLE =>
                    delay_cnt <= 0; 
                    
                    IF (lcd_mode /= prev_mode) THEN
                        state <= CLEAR_DISPLAY; 
                    END IF;
                    
            END CASE;
        END IF;
    END PROCESS;

END behavior;