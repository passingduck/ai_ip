#ifndef RTOS_LCD_COUNTER_RTOS_H
#define RTOS_LCD_COUNTER_RTOS_H

#include <stdint.h>

#define COUNT_MAX 9999u

typedef enum {
    TASK_IDLE = 0,
    TASK_COUNTER = 1,
} task_id_t;

typedef struct {
    uint32_t ra;
    uint32_t sp;
    uint32_t gp;
    uint32_t tp;
    uint32_t t0;
    uint32_t t1;
    uint32_t t2;
    uint32_t s0;
    uint32_t s1;
    uint32_t a0;
    uint32_t a1;
    uint32_t a2;
    uint32_t a3;
    uint32_t a4;
    uint32_t a5;
    uint32_t a6;
    uint32_t a7;
    uint32_t s2;
    uint32_t s3;
    uint32_t s4;
    uint32_t s5;
    uint32_t s6;
    uint32_t s7;
    uint32_t s8;
    uint32_t s9;
    uint32_t s10;
    uint32_t s11;
    uint32_t t3;
    uint32_t t4;
    uint32_t t5;
    uint32_t t6;
    uint32_t mepc;
    uint32_t mcause;
} trap_frame_t;

void rtos_init(void);
void rtos_run(void);
void rtos_on_systick(void);
void rtos_on_button_edge(void);
void trap_dispatch(trap_frame_t *frame);

#endif
