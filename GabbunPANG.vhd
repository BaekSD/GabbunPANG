library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity GabbunPANG is
	port (
		clk, rstb : in STD_LOGIC;
		key_in : in std_logic_vector(3 downto 0);
		de, lcd_clk : out std_logic;
		lcd : out std_logic_vector(15 downto 0);
		key_scan : out std_logic_vector(3 downto 0);
		segment : out std_logic_vector(7 downto 0);
		dig : out std_logic_vector(5 downto 0)
	);
end GabbunPANG;

architecture Behavioral of GabbunPANG is

COMPONENT reg
	port (
		input : in STD_LOGIC_VECTOR(11 downto 0);
		clk, reset, en : in STD_LOGIC;
		output : out STD_LOGIC_VECTOR(11 downto 0)
	);
END COMPONENT;

COMPONENT clkdivider is
	port (
		clk, rst : in STD_LOGIC;
		dclk : out STD_LOGIC
	);
end COMPONENT;

component key_matrix is
	port(
		reset : in std_logic;
		clk : in std_logic;
		key_in : in std_logic_vector(3 downto 0);
		key_scan : out std_logic_vector(3 downto 0);
		key_data : out std_logic_vector(3 downto 0);
		key_event : out std_logic
	);
end component;

component TFT_LCD is
	port(
		clk, rstb : in std_logic;
		loc_data : in std_logic_vector(11 downto 0);
		map_data : in std_logic_vector(49 downto 0);
		de, lcd_clk : out std_logic;
		lcd : out std_logic_vector(15 downto 0)
	);
end component;

COMPONENT clk_25m
PORT(
	CLKIN_IN : IN std_logic;
	RST_IN : IN std_logic;          
	CLKFX_OUT : OUT std_logic;
	CLKIN_IBUFG_OUT : OUT std_logic;
	CLK0_OUT : OUT std_logic;
	LOCKED_OUT : OUT std_logic
	);
END COMPONENT;

component random is
	port(
		clk, reset : in std_logic;
		rand : out std_logic_vector(50 downto 0)
	);
end component;

component segment7 is
	port(
		SEG_INPUT1,SEG_INPUT2,SEG_INPUT3,SEG_INPUT4,SEG_INPUT5,SEG_INPUT6 : in std_logic_vector(3 downto 0);
		segment : out std_logic_vector(7 downto 0);
		dig : out std_logic_vector(5 downto 0);
		clk, rst : in std_logic
	);
end component;

type state_type is (mix, mix_check, waiting, change, check_before_change, check_after_change, matched, point_up, sleep, check_end, ending);
signal cur_state, next_state : state_type := mix;

signal dclk, dclk_25m : std_logic;

signal key_data : std_logic_vector(3 downto 0);

signal rst_inv : std_logic;

signal loc_reg_in : std_logic_vector(11 downto 0) := "010010110110";
signal loc_reg_out : std_logic_vector(11 downto 0);

signal tile1, tile2 : std_logic_vector(1 downto 0) := "00";

signal key_event : std_logic;

signal rand : std_logic_vector(50 downto 0);

signal check_flag : std_logic := '0';

type map_row is array(0 to 4) of std_logic_vector(1 downto 0);
type map_type is array(0 to 4) of map_row;
signal map_sig : map_type;

signal rand_sig : map_type;

signal map_data : std_logic_vector(49 downto 0);

type match_row is array(0 to 4) of std_logic;
type match_type is array(0 to 4) of match_row;
signal match_sig : match_type;

signal pt3, pt2, pt1, pt0 : std_logic_vector(3 downto 0) := (others=>'0');

signal mv1, mv0 : std_logic_vector(3 downto 0);

signal mv_tmp : std_logic := '0';

begin
	
	Inst_clk_25m: clk_25m PORT MAP(
		CLKIN_IN => clk,
		RST_IN => '0',
		CLKFX_OUT => dclk_25m,
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => open,
		LOCKED_OUT => open
	);
	
	DVD : clkdivider port map (clk=>dclk_25m, rst=>rst_inv, dclk=>dclk);
	keykey : key_matrix port map (reset=>rst_inv, clk=>dclk_25m, key_in=>key_in, key_scan=>key_scan, key_data=>key_data, key_event=>key_event);
	tft : TFT_LCD port map (clk=>dclk_25m, rstb=>rst_inv, loc_data=>loc_reg_in, map_data=>map_data, de=>de, lcd_clk=>lcd_clk, lcd=>lcd);
	loc_reg : reg port map(input=>loc_reg_in, clk=>key_event, reset=>rst_inv, en=>'1', output=>loc_reg_out);
	random_module : random port map(clk=>dclk_25m, reset=>rst_inv, rand=>rand);
	
	SEG : segment7 port map(clk=>dclk, rst=>rst_inv,
									SEG_INPUT1=>pt0, SEG_INPUT2=>pt1, SEG_INPUT3=>pt2, 
									SEG_INPUT4=>pt3, SEG_INPUT5=>mv0, SEG_INPUT6=>mv1, 
									dig=>dig, segment=>segment);

	rst_inv <= not rstb;
	
	map_data <= map_sig(0)(0) & map_sig(1)(0) & map_sig(2)(0) & map_sig(3)(0) & map_sig(4)(0) &
					 map_sig(0)(1) & map_sig(1)(1) & map_sig(2)(1) & map_sig(3)(1) & map_sig(4)(1) &
					 map_sig(0)(2) & map_sig(1)(2) & map_sig(2)(2) & map_sig(3)(2) & map_sig(4)(2) &
					 map_sig(0)(3) & map_sig(1)(3) & map_sig(2)(3) & map_sig(3)(3) & map_sig(4)(3) &
					 map_sig(0)(4) & map_sig(1)(4) & map_sig(2)(4) & map_sig(3)(4) & map_sig(4)(4);

	rand_sig(0)(0) <= rand(49 downto 48);
	rand_sig(1)(0) <= rand(47 downto 46);
	rand_sig(2)(0) <= rand(45 downto 44);
	rand_sig(3)(0) <= rand(43 downto 42);
	rand_sig(4)(0) <= rand(41 downto 40);
	rand_sig(0)(1) <= rand(39 downto 38);
	rand_sig(1)(1) <= rand(37 downto 36);
	rand_sig(2)(1) <= rand(35 downto 34);
	rand_sig(3)(1) <= rand(33 downto 32);
	rand_sig(4)(1) <= rand(31 downto 30);
	rand_sig(0)(2) <= rand(29 downto 28);
	rand_sig(1)(2) <= rand(27 downto 26);
	rand_sig(2)(2) <= rand(25 downto 24);
	rand_sig(3)(2) <= rand(23 downto 22);
	rand_sig(4)(2) <= rand(21 downto 20);
	rand_sig(0)(3) <= rand(19 downto 18);
	rand_sig(1)(3) <= rand(17 downto 16);
	rand_sig(2)(3) <= rand(15 downto 14);
	rand_sig(3)(3) <= rand(13 downto 12);
	rand_sig(4)(3) <= rand(11 downto 10);
	rand_sig(0)(4) <= rand(9 downto 8);
	rand_sig(1)(4) <= rand(7 downto 6);
	rand_sig(2)(4) <= rand(5 downto 4);
	rand_sig(3)(4) <= rand(3 downto 2);
	rand_sig(4)(4) <= rand(1 downto 0);
	
	process(cur_state, next_state, dclk, rst_inv)
	begin
		if rst_inv = '1' then
			cur_state <= mix;
		elsif rising_edge(dclk) then
			cur_state <= next_state;
		end if;
	end process;

	process(cur_state, dclk, rst_inv, key_event)
		variable check_result : integer range 0 to 1 := 0;
		variable x1, y1, x2, y2 : integer range 0 to 4;
		variable cnt_var : integer range 0 to 4;
		variable sleep_cnt : integer range 0 to 3000;
	begin
		if rst_inv = '1' then
			next_state <= mix;
		elsif rising_edge(dclk) then
			if cur_state = mix then
				pt3 <= (others=>'0');
				pt2 <= (others=>'0');
				pt1 <= (others=>'0');
				pt0 <= (others=>'0');
				mv1 <= x"2";
				mv0 <= x"0";
				mv_tmp <= '0';
				cnt_var := 0;
				loc_reg_in <= "010010110110";
				for i in 0 to 4 loop
					for j in 0 to 4 loop
						map_sig(i)(j) <= rand_sig(i)(j);
					end loop;
				end loop;
				check_result := 0;
				next_state <= mix_check;
				
			elsif cur_state = mix_check then
				for p in 0 to 1 loop
					if p = 0 then
						for i in 0 to 4 loop
							for j in 1 to 3 loop
								if map_sig(i)(j-1) = map_sig(i)(j) and map_sig(i)(j) = map_sig(i)(j+1) then
									check_result := 1;
								elsif map_sig(j-1)(i) = map_sig(j)(i) and map_sig(j)(i) = map_sig(j+1)(i) then
									check_result := 1;
								end if;
							end loop;
						end loop;
					else
						if check_result = 1 then
							next_state <= mix;
						else
							next_state <= waiting;
						end if;
					end if;
				end loop;
				
			elsif cur_state = waiting then
				case key_data is
					when x"2" =>
						if loc_reg_out(8 downto 6) = "000" then
							loc_reg_in <= loc_reg_out;
						else
							loc_reg_in <= loc_reg_out(11 downto 9) & (loc_reg_out(8 downto 6) - '1') & loc_reg_out(5 downto 0);
						end if;
						next_state <= waiting;
					when x"4" =>
						if loc_reg_out(11 downto 9) = "000" then
							loc_reg_in <= loc_reg_out;
						else
							loc_reg_in <= (loc_reg_out(11 downto 9) - '1') & loc_reg_out(8 downto 6) & loc_reg_out(5 downto 0);
						end if;
						next_state <= waiting;
					when x"5" =>
						if loc_reg_out(11 downto 6) = loc_reg_out(5 downto 0) then
							loc_reg_in <= loc_reg_out(11 downto 6) & "110110";
							next_state <= waiting;
						elsif loc_reg_out(11 downto 9) = loc_reg_out(5 downto 3) then
							if loc_reg_out(8 downto 6) - '1' = loc_reg_out(2 downto 0) then
								x1 := conv_integer(loc_reg_in(11 downto 9));
								y1 := conv_integer(loc_reg_in(8 downto 6));
								x2 := conv_integer(loc_reg_in(5 downto 3));
								y2 := conv_integer(loc_reg_in(2 downto 0));
								next_state <= check_before_change;
							elsif loc_reg_out(8 downto 6) + '1' = loc_reg_out(2 downto 0) then
								x1 := conv_integer(loc_reg_in(11 downto 9));
								y1 := conv_integer(loc_reg_in(8 downto 6));
								x2 := conv_integer(loc_reg_in(5 downto 3));
								y2 := conv_integer(loc_reg_in(2 downto 0));
								next_state <= check_before_change;
							else
								loc_reg_in <= loc_reg_out(11 downto 6) & loc_reg_out(11 downto 6);
								next_state <= waiting;
							end if;
						elsif loc_reg_out(8 downto 6) = loc_reg_out(2 downto 0) then
							if loc_reg_out(11 downto 9) - '1' = loc_reg_out(5 downto 3) then
								x1 := conv_integer(loc_reg_in(11 downto 9));
								y1 := conv_integer(loc_reg_in(8 downto 6));
								x2 := conv_integer(loc_reg_in(5 downto 3));
								y2 := conv_integer(loc_reg_in(2 downto 0));
								next_state <= check_before_change;
							elsif loc_reg_out(11 downto 9) + '1' = loc_reg_out(5 downto 3) then
								x1 := conv_integer(loc_reg_in(11 downto 9));
								y1 := conv_integer(loc_reg_in(8 downto 6));
								x2 := conv_integer(loc_reg_in(5 downto 3));
								y2 := conv_integer(loc_reg_in(2 downto 0));
								next_state <= check_before_change;
							else
								loc_reg_in <= loc_reg_out(11 downto 6) & loc_reg_out(11 downto 6);
								next_state <= waiting;
							end if;
						else
							loc_reg_in <= loc_reg_out(11 downto 6) & loc_reg_out(11 downto 6);
							next_state <= waiting;
						end if;
					when x"6" =>
						if loc_reg_out(11 downto 9) = "100" then
							loc_reg_in <= loc_reg_out;
						else
							loc_reg_in <= (loc_reg_out(11 downto 9) + '1') & loc_reg_out(8 downto 6) & loc_reg_out(5 downto 0);
						end if;
						next_state <= waiting;
					when x"8" =>
						if loc_reg_out(8 downto 6) = "100" then
							loc_reg_in <= loc_reg_out;
						else
							loc_reg_in <= loc_reg_out(11 downto 9) & (loc_reg_out(8 downto 6) + '1') & loc_reg_out(5 downto 0);
						end if;
						next_state <= waiting;
					when others => loc_reg_in <= loc_reg_out;
				end case;
				
			elsif cur_state = check_before_change then
				if map_sig(x1)(y1) = map_sig(x2)(y2) then
					loc_reg_in <= loc_reg_out(11 downto 6) & "110110";
					next_state <= waiting;
				else
					tile1 <= map_sig(x1)(y1);
					tile2 <= map_sig(x2)(y2);
					if y1 = y2 then
						if x1 < x2 then
							if x2 <= 2 and map_sig(x1)(y1) = map_sig(x2+1)(y2) and map_sig(x1)(y1) = map_sig(x2+2)(y2) then
								next_state <= change;
							elsif y2 >= 2 and map_sig(x1)(y1) = map_sig(x2)(y2-1) and map_sig(x1)(y1) = map_sig(x2)(y2-2) then
								next_state <= change;
							elsif y2 <= 2 and map_sig(x1)(y1) = map_sig(x2)(y2+1) and map_sig(x1)(y1) = map_sig(x2)(y2+2) then
								next_state <= change;
							elsif y2 >= 1 and y2 <= 3 and map_sig(x1)(y1) = map_sig(x2)(y2-1) and map_sig(x1)(y1) = map_sig(x2)(y2+1) then
								next_state <= change;
							elsif x1 >= 2 and map_sig(x2)(y2) = map_sig(x1-1)(y1) and map_sig(x2)(y2) = map_sig(x1-2)(y1) then
								next_state <= change;
							elsif y1 >= 2 and map_sig(x2)(y2) = map_sig(x1)(y1-1) and map_sig(x2)(y2) = map_sig(x1)(y1-2) then
								next_state <= change;
							elsif y1 <= 2 and map_sig(x2)(y2) = map_sig(x1)(y1+1) and map_sig(x2)(y2) = map_sig(x1)(y1+2) then
								next_state <= change;
							elsif y1 >= 1 and y1 <= 3 and map_sig(x2)(y2) = map_sig(x1)(y1-1) and map_sig(x2)(y2) = map_sig(x1)(y1+1) then
								next_state <= change;
							else
								loc_reg_in <= loc_reg_out(11 downto 6) & "110110";
								next_state <= waiting;
							end if;
						else
							if x2 >= 2 and map_sig(x1)(y1) = map_sig(x2-1)(y2) and map_sig(x1)(y1) = map_sig(x2-2)(y2) then
								next_state <= change;
							elsif y2 >= 2 and map_sig(x1)(y1) = map_sig(x2)(y2-1) and map_sig(x1)(y1) = map_sig(x2)(y2-2) then
								next_state <= change;
							elsif y2 <= 2 and map_sig(x1)(y1) = map_sig(x2)(y2+1) and map_sig(x1)(y1) = map_sig(x2)(y2+2) then
								next_state <= change;
							elsif y2 >= 1 and y2 <= 3 and map_sig(x1)(y1) = map_sig(x2)(y2-1) and map_sig(x1)(y1) = map_sig(x2)(y2+1) then
								next_state <= change;
							elsif x1 <= 2 and map_sig(x2)(y2) = map_sig(x1+1)(y1) and map_sig(x2)(y2) = map_sig(x1+2)(y1) then
								next_state <= change;
							elsif y1 >= 2 and map_sig(x2)(y2) = map_sig(x1)(y1-1) and map_sig(x2)(y2) = map_sig(x1)(y1-2) then
								next_state <= change;
							elsif y1 <= 2 and map_sig(x2)(y2) = map_sig(x1)(y1+1) and map_sig(x2)(y2) = map_sig(x1)(y1+2) then
								next_state <= change;
							elsif y1 >= 1 and y1 <= 3 and map_sig(x2)(y2) = map_sig(x1)(y1-1) and map_sig(x2)(y2) = map_sig(x1)(y1+1) then
								next_state <= change;
							else
								loc_reg_in <= loc_reg_out(11 downto 6) & "110110";
								next_state <= waiting;
							end if;
						end if;
					else
						if y1 < y2 then
							if x2 >= 2 and map_sig(x1)(y1) = map_sig(x2-1)(y2) and map_sig(x1)(y1) = map_sig(x2-2)(y2) then
								next_state <= change;
							elsif x2 <= 2 and map_sig(x1)(y1) = map_sig(x2+1)(y2) and map_sig(x1)(y1) = map_sig(x2+2)(y2) then
								next_state <= change;
							elsif x2 >= 1 and x2 <= 3 and map_sig(x1)(y1) = map_sig(x2-1)(y2) and map_sig(x1)(y1) = map_sig(x2+1)(y2) then
								next_state <= change;
							elsif y2 <= 2 and map_sig(x1)(y1) = map_sig(x2)(y2+1) and map_sig(x1)(y1) = map_sig(x2)(y2+2) then
								next_state <= change;
							elsif x1 >= 2 and map_sig(x2)(y2) = map_sig(x1-1)(y1) and map_sig(x2)(y2) = map_sig(x1-2)(y1) then
								next_state <= change;
							elsif x1 <= 2 and map_sig(x2)(y2) = map_sig(x1+1)(y1) and map_sig(x2)(y2) = map_sig(x1+2)(y1) then
								next_state <= change;
							elsif x1 >= 1 and x1 <= 3 and map_sig(x2)(y2) = map_sig(x1-1)(y1) and map_sig(x2)(y2) = map_sig(x1+1)(y1) then
								next_state <= change;
							elsif y1 >= 2 and map_sig(x2)(y2) = map_sig(x1)(y1-1) and map_sig(x2)(y2) = map_sig(x1)(y1-2) then
								next_state <= change;
							else
								loc_reg_in <= loc_reg_out(11 downto 6) & "110110";
								next_state <= waiting;
							end if;
						else
							if x2 >= 2 and map_sig(x1)(y1) = map_sig(x2-1)(y2) and map_sig(x1)(y1) = map_sig(x2-2)(y2) then
								next_state <= change;
							elsif x2 <= 2 and map_sig(x1)(y1) = map_sig(x2+1)(y2) and map_sig(x1)(y1) = map_sig(x2+2)(y2) then
								next_state <= change;
							elsif x2 >= 1 and x2 <= 3 and map_sig(x1)(y1) = map_sig(x2-1)(y2) and map_sig(x1)(y1) = map_sig(x2+1)(y2) then
								next_state <= change;
							elsif y2 >= 2 and map_sig(x1)(y1) = map_sig(x2)(y2-1) and map_sig(x1)(y1) = map_sig(x2)(y2-2) then
								next_state <= change;
							elsif x1 >= 2 and map_sig(x2)(y2) = map_sig(x1-1)(y1) and map_sig(x2)(y2) = map_sig(x1-2)(y1) then
								next_state <= change;
							elsif x1 <= 2 and map_sig(x2)(y2) = map_sig(x1+1)(y1) and map_sig(x2)(y2) = map_sig(x1+2)(y1) then
								next_state <= change;
							elsif x1 >= 1 and x1 <= 3 and map_sig(x2)(y2) = map_sig(x1-1)(y1) and map_sig(x2)(y2) = map_sig(x1+1)(y1) then
								next_state <= change;
							elsif y1 <= 2 and map_sig(x2)(y2) = map_sig(x1)(y1+1) and map_sig(x2)(y2) = map_sig(x1)(y1+2) then
								next_state <= change;
							else
								loc_reg_in <= loc_reg_out(11 downto 6) & "110110";
								next_state <= waiting;
							end if;
						end if;
					end if;
				end if;
				
			elsif cur_state = change then
				if mv_tmp = '0' then
					mv_tmp <= '1';
				elsif mv0 = x"0" then
					mv1 <= mv1 - 1;
					mv0 <= x"9";
					mv_tmp <= '0';
				else
					mv0 <= mv0 - 1;
					mv_tmp <= '0';
				end if;
				loc_reg_in <= loc_reg_out(11 downto 6) & "110110";
				map_sig(x1)(y1) <= tile2;
				map_sig(x2)(y2) <= tile1;
				next_state <= check_after_change;
				check_result := 0;
				
			elsif cur_state = check_after_change then
				for p in 0 to 1 loop
					if p = 0 then
						for i in 0 to 4 loop
							for j in 1 to 3 loop
								if map_sig(i)(j-1) = map_sig(i)(j) and map_sig(i)(j) = map_sig(i)(j+1) then
									match_sig(i)(j-1) <= '1';
									match_sig(i)(j) <= '1';
									match_sig(i)(j+1) <= '1';
									check_result := 1;
								elsif map_sig(j-1)(i) = map_sig(j)(i) and map_sig(j)(i) = map_sig(j+1)(i) then
									match_sig(j-1)(i) <= '1';
									match_sig(j)(i) <= '1';
									match_sig(j+1)(i) <= '1';
									check_result := 1;
								end if;
							end loop;
						end loop;
					else
						if check_result = 1 then
							check_result := 0;
							cnt_var := 0;
							next_state <= matched;
						else
							next_state <= check_end;
						end if;
					end if;
				end loop;
				
			elsif cur_state = matched then
				if match_sig(cnt_var)(4) = '1' then --xxxx1
					if match_sig(cnt_var)(3) = '1' then --xxx11
						if match_sig(cnt_var)(2) = '1' then --xx111
							if match_sig(cnt_var)(1) = '1' then --x1111
								if match_sig(cnt_var)(0) = '1' then --11111
									map_sig(cnt_var)(4) <= rand_sig(cnt_var)(4); map_sig(cnt_var)(3) <= rand_sig(cnt_var)(3); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
									map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
								else --01111
									map_sig(cnt_var)(4) <= map_sig(cnt_var)(0); map_sig(cnt_var)(3) <= rand_sig(cnt_var)(3); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
									map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
								end if;
							elsif match_sig(cnt_var)(0) = '1' then --10111
								map_sig(cnt_var)(4) <= map_sig(cnt_var)(1); map_sig(cnt_var)(3) <= rand_sig(cnt_var)(3); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
								map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
							else --00111
								map_sig(cnt_var)(4) <= map_sig(cnt_var)(1); map_sig(cnt_var)(3) <= map_sig(cnt_var)(0); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
								map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
							end if;
						elsif match_sig(cnt_var)(1) = '1' then --x1011
							if match_sig(cnt_var)(0) = '1' then --11011
								map_sig(cnt_var)(4) <= map_sig(cnt_var)(2); map_sig(cnt_var)(3) <= rand_sig(cnt_var)(3); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
								map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
							else --01011
								map_sig(cnt_var)(4) <= map_sig(cnt_var)(2); map_sig(cnt_var)(3) <= map_sig(cnt_var)(0); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
								map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
							end if;
						elsif match_sig(cnt_var)(0) = '1' then --10011
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(2); map_sig(cnt_var)(3) <= map_sig(cnt_var)(1); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						else --00011
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(2); map_sig(cnt_var)(3) <= map_sig(cnt_var)(1); map_sig(cnt_var)(2) <= map_sig(cnt_var)(0);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						end if;
					elsif match_sig(cnt_var)(2) = '1' then --xx101
						if match_sig(cnt_var)(1) = '1' then --x1101
							if match_sig(cnt_var)(0) = '1' then --11101
								map_sig(cnt_var)(4) <= map_sig(cnt_var)(3); map_sig(cnt_var)(3) <= rand_sig(cnt_var)(3); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
								map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
							else --01101
								map_sig(cnt_var)(4) <= map_sig(cnt_var)(3); map_sig(cnt_var)(3) <= map_sig(cnt_var)(0); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
								map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
							end if;
						elsif match_sig(cnt_var)(0) = '1' then --10101
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(3); map_sig(cnt_var)(3) <= map_sig(cnt_var)(1); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						else --00101
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(3); map_sig(cnt_var)(3) <= map_sig(cnt_var)(1); map_sig(cnt_var)(2) <= map_sig(cnt_var)(0);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						end if;
					elsif match_sig(cnt_var)(1) = '1' then --x1001
						if match_sig(cnt_var)(0) = '1' then --11001
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(3); map_sig(cnt_var)(3) <= map_sig(cnt_var)(2); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						else --01001
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(3); map_sig(cnt_var)(3) <= map_sig(cnt_var)(2); map_sig(cnt_var)(2) <= map_sig(cnt_var)(0);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						end if;
					elsif match_sig(cnt_var)(0) = '1' then --10001
						map_sig(cnt_var)(4) <= map_sig(cnt_var)(3); map_sig(cnt_var)(3) <= map_sig(cnt_var)(2); map_sig(cnt_var)(2) <= map_sig(cnt_var)(1);
						map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
					else --00001
						map_sig(cnt_var)(4) <= map_sig(cnt_var)(3); map_sig(cnt_var)(3) <= map_sig(cnt_var)(2); map_sig(cnt_var)(2) <= map_sig(cnt_var)(1);
						map_sig(cnt_var)(1) <= map_sig(cnt_var)(0); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
					end if;
				elsif match_sig(cnt_var)(3) = '1' then --xxx10
					if match_sig(cnt_var)(2) = '1' then --xx110
						if match_sig(cnt_var)(1) = '1' then --x1110
							if match_sig(cnt_var)(0) = '1' then --11110
								map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= rand_sig(cnt_var)(3); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
								map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
							else --01110
								map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(0); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
								map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
							end if;
						elsif match_sig(cnt_var)(0) = '1' then --10110
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(1); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						else --00110
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(1); map_sig(cnt_var)(2) <= map_sig(cnt_var)(0);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						end if;
					elsif match_sig(cnt_var)(1) = '1' then --x1010
						if match_sig(cnt_var)(0) = '1' then --11010
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(2); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						else --01010
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(2); map_sig(cnt_var)(2) <= map_sig(cnt_var)(0);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						end if;
					elsif match_sig(cnt_var)(0) = '1' then --10010
						map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(2); map_sig(cnt_var)(2) <= map_sig(cnt_var)(1);
						map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
					else --00010
						map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(0)(3) <= map_sig(cnt_var)(2); map_sig(cnt_var)(2) <= map_sig(cnt_var)(1);
						map_sig(cnt_var)(1) <= map_sig(cnt_var)(0); map_sig(0)(0) <= rand_sig(cnt_var)(0);
					end if;
				elsif match_sig(cnt_var)(2) = '1' then --xx100
					if match_sig(cnt_var)(1) = '1' then --x1100
						if match_sig(cnt_var)(0) = '1' then --11100
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(3); map_sig(cnt_var)(2) <= rand_sig(cnt_var)(2);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						else --01100
							map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(3); map_sig(cnt_var)(2) <= map_sig(cnt_var)(0);
							map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
						end if;
					elsif match_sig(cnt_var)(0) = '1' then --10100
						map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(3); map_sig(cnt_var)(2) <= map_sig(cnt_var)(1);
						map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
					else --00100
						map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(3); map_sig(cnt_var)(2) <= map_sig(cnt_var)(1);
						map_sig(cnt_var)(1) <= map_sig(cnt_var)(0); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
					end if;
				elsif match_sig(cnt_var)(1) = '1' then --x1000
					if match_sig(cnt_var)(0) = '1' then --11000
						map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(3); map_sig(cnt_var)(2) <= map_sig(cnt_var)(2);
						map_sig(cnt_var)(1) <= rand_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
					else --01000
						map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(3); map_sig(cnt_var)(2) <= map_sig(cnt_var)(2);
						map_sig(cnt_var)(1) <= map_sig(cnt_var)(0); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
					end if;
				elsif match_sig(cnt_var)(0) = '1' then --10000
					map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(3); map_sig(cnt_var)(2) <= map_sig(cnt_var)(2);
					map_sig(cnt_var)(1) <= map_sig(cnt_var)(1); map_sig(cnt_var)(0) <= rand_sig(cnt_var)(0);
				else --00000
					map_sig(cnt_var)(4) <= map_sig(cnt_var)(4); map_sig(cnt_var)(3) <= map_sig(cnt_var)(3); map_sig(cnt_var)(2) <= map_sig(cnt_var)(2);
					map_sig(cnt_var)(1) <= map_sig(cnt_var)(1); map_sig(cnt_var)(0) <= map_sig(cnt_var)(0);
				end if;
				
				if cnt_var = 4 then
					x1 := 0;
					y1 := 0;
					check_result := 0;
					next_state <= point_up;
				else
					cnt_var := cnt_var + 1;
				end if;
				
			elsif cur_state = point_up then
				if match_sig(x1)(y1) = '1' then
					match_sig(x1)(y1) <= '0';
					if pt2 = x"9" and pt1 = x"9" and pt0 = x"9" then
						pt3 <= pt3 + 1;
						pt2 <= x"0";
						pt1 <= x"0";
						pt0 <= x"0";
					elsif pt1 = x"9" and pt0 = x"9" then
						pt2 <= pt2 + 1;
						pt1 <= x"0";
						pt0 <= x"0";
					elsif pt0 = x"9" then
						pt1 <= pt1 + 1;
						pt0 <= x"0";
					else
						pt0 <= pt0 + 1;
					end if;
				end if;
				if x1 = 4 and y1 = 4 then
					sleep_cnt := 0;
					next_state <= sleep;
				elsif y1 = 4 then
					y1 := 0;
					x1 := x1 + 1;
				else
					y1 := y1 + 1;
				end if;
				
			elsif cur_state = sleep then
				if sleep_cnt < 700 then
					sleep_cnt := sleep_cnt + 1;
					next_state <= sleep;
				else
					next_state <= check_after_change;
				end if;
				
			elsif cur_state = check_end then
				if mv0 = x"0" and mv1 = x"0" then
					next_state <= ending;
				else
					next_state <= waiting;
				end if;
				
			elsif cur_state = ending then
				next_state <= ending;
			end if;
		end if;
	end process;

end Behavioral;

