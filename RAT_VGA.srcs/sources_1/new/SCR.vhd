----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/12/2018 03:07:06 PM
-- Design Name: 
-- Module Name: SCR - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.NUMERIC_STD.ALL;

entity SCR is
    Port ( DATA_IN : in STD_LOGIC_VECTOR (9 downto 0);
           WE : in STD_LOGIC;
           ADDR : in STD_LOGIC_VECTOR (7 downto 0);
           CLK : in STD_LOGIC;
           DATA_OUT : out STD_LOGIC_VECTOR (9 downto 0));
end SCR;

architecture Behavioral of SCR is
    TYPE memory is array (0 to 256) of std_logic_vector(9 downto 0); --changed from (3 downto 0)
    SIGNAL MY_RAM : memory := (others => (others =>'0') );

begin

   the_ram: process(CLK,WE,DATA_IN,ADDR,MY_RAM)
   begin
       if (WE = '1') then 
          if (rising_edge(CLK)) then 
              MY_RAM(conv_integer(ADDR)) <= DATA_IN;
          end if; 
       end if; 
 
       DATA_OUT <= MY_RAM(conv_integer(ADDR));
 

   end process the_ram; 

end Behavioral;
