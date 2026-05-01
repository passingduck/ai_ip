#!/usr/bin/env bash
set -euo pipefail

force=0
if [ "${1:-}" = "--force" ]; then
  force=1
elif [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/run_picker.sh [--force]

Generates build/picker/configurable_lfsr from rtl/configurable_lfsr.sv.
Without --force, an existing generated package is reused.
EOF
  exit 0
elif [ "${1:-}" != "" ]; then
  echo "unknown argument: $1"
  echo "Run scripts/run_picker.sh --help"
  exit 2
fi

if ! command -v picker >/dev/null 2>&1; then
  echo "missing: picker"
  echo "Install Picker first. See docs/toolchain_setup.md."
  exit 1
fi

mkdir -p build/picker
target_dir="build/picker/configurable_lfsr"

if [ -e "$target_dir" ] && [ "$force" -eq 0 ]; then
  echo "Picker package already exists: $target_dir"
  echo "Use scripts/run_picker.sh --force to regenerate it."
  exit 0
fi

if [ -e "$target_dir" ]; then
  rm -rf "$target_dir"
fi

picker export \
  --language python \
  --sim verilator \
  --target_dir "$target_dir" \
  --source_module_name configurable_lfsr \
  --target_module_name configurable_lfsr \
  rtl/configurable_lfsr.sv
