library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TFT_LCD is
	port(
		clk, rstb : in std_logic;
		loc_data : in std_logic_vector(11 downto 0);
		map_data : in std_logic_vector(49 downto 0);
		de, lcd_clk : out std_logic;
		lcd : out std_logic_vector(15 downto 0)
	);
end TFT_LCD;

architecture Behavioral of TFT_LCD is

constant tHP  : integer := 1056;   -- Hsync Period
constant tHW  : integer := 1;   -- Hsync Pulse Width
constant tHBP : integer := 45;   -- Hsync Back Porch
constant tHV  : integer := 800;   -- Horizontal valid data width
constant tHFP : integer := (tHP-tHW-tHBP-tHV);   -- Horizontal Front Port
constant tVP  : integer := 635;   -- Vsync Period
constant tVW  : integer := 1;   -- Vsync Pulse Width
constant tVBP : integer := 22;   -- Vsync Back Portch
constant tW   : integer := 480;   -- Vertical valid data width
constant tVFP : integer := (tVP-tVW-tVBP-tW);   -- Vertical Front Porch

--constant tHP  : integer := 928;   -- Hsync Period
--constant tHW  : integer := 48;   -- Hsync Pulse Width
--constant tHBP : integer := 40;   -- Hsync Back Porch
--constant tHV  : integer := 800;   -- Horizontal valid data width
--constant tHFP : integer := (tHP-tHW-tHBP-tHV);   -- Horizontal Front Port
--constant tVP  : integer := 525;   -- Vsync Period
--constant tVW  : integer := 3;   -- Vsync Pulse Width
--constant tVBP : integer := 29;   -- Vsync Back Portch
--constant tW   : integer := 480;   -- Vertical valid data width
--constant tVFP : integer := (tVP-tVW-tVBP-tW);   -- Vertical Front Porch

signal lcd_data : std_logic_vector(15 downto 0);

signal hsync_cnt  : integer range 0 to (tHP+tHW);
signal vsync_cnt  : integer range 0 to tVP;
signal de_i: std_logic;

signal r_data: std_logic_vector(4 downto 0);
signal g_data: std_logic_vector(5 downto 0);
signal b_data: std_logic_vector(4 downto 0);

signal now_x, now_y, sel_x, sel_y : std_logic_vector(2 downto 0);

type map_row is array(0 to 4) of std_logic_vector(1 downto 0);
type map_type is array(0 to 4) of map_row;
signal map_sig : map_type;

begin
	now_x <= loc_data(11 downto 9);
	now_y <= loc_data(8 downto 6);
	sel_x <= loc_data(5 downto 3);
	sel_y <= loc_data(2 downto 0);
	
	map_sig(0)(0) <= map_data(49 downto 48);
	map_sig(1)(0) <= map_data(47 downto 46);
	map_sig(2)(0) <= map_data(45 downto 44);
	map_sig(3)(0) <= map_data(43 downto 42);
	map_sig(4)(0) <= map_data(41 downto 40);
	map_sig(0)(1) <= map_data(39 downto 38);
	map_sig(1)(1) <= map_data(37 downto 36);
	map_sig(2)(1) <= map_data(35 downto 34);
	map_sig(3)(1) <= map_data(33 downto 32);
	map_sig(4)(1) <= map_data(31 downto 30);
	map_sig(0)(2) <= map_data(29 downto 28);
	map_sig(1)(2) <= map_data(27 downto 26);
	map_sig(2)(2) <= map_data(25 downto 24);
	map_sig(3)(2) <= map_data(23 downto 22);
	map_sig(4)(2) <= map_data(21 downto 20);
	map_sig(0)(3) <= map_data(19 downto 18);
	map_sig(1)(3) <= map_data(17 downto 16);
	map_sig(2)(3) <= map_data(15 downto 14);
	map_sig(3)(3) <= map_data(13 downto 12);
	map_sig(4)(3) <= map_data(11 downto 10);
	map_sig(0)(4) <= map_data(9 downto 8);
	map_sig(1)(4) <= map_data(7 downto 6);
	map_sig(2)(4) <= map_data(5 downto 4);
	map_sig(3)(4) <= map_data(3 downto 2);
	map_sig(4)(4) <= map_data(1 downto 0);

	process(clk, rstb)         --  sync 계산
	begin
		if(rstb = '1')then
			hsync_cnt<= 0;
			vsync_cnt<= 0;
		elsif(rising_edge(clk)) then
			if(hsync_cnt=tHP)then
				hsync_cnt<=0;
			else
				hsync_cnt<= hsync_cnt + 1;
			end if;
			if(hsync_cnt=tHP)then
				if(vsync_cnt=tVP)then
					vsync_cnt<=0;
				else
					vsync_cnt<=vsync_cnt + 1;
				end if;
			end if;
		end if;   
	end process;


	
	process(CLK, RSTB,vsync_cnt,hsync_cnt)         --Data Enable
   begin
      if(RSTB = '1')then
         de_i<='0';
      elsif(rising_edge(CLK)) then
         if ((vsync_cnt >= (tVW + tVBP)) and (vsync_cnt <= (tVW + tVBP + tW ))) then
            if(hsync_cnt=(tHBP)) then
               de_i<='1';
            elsif(hsync_cnt=(tHV+tHBP)) then
               de_i<='0';
            else
               de_i<=de_i;
            end if;
         else
            de_i<='0';
         end if;
      end if;
    end process;
   


	process(clk, rstb)         --출력할 이미지
		variable x, y : integer range 0 to 5;
	begin
		if (rstb='1')then
			r_data<= (others=>'0'); g_data<= (others=>'0'); b_data<= (others=>'0');
		elsif (rising_edge(clk)) then
			if((hsync_cnt >= (tHW + tHBP + 200)) and (hsync_cnt <= (tHW + tHBP + 279))) then
				x := 0;
			elsif((hsync_cnt >= (tHW + tHBP + 280)) and (hsync_cnt <= (tHW + tHBP + 359))) then
				x := 1;
			elsif((hsync_cnt >= (tHW + tHBP + 360)) and (hsync_cnt <= (tHW + tHBP + 439))) then
				x := 2;
			elsif((hsync_cnt >= (tHW + tHBP + 440)) and (hsync_cnt <= (tHW + tHBP + 519))) then
				x := 3;
			elsif((hsync_cnt >= (tHW + tHBP + 520)) and (hsync_cnt <= (tHW + tHBP + 599))) then
				x := 4;
			else
				x := 5;
			end if;
			if((vsync_cnt >= (tVW + tVBP + 40)) and (vsync_cnt <= (tVW + tVBP + 119))) then
				y := 0;
			elsif((vsync_cnt >= (tVW + tVBP + 120)) and (vsync_cnt <= (tVW + tVBP + 199))) then
				y := 1;
			elsif((vsync_cnt >= (tVW + tVBP + 200)) and (vsync_cnt <= (tVW + tVBP + 279))) then
				y := 2;
			elsif((vsync_cnt >= (tVW + tVBP + 280)) and (vsync_cnt <= (tVW + tVBP + 359))) then
				y := 3;
			elsif((vsync_cnt >= (tVW + tVBP + 360)) and (vsync_cnt <= (tVW + tVBP + 439))) then
				y := 4;
			else
				y := 5;
			end if;
			
			if(x = 5 or y = 5) then
				r_data<= (others=>'0'); g_data<= (others=>'0'); b_data<= (others=>'0');
			else
				if((vsync_cnt >= (tVW + tVBP + 100 + conv_integer(sel_y)*80)) and (vsync_cnt <= (tVW + tVBP + 119 + conv_integer(sel_y)*80))) and
					((hsync_cnt >= (tHW + tHBP + 200 + conv_integer(sel_x)*80)) and (hsync_cnt <= (tHW + tHBP + 219 + conv_integer(sel_x)*80))) then
					r_data<= (others=>'1'); g_data<= (others=>'1'); b_data<= (others=>'1');
				elsif((vsync_cnt >= (tVW + tVBP + 100 + conv_integer(now_y)*80)) and (vsync_cnt <= (tVW + tVBP + 119 + conv_integer(now_y)*80))) and
					((hsync_cnt >= (tHW + tHBP + 260 + conv_integer(now_x)*80)) and (hsync_cnt <= (tHW + tHBP + 279 + conv_integer(now_x)*80))) then
					r_data<= (others=>'1'); g_data<= (others=>'1'); b_data<= (others=>'1');
				else
					case map_sig(x)(y) is
						when "00" => r_data<=(others=>'1'); g_data<=(others=>'0'); b_data<=(others=>'0');
						when "01" => r_data<=(others=>'0'); g_data<=(others=>'1'); b_data<=(others=>'0');
						when "10" => r_data<=(others=>'0'); g_data<=(others=>'0'); b_data<=(others=>'1');
						when "11" => r_data<=(others=>'1'); g_data<=(others=>'0'); b_data<=(others=>'1');
						when others => r_data<=(others=>'0'); g_data<=(others=>'0'); b_data<=(others=>'0');
					end case;
				end if;
			end if;
		end if;
	end process;
	
	lcd<= r_data & g_data & b_data;
	de<=de_i;
	lcd_clk <= clk;

end Behavioral;

