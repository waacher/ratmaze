----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/12/2018 03:19:46 PM
-- Design Name: 
-- Module Name: SCR_DIN_MUX - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity SCR_DIN_MUX is
    Port ( D0 : in STD_LOGIC_VECTOR (7 downto 0);
           D1 : in STD_LOGIC_VECTOR (9 downto 0);
           DATA : out STD_LOGIC_VECTOR (9 downto 0);
           SCR_DATA_SEL : in STD_LOGIC);
end SCR_DIN_MUX;

architecture Behavioral of SCR_DIN_MUX is

begin
    process(SCR_DATA_SEL)
    begin
        case SCR_DATA_SEL is
            when '0' => DATA <= "00" & D0;
            when '1' => DATA <= D1;
            when others => DATA <= D1;
        end case;
    end process;
end Behavioral;
