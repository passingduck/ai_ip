module uart_rx #(
    parameter int unsigned CLKS_PER_BIT = 234
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx_i,
    output logic       rx_valid,
    output logic [7:0] rx_data,
    output logic       framing_error
);

    typedef enum logic [2:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP
    } rx_state_t;

    localparam int unsigned HALF_CLKS_PER_BIT = CLKS_PER_BIT / 2;

    rx_state_t state_q;
    int unsigned clk_count_q;
    logic [2:0] bit_index_q;
    logic [7:0] data_q;
    logic rx_meta_q;
    logic rx_sync_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta_q <= 1'b1;
            rx_sync_q <= 1'b1;
        end else begin
            rx_meta_q <= rx_i;
            rx_sync_q <= rx_meta_q;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= RX_IDLE;
            clk_count_q <= 0;
            bit_index_q <= 3'd0;
            data_q <= 8'h00;
            rx_data <= 8'h00;
            rx_valid <= 1'b0;
            framing_error <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            framing_error <= 1'b0;

            unique case (state_q)
                RX_IDLE: begin
                    clk_count_q <= 0;
                    bit_index_q <= 3'd0;
                    if (!rx_sync_q) begin
                        state_q <= RX_START;
                    end
                end

                RX_START: begin
                    if (clk_count_q == HALF_CLKS_PER_BIT - 1) begin
                        clk_count_q <= 0;
                        if (!rx_sync_q) begin
                            state_q <= RX_DATA;
                        end else begin
                            state_q <= RX_IDLE;
                        end
                    end else begin
                        clk_count_q <= clk_count_q + 1;
                    end
                end

                RX_DATA: begin
                    if (clk_count_q == CLKS_PER_BIT - 1) begin
                        clk_count_q <= 0;
                        data_q[bit_index_q] <= rx_sync_q;
                        if (bit_index_q == 3'd7) begin
                            bit_index_q <= 3'd0;
                            state_q <= RX_STOP;
                        end else begin
                            bit_index_q <= bit_index_q + 1'b1;
                        end
                    end else begin
                        clk_count_q <= clk_count_q + 1;
                    end
                end

                RX_STOP: begin
                    if (clk_count_q == CLKS_PER_BIT - 1) begin
                        clk_count_q <= 0;
                        rx_data <= data_q;
                        rx_valid <= rx_sync_q;
                        framing_error <= !rx_sync_q;
                        state_q <= RX_IDLE;
                    end else begin
                        clk_count_q <= clk_count_q + 1;
                    end
                end

                default: begin
                    state_q <= RX_IDLE;
                end
            endcase
        end
    end

endmodule

