# AI RTL LFSR PoC Context

## Domain Terms

- **PoC**: End-to-end proof that an AI-assisted RTL workflow can produce, verify, debug, and synthesize a small IP block.
- **Configurable LFSR**: Parameterized Fibonacci LFSR with selectable width, tap mask, reset seed, enable, and seed-load controls.
- **Golden model**: Python reference model used as the behavioral oracle for tests and scoreboards.
- **Coverage plan**: Explicit set of behaviors the verification harness must observe.
- **Bug injection**: Deliberate RTL/model mutation used to measure whether tests catch plausible implementation mistakes.
- **Tang Nano 9K smoke test**: Board-level LED test that proves the design can be built and run on GW1NR-9 hardware.

## Current Scope

The first vertical slice is a configurable LFSR with a Python verification harness, optional Verilator lint/simulation, and Tang Nano 9K synthesis scripts.

