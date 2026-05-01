def uart_frame_bits(byte: int) -> list[int]:
    byte &= 0xFF
    return [0] + [(byte >> bit) & 1 for bit in range(8)] + [1]


def uart_decode_frame(bits: list[int]) -> tuple[int, bool]:
    if len(bits) != 10:
        raise ValueError("UART 8N1 frame must contain 10 bits")
    if bits[0] != 0:
        return 0, False
    if bits[9] != 1:
        return 0, False
    value = 0
    for bit in range(8):
        value |= (bits[bit + 1] & 1) << bit
    return value, True

