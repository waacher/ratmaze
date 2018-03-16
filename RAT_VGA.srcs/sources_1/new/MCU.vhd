----------------------------------------------------------------------------------
-- Company: Ratner Engineering
-- Engineer: James Ratner
-- 
-- Create Date:    20:59:29 02/04/2013 
-- Design Name: 
-- Module Name:    RAT_MCU - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Starter MCU file for RAT MCU. 
--
-- Dependencies: 
--
-- Revision: 3.00
-- Revision: 4.00 (08-24-2016): removed support for multibus
-- Revision: 4.01 (11-01-2016): removed PC_TRI reference
-- Revision: 4.02 (11-15-2016): added SCR_DATA_SEL 
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity MCU is
    Port ( IN_PORT  : in  STD_LOGIC_VECTOR (7 downto 0);
           RESET    : in  STD_LOGIC;
           CLK      : in  STD_LOGIC;
           INT      : in  STD_LOGIC;
           OUT_PORT : out  STD_LOGIC_VECTOR (7 downto 0);
           PORT_ID  : out  STD_LOGIC_VECTOR (7 downto 0);
           IO_STRB  : out  STD_LOGIC);
end MCU;

architecture Behavioral of MCU is

   component prog_rom  
      port (     ADDRESS : in std_logic_vector(9 downto 0); 
             INSTRUCTION : out std_logic_vector(17 downto 0); 
                     CLK : in std_logic);  
   end component;

   component ALUwithMux
       Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
              FROM_REG : in STD_LOGIC_VECTOR (7 downto 0);
              FROM_IMMED : in STD_LOGIC_VECTOR (7 downto 0);
              ALU_OPY_SEL : in STD_LOGIC;
              SEL : in STD_LOGIC_VECTOR (3 downto 0);
              Cin : in STD_LOGIC;
              RESULT : out STD_LOGIC_VECTOR (7 downto 0);
              C : out STD_LOGIC;
              Z : out STD_LOGIC);
   end component;
   
   component CONTROL_UNIT 
       Port ( CLK           : in   STD_LOGIC;
              C             : in   STD_LOGIC;
              Z             : in   STD_LOGIC;
              INT           : in   STD_LOGIC;
              RESET         : in   STD_LOGIC; 
              OPCODE_HI_5   : in   STD_LOGIC_VECTOR (4 downto 0);
              OPCODE_LO_2   : in   STD_LOGIC_VECTOR (1 downto 0);
              
              PC_LD         : out  STD_LOGIC;
              PC_INC        : out  STD_LOGIC;
              PC_MUX_SEL    : out  STD_LOGIC_VECTOR (1 downto 0);		  

              SP_LD         : out  STD_LOGIC;
              SP_INCR       : out  STD_LOGIC;
              SP_DECR       : out  STD_LOGIC;
 
              RF_WR         : out  STD_LOGIC;
              RF_WR_SEL     : out  STD_LOGIC_VECTOR (1 downto 0);

              ALU_OPY_SEL   : out  STD_LOGIC;
              ALU_SEL       : out  STD_LOGIC_VECTOR (3 downto 0);

              SCR_WR        : out  STD_LOGIC;
              SCR_ADDR_SEL  : out  STD_LOGIC_VECTOR (1 downto 0);
			  SCR_DATA_SEL  : out  STD_LOGIC; 

              FLG_C_LD      : out  STD_LOGIC;
              FLG_C_SET     : out  STD_LOGIC;
              FLG_C_CLR     : out  STD_LOGIC;
              FLG_SHAD_LD   : out  STD_LOGIC;
              FLG_LD_SEL    : out  STD_LOGIC;
              FLG_Z_LD      : out  STD_LOGIC;
              
              I_FLAG_SET    : out  STD_LOGIC;
              I_FLAG_CLR    : out  STD_LOGIC;

              RST           : out  STD_LOGIC;
              IO_STRB       : out  STD_LOGIC);
   end component;

   component RegisterFile 
       Port ( ALU_IN     : in STD_LOGIC_VECTOR (7 downto 0);
              FROM_STACK : in STD_LOGIC_VECTOR (7 downto 0);
              B_IN       : in STD_LOGIC_VECTOR (7 downto 0);
              IN_PORT    : in STD_LOGIC_VECTOR (7 downto 0); 
              RF_WR_SEL  : in STD_LOGIC_VECTOR (1 downto 0);
              DX_OUT     : out    STD_LOGIC_VECTOR (7 downto 0);
              DY_OUT     : out    STD_LOGIC_VECTOR (7 downto 0);
              ADRX       : in     STD_LOGIC_VECTOR (4 downto 0);
              ADRY       : in     STD_LOGIC_VECTOR (4 downto 0);
              WE         : in     STD_LOGIC;
              CLK        : in     STD_LOGIC);
   end component;

   component PC 
       port ( RST,CLK,PC_LD,PC_INC : in std_logic; 
              FROM_IMMED : in std_logic_vector (9 downto 0); 
              FROM_STACK : in std_logic_vector (9 downto 0); 
              FROM_INTRR : in std_logic_vector (9 downto 0); 
              PC_MUX_SEL : in std_logic_vector (1 downto 0); 
              PC_COUNT   : out std_logic_vector (9 downto 0)); 
   end component; 
   
   component FLAGS is
       Port ( C_IN        : in STD_LOGIC;
              Z_IN        : in STD_LOGIC;
              FLG_C_SET   : in STD_LOGIC;
              FLG_C_CLR   : in STD_LOGIC;
              FLG_C_LD    : in STD_LOGIC;
              FLG_Z_LD    : in STD_LOGIC;
              FLG_LD_SEL  : in STD_LOGIC;
              FLG_SHAD_LD : in STD_LOGIC;
              C_FLAG      : out STD_LOGIC;
              Z_FLAG      : out STD_LOGIC;
              CLK         : in STD_LOGIC);
   end component;
   
   component SCR
       Port ( DATA_IN  : in STD_LOGIC_VECTOR (9 downto 0);
              WE       : in STD_LOGIC;
              ADDR     : in STD_LOGIC_VECTOR (7 downto 0);
              CLK      : in STD_LOGIC;
              DATA_OUT : out STD_LOGIC_VECTOR (9 downto 0));
   end component;

   component SCR_ADDR_MUX
       Port ( D0   : in STD_LOGIC_VECTOR (7 downto 0);
              D1   : in STD_LOGIC_VECTOR (7 downto 0);
              D2   : in STD_LOGIC_VECTOR (7 downto 0);
              D3   : in STD_LOGIC_VECTOR (7 downto 0);
              SEL  : in STD_LOGIC_VECTOR (1 downto 0);
              ADDR : out STD_LOGIC_VECTOR (7 downto 0));
   end component;
    
   component SCR_DIN_MUX is
       Port ( D0           : in STD_LOGIC_VECTOR (7 downto 0);
              D1           : in STD_LOGIC_VECTOR (9 downto 0);
              DATA         : out STD_LOGIC_VECTOR (9 downto 0);
              SCR_DATA_SEL : in STD_LOGIC);
   end component;
   
   component SP is
       Port ( RST : in STD_LOGIC;
              LD : in STD_LOGIC;
              INCR : in STD_LOGIC;
              DECR : in STD_LOGIC;
              DATA : in STD_LOGIC_VECTOR (7 downto 0);
              CLK : in STD_LOGIC;
              OUTPUT : out STD_LOGIC_VECTOR (7 downto 0));
   end component;
   
   component FlagReg is
       Port ( D    : in  STD_LOGIC; --flag input
              LD   : in  STD_LOGIC; --load Q with the D value
              SET  : in  STD_LOGIC; --set the flag to '1'
              CLR  : in  STD_LOGIC; --clear the flag to '0'
              CLK  : in  STD_LOGIC; --system clock
              Q    : out  STD_LOGIC); --flag output
   end component FlagReg;
        

   -- intermediate signals ----------------------------------
   signal s_pc_ld : std_logic := '0'; 
   signal s_pc_inc : std_logic := '0'; 
   signal s_rst : std_logic := '0'; 
   signal s_pc_mux_sel : std_logic_vector(1 downto 0) := "00"; 
   signal s_pc_count : std_logic_vector(9 downto 0) := (others => '0');   
   signal s_inst_reg : std_logic_vector(17 downto 0) := (others => '0'); 
   
   signal s_alu_opy_sel, s_rf_wr : std_logic := '0';
   signal s_alu_sel : std_logic_vector (3 downto 0) := "1110"; -- MOV
   signal alu_res : std_logic_vector (7 downto 0);
   signal alu_cflag_out, alu_zflag_out : std_logic;
   
   signal reg_dx, reg_dy : std_logic_vector (7 downto 0);
   signal s_rf_wr_sel : std_logic_vector (1 downto 0) := "00";
   signal s_from_stack : std_logic_vector (9 downto 0);
   
   signal s_c_flag, s_flg_c_set, s_flg_c_clr, s_flg_c_ld,
          s_z_flag, s_flg_z_ld, s_flg_ld_sel, s_flg_shad_ld : std_logic := '0';
          
   signal s_io_strb : std_logic := '0';
   
   signal s_scr_data_in : std_logic_vector (9 downto 0); 
   signal s_scr_addr : std_logic_vector (7 downto 0);
   signal s_scr_we : std_logic;
   signal s_scr_addr_sel : std_logic_vector (1 downto 0);
   signal s_scr_data_sel : std_logic;
   
   signal s_sp_data_out : std_logic_vector (7 downto 0);
   signal s_sp_data_out_minus_one : std_logic_vector (7 downto 0); 
   signal s_sp_ld, s_sp_incr, s_sp_decr : std_logic;
   
   signal s_i_set, s_i_clr, s_i_out, s_int : std_logic;
   
   -- helpful aliases ------------------------------------------------------------------
   alias s_ir_immed_bits : std_logic_vector(9 downto 0) is s_inst_reg(12 downto 3); 
   alias s_ir_immed_val : std_logic_vector (7 downto 0) is s_inst_reg (7 downto 0);

begin

   my_prog_rom: prog_rom  
   port map(     ADDRESS => s_pc_count, 
             INSTRUCTION => s_inst_reg, 
                     CLK => CLK); 

   my_alu: ALUwithMux
   port map ( A => reg_dx,       
              FROM_REG => reg_dy, 
              FROM_IMMED => s_ir_immed_val (7 downto 0),
              ALU_OPY_SEL => s_alu_opy_sel,      
              Cin => s_c_flag,     
              SEL => s_alu_sel,     
              C => alu_cflag_out,       
              Z => alu_zflag_out,       
              RESULT => alu_res); 

   my_cu: CONTROL_UNIT 
   port map ( CLK           => CLK, 
              C             => s_c_flag, 
              Z             => s_z_flag, 
              INT           => s_int, 
              RESET         => RESET, 
              OPCODE_HI_5   => s_inst_reg (17 downto 13), 
              OPCODE_LO_2   => s_inst_reg (1 downto 0), 
              
              PC_LD         => s_pc_ld, 
              PC_INC        => s_pc_inc,  
              PC_MUX_SEL    => s_pc_mux_sel, 

              SP_LD         => s_sp_ld, 
              SP_INCR       => s_sp_incr, 
              SP_DECR       => s_sp_decr, 

              RF_WR         => s_rf_wr, 
              RF_WR_SEL     => s_rf_wr_sel, 

              ALU_OPY_SEL   => s_alu_opy_sel, 
              ALU_SEL       => s_alu_sel,
			  
              SCR_WR        => s_scr_we, 
              SCR_ADDR_SEL  => s_scr_addr_sel,              
			  SCR_DATA_SEL  => s_scr_data_sel,
			  
              FLG_C_LD      => s_flg_c_ld, 
              FLG_C_SET     => s_flg_c_set, 
              FLG_C_CLR     => s_flg_c_clr, 
              FLG_SHAD_LD   => s_flg_shad_ld, 
              FLG_LD_SEL    => s_flg_ld_sel,
              FLG_Z_LD      => s_flg_z_ld, 
              I_FLAG_SET    => s_i_set, 
              I_FLAG_CLR    => s_i_clr,  

              RST           => s_rst,
              IO_STRB       => s_io_strb);
              

   my_regfile: RegisterFile 
   port map ( ALU_IN => alu_res,
              FROM_STACK => s_from_stack (7 downto 0),
              B_IN => s_sp_data_out,
              IN_PORT => IN_PORT, 
              RF_WR_SEL => s_rf_wr_sel,
              DX_OUT => reg_dx,   
              DY_OUT => reg_dy,   
              ADRX   => s_inst_reg (12 downto 8),   
              ADRY   => s_inst_reg (7 downto 3),     
              WE     => s_rf_wr,   
              CLK    => CLK); 


   my_PC: PC 
   port map ( RST        => s_rst,
              CLK        => CLK,
              PC_LD      => s_pc_ld,
              PC_INC     => s_pc_inc,
              FROM_IMMED => s_ir_immed_bits,
              FROM_STACK => s_from_stack, 
              FROM_INTRR => "1111111111",
              PC_MUX_SEL => s_pc_mux_sel,
              PC_COUNT   => s_pc_count); 
              
   my_flags : FLAGS
   port map ( C_IN => alu_cflag_out,
              Z_IN => alu_zflag_out,
              FLG_C_SET => s_flg_c_set,
              FLG_C_CLR => s_flg_c_clr,
              FLG_C_LD => s_flg_c_ld,
              FLG_Z_LD => s_flg_z_ld,
              FLG_LD_SEL => s_flg_ld_sel,
              FLG_SHAD_LD => s_flg_shad_ld,
              C_FLAG => s_c_flag,
              Z_FLAG => s_z_flag,
              CLK => CLK);
              
   my_scr : SCR
   port map ( DATA_IN => s_scr_data_in,
              WE => s_scr_we,
              ADDR => s_scr_addr,
              CLK => CLK,
              DATA_OUT => s_from_stack);
              
   my_scr_addr_mux : SCR_ADDR_MUX
   port map ( D0 => reg_dy,
              D1 => s_ir_immed_val,
              D2 => s_sp_data_out,
              D3 => s_sp_data_out_minus_one,
              SEL => s_scr_addr_sel,
              ADDR => s_scr_addr);
              
   my_scr_data_mux : SCR_DIN_MUX
   port map ( D0 => reg_dx,
              D1 => s_pc_count,
              SCR_DATA_SEL => s_scr_data_sel,
              DATA => s_scr_data_in); 
              
   my_sp : SP
   port map ( RST => s_rst,
              LD => s_sp_ld,
              INCR => s_sp_incr,
              DECR => s_sp_decr,
              DATA => reg_dx,
              CLK => CLK,
              OUTPUT => s_sp_data_out);
            
   my_i_reg : FlagReg
   port map ( D => '0',
              LD => '0',
              SET => s_i_set,
              CLR => s_i_clr,
              CLK => CLK,
              Q => s_i_out);

    s_sp_data_out_minus_one <= s_sp_data_out - '1';
    s_int <= INT AND s_i_out;

    OUT_PORT <= reg_dx; 
    PORT_ID <= s_ir_immed_val; 
    IO_STRB <= s_io_strb;

end Behavioral;


