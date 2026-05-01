module configurable_lfsr #(
    parameter int unsigned WIDTH = 16,
    parameter logic [WIDTH-1:0] TAP_MASK = 16'hB400,
    parameter logic [WIDTH-1:0] RESET_SEED = 16'hACE1
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             enable,
    input  logic             load_seed,
    input  logic [WIDTH-1:0] seed_i,
    output logic [WIDTH-1:0] state_o,
    output logic             bit_o,
    output logic             zero_state_o
);

    localparam logic [WIDTH-1:0] ONE_SEED = {{(WIDTH-1){1'b0}}, 1'b1};
    localparam logic [WIDTH-1:0] RESET_SEED_SAFE =
        (RESET_SEED == '0) ? ONE_SEED : RESET_SEED;

    logic feedback;
    logic [WIDTH-1:0] next_state;

    assign feedback = ^(state_o & TAP_MASK);
    assign next_state = {state_o[WIDTH-2:0], feedback};

    function automatic logic [WIDTH-1:0] sanitize_seed(
        input logic [WIDTH-1:0] seed
    );
        sanitize_seed = (seed == '0) ? RESET_SEED_SAFE : seed;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_o <= RESET_SEED_SAFE;
        end else if (load_seed) begin
            state_o <= sanitize_seed(seed_i);
        end else if (enable) begin
            state_o <= (state_o == '0) ? RESET_SEED_SAFE : next_state;
        end
    end

    assign bit_o = state_o[WIDTH-1];
    assign zero_state_o = (state_o == '0);

endmodule

