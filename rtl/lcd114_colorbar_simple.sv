module lcd114_colorbar_simple (
    input  logic clk,
    input  logic resetn,

    output logic lcd_resetn,
    output logic lcd_clk,
    output logic lcd_cs,
    output logic lcd_rs,
    output logic lcd_data,
    output logic [5:0] led_n
);

    localparam int unsigned MAX_CMDS = 69;
    localparam int unsigned CNT_100MS = 2_700_000;
    localparam int unsigned CNT_120MS = 3_240_000;
    localparam int unsigned CNT_200MS = 5_400_000;
    localparam int unsigned PIXEL_COUNT = 32_400;
    localparam logic [6:0] CMD_DONE_INDEX = 7'(MAX_CMDS + 1);

    typedef enum logic [2:0] {
        INIT_RESET,
        INIT_PREPARE,
        INIT_WAKEUP,
        INIT_SNOOZE,
        INIT_WORKING,
        INIT_DONE
    } init_state_t;

    init_state_t init_state_q;
    logic [6:0] cmd_index_q;
    logic [31:0] clk_cnt_q;
    logic [4:0] bit_loop_q;
    logic [15:0] pixel_cnt_q;
    logic [7:0] spi_data_q;
    logic [8:0] init_cmd;
    logic [15:0] pixel;

    assign lcd_clk = ~clk;
    assign lcd_data = spi_data_q[7];

    always_comb begin
        unique case (cmd_index_q)
            7'd0: init_cmd = 9'h036;
            7'd1: init_cmd = 9'h170;
            7'd2: init_cmd = 9'h03a;
            7'd3: init_cmd = 9'h105;
            7'd4: init_cmd = 9'h0b2;
            7'd5: init_cmd = 9'h10c;
            7'd6: init_cmd = 9'h10c;
            7'd7: init_cmd = 9'h100;
            7'd8: init_cmd = 9'h133;
            7'd9: init_cmd = 9'h133;
            7'd10: init_cmd = 9'h0b7;
            7'd11: init_cmd = 9'h135;
            7'd12: init_cmd = 9'h0bb;
            7'd13: init_cmd = 9'h119;
            7'd14: init_cmd = 9'h0c0;
            7'd15: init_cmd = 9'h12c;
            7'd16: init_cmd = 9'h0c2;
            7'd17: init_cmd = 9'h101;
            7'd18: init_cmd = 9'h0c3;
            7'd19: init_cmd = 9'h112;
            7'd20: init_cmd = 9'h0c4;
            7'd21: init_cmd = 9'h120;
            7'd22: init_cmd = 9'h0c6;
            7'd23: init_cmd = 9'h10f;
            7'd24: init_cmd = 9'h0d0;
            7'd25: init_cmd = 9'h1a4;
            7'd26: init_cmd = 9'h1a1;
            7'd27: init_cmd = 9'h0e0;
            7'd28: init_cmd = 9'h1d0;
            7'd29: init_cmd = 9'h104;
            7'd30: init_cmd = 9'h10d;
            7'd31: init_cmd = 9'h111;
            7'd32: init_cmd = 9'h113;
            7'd33: init_cmd = 9'h12b;
            7'd34: init_cmd = 9'h13f;
            7'd35: init_cmd = 9'h154;
            7'd36: init_cmd = 9'h14c;
            7'd37: init_cmd = 9'h118;
            7'd38: init_cmd = 9'h10d;
            7'd39: init_cmd = 9'h10b;
            7'd40: init_cmd = 9'h11f;
            7'd41: init_cmd = 9'h123;
            7'd42: init_cmd = 9'h0e1;
            7'd43: init_cmd = 9'h1d0;
            7'd44: init_cmd = 9'h104;
            7'd45: init_cmd = 9'h10c;
            7'd46: init_cmd = 9'h111;
            7'd47: init_cmd = 9'h113;
            7'd48: init_cmd = 9'h12c;
            7'd49: init_cmd = 9'h13f;
            7'd50: init_cmd = 9'h144;
            7'd51: init_cmd = 9'h151;
            7'd52: init_cmd = 9'h12f;
            7'd53: init_cmd = 9'h11f;
            7'd54: init_cmd = 9'h11f;
            7'd55: init_cmd = 9'h120;
            7'd56: init_cmd = 9'h123;
            7'd57: init_cmd = 9'h021;
            7'd58: init_cmd = 9'h029;
            7'd59: init_cmd = 9'h02a;
            7'd60: init_cmd = 9'h100;
            7'd61: init_cmd = 9'h128;
            7'd62: init_cmd = 9'h101;
            7'd63: init_cmd = 9'h117;
            7'd64: init_cmd = 9'h02b;
            7'd65: init_cmd = 9'h100;
            7'd66: init_cmd = 9'h135;
            7'd67: init_cmd = 9'h100;
            7'd68: init_cmd = 9'h1bb;
            default: init_cmd = 9'h02c;
        endcase
    end

    always_comb begin
        if (pixel_cnt_q >= 16'd21600) begin
            pixel = 16'hf800;
        end else if (pixel_cnt_q >= 16'd10800) begin
            pixel = 16'h07e0;
        end else begin
            pixel = 16'h001f;
        end
    end

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            clk_cnt_q <= 32'd0;
            cmd_index_q <= 7'd0;
            init_state_q <= INIT_RESET;
            lcd_cs <= 1'b1;
            lcd_rs <= 1'b1;
            lcd_resetn <= 1'b0;
            spi_data_q <= 8'hff;
            bit_loop_q <= 5'd0;
            pixel_cnt_q <= 16'd0;
            led_n <= 6'b111110;
        end else begin
            unique case (init_state_q)
                INIT_RESET: begin
                    led_n <= 6'b111110;
                    if (clk_cnt_q == CNT_100MS) begin
                        clk_cnt_q <= 32'd0;
                        init_state_q <= INIT_PREPARE;
                        lcd_resetn <= 1'b1;
                    end else begin
                        clk_cnt_q <= clk_cnt_q + 32'd1;
                    end
                end

                INIT_PREPARE: begin
                    led_n <= 6'b111101;
                    if (clk_cnt_q == CNT_200MS) begin
                        clk_cnt_q <= 32'd0;
                        init_state_q <= INIT_WAKEUP;
                    end else begin
                        clk_cnt_q <= clk_cnt_q + 32'd1;
                    end
                end

                INIT_WAKEUP: begin
                    led_n <= 6'b111011;
                    if (bit_loop_q == 5'd0) begin
                        lcd_cs <= 1'b0;
                        lcd_rs <= 1'b0;
                        spi_data_q <= 8'h11;
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end else if (bit_loop_q == 5'd8) begin
                        lcd_cs <= 1'b1;
                        lcd_rs <= 1'b1;
                        bit_loop_q <= 5'd0;
                        init_state_q <= INIT_SNOOZE;
                    end else begin
                        spi_data_q <= {spi_data_q[6:0], 1'b1};
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end
                end

                INIT_SNOOZE: begin
                    led_n <= 6'b110111;
                    if (clk_cnt_q == CNT_120MS) begin
                        clk_cnt_q <= 32'd0;
                        init_state_q <= INIT_WORKING;
                    end else begin
                        clk_cnt_q <= clk_cnt_q + 32'd1;
                    end
                end

                INIT_WORKING: begin
                    led_n <= 6'b101111;
                    if (cmd_index_q == CMD_DONE_INDEX) begin
                        init_state_q <= INIT_DONE;
                    end else if (bit_loop_q == 5'd0) begin
                        lcd_cs <= 1'b0;
                        lcd_rs <= init_cmd[8];
                        spi_data_q <= init_cmd[7:0];
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end else if (bit_loop_q == 5'd8) begin
                        lcd_cs <= 1'b1;
                        lcd_rs <= 1'b1;
                        bit_loop_q <= 5'd0;
                        cmd_index_q <= cmd_index_q + 7'd1;
                    end else begin
                        spi_data_q <= {spi_data_q[6:0], 1'b1};
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end
                end

                INIT_DONE: begin
                    led_n <= 6'b011111;
                    if (pixel_cnt_q != PIXEL_COUNT[15:0]) begin
                        if (bit_loop_q == 5'd0) begin
                            lcd_cs <= 1'b0;
                            lcd_rs <= 1'b1;
                            spi_data_q <= pixel[15:8];
                            bit_loop_q <= bit_loop_q + 5'd1;
                        end else if (bit_loop_q == 5'd8) begin
                            spi_data_q <= pixel[7:0];
                            bit_loop_q <= bit_loop_q + 5'd1;
                        end else if (bit_loop_q == 5'd16) begin
                            lcd_cs <= 1'b1;
                            lcd_rs <= 1'b1;
                            bit_loop_q <= 5'd0;
                            pixel_cnt_q <= pixel_cnt_q + 16'd1;
                        end else begin
                            spi_data_q <= {spi_data_q[6:0], 1'b1};
                            bit_loop_q <= bit_loop_q + 5'd1;
                        end
                    end
                end

                default: begin
                    init_state_q <= INIT_RESET;
                end
            endcase
        end
    end

endmodule
