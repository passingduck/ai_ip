#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ ! -f build/learn_fpga_riscv_step20_hello.fs ]; then
  scripts/run_synth_learn_fpga_riscv.sh
fi

scripts/program_tang9k.sh "$@" build/learn_fpga_riscv_step20_hello.fs
