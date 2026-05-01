#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
Recommended installation path:

1. Install OSS CAD Suite for Linux and add it to PATH.
   It normally provides yosys, nextpnr-gowin or nextpnr-himbaechel,
   gowin_pack, openFPGALoader, and verilator.

2. Verify:
   scripts/check_tools.sh

3. Run local verification:
   scripts/run_python_tests.sh
   scripts/run_verilator_lint.sh
   scripts/run_verilator_sim.sh

4. Build and program Tang Nano 9K:
   scripts/run_synth.sh
   scripts/program_tang9k.sh

Optional Toffee/Picker flow:
   Picker currently expects a specific native build environment
   including cmake, GCC with C++20, SWIG, Verilator, and Python.
   After those exist, install Picker and pytoffee according to the
   XS-MLVP documentation and replace the Verilator C++ smoke test with
   a Picker-generated Python DUT package.
EOF

