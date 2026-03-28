--------------------------------------------------------------------------------
-- FileName:        system_control.vhd
-- Description:     Master state machine to control system mode based on PS/2.
--                  Includes Clock Domain Crossing (CDC) for the PS/2 pulse.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY system_control IS
    PORT(
        clk          : IN  STD_LOGIC;                      -- 50 MHz system clock
        reset_n      : IN  STD_LOGIC;                      -- Active low reset
        ps2_code     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);   -- Connect to scan_code_out
        ps2_new_data : IN  STD_LOGIC;                      -- Connect to scan_ready
        show_picture : OUT STD_LOGIC;                      -- '1' = Picture, '0' = Black
        lcd_mode     : OUT STD_LOGIC                       -- '1' = Picture, '0' = Black
    );
END system_control;

ARCHITECTURE behavior OF system_control IS

    TYPE state_type IS (WAIT_FOR_BREAK, WAIT_FOR_KEY);
    SIGNAL current_state : state_type := WAIT_FOR_BREAK;
    
    SIGNAL mode_reg : STD_LOGIC := '1'; 

    -- Synchronizer registers for Clock Domain Crossing (CDC)
    SIGNAL sync_1     : STD_LOGIC := '0';
    SIGNAL sync_2     : STD_LOGIC := '0';
    SIGNAL prev_ready : STD_LOGIC := '0';

BEGIN

    show_picture <= mode_reg;
    lcd_mode     <= mode_reg;

    PROCESS(clk, reset_n)
    BEGIN
        IF (reset_n = '0') THEN
            current_state <= WAIT_FOR_BREAK;
            mode_reg      <= '1'; 
            sync_1        <= '0';
            sync_2        <= '0';
            prev_ready    <= '0';
            
        ELSIF rising_edge(clk) THEN
            
            -- 1. Double-flop synchronizer to avoid metastability
            sync_1     <= ps2_new_data;
            sync_2     <= sync_1;
            prev_ready <= sync_2;

            -- 2. Edge Detection: Only execute exactly ONCE when the signal goes from 0 to 1
            IF (sync_2 = '1' AND prev_ready = '0') THEN
                
                CASE current_state IS
                
                    WHEN WAIT_FOR_BREAK =>
                        -- F0 is the Break Code (Key Released)
                        IF (ps2_code = x"F0") THEN
                            current_state <= WAIT_FOR_KEY;
                        END IF;
                        
                    WHEN WAIT_FOR_KEY =>
                        -- Check which key was released
                        IF (ps2_code = x"4D") THEN
                            mode_reg <= '1'; -- 'P' key
                        ELSIF (ps2_code = x"32") THEN
                            mode_reg <= '0'; -- 'B' key
                        END IF;
                        
                        current_state <= WAIT_FOR_BREAK;
                        
                    WHEN OTHERS =>
                        current_state <= WAIT_FOR_BREAK;
                END CASE;
                
            END IF;
        END IF;
    END PROCESS;

END behavior;