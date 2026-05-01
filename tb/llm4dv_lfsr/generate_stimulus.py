#!/usr/bin/env python3
import json
from pathlib import Path


def main() -> None:
    out = Path("build/llm4dv_lfsr/stimulus.json")
    out.parent.mkdir(parents=True, exist_ok=True)

    stimulus = {
        "description": "Deterministic coverage-feedback stimulus set for LFSR PoC",
        "note": "This is LLM4DV-style local generation. It does not call an LLM API yet.",
        "width": 8,
        "tap_mask": 0x8E,
        "reset_seed": 0x5A,
        "ops": [
            {"op": "reset"},
            {"op": "hold", "cycles": 4},
            {"op": "load", "seed": 0},
            {"op": "load", "seed": 0xA5},
            {"op": "run", "cycles": 32},
            {"op": "random_reset_during_active_run"},
            {"op": "random_load_during_active_run", "seed": 0x3C},
            {"op": "run_until_period", "max_cycles": 300}
        ]
    }

    out.write_text(json.dumps(stimulus, indent=2) + "\n", encoding="utf-8")
    print(out)


if __name__ == "__main__":
    main()

