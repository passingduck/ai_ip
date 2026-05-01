module uart_echo #(
    parameter int unsigned CLKS_PER_BIT = 234,
    parameter int unsigned FIFO_DEPTH = 16
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       uart_rx_i,
    output logic       uart_tx_o,
    output logic [7:0] last_rx_data_o,
    output logic       rx_valid_o,
    output logic       framing_error_o,
    output logic       tx_busy_o,
    output logic       tx_done_o
);

    localparam int unsigned FIFO_AW = (FIFO_DEPTH <= 2) ? 1 : $clog2(FIFO_DEPTH);
    localparam int unsigned FIFO_COUNT_W = $clog2(FIFO_DEPTH + 1);

    logic tx_valid;
    logic tx_ready;
    logic tx_done;
    logic tx_busy;
    logic [7:0] rx_data;
    logic rx_valid;
    logic [7:0] fifo_q [FIFO_DEPTH];
    logic [FIFO_AW-1:0] wr_ptr_q;
    logic [FIFO_AW-1:0] rd_ptr_q;
    logic [FIFO_COUNT_W-1:0] fifo_count_q;
    logic fifo_full;
    logic fifo_empty;
    logic push;
    logic pop;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_i(uart_rx_i),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .framing_error(framing_error_o)
    );

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_valid(tx_valid),
        .tx_data(fifo_q[rd_ptr_q]),
        .tx_ready(tx_ready),
        .tx_o(uart_tx_o),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    assign fifo_empty = (fifo_count_q == '0);
    assign fifo_full = (fifo_count_q == FIFO_COUNT_W'(FIFO_DEPTH));
    assign pop = tx_valid;
    assign tx_valid = !fifo_empty && tx_ready;
    assign push = rx_valid && (!fifo_full || pop);
    assign rx_valid_o = rx_valid;
    assign tx_busy_o = tx_busy;
    assign tx_done_o = tx_done;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_q <= '0;
            rd_ptr_q <= '0;
            fifo_count_q <= '0;
            last_rx_data_o <= 8'h00;
        end else begin
            if (push) begin
                fifo_q[wr_ptr_q] <= rx_data;
                last_rx_data_o <= rx_data;
                if (wr_ptr_q == FIFO_AW'(FIFO_DEPTH - 1)) begin
                    wr_ptr_q <= '0;
                end else begin
                    wr_ptr_q <= wr_ptr_q + 1'b1;
                end
            end

            if (pop) begin
                if (rd_ptr_q == FIFO_AW'(FIFO_DEPTH - 1)) begin
                    rd_ptr_q <= '0;
                end else begin
                    rd_ptr_q <= rd_ptr_q + 1'b1;
                end
            end

            unique case ({push, pop})
                2'b10: fifo_count_q <= fifo_count_q + 1'b1;
                2'b01: fifo_count_q <= fifo_count_q - 1'b1;
                default: fifo_count_q <= fifo_count_q;
            endcase
        end
    end

    initial begin : init_fifo
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            fifo_q[i] = 8'h00;
        end
    end

    generate
        if (FIFO_DEPTH < 2) begin : gen_fifo_depth_check
            initial begin
                $error("uart_echo FIFO_DEPTH must be at least 2");
            end
        end
    endgenerate

endmodule
