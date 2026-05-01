# UCAgent-Style LFSR Verification Workflow

## Scope

UCAgent itself is not installed or run in this repo yet. This document maps the current LFSR PoC into the UCAgent-style workflow described by the MLVP/UCAgent documentation: staged verification over a Picker-generated Python DUT package with Toffee-based tests and reports.

## Current Artifacts

| UCAgent-style artifact | Current repo equivalent |
| --- | --- |
| DUT specification | `spec/lfsr_spec.md`, `spec/lfsr_steps.md` |
| DUT source | `rtl/configurable_lfsr.sv`, `rtl/lfsr_csr.sv` |
| Picker DUT package | `build/picker/configurable_lfsr/` |
| Toffee/Picker test | `tb/toffee_picker/test_lfsr_toffee_picker.py` |
| Test program | `scripts/run_toffee_picker_tests.sh` |
| Coverage plan | `tb/llm4dv_lfsr/coverage_plan.json` |
| Summary input | `build/llm4dv_lfsr/coverage_result.json` |

## Stages

1. Requirement understanding: read `spec/lfsr_spec.md`.
2. DUT packaging: run `scripts/run_picker.sh`.
3. Directed verification: run `scripts/run_toffee_picker_tests.sh`.
4. Alternate simulator verification: run `scripts/run_cocotb_tests.sh`.
5. Coverage-feedback stimulus generation: run `scripts/run_llm4dv_lfsr.sh`.
6. FPGA smoke check: run `scripts/run_synth.sh` and `scripts/program_tang9k.sh --sudo`.

## Future UCAgent Integration

To run actual UCAgent, install it and point it at:

```text
DUT:       rtl/configurable_lfsr.sv
Spec:      spec/lfsr_spec.md
Tests:     tb/toffee_picker/
Commands:  scripts/run_toffee_picker_tests.sh
```

Expected next outputs:

- generated test cases
- generated test summary
- bug analysis file
- coverage report

