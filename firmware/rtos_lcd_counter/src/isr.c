#include "mmio.h"
#include "rtos.h"

void trap_dispatch(trap_frame_t *frame) {
    uint32_t pending = mmio_read32(IO_IRQ_PENDING);
    (void)frame;

    if (pending & IRQ_TIMER) {
        mmio_write32(IO_IRQ_PENDING, IRQ_TIMER);
        rtos_on_systick();
    }

    if (pending & IRQ_BUTTON) {
        mmio_write32(IO_IRQ_PENDING, IRQ_BUTTON);
        rtos_on_button_edge();
    }
}
