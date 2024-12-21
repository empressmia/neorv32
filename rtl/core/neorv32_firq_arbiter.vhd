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
    NUM_INPUT_CH    : integer := 1;
    NUM_OUTPUT_CH   : integer := 16;
    ALL_CHANNEL_EN  : boolean := true;
    DEFAULT_EN      : boolean := true;
    INIT_PROT_LEVEL : std_ulogic_vector := "11"
  );   
  port (
    clk_i           : in  std_ulogic;
    rstn_i          : in  std_ulogic;
    bus_req_i       : in  bus_req_t;
    bus_rsp_o       : out bus_rsp_t;
    irq_i           : in  std_logic_vector(NUM_INPUT_CH - 1 downto 0);
    firq_o          : out std_ulogic_vector(NUM_OUTPUT_CH - 1 downto 0)
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

  type channel_num_t is array(0 to NUM_OUTPUT_CH - 1) of 
       std_ulogic_vector(index_size_f(NUM_OUTPUT_CH) - 1 downto 0);
  type channel_wrpr_level_t is array(0 to 15) of std_ulogic_vector(1 downto 0);
 
  type ctrl_t is record
    firq_channel_en_mask   : std_ulogic_vector(15 downto 0);
    firq_channel_wrpr_mask : channel_wrpr_level_t;
    firq_channel_assign    : channel_num_t;
  end record ctrl_t;
  signal ctrl : ctrl_t;

  procedure firq_channel_init_p(signal channel_assign : inout channel_num_t) is
  begin
    for i in channel_num_t'range loop
      channel_assign(i) <= std_ulogic_vector(to_unsigned(
                             firq_enum_t'pos(firq_enum_t'val(i)), index_size_f(NUM_OUTPUT_CH))
                           );
    end loop;
  end procedure firq_channel_init_p;

begin

  l_seq_bus_access: process(clk_i, rstn_i) is
  begin
    if '0' = rstn_i then
      bus_rsp_o <= rsp_terminate_c;
      if ALL_CHANNEL_EN then
        ctrl.firq_channel_en_mask  <= (others => '1'); 
      else
        ctrl.firq_channel_en_mask  <= (others => '0');
      end if;
      ctrl.firq_channel_wrpr_mask <= (others => INIT_PROT_LEVEL); 
      firq_channel_init_p(ctrl.firq_channel_assign);
    elsif rising_edge(clk_i) then
      bus_rsp_o.ack  <= bus_req_i.stb;
      bus_rsp_o.err  <= '0';
      bus_rsp_o.data <= (others => '0');
      -- read/write access
      if '1' = bus_req_i.stb then
        if '1' = bus_req_i.rw then -- write access
          if '0' = bus_req_i.addr(3) then
              ctrl.firq_channel_en_mask <= bus_req_i.data(channel_en_mask_msb_c downto channel_en_mask_lsb_c);
            elsif '1' = bus_req_i.addr(2) then -- define addresses used for this peripheral
            if '1' = bus_req_i.addr(3) then
              for i in 0 to 7 loop
                if '0' = ctrl.firq_channel_wrpr_mask(i)(1) then
                  ctrl.firq_channel_assign(i) <= bus_req_i.data((4*(i+1)) - 1 downto 4*i);
                end if;
              end loop;
            else
              for i in 0 to 7 loop
                if '0' = ctrl.firq_channel_wrpr_mask(i)(1) then
                  ctrl.firq_channel_assign(i + 8) <= bus_req_i.data((4*(i+1)) - 1 downto 4*i);
                end if;
              end loop;
            end if;
          else
            for i in channel_wrpr_level_t'range loop
              if ch_prot_level_3_c /= ctrl.firq_channel_wrpr_mask(i) then
                if ch_prot_level_2_c = ctrl.firq_channel_wrpr_mask(i) then
                  if ch_prot_level_1_c = bus_req_i.data((2*(i+1)) - 1 downto 2*i) then
                    -- allow channel protection to be unlocked
                    ctrl.firq_channel_wrpr_mask(i) <= bus_req_i.data((2*(i+1)) - 1 downto 2*i);
                  end if;
                elsif ch_prot_level_1_c = ctrl.firq_channel_wrpr_mask(i) then
                  if ch_prot_level_0_c /= bus_req_i.data((2*(i+1)) - 1 downto 2*i) and
                     ch_prot_level_1_c /= bus_req_i.data((2*(i+1)) - 1 downto 2*i) then
                    -- allow the channel to be locked or permanently closed 
                    ctrl.firq_channel_wrpr_mask(i) <= bus_req_i.data((2*(i+1)) - 1 downto 2*i);
                  end if;
                end if;
              end if;
            end loop;
          end if;
        else  -- read access
          if '0' = bus_req_i.addr(3) then
            bus_rsp_o.data(channel_en_mask_msb_c downto channel_en_mask_lsb_c) <= ctrl.firq_channel_en_mask;
          elsif '1' = bus_req_i.addr(3) then
            if '0' = bus_req_i.addr(0) then
              -- only valid as long as there are 'only' 16 fast-irq channels
              for i in 0 to 7 loop
                bus_rsp_o.data((4*(i+1)) - 1 downto 4*i) <= ctrl.firq_channel_assign(i);
              end loop;
            else
              for i in 0 to 7 loop
                bus_rsp_o.data((4*(i+1)) - 1 downto 4*i) <= ctrl.firq_channel_assign(i + 8);
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
    -- range is reversed which allows lower input port numbers to be at higher 
    -- priority firq-channels;
    for i in firq_o'reverse_range loop
      -- check if channel is enabled or all channel enabled option
      if '1' = ctrl.firq_channel_en_mask(i) or ALL_CHANNEL_EN then
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

end architecture neorv32_firq_arbiter_rtl;

