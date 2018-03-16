------------------------------------------------------------------------------
-- Company: RAT Technologies
-- Engineer: James Ratner
-- 
-- Create Date:    13:55:34 04/06/2014 
-- Design Name: 
-- Module Name:    Mux - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Full featured D Flip-flop intended for use as flag register. 
--
-- Dependencies: 
--
-- Revision: 3.0
-- Revision 0.01 - File Created
-- Additional Comments: 
--
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity FlagReg is
    Port ( D    : in  STD_LOGIC; --flag input
           LD   : in  STD_LOGIC; --load Q with the D value
           SET  : in  STD_LOGIC; --set the flag to '1'
           CLR  : in  STD_LOGIC; --clear the flag to '0'
           CLK  : in  STD_LOGIC; --system clock
           Q    : out  STD_LOGIC); --flag output
end FlagReg;

architecture Behavioral of FlagReg is
   signal s_D : STD_LOGIC := '0';  
begin
    process(CLK,LD,SET,CLR,D)
    begin
        if( rising_edge(CLK) ) then
            if( LD = '1' ) then
                s_D <= D;
            elsif( SET = '1' ) then
                s_D <= '1';
            elsif( CLR = '1' ) then
                s_D <= '0';
         end if;
      end if;
    end process;	

    Q <= s_D; 
    
end Behavioral;
