--------------------------------------------------------------------------------
-- FileName:        hw_image_generator.vhd
-- Description:     VGA Image Generator with Spatial Downsampling.
--                  Scales a 1024x768 ROM image to fit 640x480 or 800x600.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY hw_image_generator IS
    PORT(
        disp_ena     : IN  STD_LOGIC;  -- '1' = Display time, '0' = Blanking
        row          : IN  INTEGER;    -- Current vertical pixel
        column       : IN  INTEGER;    -- Current horizontal pixel
        h_pixels     : IN  INTEGER;    -- Current VGA horizontal resolution
        v_pixels     : IN  INTEGER;    -- Current VGA vertical resolution
        pixel_clk    : IN  STD_LOGIC;  -- Pixel clock
        show_picture : IN  STD_LOGIC;  -- From system_control ('1'=Pic, '0'=Black)
        red          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        green        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        blue         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END hw_image_generator;

ARCHITECTURE behavior OF hw_image_generator IS

    SIGNAL direccion : STD_LOGIC_VECTOR(19 DOWNTO 0);
    SIGNAL dato      : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

    -- ROM Instantiation: Contains the 1024x768 4-bit grayscale image
    memoria: work.EZ_ROM PORT MAP(
        address => direccion,
        clock   => pixel_clk,
        q       => dato
    );

    PROCESS(disp_ena, show_picture, column, row, h_pixels, v_pixels)
        VARIABLE mapped_col : INTEGER;
        VARIABLE mapped_row : INTEGER;
        VARIABLE rom_index  : INTEGER;
    BEGIN
        IF (disp_ena = '1' AND show_picture = '1') THEN
            
            -- =========================================================
            -- CONCEPTO APLICADO: Spatial Downsampling (Submuestreo)
            -- Aquí se evidencia el ajuste de la resolución de pantalla
            -- a la matriz fija de la ROM (1024x768).
            -- =========================================================
            
            -- Horizontal Mapping
            IF (h_pixels = 640) THEN
                mapped_col := (column * 1023) / 639;
            ELSIF (h_pixels = 800) THEN
                mapped_col := (column * 1023) / 799;
            ELSE
                mapped_col := column; -- Native 1024x768 case
            END IF;
            
            -- Vertical Mapping
            IF (v_pixels = 480) THEN
                mapped_row := (row * 767) / 479;
            ELSIF (v_pixels = 600) THEN
                mapped_row := (row * 767) / 599;
            ELSE
                mapped_row := row; -- Native 1024x768 case
            END IF;
            
            -- Calculate 1D memory address
            rom_index := (mapped_row * 1024) + mapped_col;
            direccion <= std_logic_vector(to_unsigned(rom_index, 20));

            -- Grayscale Expansion: 4-bit to 8-bit DAC mapping
            red   <= dato & "0000";
            green <= dato & "0000";
            blue  <= dato & "0000";

        ELSE
            -- Output black when in blanking time or Black Screen mode
            red       <= (OTHERS => '0');
            green     <= (OTHERS => '0');
            blue      <= (OTHERS => '0');
            direccion <= (OTHERS => '0');
        END IF;

    END PROCESS;
END behavior;