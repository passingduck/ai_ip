module lfsr_csr #(
    parameter int unsigned WIDTH = 16,
    parameter logic [WIDTH-1:0] RESET_SEED = 16'hACE1,
    parameter logic [WIDTH-1:0] RESET_TAP_MASK = 16'hB400
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        csr_valid,
    input  logic        csr_write,
    input  logic [4:0]  csr_addr,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [31:0] csr_wdata,
    /* verilator lint_on UNUSEDSIGNAL */
    output logic [31:0] csr_rdata,
    output logic        csr_ready,
    output logic [WIDTH-1:0] state_o,
    output logic        bit_o,
    output logic        zero_state_o,
    output logic        period_done_o
);

    localparam logic [WIDTH-1:0] ONE_SEED = {{(WIDTH-1){1'b0}}, 1'b1};
    localparam logic [WIDTH-1:0] RESET_SEED_SAFE =
        (RESET_SEED == '0) ? ONE_SEED : RESET_SEED;

    logic enable_q;
    logic [WIDTH-1:0] seed_q;
    logic [WIDTH-1:0] tap_mask_q;
    logic [WIDTH-1:0] state_q;
    logic [WIDTH-1:0] loaded_seed_q;
    logic period_seen_q;
    logic feedback;
    logic [WIDTH-1:0] next_state;

    assign csr_ready = csr_valid;
    assign feedback = ^(state_q & tap_mask_q);
    assign next_state = {state_q[WIDTH-2:0], feedback};
    assign state_o = state_q;
    assign bit_o = state_q[WIDTH-1];
    assign zero_state_o = (state_q == '0);
    assign period_done_o = period_seen_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_q <= 1'b0;
            seed_q <= RESET_SEED_SAFE;
            tap_mask_q <= RESET_TAP_MASK;
            state_q <= RESET_SEED_SAFE;
            loaded_seed_q <= RESET_SEED_SAFE;
            period_seen_q <= 1'b0;
        end else begin
            if (csr_valid && csr_write) begin
                unique case (csr_addr)
                    5'h00: begin
                        enable_q <= csr_wdata[0];
                        if (csr_wdata[2]) begin
                            state_q <= RESET_SEED_SAFE;
                            loaded_seed_q <= RESET_SEED_SAFE;
                            period_seen_q <= 1'b0;
                        end else if (csr_wdata[1]) begin
                            state_q <= seed_q;
                            loaded_seed_q <= seed_q;
                            period_seen_q <= 1'b0;
                        end
                    end
                    5'h04: begin
                        // Upper CSR write bits are intentionally ignored for WIDTH < 32.
                        /* verilator lint_off UNUSEDSIGNAL */
                        seed_q <= csr_wdata[WIDTH-1:0] == '0
                            ? RESET_SEED_SAFE
                            : csr_wdata[WIDTH-1:0];
                        /* verilator lint_on UNUSEDSIGNAL */
                    end
                    5'h08: begin
                        /* verilator lint_off UNUSEDSIGNAL */
                        tap_mask_q <= csr_wdata[WIDTH-1:0];
                        /* verilator lint_on UNUSEDSIGNAL */
                        period_seen_q <= 1'b0;
                    end
                    default: begin
                    end
                endcase
            end else if (enable_q) begin
                state_q <= (state_q == '0) ? RESET_SEED_SAFE : next_state;
                if (next_state == loaded_seed_q) begin
                    period_seen_q <= 1'b1;
                end
            end
        end
    end

    always_comb begin
        unique case (csr_addr)
            5'h00: csr_rdata = {29'b0, 1'b0, 1'b0, enable_q};
            5'h04: csr_rdata = {{(32-WIDTH){1'b0}}, seed_q};
            5'h08: csr_rdata = {{(32-WIDTH){1'b0}}, tap_mask_q};
            5'h0c: csr_rdata = {{(32-WIDTH){1'b0}}, state_o};
            5'h10: csr_rdata = {30'b0, period_done_o, zero_state_o};
            default: csr_rdata = 32'b0;
        endcase
    end

endmodule
