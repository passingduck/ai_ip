import unittest

from model_lfsr import LfsrCsrModel


class LfsrCsrModelTest(unittest.TestCase):
    def test_reset_and_csr_readback(self) -> None:
        dut = LfsrCsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

        self.assertEqual(dut.read(dut.CTRL), 0)
        self.assertEqual(dut.read(dut.SEED), 0xACE1)
        self.assertEqual(dut.read(dut.TAP_MASK), 0xB400)
        self.assertEqual(dut.read(dut.STATE), 0xACE1)
        self.assertEqual(dut.read(dut.STATUS), 0)

    def test_seed_load_enable_and_clear(self) -> None:
        dut = LfsrCsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

        dut.write(dut.SEED, 0x1234)
        dut.write(dut.CTRL, 0x2)
        self.assertEqual(dut.read(dut.STATE), 0x1234)

        dut.write(dut.CTRL, 0x1)
        self.assertEqual(dut.step(), 0x2469)

        dut.write(dut.CTRL, 0x4)
        self.assertEqual(dut.read(dut.STATE), 0xACE1)
        self.assertEqual(dut.read(dut.STATUS), 0)

    def test_zero_seed_is_sanitized(self) -> None:
        dut = LfsrCsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

        dut.write(dut.SEED, 0)
        dut.write(dut.CTRL, 0x2)

        self.assertEqual(dut.read(dut.SEED), 0xACE1)
        self.assertEqual(dut.read(dut.STATE), 0xACE1)

    def test_period_done_for_small_width(self) -> None:
        dut = LfsrCsrModel(width=4, tap_mask=0x9, reset_seed=0x1)

        dut.write(dut.CTRL, 0x1)
        for _ in range(15):
            dut.step()

        self.assertEqual(dut.read(dut.STATE), 0x1)
        self.assertEqual(dut.read(dut.STATUS), 0x2)


if __name__ == "__main__":
    unittest.main()

