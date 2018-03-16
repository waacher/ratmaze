----------------------------------------------------------------------------------
-- Engineer: 
-- 
-- Create Date: 01/25/2018 09:42:16 PM
-- Design Name: 
-- Module Name: InSelMux - Behavioral
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

entity PC is
    Port ( FROM_IMMED : in STD_LOGIC_VECTOR (9 downto 0);
           FROM_STACK : in STD_LOGIC_VECTOR (9 downto 0);
           FROM_INTRR : in STD_LOGIC_VECTOR (9 downto 0);
           PC_MUX_SEL : in STD_LOGIC_VECTOR (1 downto 0);
           
           PC_LD : in STD_LOGIC;
           PC_INC : in STD_LOGIC;
           RST : in STD_LOGIC;
           CLK : in STD_LOGIC;
           
           PC_Count : out STD_LOGIC_VECTOR (9 downto 0));
           
end PC;

architecture Behavioral of PC is

    component ProgramCounter
        Port ( D_IN : in STD_LOGIC_VECTOR (9 downto 0);
               PC_LD : in STD_LOGIC;
               PC_INC : in STD_LOGIC;
               RST : in STD_LOGIC;
               CLK : in STD_LOGIC;
               COUNT : out STD_LOGIC_VECTOR (9 downto 0));
    end component ProgramCounter;

    
    signal Data1 : std_logic_vector (9 downto 0);
    signal LD, INC, RESET, CLK_sig : std_logic;    -- signals for PC
    signal Data_OUT : std_logic_vector (9 downto 0);
    --signal INSTR : std_logic_vector (17 downto 0);

begin
    
    Data1 <= FROM_IMMED when (PC_MUX_SEL = "00") else
             FROM_STACK when (PC_MUX_SEL = "01") else
             FROM_INTRR when (PC_MUX_SEL = "10") else
             FROM_IMMED; 
    
    LD <= PC_LD;
    INC <= PC_INC;
    RESET <= RST;
    CLK_sig <= CLK;
    
    MuxToPC : ProgramCounter port map (D_IN => Data1, 
                                        PC_LD => LD, 
                                        PC_INC => INC, 
                                        RST => RESET, 
                                        CLK => CLK_sig,
                                        COUNT => Data_OUT); 
    
    PC_COUNT <= Data_OUT;
                                        
end Behavioral;
