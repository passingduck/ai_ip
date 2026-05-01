module uart_tx #(
    parameter int unsigned CLKS_PER_BIT = 234
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tx_valid,
    input  logic [7:0] tx_data,
    output logic       tx_ready,
    output logic       tx_o,
    output logic       tx_busy,
    output logic       tx_done
);

    typedef enum logic [2:0] {
        TX_IDLE,
        TX_START,
        TX_DATA,
        TX_STOP,
        TX_DONE
    } tx_state_t;

    tx_state_t state_q;
    int unsigned clk_count_q;
    logic [2:0] bit_index_q;
    logic [7:0] data_q;

    assign tx_ready = (state_q == TX_IDLE);
    assign tx_busy = (state_q != TX_IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= TX_IDLE;
            clk_count_q <= 0;
            bit_index_q <= 3'd0;
            data_q <= 8'h00;
            tx_o <= 1'b1;
            tx_done <= 1'b0;
        end else begin
            tx_done <= 1'b0;

            unique case (state_q)
                TX_IDLE: begin
                    tx_o <= 1'b1;
                    clk_count_q <= 0;
                    bit_index_q <= 3'd0;
                    if (tx_valid) begin
                        data_q <= tx_data;
                        state_q <= TX_START;
                    end
                end

                TX_START: begin
                    tx_o <= 1'b0;
                    if (clk_count_q == CLKS_PER_BIT - 1) begin
                        clk_count_q <= 0;
                        state_q <= TX_DATA;
                    end else begin
                        clk_count_q <= clk_count_q + 1;
                    end
                end

                TX_DATA: begin
                    tx_o <= data_q[bit_index_q];
                    if (clk_count_q == CLKS_PER_BIT - 1) begin
                        clk_count_q <= 0;
                        if (bit_index_q == 3'd7) begin
                            bit_index_q <= 3'd0;
                            state_q <= TX_STOP;
                        end else begin
                            bit_index_q <= bit_index_q + 1'b1;
                        end
                    end else begin
                        clk_count_q <= clk_count_q + 1;
                    end
                end

                TX_STOP: begin
                    tx_o <= 1'b1;
                    if (clk_count_q == CLKS_PER_BIT - 1) begin
                        clk_count_q <= 0;
                        state_q <= TX_DONE;
                    end else begin
                        clk_count_q <= clk_count_q + 1;
                    end
                end

                TX_DONE: begin
                    tx_done <= 1'b1;
                    state_q <= TX_IDLE;
                end

                default: begin
                    state_q <= TX_IDLE;
                end
            endcase
        end
    end

endmodule

