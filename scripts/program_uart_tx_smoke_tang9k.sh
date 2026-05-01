#!/usr/bin/env bash
set -euo pipefail

if [ ! -f build/tang9k_uart_tx_smoke.fs ]; then
  scripts/run_synth_uart_tx_smoke.sh
fi

scripts/program_tang9k.sh "$@" build/tang9k_uart_tx_smoke.fs
