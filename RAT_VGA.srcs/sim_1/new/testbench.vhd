----------------------------------------------------------------------------------
-- Engineer: Stolen from Jordan Jones & Brandon Nghe
--           Modified by James Ratner
-- 
-- Create Date: 10/19/2016 03:04:18 AM
-- Design Name: testbench
-- Module Name: testbench - Behavioral
-- Project Name: Exp 7
-- Target Devices: 
-- Tool Versions: 
-- Description: Experiment 7 testbench 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 1.00 - File Created (11-20-2016)
-- Revision 1.01 - Finished Modifications for Basys3 (10-29-2017)
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity testbench is
--  Port ( );
end testbench;

architecture Behavioral of testbench is

	component RAT_wrapper is
    Port ( RST      : in    STD_LOGIC;
           CLK      : in    STD_LOGIC;
           BUTTONS  : in    STD_LOGIC_VECTOR(3 downto 0);
           VGA_RGB  : out   STD_LOGIC_VECTOR (7 downto 0);
           VGA_HS   : out   STD_LOGIC;
           VGA_VS   : out   STD_LOGIC; 
           LEDS     : out   STD_LOGIC_VECTOR (7 downto 0));
    end component;


--	signal s_LEDS     : STD_LOGIC_VECTOR(7 downto 0):= (others => '0'); 
--	signal s_SEGMENTS : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); 
--	signal s_DISP_EN  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); 
--	signal s_SWITCHES : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); 
	signal s_BUTTONS  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); 
	signal s_RST      : STD_LOGIC := '0';
	signal s_CLK      : STD_LOGIC := '0';
	signal s_LEDS     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	
	signal s_RGB       : std_logic_vector (7 downto 0) := "00000000";
	signal s_HS, s_VS  : std_logic := '0';

begin

   -- instantiate device under test (DUT) ---------
   testMCU : RAT_wrapper 
   PORT Map( RST       => s_RST,
             CLK       => s_CLK,
             BUTTONS   => s_BUTTONS,
             VGA_RGB   => s_RGB,
             VGA_HS    => s_HS,
             VGA_VS    => s_VS,
             LEDS      => s_LEDS);
      
   -- generate clock signal -----------------------
   clk_process : process
   begin
      s_CLK <= '1';
      wait for 5ns;
      s_CLK <= '0';
      wait for 5ns;
   end process clk_process;
    
   -- generate stimulus for DUT --------------------	
   stim_process : process
   begin
        wait for 100 ns;
        s_BUTTONS <= "0100";
        wait for 1000 ns;
        s_BUTTONS <= "0000";
        wait for 100 ns;
        s_BUTTONS <= "0010";
   
        wait;   
        
   end process stim_process;

end Behavioral;
