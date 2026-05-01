#ifndef RTOS_LCD_COUNTER_MMIO_H
#define RTOS_LCD_COUNTER_MMIO_H

#include <stdint.h>

#define IO_BASE              0x00400000u

#define IO_LED               (IO_BASE + 0x00u)
#define IO_UART_DATA         (IO_BASE + 0x04u)
#define IO_UART_STATUS       (IO_BASE + 0x08u)
#define IO_LCD_CMD           (IO_BASE + 0x0cu)
#define IO_LCD_VALUE         (IO_BASE + 0x10u)
#define IO_IRQ_PENDING       (IO_BASE + 0x14u)
#define IO_IRQ_ENABLE        (IO_BASE + 0x18u)
#define IO_TIMER_RELOAD      (IO_BASE + 0x1cu)
#define IO_TIMER_VALUE       (IO_BASE + 0x20u)
#define IO_BUTTON_STATE      (IO_BASE + 0x24u)
#define IO_BUTTON_DEBOUNCE   (IO_BASE + 0x28u)

#define IRQ_TIMER            (1u << 0)
#define IRQ_BUTTON           (1u << 1)

#define LCD_CMD_CLEAR        0u
#define LCD_CMD_SHOW_IDLE    1u
#define LCD_CMD_SHOW_COUNT   2u

static inline void mmio_write32(uint32_t addr, uint32_t value) {
    *(volatile uint32_t *)addr = value;
}

static inline uint32_t mmio_read32(uint32_t addr) {
    return *(volatile uint32_t *)addr;
}

#endif
