
--=======================================================================
-- Filename:    ad9910_spi.vhd
--
-- Simulate the SPI bus interface registers of a AD9910 DDS chip.
-- It has two phases: The first phase receives the instruction/address
-- The second phase sends or receives 2,4, or 8 bytes of data
--
--=======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity AD9910_SPI is
  port(
    SCLK      : in  std_logic;   -- serial clock
    MOSI      : in  std_logic;   -- serial data out
    MISO      : out std_logic;   -- serial data in

    CFR1      : out std_logic_vector(31 downto 0);
    CFR2      : out std_logic_vector(31 downto 0);
    CFR3      : out std_logic_vector(31 downto 0);
    AUX_DCTL  : out std_logic_vector(31 downto 0);
    UPD_RATE  : out std_logic_vector(31 downto 0);
    FTW       : out std_logic_vector(31 downto 0);
    POW       : out std_logic_vector(15 downto 0);
    ASF       : out std_logic_vector(31 downto 0);
    MC_SYNC   : out std_logic_vector(31 downto 0);
    DR_LIMIT  : out std_logic_vector(63 downto 0);
    DR_STEP   : out std_logic_vector(63 downto 0);
    DR_RATE   : out std_logic_vector(31 downto 0);
    ST_PROF0  : out std_logic_vector(63 downto 0);
    RM_PROF0  : out std_logic_vector(63 downto 0);
    ST_PROF1  : out std_logic_vector(63 downto 0);
    RM_PROF1  : out std_logic_vector(63 downto 0);
    ST_PROF2  : out std_logic_vector(63 downto 0);
    RM_PROF2  : out std_logic_vector(63 downto 0);
    ST_PROF3  : out std_logic_vector(63 downto 0);
    RM_PROF3  : out std_logic_vector(63 downto 0);

    IO_UPDATE : in  std_logic;   -- update registers
    RESET_N   : in  std_logic    -- system reset
  );
end entity AD9910_SPI;


architecture behavioral of AD9910_SPI is

    --================================================================
    -- Types, component, and signal definitions
    --================================================================

    -- state machine states
    type  STATE_TYPE is (IDLE, S1, S2, S3);

    signal STATE      : STATE_TYPE;  -- for state machine
    signal NEXT_STATE : STATE_TYPE;  -- for state machine

    signal INIT_COUNT : unsigned(5 downto 0);
    signal COUNT      : unsigned(5 downto 0);
    signal LOAD_COUNT : std_logic;
    signal DECR_COUNT : std_logic;

    signal CLR_DREG   : std_logic;
    signal LOAD_ADDR  : std_logic;
    signal REG_ADDR   : std_logic_vector( 4 downto 0);
    signal REG_SIZE   : std_logic_vector( 1 downto 0);
    signal AREG       : std_logic_vector( 7 downto 0);
    signal DREG       : std_logic_vector(63 downto 0);
    signal SHIFT_AR   : std_logic;
    signal SHIFT_DR   : std_logic;

    --================================================================
    -- End of types, component, and signal definition section
    --================================================================

begin

    --================================================================
    -- Start of the behavioral description
    --================================================================

    --================================================
    -- Bit Counter
    --================================================
    BIT_COUNTER:
    process(SCLK, RESET_N)
    begin
        if (SCLK = '1' and SCLK'event) then
            if (DECR_COUNT = '1') then
                COUNT <= COUNT - 1;
            end if;
            if (LOAD_COUNT = '1') then
                COUNT <= INIT_COUNT;
            end if;
        end if;
        -- reset state
        if (RESET_N = '0') then
            COUNT <= (others => '0');
        end if;
    end process;

    --================================================
    -- Address Register
    --================================================
    ADDR_REGISTER:
    process(SCLK, RESET_N)
    begin
        if (SCLK = '1' and SCLK'event) then
            if (LOAD_ADDR = '1') then
                REG_ADDR <= AREG(4 downto 0);
            end if;
        end if;
        -- reset state
        if (RESET_N = '0') then
            REG_ADDR <= (others => '0');
        end if;
    end process;


    --================================================
    -- DDS Register
    --================================================
    DDS_REGISTERS:
    process(IO_UPDATE, RESET_N)
    begin
        if (IO_UPDATE = '1' and IO_UPDATE'event) then
            case REG_ADDR is
            when "00000" =>
                CFR1 <= DREG(31 downto 0); -- 4 bytes
            when "00001" =>
                CFR2 <= DREG(31 downto 0); -- 4 bytes
            when "00010" =>
                CFR3 <= DREG(31 downto 0); -- 4 bytes
            when "00011" =>
                AUX_DCTL <= DREG(31 downto 0); -- 4 bytes
            when "00100" =>
                UPD_RATE <= DREG(31 downto 0); -- 4 bytes
            when "00111" =>
                FTW      <= DREG(31 downto 0); -- 4 bytes
            when "01000" =>
                POW      <= DREG(15 downto 0); -- 2 bytes
            when "01001" =>
                ASF      <= DREG(31 downto 0); -- 4 bytes
            when "01010" =>
                MC_SYNC  <= DREG(31 downto 0); -- 4 bytes
            when "01011" =>
                DR_LIMIT <= DREG(63 downto 0); -- 8 bytes
            when "01100" =>
                DR_STEP  <= DREG(63 downto 0); -- 8 bytes
            when "01101" =>
                DR_RATE  <= DREG(31 downto 0); -- 4 bytes
            when "01110" =>
                ST_PROF0 <= DREG(63 downto 0); -- 8 bytes
            when "01111" =>
                RM_PROF0 <= DREG(63 downto 0); -- 8 bytes
            when "10000" =>
                ST_PROF1 <= DREG(63 downto 0); -- 8 bytes
            when "10001" =>
                RM_PROF1 <= DREG(63 downto 0); -- 8 bytes
            when "10010" =>
                ST_PROF2 <= DREG(63 downto 0); -- 8 bytes
            when "10011" =>
                RM_PROF2 <= DREG(63 downto 0); -- 8 bytes
            when "10100" =>
                ST_PROF3 <= DREG(63 downto 0); -- 8 bytes
            when "10101" =>
                RM_PROF3 <= DREG(63 downto 0); -- 8 bytes

            when others  =>
            end case;
        end if;
        -- reset state
        if (RESET_N = '0') then
            CFR1     <= (others => '0');
            CFR2     <= (others => '0');
            CFR3     <= (others => '0');
            AUX_DCTL <= (others => '0');
            UPD_RATE <= (others => '0');
            FTW      <= (others => '0');
            POW      <= (others => '0');
            ASF      <= (others => '0');
            MC_SYNC  <= (others => '0');
            DR_LIMIT <= (others => '0');
            DR_STEP  <= (others => '0');
            DR_RATE  <= (others => '0');
            ST_PROF0 <= (others => '0');
            RM_PROF0 <= (others => '0');
            ST_PROF1 <= (others => '0');
            RM_PROF1 <= (others => '0');
            ST_PROF2 <= (others => '0');
            RM_PROF2 <= (others => '0');
            ST_PROF3 <= (others => '0');
            RM_PROF3 <= (others => '0');
       end if;
    end process;

    --================================================
    -- AD9910 Register Sizes (in bytes)
    --================================================
    DDS_REGISTER_SIZES:
    process (REG_ADDR)
    begin
        case REG_ADDR is
        when "00000"  =>
            REG_SIZE <= "10"; -- 4 bytes
        when "00001"  =>
            REG_SIZE <= "10"; -- 4 bytes
        when "00010"  =>
            REG_SIZE <= "10"; -- 4 bytes
        when "00011"  =>
            REG_SIZE <= "10"; -- 4 bytes
        when "00100"  =>
            REG_SIZE <= "10"; -- 4 bytes
        when "00101"  =>
            REG_SIZE <= "00"; -- 0 bytes (not used)
        when "00110"  =>
            REG_SIZE <= "00"; -- 0 bytes (not used)
        when "00111"  =>
            REG_SIZE <= "10"; -- 4 bytes
        when "01000"  =>
            REG_SIZE <= "01"; -- 2 bytes
        when "01001"  =>
            REG_SIZE <= "10"; -- 4 bytes
        when "01010"  =>
            REG_SIZE <= "10"; -- 4 bytes
        when "01011"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when "01100"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when "01101"  =>
            REG_SIZE <= "10"; -- 4 bytes
        when "01110"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when "01111"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when "10000"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when "10001"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when "10010"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when "10011"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when "10100"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when "10101"  =>
            REG_SIZE <= "11"; -- 8 bytes
        when others =>
            REG_SIZE <= "00"; -- 0 bytes
        end case;
    end process;

    --================================================
    -- SPI Address Shift Register
    --================================================
    SPI_ADDR_SHIFT_REGISTER:
    process(SCLK, RESET_N)
    begin
        if (SCLK = '1' and SCLK'event) then
            if (SHIFT_AR = '1') then
                AREG <= AREG(6 downto 0) & MOSI;
            end if;
        end if;
        -- reset state
        if (RESET_N = '0') then
            AREG <= (others => '0');
        end if;
    end process;

    --================================================
    -- SPIData Shift Register
    --================================================
    SPI_DATA_SHIFT_REGISTER:
    process(SCLK, RESET_N)
    begin
        if (SCLK = '1' and SCLK'event) then
            if (SHIFT_DR = '1') then
                DREG <= DREG(62 downto 0) & MOSI;
            end if;
        end if;
        -- reset state
        if ((RESET_N = '0') or (CLR_DREG = '1')) then
            DREG <= (others => '0');
        end if;
    end process;

    --================================================
    -- FSM State
    --================================================
    FSM_STATE:
    process(SCLK, RESET_N, IO_UPDATE)
    begin
        if (SCLK = '1' and SCLK'event) then
            STATE <= NEXT_STATE;
        end if;
        -- reset state
        if ((RESET_N = '0') or (IO_UPDATE = '1')) then
            STATE <= IDLE;
        end if;
    end process;

    --================================================
    -- FSM next-state generation
    --================================================
    FSM_NEXT_STATE_GENERATION:
    process(STATE, COUNT, REG_SIZE)
    begin

        CLR_DREG   <= '0';
        LOAD_ADDR  <= '0';
        SHIFT_AR   <= '0';
        SHIFT_DR   <= '0';
        LOAD_COUNT <= '0';
        DECR_COUNT <= '0';
        INIT_COUNT <= (others => '0');

        case STATE is

        --============================================
        -- Idle state
        --============================================
        when IDLE =>
            INIT_COUNT <= "000111"; -- 1 byte
            LOAD_COUNT <= '1';
            CLR_DREG   <= '1';
            SHIFT_AR   <= '1';
            NEXT_STATE <= S1;

        --============================================
        -- Get the instruction/address
        --============================================
        when S1 =>
            SHIFT_AR <= '1';
            DECR_COUNT <= '1';
            NEXT_STATE <= S1;
            if (COUNT = "0000000") then
                LOAD_ADDR  <= '1';
                NEXT_STATE <= S2;
            end if;

        --============================================
        -- Load the byte counter
        --============================================
        when S2 =>
            SHIFT_DR   <= '1';
            NEXT_STATE <= S3;
            LOAD_COUNT <= '1';
            case REG_SIZE is
            when "01"  =>
                INIT_COUNT <= "001110"; -- 2 bytes
            when "10"  =>
                INIT_COUNT <= "011110"; -- 4 bytes
            when "11"  =>
                INIT_COUNT <= "111110"; -- 8 bytes
            when others  =>
        end case;

        --============================================
        -- Get the data
        --============================================
        when S3 =>
            SHIFT_DR <= '1';
            DECR_COUNT <= '1';
            NEXT_STATE <= S3;
            if (COUNT = "0000000") then
                NEXT_STATE <= IDLE;
            end if;

        when others =>
            NEXT_STATE <= IDLE;

        end case;
    end process;

end architecture behavioral;

