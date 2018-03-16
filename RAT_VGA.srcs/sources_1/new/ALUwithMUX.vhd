----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/08/2018 12:35:10 AM
-- Design Name: 
-- Module Name: ALUwithMUX - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

entity ALUwithMUX is
    Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           FROM_REG : in STD_LOGIC_VECTOR (7 downto 0);
           FROM_IMMED : in STD_LOGIC_VECTOR (7 downto 0);
           ALU_OPY_SEL : in STD_LOGIC;
           SEL : in STD_LOGIC_VECTOR (3 downto 0);
           Cin : in STD_LOGIC;
           RESULT : out STD_LOGIC_VECTOR (7 downto 0);
           C : out STD_LOGIC;
           Z : out STD_LOGIC);
end ALUwithMUX;

architecture Behavioral of ALUwithMUX is

    component ALU
    Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           SEL : in STD_LOGIC_VECTOR (3 downto 0);
           Cin : in STD_LOGIC;
           RESULT : out STD_LOGIC_VECTOR (7 downto 0);
           C : out STD_LOGIC;
           Z : out STD_LOGIC);
    end component ALU;
    
    signal A_sig, B_sig, res_sig : std_logic_vector (7 downto 0);
    signal Cin_sig, C_sig, Z_sig : std_logic;
    signal sel_sig : std_logic_vector (3 downto 0);

begin

    A_sig <= A; Cin_sig <= Cin; sel_sig <= SEL; 
    
    B_sig <= FROM_REG when (ALU_OPY_SEL = '0') else
             FROM_IMMED when (ALU_OPY_SEL = '1') else
             "00000000";   
    
    MuxToALU : ALU port map (A => A_sig, B => B_sig, SEL => sel_sig, Cin => Cin_sig, 
                             RESULT => RESULT, C => C, Z => Z); 
                             
--    RESULT <= res_sig; 
--    C <= C_sig;
--    Z <= Z_sig;

end Behavioral;
