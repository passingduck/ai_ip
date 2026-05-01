#!/usr/bin/env python3
import argparse
import sys
import time

try:
    import serial
except ImportError:
    print("missing Python package: pyserial", file=sys.stderr)
    print("Run: . .venv/bin/activate && pip install pyserial", file=sys.stderr)
    sys.exit(2)


def main() -> int:
    parser = argparse.ArgumentParser(description="Check learn-fpga FemtoRV UART hello output.")
    parser.add_argument("--port", default="/dev/ttyUSB1")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=5.0)
    args = parser.parse_args()

    deadline = time.monotonic() + args.timeout
    data = bytearray()

    with serial.Serial(args.port, args.baud, timeout=0.1) as ser:
        ser.reset_input_buffer()
        while time.monotonic() < deadline:
            chunk = ser.read(256)
            if chunk:
                data.extend(chunk)
                if b"Hello, world !" in data:
                    print(f"learn-fpga RISC-V UART PASS on {args.port}: Hello, world !")
                    return 0

    printable = bytes(data).decode("utf-8", errors="replace")
    print(f"learn-fpga RISC-V UART FAIL on {args.port}", file=sys.stderr)
    print(f"recv: {printable!r}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
