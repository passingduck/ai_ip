import unittest

from model_lfsr import LfsrModel, sanitize_seed


class ConfigurableLfsrBasicTest(unittest.TestCase):
    def test_reset_uses_reset_seed(self) -> None:
        dut = LfsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

        self.assertEqual(dut.reset(), 0xACE1)
        self.assertFalse(dut.zero_state)

    def test_enable_low_holds_state(self) -> None:
        dut = LfsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)
        before = dut.state

        for _ in range(8):
            self.assertEqual(dut.cycle(enable=False), before)

    def test_load_seed_takes_priority_over_enable(self) -> None:
        dut = LfsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

        self.assertEqual(dut.cycle(enable=True, load_seed=True, seed=0x1234), 0x1234)

    def test_zero_seed_recovers_to_reset_seed(self) -> None:
        dut = LfsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

        self.assertEqual(dut.cycle(load_seed=True, seed=0), 0xACE1)

    def test_zero_reset_seed_is_sanitized_to_one(self) -> None:
        self.assertEqual(sanitize_seed(width=8, reset_seed=0, seed=0), 1)

    def test_known_sequence_matches_left_shift_b400(self) -> None:
        dut = LfsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

        observed = [dut.state]
        for _ in range(7):
            observed.append(dut.cycle(enable=True))

        self.assertEqual(
            observed,
            [0xACE1, 0x59C3, 0xB387, 0x670F, 0xCE1E, 0x9C3C, 0x3879, 0x70F2],
        )


if __name__ == "__main__":
    unittest.main()
