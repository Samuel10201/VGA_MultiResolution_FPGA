--------------------------------------------------------------------------------
-- FileName:        system_control.vhd
-- Description:     Master state machine to control system mode based on PS/2.
--                  Direct detection logic for 'P' and 'B' keys.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY system_control IS
    PORT(
        clk          : IN  STD_LOGIC;                      -- 50 MHz system clock (PIN_Y2)
        reset_n      : IN  STD_LOGIC;                      -- Active low reset (KEY[0])
        ps2_code     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);   -- Connect to scan_code_out
        ps2_new_data : IN  STD_LOGIC;                      -- Connect to scan_ready pulse
        show_picture : OUT STD_LOGIC;                      -- '1' = Picture, '0' = Black
        lcd_mode     : OUT STD_LOGIC                       -- '1' = Picture, '0' = Black
    );
END system_control;

ARCHITECTURE behavior OF system_control IS

    -- mode_reg: '1' starts in Picture Mode
    SIGNAL mode_reg   : STD_LOGIC := '1'; 

    -- Synchronizer registers for Clock Domain Crossing (CDC) and Edge Detection
    SIGNAL sync_1     : STD_LOGIC := '0';
    SIGNAL sync_2     : STD_LOGIC := '0';
    SIGNAL prev_ready : STD_LOGIC := '0';

BEGIN

    show_picture <= mode_reg;
    lcd_mode     <= mode_reg;

    PROCESS(clk, reset_n)
    BEGIN
        IF (reset_n = '0') THEN
            mode_reg      <= '1'; 
            sync_1        <= '0';
            sync_2        <= '0';
            prev_ready    <= '0';
            
        ELSIF rising_edge(clk) THEN
            
            -- 1. Double-flop synchronizer to avoid metastability issues
            -- between the PS/2 clock domain and the 50MHz domain.
            sync_1     <= ps2_new_data;
            sync_2     <= sync_1;
            prev_ready <= sync_2;

            -- 2. Edge Detection: We trigger ONLY when ps2_new_data goes from 0 to 1
            IF (sync_2 = '1' AND prev_ready = '0') THEN
                
                -- We check the Scan Code directly when the pulse arrives
                CASE ps2_code IS
                    
                    WHEN x"4D" =>       -- 'P' Key (Picture Mode)
                        mode_reg <= '1';
                        
                    WHEN x"32" =>       -- 'B' Key (Black Screen)
                        mode_reg <= '0';
                        
                    WHEN OTHERS =>      -- Ignore any other key
                        mode_reg <= mode_reg;
                        
                END CASE;
                
            END IF;
        END IF;
    END PROCESS;

END behavior;