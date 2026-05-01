module rtos_lcd_mmio (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        cmd_wr,
    input  logic        value_wr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    output logic        lcd_rst_n,
    output logic        lcd_sclk,
    output logic        lcd_cs_n,
    output logic        lcd_dc,
    output logic        lcd_mosi
);

    localparam int unsigned MAX_CMDS = 69;
    localparam int unsigned WINDOW_CMD_START = 59;
    localparam int unsigned CNT_100MS = 2_700_000;
    localparam int unsigned CNT_120MS = 3_240_000;
    localparam int unsigned CNT_200MS = 5_400_000;
    localparam int unsigned LCD_WIDTH = 240;
    localparam int unsigned LCD_HEIGHT = 135;
    localparam int unsigned PIXEL_COUNT = LCD_WIDTH * LCD_HEIGHT;
    localparam int unsigned TEXT_SCALE = 7;
    localparam int unsigned TEXT_WIDTH = 4 * 6 * TEXT_SCALE;
    localparam int signed TEXT_X = (int'(LCD_WIDTH) - int'(TEXT_WIDTH)) / 2;
    localparam int signed TEXT_Y = (int'(LCD_HEIGHT) - int'(7 * TEXT_SCALE)) / 2;
    localparam logic [6:0] CMD_DONE_INDEX = 7'(MAX_CMDS + 1);
    localparam logic [15:0] BLUE_RGB565 = 16'h001f;
    localparam logic [15:0] WHITE_RGB565 = 16'hffff;
    localparam logic [15:0] BLACK_RGB565 = 16'h0000;

    typedef enum logic [2:0] {
        INIT_RESET,
        INIT_PREPARE,
        INIT_WAKEUP,
        INIT_SNOOZE,
        INIT_WORKING,
        DRAW_FRAME
    } lcd_state_t;

    lcd_state_t state_q;
    logic [6:0] cmd_index_q;
    logic [31:0] clk_cnt_q;
    logic [4:0] bit_loop_q;
    logic [15:0] pixel_cnt_q;
    logic [15:0] pixel_x_q;
    logic [15:0] pixel_y_q;
    logic [7:0] spi_data_q;
    logic [8:0] init_cmd;
    logic [15:0] pixel;
    logic [31:0] value_q;
    logic [1:0] display_mode_q;
    logic [3:0] digit_0_q;
    logic [3:0] digit_1_q;
    logic [3:0] digit_2_q;
    logic [3:0] digit_3_q;

    assign lcd_sclk = ~clk;
    assign lcd_mosi = spi_data_q[7];
    assign rdata = (display_mode_q == 2'd2) ? value_q : {30'd0, display_mode_q};

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

    function automatic logic [6:0] segment_mask(input logic [3:0] glyph);
        begin
            unique case (glyph)
                4'd0: segment_mask = 7'b0111111;
                4'd1: segment_mask = 7'b0000110;
                4'd2: segment_mask = 7'b1011011;
                4'd3: segment_mask = 7'b1001111;
                4'd4: segment_mask = 7'b1100110;
                4'd5: segment_mask = 7'b1101101;
                4'd6: segment_mask = 7'b1111101;
                4'd7: segment_mask = 7'b0000111;
                4'd8: segment_mask = 7'b1111111;
                4'd9: segment_mask = 7'b1101111;
                4'd10: segment_mask = 7'b0000110; // I
                4'd11: segment_mask = 7'b0111111; // D/O-like
                4'd12: segment_mask = 7'b0111000; // L
                4'd13: segment_mask = 7'b1111001; // E
                default: segment_mask = 7'b0000000;
            endcase
        end
    endfunction

    function automatic logic [3:0] text_glyph(input logic [1:0] mode, input logic [1:0] index);
        begin
            if (mode == 2'd1) begin
                unique case (index)
                    2'd0: text_glyph = 4'd10;
                    2'd1: text_glyph = 4'd11;
                    2'd2: text_glyph = 4'd12;
                    default: text_glyph = 4'd13;
                endcase
            end else begin
                unique case (index)
                    2'd0: text_glyph = digit_3_q;
                    2'd1: text_glyph = digit_2_q;
                    2'd2: text_glyph = digit_1_q;
                    default: text_glyph = digit_0_q;
                endcase
            end
        end
    endfunction

    function automatic logic text_pixel_on(input int signed x, input int signed y);
        int signed char_base_x;
        int signed local_x;
        int signed local_y;
        logic [3:0] glyph;
        logic [6:0] segments;
        logic seg_a;
        logic seg_b;
        logic seg_c;
        logic seg_d;
        logic seg_e;
        logic seg_f;
        logic seg_g;
        begin
            text_pixel_on = 1'b0;
            if (display_mode_q != 2'd0) begin
                for (int unsigned char_idx = 0; char_idx < 4; char_idx++) begin
                    char_base_x = TEXT_X + int'(char_idx * 6 * TEXT_SCALE);
                    local_x = x - char_base_x;
                    local_y = y - TEXT_Y;
                    glyph = text_glyph(display_mode_q, char_idx[1:0]);
                    segments = segment_mask(glyph);
                    seg_a = local_x >= int'(TEXT_SCALE) && local_x < int'(4 * TEXT_SCALE)
                            && local_y >= 0 && local_y < int'(TEXT_SCALE);
                    seg_b = local_x >= int'(4 * TEXT_SCALE) && local_x < int'(5 * TEXT_SCALE)
                            && local_y >= int'(TEXT_SCALE) && local_y < int'(3 * TEXT_SCALE);
                    seg_c = local_x >= int'(4 * TEXT_SCALE) && local_x < int'(5 * TEXT_SCALE)
                            && local_y >= int'(4 * TEXT_SCALE) && local_y < int'(6 * TEXT_SCALE);
                    seg_d = local_x >= int'(TEXT_SCALE) && local_x < int'(4 * TEXT_SCALE)
                            && local_y >= int'(6 * TEXT_SCALE) && local_y < int'(7 * TEXT_SCALE);
                    seg_e = local_x >= 0 && local_x < int'(TEXT_SCALE)
                            && local_y >= int'(4 * TEXT_SCALE) && local_y < int'(6 * TEXT_SCALE);
                    seg_f = local_x >= 0 && local_x < int'(TEXT_SCALE)
                            && local_y >= int'(TEXT_SCALE) && local_y < int'(3 * TEXT_SCALE);
                    seg_g = local_x >= int'(TEXT_SCALE) && local_x < int'(4 * TEXT_SCALE)
                            && local_y >= int'(3 * TEXT_SCALE) && local_y < int'(4 * TEXT_SCALE);
                    if ((segments[0] && seg_a) || (segments[1] && seg_b)
                            || (segments[2] && seg_c) || (segments[3] && seg_d)
                            || (segments[4] && seg_e) || (segments[5] && seg_f)
                            || (segments[6] && seg_g)) begin
                        text_pixel_on = 1'b1;
                    end
                end
            end
        end
    endfunction

    always_comb begin
        if (text_pixel_on(int'(pixel_x_q), int'(pixel_y_q))) begin
            pixel = (display_mode_q == 2'd1) ? WHITE_RGB565 : BLUE_RGB565;
        end else begin
            pixel = BLACK_RGB565;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            value_q <= 32'd0;
            display_mode_q <= 2'd0;
            digit_0_q <= 4'd0;
            digit_1_q <= 4'd0;
            digit_2_q <= 4'd0;
            digit_3_q <= 4'd0;
        end else begin
            if (value_wr) begin
                value_q <= wdata;
                digit_0_q <= wdata[3:0];
                digit_1_q <= wdata[7:4];
                digit_2_q <= wdata[11:8];
                digit_3_q <= wdata[15:12];
            end

            if (cmd_wr) begin
                unique case (wdata[1:0])
                    2'd0: display_mode_q <= 2'd0;
                    2'd1: display_mode_q <= 2'd1;
                    2'd2: display_mode_q <= 2'd2;
                    default: display_mode_q <= display_mode_q;
                endcase
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt_q <= 32'd0;
            cmd_index_q <= 7'd0;
            state_q <= INIT_RESET;
            lcd_cs_n <= 1'b1;
            lcd_dc <= 1'b1;
            lcd_rst_n <= 1'b0;
            spi_data_q <= 8'hff;
            bit_loop_q <= 5'd0;
            pixel_cnt_q <= 16'd0;
            pixel_x_q <= 16'd0;
            pixel_y_q <= 16'd0;
        end else begin
            unique case (state_q)
                INIT_RESET: begin
                    if (clk_cnt_q == CNT_100MS) begin
                        clk_cnt_q <= 32'd0;
                        state_q <= INIT_PREPARE;
                        lcd_rst_n <= 1'b1;
                    end else begin
                        clk_cnt_q <= clk_cnt_q + 32'd1;
                    end
                end

                INIT_PREPARE: begin
                    if (clk_cnt_q == CNT_200MS) begin
                        clk_cnt_q <= 32'd0;
                        state_q <= INIT_WAKEUP;
                    end else begin
                        clk_cnt_q <= clk_cnt_q + 32'd1;
                    end
                end

                INIT_WAKEUP: begin
                    if (bit_loop_q == 5'd0) begin
                        lcd_cs_n <= 1'b0;
                        lcd_dc <= 1'b0;
                        spi_data_q <= 8'h11;
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end else if (bit_loop_q == 5'd8) begin
                        lcd_cs_n <= 1'b1;
                        lcd_dc <= 1'b1;
                        bit_loop_q <= 5'd0;
                        state_q <= INIT_SNOOZE;
                    end else begin
                        spi_data_q <= {spi_data_q[6:0], 1'b1};
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end
                end

                INIT_SNOOZE: begin
                    if (clk_cnt_q == CNT_120MS) begin
                        clk_cnt_q <= 32'd0;
                        state_q <= INIT_WORKING;
                    end else begin
                        clk_cnt_q <= clk_cnt_q + 32'd1;
                    end
                end

                INIT_WORKING: begin
                    if (cmd_index_q == CMD_DONE_INDEX) begin
                        pixel_cnt_q <= 16'd0;
                        pixel_x_q <= 16'd0;
                        pixel_y_q <= 16'd0;
                        state_q <= DRAW_FRAME;
                    end else if (bit_loop_q == 5'd0) begin
                        lcd_cs_n <= 1'b0;
                        lcd_dc <= init_cmd[8];
                        spi_data_q <= init_cmd[7:0];
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end else if (bit_loop_q == 5'd8) begin
                        lcd_cs_n <= 1'b1;
                        lcd_dc <= 1'b1;
                        bit_loop_q <= 5'd0;
                        cmd_index_q <= cmd_index_q + 7'd1;
                    end else begin
                        spi_data_q <= {spi_data_q[6:0], 1'b1};
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end
                end

                DRAW_FRAME: begin
                    if (pixel_cnt_q == PIXEL_COUNT[15:0]) begin
                        cmd_index_q <= 7'(WINDOW_CMD_START);
                        bit_loop_q <= 5'd0;
                        state_q <= INIT_WORKING;
                    end else if (bit_loop_q == 5'd0) begin
                        lcd_cs_n <= 1'b0;
                        lcd_dc <= 1'b1;
                        spi_data_q <= pixel[15:8];
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end else if (bit_loop_q == 5'd8) begin
                        spi_data_q <= pixel[7:0];
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end else if (bit_loop_q == 5'd16) begin
                        lcd_cs_n <= 1'b1;
                        lcd_dc <= 1'b1;
                        bit_loop_q <= 5'd0;
                        pixel_cnt_q <= pixel_cnt_q + 16'd1;
                        if (pixel_x_q == 16'(LCD_WIDTH - 1)) begin
                            pixel_x_q <= 16'd0;
                            pixel_y_q <= pixel_y_q + 16'd1;
                        end else begin
                            pixel_x_q <= pixel_x_q + 16'd1;
                        end
                    end else begin
                        spi_data_q <= {spi_data_q[6:0], 1'b1};
                        bit_loop_q <= bit_loop_q + 5'd1;
                    end
                end

                default: begin
                    state_q <= INIT_RESET;
                end
            endcase
        end
    end

endmodule
