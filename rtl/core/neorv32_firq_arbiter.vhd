library ieee;
use ieee.std_logic_1164.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_firq_arbiter is
  generic (
    FIRQ_ARBITER_EN : boolean := false;
    WR_PROT_EN      : boolean := true 
  );
  port (
    clk_i           : in  std_ulogic;
    rstn_i          : in  std_ulogic;
    bus_req_i       : in  bus_req_t;
    bus_rsp_o       : out bus_rsp_t;
    irq_i           : in  std_ulogic_vector(15 downto 0);
    firq_o          : out std_ulogic_vector(15 downto 0)
  );
end entity neorv32_firq_arbiter;

architecture neorv32_firq_arbiter_rtl of neorv32_firq_arbiter is

  type firq_enum_t is (
    FIRQ_TRNG, FIRQ_UART0_RX, FIRQ_UART0_TX, FIRQ_UART1_RX, FIRQ_UART1_TX, FIRQ_SPI, FIRQ_SDI, FIRQ_TWI,
    FIRQ_CFS, FIRQ_NEOLED, FIRQ_XIRQ, FIRQ_GPTMR, FIRQ_ONEWIRE, FIRQ_DMA, FIRQ_SLINK_RX, FIRQ_SLINK_TX,
    FIRQ_GPIO
  );
  type firq_t is array(firq_enum_t) of std_ulogic;
  signal firq : firq_t;

  type channel_num_t is array(0 to 15) of std_ulogic_vector(log2_ceil(firq_enum_t) - 1 dwonto 0);
 
  type ctrl_t is record
    wr_prot_en           : std_ulogic;
    default_en           : std_ulogic;
    firq_channel_en_mask : std_ulogic_vector(15 downto 0);
  end record ctrl_t;
  signal ctrl : ctrl_t;

begin
  
  lGenNoArbiter: if not(FIRQ_ARBITER_EN) generate
    firq_o(0)  <= firq(FIRQ_TRNG);
    firq_o(1)  <= firq(FIRQ_CFS);
    firq_o(2)  <= firq(FIRQ_UART0_RX);
    firq_o(3)  <= firq(FIRQ_UART0_TX);
    firq_o(4)  <= firq(FIRQ_UART1_RX);
    firq_o(5)  <= firq(FIRQ_UART1_TX);
    firq_o(6)  <= firq(FIRQ_SPI);
    firq_o(7)  <= firq(FIRQ_TWI);
    firq_o(8)  <= firq(FIRQ_XIRQ);
    firq_o(9)  <= firq(FIRQ_NEOLED);
    firq_o(10) <= firq(FIRQ_DMA);
    firq_o(11) <= firq(FIRQ_SDI);
    firq_o(12) <= firq(FIRQ_GPTMR);
    firq_o(13) <= firq(FIRQ_ONEWIRE);
    firq_o(14) <= firq(FIRQ_SLINK_RX);
    firq_o(15) <= firq(FIRQ_SLINK_TX);
  end generate lGenNoArbiter;

  lGenArbiter: if FIRQ_ARBITER_EN generate

  end generate lGenArbiter;

end architecture neorv32_firq_arbiter_rtl;

