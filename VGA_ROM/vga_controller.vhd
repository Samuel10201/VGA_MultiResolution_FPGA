--------------------------------------------------------------------------------
--
--   FileName:         vga_controller.vhd
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
--   Version 1.1 03/07/2018 Scott Larson
--     Corrected two minor "off-by-one" errors
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY vga_controller IS
	PORT(
		h_pulse 	:	IN INTEGER;    	--horiztonal sync pulse width in pixels
		h_bp	 	:	IN INTEGER;		--horiztonal back porch width in pixels
		h_pixels	:	IN INTEGER;		--horiztonal display width in pixels
		h_fp	 	:	IN INTEGER;		--horiztonal front porch width in pixels
		h_pol		:	IN STD_LOGIC;		--horizontal sync pulse polarity (1 = positive, 0 = negative)
		v_pulse 	:	IN INTEGER;			--vertical sync pulse width in rows
		v_bp	 	:	IN INTEGER;			--vertical back porch width in rows
		v_pixels	:	IN INTEGER;		--vertical display width in rows
		v_fp	 	:	IN INTEGER;			--vertical front porch width in rows
		v_pol		:	IN STD_LOGIC;	--vertical sync pulse polarity (1 = positive, 0 = negative)
		
		
		pixel_clk	:	IN		STD_LOGIC;	--pixel clock at frequency of VGA mode being used
		reset_n		:	IN		STD_LOGIC;	--active low asycnchronous reset
		h_sync		:	OUT	STD_LOGIC;	--horiztonal sync pulse
		v_sync		:	OUT	STD_LOGIC;	--vertical sync pulse
		disp_ena		:	OUT	STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
		column		:	OUT	INTEGER;		--horizontal pixel coordinate
		row			:	OUT	INTEGER;		--vertical pixel coordinate
		n_blank		:	OUT	STD_LOGIC;	--direct blacking output to DAC
		n_sync		:	OUT	STD_LOGIC); --sync-on-green output to DAC
END vga_controller;

ARCHITECTURE behavior OF vga_controller IS
BEGIN

	n_blank <= '1';  --no direct blanking
	n_sync <= '0';   --no sync on green
	
	PROCESS(pixel_clk, reset_n)
		VARIABLE h_count	:	INTEGER RANGE 0 TO 4095 := 0;  --horizontal counter (counts the columns)
		VARIABLE v_count	:	INTEGER RANGE 0 TO 4095 := 0;  --vertical counter (counts the rows)
		
		VARIABLE	h_period	:	INTEGER;  --total number of pixel clocks in a row
		VARIABLE	v_period	:	INTEGER;  --total number of rows in column
	BEGIN
	
		IF(reset_n = '0') THEN		--reset asserted
			h_count := 0;				
			v_count := 0;				
			h_sync <= NOT h_pol;		
			v_sync <= NOT v_pol;		
			disp_ena <= '0';			
			column <= 0;				
			row <= 0;					
			
		ELSIF(pixel_clk'EVENT AND pixel_clk = '1') THEN
			h_period := h_pulse + h_bp + h_pixels + h_fp;
			v_period := v_pulse + v_bp + v_pixels + v_fp;

			IF(h_count < h_period - 1) THEN		
				h_count := h_count + 1;
			ELSE
				h_count := 0;
				IF(v_count < v_period - 1) THEN	
					v_count := v_count + 1;
				ELSE
					v_count := 0;
				END IF;
			END IF;

			--horizontal sync signal
			IF(h_count < h_pixels + h_fp OR h_count >= h_pixels + h_fp + h_pulse) THEN
				h_sync <= NOT h_pol;		
			ELSE
				h_sync <= h_pol;			
			END IF;
			
			--vertical sync signal
			IF(v_count < v_pixels + v_fp OR v_count >= v_pixels + v_fp + v_pulse) THEN
				v_sync <= NOT v_pol;		
			ELSE
				v_sync <= v_pol;			
			END IF;
			
			--set pixel coordinates
			IF(h_count < h_pixels) THEN  	
				column <= h_count;			
			END IF;
			IF(v_count < v_pixels) THEN	
				row <= v_count;				
			END IF;

			--set display enable output
			IF(h_count < h_pixels AND v_count < v_pixels) THEN  	
				disp_ena <= '1';											 	
			ELSE																	
				disp_ena <= '0';												
			END IF;

		END IF;
	END PROCESS;

END behavior;