module uart_loopback_top #(
    parameter int unsigned CLKS_PER_BIT = 4
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tx_valid,
    input  logic [7:0] tx_data,
    output logic       tx_ready,
    output logic       tx_busy,
    output logic       tx_done,
    output logic       rx_valid,
    output logic [7:0] rx_data,
    output logic       framing_error,
    output logic       uart_wire
);

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx_ready(tx_ready),
        .tx_o(uart_wire),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_i(uart_wire),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .framing_error(framing_error)
    );

endmodule

