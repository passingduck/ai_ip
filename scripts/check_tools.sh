#!/usr/bin/env bash
set -euo pipefail

missing=0

check_tool() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf "ok: %s -> %s\n" "$name" "$(command -v "$name")"
  else
    printf "missing: %s\n" "$name"
    missing=1
  fi
}

check_tool python3
check_tool verilator
check_tool yosys

if command -v nextpnr-gowin >/dev/null 2>&1; then
  printf "ok: nextpnr-gowin -> %s\n" "$(command -v nextpnr-gowin)"
elif command -v nextpnr-himbaechel >/dev/null 2>&1; then
  printf "ok: nextpnr-himbaechel -> %s\n" "$(command -v nextpnr-himbaechel)"
else
  printf "missing: nextpnr-gowin or nextpnr-himbaechel\n"
  missing=1
fi

check_tool gowin_pack
check_tool openFPGALoader

exit "$missing"

