--------------------------------------------------------------------------------
--
--   FileName:         hw_image_generator.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 12.1 Build 177 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 05/10/2013 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY hw_image_generator IS
	GENERIC(
		pixels_y :	INTEGER := 478;    --row that first color will persist until
		pixels_x	:	INTEGER := 600);   --column that first color will persist until
	PORT(
		disp_ena		:	IN		STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
		row			:	IN		INTEGER;		--row pixel coordinate
		column		:	IN		INTEGER;		--column pixel coordinate
		pixel_clk	:	IN		STD_LOGIC;
		red			:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
		green			:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
		blue			:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')); --blue magnitude output to DAC
END hw_image_generator;



ARCHITECTURE behavior OF hw_image_generator IS

signal direccion: STD_LOGIC_VECTOR (19 DOWNTO 0);
signal dato: STD_LOGIC_VECTOR (3 DOWNTO 0);
BEGIN

	memoria: work.EZ_ROM port map(address => direccion,
											clock => pixel_clk,
											q =>	dato);
	PROCESS(disp_ena, column, row)
	variable indice: integer := column*128+row;--row * 128 + column;
	BEGIN
		IF(disp_ena = '1') THEN		--display time
		
			IF(row < 128 and column < 128) THEN
				direccion <= std_logic_vector(to_unsigned(indice, direccion'length));
				red <= dato(23 downto 16); --red_vec(indice);
				green	<= dato(15 downto 8); --green_vec(indice);
				blue <= dato(7 downto 0); --blue_vec(indice);
			ELSE
				red <= (OTHERS => '0');
				green <= (OTHERS => '0');
				blue <= (OTHERS => '0');
			END IF;
			
			
		ELSE								--blanking time
			red <= (OTHERS => '0');
			green <= (OTHERS => '0');
			blue <= (OTHERS => '0');
			rom_address <= (OTHERS => '0');
		END IF;
	
	END PROCESS;
END behavior;