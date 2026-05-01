#!/usr/bin/env python3
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from coverage_lfsr import LfsrCoverage
from model_lfsr import LfsrModel


def sample(cov: LfsrCoverage, dut: LfsrModel) -> None:
    cov.sample_state(dut.state, dut.bit)


def run_ops(stimulus_path: Path) -> dict:
    stimulus = json.loads(stimulus_path.read_text(encoding="utf-8"))
    dut = LfsrModel(
        width=stimulus["width"],
        tap_mask=stimulus["tap_mask"],
        reset_seed=stimulus["reset_seed"],
    )
    cov = LfsrCoverage(width=stimulus["width"])
    initial_seed = dut.state

    for op in stimulus["ops"]:
        name = op["op"]

        if name == "reset":
            dut.reset()
            cov.mark("reset_observed")
            sample(cov, dut)

        elif name == "hold":
            before = dut.state
            for _ in range(op["cycles"]):
                dut.cycle(enable=False)
                assert dut.state == before
                cov.mark("enable_hold_observed")
                sample(cov, dut)

        elif name == "load":
            seed = op["seed"]
            dut.cycle(load_seed=True, seed=seed)
            cov.mark("load_seed_observed")
            cov.mark("zero_seed_observed" if seed == 0 else "non_zero_seed_observed")
            sample(cov, dut)

        elif name == "run":
            for _ in range(op["cycles"]):
                dut.cycle(enable=True)
                if dut.state == initial_seed:
                    cov.mark("state_returned_to_initial_seed")
                sample(cov, dut)

        elif name == "random_reset_during_active_run":
            dut.cycle(enable=True)
            dut.reset()
            cov.mark("random_reset_during_run")
            sample(cov, dut)

        elif name == "random_load_during_active_run":
            dut.cycle(enable=True)
            dut.cycle(load_seed=True, seed=op["seed"])
            cov.mark("load_seed_observed")
            cov.mark("non_zero_seed_observed")
            cov.mark("random_load_during_run")
            sample(cov, dut)

        elif name == "run_until_period":
            period_dut = LfsrModel(
                width=stimulus["width"],
                tap_mask=stimulus["tap_mask"],
                reset_seed=stimulus["reset_seed"],
            )
            period, repeated = period_dut.run_until_repeat(max_cycles=op["max_cycles"])
            if period == (1 << stimulus["width"]) - 1 and repeated == stimulus["reset_seed"]:
                cov.mark("period_reached")

            dut.reset()
            for _ in range((1 << stimulus["width"]) - 1):
                dut.cycle(enable=True)
                if dut.state == initial_seed:
                    cov.mark("state_returned_to_initial_seed")
                sample(cov, dut)

        else:
            raise ValueError(f"unknown op: {name}")

    result = {
        "coverage_ratio": cov.ratio(),
        "covered_bins": sorted(cov.bins & cov.REQUIRED_BINS),
        "missing_bins": sorted(cov.missing()),
    }
    return result


def main() -> None:
    stimulus_path = Path("build/llm4dv_lfsr/stimulus.json")
    result = run_ops(stimulus_path)
    out = Path("build/llm4dv_lfsr/coverage_result.json")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    if result["missing_bins"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

