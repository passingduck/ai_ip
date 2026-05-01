#!/usr/bin/env bash
set -euo pipefail

use_sudo=0
serial_sudo=0
skip_program=0
port_args=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --sudo)
      use_sudo=1
      shift
      ;;
    --serial-sudo)
      serial_sudo=1
      shift
      ;;
    --skip-program)
      skip_program=1
      shift
      ;;
    --port)
      port_args+=(--port "$2")
      shift 2
      ;;
    --baud)
      port_args+=(--baud "$2")
      shift 2
      ;;
    --payload)
      port_args+=(--payload "$2")
      shift 2
      ;;
    --help)
      cat <<'EOF'
Usage:
  scripts/run_uart_board_test.sh [--sudo] [--serial-sudo] [--skip-program] [--port /dev/ttyUSB1] [--baud 115200] [--payload HEX]

Builds the UART bitstream when needed, programs Tang Nano 9K SRAM, then checks
the FPGA UART echo path from the host serial port.

Use --sudo when openFPGALoader cannot access the JTAG interface without sudo.
Use --serial-sudo when the current user is not in the dialout group yet.
Use --skip-program after the UART bitstream has already been uploaded.
EOF
      exit 0
      ;;
    *)
      echo "unknown argument: $1"
      echo "Run scripts/run_uart_board_test.sh --help"
      exit 2
      ;;
  esac
done

if [ "$skip_program" -eq 0 ]; then
  if [ ! -f build/tang9k_uart.fs ]; then
    scripts/run_synth_uart.sh
  fi

  if [ "$use_sudo" -eq 1 ]; then
    scripts/program_uart_tang9k.sh --sudo
  else
    scripts/program_uart_tang9k.sh
  fi

  sleep 0.5
fi

if [ "$serial_sudo" -eq 1 ]; then
  sudo scripts/test_uart_echo_host.py "${port_args[@]}"
else
  scripts/test_uart_echo_host.py "${port_args[@]}"
fi
