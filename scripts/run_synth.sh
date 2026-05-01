#!/usr/bin/env bash
set -euo pipefail

mkdir -p build
mkdir -p build/.config
mkdir -p build/home

export XDG_CONFIG_HOME="$PWD/build/.config"
export NEXTPNR_HOME="$PWD/build/home"

yosys -p "read_verilog -sv rtl/configurable_lfsr.sv fpga/tang9k_top.sv; synth_gowin -top top -json build/tang9k_lfsr.json"

if command -v nextpnr-gowin >/dev/null 2>&1; then
  HOME="$NEXTPNR_HOME" nextpnr-gowin \
    --json build/tang9k_lfsr.json \
    --freq 27 \
    --write build/tang9k_lfsr_pnr.json \
    --device GW1NR-LV9QN88PC6/I5 \
    --family GW1N-9C \
    --cst fpga/tang9k.cst
else
  HOME="$NEXTPNR_HOME" nextpnr-himbaechel \
    --json build/tang9k_lfsr.json \
    --write build/tang9k_lfsr_pnr.json \
    --device GW1NR-LV9QN88PC6/I5 \
    --vopt family=GW1N-9C \
    --vopt cst=fpga/tang9k.cst
fi

gowin_pack -d GW1N-9C -o build/tang9k_lfsr.fs build/tang9k_lfsr_pnr.json
