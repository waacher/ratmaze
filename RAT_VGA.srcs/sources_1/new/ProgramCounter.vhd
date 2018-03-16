----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/25/2018 09:12:31 PM
-- Design Name: 
-- Module Name: ProgramCounter - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity ProgramCounter is
    Port ( D_IN : in STD_LOGIC_VECTOR (9 downto 0);
           PC_LD : in STD_LOGIC;
           PC_INC : in STD_LOGIC;
           RST : in STD_LOGIC;
           CLK : in STD_LOGIC;
           COUNT : out STD_LOGIC_VECTOR (9 downto 0));
end ProgramCounter;

architecture Behavioral of ProgramCounter is 

    signal  t_cnt : std_logic_vector(9 downto 0); 
    
begin 
         
   process (CLK, RST, PC_LD, t_cnt) 
   begin
      if (rising_edge(CLK)) then
         if (RST = '1') then    
            t_cnt <= (others => '0'); -- sync clear
         else
            if (PC_LD = '1') then     
                t_cnt <= D_IN;  -- load
            
            elsif (PC_INC = '1') then  
                t_cnt <= t_cnt + 1; -- incr
            end if;   
         end if;
      end if;
   end process;

   COUNT <= t_cnt; 

end Behavioral; 