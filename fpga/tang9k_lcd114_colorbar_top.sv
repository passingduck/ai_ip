module tang9k_lcd114_colorbar_top (
    input  logic       clk,
    input  logic       resetn,
    output logic       lcd_resetn,
    output logic       lcd_clk,
    output logic       lcd_cs,
    output logic       lcd_rs,
    output logic       lcd_data,
    output logic [5:0] led_n
);

    lcd114_colorbar_simple u_lcd (
        .clk(clk),
        .resetn(resetn),
        .lcd_resetn(lcd_resetn),
        .lcd_clk(lcd_clk),
        .lcd_cs(lcd_cs),
        .lcd_rs(lcd_rs),
        .lcd_data(lcd_data),
        .led_n(led_n)
    );

endmodule
