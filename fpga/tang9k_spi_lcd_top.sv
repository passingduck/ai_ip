module tang9k_spi_lcd_top (
    input  logic       clk,
    input  logic       resetn,
    output logic       lcd_sclk,
    output logic       lcd_mosi,
    output logic       lcd_cs_n,
    output logic       lcd_dc,
    output logic       lcd_rst_n,
    output logic [5:0] led_n
);

    lcd114_deepx_simple u_lcd_demo (
        .clk(clk),
        .resetn(resetn),
        .lcd_resetn(lcd_rst_n),
        .lcd_clk(lcd_sclk),
        .lcd_cs(lcd_cs_n),
        .lcd_rs(lcd_dc),
        .lcd_data(lcd_mosi),
        .led_n(led_n)
    );

endmodule
