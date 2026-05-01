#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$repo_root/tools/learn-fpga/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV"
fw_dir="$work_dir/FIRMWARE"
out_fs="$repo_root/build/learn_fpga_riscv_step20_hello.fs"

cd "$repo_root"

if [ ! -d tools/learn-fpga ]; then
  echo "missing: tools/learn-fpga"
  echo "Run: git clone --depth 1 https://github.com/BrunoLevy/learn-fpga.git tools/learn-fpga"
  exit 1
fi

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

cat > "$repo_root/tools/learn-fpga/FemtoRV/FIRMWARE/config.mk" <<'EOF'
ARCH=rv32i
ABI=ilp32
OPTIMIZE=-Os
DEVICES=-DICE_STICK
BOARD=icestick
EOF

if ! grep -q 'NO_PLL' "$work_dir/clockworks.v"; then
  echo "missing local NO_PLL patch in $work_dir/clockworks.v"
  echo "This patch bypasses the upstream Tang Nano 9K PLL wrapper for oss-cad-suite."
  exit 1
fi

make -C "$fw_dir" hello.bram.hex

mkdir -p "$repo_root/build/learn_fpga_riscv/.config"
mkdir -p "$repo_root/build/learn_fpga_riscv/home"

export XDG_CONFIG_HOME="$repo_root/build/learn_fpga_riscv/.config"
export NEXTPNR_HOME="$repo_root/build/learn_fpga_riscv/home"

cd "$work_dir"

yosys -q \
  -DTANGNANO9K \
  -DNO_PLL \
  -DBOARD_FREQ=27 \
  -DCPU_FREQ=27 \
  -p "synth_gowin -top SOC -json SOC.json" \
  step20.v

HOME="$NEXTPNR_HOME" nextpnr-himbaechel \
  --force \
  --json SOC.json \
  --vopt cst=BOARDS/tangnano9k.cst \
  --write pnr_SOC.json \
  --device GW1NR-LV9QN88PC6/I5 \
  --vopt family=GW1N-9C \
  --freq 27

gowin_pack -d GW1N-9C -o SOC.fs pnr_SOC.json
cp SOC.fs "$out_fs"

echo "Wrote $out_fs"
