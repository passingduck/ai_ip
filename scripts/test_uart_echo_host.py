#!/usr/bin/env python3
"""Host-side UART echo smoke test for the Tang Nano 9K UART PoC."""

import argparse
import glob
import os
import select
import sys
import termios
import time


def detect_port() -> str:
    candidates = []
    candidates.extend(sorted(glob.glob("/dev/ttyUSB*")))
    candidates.extend(sorted(glob.glob("/dev/ttyACM*")))

    # Tang Nano 9K exposes two FT2232 channels on many Linux setups. The second
    # ttyUSB device is usually the UART channel, while the first is often JTAG.
    for preferred in ("/dev/ttyUSB1", "/dev/ttyUSB0"):
        if preferred in candidates:
            return preferred
    if candidates:
        return candidates[0]
    raise RuntimeError("no /dev/ttyUSB* or /dev/ttyACM* serial port found")


def baud_constant(baud: int) -> int:
    name = f"B{baud}"
    if not hasattr(termios, name):
        raise RuntimeError(f"unsupported baud rate by termios: {baud}")
    return getattr(termios, name)


def configure_serial(fd: int, baud: int) -> None:
    attrs = termios.tcgetattr(fd)
    iflag, oflag, cflag, lflag, ispeed, ospeed, cc = attrs

    iflag = 0
    oflag = 0
    lflag = 0
    cflag = termios.CLOCAL | termios.CREAD | termios.CS8
    if hasattr(termios, "HUPCL"):
        cflag |= termios.HUPCL

    cc[termios.VMIN] = 0
    cc[termios.VTIME] = 0

    speed = baud_constant(baud)
    termios.tcsetattr(fd, termios.TCSANOW, [iflag, oflag, cflag, lflag, speed, speed, cc])
    termios.tcflush(fd, termios.TCIOFLUSH)


def read_exact(fd: int, count: int, timeout_s: float) -> bytes:
    deadline = time.monotonic() + timeout_s
    data = bytearray()
    while len(data) < count:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        readable, _, _ = select.select([fd], [], [], remaining)
        if not readable:
            continue
        chunk = os.read(fd, count - len(data))
        if chunk:
            data.extend(chunk)
    return bytes(data)


def drain_input(fd: int, quiet_s: float, timeout_s: float) -> bytes:
    deadline = time.monotonic() + timeout_s
    quiet_deadline = time.monotonic() + quiet_s
    data = bytearray()

    while time.monotonic() < deadline:
        wait_s = max(0.0, min(quiet_deadline, deadline) - time.monotonic())
        readable, _, _ = select.select([fd], [], [], wait_s)
        if not readable:
            break
        chunk = os.read(fd, 4096)
        if chunk:
            data.extend(chunk)
            quiet_deadline = time.monotonic() + quiet_s

    return bytes(data)


def read_until_contains(fd: int, needle: bytes, timeout_s: float, max_bytes: int) -> bytes:
    deadline = time.monotonic() + timeout_s
    data = bytearray()

    while time.monotonic() < deadline and needle not in data and len(data) < max_bytes:
        remaining = deadline - time.monotonic()
        readable, _, _ = select.select([fd], [], [], remaining)
        if not readable:
            continue
        chunk = os.read(fd, min(4096, max_bytes - len(data)))
        if chunk:
            data.extend(chunk)

    return bytes(data)


def parse_payload(text: str) -> bytes:
    cleaned = text.replace(" ", "").replace("_", "")
    if len(cleaned) % 2 != 0:
        raise argparse.ArgumentTypeError("hex payload must have an even number of digits")
    try:
        return bytes.fromhex(cleaned)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", default=None, help="serial device, for example /dev/ttyUSB1")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument(
        "--payload",
        type=parse_payload,
        default=parse_payload("55aa003cc3817e"),
        help="hex bytes to send and expect back",
    )
    parser.add_argument("--timeout", type=float, default=2.0, help="read timeout in seconds")
    parser.add_argument("--drain-timeout", type=float, default=1.0, help="input drain timeout before sending")
    parser.add_argument("--quiet", type=float, default=0.2, help="required quiet time while draining")
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
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    try:
        configure_serial(fd, args.baud)
        drained = drain_input(fd, args.quiet, args.drain_timeout)
        if drained:
            print(f"drained stale serial input before test: {drained.hex()}")
        time.sleep(0.05)
        os.write(fd, args.payload)
        echo = read_until_contains(fd, args.payload, args.timeout, max(256, len(args.payload) * 8))
    finally:
        os.close(fd)

    if args.payload not in echo:
        print(f"UART echo mismatch on {port} @ {args.baud}")
        print(f"sent: {args.payload.hex()}")
        print(f"recv: {echo.hex()}")
        return 1

    print(f"UART echo PASS on {port} @ {args.baud}: {echo.hex()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
