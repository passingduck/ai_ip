# AI RTL LFSR PoC

This repo is a small end-to-end RTL development proof of concept for Tang Nano 9K. The target workflow is:

```text
spec -> RTL -> Python golden model -> regression/coverage -> lint/sim -> Tang Nano 9K synth/program
```

## Repository Layout

- `spec/lfsr_spec.md`: configurable LFSR behavior spec
- `rtl/configurable_lfsr.sv`: reference RTL
- `rtl/lfsr8.sv`, `rtl/lfsr16.sv`: fixed Step 1 wrappers
- `rtl/lfsr_csr.sv`: simple CSR-controlled LFSR variant
- `tb/model_lfsr.py`: Python golden model
- `tb/test_lfsr_basic.py`: directed tests
- `tb/test_lfsr_random.py`: random, coverage, period, and bug-injection tests
- `tb/cocotb/`: cocotb + Verilator RTL testbench
- `tb/toffee_picker/`: Picker-generated DUT driven from Python with Toffee coverage primitives
- `tb/llm4dv_lfsr/`: LLM4DV-style coverage-feedback stimulus generation harness
- `fpga/tang9k_top.sv`: LED smoke-test top module
- `fpga/tang9k.cst`: Tang Nano 9K constraints
- `rtl/uart_tx.sv`, `rtl/uart_rx.sv`, `rtl/uart_echo.sv`: UART 8N1 TX/RX echo PoC
- `fpga/tang9k_uart_top.sv`, `fpga/tang9k_uart.cst`: Tang Nano 9K UART echo top and constraints
- `scripts/`: local verification, lint, synthesis, programming, and tool checks

## Quick Start

No external Python packages are required for the baseline regression:

```bash
scripts/run_python_tests.sh
```

Expected result:

```text
Ran 9 tests
OK
```

## Project Setup

### 1. Check Current Tools

```bash
scripts/check_tools.sh
```

This reports which tools are already available and which are missing.

### 2. Install Host Dependencies

For Ubuntu/Debian-like machines:

```bash
scripts/install_ubuntu_deps.sh
```

This installs host packages such as `curl`, `git`, `cmake`, `make`, `pipx`, `python3-pip`, `python3-venv`, and `swig`.

### 3. Install OSS CAD Suite

```bash
scripts/install_oss_cad_suite.sh
source scripts/source_oss_cad_suite.sh
scripts/check_tools.sh
```

By default this installs OSS CAD Suite to:

```text
$HOME/opt/oss-cad-suite
```

Override the install path if needed:

```bash
OSS_CAD_SUITE_DIR=/path/to/oss-cad-suite scripts/install_oss_cad_suite.sh
source scripts/source_oss_cad_suite.sh
```

OSS CAD Suite provides the tools needed for this PoC:

- `yosys`
- `verilator`
- `nextpnr-gowin` or `nextpnr-himbaechel`
- `gowin_pack`
- `openFPGALoader`

### 4. Install Picker and Toffee

```bash
source scripts/source_oss_cad_suite.sh
scripts/install_picker_toffee.sh
source .venv/bin/activate
```

This clones and builds Picker under `tools/picker`, then installs Picker wheels and `pytoffee` into `.venv`.

If Picker fails with `pipx: not found`, install the missing host dependency and rerun the same step:

```bash
sudo apt-get update
sudo apt-get install -y pipx
source scripts/source_oss_cad_suite.sh
scripts/install_picker_toffee.sh
```

### 5. One-Command Setup

For a fresh Ubuntu/Debian-like machine:

```bash
scripts/setup_all_tools.sh
source scripts/source_oss_cad_suite.sh
source .venv/bin/activate
scripts/check_tools.sh
```

## Verification Flow

### Python Golden-Model Regression

```bash
scripts/run_python_tests.sh
```

This runs:

- directed reset/hold/load/zero-seed/known-sequence checks
- random control-stream checks
- small-width maximal-period check
- coverage-bin closure check
- bug-injection detection check

### Verilator Lint

```bash
scripts/run_verilator_lint.sh
```

To lint all Step 1/2/3 RTL:

```bash
scripts/run_verilator_lint.sh all
```

To lint a generated candidate instead of the reference RTL:

```bash
scripts/run_verilator_lint.sh generated/candidate_from_verilogcoder.sv
scripts/run_verilator_lint.sh generated/candidate_from_mage.sv
```

### Verilator Simulation

```bash
scripts/run_verilator_sim.sh
```

This builds and runs the C++ smoke test in `tb/verilator_lfsr_tb.cpp`.

### Step 1/2/3 Verilator Tests

```bash
scripts/run_verilator_step_tests.sh
```

This verifies:

- Step 1 fixed 8-bit LFSR sequence
- Step 1 fixed 16-bit LFSR sequence
- Step 3 CSR reset, seed, load, enable, clear, zero-seed sanitization, and period-done behavior

### cocotb RTL Tests

```bash
scripts/run_cocotb_tests.sh
```

This uses OSS CAD Suite's cocotb + Verilator flow to drive `rtl/configurable_lfsr.sv` directly and compare it with `tb/model_lfsr.py`.

### Toffee/Picker Tests

```bash
scripts/run_picker.sh
scripts/run_toffee_picker_tests.sh
```

This generates a Picker Python DUT package, drives it from Python, and uses Toffee functional coverage primitives.
Use `scripts/run_picker.sh --force` when RTL has changed and the generated package must be rebuilt.

### LLM4DV-Style Coverage Feedback

```bash
scripts/run_llm4dv_lfsr.sh
```

This implements the LLM4DV-style loop locally:

```text
coverage plan -> stimulus generation -> golden model execution -> coverage feedback
```

It does not call an external LLM API yet.

### Full Verification Matrix

```bash
scripts/run_verification_matrix.sh
```

This runs the current PC-side verification matrix:

- Python golden-model tests
- Verilator lint
- Verilator C++ tests
- cocotb tests
- Picker DUT generation
- Toffee/Picker tests
- LLM4DV-style coverage stimulus run

## UART TX/RX PoC

The UART PoC adds a small 8N1 TX/RX IP and a Tang Nano 9K echo top:

```text
host serial TX -> FPGA uart_rx -> echo buffer -> FPGA uart_tx -> host serial RX
```

PC-side verification:

```bash
scripts/run_uart_regression.sh
```

This runs:

- Python UART frame/golden-model tests
- Verilator lint for `uart_tx`, `uart_rx`, `uart_echo`, and the Tang Nano top
- Verilator C++ loopback simulation
- cocotb UART echo test

Build the UART bitstream:

```bash
scripts/run_synth_uart.sh
```

Program Tang Nano 9K SRAM:

```bash
scripts/program_uart_tang9k.sh --sudo
```

Run board-level UART echo smoke test:

```bash
scripts/run_uart_board_test.sh --sudo --port /dev/ttyUSB1
```

If both JTAG and serial access need sudo on the current login session:

```bash
scripts/run_uart_board_test.sh --sudo --serial-sudo --port /dev/ttyUSB1
```

If the UART bitstream is already uploaded and only the serial echo check is needed:

```bash
scripts/run_uart_board_test.sh --skip-program --serial-sudo --port /dev/ttyUSB1
```

If echo receives nothing, isolate the board TX path with the TX-only smoke bitstream:

```bash
scripts/run_synth_uart_tx_smoke.sh
scripts/program_uart_tx_smoke_tang9k.sh --sudo
sudo scripts/test_uart_receive_host.py --port /dev/ttyUSB1
```

If serial access fails with permission denied, add the user to `dialout` and log out/in:

```bash
sudo usermod -aG dialout "$USER"
```

## Tang Nano 9K Flow

### Synthesize and Pack Bitstream

```bash
source scripts/source_oss_cad_suite.sh
scripts/run_synth.sh
```

Generated files are written under `build/`, including:

```text
build/tang9k_lfsr.json
build/tang9k_lfsr_pnr.json
build/tang9k_lfsr.fs
```

## SPI LCD DEEPX Demo

The SPI LCD demo targets common 1.14-inch 240x135 4-wire SPI LCD modules using
ST7789-like controllers. It initializes the LCD in RGB565 mode and renders blue
`DEEPX` text sliding across a black background.

RTL:

- `rtl/spi_lcd_byte_tx.sv`
- `rtl/spi_lcd_deepx_demo.sv`
- `fpga/tang9k_spi_lcd_top.sv`

The default constraint file is for the built-in Tang Nano 9K 8-pin SPI LCD FPC
connector:

```text
lcd_sclk   FPGA pin 76
lcd_mosi   FPGA pin 77
lcd_cs_n   FPGA pin 48
lcd_dc     FPGA pin 49
lcd_rst_n  FPGA pin 47
```

Run lint:

```bash
scripts/run_spi_lcd_lint.sh
```

For first bring-up or blank-screen debug, use the minimal 1.14-inch LCD color
bar example. It follows the Sipeed Tang Nano 9K 1.14-inch LCD init flow and
draws blue/green/red bars once:

```bash
scripts/run_lcd114_colorbar_lint.sh
scripts/run_synth_lcd114_colorbar.sh
scripts/program_lcd114_colorbar_tang9k.sh --sudo
```

Build and program:

```bash
scripts/run_synth_spi_lcd.sh
scripts/program_spi_lcd_tang9k.sh --sudo
```

The default top is configured for a 1.14-inch 240x135 ST7789-style panel:

```text
LCD_WIDTH=240
LCD_HEIGHT=135
LCD_X_OFFSET=40
LCD_Y_OFFSET=53
MADCTL=8'h70
```

If the image is shifted, clipped, mirrored, or rotated, tune `LCD_X_OFFSET`,
`LCD_Y_OFFSET`, and `MADCTL` in `fpga/tang9k_spi_lcd_top.sv`.

## learn-fpga FemtoRV RISC-V on Tang Nano 9K

This flow builds Bruno Levy's `learn-fpga` tutorial RISC-V SoC for Tang Nano 9K.
The current board smoke test uses `FROM_BLINKER_TO_RISCV/step20.v` with the
`hello.S` firmware loaded into BRAM. After programming, the CPU repeatedly sends
`Hello, world !` over UART at 115200 baud.

One local compatibility patch is applied in
`tools/learn-fpga/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/clockworks.v`: the
upstream Tang Nano 9K PLL wrapper does not elaborate cleanly with the current
oss-cad-suite Gowin cells, so the build defines `NO_PLL` and runs the CPU at the
board clock, 27 MHz. The UART divider is also configured for 27 MHz.

Build:

```bash
scripts/run_synth_learn_fpga_riscv.sh
```

Program:

```bash
scripts/program_learn_fpga_riscv_tang9k.sh --sudo
```

Check UART:

```bash
sudo scripts/test_learn_fpga_riscv_uart.py --port /dev/ttyUSB1
```

Expected output:

```text
learn-fpga RISC-V UART PASS on /dev/ttyUSB1: Hello, world !
```

## RTOS LCD Counter PoC

The `learn-fpga` tutorial `step20.v` CPU used for the first `Hello, world !`
board smoke test does not implement the interrupt CSRs needed for RTOS-style
trap handling. The RTOS PoC therefore targets the interrupt-capable FemtoRV
cores in `tools/learn-fpga/FemtoRV/RTL/PROCESSOR`, starting with
`femtorv32_intermissum.v` (`RV32IM + CSR + MRET`).

Firmware tree:

```bash
make -C firmware/rtos_lcd_counter
```

Generated outputs:

```text
firmware/rtos_lcd_counter/build/rtos_lcd_counter.elf
firmware/rtos_lcd_counter/build/rtos_lcd_counter.hex
firmware/rtos_lcd_counter/build/rtos_lcd_counter.list
```

RTL support block:

```bash
scripts/run_rtos_soc_lint.sh
scripts/run_synth_rtos_soc.sh
```

Architecture notes:

```text
docs/rtos_lcd_counter/architecture.md
```

Board upload and UART banner check:

```bash
scripts/program_rtos_soc_tang9k.sh --sudo
sudo scripts/test_rtos_soc_uart.py --port /dev/ttyUSB1
```

Expected behavior:

```text
UART: RTOS LCD counter boot
LCD : IDLE after boot; 4-digit count after button edge
LED : low 4 bits from firmware LED register, plus IRQ/button status
```

Current synthesis result for Tang Nano 9K:

```text
LUT4  : about 45%
DFF   : about 16%
BSRAM : 16 / 26
Timing: PASS at 27 MHz
Output: build/tang9k_rtos_soc.fs
```

## Program Board

Connect the Tang Nano 9K, then run:

```bash
source scripts/source_oss_cad_suite.sh
scripts/program_tang9k.sh
```

If USB permission is not configured and direct programming fails, use:

```bash
scripts/program_tang9k.sh --sudo
```

To make programming work without `sudo`, install the udev rule and reconnect the board:

```bash
scripts/install_tang9k_udev_rules.sh
```

The FPGA top drives the six on-board LEDs with the low state bits of the LFSR. LEDs are active-low. Button 0 resets the design, and button 1 loads a fixed non-zero seed.

## Picker/Toffee Follow-Up

After installing Picker and Toffee:

```bash
source scripts/source_oss_cad_suite.sh
source .venv/bin/activate
scripts/run_picker.sh
scripts/run_toffee_tests.sh
```

Current status:

- `scripts/run_picker.sh` generates a Python-callable DUT package from `rtl/configurable_lfsr.sv`.
- `scripts/run_toffee_tests.sh` checks that `pytoffee` is installed and points back to the existing Python golden-model tests as the behavioral source of truth.

Next implementation step is to replace the placeholder Toffee script with a DUT-driving Toffee environment that reuses `tb/model_lfsr.py`.

## AI Candidate Evaluation

Put generated RTL candidates here:

```text
generated/candidate_from_verilogcoder.sv
generated/candidate_from_mage.sv
```

Then run the same checks against each candidate:

```bash
scripts/run_verilator_lint.sh generated/candidate_from_verilogcoder.sv
scripts/run_verilator_lint.sh generated/candidate_from_mage.sv
scripts/run_python_tests.sh
```

Track the results using:

- syntax/lint pass
- directed test pass count
- random regression pass count
- coverage bins reached
- bug-injection detection
- synthesis success
- Tang Nano 9K LED smoke-test result

## Script Reference

| Script | Purpose |
| --- | --- |
| `scripts/check_tools.sh` | Report installed and missing EDA tools. |
| `scripts/install_ubuntu_deps.sh` | Install Ubuntu/Debian host dependencies. |
| `scripts/install_oss_cad_suite.sh` | Download and install OSS CAD Suite. |
| `scripts/source_oss_cad_suite.sh` | Source OSS CAD Suite into the current shell. |
| `scripts/install_picker_toffee.sh` | Build Picker and install Toffee into `.venv`. |
| `scripts/setup_all_tools.sh` | Run host dependency, OSS CAD Suite, and Picker/Toffee setup. |
| `scripts/install_tang9k_udev_rules.sh` | Install Tang Nano 9K USB permission rule for non-sudo programming. |
| `scripts/run_python_tests.sh` | Run dependency-free Python regression. |
| `scripts/run_verilator_lint.sh` | Run Verilator lint on reference or candidate RTL. |
| `scripts/run_verilator_sim.sh` | Run Verilator C++ smoke simulation. |
| `scripts/run_verilator_step_tests.sh` | Run Step 1 fixed LFSR and Step 3 CSR Verilator tests. |
| `scripts/run_cocotb_tests.sh` | Run cocotb + Verilator RTL tests. |
| `scripts/run_toffee_picker_tests.sh` | Run Picker-generated DUT tests with Toffee coverage primitives. |
| `scripts/run_llm4dv_lfsr.sh` | Run LLM4DV-style coverage-feedback stimulus generation. |
| `scripts/run_verification_matrix.sh` | Run all current PC-side verification benches. |
| `scripts/run_synth.sh` | Build Tang Nano 9K `.fs` bitstream. |
| `scripts/program_tang9k.sh` | Program Tang Nano 9K with the generated bitstream. |
| `scripts/run_picker.sh` | Generate a Picker Python DUT package. |
| `scripts/run_toffee_tests.sh` | Toffee installation check and future test entry point. |

## References

- Toolchain setup details: `docs/toolchain_setup.md`
- AI RTL flow details: `docs/ai_rtl_flow.md`
- LFSR shift convention: `docs/adr/0001-lfsr-shift-convention.md`
