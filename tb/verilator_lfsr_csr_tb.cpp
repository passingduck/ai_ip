#include <cstdint>
#include <iostream>
#include "Vlfsr_csr.h"

static void tick(Vlfsr_csr& dut) {
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
}

static void csr_write(Vlfsr_csr& dut, uint8_t addr, uint32_t data) {
    dut.csr_valid = 1;
    dut.csr_write = 1;
    dut.csr_addr = addr;
    dut.csr_wdata = data;
    tick(dut);
    dut.csr_valid = 0;
    dut.csr_write = 0;
    dut.csr_addr = 0;
    dut.csr_wdata = 0;
}

static bool expect_state(Vlfsr_csr& dut, uint32_t expected, const char* label) {
    if (dut.state_o != expected) {
        std::cerr << label << ": got 0x" << std::hex << dut.state_o
                  << " expected 0x" << expected << "\n";
        return false;
    }
    return true;
}

int main() {
    Vlfsr_csr dut;

    dut.rst_n = 0;
    dut.csr_valid = 0;
    dut.csr_write = 0;
    dut.csr_addr = 0;
    dut.csr_wdata = 0;
    tick(dut);
    dut.rst_n = 1;

    if (!expect_state(dut, 0x1, "reset")) return 1;
    if (dut.period_done_o != 0 || dut.zero_state_o != 0) return 1;

    csr_write(dut, 0x04, 0x5);
    csr_write(dut, 0x00, 0x2);
    if (!expect_state(dut, 0x5, "load seed")) return 1;

    csr_write(dut, 0x00, 0x1);
    tick(dut);
    if (!expect_state(dut, 0xb, "advance after enable")) return 1;

    csr_write(dut, 0x00, 0x4);
    if (!expect_state(dut, 0x1, "clear")) return 1;

    csr_write(dut, 0x04, 0x0);
    csr_write(dut, 0x00, 0x2);
    if (!expect_state(dut, 0x1, "zero seed sanitize")) return 1;

    csr_write(dut, 0x00, 0x1);
    for (int i = 0; i < 15; ++i) {
        tick(dut);
    }
    if (dut.period_done_o != 1) {
        std::cerr << "period_done did not assert\n";
        return 1;
    }

    return 0;
}

