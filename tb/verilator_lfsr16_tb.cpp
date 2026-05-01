#include <cstdint>
#include <iostream>
#include "Vlfsr16.h"

static void tick(Vlfsr16& dut) {
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
}

int main() {
    Vlfsr16 dut;
    const uint16_t expected[] = {
        0xACE1, 0x59C3, 0xB387, 0x670F,
        0xCE1E, 0x9C3C, 0x3879, 0x70F2
    };

    dut.rst_n = 0;
    dut.enable = 0;
    tick(dut);
    dut.rst_n = 1;

    for (int i = 0; i < 8; ++i) {
        if (dut.state_o != expected[i]) {
            std::cerr << "lfsr16 mismatch at step " << i
                      << ": got 0x" << std::hex << dut.state_o
                      << " expected 0x" << expected[i] << "\n";
            return 1;
        }
        dut.enable = 1;
        tick(dut);
    }

    return 0;
}

