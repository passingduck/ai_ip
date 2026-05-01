#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

use_sudo=0
if [ "${1:-}" = "--sudo" ]; then
  use_sudo=1
fi

if [ ! -f build/tang9k_rtos_soc.fs ]; then
  scripts/run_synth_rtos_soc.sh
fi

if [ "$use_sudo" -eq 1 ]; then
  scripts/program_tang9k.sh --sudo build/tang9k_rtos_soc.fs
else
  scripts/program_tang9k.sh build/tang9k_rtos_soc.fs
fi
