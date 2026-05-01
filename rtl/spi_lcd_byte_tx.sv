module spi_lcd_byte_tx #(
    parameter int unsigned CLKS_PER_HALF_SCLK = 1
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,
    input  logic       dc_i,
    input  logic [7:0] data_i,
    output logic       ready,
    output logic       done,
    output logic       lcd_sclk,
    output logic       lcd_mosi,
    output logic       lcd_cs_n,
    output logic       lcd_dc
);

    typedef enum logic [1:0] {
        SPI_IDLE,
        SPI_HIGH,
        SPI_LOW,
        SPI_DONE
    } spi_state_t;

    spi_state_t state_q;
    logic [7:0] shift_q;
    logic [2:0] bit_index_q;
    int unsigned div_count_q;

    assign ready = (state_q == SPI_IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= SPI_IDLE;
            shift_q <= 8'h00;
            bit_index_q <= 3'd7;
            div_count_q <= 0;
            lcd_sclk <= 1'b0;
            lcd_mosi <= 1'b0;
            lcd_cs_n <= 1'b1;
            lcd_dc <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            unique case (state_q)
                SPI_IDLE: begin
                    lcd_sclk <= 1'b0;
                    lcd_cs_n <= 1'b1;
                    div_count_q <= 0;
                    if (start) begin
                        shift_q <= data_i;
                        bit_index_q <= 3'd7;
                        lcd_dc <= dc_i;
                        lcd_mosi <= data_i[7];
                        lcd_cs_n <= 1'b0;
                        state_q <= SPI_HIGH;
                    end
                end

                SPI_HIGH: begin
                    if (div_count_q == CLKS_PER_HALF_SCLK - 1) begin
                        div_count_q <= 0;
                        lcd_sclk <= 1'b1;
                        state_q <= SPI_LOW;
                    end else begin
                        div_count_q <= div_count_q + 1;
                    end
                end

                SPI_LOW: begin
                    if (div_count_q == CLKS_PER_HALF_SCLK - 1) begin
                        div_count_q <= 0;
                        lcd_sclk <= 1'b0;
                        if (bit_index_q == 3'd0) begin
                            state_q <= SPI_DONE;
                        end else begin
                            bit_index_q <= bit_index_q - 1'b1;
                            lcd_mosi <= shift_q[bit_index_q - 1'b1];
                            state_q <= SPI_HIGH;
                        end
                    end else begin
                        div_count_q <= div_count_q + 1;
                    end
                end

                SPI_DONE: begin
                    lcd_cs_n <= 1'b1;
                    done <= 1'b1;
                    state_q <= SPI_IDLE;
                end

                default: begin
                    state_q <= SPI_IDLE;
                end
            endcase
        end
    end

endmodule
