----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:24:27 05/24/2018 
-- Design Name: 
-- Module Name:    random - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity random is
	port(
		clk, reset : in std_logic;
		rand : out std_logic_vector(50 downto 0)
	);
end random;

architecture Behavioral of random is

signal rand_sig : std_logic_vector(50 downto 0) := "010001000000000000000000000000000000000000000000000";
signal count : std_logic_vector(50 downto 0) := (others => '0');

begin
	process(clk, reset)
	begin
		if reset = '1' then
			rand_sig <= count;
		elsif rising_edge(clk) then
			count <= count + 1;
			rand_sig <= rand_sig(49 downto 0) & (not (rand_sig(50) xor rand_sig(25)));
		end if;
	end process;
	
	rand <= rand_sig;

end Behavioral;

