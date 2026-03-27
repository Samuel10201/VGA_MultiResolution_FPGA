-- Concept: Simple Logic-Based Clock Multiplexer
-- This bypasses physical ALTCLKCTRL constraints by using FPGA logic.

library ieee;
use ieee.std_logic_1164.all;

entity clock_mux is
    port (
        clk0    : in  std_logic; -- Connect to PLL c0 (25 MHz)
        clk1    : in  std_logic; -- Connect to PLL c1 (40 MHz)
        clk2    : in  std_logic; -- Connect to PLL c2 (65 MHz)
        sel     : in  std_logic_vector(1 downto 0);
        clk_out : out std_logic
    );
end entity;

architecture behavior of clock_mux is
begin
    -- The concept is applied here: A simple case statement for selection
    process(sel, clk0, clk1, clk2)
    begin
        case sel is
            when "00"   => clk_out <= clk0;
            when "01"   => clk_out <= clk1;
            when "10"   => clk_out <= clk2;
            when others => clk_out <= clk0;
        end case;
    end process;
end architecture;