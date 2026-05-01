module tang9k_uart_top (
    input  logic       clk,
    input  logic [1:0] btn_n,
    input  logic       uart_rx,
    output logic       uart_tx,
    output logic [5:0] led_n
);

    logic rst_n;
    logic [7:0] last_rx_data;
    logic rx_valid;
    logic framing_error;
    logic tx_busy;
    logic tx_done;
    logic status_toggle_q;

    assign rst_n = btn_n[0];

    uart_echo #(
        .CLKS_PER_BIT(234)
    ) u_uart_echo (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_i(uart_rx),
        .uart_tx_o(uart_tx),
        .last_rx_data_o(last_rx_data),
        .rx_valid_o(rx_valid),
        .framing_error_o(framing_error),
        .tx_busy_o(tx_busy),
        .tx_done_o(tx_done)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_toggle_q <= 1'b0;
        end else if (rx_valid || tx_done || !btn_n[1]) begin
            status_toggle_q <= ~status_toggle_q;
        end
    end

    assign led_n[2:0] = ~last_rx_data[2:0];
    assign led_n[3] = ~(^last_rx_data[7:3]);
    assign led_n[4] = ~tx_busy;
    assign led_n[5] = ~(framing_error | status_toggle_q);

endmodule
