#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

cst_file="${LCD_CST:-fpga/tang9k_spi_lcd.cst}"

if [ ! -f "$cst_file" ]; then
  cat <<EOF
Missing LCD constraint file: $cst_file

Create it from the template and fill the actual LCD SPI pin locations:
  cp fpga/tang9k_spi_lcd.cst.example fpga/tang9k_spi_lcd.cst
  \$EDITOR fpga/tang9k_spi_lcd.cst

Required signals:
  lcd_sclk lcd_mosi lcd_cs_n lcd_dc lcd_rst_n lcd_bl
EOF
  exit 1
fi

if [ -f "$repo_root/.env/oss-cad-suite.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/.env/oss-cad-suite.env"
fi

mkdir -p build
mkdir -p build/.config
mkdir -p build/home

export XDG_CONFIG_HOME="$PWD/build/.config"
export NEXTPNR_HOME="$PWD/build/home"

yosys -p "read_verilog -sv rtl/lcd114_deepx_simple.sv fpga/tang9k_spi_lcd_top.sv; synth_gowin -top tang9k_spi_lcd_top -json build/tang9k_spi_lcd.json"

if command -v nextpnr-gowin >/dev/null 2>&1; then
  HOME="$NEXTPNR_HOME" nextpnr-gowin \
    --json build/tang9k_spi_lcd.json \
    --freq 27 \
    --write build/tang9k_spi_lcd_pnr.json \
    --device GW1NR-LV9QN88PC6/I5 \
    --family GW1N-9C \
    --cst "$cst_file"
else
  HOME="$NEXTPNR_HOME" nextpnr-himbaechel \
    --json build/tang9k_spi_lcd.json \
    --write build/tang9k_spi_lcd_pnr.json \
    --freq 27 \
    --device GW1NR-LV9QN88PC6/I5 \
    --vopt family=GW1N-9C \
    --vopt cst="$cst_file"
fi

gowin_pack -d GW1N-9C -o build/tang9k_spi_lcd.fs build/tang9k_spi_lcd_pnr.json
