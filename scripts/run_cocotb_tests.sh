#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

if ! command -v cocotb-config >/dev/null 2>&1; then
  echo "missing: cocotb-config"
  echo "OSS CAD Suite provides cocotb for this repo. Run: source scripts/source_oss_cad_suite.sh"
  exit 1
fi

make -C "$repo_root/tb/cocotb"

