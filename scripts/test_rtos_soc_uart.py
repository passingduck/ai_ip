#!/usr/bin/env python3
import argparse
import sys
import time

try:
    import serial
except ImportError:
    print("missing Python package: pyserial", file=sys.stderr)
    print("Install: python3 -m pip install --user pyserial", file=sys.stderr)
    raise


def main() -> int:
    parser = argparse.ArgumentParser(description="Check RTOS SoC UART boot banner.")
    parser.add_argument("--port", default="/dev/ttyUSB1")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=5.0)
    args = parser.parse_args()

    expected = b"RTOS LCD counter boot\r\n"
    deadline = time.monotonic() + args.timeout
    data = bytearray()

    with serial.Serial(args.port, args.baud, timeout=0.1) as ser:
        ser.reset_input_buffer()
        while time.monotonic() < deadline:
            chunk = ser.read(128)
            if chunk:
                data.extend(chunk)
                if expected in data:
                    print(f"RTOS SoC UART PASS on {args.port} @ {args.baud}: {expected!r}")
                    return 0

    print(f"RTOS SoC UART FAIL on {args.port} @ {args.baud}", file=sys.stderr)
    print(f"expected: {expected!r}", file=sys.stderr)
    print(f"received: {bytes(data)!r}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
