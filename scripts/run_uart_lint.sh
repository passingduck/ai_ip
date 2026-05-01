#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

verilator --lint-only --timing -Wall rtl/uart_tx.sv
verilator --lint-only --timing -Wall rtl/uart_rx.sv
verilator --lint-only --timing -Wall rtl/uart_tx.sv rtl/uart_rx.sv rtl/uart_echo.sv --top-module uart_echo
verilator --lint-only --timing -Wall \
  rtl/uart_tx.sv rtl/uart_rx.sv rtl/uart_echo.sv fpga/tang9k_uart_top.sv \
  --top-module tang9k_uart_top

