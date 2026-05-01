module irq_timer_button #(
    parameter int unsigned CLK_HZ = 27_000_000
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        button_n,

    input  logic        bus_wr,
    input  logic        bus_rd,
    input  logic [3:0]  bus_addr,
    input  logic [31:0] bus_wdata,
    output logic [31:0] bus_rdata,

    output logic        irq_o,
    output logic        button_level_o
);

    localparam logic [31:0] DEFAULT_RELOAD = CLK_HZ / 1000;
    localparam logic [31:0] DEFAULT_DEBOUNCE = CLK_HZ / 50;

    logic [2:0] button_sync_q;
    logic button_level_q;
    logic button_stable_q;
    logic button_stable_d_q;
    logic [31:0] debounce_count_q;
    logic [31:0] debounce_limit_q;
    logic [31:0] timer_reload_q;
    logic [31:0] timer_count_q;
    logic [31:0] irq_pending_q;
    logic [31:0] irq_enable_q;

    assign button_level_o = button_stable_q;
    assign irq_o = |(irq_pending_q & irq_enable_q);

    always_comb begin
        bus_rdata = 32'd0;
        unique case (bus_addr)
            4'h0: if (bus_rd) bus_rdata = irq_pending_q;
            4'h1: if (bus_rd) bus_rdata = irq_enable_q;
            4'h2: if (bus_rd) bus_rdata = timer_reload_q;
            4'h3: if (bus_rd) bus_rdata = timer_count_q;
            4'h4: if (bus_rd) bus_rdata = {31'd0, button_stable_q};
            4'h5: if (bus_rd) bus_rdata = debounce_limit_q;
            default: begin
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_sync_q <= 3'b000;
            button_level_q <= 1'b0;
            button_stable_q <= 1'b0;
            button_stable_d_q <= 1'b0;
            debounce_count_q <= 32'd0;
            debounce_limit_q <= DEFAULT_DEBOUNCE;
            timer_reload_q <= DEFAULT_RELOAD;
            timer_count_q <= DEFAULT_RELOAD;
            irq_pending_q <= 32'd0;
            irq_enable_q <= 32'd0;
        end else begin
            button_sync_q <= {button_sync_q[1:0], ~button_n};
            button_level_q <= button_sync_q[2];
            button_stable_d_q <= button_stable_q;

            if (button_level_q == button_stable_q) begin
                debounce_count_q <= 32'd0;
            end else if (debounce_count_q >= debounce_limit_q) begin
                debounce_count_q <= 32'd0;
                button_stable_q <= button_level_q;
            end else begin
                debounce_count_q <= debounce_count_q + 32'd1;
            end

            if (timer_count_q == 32'd0) begin
                timer_count_q <= timer_reload_q;
                irq_pending_q[0] <= 1'b1;
            end else begin
                timer_count_q <= timer_count_q - 32'd1;
            end

            if (button_stable_q && !button_stable_d_q) begin
                irq_pending_q[1] <= 1'b1;
            end

            if (bus_wr) begin
                unique case (bus_addr)
                    4'h0: irq_pending_q <= irq_pending_q & ~bus_wdata;
                    4'h1: irq_enable_q <= bus_wdata;
                    4'h2: begin
                        timer_reload_q <= bus_wdata;
                        timer_count_q <= bus_wdata;
                    end
                    4'h5: debounce_limit_q <= bus_wdata;
                    default: begin
                    end
                endcase
            end
        end
    end

endmodule
