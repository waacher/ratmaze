----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/12/2018 03:07:05 PM
-- Design Name: 
-- Module Name: SP - Behavioral
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SP is
    Port ( RST : in STD_LOGIC;
           LD : in STD_LOGIC;
           INCR : in STD_LOGIC;
           DECR : in STD_LOGIC;
           DATA : in STD_LOGIC_VECTOR (7 downto 0);
           CLK : in STD_LOGIC;
           OUTPUT : out STD_LOGIC_VECTOR (7 downto 0)
           );
end SP;

architecture my_count of SP is 
   signal  t_cnt : std_logic_vector(7 downto 0); 
begin 
         
   process (CLK, RST, LD, INCR, DECR, DATA, t_cnt) 
   begin
     if (rising_edge(CLK)) then
        if (RST = '1') then    
               t_cnt <= (others => '0');
        elsif (LD = '1') then     t_cnt <= DATA;  -- load
        else        
               if (INCR = '1') then  t_cnt <= t_cnt + 1; -- incr
               elsif (DECR = '1') then t_cnt <= t_cnt - 1;
               else t_cnt <= t_cnt;
               end if;
        end if;
     end if;
   end process;

   OUTPUT <= t_cnt; 

end my_count; 
