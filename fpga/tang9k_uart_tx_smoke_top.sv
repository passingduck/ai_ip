module tang9k_uart_tx_smoke_top (
    input  logic       clk,
    input  logic [1:0] btn_n,
    input  logic       uart_rx,
    output logic       uart_tx,
    output logic [5:0] led_n
);

    localparam int unsigned CLKS_PER_BIT = 234;
    localparam int unsigned GAP_CLKS = 13_500_000;
    localparam int unsigned MESSAGE_LEN = 14;
    localparam logic [3:0] LAST_BYTE_INDEX = 4'(MESSAGE_LEN - 1);
    localparam logic [23:0] LAST_GAP_COUNT = 24'(GAP_CLKS - 1);

    logic tx_valid;
    logic tx_ready;
    logic tx_busy;
    logic tx_done;
    logic [7:0] tx_data;
    logic [23:0] gap_count_q;
    logic [3:0] byte_index_q;
    logic active_q;
    logic sent_toggle_q;
    logic rx_idle_sample_q;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_tx (
        .clk(clk),
        .rst_n(btn_n[0]),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx_ready(tx_ready),
        .tx_o(uart_tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    always_comb begin
        unique case (byte_index_q)
            4'd0: tx_data = "A";
            4'd1: tx_data = "I";
            4'd2: tx_data = "I";
            4'd3: tx_data = "P";
            4'd4: tx_data = " ";
            4'd5: tx_data = "U";
            4'd6: tx_data = "A";
            4'd7: tx_data = "R";
            4'd8: tx_data = "T";
            4'd9: tx_data = " ";
            4'd10: tx_data = "T";
            4'd11: tx_data = "X";
            4'd12: tx_data = 8'h0d;
            default: tx_data = 8'h0a;
        endcase
    end

    assign tx_valid = active_q && tx_ready;

    always_ff @(posedge clk or negedge btn_n[0]) begin
        if (!btn_n[0]) begin
            gap_count_q <= 24'd0;
            byte_index_q <= 4'd0;
            active_q <= 1'b0;
            sent_toggle_q <= 1'b0;
            rx_idle_sample_q <= 1'b1;
        end else begin
            rx_idle_sample_q <= uart_rx;

            if (tx_done) begin
                sent_toggle_q <= ~sent_toggle_q;
                if (byte_index_q == LAST_BYTE_INDEX) begin
                    byte_index_q <= 4'd0;
                    active_q <= 1'b0;
                    gap_count_q <= 24'd0;
                end else begin
                    byte_index_q <= byte_index_q + 1'b1;
                end
            end else if (!active_q) begin
                if (gap_count_q == LAST_GAP_COUNT || !btn_n[1]) begin
                    active_q <= 1'b1;
                    gap_count_q <= 24'd0;
                end else begin
                    gap_count_q <= gap_count_q + 1'b1;
                end
            end
        end
    end

    assign led_n[0] = ~active_q;
    assign led_n[1] = ~tx_busy;
    assign led_n[2] = ~sent_toggle_q;
    assign led_n[3] = ~rx_idle_sample_q;
    assign led_n[4] = ~btn_n[0];
    assign led_n[5] = ~btn_n[1];

endmodule
