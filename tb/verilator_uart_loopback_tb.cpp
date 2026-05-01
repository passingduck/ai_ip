#include <cstdint>
#include <iostream>
#include "Vuart_loopback_top.h"

static void tick(Vuart_loopback_top& dut) {
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
}

static bool send_byte(Vuart_loopback_top& dut, uint8_t value) {
    dut.tx_data = value;
    dut.tx_valid = 1;
    tick(dut);
    dut.tx_valid = 0;

    for (int cycle = 0; cycle < 200; ++cycle) {
        tick(dut);
        if (dut.rx_valid) {
            if (dut.framing_error) {
                std::cerr << "framing error while receiving 0x"
                          << std::hex << static_cast<int>(value) << "\n";
                return false;
            }
            if (dut.rx_data != value) {
                std::cerr << "rx mismatch: got 0x" << std::hex
                          << static_cast<int>(dut.rx_data)
                          << " expected 0x" << static_cast<int>(value) << "\n";
                return false;
            }
            return true;
        }
    }

    std::cerr << "timeout receiving 0x" << std::hex << static_cast<int>(value) << "\n";
    return false;
}

int main() {
    Vuart_loopback_top dut;

    dut.rst_n = 0;
    dut.tx_valid = 0;
    dut.tx_data = 0;
    for (int i = 0; i < 4; ++i) {
        tick(dut);
    }
    dut.rst_n = 1;
    for (int i = 0; i < 4; ++i) {
        tick(dut);
    }

    const uint8_t values[] = {0x00, 0x55, 0xA5, 0xFF, 0x3C};
    for (uint8_t value : values) {
        if (!send_byte(dut, value)) {
            return 1;
        }
    }

    return 0;
}

