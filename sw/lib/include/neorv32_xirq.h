// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2024 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**
 * @file neorv32_xirq.h
 * @brief External Interrupt controller HW driver header file.
 *
 * @see https://stnolting.github.io/neorv32/sw/files.html
 */

#ifndef neorv32_xirq_h
#define neorv32_xirq_h

/**********************************************************************//**
 * @name IO Device: External Interrupt Controller (XIRQ)
 **************************************************************************/
/**@{*/
/** XIRQ module prototype */
typedef volatile struct __attribute__((packed,aligned(4))) {
  uint32_t       EIE;      /**< offset 0:  external interrupt enable register */
  uint32_t       EIP;      /**< offset 4:  external interrupt pending register */
  uint32_t       ESC;      /**< offset 8:  external interrupt source register */
  const uint32_t reserved; /**< offset 12: reserved */
} neorv32_xirq_t;

/** XIRQ module hardware access (#neorv32_xirq_t) */
#define NEORV32_XIRQ ((neorv32_xirq_t*) (NEORV32_XIRQ_BASE))
/**@}*/


/**********************************************************************//**
 * @name Prototypes
 **************************************************************************/
/**@{*/
int  neorv32_xirq_available(void);
int  neorv32_xirq_setup(void);
void neorv32_xirq_global_enable(void);
void neorv32_xirq_global_disable(void);
int  neorv32_xirq_get_num(void);
void neorv32_xirq_clear_pending(int channel);
void neorv32_xirq_channel_enable(int channel);
void neorv32_xirq_channel_disable(int channel);
int  neorv32_xirq_install(int channel, void (*handler)(void));
int  neorv32_xirq_uninstall(int channel);
/**@}*/


#endif // neorv32_xirq_h
