// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2024 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**
 * @file neorv32_gptmr.h
 * @brief General purpose timer (GPTMR) HW driver header file.
 *
 * @note These functions should only be used if the GPTMR unit was synthesized (IO_GPTMR_EN = true).
 *
 * @see https://stnolting.github.io/neorv32/sw/files.html
 */

#ifndef neorv32_firq_crossbar_h
#define neorv32_firq_crossbar_h

#include <stdint.h>

typedef volatile struct __attribute__((packed,aligned(4))) {
  uint32_t CH_EN_MASK;      /** < offset o: output channel enabled; i.e. forwards irq to cpu */
  uint32_t CH_WRPR_MASK[2]; /** < offset 4: */
  uint32_t CH_ASSIGN[3];    /** < offset 8: */
} neorv32_firq_crossbar_t;

enum NEORV32_FIRQ_CB_WRPR_CH_enum {
 WRPR_CH_0  =  0,
 WRPR_CH_1  =  2,
 WRPR_CH_2  =  4,
 WRPR_CH_3  =  6,
 WRPR_CH_4  =  8,
 WRPR_CH_5  = 10,
 WRPR_CH_6  = 12,
 WRPR_CH_7  = 14,
 WRPR_CH_8  = 16,
 WRPR_CH_9  = 18,
 WRPR_CH_10 = 20,
 WRPR_CH_11 = 22,
 WRPR_CH_12 = 24,
 WRPR_CH_13 = 26,
 WRPR_CH_14 = 28,
 WRPR_CH_15 = 30
} neorv32_firq_cb_wrpr_ch_t;

enum NEORV32_FIRQ_CB_WRPR_enum {
  CH_PROT_LEVEL_0 = 0,
  CH_PROT_LEVEL_1 = 1,
  CH_PROT_LEVEL_2 = 2,
  CH_PROT_LEVEL_3 = 3
} neorv32_firq_cb_wrpr_t;

/** FIRQ crossbar module hardware access (#neorv32_firq_crossbar_t) */
#define NEORV32_FIRQ_CB ((neorv32_firq_crossbar_t*) (NEORV32_FIRQ_CB_BASE))

int neorv32_firq_cb_available(void);
int neorv32_firq_cb_ch_enable(const uint16_t ch_num);
int neorv32_firq_cb_ch_disable(const uint16_t ch_num);
int neorv32_firq_cb_ch_wrpr(const enum NEORV32_FIRQ_CB_WRPR_CH_enum ch, const enum NEORV32_FIRQ_CB_WRPR_enum level);
int neorv32_firq_cb_ch_assign(const uint16_t ch, const uint8_t input_ch_num);
enum NEORV32_FIRQ_CB_WRPR_enum neorv32_firq_cb_get_wrpr(const uint16_t ch);

#endif /* neorv32_firq_crossbar_h */
