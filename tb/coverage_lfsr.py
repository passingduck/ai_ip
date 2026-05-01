class LfsrCoverage:
    REQUIRED_BINS = {
        "reset_observed",
        "enable_hold_observed",
        "load_seed_observed",
        "zero_seed_observed",
        "non_zero_seed_observed",
        "all_state_bits_toggled",
        "bit_o_zero_observed",
        "bit_o_one_observed",
        "state_returned_to_initial_seed",
        "period_reached",
        "random_reset_during_run",
        "random_load_during_run",
    }

    def __init__(self, width: int) -> None:
        self.width = width
        self.bins: set[str] = set()
        self._or_bits = 0
        self._and_bits = (1 << width) - 1

    def sample_state(self, state: int, bit: int) -> None:
        self._or_bits |= state
        self._and_bits &= state
        if bit == 0:
            self.bins.add("bit_o_zero_observed")
        else:
            self.bins.add("bit_o_one_observed")
        if self._or_bits == (1 << self.width) - 1 and self._and_bits == 0:
            self.bins.add("all_state_bits_toggled")

    def mark(self, name: str) -> None:
        self.bins.add(name)

    def missing(self) -> set[str]:
        return self.REQUIRED_BINS - self.bins

    def ratio(self) -> float:
        return len(self.bins & self.REQUIRED_BINS) / len(self.REQUIRED_BINS)

