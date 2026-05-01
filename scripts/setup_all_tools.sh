#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
This script installs the host packages, OSS CAD Suite, and Picker/Toffee.
It uses sudo for apt packages and downloads tools from GitHub/PyPI.

Steps:
  1. scripts/install_ubuntu_deps.sh
  2. scripts/install_oss_cad_suite.sh
  3. source scripts/source_oss_cad_suite.sh
  4. scripts/install_picker_toffee.sh
EOF

scripts/install_ubuntu_deps.sh
scripts/install_oss_cad_suite.sh
# shellcheck disable=SC1091
source scripts/source_oss_cad_suite.sh
scripts/install_picker_toffee.sh

scripts/check_tools.sh

