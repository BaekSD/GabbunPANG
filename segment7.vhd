----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:35:45 05/15/2018 
-- Design Name: 
-- Module Name:    segment7 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity segment7 is
	port(
		SEG_INPUT1,SEG_INPUT2,SEG_INPUT3,SEG_INPUT4,SEG_INPUT5,SEG_INPUT6 : in std_logic_vector(3 downto 0);
		segment : out std_logic_vector(7 downto 0);
		dig : out std_logic_vector(5 downto 0);
		clk, rst : in std_logic
	);
end segment7;

architecture Behavioral of segment7 is

component countoto5 is
	port(
		clk, rst : in std_logic;
		cnt : out std_logic_vector(2 downto 0)
	);
end component;

signal seg_int : std_logic_vector(7 downto 0);
signal display_data : std_logic_vector(3 downto 0);
signal clk_count : std_logic_vector(2 downto 0);
signal digit : std_logic_vector(5 downto 0);

begin

	C5 : countoto5 port map(clk=>clk, rst=>rst, cnt=>clk_count);
	
	process(clk, rst)
	begin
		if rst = '1' then
			digit <= "000001";
		else
			if rising_edge(clk) then
				case clk_count is
					when "000" => digit <= "000001";
					when "001" => digit <= "000010";
					when "010" => digit <= "000100";
					when "011" => digit <= "000000";
					--when "011" => digit <= "001000";
					when "100" => digit <= "010000";
					when "101" => digit <= "100000";
					when others => digit <= "000000";
				end case;
			end if;
		end if;
	end process;
	
	process(digit, rst, SEG_INPUT1, SEG_INPUT2, SEG_INPUT3, SEG_INPUT4, SEG_INPUT5, SEG_INPUT6)
	begin
		case digit is
			when "000001" => display_data <= SEG_INPUT1;
			when "000010" => display_data <= SEG_INPUT2;
			when "000100" => display_data <= SEG_INPUT3;
			when "001000" => display_data <= SEG_INPUT4;
			when "010000" => display_data <= SEG_INPUT5;
			when "100000" => display_data <= SEG_INPUT6;
			when others => display_data <= "0000";
		end case;
	end process;
	
	process(display_data)
	begin
		case display_data is
			when x"0" => seg_int <= "11111100";
			when x"1" => seg_int <= "01100000";
			when x"2" => seg_int <= "11011010";
			when x"3" => seg_int <= "11110010";
			when x"4" => seg_int <= "01100110";
			when x"5" => seg_int <= "10110110";
			when x"6" => seg_int <= "10111110";
			when x"7" => seg_int <= "11100100";
			when x"8" => seg_int <= "11111110";
			when x"9" => seg_int <= "11110110";
			when others => seg_int <= (others=>'0');
		end case;
	end process;
	
	dig <= digit;
	segment <= seg_int;

end Behavioral;

