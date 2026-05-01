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

yosys -p "read_verilog -sv rtl/lcd114_colorbar_simple.sv fpga/tang9k_lcd114_colorbar_top.sv; synth_gowin -top tang9k_lcd114_colorbar_top -json build/tang9k_lcd114_colorbar.json"

if command -v nextpnr-gowin >/dev/null 2>&1; then
  HOME="$NEXTPNR_HOME" nextpnr-gowin \
    --json build/tang9k_lcd114_colorbar.json \
    --freq 27 \
    --write build/tang9k_lcd114_colorbar_pnr.json \
    --device GW1NR-LV9QN88PC6/I5 \
    --family GW1N-9C \
    --cst fpga/tang9k_lcd114_colorbar.cst
else
  HOME="$NEXTPNR_HOME" nextpnr-himbaechel \
    --json build/tang9k_lcd114_colorbar.json \
    --write build/tang9k_lcd114_colorbar_pnr.json \
    --device GW1NR-LV9QN88PC6/I5 \
    --vopt family=GW1N-9C \
    --vopt cst=fpga/tang9k_lcd114_colorbar.cst \
    --freq 27
fi

gowin_pack -d GW1N-9C -o build/tang9k_lcd114_colorbar.fs build/tang9k_lcd114_colorbar_pnr.json
