library ieee ;
use ieee.std_logic_1164.all;
-----------------------------------------------------
entity ps2_estados is
port(
	ps2_data    :   in std_logic;
	ps2_clock : in  std_logic;									
	key0a : out std_logic_vector(6 downto 0);
	key0b : out std_logic_vector(6 downto 0);	
	key1a : out std_logic_vector(6 downto 0);
	key1b : out std_logic_vector(6 downto 0);	
	key2a : out std_logic_vector(6 downto 0);
	key2b : out std_logic_vector(6 downto 0);
	scan_code_out : out std_logic_vector(7 downto 0);
	scan_ready    : out std_logic	
);
end ps2_estados;
-----------------------------------------------------
architecture PS2 of ps2_estados is
	type tipo_estado is (e0,e1,e2);
	signal estado_siguiente, estado_actual: tipo_estado;
	signal i : integer := 0;
	signal code,tecla,sig0,sig1,sig2 : std_logic_vector(10 downto 0);
	function hex_a_7(h: in std_logic_vector(3 downto 0))
				return std_logic_vector is
		variable resultado: std_logic_vector(6 downto 0);
	begin
		case h is
			when "0000" => resultado := "1000000";
			when "0001" => resultado := "1111001";
			when "0010" => resultado := "0100100";
			when "0011" => resultado := "0110000";
			when "0100" => resultado := "0011001";
			when "0101" => resultado := "0010010";
			when "0110" => resultado := "0000010";
			when "0111" => resultado := "1111000";
			when "1000" => resultado := "0000000";
			when "1001" => resultado := "0010000";
			when "1010" => resultado := "0001000";
			when "1011" => resultado := "0000011";
			when "1100" => resultado := "1000110";
			when "1101" => resultado := "0100001";
			when "1110" => resultado := "0000110";
			when "1111" => resultado := "0001110";
			when others => resultado := "1111111";
		end case;
		return resultado;
	end function;
begin
    state_reg: process(ps2_clock)
    begin
		if (ps2_clock' event and ps2_clock = '0') then
			code(i)<=ps2_data;
			i<=i+1;
			scan_ready <= '0';
			
			if(i=10) then
				tecla<=code;
				
				scan_code_out <= code(8 downto 1); 
				scan_ready    <= '1';
				
				i<=0;
				estado_actual <= estado_siguiente;
			end if;
		end if;
	end process;
	estados: process(estado_actual,tecla)
	begin
		case estado_actual is
			when e0 => 	estado_siguiente<=e1;
							sig0 <= tecla;
			when e1 => 	estado_siguiente<=e2;
							sig1 <= tecla;
			when e2 => 	estado_siguiente<=e0;
							sig2 <= tecla;
			when others => 	estado_siguiente<=e0;
							sig0 <= "11111111111";
							sig1 <= "11111111111";
							sig2 <= "11111111111";
		end case;
	end process;
	key0a <= hex_a_7(sig0(4 downto 1));
	key0b <= hex_a_7(sig0(8 downto 5));	
	key1a <= hex_a_7(sig1(4 downto 1));
	key1b <= hex_a_7(sig1(8 downto 5));	
	key2a <= hex_a_7(sig2(4 downto 1));
	key2b <= hex_a_7(sig2(8 downto 5));	
end PS2;


