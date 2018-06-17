----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:25:36 05/15/2018 
-- Design Name: 
-- Module Name:    clockDividerx4 - Behavioral 
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

entity clockDividerx4 is
	port(
		clk, reset : in std_logic;
		dclk : out std_logic
	);
end clockDividerx4;

architecture Behavioral of clockDividerx4 is

signal cnt_data : std_logic_vector(3 downto 0);
signal d_clk : std_logic;

begin

	process(clk, reset)
	begin
		if reset = '1' then
			cnt_data <= (others=>'0');
			d_clk <= '0';
		elsif rising_edge(clk) then
			if cnt_data = x"f" then
				cnt_data <= (others=>'0');
				d_clk <= not d_clk;
			else
				d_clk <= d_clk;
				cnt_data <= cnt_data + '1';
			end if;
		end if;
	end process;

	dclk <= d_clk;

end Behavioral;

