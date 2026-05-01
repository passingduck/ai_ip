#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ ! -f build/tang9k_lcd114_colorbar.fs ]; then
  scripts/run_synth_lcd114_colorbar.sh
fi

scripts/program_tang9k.sh "$@" build/tang9k_lcd114_colorbar.fs
