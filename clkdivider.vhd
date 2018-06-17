library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clkdivider is

	port (clk, rst : in STD_LOGIC;
			dclk : out STD_LOGIC
	);

end clkdivider;

architecture Behavioral of clkdivider is

signal cnt_data : std_logic_vector(23 downto 0);
signal d_clk : std_logic := '0';

begin

	process(clk, rst)
	begin
		if rst='1' then
			cnt_data <= (others=>'0');
			d_clk <= '0';
		elsif rising_edge(clk) then
			--if cnt_data = x"0fffff" then
			if cnt_data = x"003fff" then
				d_clk <= not d_clk;
				cnt_data <= (others=>'0');
			else
				cnt_data <= cnt_data+1;
			end if;
		end if;
	end process;
	
	dclk <= d_clk;

end Behavioral;

