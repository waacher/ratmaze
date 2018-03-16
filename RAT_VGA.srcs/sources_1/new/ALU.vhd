library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ALU is
    Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           SEL : in STD_LOGIC_VECTOR (3 downto 0);
           Cin : in STD_LOGIC;
           RESULT : out STD_LOGIC_VECTOR (7 downto 0);
           C : out STD_LOGIC;
           Z : out STD_LOGIC);
end ALU;

architecture Behavioral of ALU is

begin
proc1: process(A,B,SEL,Cin)
    variable result_temp : std_logic_vector(8 downto 0);
    variable shift : std_logic;
    variable b_shift : std_logic_vector(7 downto 0);
    variable shift_temp : std_logic_vector(7 downto 0);
    variable b_val : integer := 0; 
begin
    shift := '0';
    result_temp := "000000000";
    C <= '0';
    Z <= '0';
    RESULT <= "00000000";
    b_shift := "00000000";
    shift_temp := "00000000";
    
    case SEL is
        when "0000" => result_temp := ('0' & A) + ('0' & B);        -- ADD
            C <= result_temp(8);

        when "0001" => result_temp := ('0' & A) + ('0' & B) + Cin;  -- ADDC
            C <= result_temp(8);

        when "0010" => result_temp := ('0' & A) - ('0' & B);             -- SUB
            C <= result_temp(8);

        when "0011" => result_temp := ('0' & A) - ('0' & B) - Cin;      -- SUBC
            C <= result_temp(8);

        when "0100" => result_temp := ('0' & A) - ('0' & B);             -- CMP       
            
            if (A < B) then C <= '1';
            else
                C <= '0';
            end if;
            
-- LOGIC
            
        when "0101" =>                          -- AND                              
            result_temp :=  '0' & (A AND B);  
            C <= '0';

        when "0110" =>                          -- OR
            result_temp :=  '0' & (A OR B); 
            C <= '0';

        when "0111" =>                      -- EXOR
            result_temp :=  '0' & (A XOR B); 
            C <= '0';
            
        when "1000" =>                      --TEST
            result_temp := '0' & (A AND B);
            C <= '0';        

        when "1001" =>                     -- LSL
            shift := A(7);
            result_temp := '0' & A(6 downto 0) & Cin;
            C <= shift; 
            
        when "1010" =>                  -- LSR
            shift := A(0);
            result_temp := '0' & Cin & A(7 downto 1);            
            C <= shift;
            
        when "1011" =>                 -- ROL
            shift := A(7);
            result_temp := '0' & A(6 downto 0) & shift;
            C <= shift; 
            
        when "1100" =>                 -- ROR
            shift := A(0);
            result_temp := '0' & shift & A(7 downto 1);
            C <= shift;

        when "1101" =>                -- ASR
            C <= A(0);
            result_temp := '0' & A(7) & A(7 downto 1);
            
        when "1110" =>          -- MOV
            result_temp := '0' & B;
        
        when "1111" =>          --barrel shift
            if (B > "00001000") then 
                C <= '1';
            else C <= '0';
            b_shift := B;
            shift_temp := A;
            b_val := to_integer(unsigned(b_shift));
                if (Cin = '1') then --left shift
                 for i in 0 to 8 loop
                    exit when i = b_val;
                    shift_temp := shift_temp(6 downto 0) & '0';
                  end loop;  
                else                --right shift
                  for i in 0 to 8 loop
                    exit when i = b_val;
                    shift_temp := '0' & shift_temp(7 downto 1);
                  end loop;
                end if; 
            result_temp := '0' & shift_temp;  
       
        end if;
        
        when others =>          -- not used
            result_temp := '0'& A;
      
    end case;
    
    if (result_temp(7 downto 0) = "00000000") then
        Z <= '1';
    else Z <= '0';
    end if; 
           
    RESULT <= result_temp(7 downto 0);  
    
end process proc1;
end Behavioral;

--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

--entity ALU is
--    Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
--           B : in STD_LOGIC_VECTOR (7 downto 0);
--           SEL : in STD_LOGIC_VECTOR (3 downto 0);
--           Cin : in STD_LOGIC;
--           RESULT : out STD_LOGIC_VECTOR (7 downto 0);
--           C : out STD_LOGIC;
--           Z : out STD_LOGIC);
--end ALU;

--architecture Behavioral of ALU is
    
--begin
    
--    logic: process(A, B, SEL, Cin)
--        variable temp : STD_LOGIC_VECTOR (8 downto 0);
--        variable temp_s : STD_LOGIC_VECTOR (7 downto 0);
--        variable shift : integer;
--    begin
        
--        -- initializing outputs to prevent latches
--        RESULT <= B;
--        C <= '0';
--        Z <= '0';
        
--        case SEL is
        
--        when "0000" => -- ADD; add A and B
--            temp := ('0' & A) + ('0' & B);
--            RESULT <= temp (7 downto 0);
--            C <= temp (8);
--            if temp (7 downto 0) = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "0001" => -- ADDC; add A, B, and Carry
--            temp := ('0' & A) + ('0' & B) + Cin;
--            RESULT <= temp (7 downto 0);
--            C <= temp (8);
--            if temp (7 downto 0) = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "0010" => -- SUB; subtract B from A
--            temp := ('0' & A) - ('0' & B);
--            RESULT <= temp (7 downto 0);
--            C <= temp (8);
--            if temp (7 downto 0) = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "0011" => -- SUBC; subtract B and C from A
--            temp := ('0' & A) - ('0' & B) - Cin;
--            RESULT <= temp (7 downto 0);
--            C <= temp (8);
--            if temp (7 downto 0) = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "0100" => -- CMP; subtract B from A and set carry if MSB is underflow
--            temp := ('0' & A) - ('0' & B);
--            RESULT <= temp (7 downto 0);
--            C <= temp (8);
--            if temp (7 downto 0) = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "0101" => -- AND; bitwise AND A, B
--            RESULT <= A and B;
--            C <= '0';
--            if (A and B) = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "0110" => -- OR; bitwise OR A, B
--            RESULT <= A or B;
--            C <= '0';
--            if (A or B) = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "0111" => -- EXOR; bitwise EXOR A, B
--            RESULT <= A xor B;
--            C <= '0';
--            if (A xor B) = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "1000" => -- TEST; bitwise AND A, B, result not written
--            RESULT <= x"00";
--            C <= '0';
--            if (A and B) = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "1001" => -- LSL; logical shift left
--            if B (2) = '0' then
--                temp_s := A (6 downto 0) & Cin;
--                RESULT <= temp_s;
--                C <= A (7);
--            else
--                if B (6) = '1' then
--                    if B (5 downto 3) = x"00" then
--                        temp_s := x"00";
--                        C <= '0';
--                    else
--                        temp_s := A;
--                        C <= '1';
--                    end if;
--                    RESULT <= temp_s;
--                else
--                    shift := to_integer(unsigned(B (5 downto 3)));
--                    temp_s := A;
--                    for I in 0 to 8 loop
--                       temp_s := temp_s (6 downto 0) & '0';
--                       exit when I = shift - 1;
--                    end loop;
--                    RESULT <= temp_s;
--                    C <= '0';
--                end if;
--            end if;
--            if temp_s = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "1010" => -- LSR; logical shift right
--            if B (2) = '0' then
--                temp_s := Cin & A (7 downto 1);
--                RESULT <= temp_s;
--                C <= A (0);
--                if temp_s = x"00" then
--                    Z <= '1';
--                else
--                    Z <= '0';
--                end if;
--            else
--                if B (6) = '1' then
--                    if B (5 downto 3) = x"00" then
--                        temp_s := x"00";
--                        C <= '0';
--                    else
--                        temp_s := A;
--                        C <= '1';
--                    end if;
--                RESULT <= temp_s;
--                else
--                    shift := to_integer(unsigned(B (5 downto 3)));
--                    temp_s := A;
--                    for I in 0 to 8 loop
--                        temp_s := '0' & temp_s (7 downto 1);
--                        exit when I = shift - 1;
--                    end loop;
--                    RESULT <= temp_s;
--                    C <= '0';
--                end if;
--            end if;
--            if temp_s = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "1011" => -- ROL; rotate left
--            temp_s := A (6 downto 0) & A (7);
--            RESULT <= temp_s;
--            C <= A (7);
--            if temp_s = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "1100" => -- ROR; rotate right
--            temp_s := A (0) & A (7 downto 1);
--            RESULT <= temp_s;
--            C <= A (0);
--            if temp_s = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "1101" => -- ASR; arithmetic shift right
--            temp_s := A (7) & A (7) & A (6 downto 1);
--            RESULT <= temp_s;
--            C <= A (0);
--            if temp_s = x"00" then
--                Z <= '1';
--            else
--                Z <= '0';
--            end if;
--        when "1110" => -- MOV; copy data from source register into destination register
--            RESULT <= B;
--        when others => 
--            RESULT <= x"11";
--            C <= '0';
--            Z <= '0';
--         end case;
--     end process;
        
--end Behavioral;
