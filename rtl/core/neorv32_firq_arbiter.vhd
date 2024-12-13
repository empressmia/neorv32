-- ================================================================================ --
-- NEORV32 SoC - Processor Top Entity                                               --
-- -------------------------------------------------------------------------------- --
-- HQ:           https://github.com/stnolting/neorv32                               --
-- Data Sheet:   https://stnolting.github.io/neorv32                                --
-- User Guide:   https://stnolting.github.io/neorv32/ug                             --
-- Software Ref: https://stnolting.github.io/neorv32/sw/files.html                  --
-- -------------------------------------------------------------------------------- --
-- The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              --
-- Copyright (c) NEORV32 contributors.                                              --
-- Copyright (c) 2020 - 2024 Stephan Nolting. All rights reserved.                  --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --
-- brief: assign peripherals interrupt signals to fast irq (firq) channels of the cpu
-- entity can be disabled completly by generics
-- assignment of interrupt channels to firq channels is done via sw when initializing
-- interrupts

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_firq_arbiter is
  generic (
    FIRQ_ARBITER_EN : boolean := false;
    ALL_CHANNEL_EN  : boolean := true;
    DEFAULT_EN      : boolean := true;
    ALL_WR_PROT_EN  : boolean := true 
  );
  port (
    clk_i           : in  std_ulogic;
    rstn_i          : in  std_ulogic;
    bus_req_i       : in  bus_req_t;
    bus_rsp_o       : out bus_rsp_t;
    irq_i           : in  firq_t;
    firq_o          : out std_ulogic_vector(15 downto 0)
  );
end entity neorv32_firq_arbiter;

architecture neorv32_firq_arbiter_rtl of neorv32_firq_arbiter is

  constant channel_en_mask_lsb_c : natural := 0;
  constant channel_en_mask_msb_c : natural := 15;

  -- free for all/no protection level read/write as pleased
  constant ch_prot_level_0_c : std_ulogic_vector(1 downto 0) := "00";
  -- unlocked protection level, gets locked again after write access 
  constant ch_prot_level_1_c : std_ulogic_vector(1 downto 0) := "01";
  --locked protection level, set to unlock before writing 
  constant ch_prot_level_2_c : std_ulogic_vector(1 downto 0) := "10";
  -- locked down protection level can't be changed during runtime
  constant ch_prot_level_3_c : std_ulogic_vector(1 downto 0) := "11";

  type channel_num_t is array(0 to 15) of std_ulogic_vector(log2_ceil(firq_enum_t) - 1 dwonto 0);
  type channel_wrpr_level_t is array(0 to 15) of std_ulogic_vector(1 downto 0);
 
  type ctrl_t is record
    firq_channel_en_mask   : std_ulogic_vector(15 downto 0);
    firq_channel_wrpr_mask : channel_wrpr_level_t;
    firq_channel_assign    : channel_num_t;
  end record ctrl_t;
  signal ctrl : ctrl_t;

begin
  
  lGenNoArbiter: if not(FIRQ_ARBITER_EN) generate
    firq_o(irq_firq_0_c)  <= irq_i(FIRQ_TRNG);
    firq_o(irq_firq_1_c)  <= irq_i(FIRQ_CFS);
    firq_o(irq_firq_2_c)  <= irq_i(FIRQ_UART0_RX);
    firq_o(irq_firq_3_c)  <= irq_i(FIRQ_UART0_TX);
    firq_o(irq_firq_4_c)  <= irq_i(FIRQ_UART1_RX);
    firq_o(irq_firq_5_c)  <= irq_i(FIRQ_UART1_TX);
    firq_o(irq_firq_6_c)  <= irq_i(FIRQ_SPI);
    firq_o(irq_firq_7_c)  <= irq_i(FIRQ_TWI);
    firq_o(irq_firq_8_c)  <= irq_i(FIRQ_XIRQ);
    firq_o(irq_firq_9_c)  <= irq_i(FIRQ_NEOLED);
    firq_o(irq_firq_10_c) <= irq_i(FIRQ_DMA);
    firq_o(irq_firq_11_c) <= irq_i(FIRQ_SDI);
    firq_o(irq_firq_12_c) <= irq_i(FIRQ_GPTMR);
    firq_o(irq_firq_13_c) <= irq_i(FIRQ_ONEWIRE);
    firq_o(irq_firq_14_c) <= irq_i(FIRQ_SLINK_RX);
    firq_o(irq_firq_15_c) <= irq_i(FIRQ_SLINK_TX);
  end generate lGenNoArbiter;

  lGenArbiter: if FIRQ_ARBITER_EN generate

    l_seq_bus_access: process(clk_i, rstn_i) is
    begin
      if '0' = rstn_i then
        bus_rsp_o <= rsp_terminate_c;
        if ALL_CHANNEL_EN then
          ctrl.firq_channel_en_mask  <= (others => '1'); 
        else
          ctrl_firq_channel_en_mask  <= (others => '0');
        end if;
        if ALL_WR_PROT_EN then
          ctrl.firq_channel_wrpr_mask <= ch_prot_level_3_c; -- prot-lvl can't be changed
        else
          ctrl.firq_channel_wrpr_mask <= ch_prot_level_0_c; 
        end if;
      elsif rising_edge(clk_i) then
        bus_rsp_o.ack  <= bus_req_i.stb;
        bus_rsp_o.err  <= '0';
        bus_rsp_o.data <= (others => '0');
        -- read/write access
        if '1' = bus_req_i.stb then
          if '1' = bus_req_i.rw then -- write access
            if '0' = bus_req_i.addr(2) then
                ctrl.firq_channel_en_mask <= bus_req_i.data(channel_en_mask_msb_c downto channel_en_mask_lsb);
              elsif '1' = bus_req_i.addr(2) then -- define addresses used for this peripheral
              -- todo: impelemnt input to output channel assignment based on register protection level
              if '0' = bus_req_i.addr(0) then
                for i in 0 to 7 loop
                  if '0' = ctrl.firq_channel_wrpr_mask(i)(1) then
                    ctrl.firq_channel_wrpr_mask(i) <= bus_req_i.data((4*(i+1)) - 1 downto 4*i);
                  end if;
                end loop
              else
                for in 8 to 15 loop
                  if '0' = ctrl.firq_channel_wrpr_mask(i)(1) then
                    ctrl.firq_channel_assign(i) <= bus_req_i.data((4*(i+1)) - 1 downto 4*i);
                  end if;
                end loop;
              end if;
            else
              for i in channel_wrpr_level_t'range loop
                if ch_prot_level_3_c /= ctrl.firq_channel_wrpr_mask(i) then
                  if ch_prot_level_2_c = ctrl_firq_channel_wrpr_mask(i) then
                    if ch_prot_level_1 = bus_req_i.data((2*(i+1)) - 1 downto 2*i) then
                      -- allow channel protection to be unlocked
                      ctrl.firq_channel_wrpr_mask(i) <= bus_req_i.data((2*(i+1)) - 1 downto 2*i);
                    end if;
                  elsif ch_prot_level_1_c = ctrl_firq_channel_wrpr_mask(i) then
                    if ch_prot_level_0 /= bus_req_i.data((2*(i+1)) - 1 downto 2*i) and
                       ch_prot_level_1 /= bus_req_i.data((2*(i+1)) - 1 downto 2*i) then
                      -- allow the channel to be locked or permanently closed 
                      ctrl.firq_channel_wrpr_mask(i) <= bus_req_i.data((2*(i+1)) - 1 downto 2*i);
                    end if;
                  end if;
                end if;
              end loop;
            end if;
          else  -- read access
            if '0' = bus_req_i.addr(2) is
              bus_rsp_o.data(channel_en_mask_msb_c downto channel_en_mask_lsb_c) <= ctrl.firq_channel_en_mask;
            elsif '1' = bus_req_i.addr(2) then
              -- todo: implement input to output channel assignment reading
              if '0' = bus_req_i.addr(0) then
                for i in 0 to 7 loop
                  bus_rsp_o.data((4*(i+1)) - 1 downto 4*i) <= ctrl.firq_channel_assign(i);
                end loop;
              else
                for i in 8 to 15 loop
                  bus_rsp_o.data((4*(i+1)) - 1 downto 4*i) <= ctrl.firq_channel_assign(i)
                end loop;
              end if;
            else
              for i in channel_wrpr_level_t'range loop
                bus_rsp_o.data((2*(i+1)) - 1 downto 2*i) <= ctrl.firq_channel_wrpr_mask(i);
              end loop;
            end if;
          end if;
        end if;
      end if;
    end process l_seq_bus_access;

    l_assign_output: process(ctrl) is
      -- assertion: no clocked process to avoid further delay due induced flip flop
    begin
      -- range is reversed which allows lower input numbers to be at higher 
      -- priority firq-channels;
      for i in firq_o'reverse_range loop
        -- check if channel is enabled or all channel enabled option
        if '1' = ctrl.channel_en_mask(i) or ALL_CHANNEL_EN then
          if DEFAULT_EN then
            -- n-th input of entity irq_i port is forwarded to n-th firq_o output port
            -- which should equal to default 
            firq_o(i) <= irq_i(i);
          else
            firq_o(i) <= irq_i(to_integer(unsigned(ctrl.firq_channel_assign(i)))); 
          end if;
        else
          firq_o(i) <= '0';
        end if;
      end loop;
    end process l_assign_output;

  end generate lGenArbiter;

end architecture neorv32_firq_arbiter_rtl;

