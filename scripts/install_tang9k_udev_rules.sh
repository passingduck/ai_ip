#!/usr/bin/env bash
set -euo pipefail

rule_file="/etc/udev/rules.d/99-tangnano9k.rules"

if ! command -v sudo >/dev/null 2>&1; then
  echo "missing: sudo"
  exit 1
fi

cat <<'EOF' | sudo tee "$rule_file" >/dev/null
# Tang Nano 9K FT2232 JTAG/UART interface
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE="0666", TAG+="uaccess"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

cat <<EOF
Installed: $rule_file

Unplug and reconnect Tang Nano 9K, then verify:
  source scripts/source_oss_cad_suite.sh
  openFPGALoader -b tangnano9k --detect

After this, programming should work without sudo:
  scripts/program_tang9k.sh
EOF

