module top (
    input  logic       clk,
    input  logic [1:0] btn_n,
    output logic [5:0] led_n
);

    logic [23:0] div_q;
    logic slow_tick;
    logic rst_n;
    logic [15:0] state;

    assign rst_n = btn_n[0];
    assign slow_tick = (div_q == 24'd0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_q <= 24'd0;
        end else begin
            div_q <= div_q + 24'd1;
        end
    end

    configurable_lfsr #(
        .WIDTH(16),
        .TAP_MASK(16'hB400),
        .RESET_SEED(16'hACE1)
    ) u_lfsr (
        .clk(clk),
        .rst_n(rst_n),
        .enable(slow_tick),
        .load_seed(~btn_n[1]),
        .seed_i(16'h1D0F),
        .state_o(state),
        .bit_o(),
        .zero_state_o()
    );

    assign led_n = ~state[5:0];

endmodule

