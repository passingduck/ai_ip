#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

make -C firmware/rtos_lcd_counter all

mkdir -p build/verilator/rtos_soc

verilator -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET --public-flat-rw --cc \
  tools/learn-fpga/FemtoRV/RTL/PROCESSOR/femtorv32_intermissum.v \
  rtl/uart_tx.sv \
  rtl/irq_timer_button.sv \
  rtl/rtos_lcd_mmio.sv \
  fpga/tang9k_rtos_soc_top.sv \
  --top-module tang9k_rtos_soc_top \
  --exe tb/verilator_rtos_soc_tb.cpp \
  --Mdir build/verilator/rtos_soc

make -C build/verilator/rtos_soc -f Vtang9k_rtos_soc_top.mk Vtang9k_rtos_soc_top
build/verilator/rtos_soc/Vtang9k_rtos_soc_top
