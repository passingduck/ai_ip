module lfsr8 (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    output logic [7:0] state_o,
    output logic       bit_o
);

    /* verilator lint_off UNUSEDSIGNAL */
    logic zero_state_unused;
    /* verilator lint_on UNUSEDSIGNAL */

    configurable_lfsr #(
        .WIDTH(8),
        .TAP_MASK(8'h8E),
        .RESET_SEED(8'h5A)
    ) u_lfsr (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .load_seed(1'b0),
        .seed_i(8'h00),
        .state_o(state_o),
        .bit_o(bit_o),
        .zero_state_o(zero_state_unused)
    );

endmodule
