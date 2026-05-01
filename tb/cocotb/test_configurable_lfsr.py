import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, RisingEdge, Timer

from model_lfsr import LfsrModel


async def sample_after_rising_edge(dut):
    await RisingEdge(dut.clk)
    await ReadOnly()
    await Timer(1, unit="ps")


async def reset_dut(dut, model):
    dut.enable.value = 0
    dut.load_seed.value = 0
    dut.seed_i.value = 0
    dut.rst_n.value = 0
    await sample_after_rising_edge(dut)
    model.reset()
    assert int(dut.state_o.value) == model.state
    assert int(dut.zero_state_o.value) == 0
    dut.rst_n.value = 1


@cocotb.test()
async def directed_sequence_matches_golden_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    model = LfsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

    await reset_dut(dut, model)

    dut.enable.value = 0
    for _ in range(4):
        await sample_after_rising_edge(dut)
        model.cycle(enable=False)
        assert int(dut.state_o.value) == model.state

    dut.load_seed.value = 1
    dut.seed_i.value = 0x1234
    await sample_after_rising_edge(dut)
    model.cycle(load_seed=True, seed=0x1234)
    assert int(dut.state_o.value) == model.state

    dut.load_seed.value = 0
    dut.enable.value = 1
    for _ in range(16):
        await sample_after_rising_edge(dut)
        model.cycle(enable=True)
        assert int(dut.state_o.value) == model.state
        assert int(dut.bit_o.value) == model.bit


@cocotb.test()
async def random_control_stream_matches_golden_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    rng = random.Random(20260501)
    model = LfsrModel(width=16, tap_mask=0xB400, reset_seed=0xACE1)

    await reset_dut(dut, model)

    for cycle in range(128):
        if cycle == 40:
            await reset_dut(dut, model)

        load_seed = cycle in {3, 70} or rng.randrange(30) == 0
        enable = rng.choice([False, True, True])
        seed = 0 if cycle == 3 else rng.randrange(1, 1 << 16)

        dut.load_seed.value = int(load_seed)
        dut.enable.value = int(enable)
        dut.seed_i.value = seed

        await sample_after_rising_edge(dut)
        model.cycle(enable=enable, load_seed=load_seed, seed=seed)

        assert int(dut.state_o.value) == model.state
        assert int(dut.zero_state_o.value) == int(model.zero_state)
