#include "csr.h"
#include "mmio.h"
#include "rtos.h"

extern void trap_entry(void);

static void uart_putc(char ch) {
    while (mmio_read32(IO_UART_STATUS) & (1u << 9)) {
    }
    mmio_write32(IO_UART_DATA, (uint32_t)(uint8_t)ch);
}

static void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

int main(void) {
    csr_write_mtvec((uint32_t)trap_entry);

    mmio_write32(IO_BUTTON_DEBOUNCE, 27u * 1000u * 20u);
    mmio_write32(IO_TIMER_RELOAD, 27u * 1000u);
    mmio_write32(IO_IRQ_PENDING, IRQ_TIMER | IRQ_BUTTON);
    mmio_write32(IO_IRQ_ENABLE, IRQ_TIMER | IRQ_BUTTON);

    rtos_init();
    uart_puts("RTOS LCD counter boot\r\n");
    irq_enable_global();
    rtos_run();

    while (1) {
    }
}
