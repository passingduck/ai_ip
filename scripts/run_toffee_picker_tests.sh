#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

if [ -f "$repo_root/.venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.venv/bin/activate"
else
  echo "missing: .venv"
  echo "Run: scripts/install_picker_toffee.sh"
  exit 1
fi

python3 - <<'PY'
import importlib
for name in ("toffee", "picker"):
    importlib.import_module(name)
PY

if [ ! -f build/picker/configurable_lfsr/__init__.py ]; then
  scripts/run_picker.sh
fi

PYTHONPATH="$repo_root/build/picker:$repo_root/tb:${PYTHONPATH:-}" \
  python -m unittest discover -s tb/toffee_picker -p 'test_*.py'

