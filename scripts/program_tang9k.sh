#!/usr/bin/env bash
set -euo pipefail

use_sudo=0
bitstream="build/tang9k_lfsr.fs"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --sudo)
      use_sudo=1
      shift
      ;;
    --help)
  cat <<'EOF'
Usage:
  scripts/program_tang9k.sh [--sudo] [bitstream.fs]

Programs a bitstream to Tang Nano 9K SRAM.
Use --sudo when USB permissions are not configured for the current user.
EOF
      exit 0
      ;;
    *.fs)
      bitstream="$1"
      shift
      ;;
    *)
      echo "unknown argument: $1"
      echo "Run scripts/program_tang9k.sh --help"
      exit 2
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

if [ "$bitstream" = "build/tang9k_lfsr.fs" ] && [ ! -f "$bitstream" ]; then
  scripts/run_synth.sh
fi

if [ ! -f "$bitstream" ]; then
  echo "missing bitstream: $bitstream"
  exit 1
fi

loader="$(command -v openFPGALoader || true)"
if [ -z "$loader" ]; then
  echo "missing: openFPGALoader"
  echo "Run: source scripts/source_oss_cad_suite.sh"
  exit 1
fi

if [ "$use_sudo" -eq 1 ]; then
  sudo "$loader" -b tangnano9k "$bitstream"
else
  "$loader" -b tangnano9k "$bitstream"
fi
