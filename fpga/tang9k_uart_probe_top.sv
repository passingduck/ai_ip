module tang9k_uart_probe_top (
    input  logic       clk,
    input  logic [1:0] btn_n,
    input  logic       uart_rx,
    output logic       uart_tx,
    output logic [5:0] led_n
);

    localparam int unsigned CLKS_PER_BIT = 234;
    localparam int unsigned HEARTBEAT_CLKS = 13_500_000;
    localparam logic [23:0] LAST_HEARTBEAT_COUNT = 24'(HEARTBEAT_CLKS - 1);

    typedef enum logic [1:0] {
        MSG_IDLE,
        MSG_HEARTBEAT,
        MSG_RX_ACK
    } msg_state_t;

    logic rx_valid;
    logic [7:0] rx_data;
    logic framing_error;
    logic tx_valid;
    logic tx_ready;
    logic tx_busy;
    logic tx_done;
    logic [7:0] tx_data;
    logic [23:0] heartbeat_count_q;
    logic [7:0] rx_data_q;
    logic rx_pending_q;
    logic rx_toggle_q;
    logic [3:0] msg_index_q;
    msg_state_t msg_state_q;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_rx (
        .clk(clk),
        .rst_n(btn_n[0]),
        .rx_i(uart_rx),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .framing_error(framing_error)
    );

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

    function automatic logic [7:0] hex_char(input logic [3:0] nibble);
        if (nibble < 4'd10) begin
            hex_char = 8'("0") + {4'd0, nibble};
        end else begin
            hex_char = 8'("A") + {4'd0, nibble - 4'd10};
        end
    endfunction

    always_comb begin
        unique case (msg_state_q)
            MSG_HEARTBEAT: begin
                unique case (msg_index_q)
                    4'd0: tx_data = "R";
                    4'd1: tx_data = "D";
                    4'd2: tx_data = "Y";
                    4'd3: tx_data = 8'h0d;
                    default: tx_data = 8'h0a;
                endcase
            end

            MSG_RX_ACK: begin
                unique case (msg_index_q)
                    4'd0: tx_data = "R";
                    4'd1: tx_data = "X";
                    4'd2: tx_data = " ";
                    4'd3: tx_data = hex_char(rx_data_q[7:4]);
                    4'd4: tx_data = hex_char(rx_data_q[3:0]);
                    4'd5: tx_data = 8'h0d;
                    default: tx_data = 8'h0a;
                endcase
            end

            default: begin
                tx_data = 8'hff;
            end
        endcase
    end

    assign tx_valid = (msg_state_q != MSG_IDLE) && tx_ready;

    always_ff @(posedge clk or negedge btn_n[0]) begin
        if (!btn_n[0]) begin
            heartbeat_count_q <= 24'd0;
            rx_data_q <= 8'h00;
            rx_pending_q <= 1'b0;
            rx_toggle_q <= 1'b0;
            msg_index_q <= 4'd0;
            msg_state_q <= MSG_IDLE;
        end else begin
            if (rx_valid) begin
                rx_data_q <= rx_data;
                rx_pending_q <= 1'b1;
                rx_toggle_q <= ~rx_toggle_q;
            end

            if (msg_state_q == MSG_IDLE) begin
                msg_index_q <= 4'd0;
                if (rx_pending_q) begin
                    rx_pending_q <= 1'b0;
                    msg_state_q <= MSG_RX_ACK;
                end else if (heartbeat_count_q == LAST_HEARTBEAT_COUNT || !btn_n[1]) begin
                    heartbeat_count_q <= 24'd0;
                    msg_state_q <= MSG_HEARTBEAT;
                end else begin
                    heartbeat_count_q <= heartbeat_count_q + 1'b1;
                end
            end else if (tx_done) begin
                unique case (msg_state_q)
                    MSG_HEARTBEAT: begin
                        if (msg_index_q == 4'd4) begin
                            msg_state_q <= MSG_IDLE;
                            msg_index_q <= 4'd0;
                        end else begin
                            msg_index_q <= msg_index_q + 1'b1;
                        end
                    end

                    MSG_RX_ACK: begin
                        if (msg_index_q == 4'd6) begin
                            msg_state_q <= MSG_IDLE;
                            msg_index_q <= 4'd0;
                        end else begin
                            msg_index_q <= msg_index_q + 1'b1;
                        end
                    end

                    default: begin
                        msg_state_q <= MSG_IDLE;
                        msg_index_q <= 4'd0;
                    end
                endcase
            end
        end
    end

    assign led_n[0] = ~rx_data_q[0];
    assign led_n[1] = ~rx_data_q[1];
    assign led_n[2] = ~rx_data_q[2];
    assign led_n[3] = ~rx_toggle_q;
    assign led_n[4] = ~tx_busy;
    assign led_n[5] = ~framing_error;

endmodule
