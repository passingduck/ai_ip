import random
import unittest

from coverage_lfsr import LfsrCoverage
from model_lfsr import LfsrModel


class ConfigurableLfsrRandomTest(unittest.TestCase):
    def test_maximal_period_for_small_width(self) -> None:
        dut = LfsrModel(width=4, tap_mask=0x9, reset_seed=0x1)

        period, repeated = dut.run_until_repeat()

        self.assertEqual(period, 15)
        self.assertEqual(repeated, 0x1)

    def test_random_control_stream_reaches_coverage_bins(self) -> None:
        rng = random.Random(20260501)
        dut = LfsrModel(width=8, tap_mask=0x8E, reset_seed=0x5A)
        cov = LfsrCoverage(width=8)
        cov.mark("reset_observed")
        initial_seed = dut.state

        for cycle in range(512):
            if cycle == 30:
                dut.reset()
                cov.mark("random_reset_during_run")
            load_seed = cycle in {5, 77} or rng.randrange(25) == 0
            seed = 0 if cycle == 5 else rng.randrange(1, 256)
            enable = rng.choice([False, True, True])

            before = dut.state
            after = dut.cycle(enable=enable, load_seed=load_seed, seed=seed)

            if not enable and not load_seed:
                self.assertEqual(after, before)
                cov.mark("enable_hold_observed")
            if load_seed:
                cov.mark("load_seed_observed")
                cov.mark("random_load_during_run")
                cov.mark("zero_seed_observed" if seed == 0 else "non_zero_seed_observed")
            if after == initial_seed and cycle > 0:
                cov.mark("state_returned_to_initial_seed")

            cov.sample_state(dut.state, dut.bit)

        period_dut = LfsrModel(width=8, tap_mask=0x8E, reset_seed=0x5A)
        period, repeated = period_dut.run_until_repeat()
        if period == 255 and repeated == 0x5A:
            cov.mark("period_reached")

        self.assertEqual(cov.missing(), set())

    def test_bug_injection_missing_tap_is_detected(self) -> None:
        golden = LfsrModel(width=8, tap_mask=0x8E, reset_seed=0x5A)
        buggy = LfsrModel(width=8, tap_mask=0x86, reset_seed=0x5A)

        mismatch_cycle = None
        for cycle in range(32):
            g_state = golden.cycle(enable=True)
            b_state = buggy.cycle(enable=True)
            if g_state != b_state:
                mismatch_cycle = cycle + 1
                break

        self.assertIsNotNone(mismatch_cycle)


if __name__ == "__main__":
    unittest.main()

