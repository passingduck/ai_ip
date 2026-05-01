#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-BLKSEQ -Wno-UNUSEDSIGNAL \
  rtl/lcd114_colorbar_simple.sv \
  fpga/tang9k_lcd114_colorbar_top.sv \
  --top-module tang9k_lcd114_colorbar_top
