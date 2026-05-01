module tang9k_rtos_soc_top (
    input  logic       clk,
    input  logic [1:0] btn_n,

    output logic [5:0] led_n,

    output logic       uart_tx,
    input  logic       uart_rx,

    output logic       lcd_sclk,
    output logic       lcd_mosi,
    output logic       lcd_cs_n,
    output logic       lcd_dc,
    output logic       lcd_rst_n
);

    localparam int unsigned CLK_HZ = 27_000_000;
    localparam int unsigned BAUD = 115_200;
    localparam int unsigned CLKS_PER_BIT = CLK_HZ / BAUD;
    localparam int unsigned RAM_WORDS = 8_192;

    localparam logic [5:0] IO_LED_ADDR = 6'd0;
    localparam logic [5:0] IO_UART_DATA_ADDR = 6'd1;
    localparam logic [5:0] IO_UART_STATUS_ADDR = 6'd2;
    localparam logic [5:0] IO_LCD_CMD_ADDR = 6'd3;
    localparam logic [5:0] IO_LCD_VALUE_ADDR = 6'd4;
    localparam logic [5:0] IO_IRQ_PENDING_ADDR = 6'd5;
    localparam logic [5:0] IO_IRQ_ENABLE_ADDR = 6'd6;
    localparam logic [5:0] IO_TIMER_RELOAD_ADDR = 6'd7;
    localparam logic [5:0] IO_TIMER_VALUE_ADDR = 6'd8;
    localparam logic [5:0] IO_BUTTON_STATE_ADDR = 6'd9;
    localparam logic [5:0] IO_BUTTON_DEBOUNCE_ADDR = 6'd10;

    logic rst_n;
    assign rst_n = btn_n[1];

    wire unused_uart_rx = uart_rx;
    wire _unused_uart_rx_ok = unused_uart_rx;

    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0] mem_wmask;
    logic [31:0] mem_rdata;
    logic mem_rstrb;
    logic interrupt_request;

    logic mem_address_is_io;
    logic mem_address_is_ram;
    logic mem_wstrb;
    logic [12:0] ram_word_address;
    logic [5:0] io_word_address;
    logic io_wstrb;
    logic io_rstrb;

    logic [31:0] ram_rdata;
    logic [31:0] io_rdata;
    logic [31:0] irq_rdata;
    logic [31:0] lcd_rdata;
    logic [31:0] led_q;
    logic uart_tx_valid;
    logic uart_tx_ready;
    logic uart_tx_busy;
    logic uart_tx_done_unused;
    logic irq_bus_wr;
    logic irq_bus_rd;
    logic [3:0] irq_bus_addr;
    logic button_level;

    (* no_rw_check *)
    logic [31:0] ram [0:RAM_WORDS-1];

    initial begin
        $readmemh("firmware/rtos_lcd_counter/build/rtos_lcd_counter.hex", ram);
    end

    assign mem_wstrb = |mem_wmask;
    assign mem_address_is_io = mem_addr[22];
    assign mem_address_is_ram = !mem_addr[22];
    assign ram_word_address = mem_addr[14:2];
    assign io_word_address = mem_addr[7:2];
    assign io_wstrb = mem_wstrb && mem_address_is_io;
    assign io_rstrb = mem_rstrb && mem_address_is_io;

    always_ff @(posedge clk) begin
        if (mem_address_is_ram) begin
            if (mem_wmask[0]) ram[ram_word_address][7:0] <= mem_wdata[7:0];
            if (mem_wmask[1]) ram[ram_word_address][15:8] <= mem_wdata[15:8];
            if (mem_wmask[2]) ram[ram_word_address][23:16] <= mem_wdata[23:16];
            if (mem_wmask[3]) ram[ram_word_address][31:24] <= mem_wdata[31:24];
        end
        ram_rdata <= ram[ram_word_address];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_q <= 32'd0;
        end else if (io_wstrb && io_word_address == IO_LED_ADDR) begin
            led_q <= mem_wdata;
        end
    end

    assign led_n = ~{
        button_level,
        interrupt_request,
        led_q[3:0]
    };

    always_comb begin
        unique case (io_word_address)
            IO_LED_ADDR: io_rdata = led_q;
            IO_UART_DATA_ADDR: io_rdata = 32'd0;
            IO_UART_STATUS_ADDR: io_rdata = {22'd0, uart_tx_busy, 9'd0};
            IO_LCD_CMD_ADDR: io_rdata = lcd_rdata;
            IO_LCD_VALUE_ADDR: io_rdata = 32'd0;
            IO_IRQ_PENDING_ADDR,
            IO_IRQ_ENABLE_ADDR,
            IO_TIMER_RELOAD_ADDR,
            IO_TIMER_VALUE_ADDR,
            IO_BUTTON_STATE_ADDR,
            IO_BUTTON_DEBOUNCE_ADDR: io_rdata = irq_rdata;
            default: io_rdata = 32'd0;
        endcase
    end

    assign mem_rdata = mem_address_is_io ? io_rdata : ram_rdata;

    FemtoRV32 #(
        .RESET_ADDR(32'h0000_0000),
        .ADDR_WIDTH(24)
    ) cpu (
        .clk(clk),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wmask(mem_wmask),
        .mem_rdata(mem_rdata),
        .mem_rstrb(mem_rstrb),
        .mem_rbusy(1'b0),
        .mem_wbusy(1'b0),
        .interrupt_request(interrupt_request),
        .reset(rst_n)
    );

    assign uart_tx_valid = io_wstrb && io_word_address == IO_UART_DATA_ADDR && uart_tx_ready;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_tx_i (
        .clk(clk),
        .rst_n(rst_n),
        .tx_valid(uart_tx_valid),
        .tx_data(mem_wdata[7:0]),
        .tx_ready(uart_tx_ready),
        .tx_o(uart_tx),
        .tx_busy(uart_tx_busy),
        .tx_done(uart_tx_done_unused)
    );

    assign irq_bus_wr = io_wstrb && io_word_address >= IO_IRQ_PENDING_ADDR
            && io_word_address <= IO_BUTTON_DEBOUNCE_ADDR;
    assign irq_bus_rd = io_rstrb && io_word_address >= IO_IRQ_PENDING_ADDR
            && io_word_address <= IO_BUTTON_DEBOUNCE_ADDR;

    always_comb begin
        unique case (io_word_address)
            IO_IRQ_PENDING_ADDR: irq_bus_addr = 4'h0;
            IO_IRQ_ENABLE_ADDR: irq_bus_addr = 4'h1;
            IO_TIMER_RELOAD_ADDR: irq_bus_addr = 4'h2;
            IO_TIMER_VALUE_ADDR: irq_bus_addr = 4'h3;
            IO_BUTTON_STATE_ADDR: irq_bus_addr = 4'h4;
            IO_BUTTON_DEBOUNCE_ADDR: irq_bus_addr = 4'h5;
            default: irq_bus_addr = 4'h0;
        endcase
    end

    irq_timer_button #(
        .CLK_HZ(CLK_HZ)
    ) irq_i (
        .clk(clk),
        .rst_n(rst_n),
        .button_n(btn_n[0]),
        .bus_wr(irq_bus_wr),
        .bus_rd(irq_bus_rd),
        .bus_addr(irq_bus_addr),
        .bus_wdata(mem_wdata),
        .bus_rdata(irq_rdata),
        .irq_o(interrupt_request),
        .button_level_o(button_level)
    );

    rtos_lcd_mmio lcd_i (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_wr(io_wstrb && io_word_address == IO_LCD_CMD_ADDR),
        .value_wr(io_wstrb && io_word_address == IO_LCD_VALUE_ADDR),
        .wdata(mem_wdata),
        .rdata(lcd_rdata),
        .lcd_rst_n(lcd_rst_n),
        .lcd_sclk(lcd_sclk),
        .lcd_cs_n(lcd_cs_n),
        .lcd_dc(lcd_dc),
        .lcd_mosi(lcd_mosi)
    );

endmodule
