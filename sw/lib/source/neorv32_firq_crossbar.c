#include "neorv32_firq_crossbar.h"

int neorv32_firq_cb_available(void) {

  if (NEORV32_SYSINFO->SOC & (1 << SYSINFO_SOC_FIRQ_CB)) {
    return 1;
  }
  else {
    return 0;
  }
}

int neorv32_firq_cb_ch_enable(const uint16_t ch) {

  if (0 > ch || 15 < ch) {
    return 0;
  }
  else {
    NEORV32_FIRQ_CB->CH_EN_MASK | (1 << ch);
    return 1;
  }
}

int neorv32_firq_cb_ch_disable(const uint16_t ch) {

  if (0 > ch || 15 < ch) {
    return 0;
  }
  else {
    NEORV32_FIRQ_CB->CH_EN_MASK & ~(1 << ch);
    return 1;
  }
}

int neorv32_firq_cb_ch_wrpr(const enum NEORV32_FIRQ_CB_WRPR_CH_enum ch, const enum NEORV32_FIRQ_CB_WRPR_enum level) {

  uint32_t reg_num = 0;
  if (WRPR_CH_8 <= ch) {
    reg_num = 1;
  }
  /* first clear write protection bits for this channel */
  NEORV32_FIRQ_CB->CH_WRPR_MASK[reg_num]  & ~(1 << ch) & ~(1 << ch + 1);
  /* then set to level accordingly */
  if (level & (1 << 0)) {
    NEORV32_FIRQ_CB->CH_WRPR_MASK[reg_num] |= (1 << ch);
  }
  if (level & (1 << 1)) {
    NEORV32_FIRQ_CB->CH_WRPR_MASK[reg_num] |= (1 << ch + 1);
  }
  return 0;
}

#undef neo32_firq_crossbar_h
