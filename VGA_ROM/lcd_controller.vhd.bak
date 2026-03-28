--------------------------------------------------------------------------------
-- FileName:        lcd_controller.vhd
-- Description:     Driver for the 16x2 LCD on the DE2-115 board.
--                  Updates display in real-time between two English messages.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY lcd_controller IS
    PORT(
        clk          : IN  STD_LOGIC;  -- 50 MHz clock
        reset_n      : IN  STD_LOGIC;  -- Active low reset
        lcd_mode     : IN  STD_LOGIC;  -- '1' = Picture Mode, '0' = Black Screen
        lcd_data     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- LCD Data bus
        lcd_rs       : OUT STD_LOGIC;  -- Register Select: 0=Command, 1=Data
        lcd_rw       : OUT STD_LOGIC;  -- Read/Write: 0=Write
        lcd_en       : OUT STD_LOGIC;  -- Enable pulse
        lcd_on       : OUT STD_LOGIC;  -- Power ON
        lcd_blon     : OUT STD_LOGIC   -- Backlight ON
    );
END lcd_controller;

ARCHITECTURE behavior OF lcd_controller IS

    -- LCD Hardware requirements
    CONSTANT CLK_FREQ : INTEGER := 50_000_000; -- 50 MHz
    
    -- State machine for LCD initialization and writing
    TYPE state_type IS (POWER_UP, INIT_DISPLAY, CLEAR_DISPLAY, WRITE_CHAR, IDLE);
    SIGNAL state : state_type := POWER_UP;
    
    -- Timers and counters
    SIGNAL delay_cnt  : INTEGER RANGE 0 TO CLK_FREQ := 0; 
    SIGNAL char_index : INTEGER RANGE 0 TO 15 := 0;
    
    -- Track previous mode to detect changes in real-time
    SIGNAL prev_mode  : STD_LOGIC := '1';

    -- Data arrays for the two 16-character English messages
    TYPE char_array IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Message 1: "PICTURE MODE    "
    CONSTANT msg_picture : char_array := (
        x"50", x"49", x"43", x"54", x"55", x"52", x"45", x"20", 
        x"4D", x"4F", x"44", x"45", x"20", x"20", x"20", x"20"
    );
    
    -- Message 2: "BLACK SCREEN    "
    CONSTANT msg_black : char_array := (
        x"42", x"4C", x"41", x"43", x"4B", x"20", x"53", x"43", 
        x"52", x"45", x"45", x"4E", x"20", x"20", x"20", x"20"
    );

BEGIN

    -- Hardwired control pins for DE2-115 LCD
    lcd_on   <= '1'; -- Force power on
    lcd_blon <= '1'; -- Force backlight on
    lcd_rw   <= '0'; -- We only write to the LCD

    PROCESS(clk, reset_n)
    BEGIN
        IF (reset_n = '0') THEN
            state      <= POWER_UP;
            delay_cnt  <= 0;
            char_index <= 0;
            lcd_en     <= '0';
            lcd_rs     <= '0';
            lcd_data   <= (OTHERS => '0');
            prev_mode  <= lcd_mode;
            
        ELSIF rising_edge(clk) THEN
            
            CASE state IS
                
                -- Wait 20ms for LCD to power up stably
                WHEN POWER_UP =>
                    IF (delay_cnt < 1_000_000) THEN
                        delay_cnt <= delay_cnt + 1;
                    ELSE
                        delay_cnt <= 0;
                        state     <= INIT_DISPLAY;
                    END IF;
                
                -- Send Function Set command (8-bit interface, 2 lines)
                WHEN INIT_DISPLAY =>
                    lcd_rs   <= '0'; -- Command mode
                    lcd_data <= x"38";
                    
                    -- Generate Enable pulse manually
                    IF (delay_cnt = 10) THEN
                        lcd_en <= '1';
                    ELSIF (delay_cnt = 20) THEN
                        lcd_en <= '0';
                    ELSIF (delay_cnt = 100_000) THEN -- Wait 2ms
                        delay_cnt <= 0;
                        state     <= CLEAR_DISPLAY;
                    END IF;
                    delay_cnt <= delay_cnt + 1;

                -- Send Clear Display command (0x01)
                WHEN CLEAR_DISPLAY =>
                    lcd_rs   <= '0';
                    lcd_data <= x"01";
                    
                    IF (delay_cnt = 10) THEN
                        lcd_en <= '1';
                    ELSIF (delay_cnt = 20) THEN
                        lcd_en <= '0';
                    ELSIF (delay_cnt = 100_000) THEN -- Clear takes 2ms
                        delay_cnt  <= 0;
                        char_index <= 0;
                        state      <= WRITE_CHAR;
                    END IF;
                    delay_cnt <= delay_cnt + 1;

                -- Write the 16 characters one by one
                WHEN WRITE_CHAR =>
                    lcd_rs <= '1'; -- Data mode
                    
                    -- Select message based on current mode
                    IF (lcd_mode = '1') THEN
                        lcd_data <= msg_picture(char_index);
                    ELSE
                        lcd_data <= msg_black(char_index);
                    END IF;
                    
                    -- Enable pulse for each character
                    IF (delay_cnt = 10) THEN
                        lcd_en <= '1';
                    ELSIF (delay_cnt = 20) THEN
                        lcd_en <= '0';
                    ELSIF (delay_cnt = 5_000) THEN -- Wait 100us between chars
                        delay_cnt <= 0;
                        IF (char_index < 15) THEN
                            char_index <= char_index + 1;
                        ELSE
                            state <= IDLE;
                            prev_mode <= lcd_mode; -- Update tracker
                        END IF;
                    END IF;
                    delay_cnt <= delay_cnt + 1;

                -- Wait for a change in the mode from the keyboard
                WHEN IDLE =>
                    -- Check if system_control changed the mode
                    IF (lcd_mode /= prev_mode) THEN
                        state <= CLEAR_DISPLAY; -- Restart write sequence
                    END IF;
                    
            END CASE;
        END IF;
    END PROCESS;

END behavior;