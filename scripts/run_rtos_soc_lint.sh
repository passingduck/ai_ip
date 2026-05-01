#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

verilator --lint-only -Wall \
  -Wno-DECLFILENAME \
  -Wno-UNUSEDSIGNAL \
  -Wno-SYNCASYNCNET \
  tools/learn-fpga/FemtoRV/RTL/PROCESSOR/femtorv32_intermissum.v \
  rtl/uart_tx.sv \
  rtl/irq_timer_button.sv \
  rtl/rtos_lcd_mmio.sv \
  fpga/tang9k_rtos_soc_top.sv
