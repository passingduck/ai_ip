#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ ! -f "$repo_root/.venv/bin/activate" ]; then
  echo "missing: .venv"
  echo "Run: scripts/install_picker_toffee.sh"
  exit 1
fi

# shellcheck disable=SC1091
source "$repo_root/.venv/bin/activate"

python -m pip install --upgrade pip
python -m pip install 'git+https://github.com/XS-MLVP/UCAgent@main'

ucagent --help

