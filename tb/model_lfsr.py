from dataclasses import dataclass


def mask_for(width: int) -> int:
    if width < 2:
        raise ValueError("WIDTH must be at least 2")
    return (1 << width) - 1


def sanitize_seed(width: int, reset_seed: int, seed: int) -> int:
    mask = mask_for(width)
    reset = reset_seed & mask
    if reset == 0:
        reset = 1
    seed &= mask
    return reset if seed == 0 else seed


def lfsr_next(width: int, tap_mask: int, state: int, reset_seed: int) -> int:
    mask = mask_for(width)
    state &= mask
    if state == 0:
        return sanitize_seed(width, reset_seed, reset_seed)
    feedback = ((state & tap_mask).bit_count() & 1)
    return ((state << 1) & mask) | feedback


@dataclass
class LfsrModel:
    width: int = 16
    tap_mask: int = 0xB400
    reset_seed: int = 0xACE1

    def __post_init__(self) -> None:
        self.mask = mask_for(self.width)
        self.reset_seed &= self.mask
        self.tap_mask &= self.mask
        self.state = sanitize_seed(self.width, self.reset_seed, self.reset_seed)

    @property
    def bit(self) -> int:
        return (self.state >> (self.width - 1)) & 1

    @property
    def zero_state(self) -> bool:
        return self.state == 0

    def reset(self) -> int:
        self.state = sanitize_seed(self.width, self.reset_seed, self.reset_seed)
        return self.state

    def cycle(self, enable: bool = False, load_seed: bool = False, seed: int = 0) -> int:
        if load_seed:
            self.state = sanitize_seed(self.width, self.reset_seed, seed)
        elif enable:
            self.state = lfsr_next(self.width, self.tap_mask, self.state, self.reset_seed)
        return self.state

    def run_until_repeat(self, max_cycles: int | None = None) -> tuple[int, int]:
        seen: set[int] = set()
        limit = max_cycles if max_cycles is not None else (1 << self.width) + 1
        for _ in range(limit):
            if self.state in seen:
                return len(seen), self.state
            seen.add(self.state)
            self.cycle(enable=True)
        return len(seen), self.state


class LfsrCsrModel:
    CTRL = 0x00
    SEED = 0x04
    TAP_MASK = 0x08
    STATE = 0x0C
    STATUS = 0x10

    def __init__(self, width: int = 16, tap_mask: int = 0xB400, reset_seed: int = 0xACE1) -> None:
        self.width = width
        self.mask = mask_for(width)
        self.reset_seed = sanitize_seed(width, reset_seed, reset_seed)
        self.enable = False
        self.seed = self.reset_seed
        self.tap_mask = tap_mask & self.mask
        self.state = self.reset_seed
        self.loaded_seed = self.reset_seed
        self.period_done = False

    @property
    def zero_state(self) -> bool:
        return self.state == 0

    def reset(self) -> None:
        self.enable = False
        self.seed = self.reset_seed
        self.state = self.reset_seed
        self.loaded_seed = self.reset_seed
        self.period_done = False

    def write(self, addr: int, data: int) -> None:
        if addr == self.CTRL:
            self.enable = bool(data & 0x1)
            if data & 0x4:
                self.state = self.reset_seed
                self.loaded_seed = self.reset_seed
                self.period_done = False
            elif data & 0x2:
                self.state = self.seed
                self.loaded_seed = self.seed
                self.period_done = False
        elif addr == self.SEED:
            self.seed = sanitize_seed(self.width, self.reset_seed, data)
        elif addr == self.TAP_MASK:
            self.tap_mask = data & self.mask
            self.period_done = False

    def read(self, addr: int) -> int:
        if addr == self.CTRL:
            return int(self.enable)
        if addr == self.SEED:
            return self.seed
        if addr == self.TAP_MASK:
            return self.tap_mask
        if addr == self.STATE:
            return self.state
        if addr == self.STATUS:
            return (int(self.period_done) << 1) | int(self.zero_state)
        return 0

    def step(self) -> int:
        if self.enable:
            next_state = lfsr_next(self.width, self.tap_mask, self.state, self.reset_seed)
            self.state = next_state
            if next_state == self.loaded_seed:
                self.period_done = True
        return self.state
