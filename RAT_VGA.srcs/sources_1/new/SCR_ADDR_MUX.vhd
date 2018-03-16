----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/12/2018 03:19:46 PM
-- Design Name: 
-- Module Name: SCR_ADDR_MUX - Behavioral
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

entity SCR_ADDR_MUX is
    Port ( D0 : in STD_LOGIC_VECTOR (7 downto 0);
           D1 : in STD_LOGIC_VECTOR (7 downto 0);
           D2 : in STD_LOGIC_VECTOR (7 downto 0);
           D3 : in STD_LOGIC_VECTOR (7 downto 0);
           SEL : in STD_LOGIC_VECTOR (1 downto 0);
           ADDR : out STD_LOGIC_VECTOR (7 downto 0));
end SCR_ADDR_MUX;

architecture Behavioral of SCR_ADDR_MUX is

begin

    process(SEL)
    begin
        case SEL is
            when "00" => ADDR <= D0;
            when "01" => ADDR <= D1;
            when "10" => ADDR <= D2;
            when "11" => ADDR <= D3;
            when others => ADDR <= D0;
        end case;
    end process;
end Behavioral;
