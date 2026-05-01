#!/usr/bin/env bash
set -euo pipefail

if [ ! -f build/tang9k_spi_lcd.fs ]; then
  scripts/run_synth_spi_lcd.sh
fi

scripts/program_tang9k.sh "$@" build/tang9k_spi_lcd.fs
