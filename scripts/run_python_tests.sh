#!/usr/bin/env bash
set -euo pipefail

python3 -m unittest discover -s tb -p 'test_*.py'

