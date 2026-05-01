# ADR-0001: LFSR Shift Convention

## Status

Accepted

## Context

The PoC needs one unambiguous interpretation of `TAP_MASK` so RTL, Python golden model, and tests agree. The common `16'hB400` tap mask is maximal-length for a left-shifting Fibonacci LFSR when feedback is the parity of `state & TAP_MASK`.

## Decision

Use a left-shifting Fibonacci LFSR:

```text
feedback = parity(state & TAP_MASK)
next     = {state[WIDTH-2:0], feedback}
bit_o    = state[WIDTH-1]
```

`load_seed` takes priority over `enable`. A zero loaded seed is replaced with `RESET_SEED`, and a zero runtime state recovers to `RESET_SEED` on the next enabled cycle.

## Consequences

The default 16-bit mask remains `16'hB400`. Any generated candidate using a right-shift convention must either transform the tap mask or will fail the shared tests.

