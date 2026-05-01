module lfsr16 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    output logic [15:0] state_o,
    output logic        bit_o
);

    /* verilator lint_off UNUSEDSIGNAL */
    logic zero_state_unused;
    /* verilator lint_on UNUSEDSIGNAL */

    configurable_lfsr #(
        .WIDTH(16),
        .TAP_MASK(16'hB400),
        .RESET_SEED(16'hACE1)
    ) u_lfsr (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .load_seed(1'b0),
        .seed_i(16'h0000),
        .state_o(state_o),
        .bit_o(bit_o),
        .zero_state_o(zero_state_unused)
    );

endmodule
