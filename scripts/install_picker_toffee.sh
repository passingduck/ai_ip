#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tools_dir="$repo_root/tools"
venv_dir="$repo_root/.venv"
picker_dir="$tools_dir/picker"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

need_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing: $1"
    echo "Install host dependencies first: scripts/install_ubuntu_deps.sh"
    echo "Install OSS CAD Suite first: scripts/install_oss_cad_suite.sh"
    exit 1
  fi
}

need_tool git
need_tool cmake
need_tool make
need_tool pipx
need_tool swig
need_tool verilator
need_tool python3

if ! python3 -m pip --version >/dev/null 2>&1; then
  echo "missing: python3 pip"
  echo "Install it with: scripts/install_ubuntu_deps.sh"
  exit 1
fi

mkdir -p "$tools_dir"

if [ ! -d "$picker_dir/.git" ]; then
  git clone https://github.com/XS-MLVP/picker.git "$picker_dir" --depth=1
fi

cd "$picker_dir"
make init
make BUILD_XSPCOMM_SWIG=python
make BUILD_XSPCOMM_SWIG=python wheel

cd "$repo_root"
python3 -m venv "$venv_dir"
# shellcheck disable=SC1091
source "$venv_dir/bin/activate"
python -m pip install --upgrade pip
python -m pip install "$picker_dir"/dist/*.whl
python -m pip install pytoffee

echo
echo "Picker/Toffee installed in: $venv_dir"
echo "For this shell, run:"
echo "  source .venv/bin/activate"
echo "  source scripts/source_oss_cad_suite.sh"
echo
echo "Then verify:"
echo "  picker --check"
echo "  scripts/run_picker.sh"
echo "  scripts/run_toffee_tests.sh"
