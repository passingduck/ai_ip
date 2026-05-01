# AI RTL Development Flow: LFSR PoC

## Goal

Validate whether an AI-assisted RTL workflow can take a small IP block through specification, RTL generation, verification, debug, and Tang Nano 9K synthesis.

## Flow

1. Write or generate candidate RTL into `generated/`.
2. Normalize the public interface to match `spec/lfsr_spec.md`.
3. Run `scripts/run_python_tests.sh` against the golden model behavior.
4. Run `scripts/run_verilator_lint.sh <candidate>` when Verilator is available.
5. Add candidate-specific Verilator or Picker/Toffee tests.
6. Run `scripts/run_synth.sh` for Tang Nano 9K build.
7. Run `scripts/program_tang9k.sh` for LED smoke test.

## Evaluation Metrics

- Syntax/lint pass or fail.
- Directed tests passed.
- Random tests passed.
- Coverage bins reached.
- Bug-injection detection rate.
- Human lines changed after AI generation.
- Synthesis result and timing result.
- Tang Nano 9K LED smoke-test result.

## Candidate Comparison

Keep each AI generator output as a separate file:

- `generated/candidate_from_verilogcoder.sv`
- `generated/candidate_from_mage.sv`
- `rtl/configurable_lfsr.sv` as handwritten reference

Run the same verification harness against every candidate.

