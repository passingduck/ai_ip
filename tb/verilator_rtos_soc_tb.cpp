#include <cstdint>
#include <iostream>
#include <string>

#include "Vtang9k_rtos_soc_top.h"
#include "Vtang9k_rtos_soc_top___024root.h"

namespace {

constexpr int kClksPerBit = 27000000 / 115200;
constexpr const char* kBootBanner = "RTOS LCD counter boot\r\n";

void tick(Vtang9k_rtos_soc_top& dut) {
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
}

void run_cycles(Vtang9k_rtos_soc_top& dut, int cycles) {
    for (int i = 0; i < cycles; ++i) {
        tick(dut);
    }
}

bool try_receive_byte(Vtang9k_rtos_soc_top& dut, uint8_t& value, int timeout_cycles) {
    int previous_tx = dut.uart_tx;

    for (int elapsed = 0; elapsed < timeout_cycles; ++elapsed) {
        tick(dut);
        int current_tx = dut.uart_tx;

        if (previous_tx == 1 && current_tx == 0) {
            run_cycles(dut, kClksPerBit + (kClksPerBit / 2));

            uint8_t byte = 0;
            for (int bit = 0; bit < 8; ++bit) {
                if (dut.uart_tx) {
                    byte |= static_cast<uint8_t>(1u << bit);
                }
                run_cycles(dut, kClksPerBit);
            }

            if (dut.uart_tx != 1) {
                std::cerr << "UART stop bit was low\n";
                return false;
            }

            value = byte;
            return true;
        }

        previous_tx = current_tx;
    }

    return false;
}

} // namespace

int main() {
    Vtang9k_rtos_soc_top dut;
    std::string received;

    dut.clk = 0;
    dut.btn_n = 0b01; // run button released, reset button held
    dut.uart_rx = 1;
    run_cycles(dut, 16);

    dut.btn_n = 0b11; // release reset
    run_cycles(dut, 16);

    for (int i = 0; i < 128; ++i) {
        uint8_t byte = 0;
        if (!try_receive_byte(dut, byte, 200000)) {
            std::cerr << "timeout waiting for UART byte; received: " << received << "\n";
            return 1;
        }

        received.push_back(static_cast<char>(byte));
        if (received.find(kBootBanner) != std::string::npos) {
            break;
        }
    }

    if (received.find(kBootBanner) == std::string::npos) {
        std::cerr << "boot banner not found; received: " << received << "\n";
        return 1;
    }

    dut.btn_n = 0b10; // press run button, keep reset released
    run_cycles(dut, 700000);
    dut.btn_n = 0b11;
    run_cycles(dut, 100000);

    const auto* root = dut.rootp;
    const bool count_mode =
        root->tang9k_rtos_soc_top__DOT__lcd_i__DOT__display_mode_q == 2;
    const unsigned count_bcd =
        (root->tang9k_rtos_soc_top__DOT__lcd_i__DOT__digit_3_q << 12) |
        (root->tang9k_rtos_soc_top__DOT__lcd_i__DOT__digit_2_q << 8) |
        (root->tang9k_rtos_soc_top__DOT__lcd_i__DOT__digit_1_q << 4) |
        root->tang9k_rtos_soc_top__DOT__lcd_i__DOT__digit_0_q;

    if (!count_mode || count_bcd == 0) {
        std::cerr << "button did not advance LCD count: mode="
                  << static_cast<unsigned>(
                         root->tang9k_rtos_soc_top__DOT__lcd_i__DOT__display_mode_q)
                  << " bcd=0x" << std::hex << count_bcd << "\n";
        return 1;
    }

    std::cout << "RTOS SoC UART/button PASS: " << received
              << "LCD count BCD=0x" << std::hex << count_bcd << "\n";
    return 0;
}
