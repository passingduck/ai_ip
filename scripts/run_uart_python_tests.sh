#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHONPATH="$repo_root/tb:${PYTHONPATH:-}" python3 -m unittest tb/test_uart_model.py
