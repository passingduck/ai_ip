#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

mkdir -p build/verilator/uart_loopback

verilator -Wall --cc \
  rtl/uart_tx.sv rtl/uart_rx.sv tb/uart_loopback_top.sv \
  --top-module uart_loopback_top \
  -GCLKS_PER_BIT=4 \
  --exe tb/verilator_uart_loopback_tb.cpp \
  --Mdir build/verilator/uart_loopback
make -C build/verilator/uart_loopback -f Vuart_loopback_top.mk Vuart_loopback_top
build/verilator/uart_loopback/Vuart_loopback_top

