#include <cstdint>
#include <iostream>
#include "Vconfigurable_lfsr.h"

static void tick(Vconfigurable_lfsr& dut) {
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
}

int main() {
    Vconfigurable_lfsr dut;
    const uint16_t expected[] = {
        0xACE1, 0x59C3, 0xB387, 0x670F,
        0xCE1E, 0x9C3C, 0x3879, 0x70F2
    };

    dut.rst_n = 0;
    dut.enable = 0;
    dut.load_seed = 0;
    dut.seed_i = 0;
    tick(dut);

    dut.rst_n = 1;
    if (dut.state_o != expected[0]) {
        std::cerr << "reset state mismatch\n";
        return 1;
    }

    dut.enable = 1;
    for (int i = 1; i < 8; ++i) {
        tick(dut);
        if (dut.state_o != expected[i]) {
            std::cerr << "sequence mismatch at step " << i
                      << ": got 0x" << std::hex << dut.state_o
                      << " expected 0x" << expected[i] << "\n";
            return 1;
        }
    }

    dut.enable = 0;
    uint16_t held = dut.state_o;
    for (int i = 0; i < 4; ++i) {
        tick(dut);
        if (dut.state_o != held) {
            std::cerr << "state changed while enable=0\n";
            return 1;
        }
    }

    dut.load_seed = 1;
    dut.seed_i = 0;
    tick(dut);
    if (dut.state_o != expected[0]) {
        std::cerr << "zero seed recovery mismatch\n";
        return 1;
    }

    return 0;
}
