import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, RisingEdge, Timer

from model_uart import uart_frame_bits


async def tick(dut):
    await RisingEdge(dut.clk)
    await ReadOnly()
    await Timer(1, unit="ps")


async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.uart_rx_i.value = 1
    for _ in range(4):
        await tick(dut)
    dut.rst_n.value = 1
    for _ in range(4):
        await tick(dut)


async def drive_uart_byte(dut, byte, clks_per_bit=4):
    for bit in uart_frame_bits(byte):
        dut.uart_rx_i.value = bit
        for _ in range(clks_per_bit):
            await tick(dut)
    dut.uart_rx_i.value = 1


async def collect_uart_byte(dut, clks_per_bit=4):
    for _ in range(200):
        await tick(dut)
        if int(dut.uart_tx_o.value) == 0:
            break
    else:
        raise AssertionError("timeout waiting for echoed start bit")

    for _ in range(clks_per_bit + clks_per_bit // 2):
        await tick(dut)

    value = 0
    for bit_index in range(8):
        value |= int(dut.uart_tx_o.value) << bit_index
        for _ in range(clks_per_bit):
            await tick(dut)

    assert int(dut.uart_tx_o.value) == 1
    return value


async def drive_uart_burst(dut, payload, clks_per_bit=4):
    for byte in payload:
        await drive_uart_byte(dut, byte, clks_per_bit)


@cocotb.test()
async def uart_echoes_received_bytes(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    for byte in [0x00, 0x55, 0xA5, 0xFF, 0x3C]:
        await drive_uart_byte(dut, byte)
        echoed = await collect_uart_byte(dut)
        assert echoed == byte
        assert int(dut.last_rx_data_o.value) == byte
        assert int(dut.framing_error_o.value) == 0


@cocotb.test()
async def uart_echoes_back_to_back_burst(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    payload = [0x55, 0xAA, 0x00, 0x3C, 0xC3, 0x81, 0x7E]
    cocotb.start_soon(drive_uart_burst(dut, payload))

    echoed = []
    for _ in payload:
        echoed.append(await collect_uart_byte(dut))

    assert echoed == payload
    assert int(dut.last_rx_data_o.value) == payload[-1]
    assert int(dut.framing_error_o.value) == 0
