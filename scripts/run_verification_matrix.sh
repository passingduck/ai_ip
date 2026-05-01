#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

scripts/run_python_tests.sh

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

scripts/run_verilator_lint.sh all
scripts/run_verilator_step_tests.sh
scripts/run_verilator_sim.sh
scripts/run_cocotb_tests.sh
scripts/run_picker.sh
scripts/run_toffee_picker_tests.sh
scripts/run_llm4dv_lfsr.sh

