# AI Agent IP Development and Verification Flow

## Purpose

This document summarizes the LFSR IP proof-of-concept flow we exercised on the local PC and Tang Nano 9K board.

The goal was not just to make an LFSR. The goal was to validate a small end-to-end IP development loop that an AI agent can help drive:

```text
spec -> RTL implementation -> golden model -> regression tests -> lint/simulation -> FPGA synthesis -> board smoke test
```

## Important Scope Clarification

This PoC did not yet use VerilogCoder or MAGE to generate RTL.

The RTL was implemented directly in this repo during the agent session:

- fixed LFSR wrappers
- configurable LFSR
- CSR-controlled LFSR
- Tang Nano 9K top module

The initial board bring-up PoC did not use LLM4DV, cocotb, UCAgent, or a real Toffee/Picker verification environment. After that, we extended the repo with additional verification benches:

- cocotb + Verilator RTL tests
- Picker-generated DUT tests with Toffee functional coverage primitives
- LLM4DV-style local coverage-feedback stimulus generation
- UCAgent-style workflow mapping document

UCAgent itself is still not installed or run, and the LLM4DV harness does not call an LLM API yet.

What was actually used:

- Python `unittest` golden-model regression
- C++ Verilator smoke tests
- Verilator lint
- Picker DUT package generation smoke check
- cocotb RTL regression
- Toffee/Picker DUT-driving regression
- LLM4DV-style local coverage-feedback stimulus run
- Yosys / nextpnr-himbaechel / gowin_pack synthesis flow
- openFPGALoader board programming

Picker was installed and used to generate a Python-callable DUT package. A small Toffee/Picker testbench now drives that generated DUT and samples Toffee functional coverage points.

## Implemented IP Steps

### Step 1: Fixed LFSR

Purpose:

```text
Prove the simplest spec -> RTL -> simulation path.
```

Implemented modules:

- `rtl/lfsr8.sv`
- `rtl/lfsr16.sv`

Behavior:

- reset to fixed seed
- advance when `enable=1`
- hold when `enable=0`
- expose `state_o` and `bit_o`

Validation:

- Verilator C++ sequence tests
- Verilator lint

### Step 2: Configurable LFSR

Purpose:

```text
Move from a toy fixed block to reusable configurable IP.
```

Implemented module:

- `rtl/configurable_lfsr.sv`

Features:

- parameterized `WIDTH`
- parameterized `TAP_MASK`
- parameterized `RESET_SEED`
- `enable`
- `load_seed`
- `seed_i`
- `zero_state_o`
- zero seed sanitization
- zero-state recovery

Validation:

- Python golden model
- directed tests
- random tests
- coverage-bin tracking
- bug-injection test
- Verilator lint
- Verilator C++ smoke simulation
- Tang Nano 9K synthesis path

### Step 3: CSR-Controlled LFSR

Purpose:

```text
Move closer to real IP shape with register control and status readback.
```

Implemented module:

- `rtl/lfsr_csr.sv`

CSR map:

| Address | Name | Description |
| --- | --- | --- |
| `0x00` | `CTRL` | bit0 `enable`, bit1 `load_seed`, bit2 `clear` |
| `0x04` | `SEED` | seed register |
| `0x08` | `TAP_MASK` | runtime tap mask |
| `0x0c` | `STATE` | current state readback |
| `0x10` | `STATUS` | bit0 `zero_state`, bit1 `period_done` |

Validation:

- Python CSR model tests
- Verilator CSR C++ smoke test
- Verilator lint

## Verification Flow Used

### 1. Python Golden Model

File:

- `tb/model_lfsr.py`

The golden model defines the expected LFSR behavior:

```text
feedback = parity(state & TAP_MASK)
next     = {state[WIDTH-2:0], feedback}
```

It also models:

- reset seed sanitization
- zero seed policy
- enable hold
- seed loading
- small-width period checking
- CSR behavior

### 2. Directed Tests

Files:

- `tb/test_lfsr_basic.py`
- `tb/test_lfsr_csr.py`

Covered behavior:

- reset state
- enable hold
- seed load priority
- zero seed sanitization
- known sequence
- CSR readback
- CSR load/enable/clear
- CSR period-done

### 3. Random and Coverage Tests

File:

- `tb/test_lfsr_random.py`

Covered behavior:

- random enable toggling
- random seed loading
- random reset during run
- all state bits toggled
- `bit_o` observed as both 0 and 1
- maximal period for small-width primitive tap
- bug-injection detection

Coverage tracking is implemented locally in:

- `tb/coverage_lfsr.py`

This is an LLM4DV-style coverage-plan idea, but it is not LLM4DV-generated stimulus.

### 4. Verilator Lint and Simulation

Scripts:

- `scripts/run_verilator_lint.sh all`
- `scripts/run_verilator_sim.sh`
- `scripts/run_verilator_step_tests.sh`

Verilator checks:

- Step 1 fixed 8-bit sequence
- Step 1 fixed 16-bit sequence
- Step 2 configurable LFSR smoke test
- Step 3 CSR smoke test

### 5. Picker Smoke Check

Script:

- `scripts/run_picker.sh`

Picker generated a Python-callable DUT package under:

- `build/picker/configurable_lfsr/`

We confirmed the generated package imports and runs its example:

```bash
PYTHONPATH=build/picker python3 -m configurable_lfsr.example
```

This proves Picker can wrap this DUT in the local environment.

### 6. Toffee/Picker Testbench

Script:

- `scripts/run_toffee_picker_tests.sh`

Test file:

- `tb/toffee_picker/test_lfsr_toffee_picker.py`

This testbench drives the Picker-generated Python DUT and compares it with the Python golden model. It also uses Toffee functional coverage primitives.

This is still a minimal Toffee/Picker bench, not a full UVM-like environment with separate driver, monitor, scoreboard, and reusable agent layers.

### 7. cocotb Testbench

Script:

- `scripts/run_cocotb_tests.sh`

Test file:

- `tb/cocotb/test_configurable_lfsr.py`

This testbench uses cocotb with Verilator to drive the RTL directly and compare it cycle-by-cycle with the Python golden model.

### 8. LLM4DV-Style Coverage Feedback

Script:

- `scripts/run_llm4dv_lfsr.sh`

Files:

- `tb/llm4dv_lfsr/coverage_plan.json`
- `tb/llm4dv_lfsr/generate_stimulus.py`
- `tb/llm4dv_lfsr/run_stimulus.py`

This follows the LLM4DV concept:

```text
coverage plan -> stimulus generation -> DUT/model execution -> coverage feedback
```

It is not yet using the upstream `ml4dv` repo or an LLM API. It is a local LFSR-specific scaffold that can be replaced by an LLM-backed stimulus generator.

## FPGA Flow Used

Target:

- Sipeed Tang Nano 9K
- GW1NR-LV9QN88PC6/I5

Scripts:

- `scripts/run_synth.sh`
- `scripts/program_tang9k.sh --sudo`

Toolchain:

- Yosys
- nextpnr-himbaechel
- gowin_pack
- openFPGALoader

Board smoke test:

- `fpga/tang9k_top.sv`
- `fpga/tang9k.cst`

Behavior:

- 27 MHz board clock
- clock divider slows LFSR stepping
- six active-low LEDs show `state[5:0]`
- button 0 resets
- button 1 loads a fixed seed

Observed result:

```text
openFPGALoader programming succeeded
CRC check: Success
LEDs moved on board
```

## Verification Status

Latest status:

```text
Python tests: 13 passed
Verilator lint all: PASS
Verilator step tests: PASS
Verilator configurable smoke sim: PASS
cocotb + Verilator tests: PASS
Toffee/Picker tests: PASS
LLM4DV-style coverage run: PASS
Tang Nano 9K synthesis: PASS
Tang Nano 9K programming: PASS
Board LED smoke test: PASS
```

Synthesis result:

```text
Bitstream: build/tang9k_lfsr.fs
Max frequency: 159.90 MHz, PASS
```

Resource use was very small:

```text
LUT4: 65 / 8640
DFF:  40 / 6480
IOB:   9 / 276
```

## What AI Agent Helped With

The AI agent helped with:

- turning the high-level PoC idea into repo structure
- writing the LFSR spec
- implementing RTL modules
- writing Python golden models
- writing directed/random/coverage tests
- writing Verilator smoke tests
- writing install/setup scripts
- debugging setup failures
- bringing up OSS CAD Suite
- running synthesis
- debugging board programming permissions
- documenting the flow

This is an AI-assisted development and verification flow.

It is not yet a fully autonomous multi-agent RTL-generation flow using VerilogCoder/MAGE.

## What Was Not Yet Done

### VerilogCoder/MAGE RTL Generation

Not done yet.

The repo has placeholder files:

- `generated/candidate_from_verilogcoder.sv`
- `generated/candidate_from_mage.sv`

Next step would be:

```text
Generate candidate RTL with VerilogCoder/MAGE -> normalize interface -> run same regression -> compare failures/iterations/human fixes.
```

### LLM4DV Stimulus Generation

Partially done.

We now have a local LFSR-specific LLM4DV-style loop. It generates deterministic stimulus from a predefined coverage plan and reports coverage feedback.

Not done:

- upstream `ml4dv` integration
- LLM API prompt/response loop
- automatic prompt generation from uncovered bins

Next step would be:

```text
Feed uncovered bins to an LLM stimulus generator -> generate tests -> measure coverage improvement.
```

### cocotb

Now used.

cocotb drives the RTL through Verilator and compares against the golden model.

Next step would be:

```text
Add more protocol-style tests and coverage collection through cocotb.
```

### UCAgent / Toffee / Picker Full Verification

Partially done.

Picker was installed and used for DUT package generation. Toffee primitives are now used in `tb/toffee_picker/test_lfsr_toffee_picker.py`.

Not done:

- full Toffee driver/monitor/scoreboard layering
- UCAgent-style multi-stage verification workflow
- actual UCAgent execution

Next step would be:

```text
Use Picker-generated DUT package -> build Toffee env -> attach golden model -> run same directed/random tests through actual RTL.
```

## Recommended Next Steps

1. Build real Toffee verification environment on top of the Picker-generated DUT.
2. Add cocotb as an alternate Python RTL verification path if the team wants broader industry familiarity.
3. Run VerilogCoder/MAGE to generate candidate LFSR RTL.
4. Compare generated RTL against the same regression suite.
5. Add bug-injected RTL candidates and measure detection rate.
6. Extend CSR LFSR board top with UART readback or simple host control.
7. Apply the same flow to a tiny int8 MAC or stream FIFO, closer to NPU IP needs.

## Practical Takeaway

The useful result is that the repo now has a working, repeatable IP development loop:

```text
write/change RTL
run Python model tests
run Verilator lint and smoke tests
run FPGA synthesis
program Tang Nano 9K
observe board behavior
```

That loop is ready to receive AI-generated RTL candidates and more advanced verification agents.
