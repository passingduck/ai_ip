#!/usr/bin/env python3
"""Host-side UART receive-only smoke test."""

import argparse
import os
import sys
import time

from test_uart_echo_host import configure_serial, detect_port, read_exact


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", default=None, help="serial device, for example /dev/ttyUSB1")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument("--expect", default="AIIP UART TX", help="ASCII substring to wait for")
    parser.add_argument("--timeout", type=float, default=3.0, help="read timeout in seconds")
    args = parser.parse_args()

    try:
        port = args.port or detect_port()
        fd = os.open(port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    except PermissionError as exc:
        print(f"permission denied opening serial port: {exc}", file=sys.stderr)
        print("Try: sudo usermod -aG dialout $USER, then log out/in.", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"failed to open serial port: {exc}", file=sys.stderr)
        return 1

    expected = args.expect.encode("ascii")
    received = bytearray()
    deadline = time.monotonic() + args.timeout

    try:
        configure_serial(fd, args.baud)
        while time.monotonic() < deadline and expected not in received:
            received.extend(read_exact(fd, 1, max(0.05, deadline - time.monotonic())))
    finally:
        os.close(fd)

    if expected not in received:
        printable = bytes(received).decode("ascii", errors="replace")
        print(f"UART receive mismatch on {port} @ {args.baud}")
        print(f"expected substring: {args.expect!r}")
        print(f"received hex: {bytes(received).hex()}")
        print(f"received text: {printable!r}")
        return 1

    printable = bytes(received).decode("ascii", errors="replace")
    print(f"UART receive PASS on {port} @ {args.baud}: {printable!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
