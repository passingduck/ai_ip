#!/usr/bin/env bash
set -euo pipefail

rtl_file="${1:-rtl/configurable_lfsr.sv}"

if [ "$rtl_file" = "all" ]; then
  verilator --lint-only --timing -Wall rtl/configurable_lfsr.sv rtl/lfsr8.sv --top-module lfsr8
  verilator --lint-only --timing -Wall rtl/configurable_lfsr.sv rtl/lfsr16.sv --top-module lfsr16
  verilator --lint-only --timing -Wall rtl/configurable_lfsr.sv
  verilator --lint-only --timing -Wall rtl/lfsr_csr.sv
else
  verilator --lint-only --timing -Wall "$rtl_file"
fi
