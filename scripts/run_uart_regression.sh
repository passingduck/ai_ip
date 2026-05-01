#!/usr/bin/env bash
set -euo pipefail

scripts/run_uart_python_tests.sh
scripts/run_uart_lint.sh
scripts/run_uart_verilator_tests.sh
scripts/run_uart_cocotb_tests.sh

