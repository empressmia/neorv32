-- #################################################################################################
-- # << NEORV32 - Simple Test Setup >>                                                             #
-- # ********************************************************************************************* #
-- # This test setup instantiates the NEORV32 processor with a rather small configuration and only #
-- # propagates the UART and GPIO.out signals to the outer world.                                  #
-- # Only internal memories are used and the address space for instructions/data is constrained to #
-- # these memories.                                                                               #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_ProcessorTop_Test is
  port (
    -- Global control --
    clk_i       : in  std_ulogic := '0'; -- global clock, rising edge
    rstn_i      : in  std_ulogic := '0'; -- global reset, low-active, async
    -- GPIO --
    gpio_o      : out std_ulogic_vector(7 downto 0); -- parallel output
    -- UART0 --
    uart0_txd_o : out std_ulogic; -- UART0 send data
    uart0_rxd_i : in  std_ulogic := '0' -- UART0 receive data
  );
end entity;

architecture neorv32_ProcessorTop_Test_rtl of neorv32_ProcessorTop_Test is

  -- gpio output --
  signal gpio_out : std_ulogic_vector(31 downto 0);

begin

  -- The Core Of The Problem ----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_top_inst: neorv32_top
  generic map (
    -- General --
    CLOCK_FREQUENCY              => 100000000,   -- clock frequency of clk_i in Hz
    INT_BOOTLOADER_EN            => true,        -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM
    USER_CODE                    => x"00000000", -- custom user code
    HW_THREAD_ID                 => 0,           -- hardware thread id (hartid)
    -- On-Chip Debugger (OCD) --
    ON_CHIP_DEBUGGER_EN          => false,       -- implement on-chip debugger
    -- RISC-V CPU Extensions --
    CPU_EXTENSION_RISCV_A        => false,       -- implement atomic extension?
    CPU_EXTENSION_RISCV_C        => true,        -- implement compressed extension?
    CPU_EXTENSION_RISCV_E        => false,       -- implement embedded RF extension?
    CPU_EXTENSION_RISCV_M        => true,        -- implement muld/div extension?
    CPU_EXTENSION_RISCV_U        => true,        -- implement user mode extension?
    CPU_EXTENSION_RISCV_Zfinx    => false,       -- implement 32-bit floating-point extension (using INT reg!)
    CPU_EXTENSION_RISCV_Zicsr    => true,        -- implement CSR system?
    CPU_EXTENSION_RISCV_Zifencei => false,       -- implement instruction stream sync.?
    -- Extension Options --
    FAST_MUL_EN                  => false,       -- use DSPs for M extension's multiplier
    FAST_SHIFT_EN                => false,       -- use barrel shifter for shift operations
    CPU_CNT_WIDTH                => 64,          -- total width of CPU cycle and instret counters (0..64)
    -- Physical Memory Protection (PMP) --
    PMP_NUM_REGIONS              => 0,           -- number of regions (0..64)
    PMP_MIN_GRANULARITY          => 64*1024,     -- minimal region granularity in bytes, has to be a power of 2, min 8 bytes
    -- Hardware Performance Monitors (HPM) --
    HPM_NUM_CNTS                 => 4,           -- number of implemented HPM counters (0..29)
    HPM_CNT_WIDTH                => 40,          -- total size of HPM counters (0..64)
    -- Internal Instruction memory --
    MEM_INT_IMEM_EN              => true,        -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE            => 16*1024,     -- size of processor-internal instruction memory in bytes
    -- Internal Data memory --
    MEM_INT_DMEM_EN              => true,        -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE            => 8*1024,      -- size of processor-internal data memory in bytes
    -- Internal Cache memory --
    ICACHE_EN                    => false,       -- implement instruction cache
    ICACHE_NUM_BLOCKS            => 4,           -- i-cache: number of blocks (min 1), has to be a power of 2
    ICACHE_BLOCK_SIZE            => 64,          -- i-cache: block size in bytes (min 4), has to be a power of 2
    ICACHE_ASSOCIATIVITY         => 1,           -- i-cache: associativity / number of sets (1=direct_mapped), has to be a power of 2
    -- External memory interface --
    MEM_EXT_EN                   => false,       -- implement external memory bus interface?
    MEM_EXT_TIMEOUT              => 0,           -- cycles after a pending bus access auto-terminates (0 = disabled)
    -- Processor peripherals --
    IO_GPIO_EN                   => true,        -- implement general purpose input/output port unit (GPIO)?
    IO_MTIME_EN                  => true,        -- implement machine system timer (MTIME)?
    IO_UART0_EN                  => true,        -- implement primary universal asynchronous receiver/transmitter (UART0)?
    IO_UART1_EN                  => false,       -- implement secondary universal asynchronous receiver/transmitter (UART1)?
    IO_SPI_EN                    => false,       -- implement serial peripheral interface (SPI)?
    IO_TWI_EN                    => false,       -- implement two-wire interface (TWI)?
    IO_PWM_NUM_CH                => 0,           -- number of PWM channels to implement (0..60); 0 = disabled
    IO_WDT_EN                    => true,        -- implement watch dog timer (WDT)?
    IO_TRNG_EN                   => false,       -- implement true random number generator (TRNG)?
    IO_CFS_EN                    => false,       -- implement custom functions subsystem (CFS)?
    IO_CFS_CONFIG                => x"00000000", -- custom CFS configuration generic
    IO_CFS_IN_SIZE               => 32,          -- size of CFS input conduit in bits
    IO_CFS_OUT_SIZE              => 32,          -- size of CFS output conduit in bits
    IO_NCO_EN                    => false,       -- implement numerically-controlled oscillator (NCO)?
    IO_NEOLED_EN                 => false        -- implement NeoPixel-compatible smart LED interface (NEOLED)?
  )
  port map (
    -- Global control --
    clk_i       => clk_i,           -- global clock, rising edge
    rstn_i      => rstn_i,          -- global reset, low-active, async
    -- JTAG on-chip debugger interface (available if ON_CHIP_DEBUGGER_EN = true) --
    jtag_trst_i => '0',             -- low-active TAP reset (optional)
    jtag_tck_i  => '0',             -- serial clock
    jtag_tdi_i  => '0',             -- serial data input
    jtag_tdo_o  => open,            -- serial data output
    jtag_tms_i  => '0',             -- mode select
    -- Wishbone bus interface (available if MEM_EXT_EN = true) --
    wb_tag_o    => open,            -- tag
    wb_adr_o    => open,            -- address
    wb_dat_i    => (others => '0'), -- read data
    wb_dat_o    => open,            -- write data
    wb_we_o     => open,            -- read/write
    wb_sel_o    => open,            -- byte enable
    wb_stb_o    => open,            -- strobe
    wb_cyc_o    => open,            -- valid cycle
    wb_lock_o   => open,            -- exclusive access request
    wb_ack_i    => '0',             -- transfer acknowledge
    wb_err_i    => '0',             -- transfer error
    -- Advanced memory control signals (available if MEM_EXT_EN = true) --
    fence_o     => open,            -- indicates an executed FENCE operation
    fencei_o    => open,            -- indicates an executed FENCEI operation
    -- GPIO (available if IO_GPIO_EN = true) --
    gpio_o      => gpio_out,        -- parallel output
    gpio_i      => (others => '0'), -- parallel input
    -- primary UART0 (available if IO_UART0_EN = true) --
    uart0_txd_o => uart0_txd_o,     -- UART0 send data
    uart0_rxd_i => uart0_rxd_i,     -- UART0 receive data
    uart0_rts_o => open,            -- hw flow control: UART0.RX ready to receive ("RTR"), low-active, optional
    uart0_cts_i => '0',             -- hw flow control: UART0.TX allowed to transmit, low-active, optional
    -- secondary UART1 (available if IO_UART1_EN = true) --
    uart1_txd_o => open,            -- UART1 send data
    uart1_rxd_i => '0',             -- UART1 receive data
    uart1_rts_o => open,            -- hw flow control: UART1.RX ready to receive ("RTR"), low-active, optional
    uart1_cts_i => '0',             -- hw flow control: UART1.TX allowed to transmit, low-active, optional
    -- SPI (available if IO_SPI_EN = true) --
    spi_sck_o   => open,            -- SPI serial clock
    spi_sdo_o   => open,            -- controller data out, peripheral data in
    spi_sdi_i   => '0',             -- controller data in, peripheral data out
    spi_csn_o   => open,            -- SPI CS
    -- TWI (available if IO_TWI_EN = true) --
    twi_sda_io  => open,            -- twi serial data line
    twi_scl_io  => open,            -- twi serial clock line
    -- PWM (available if IO_PWM_NUM_CH > 0) --
    pwm_o       => open,            -- pwm channels
    -- Custom Functions Subsystem IO --
    cfs_in_i    => (others => '0'), -- custom inputs
    cfs_out_o   => open,            -- custom outputs
    -- NCO output (available if IO_NCO_EN = true) --
    nco_o       => open,            -- numerically-controlled oscillator channels
    -- NeoPixel-compatible smart LED interface (available if IO_NEOLED_EN = true) --
    neoled_o    => open,            -- async serial data line
    -- System time --
    mtime_i     => (others => '0'), -- current system time from ext. MTIME (if IO_MTIME_EN = false)
    mtime_o     => open,            -- current system time from int. MTIME (if IO_MTIME_EN = true)
    -- Interrupts --
    nm_irq_i    => '0',             -- non-maskable interrupt
    soc_firq_i  => (others => '0'), -- fast interrupt channels
    mtime_irq_i => '0',             -- machine timer interrupt, available if IO_MTIME_EN = false
    msw_irq_i   => '0',             -- machine software interrupt
    mext_irq_i  => '0'              -- machine external interrupt
  );

  -- output --
  gpio_o <= gpio_out(7 downto 0);


end architecture;
