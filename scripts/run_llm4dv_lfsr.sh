#!/usr/bin/env bash
set -euo pipefail

python3 tb/llm4dv_lfsr/generate_stimulus.py
python3 tb/llm4dv_lfsr/run_stimulus.py

