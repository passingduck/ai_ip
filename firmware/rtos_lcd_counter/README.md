# RTOS LCD Counter Firmware

This firmware targets the Tang Nano 9K custom FemtoRV interrupt PoC.

Goal:

- idle task shows `idle` on the 1.14-inch SPI LCD
- button rising edge wakes a counter task
- counter task increments from 0 to `COUNT_MAX`
- systick interrupt drives timing and scheduler ticks
- trap entry saves all volatile CPU context before calling C handlers

The firmware assumes an interrupt-capable FemtoRV core such as
`femtorv32_intermissum`, not the tutorial `step20.v` CPU.

## Tree

```text
firmware/rtos_lcd_counter/
  Makefile
  include/
    csr.h
    mmio.h
    rtos.h
  src/
    main.c
    isr.c
    rtos.c
  arch/riscv/
    startup.S
    trap.S
  ld/
    linker.ld
```

## Build

```bash
make -C firmware/rtos_lcd_counter
```

Outputs go to `firmware/rtos_lcd_counter/build/`.
