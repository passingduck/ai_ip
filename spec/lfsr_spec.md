# Configurable LFSR Specification

## Module

`configurable_lfsr`

## Parameters

| Name | Default | Meaning |
| --- | --- | --- |
| `WIDTH` | `16` | LFSR state width. Must be at least 2. |
| `TAP_MASK` | `16'hB400` | Fibonacci feedback tap mask for the selected shift convention. |
| `RESET_SEED` | `16'hACE1` | Reset and zero-recovery seed. |

## Ports

| Port | Direction | Meaning |
| --- | --- | --- |
| `clk` | input | Rising-edge clock. |
| `rst_n` | input | Active-low asynchronous reset. |
| `enable` | input | Advance the LFSR when high. |
| `load_seed` | input | Load `seed_i` when high. |
| `seed_i` | input | Candidate seed value. |
| `state_o` | output | Current LFSR state. |
| `bit_o` | output | Current output bit, defined as `state_o[WIDTH-1]`. |
| `zero_state_o` | output | High when the current state is zero. |

## Behavior

Priority order:

1. `rst_n == 0`: `state_o <= RESET_SEED`, unless `RESET_SEED` is zero, in which case state becomes `1`.
2. `load_seed == 1`: `state_o <= seed_i`, unless `seed_i` is zero, in which case state becomes the sanitized reset seed.
3. `enable == 1`: advance by one Fibonacci LFSR step.
4. Otherwise: hold state.

LFSR step:

```text
feedback = xor_reduce(state_o & TAP_MASK)
state_o  = {state_o[WIDTH-2:0], feedback}
```

If the runtime state is ever zero and `enable == 1`, the implementation recovers to the sanitized reset seed instead of remaining locked at zero.

