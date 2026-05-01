#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

mkdir -p build
mkdir -p build/.config
mkdir -p build/home

export XDG_CONFIG_HOME="$PWD/build/.config"
export NEXTPNR_HOME="$PWD/build/home"

yosys -p "read_verilog -sv rtl/uart_tx.sv fpga/tang9k_uart_tx_smoke_top.sv; synth_gowin -top tang9k_uart_tx_smoke_top -json build/tang9k_uart_tx_smoke.json"

if command -v nextpnr-gowin >/dev/null 2>&1; then
  HOME="$NEXTPNR_HOME" nextpnr-gowin \
    --json build/tang9k_uart_tx_smoke.json \
    --freq 27 \
    --write build/tang9k_uart_tx_smoke_pnr.json \
    --device GW1NR-LV9QN88PC6/I5 \
    --family GW1N-9C \
    --cst fpga/tang9k_uart.cst
else
  HOME="$NEXTPNR_HOME" nextpnr-himbaechel \
    --json build/tang9k_uart_tx_smoke.json \
    --write build/tang9k_uart_tx_smoke_pnr.json \
    --freq 27 \
    --device GW1NR-LV9QN88PC6/I5 \
    --vopt family=GW1N-9C \
    --vopt cst=fpga/tang9k_uart.cst
fi

gowin_pack -d GW1N-9C -o build/tang9k_uart_tx_smoke.fs build/tang9k_uart_tx_smoke_pnr.json
