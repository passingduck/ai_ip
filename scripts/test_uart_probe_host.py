#!/usr/bin/env python3
"""Host-side UART probe for heartbeat and RX acknowledgement."""

import argparse
import os
import sys
import time

from test_uart_echo_host import configure_serial, detect_port, parse_payload, read_exact


def read_until(fd: int, needle: bytes, timeout_s: float) -> bytes:
    deadline = time.monotonic() + timeout_s
    data = bytearray()
    while time.monotonic() < deadline and needle not in data:
        data.extend(read_exact(fd, 1, max(0.05, deadline - time.monotonic())))
    return bytes(data)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", default=None, help="serial device, for example /dev/ttyUSB1")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument("--payload", type=parse_payload, default=parse_payload("55"), help="hex byte(s) to send")
    parser.add_argument("--timeout", type=float, default=3.0, help="timeout in seconds for each phase")
    args = parser.parse_args()

    if not args.payload:
        print("payload must contain at least one byte", file=sys.stderr)
        return 1

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

    try:
        configure_serial(fd, args.baud)
        heartbeat = read_until(fd, b"RDY\r\n", args.timeout)
        if b"RDY\r\n" not in heartbeat:
            print(f"UART probe heartbeat missing on {port} @ {args.baud}")
            print(f"received hex: {heartbeat.hex()}")
            print(f"received text: {heartbeat.decode('ascii', errors='replace')!r}")
            return 1

        first_byte = args.payload[:1]
        expected_ack = f"RX {first_byte[0]:02X}\r\n".encode("ascii")
        os.write(fd, first_byte)
        ack = read_until(fd, expected_ack, args.timeout)
    finally:
        os.close(fd)

    if expected_ack not in ack:
        print(f"UART probe RX ACK missing on {port} @ {args.baud}")
        print(f"expected: {expected_ack.decode('ascii', errors='replace')!r}")
        print(f"received hex: {ack.hex()}")
        print(f"received text: {ack.decode('ascii', errors='replace')!r}")
        return 1

    print(f"UART probe PASS on {port} @ {args.baud}: heartbeat and {expected_ack!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
