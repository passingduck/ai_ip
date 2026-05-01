#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "apt-get not found. This script is for Ubuntu/Debian-like systems."
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  build-essential \
  ca-certificates \
  cmake \
  curl \
  git \
  make \
  pipx \
  pkg-config \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  swig \
  tar \
  xz-utils

echo
echo "Host dependencies installed."
echo "Next:"
echo "  scripts/install_oss_cad_suite.sh"
