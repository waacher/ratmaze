------------------------------------------------------------------------
-- CPE 133 VHDL File: universal_sseg_dec.vhd
--
-- Company: Ratface Engineering
-- Engineer: Samuel Cheng, James Ratner
-- 
-- 
-- Description: Special seven segment display driver. This file 
--  interprets the input(s) as an unsigned binary number
--  and displays the result on the four seven-segment
--  displays on the development board. This module implements 
--  the required multiplexing of the display based
--  upon the CLK input. For this module, the CLK frequency 
--  is expected to be in 50MHz but will work for other 
--  relatively fast frequencies. The CLK input connects to a
--  clock signal from the development board. 
--
--  The display controls are hierarchical in nature. The description 
--   below presents the input information according to it's 
--   functionality. 
-- 
--    VALID: if valid = '0', four dashes are displayed
--           if valid = '1', decimal number appears on display
-- 
--    DP_OE: if dp_oe = '0', no decimal point is displayed 
--           if dp_oe = '1', one decimal point is displayed  
--                             according to dp inputs
--      
--    DP : if dp = "00", dp displayed on right-most 7-seg display
--         if dp = "01", dp displayed on middle-right 7-seg display
--         if dp = "10", dp displayed on middle-left 7-seg display
--         if dp = "11", dp displayed on left-most 7-seg display
--
--    SEL : if sel = "00", displays one count [0,255] with optional '-' sign
--          if sel = "01", displays two counts [0,99] (no sign)
--          if sel = "10", displays one count [0,9999] (no sign) 
--          if sel = "11", displays average academic administrator IQ 
--
--    SIGN: WARNING: only works in SEL="00" 
--           if sign = 0, no minus sign appears
--           if sign = '1', minus sign appears on left-most display
--
--    COUNT1: count used for sel="00" ([0,255]) & sel="10" [0,9999] modes
--            right-most 2-digit count ([0,99]) for sel="01" mode
--            NOTE: 14-bit count
--
--    COUNT2: left-most 2-digit count ([0,99]) for sel="01" mode
--            NOTE: 8-bit count
--
------------------------------------------------------------------------

-----------------------------------------------------------------------
-----------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-------------------------------------------------------------
-- Universal seven-segment display driver. Outputs are active
-- low and configured ABCEDFG in "segment" output. 
--------------------------------------------------------------
entity sseg_dec_uni is
    Port (       COUNT1 : in std_logic_vector(13 downto 0); 
                 COUNT2 : in std_logic_vector(7 downto 0);
                    SEL : in std_logic_vector(1 downto 0);
				  dp_oe : in std_logic;
                     dp : in std_logic_vector(1 downto 0); 					  
                    CLK : in std_logic;
						 SIGN : in std_logic;
						VALID : in std_logic;
                DISP_EN : out std_logic_vector(3 downto 0);
               SEGMENTS : out std_logic_vector(7 downto 0));
end sseg_dec_uni;


-------------------------------------------------------------
-- description of ssegment decoder
-------------------------------------------------------------
architecture my_sseg of sseg_dec_uni is

   -- declaration of 8-bit binary to 2-digit BCD converter --
   component bin2bcdconv 
       Port ( BIN_CNT_IN : in std_logic_vector(13 downto 0);
							SEL : in std_logic_vector(1 downto 0);
                 LSD_OUT : out std_logic_vector(3 downto 0);
                 MSD_OUT : out std_logic_vector(3 downto 0);
                MMSD_OUT : out std_logic_vector(3 downto 0);
					 LLSD_OUT : out std_logic_vector(3 downto 0));
   end component;

	component clk_div
		 Port (  clk : in std_logic;
				  sclk : out std_logic);
	end component;
	
   -- intermediate signal declaration -----------------------
   signal   cnt_dig : std_logic_vector(1 downto 0) := "00"; 
   signal   digit : std_logic_vector (3 downto 0); 
   signal   llsd, mmsd, lsd_cnt1,lsd_cnt2,msd_cnt1,msd_cnt2 : std_logic_vector(3 downto 0); 
	signal   sclk : std_logic; 
   signal   s_count2 : std_logic_vector(13 downto 0); 
	signal   dp_position : STD_LOGIC_VECTOR(3 downto 0);
begin

   -- instantiation of bin to bcd converter -----------------
   my_conv1: bin2bcdconv 
	port map ( BIN_CNT_IN => COUNT1,
                     SEL => SEL,	
                 LSD_OUT => lsd_cnt1, 
                 MSD_OUT => msd_cnt1,
					 MMSD_OUT => mmsd,
					 LLSD_OUT => llsd); 

   s_COUNT2 <= "00" & X"0" & COUNT2;
	
   -- instantiation of bin to bcd converter for second 2 digit display -----------------
   my_conv2: bin2bcdconv 
	port map ( BIN_CNT_IN => s_COUNT2, 
                     SEL => SEL,	
					  LSD_OUT => lsd_cnt2, 
                 MSD_OUT => msd_cnt2,
					 MMSD_OUT => open,
					 LLSD_OUT => open); 
				 
   -- instantiation of clock divider -----------------
   my_clk: clk_div 
	port map (clk => clk,
	          sclk => sclk ); 

   -- advance the count (used for display multiplexing) -----
   process (SCLK)
   begin
      if (rising_edge(SCLK)) then 
         cnt_dig <= cnt_dig + 1; 
      end if; 
   end process; 

	-- select decimal position for Two 2-digit display--
	process(dp)
	begin
		case dp is
			when "00" => dp_position <= "0101";
			when "01" => dp_position <= "1001";
			when "10" => dp_position <= "0110";
			when "11" => dp_position <= "1010";
			when others => dp_position <= "1111";
		end case;
	end process;
	
   -- select the display sseg data abcdefg (active low) based on dp -----
   process (SEL, dp, cnt_dig, digit, dp_oe)
	begin
	   case dp_oe is
		   -- output decimal point --
		   when '1' =>
				case SEL is
					when "00" | "10" =>
						if (not dp = cnt_dig) then
							case digit is
								when "0000" => segments <= "00000010";
								when "0001" => segments <= "10011110";
								when "0010"	=> segments <= "00100100"; 
								when "0011"	=> segments <=	"00001100"; 
								when "0100"	=> segments <=	"10011000"; 
								when "0101"	=> segments <=	"01001000"; 
								when "0110"	=> segments <=	"01000000"; 
								when "0111"	=> segments <=	"00011110"; 
								when "1000"	=> segments <=	"00000000"; 
								when "1001"	=> segments <=	"00001000"; 
								when "1110"	=> segments <=	"11111100";   -- dash
								when others	=> segments <=	"00000010";   -- leading zero
							end case;
						else
							case digit is
								when "0000" => segments <= "00000011";
								when "0001" => segments <= "10011111";
								when "0010"	=> segments <= "00100101"; 
								when "0011"	=> segments <=	"00001101"; 
								when "0100"	=> segments <=	"10011001"; 
								when "0101"	=> segments <=	"01001001"; 
								when "0110"	=> segments <=	"01000001"; 
								when "0111"	=> segments <=	"00011111"; 
								when "1000"	=> segments <=	"00000001"; 
								when "1001"	=> segments <=	"00001001"; 
								when "1110"	=> segments <=	"11111101";   -- dash
								when others	=> segments <=	"11111111";   -- blank
							end case;
						end if;
					
					--Two 2-digit case--	
					when "01" =>
						if(dp_position(CONV_INTEGER(cnt_dig)) = '0') then
							case digit is
								when "0000" => segments <= "0000001" & dp_position(CONV_INTEGER(cnt_dig));
								when "0001" => segments <= "1001111" & dp_position(CONV_INTEGER(cnt_dig));
								when "0010"	=> segments <= "0010010" & dp_position(CONV_INTEGER(cnt_dig)); 
								when "0011"	=> segments <=	"0000110" & dp_position(CONV_INTEGER(cnt_dig)); 
								when "0100"	=> segments <=	"1001100" & dp_position(CONV_INTEGER(cnt_dig)); 
								when "0101"	=> segments <=	"0100100" & dp_position(CONV_INTEGER(cnt_dig)); 
								when "0110"	=> segments <=	"0100000" & dp_position(CONV_INTEGER(cnt_dig)); 
								when "0111"	=> segments <=	"0001111" & dp_position(CONV_INTEGER(cnt_dig)); 
								when "1000"	=> segments <=	"0000000" & dp_position(CONV_INTEGER(cnt_dig)); 
								when "1001"	=> segments <=	"0000100" & dp_position(CONV_INTEGER(cnt_dig)); 
								when "1110"	=> segments <=	"11111101";   -- dash
								when others	=> segments <=	"0000001" & dp_position(CONV_INTEGER(cnt_dig));   -- leading zero
							end case;
						else
							case digit is
								when "0000" => segments <= "00000011";
								when "0001" => segments <= "10011111";
								when "0010"	=> segments <= "00100101"; 
								when "0011"	=> segments <=	"00001101"; 
								when "0100"	=> segments <=	"10011001"; 
								when "0101"	=> segments <=	"01001001"; 
								when "0110"	=> segments <=	"01000001"; 
								when "0111"	=> segments <=	"00011111"; 
								when "1000"	=> segments <=	"00000001"; 
								when "1001"	=> segments <=	"00001001"; 
								when "1110"	=> segments <=	"11111101";   -- dash
								when others	=> segments <=	"11111111";   -- blank
							end case;
						end if;
						
					when others =>
							case digit is
								when "0000" => segments <= "00000011";
								when "0001" => segments <= "10011111";
								when "0010"	=> segments <= "00100101"; 
								when "0011"	=> segments <=	"00001101"; 
								when "0100"	=> segments <=	"10011001"; 
								when "0101"	=> segments <=	"01001001"; 
								when "0110"	=> segments <=	"01000001"; 
								when "0111"	=> segments <=	"00011111"; 
								when "1000"	=> segments <=	"00000001"; 
								when "1001"	=> segments <=	"00001001"; 
								when "1110"	=> segments <=	"11111101";   -- dash
								when others	=> segments <=	"11111111";   -- blank
							end case;		
					end case;
				
			-- don't output decimal point	
			when others =>
				case digit is
					when "0000" => segments <= "00000011";
					when "0001" => segments <= "10011111";
					when "0010"	=> segments <= "00100101"; 
					when "0011"	=> segments <=	"00001101"; 
					when "0100"	=> segments <=	"10011001"; 
					when "0101"	=> segments <=	"01001001"; 
					when "0110"	=> segments <=	"01000001"; 
					when "0111"	=> segments <=	"00011111"; 
					when "1000"	=> segments <=	"00000001"; 
					when "1001"	=> segments <=	"00001001"; 
					when "1110"	=> segments <=	"11111101";   -- dash
					when others	=> segments <=	"11111111";   -- blank
				end case;
		end case;
	end process;
	
   -- actuate the correct display --------------------------
   disp_en <= "1110" when cnt_dig = "00" else 
              "1101" when cnt_dig = "01" else
              "1011" when cnt_dig = "10" else
              "0111" when cnt_dig = "11" else
              "1111"; 

 
	process (cnt_dig, lsd_cnt2, lsd_cnt1, msd_cnt2, msd_cnt1, SEL, valid, sign, mmsd, llsd, dp_oe, dp)
	   variable v_lsd_cnt1, v_msd_cnt1, v_msd_cnt2, mmsd_v : std_logic_vector(3 downto 0);    
	begin
		 
      case SEL is
		   --4 digit display (255)		
			when "00" =>
				-- do the lead zero blanking for mmsb and/or msb's
				if(dp_oe = '1') then
					if (mmsd = X"0" and (dp /= "11")) then 
						if ((msd_cnt1 = X"0") and (dp = "00")) then 
							v_msd_cnt1 := X"F";
						else
							v_msd_cnt1 := msd_cnt1; 
						end if; 
						mmsd_v := X"F";
					else
						v_msd_cnt1 := msd_cnt1;
						mmsd_v := mmsd;
					end if; 
				else
					if (mmsd = X"0") then 
						if (msd_cnt1 = X"0") then 
							v_msd_cnt1 := X"F";
						else
							v_msd_cnt1 := msd_cnt1; 
						end if; 
						mmsd_v := X"F";
					else
						v_msd_cnt1 := msd_cnt1;
						mmsd_v := mmsd;
					end if; 
				end if;
				
				if (valid = '1') then
					if (sign = '0') then
						case cnt_dig is
							when "00" => digit <= "1111"; 
							when "01" => digit <= mmsd_v; 
							when "10" => digit <= v_msd_cnt1; 
							when "11" => digit <= lsd_cnt1; 
							when others => digit <= "0000"; 
						end case; 
					else
						case cnt_dig is 
							when "00" => digit <= "1110"; 
							when "01" => digit <= mmsd_v; 
							when "10" => digit <= v_msd_cnt1; 
							when "11" => digit <= lsd_cnt1; 
							when others => digit <= "0000";
						end case;
					end if;
				else digit <= "1110";
				end if;
			
			--Two 2 digit display
			when "01" =>
				-- do the lead zero blanking for two msb's
				if (msd_cnt1 = X"0") then 
					 v_msd_cnt1 := X"F"; 
				else 
					 v_msd_cnt1 := msd_cnt1;
				end if; 
				  
				if (msd_cnt2 = X"0") then 
					 v_msd_cnt2 := X"F"; 
				else 
					 v_msd_cnt2 := msd_cnt2;
				end if; 

			  
				case cnt_dig is
					when "00" => digit <= v_msd_cnt1; 
					when "01" => digit <= lsd_cnt1; 
					when "10" => digit <= v_msd_cnt2; 
					when "11" => digit <= lsd_cnt2; 
					when others => digit <= "0000"; 
				end case;

			--4 digit display (9999)
			when "10" =>
				if(dp_oe = '1') then
					if (mmsd = X"0" and (dp /= "11")) then 
						if ((msd_cnt1 = X"0") and (dp /= "10")) then 
							if((lsd_cnt1 = X"0") and (dp /= "01")) then
								v_lsd_cnt1 := X"F";
							else
								v_lsd_cnt1 := lsd_cnt1;
							end if;
							v_msd_cnt1 := X"F";
						else
							v_lsd_cnt1 := lsd_cnt1;
							v_msd_cnt1 := msd_cnt1;
						end if; 
						mmsd_v := X"F";
					else
						v_lsd_cnt1 := lsd_cnt1;
						v_msd_cnt1 := msd_cnt1;
						mmsd_v := mmsd;
					end if; 
				else
					if (mmsd = X"0") then 
						if (msd_cnt1 = X"0") then
							if (lsd_cnt1 = X"0") then
								v_lsd_cnt1 := X"F";
							else
								v_lsd_cnt1 := lsd_cnt1;
							end if;
							v_msd_cnt1 := X"F";
						else
							v_lsd_cnt1 := lsd_cnt1;
							v_msd_cnt1 := msd_cnt1;
						end if; 
						mmsd_v := X"F";
					else
						v_lsd_cnt1 := lsd_cnt1;
						v_msd_cnt1 := msd_cnt1;
						mmsd_v := mmsd;
					end if;
				end if;

				case cnt_dig is
					when "00" => digit <= mmsd_v; 
					when "01" => digit <=v_msd_cnt1; 
					when "10" => digit <= v_lsd_cnt1; 
					when "11" => digit <= llsd; 
					when others => digit <= "0000"; 
				end case; 
		
			--Catch all--	
			when others =>
				digit <= "0000";
		end case;
	end process;
			
end my_sseg;




--------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--------------------------------------------------------------------
-- interface description for bin to bcd converter 
--------------------------------------------------------------------
entity bin2bcdconv is
    Port ( BIN_CNT_IN : in std_logic_vector(13 downto 0);
	               SEL : in std_logic_vector(1 downto 0);
              LSD_OUT : out std_logic_vector(3 downto 0);
              MSD_OUT : out std_logic_vector(3 downto 0);
             MMSD_OUT : out std_logic_vector(3 downto 0);
				 LLSD_OUT : out std_logic_vector(3 downto 0));
end bin2bcdconv;

---------------------------------------------------------------------
-- description of 8-bit binary to 3-digit BCD converter 
---------------------------------------------------------------------
architecture my_ckt of bin2bcdconv is
begin
   process(bin_cnt_in, SEL)
       variable cnt_tot_13          : INTEGER range 0 to 9999 := 0;
	    variable cnt_tot_8           : INTEGER range 0 to 255 := 0;
	    variable llsd, lsd,msd, mmsd : INTEGER range 0 to 9 := 0; 
   begin
	 
    cnt_tot_13 := CONV_INTEGER(bin_cnt_in);
    cnt_tot_8  := CONV_INTEGER(bin_cnt_in);

	 -- initialize intermediate signals
    msd  := 0; 
	 lsd  := 0;
	 mmsd := 0;
	 llsd := 0;
	 
	 case SEL is
	    --Max 255
		 when "00" | "01" =>
   	    --  calculate the MMSB
			 for I in 1 to 2 loop
				 exit when (cnt_tot_8 >= 0 and cnt_tot_8 < 100); 
				 mmsd := mmsd + 1; -- increment the mmds count
				 cnt_tot_8 := cnt_tot_8 - 100;
			 end loop;
			 
			 --  calculate the MSB
			 for I in 1 to 9 loop	     
				 exit when (cnt_tot_8 >= 0 and cnt_tot_8 < 10); 
				 msd := msd + 1; -- increment the msd count
				 cnt_tot_8 := cnt_tot_8 - 10;
			 end loop;
			 
			 -- lsd is what is left over	 
			 lsd := cnt_tot_8;  			 
		 
		 --Max 9999 
		 when "10" =>
		    --  calculate the MMSB
			 for I in 1 to 9 loop
				 exit when (cnt_tot_13 >= 0 and cnt_tot_13 < 1000); 
				 mmsd := mmsd + 1; -- increment the mmds count
				 cnt_tot_13 := cnt_tot_13 - 1000;
			 end loop;
			 
			 --  calculate the MSB
			 for I in 1 to 9 loop	     
				 exit when (cnt_tot_13 >= 0 and cnt_tot_13 < 100); 
				 msd := msd + 1; -- increment the msd count
				 cnt_tot_13 := cnt_tot_13 - 100;
			 end loop;
			 
			 --  calculate the LSB
			 for I in 1 to 9 loop	     
				 exit when (cnt_tot_13 >= 0 and cnt_tot_13 < 10); 
				 lsd := lsd + 1; -- increment the msd count
				 cnt_tot_13 := cnt_tot_13 - 10;
			 end loop;
			 
			 -- llsd is what is left over	 
			 llsd := cnt_tot_13; 
			 
		 when others =>
			 msd  := 0; 
			 lsd  := 0;
			 mmsd := 0;
				 llsd := 0; 			 
				 end case;

	 -- convert lsd to binary
	 case llsd is 
	    when 9 =>  llsd_out <= "1001"; 
	    when 8 =>  llsd_out <= "1000"; 
	    when 7 =>  llsd_out <= "0111"; 
	    when 6 =>  llsd_out <= "0110"; 
	    when 5 =>  llsd_out <= "0101"; 
	    when 4 =>  llsd_out <= "0100"; 
	    when 3 =>  llsd_out <= "0011"; 
	    when 2 =>  llsd_out <= "0010"; 
	    when 1 =>  llsd_out <= "0001"; 
	    when 0 =>  llsd_out <= "0000"; 
	    when others =>  llsd_out <= "0000"; 
    end case; 
	 
	 -- convert lsd to binary
	 case lsd is 
	    when 9 =>  lsd_out <= "1001"; 
	    when 8 =>  lsd_out <= "1000"; 
	    when 7 =>  lsd_out <= "0111"; 
	    when 6 =>  lsd_out <= "0110"; 
	    when 5 =>  lsd_out <= "0101"; 
	    when 4 =>  lsd_out <= "0100"; 
	    when 3 =>  lsd_out <= "0011"; 
	    when 2 =>  lsd_out <= "0010"; 
	    when 1 =>  lsd_out <= "0001"; 
	    when 0 =>  lsd_out <= "0000"; 
	    when others =>  lsd_out <= "0000"; 
    end case; 

	 -- convert msd to binary
	 case msd is 
	    when 9 =>  msd_out <= "1001"; 
	    when 8 =>  msd_out <= "1000"; 
	    when 7 =>  msd_out <= "0111"; 
	    when 6 =>  msd_out <= "0110"; 
	    when 5 =>  msd_out <= "0101"; 
	    when 4 =>  msd_out <= "0100"; 
	    when 3 =>  msd_out <= "0011"; 
	    when 2 =>  msd_out <= "0010"; 
	    when 1 =>  msd_out <= "0001"; 
	    when 0 =>  msd_out <= "0000"; 
	    when others =>  msd_out <= "0000"; 
    end case; 

	 -- convert msd to binary
	 case mmsd is 
	    when 9 =>  mmsd_out <= "1001"; 
	    when 8 =>  mmsd_out <= "1000"; 
	    when 7 =>  mmsd_out <= "0111"; 
	    when 6 =>  mmsd_out <= "0110"; 
	    when 5 =>  mmsd_out <= "0101"; 
	    when 4 =>  mmsd_out <= "0100"; 
	    when 3 =>  mmsd_out <= "0011"; 
	    when 2 =>  mmsd_out <= "0010"; 
	    when 1 =>  mmsd_out <= "0001"; 
	    when 0 =>  mmsd_out <= "0000"; 
	    when others =>  mmsd_out <= "0000"; 
    end case; 	 
   end process; 
   
end my_ckt;



-----------------------------------------------------------------------
-----------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-----------------------------------------------------------------------
-- Module to divide the clock 
-----------------------------------------------------------------------
entity clk_div is
    Port (  clk : in std_logic;
           sclk : out std_logic);
end clk_div;

architecture my_clk_div of clk_div is
   constant max_count : integer := (2200);  
   signal tmp_clk : std_logic := '0'; 
begin
   my_div: process (clk,tmp_clk)              
      variable div_cnt : integer := 0;   
   begin
      if (rising_edge(clk)) then   
         if (div_cnt = MAX_COUNT) then 
            tmp_clk <= not tmp_clk; 
            div_cnt := 0; 
         else
            div_cnt := div_cnt + 1; 
         end if; 
      end if; 
      sclk <= tmp_clk; 
   end process my_div; 
end my_clk_div;

