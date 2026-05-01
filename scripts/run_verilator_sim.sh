#!/usr/bin/env bash
set -euo pipefail

verilator -Wall --cc rtl/configurable_lfsr.sv --exe tb/verilator_lfsr_tb.cpp
make -C obj_dir -f Vconfigurable_lfsr.mk Vconfigurable_lfsr
./obj_dir/Vconfigurable_lfsr

