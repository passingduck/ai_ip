#!/usr/bin/env bash
# Source this file, do not execute it:
#   source scripts/source_oss_cad_suite.sh

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
elif [ -f "$HOME/opt/oss-cad-suite/environment" ]; then
  # shellcheck disable=SC1091
  source "$HOME/opt/oss-cad-suite/environment"
else
  echo "OSS CAD Suite environment not found."
  echo "Run: scripts/install_oss_cad_suite.sh"
  return 1 2>/dev/null || exit 1
fi

echo "OSS CAD Suite active: ${OSS_CAD_SUITE:-unknown}"

