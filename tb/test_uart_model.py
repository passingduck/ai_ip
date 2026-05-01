import unittest

from model_uart import uart_decode_frame, uart_frame_bits


class UartModelTest(unittest.TestCase):
    def test_frame_is_8n1_lsb_first(self) -> None:
        self.assertEqual(uart_frame_bits(0xA5), [0, 1, 0, 1, 0, 0, 1, 0, 1, 1])

    def test_decode_valid_frame(self) -> None:
        value, valid = uart_decode_frame(uart_frame_bits(0x3C))

        self.assertTrue(valid)
        self.assertEqual(value, 0x3C)

    def test_decode_framing_error(self) -> None:
        bits = uart_frame_bits(0x55)
        bits[-1] = 0

        _, valid = uart_decode_frame(bits)

        self.assertFalse(valid)


if __name__ == "__main__":
    unittest.main()

