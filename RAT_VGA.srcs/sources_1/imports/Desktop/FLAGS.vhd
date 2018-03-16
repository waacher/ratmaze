----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/07/2018 07:37:51 PM
-- Design Name: 
-- Module Name: FLAGS - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FLAGS is
    Port ( C_IN : in STD_LOGIC;
           Z_IN : in STD_LOGIC;
           FLG_C_SET : in STD_LOGIC;
           FLG_C_CLR : in STD_LOGIC;
           FLG_C_LD : in STD_LOGIC;
           FLG_Z_LD : in STD_LOGIC;
           FLG_LD_SEL : in STD_LOGIC;
           FLG_SHAD_LD : in STD_LOGIC;
           C_FLAG : out STD_LOGIC;
           Z_FLAG : out STD_LOGIC;
           CLK : in STD_LOGIC);
end FLAGS;

architecture Behavioral of FLAGS is

component FlagReg is
    Port ( D    : in  STD_LOGIC; --flag input
           LD   : in  STD_LOGIC; --load Q with the D value
           SET  : in  STD_LOGIC; --set the flag to '1'
           CLR  : in  STD_LOGIC; --clear the flag to '0'
           CLK  : in  STD_LOGIC; --system clock
           Q    : out  STD_LOGIC); --flag output
end component FlagReg;

component mux2to1 is
    port(   d0,d1 : in std_logic;
            sel : in std_logic;
            Q : out std_logic);
end component mux2to1;


signal Z_OUT, SHAD_Z_OUT, C_OUT, SHAD_C_OUT, C_MUX_OUT, Z_MUX_OUT : STD_LOGIC := '0';

begin

    Z_REG : FLAGREG
        port map(   D => Z_MUX_OUT,
                    LD => FLG_Z_LD,
                    SET => '0',
                    CLR => '0',
                    CLK => CLK,
                    Q => Z_OUT);
                    
    C_REG : FLAGREG
        port map(   D => C_MUX_OUT,
                    LD => FLG_C_LD,
                    SET => FLG_C_SET,
                    CLR => FLG_C_CLR,
                    CLK => CLK,
                    Q => C_OUT);
                    
    SHAD_Z_REG : FLAGREG
        port map(   D => Z_OUT,
                    LD => FLG_SHAD_LD,
                    CLK => CLK,
                    Q => SHAD_Z_OUT,
                    SET => '0',
                    CLR => '0');

    SHAD_C_REG : FLAGREG
        port map(   D => C_OUT,
                    LD => FLG_SHAD_LD,
                    CLK => CLK,
                    Q => SHAD_C_OUT,
                    SET => '0',
                    CLR => '0');
                    
    Z_MUX : MUX2TO1
        port map(   d0 => Z_IN,
                    d1 => Z_OUT,
                    SEL => FLG_LD_SEL,
                    Q => Z_MUX_OUT);
                    
    C_MUX : MUX2TO1
         port map(  d0 => C_IN,
                    d1 => C_OUT,
                    SEL => FLG_LD_SEL,
                    Q => C_MUX_OUT);
                    
    Z_FLAG <= Z_OUT;
    C_FLAG <= C_OUT;

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2to1 is
    port(   d0,d1 : in std_logic;
            sel : in std_logic;
            Q : out std_logic);
end mux2to1;

architecture mux of mux2to1 is
begin

with sel select
    Q <= d0 when '0',
         d1 when others;

end mux;

