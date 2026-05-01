module spi_lcd_deepx_demo #(
    parameter int unsigned LCD_WIDTH = 240,
    parameter int unsigned LCD_HEIGHT = 135,
    parameter int unsigned LCD_X_OFFSET = 40,
    parameter int unsigned LCD_Y_OFFSET = 53,
    parameter logic [7:0] MADCTL = 8'h70,
    parameter int unsigned TEXT_SCALE = 6,
    parameter int unsigned SLIDE_STEP = 4,
    parameter int unsigned CLKS_PER_HALF_SCLK = 1
) (
    input  logic       clk,
    input  logic       rst_n,
    output logic       lcd_sclk,
    output logic       lcd_mosi,
    output logic       lcd_cs_n,
    output logic       lcd_dc,
    output logic       lcd_rst_n,
    output logic       lcd_bl,
    output logic [5:0] debug_led_n
);

    localparam int unsigned RESET_LOW_CLKS = 270_000;
    localparam int unsigned RESET_HIGH_CLKS = 3_240_000;
    localparam int unsigned DELAY_10MS_CLKS = 270_000;
    localparam int unsigned DELAY_100MS_CLKS = 2_700_000;
    localparam int unsigned DELAY_120MS_CLKS = 3_240_000;
    localparam int unsigned DELAY_150MS_CLKS = 4_050_000;
    localparam int unsigned TEXT_COLUMNS = 30;
    localparam int unsigned TEXT_WIDTH = TEXT_COLUMNS * TEXT_SCALE;
    localparam int unsigned TEXT_HEIGHT = 7 * TEXT_SCALE;
    localparam int signed TEXT_Y = (int'(LCD_HEIGHT) - int'(TEXT_HEIGHT)) / 2;
    localparam logic [15:0] X_START = 16'(LCD_X_OFFSET);
    localparam logic [15:0] Y_START = 16'(LCD_Y_OFFSET);
    localparam logic [15:0] X_END = 16'(LCD_X_OFFSET + LCD_WIDTH - 1);
    localparam logic [15:0] Y_END = 16'(LCD_Y_OFFSET + LCD_HEIGHT - 1);
    localparam logic [15:0] MAX_X = 16'(LCD_WIDTH - 1);
    localparam logic [15:0] MAX_Y = 16'(LCD_HEIGHT - 1);
    localparam logic [15:0] BLUE_RGB565 = 16'h001f;
    localparam logic [15:0] BLACK_RGB565 = 16'h0000;

    typedef enum logic [3:0] {
        S_RESET_LOW,
        S_RESET_HIGH,
        S_INIT,
        S_DELAY,
        S_SEND_WAIT,
        S_WINDOW,
        S_PIXEL_HIGH,
        S_PIXEL_LOW,
        S_FRAME_DONE
    } state_t;

    state_t state_q;
    state_t return_state_q;
    logic spi_start_q;
    logic spi_dc_q;
    logic [7:0] spi_data_q;
    logic spi_ready;
    logic spi_done;
    logic [4:0] init_step_q;
    logic [3:0] window_step_q;
    logic [15:0] pixel_x_q;
    logic [15:0] pixel_y_q;
    logic [7:0] pixel_low_q;
    int unsigned wait_count_q;
    int unsigned delay_target_q;
    int signed slide_x_q;
    logic frame_toggle_q;

    spi_lcd_byte_tx #(
        .CLKS_PER_HALF_SCLK(CLKS_PER_HALF_SCLK)
    ) u_spi_tx (
        .clk(clk),
        .rst_n(rst_n),
        .start(spi_start_q),
        .dc_i(spi_dc_q),
        .data_i(spi_data_q),
        .ready(spi_ready),
        .done(spi_done),
        .lcd_sclk(lcd_sclk),
        .lcd_mosi(lcd_mosi),
        .lcd_cs_n(lcd_cs_n),
        .lcd_dc(lcd_dc)
    );

    function automatic logic [4:0] glyph_row(input logic [2:0] char_index, input logic [2:0] row);
        unique case (char_index)
            3'd0: begin
                unique case (row)
                    3'd0: glyph_row = 5'b11110;
                    3'd1: glyph_row = 5'b10001;
                    3'd2: glyph_row = 5'b10001;
                    3'd3: glyph_row = 5'b10001;
                    3'd4: glyph_row = 5'b10001;
                    3'd5: glyph_row = 5'b10001;
                    default: glyph_row = 5'b11110;
                endcase
            end
            3'd1, 3'd2: begin
                unique case (row)
                    3'd0: glyph_row = 5'b11111;
                    3'd1: glyph_row = 5'b10000;
                    3'd2: glyph_row = 5'b10000;
                    3'd3: glyph_row = 5'b11110;
                    3'd4: glyph_row = 5'b10000;
                    3'd5: glyph_row = 5'b10000;
                    default: glyph_row = 5'b11111;
                endcase
            end
            3'd3: begin
                unique case (row)
                    3'd0: glyph_row = 5'b11110;
                    3'd1: glyph_row = 5'b10001;
                    3'd2: glyph_row = 5'b10001;
                    3'd3: glyph_row = 5'b11110;
                    3'd4: glyph_row = 5'b10000;
                    3'd5: glyph_row = 5'b10000;
                    default: glyph_row = 5'b10000;
                endcase
            end
            default: begin
                unique case (row)
                    3'd0: glyph_row = 5'b10001;
                    3'd1: glyph_row = 5'b01010;
                    3'd2: glyph_row = 5'b00100;
                    3'd3: glyph_row = 5'b00100;
                    3'd4: glyph_row = 5'b00100;
                    3'd5: glyph_row = 5'b01010;
                    default: glyph_row = 5'b10001;
                endcase
            end
        endcase
    endfunction

    function automatic logic text_pixel_on(input int signed x, input int signed y, input int signed text_x);
        int signed rel_x;
        int signed rel_y;
        int unsigned slot;
        int unsigned glyph_col;
        int unsigned glyph_r;
        logic [4:0] row_bits;
        begin
            text_pixel_on = 1'b0;
            rel_x = x - text_x;
            rel_y = y - TEXT_Y;

            if (rel_x >= 0 && rel_x < int'(TEXT_WIDTH) && rel_y >= 0 && rel_y < int'(TEXT_HEIGHT)) begin
                slot = rel_x / (6 * TEXT_SCALE);
                glyph_col = (rel_x / TEXT_SCALE) % 6;
                glyph_r = rel_y / TEXT_SCALE;
                if (slot < 5 && glyph_col < 5 && glyph_r < 7) begin
                    row_bits = glyph_row(slot[2:0], glyph_r[2:0]);
                    text_pixel_on = row_bits[4 - glyph_col];
                end
            end
        end
    endfunction

    function automatic logic [15:0] pixel_color(input logic [15:0] px, input logic [15:0] py, input int signed text_x);
        if (text_pixel_on(int'(px), int'(py), text_x)) begin
            pixel_color = BLUE_RGB565;
        end else begin
            pixel_color = BLACK_RGB565;
        end
    endfunction

    function automatic logic [7:0] window_byte(input logic [3:0] step);
        begin
            unique case (step)
                4'd0: window_byte = 8'h2a;
                4'd1: window_byte = X_START[15:8];
                4'd2: window_byte = X_START[7:0];
                4'd3: window_byte = X_END[15:8];
                4'd4: window_byte = X_END[7:0];
                4'd5: window_byte = 8'h2b;
                4'd6: window_byte = Y_START[15:8];
                4'd7: window_byte = Y_START[7:0];
                4'd8: window_byte = Y_END[15:8];
                4'd9: window_byte = Y_END[7:0];
                default: window_byte = 8'h2c;
            endcase
        end
    endfunction

    function automatic logic window_dc(input logic [3:0] step);
        window_dc = !(step == 4'd0 || step == 4'd5 || step == 4'd10);
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_RESET_LOW;
            return_state_q <= S_INIT;
            spi_start_q <= 1'b0;
            spi_dc_q <= 1'b0;
            spi_data_q <= 8'h00;
            init_step_q <= 5'd0;
            window_step_q <= 4'd0;
            pixel_x_q <= 16'd0;
            pixel_y_q <= 16'd0;
            pixel_low_q <= BLACK_RGB565[7:0];
            wait_count_q <= 0;
            delay_target_q <= RESET_LOW_CLKS;
            slide_x_q <= int'(LCD_WIDTH);
            frame_toggle_q <= 1'b0;
            lcd_rst_n <= 1'b0;
            lcd_bl <= 1'b0;
        end else begin
            spi_start_q <= 1'b0;

            unique case (state_q)
                S_RESET_LOW: begin
                    lcd_rst_n <= 1'b0;
                    lcd_bl <= 1'b0;
                    if (wait_count_q == RESET_LOW_CLKS - 1) begin
                        wait_count_q <= 0;
                        state_q <= S_RESET_HIGH;
                    end else begin
                        wait_count_q <= wait_count_q + 1;
                    end
                end

                S_RESET_HIGH: begin
                    lcd_rst_n <= 1'b1;
                    lcd_bl <= 1'b1;
                    if (wait_count_q == RESET_HIGH_CLKS - 1) begin
                        wait_count_q <= 0;
                        init_step_q <= 5'd0;
                        state_q <= S_INIT;
                    end else begin
                        wait_count_q <= wait_count_q + 1;
                    end
                end

                S_INIT: begin
                    if (spi_ready) begin
                        unique case (init_step_q)
                            5'd0: begin
                                spi_dc_q <= 1'b0;
                                spi_data_q <= 8'h01;
                                spi_start_q <= 1'b1;
                                init_step_q <= 5'd1;
                                return_state_q <= S_INIT;
                                state_q <= S_SEND_WAIT;
                            end
                            5'd1: begin
                                delay_target_q <= DELAY_150MS_CLKS;
                                init_step_q <= 5'd2;
                                state_q <= S_DELAY;
                            end
                            5'd2: begin
                                spi_dc_q <= 1'b0;
                                spi_data_q <= 8'h11;
                                spi_start_q <= 1'b1;
                                init_step_q <= 5'd3;
                                return_state_q <= S_INIT;
                                state_q <= S_SEND_WAIT;
                            end
                            5'd3: begin
                                delay_target_q <= DELAY_120MS_CLKS;
                                init_step_q <= 5'd4;
                                state_q <= S_DELAY;
                            end
                            5'd4: begin
                                spi_dc_q <= 1'b0;
                                spi_data_q <= 8'h3a;
                                spi_start_q <= 1'b1;
                                init_step_q <= 5'd5;
                                return_state_q <= S_INIT;
                                state_q <= S_SEND_WAIT;
                            end
                            5'd5: begin
                                spi_dc_q <= 1'b1;
                                spi_data_q <= 8'h55;
                                spi_start_q <= 1'b1;
                                init_step_q <= 5'd6;
                                return_state_q <= S_INIT;
                                state_q <= S_SEND_WAIT;
                            end
                            5'd6: begin
                                spi_dc_q <= 1'b0;
                                spi_data_q <= 8'h36;
                                spi_start_q <= 1'b1;
                                init_step_q <= 5'd7;
                                return_state_q <= S_INIT;
                                state_q <= S_SEND_WAIT;
                            end
                            5'd7: begin
                                spi_dc_q <= 1'b1;
                                spi_data_q <= MADCTL;
                                spi_start_q <= 1'b1;
                                init_step_q <= 5'd8;
                                return_state_q <= S_INIT;
                                state_q <= S_SEND_WAIT;
                            end
                            5'd8: begin
                                spi_dc_q <= 1'b0;
                                spi_data_q <= 8'h21;
                                spi_start_q <= 1'b1;
                                init_step_q <= 5'd9;
                                return_state_q <= S_INIT;
                                state_q <= S_SEND_WAIT;
                            end
                            5'd9: begin
                                spi_dc_q <= 1'b0;
                                spi_data_q <= 8'h13;
                                spi_start_q <= 1'b1;
                                init_step_q <= 5'd10;
                                return_state_q <= S_INIT;
                                state_q <= S_SEND_WAIT;
                            end
                            5'd10: begin
                                delay_target_q <= DELAY_10MS_CLKS;
                                init_step_q <= 5'd11;
                                state_q <= S_DELAY;
                            end
                            5'd11: begin
                                spi_dc_q <= 1'b0;
                                spi_data_q <= 8'h29;
                                spi_start_q <= 1'b1;
                                init_step_q <= 5'd12;
                                return_state_q <= S_INIT;
                                state_q <= S_SEND_WAIT;
                            end
                            5'd12: begin
                                delay_target_q <= DELAY_100MS_CLKS;
                                init_step_q <= 5'd13;
                                state_q <= S_DELAY;
                            end
                            default: begin
                                window_step_q <= 4'd0;
                                pixel_x_q <= 16'd0;
                                pixel_y_q <= 16'd0;
                                state_q <= S_WINDOW;
                            end
                        endcase
                    end
                end

                S_DELAY: begin
                    if (wait_count_q == delay_target_q - 1) begin
                        wait_count_q <= 0;
                        state_q <= S_INIT;
                    end else begin
                        wait_count_q <= wait_count_q + 1;
                    end
                end

                S_SEND_WAIT: begin
                    if (spi_done) begin
                        state_q <= return_state_q;
                    end
                end

                S_WINDOW: begin
                    if (spi_ready) begin
                        spi_dc_q <= window_dc(window_step_q);
                        spi_data_q <= window_byte(window_step_q);
                        spi_start_q <= 1'b1;
                        if (window_step_q == 4'd10) begin
                            pixel_x_q <= 16'd0;
                            pixel_y_q <= 16'd0;
                            return_state_q <= S_PIXEL_HIGH;
                        end else begin
                            window_step_q <= window_step_q + 1'b1;
                            return_state_q <= S_WINDOW;
                        end
                        state_q <= S_SEND_WAIT;
                    end
                end

                S_PIXEL_HIGH: begin
                    if (spi_ready) begin
                        spi_dc_q <= 1'b1;
                        if (text_pixel_on(int'(pixel_x_q), int'(pixel_y_q), slide_x_q)) begin
                            spi_data_q <= BLUE_RGB565[15:8];
                            pixel_low_q <= BLUE_RGB565[7:0];
                        end else begin
                            spi_data_q <= BLACK_RGB565[15:8];
                            pixel_low_q <= BLACK_RGB565[7:0];
                        end
                        spi_start_q <= 1'b1;
                        return_state_q <= S_PIXEL_LOW;
                        state_q <= S_SEND_WAIT;
                    end
                end

                S_PIXEL_LOW: begin
                    if (spi_ready) begin
                        spi_dc_q <= 1'b1;
                        spi_data_q <= pixel_low_q;
                        spi_start_q <= 1'b1;
                        return_state_q <= S_PIXEL_HIGH;
                        state_q <= S_SEND_WAIT;

                        if (pixel_x_q == MAX_X) begin
                            pixel_x_q <= 16'd0;
                            if (pixel_y_q == MAX_Y) begin
                                pixel_y_q <= 16'd0;
                                return_state_q <= S_FRAME_DONE;
                            end else begin
                                pixel_y_q <= pixel_y_q + 1'b1;
                            end
                        end else begin
                            pixel_x_q <= pixel_x_q + 1'b1;
                        end
                    end
                end

                S_FRAME_DONE: begin
                    frame_toggle_q <= ~frame_toggle_q;
                    if (slide_x_q < -int'(TEXT_WIDTH)) begin
                        slide_x_q <= int'(LCD_WIDTH);
                    end else begin
                        slide_x_q <= slide_x_q - int'(SLIDE_STEP);
                    end
                    window_step_q <= 4'd0;
                    state_q <= S_WINDOW;
                end

                default: begin
                    state_q <= S_RESET_LOW;
                end
            endcase
        end
    end

    assign debug_led_n[0] = ~frame_toggle_q;
    assign debug_led_n[1] = ~lcd_rst_n;
    assign debug_led_n[2] = ~lcd_bl;
    assign debug_led_n[3] = ~lcd_cs_n;
    assign debug_led_n[4] = ~lcd_dc;
    assign debug_led_n[5] = ~lcd_sclk;

endmodule
