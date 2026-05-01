#include <cstdint>
#include <iostream>
#include "Vlfsr8.h"

static void tick(Vlfsr8& dut) {
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
}

int main() {
    Vlfsr8 dut;
    const uint8_t expected[] = {0x5a, 0xb4, 0x68, 0xd1, 0xa3, 0x46, 0x8c, 0x19};

    dut.rst_n = 0;
    dut.enable = 0;
    tick(dut);
    dut.rst_n = 1;

    for (int i = 0; i < 8; ++i) {
        if (dut.state_o != expected[i]) {
            std::cerr << "lfsr8 mismatch at step " << i
                      << ": got 0x" << std::hex << static_cast<int>(dut.state_o)
                      << " expected 0x" << static_cast<int>(expected[i]) << "\n";
            return 1;
        }
        dut.enable = 1;
        tick(dut);
    }

    return 0;
}

