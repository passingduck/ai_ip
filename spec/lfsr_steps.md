# LFSR PoC Steps

## Step 1: Fixed LFSR

Fixed modules prove the simplest RTL generation and board smoke-test path.

- `rtl/lfsr8.sv`: 8-bit LFSR, `TAP_MASK=8'h8E`, `RESET_SEED=8'h5A`
- `rtl/lfsr16.sv`: 16-bit LFSR, `TAP_MASK=16'hB400`, `RESET_SEED=16'hACE1`

Controls:

- `rst_n`
- `enable`

Outputs:

- `state_o`
- `bit_o`

## Step 2: Configurable LFSR

`rtl/configurable_lfsr.sv` adds parameters and runtime seed loading:

- `WIDTH`
- `TAP_MASK`
- `RESET_SEED`
- `enable`
- `load_seed`
- `seed_i`
- `zero_state_o`

This is the reference DUT for AI-generated candidate comparison.

## Step 3: CSR-Controlled LFSR

`rtl/lfsr_csr.sv` wraps LFSR behavior with a simple single-cycle CSR interface.

CSR map:

| Address | Name | Access | Description |
| --- | --- | --- | --- |
| `0x00` | `CTRL` | RW/action | bit0 `enable`, bit1 `load_seed`, bit2 `clear` |
| `0x04` | `SEED` | RW | Seed register, zero sanitized to reset seed |
| `0x08` | `TAP_MASK` | RW | Runtime tap mask |
| `0x0c` | `STATE` | RO | Current LFSR state |
| `0x10` | `STATUS` | RO | bit0 `zero_state`, bit1 `period_done` |

Write behavior:

- `CTRL.enable` is persistent.
- `CTRL.load_seed` is a write action using the current `SEED` register.
- `CTRL.clear` is a write action that restores the reset seed.
- `clear` has priority over `load_seed`.
- An enabled CSR write cycle updates control/action state but does not also advance the LFSR.

