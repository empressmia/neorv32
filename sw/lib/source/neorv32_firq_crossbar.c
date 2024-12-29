#include "neorv32_firq_crossbar.h"

int neorv32_firq_cb_available(void) {

  if (NEORV32_SYSINFO->SOC & (1 << SYSINFO_SOC_FIRQ_CB)) {
    return 1;
  }
  else {
    return 0;
  }
}

#undef neo32_firq_crossbar_h
