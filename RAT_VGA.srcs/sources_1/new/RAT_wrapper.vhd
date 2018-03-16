----------------------------------------------------------------------------------
-- Company:  RAT Technologies (a subdivision of Cal Poly CENG)
-- Engineer:  Various RAT rats
--
-- Create Date:    02/03/2017
-- Module Name:    RAT_wrapper - Behavioral
-- Target Devices:  Basys3
-- Description: Wrapper for RAT CPU. This model provides a template to interfaces
--    the RAT CPU to the Basys3 development board and includes connections for
--    the VGA driver
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAT_wrapper is
    Port ( RST      : in    STD_LOGIC;
           CLK      : in    STD_LOGIC;
           BUTTONS  : in    STD_LOGIC_VECTOR (3 downto 0);
           SWITCHES : in    STD_LOGIC_VECTOR (7 downto 0);
           VGA_RGB  : out   STD_LOGIC_VECTOR (7 downto 0);
           VGA_HS   : out   STD_LOGIC;
           VGA_VS   : out   STD_LOGIC;
           LEDS     : out   STD_LOGIC_VECTOR (7 downto 0);
           SEGMENTS : out   STD_LOGIC_VECTOR (7 downto 0);
           DISP_EN  : out   STD_LOGIC_VECTOR (3 downto 0));
end RAT_wrapper;

architecture Behavioral of RAT_wrapper is

   -- INPUT PORT IDS -------------------------------------------------------------
   -- Right now, the only possible inputs are the switches
   -- In future labs you can add more port IDs, and you'll have
   -- to add constants here for the mux below
   CONSTANT VGA_READ_ID    : STD_LOGIC_VECTOR (7 downto 0) := X"93";
   CONSTANT BUTTONS_ID     : STD_LOGIC_VECTOR (7 downto 0) := X"24";
   CONSTANT SWITCHES_LO_ID : STD_LOGIC_VECTOR (7 downto 0) := X"20";
   -------------------------------------------------------------------------------
   
   -------------------------------------------------------------------------------
   -- OUTPUT PORT IDS ------------------------------------------------------------
   -- In future labs you can add more port IDs
   CONSTANT VGA_HADDR_ID  : STD_LOGIC_VECTOR (7 downto 0)   := X"90";
   CONSTANT VGA_LADDR_ID  : STD_LOGIC_VECTOR (7 downto 0)   := X"91";
   CONSTANT VGA_WRITE_ID  : STD_LOGIC_VECTOR (7 downto 0)   := X"92";
   CONSTANT LEDS_LO_ID    : STD_LOGIC_VECTOR (7 downto 0)   := X"40";
   CONSTANT SEGMENTS_ID   : STD_LOGIC_VECTOR (7 downto 0)   := X"81";
   CONSTANT DISP_EN_ID    : STD_LOGIC_VECTOR (7 downto 0)   := X"83";

   -------------------------------------------------------------------------------

   -- Declare RAT_CPU ------------------------------------------------------------
   component MCU
       Port ( IN_PORT  : in  STD_LOGIC_VECTOR (7 downto 0);
              OUT_PORT : out STD_LOGIC_VECTOR (7 downto 0);
              PORT_ID  : out STD_LOGIC_VECTOR (7 downto 0);
              IO_STRB  : out STD_LOGIC;
              RESET    : in  STD_LOGIC;
              INT      : in  STD_LOGIC;
              CLK      : in  STD_LOGIC);
   end component;
   -------------------------------------------------------------------------------
    
   -- Declare VGA driver ---------------------------------------------------------
   component vgaDriverBuffer is
       Port ( CLK   : in std_logic;
              we    : in std_logic;
              wa    : in std_logic_vector (12 downto 0);
              wd    : in std_logic_vector (7 downto 0);
              Rout  : out std_logic_vector (2 downto 0);
              Gout  : out std_logic_vector (2 downto 0);
              Bout  : out std_logic_vector (1 downto 0);
              HS    : out std_logic;
              VS    : out std_logic;
              pixelData : out std_logic_vector (7 downto 0));
   end component;
   -------------------------------------------------------------------------------
   
   component sseg_dec_uni is
          Port (       COUNT1 : in std_logic_vector(13 downto 0); 
                       COUNT2 : in std_logic_vector(7 downto 0);
                          SEL : in std_logic_vector(1 downto 0);
                        dp_oe : in std_logic;
                           dp : in std_logic_vector(1 downto 0);                       
                          CLK : in std_logic;
                         SIGN : in std_logic;
                        VALID : in std_logic;
                      DISP_EN : out std_logic_vector(3 downto 0);
                     SEGMENTS : out std_logic_vector(7 downto 0));
   end component;
   --------------------------------------------------------------------------------
   component db_1shot_FSM is
          Port ( A    : in STD_LOGIC;
                 CLK  : in STD_LOGIC;
                 A_DB : out STD_LOGIC);
   end component;
          
    
   -- Signals for connecting RAT_CPU to RAT_wrapper -------------------------------
   signal s_input_port  : std_logic_vector (7 downto 0);
   signal s_output_port : std_logic_vector (7 downto 0);
   signal s_port_id     : std_logic_vector (7 downto 0);
   signal s_load        : std_logic;
   signal s_clk_50      : std_logic := '0';
   --signal s_interrupt   : std_logic;
   

   -- Signals for vgaDriveBuffer -------------------------------------------------
   signal r_vga_we  : std_logic                         := '0';
   signal r_vga_wa  : std_logic_vector (12 downto 0)    := (others=>'0');
   signal r_vga_wd  : std_logic_vector (7 downto 0)     := (others=>'0');
   signal r_vgaData : std_logic_vector (7 downto 0)     := (others=>'0');
   signal r_drawPlayer : std_logic := '0';
   
   signal r_LEDS_LO    : std_logic_vector (7 downto 0)  := (others => '0'); 
   signal r_SEGMENTS   : std_logic_vector (13 downto 0) := (others => '0');
   signal r_DISP_EN    : std_logic_vector (3 downto 0)  := (others => '0'); 
   
   -- Signals for interrupt buttons
   signal s_int_button, s_db_int : std_logic;
   
begin

    -- Instantiate RAT_CPU --------------------------------------------------------
    CPU: MCU
    port map( IN_PORT  => s_input_port,
              OUT_PORT => s_output_port,
              PORT_ID  => s_port_id,
              RESET    => RST,
              IO_STRB  => s_load,
              INT      => s_db_int,
              CLK      => s_clk_50);
    -------------------------------------------------------------------------------
    
    
    -- Instantiate VGA Controller -------------------------------------------------
    VGA : vgaDriverBuffer
    port map( CLK => s_clk_50,
              WE => r_vga_we,
              WA => r_vga_wa,
              WD => r_vga_wd,
              Rout => VGA_RGB(7 downto 5),
              Gout => VGA_RGB(4 downto 2),
              Bout => VGA_RGB(1 downto 0),
              HS => VGA_HS,
              VS => VGA_VS,
              pixelData => r_vgaData);
    ------------------------------------------------------------------------------
    
    my_sseg : sseg_dec_uni
        port map(    COUNT1 => r_segments,
                     COUNT2 => (others => '0'),
                        SEL => "00",
                      dp_oe => '0',
                         dp => "00",                     
                        CLK => clk,
                       SIGN => '0',
                      VALID => '1',
                    DISP_EN => DISP_EN,
                   SEGMENTS => SEGMENTS);
    
    my_DB : db_1shot_FSM
    port map ( A => s_int_button,
               CLK => s_clk_50,
               A_DB => s_db_int);
   
   -------------------------------------------------------------------------------
   -- Create 50 MHz clock from 100 MHz system clock (Basys3)
   -------------------------------------------------------------------------------
   clk_div: process(CLK)
   begin
      if (rising_edge(CLK)) then
        s_clk_50 <= not s_clk_50;
      end if;
   end process clk_div;
   -------------------------------------------------------------------------------


   -------------------------------------------------------------------------------
   -- MUX for selecting what input to read ---------------------------------------
   -- add conditions and connections for any added PORT IDs
   -------------------------------------------------------------------------------
   inputs: process(s_port_id)
   begin
      if (s_port_id = VGA_READ_ID) then
         s_input_port <= r_vgaData;
      elsif (s_port_id = BUTTONS_ID) then 
         s_input_port <= "0000" & BUTTONS;
      elsif (s_port_id = SWITCHES_LO_ID) then
         s_input_port <= SWITCHES(7 downto 0);
      else
         s_input_port <= x"00";
      end if;
   end process inputs;
   -------------------------------------------------------------------------------


   -------------------------------------------------------------------------------
   -- MUX for updating output registers ------------------------------------------
   -- Register updates depend on rising clock edge and asserted load signal
   -- add conditions and connections for any added PORT IDs
   -------------------------------------------------------------------------------
   outputs: process(s_clk_50)
   begin
      if (rising_edge(s_clk_50)) then
         if (s_load = '1') then
            if (s_port_id = LEDS_LO_ID) then
                r_LEDS_LO <= s_output_port;
            elsif (s_port_id = VGA_HADDR_ID) then
                r_vga_wa(12 downto 8) <= s_output_port(4 downto 0);
            elsif (s_port_id = VGA_LADDR_ID) then
                r_vga_wa(7 downto 0) <= s_output_port(7 downto 0);
            elsif (s_port_id = VGA_WRITE_ID) then
                r_vga_wd <= s_output_port;
            elsif (s_port_id = SEGMENTS_ID) then
                r_SEGMENTS <= "000000" & s_output_port;
            elsif (s_port_id = DISP_EN_ID) then
                r_DISP_EN <= s_output_port(3 downto 0);
            end if;
            
            if (s_port_id = VGA_WRITE_ID) then
                r_vga_we <= '1';
            else
                r_vga_we <= '0';
                           
            end if;
           
         end if;
      end if;
   end process outputs;
   -------------------------------------------------------------------------------

   -- Register Interface Assignments ---------------------------------------------
   -- add all outputs that you added to this design
   
   LEDS(7 downto 0) <= r_LEDS_LO;
   
   s_int_button <= SWITCHES(0) OR SWITCHES(1) OR SWITCHES(2) OR SWITCHES(3) OR SWITCHES(4) OR SWITCHES(5) OR SWITCHES(6) OR SWITCHES(7); 

end Behavioral;
