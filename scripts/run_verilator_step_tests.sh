#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

mkdir -p build/verilator

verilator -Wall --cc rtl/configurable_lfsr.sv rtl/lfsr8.sv \
  --top-module lfsr8 \
  --exe tb/verilator_lfsr8_tb.cpp \
  --Mdir build/verilator/lfsr8
make -C build/verilator/lfsr8 -f Vlfsr8.mk Vlfsr8
build/verilator/lfsr8/Vlfsr8

verilator -Wall --cc rtl/configurable_lfsr.sv rtl/lfsr16.sv \
  --top-module lfsr16 \
  --exe tb/verilator_lfsr16_tb.cpp \
  --Mdir build/verilator/lfsr16
make -C build/verilator/lfsr16 -f Vlfsr16.mk Vlfsr16
build/verilator/lfsr16/Vlfsr16

verilator -Wall --cc rtl/lfsr_csr.sv \
  --top-module lfsr_csr \
  -GWIDTH=4 \
  "-GRESET_SEED=4'h1" \
  "-GRESET_TAP_MASK=4'h9" \
  --exe tb/verilator_lfsr_csr_tb.cpp \
  --Mdir build/verilator/lfsr_csr_w4
make -C build/verilator/lfsr_csr_w4 -f Vlfsr_csr.mk Vlfsr_csr
build/verilator/lfsr_csr_w4/Vlfsr_csr
