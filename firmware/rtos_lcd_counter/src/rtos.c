#include "mmio.h"
#include "rtos.h"

static volatile task_id_t current_task;
static volatile uint32_t ticks;
static volatile uint32_t button_events;
static volatile uint32_t counter;
static volatile uint32_t counter_active;

static void lcd_idle(void) {
    mmio_write32(IO_LCD_CMD, LCD_CMD_SHOW_IDLE);
}

static void lcd_count(uint32_t value) {
    mmio_write32(IO_LCD_VALUE, value);
    mmio_write32(IO_LCD_CMD, LCD_CMD_SHOW_COUNT);
}

void rtos_init(void) {
    current_task = TASK_IDLE;
    ticks = 0;
    button_events = 0;
    counter = 0;
    counter_active = 0;
    lcd_idle();
}

void rtos_on_systick(void) {
    ticks++;
}

void rtos_on_button_edge(void) {
    button_events++;
    counter = 0;
    counter_active = 1;
    current_task = TASK_COUNTER;
}

static void idle_task_step(void) {
    lcd_idle();
}

static void counter_task_step(void) {
    if (!counter_active) {
        current_task = TASK_IDLE;
        return;
    }

    lcd_count(counter);
    if (counter >= COUNT_MAX) {
        counter_active = 0;
        current_task = TASK_IDLE;
    } else {
        counter++;
    }
}

void rtos_run(void) {
    uint32_t last_tick = ticks;

    while (1) {
        if (last_tick == ticks && button_events == 0) {
            __asm__ volatile ("nop");
            continue;
        }
        last_tick = ticks;

        if (button_events != 0) {
            button_events = 0;
        }

        if (current_task == TASK_COUNTER) {
            counter_task_step();
        } else {
            idle_task_step();
        }
    }
}
