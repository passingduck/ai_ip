# RTOS LCD Counter Architecture

## CPU Choice

The `learn-fpga` tutorial `step20.v` CPU that currently runs `Hello, world !`
does not have usable interrupt support. It treats `SYSTEM` as a special/simple
operation and does not implement the interrupt CSRs needed for an RTOS-style
trap path.

For this PoC, use an interrupt-capable FemtoRV core:

- preferred first core: `FemtoRV/RTL/PROCESSOR/femtorv32_intermissum.v`
- ISA: `RV32IM + CSR + MRET`
- interrupt input: `interrupt_request`
- implemented CSRs: `mstatus`, `mtvec`, `mepc`, `mcause`, `cycle`

The core accepts interrupts in its execute state, saves the return PC into
`mepc`, jumps to `mtvec`, and returns with `mret`.

## Interrupt Sources

The custom SoC should OR these sources into `interrupt_request`:

- `IRQ_TIMER`: periodic systick down-counter
- `IRQ_BUTTON`: debounced button rising edge

The hardware block [irq_timer_button.sv](/home/sungjin/workspace/ai_ip/rtl/irq_timer_button.sv)
implements:

- synchronizer for active-low Tang Nano 9K button input
- debounce counter
- rising edge detect after debounce
- periodic timer reload counter
- pending/enable/clear MMIO registers

## MMIO Map

The firmware uses a simple word-addressed IO page at `0x00400000`.

```text
0x00400000 IO_LED
0x00400004 IO_UART_DATA
0x00400008 IO_UART_STATUS
0x0040000c IO_LCD_CMD
0x00400010 IO_LCD_VALUE
0x00400014 IO_IRQ_PENDING
0x00400018 IO_IRQ_ENABLE
0x0040001c IO_TIMER_RELOAD
0x00400020 IO_TIMER_VALUE
0x00400024 IO_BUTTON_STATE
0x00400028 IO_BUTTON_DEBOUNCE
```

`IO_IRQ_PENDING` is write-1-to-clear.

## Firmware Trap Path

Firmware lives under [firmware/rtos_lcd_counter](/home/sungjin/workspace/ai_ip/firmware/rtos_lcd_counter).

Trap entry:

- saves `ra`, `gp`, `tp`, all `t*`, `s*`, `a*`, plus `mepc` and `mcause`
- calls `trap_dispatch(trap_frame_t *)`
- restores registers
- exits with `mret`

This proves the basic mechanism needed for RTOS context backup. A full preemptive
context switch can extend this by storing each task's saved trap frame pointer in
a task control block and restoring another task's frame before `mret`.

## Task Behavior

Initial firmware behavior:

- boot sets `mtvec`, enables timer and button IRQs, then enables `mstatus.MIE`
- idle task displays `idle`
- debounced button edge resets `counter` to 0 and activates counter task
- systick drives scheduler ticks
- counter task displays and increments the count until `COUNT_MAX`

## Board Pin Assumptions

Tang Nano 9K:

- `clk`: pin 52, 27 MHz
- reset button: pin 4, active low
- user button edge source: pin 3, active low
- UART TX/RX: pins 17/18
- 1.14-inch FPC SPI LCD: pins 77/76/48/49/47

## Implemented RTL Flow

The Tang Nano 9K SoC top is [tang9k_rtos_soc_top.sv](/home/sungjin/workspace/ai_ip/fpga/tang9k_rtos_soc_top.sv).

It currently implements:

- `femtorv32_intermissum` CPU with `interrupt_request`
- 32 KiB firmware RAM initialized from `firmware/rtos_lcd_counter/build/rtos_lcd_counter.hex`
- UART TX MMIO for boot/status logs
- `irq_timer_button` connected to timer/button pending bits
- LCD MMIO renderer:
  - `LCD_CMD_SHOW_IDLE` renders `IDLE`
  - `LCD_CMD_SHOW_COUNT` renders a 4-digit BCD count

Build and board-test commands:

```bash
scripts/run_rtos_soc_lint.sh
scripts/run_synth_rtos_soc.sh
scripts/program_rtos_soc_tang9k.sh --sudo
sudo scripts/test_rtos_soc_uart.py --port /dev/ttyUSB1
```

Current Tang Nano 9K synthesis status:

- `build/tang9k_rtos_soc.fs` is generated.
- 27 MHz timing passes.
- BSRAM use is 16 of 26 blocks after reducing RAM from 64 KiB to 32 KiB.

## Remaining Verification Work

Next verification steps:

1. Add a Verilator SoC test that runs the firmware for enough cycles to observe the UART boot banner.
2. Add a direct IRQ test that forces timer/button pending bits and confirms:
   - `mtvec` is reached
   - `mret` returns
   - pending bits are cleared
   - count task state changes after button edge
3. Run the board image and confirm:
   - LCD shows `IDLE` after boot
   - button edge starts the counter
   - repeated jitter during a press does not create multiple button events
