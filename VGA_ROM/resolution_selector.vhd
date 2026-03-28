-- Concept: Priority Resolution Selector for Multi-mode VGA Controller
-- This module defines the timing parameters based on switch priority.

library ieee;
use ieee.std_logic_1164.all;

entity resolution_selector is
    port(
        sw0: in  std_logic;
		  sw1 : in  std_logic;
		  sw2 : in  std_logic;
        clk_select    : out std_logic_vector(1 downto 0);
		  
        h_pixels      : out integer;
        h_pulse       : out integer;
        h_bp          : out integer;
        h_fp          : out integer;
		  
        v_pixels      : out integer;
        v_pulse       : out integer;
        v_bp          : out integer;
        v_fp          : out integer;

        h_pol, v_pol  : out std_logic
    );
end entity;

architecture behavior of resolution_selector is
begin
    process(sw0, sw1, sw2)
    begin
        -- Priority 1: 640x480 (Highest Priority per SW2)
        if (sw2 = '1') then
            clk_select <= "00";   -- Selects the 25.175 MHz clock
            h_pixels   <= 640; h_pulse <= 96;  h_bp <= 48;  h_fp <= 16;
            v_pixels   <= 480; v_pulse <= 2;   v_bp <= 33;  v_fp <= 10;
            h_pol      <= '0'; v_pol   <= '0'; -- Negative Polarity

        -- Priority 2: 800x600 (Middle Priority per SW1)
        elsif (sw1 = '1') then
            clk_select <= "01";   -- Selects the 40.0 MHz clock
            h_pixels   <= 800; h_pulse <= 128; h_bp <= 88;  h_fp <= 40;
            v_pixels   <= 600; v_pulse <= 4;   v_bp <= 23;  v_fp <= 1;
            h_pol      <= '1'; v_pol   <= '1'; -- Positive Polarity

        -- Priority 3: 1024x768 (Lower Priority per SW0)
        elsif (sw0 = '1') then
            clk_select <= "10";   -- Selects the 65.0 MHz clock
            h_pixels   <= 1024; h_pulse <= 136; h_bp <= 160; h_fp <= 24;
            v_pixels   <= 768;  v_pulse <= 6;   v_bp <= 29;  v_fp <= 3;
            h_pol      <= '0';  v_pol   <= '0'; -- Negative Polarity

        -- Default State: Safe Resolution (640x480)
        else
            clk_select <= "00";
            h_pixels   <= 640; h_pulse <= 96;  h_bp <= 48;  h_fp <= 16;
            v_pixels   <= 480; v_pulse <= 2;   v_bp <= 33;  v_fp <= 10;
            h_pol      <= '0'; v_pol   <= '0';
        end if;
    end process;
end architecture;