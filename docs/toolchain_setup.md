# Toolchain Setup Notes

## Current Baseline

The repo intentionally keeps the first regression dependency-free:

```bash
scripts/run_python_tests.sh
```

For RTL lint/simulation and Tang Nano 9K hardware tests, install these tools:

- `verilator`
- `yosys`
- `nextpnr-gowin` or `nextpnr-himbaechel`
- `gowin_pack`
- `openFPGALoader`

Check the environment with:

```bash
scripts/check_tools.sh
```

## One-Command Setup

For Ubuntu/Debian-like machines:

```bash
scripts/setup_all_tools.sh
```

That script installs host packages, downloads OSS CAD Suite, activates it for the script process, then builds Picker and installs Toffee into `.venv`.

If you prefer step-by-step installation:

```bash
scripts/install_ubuntu_deps.sh
scripts/install_oss_cad_suite.sh
source scripts/source_oss_cad_suite.sh
scripts/install_picker_toffee.sh
source .venv/bin/activate
scripts/check_tools.sh
```

## Open-Source Tang Nano 9K Flow

The synthesis flow in `scripts/run_synth.sh` follows the usual Gowin open-source chain:

```text
SystemVerilog -> yosys synth_gowin -> JSON
JSON -> nextpnr-gowin/nextpnr-himbaechel -> routed JSON
routed JSON -> gowin_pack -> .fs bitstream
.fs -> openFPGALoader -> Tang Nano 9K
```

The board target is:

```text
family: GW1N-9C
device: GW1NR-LV9QN88PC6/I5
board:  tangnano9k
clock:  27 MHz
```

## Toffee/Picker Path

Picker converts RTL into a software-callable DUT library, and Toffee builds the Python verification environment on top of that generated package.

Required before trying this path:

- `cmake >= 3.11`
- GCC with C++20 support
- Python 3.8+
- `pipx`, used by Picker's wheel build
- Verilator, with the Picker docs currently naming `4.218`
- `verible-verilog-format`
- `swig >= 4.2.0` for multi-language bindings
- Picker installed and visible on `PATH`
- `pytoffee` installed after Picker

Once Picker is installed, use:

```bash
scripts/run_picker.sh
scripts/run_toffee_tests.sh
```

The scripts currently fail fast with a clear message when Picker or Toffee is not installed.

## References

- Apycula Gowin flow and Tang Nano 9K support: https://github.com/YosysHQ/apicula
- Tang Nano 9K manual open-source flow: https://learn.lushaylabs.com/os-toolchain-manual-installation/
- Tang Nano 9K pinout summary: https://7-bit.xyz/guides/tang-nano-9k/
- Picker setup: https://open-verify.cc/mlvp/en/docs/quick-start/installer/
- Toffee package notes: https://pypi.org/project/pytoffee/
