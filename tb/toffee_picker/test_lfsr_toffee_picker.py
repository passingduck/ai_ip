import unittest

from configurable_lfsr import DUTconfigurable_lfsr
from model_lfsr import LfsrModel
from toffee import CovEq, CovGroup


def full_cycle(dut) -> None:
    dut.clk.value = 0
    dut.Step(1)
    dut.clk.value = 1
    dut.Step(1)


def pin_int(pin) -> int:
    return int(pin.value)


class ToffeePickerLfsrTest(unittest.TestCase):
    def setUp(self) -> None:
        self.dut = DUTconfigurable_lfsr()
        self.model = LfsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

    def tearDown(self) -> None:
        self.dut.Finish()

    def reset(self) -> None:
        self.dut.rst_n.value = 0
        self.dut.enable.value = 0
        self.dut.load_seed.value = 0
        self.dut.seed_i.value = 0
        full_cycle(self.dut)
        self.model.reset()
        self.assertEqual(pin_int(self.dut.state_o), self.model.state)
        self.dut.rst_n.value = 1

    def test_picker_dut_matches_golden_model(self) -> None:
        self.reset()

        self.dut.enable.value = 1
        for _ in range(16):
            full_cycle(self.dut)
            self.model.cycle(enable=True)
            self.assertEqual(pin_int(self.dut.state_o), self.model.state)
            self.assertEqual(pin_int(self.dut.bit_o), self.model.bit)

    def test_load_zero_hold_and_toffee_coverage(self) -> None:
        self.reset()
        cov = CovGroup("lfsr_picker_functional_coverage")
        cov.add_cover_point(
            self.dut.bit_o,
            {"bit_o_zero": CovEq(0), "bit_o_one": CovEq(1)},
            name="bit_o_values",
            once=False,
        )
        cov.add_cover_point(
            self.dut.zero_state_o,
            {"zero_state_never_observed": CovEq(0)},
            name="zero_state_policy",
            once=False,
        )

        self.dut.load_seed.value = 1
        self.dut.seed_i.value = 0
        self.dut.enable.value = 1
        full_cycle(self.dut)
        self.model.cycle(enable=True, load_seed=True, seed=0)
        self.assertEqual(pin_int(self.dut.state_o), self.model.state)
        cov.sample()

        self.dut.load_seed.value = 0
        self.dut.enable.value = 0
        held = pin_int(self.dut.state_o)
        for _ in range(4):
            full_cycle(self.dut)
            self.model.cycle(enable=False)
            self.assertEqual(pin_int(self.dut.state_o), held)
            cov.sample()

        self.dut.enable.value = 1
        for _ in range(64):
            full_cycle(self.dut)
            self.model.cycle(enable=True)
            self.assertEqual(pin_int(self.dut.state_o), self.model.state)
            cov.sample()

        self.assertTrue(cov.is_all_covered(), cov.as_dict())


if __name__ == "__main__":
    unittest.main()
