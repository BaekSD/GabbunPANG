----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:17:06 05/15/2018 
-- Design Name: 
-- Module Name:    Key_Matrix - Behavioral 
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

entity Key_Matrix is
	port(
		reset : in std_logic;
		clk : in std_logic;
		key_in : in std_logic_vector(3 downto 0);
		key_scan : out std_logic_vector(3 downto 0);
		key_data : out std_logic_vector(3 downto 0);
		key_event : out std_logic
	);
end Key_Matrix;

architecture Behavioral of Key_Matrix is

component clockDividerx4 is
	port(
		clk, reset : in std_logic;
		dclk : out std_logic
	);
end component;

signal scan_cnt : std_logic_vector(3 downto 0);
signal key_data_int : std_logic_vector(3 downto 0);
signal key_in_int : std_logic_vector(3 downto 0);
signal seg_clk : std_logic;

signal key_temp : std_logic_vector(15 downto 0);

begin

	DVD0 : clockDividerx4 port map(clk=>clk, reset=>reset, dclk=>seg_clk);
	
	process(reset, seg_clk)
	begin
		if reset = '1' then
			scan_cnt <= "1110";
		elsif rising_edge(seg_clk) then
			scan_cnt <= scan_cnt(2 downto 0) & scan_cnt(3);
		end if;
	end process;

	process(reset, clk)
	begin
		if reset = '1' then
			key_in_int <= (others=>'1');
		elsif rising_edge(clk) then
			key_in_int <= key_in;
		end if;
	end process;
	
	process(reset, key_in_int, scan_cnt, seg_clk)
	begin
		if reset = '1' then
			key_temp <= (others=>'1');
		elsif rising_edge(seg_clk) then
			case scan_cnt is
				when "1110" => key_temp(15 downto 12) <= "11" & key_in_int(1) & "1";
				when "1101" => key_temp(11 downto 8) <= "1" & key_in_int(2 downto 0);
				when "1011" => key_temp(7 downto 4) <= "11" & key_in_int(1) & "1";
				when "0111" => key_temp(3 downto 0) <= "1111";
--				when "1110" => key_temp(15 downto 12) <= key_in_int;
--				when "1101" => key_temp(11 downto 8) <= key_in_int;
--				when "1011" => key_temp(7 downto 4) <= key_in_int;
--				when "0111" => key_temp(3 downto 0) <= key_in_int;
				when others => key_temp <= key_temp;
			end case;
		end if;
	end process;
	
	process(key_temp)
	begin
		if key_temp = x"ffff" then
			key_event <= '0';
		else
			key_event <= '1';
		end if;
	end process;
	
	process(scan_cnt, key_in_int, seg_clk)
	begin
		if rising_edge(seg_clk) then
			case scan_cnt is
				when "1110" => --if		key_in_int = "1110" then
									--		key_data_int <= x"1";
									if	key_in_int = "1101" then
											key_data_int <= x"4";
--									elsif	key_in_int = "1011" then
--											key_data_int <= x"7";
--									elsif	key_in_int = "0111" then
--											key_data_int <= x"0";
									end if;
				when "1101" => if		key_in_int = "1110" then
											key_data_int <= x"2";
									elsif	key_in_int = "1101" then
											key_data_int <= x"5";
									elsif	key_in_int = "1011" then
											key_data_int <= x"8";
--									elsif	key_in_int = "0111" then
--											key_data_int <= x"a";
									end if;
				when "1011" => --if		key_in_int = "1110" then
									--		key_data_int <= x"3";
									if	key_in_int = "1101" then
											key_data_int <= x"6";
--									elsif	key_in_int = "1011" then
--											key_data_int <= x"9";
--									elsif	key_in_int = "0111" then
--											key_data_int <= x"b";
									end if;
--				when "0111" => if		key_in_int = "1110" then
--											key_data_int <= x"f";
--									elsif	key_in_int = "1101" then
--											key_data_int <= x"e";
--									elsif	key_in_int = "1011" then
--											key_data_int <= x"d";
--									elsif	key_in_int = "0111" then
--											key_data_int <= x"c";
--									end if;
				when others => key_data_int <= key_data_int;
			end case;
		end if;
	end process;
	
	key_data <= key_data_int;
	key_scan <= scan_cnt;

end Behavioral;

