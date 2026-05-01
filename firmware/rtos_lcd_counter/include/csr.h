#ifndef RTOS_LCD_COUNTER_CSR_H
#define RTOS_LCD_COUNTER_CSR_H

#include <stdint.h>

#define CSR_MSTATUS 0x300
#define CSR_MTVEC   0x305
#define CSR_MEPC    0x341
#define CSR_MCAUSE  0x342

#define MSTATUS_MIE (1u << 3)

static inline void csr_write_mstatus(uint32_t value) {
    __asm__ volatile ("csrw mstatus, %0" :: "r"(value) : "memory");
}

static inline uint32_t csr_read_mstatus(void) {
    uint32_t value;
    __asm__ volatile ("csrr %0, mstatus" : "=r"(value));
    return value;
}

static inline void csr_write_mtvec(uint32_t value) {
    __asm__ volatile ("csrw mtvec, %0" :: "r"(value) : "memory");
}

static inline uint32_t csr_read_mcause(void) {
    uint32_t value;
    __asm__ volatile ("csrr %0, mcause" : "=r"(value));
    return value;
}

static inline uint32_t csr_read_mepc(void) {
    uint32_t value;
    __asm__ volatile ("csrr %0, mepc" : "=r"(value));
    return value;
}

static inline void irq_enable_global(void) {
    csr_write_mstatus(csr_read_mstatus() | MSTATUS_MIE);
}

static inline void irq_disable_global(void) {
    csr_write_mstatus(csr_read_mstatus() & ~MSTATUS_MIE);
}

#endif
