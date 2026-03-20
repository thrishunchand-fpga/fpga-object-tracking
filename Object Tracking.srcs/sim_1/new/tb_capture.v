`timescale 1ns/1ps

module tb_capture;

    reg pclk;
    reg vsync;
    reg href;
    reg [7:0] data;

    wire [16:0] wr_addr;
    wire [11:0] wr_data;
    wire we;

    ov7670_capture uut(
        .pclk(pclk),
        .vsync(vsync),
        .href(href),
        .d(data),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .we(we)
    );

    // ~24MHz clock
    initial begin
        pclk = 0;
        forever #20 pclk = ~pclk;
    end

    initial begin
        // Output waveform dumping for Vivado/ModelSim
        // $dumpfile("tb_capture.vcd");
        // $dumpvars(0, tb_capture);

        // Reset state (VSYNC active high during blanking)
        vsync = 1;
        href = 0;
        data = 0;

        #100;
        // Start of frame (VSYNC falling edge)
        vsync = 0;
        
        #100;
        
        // Line 1, Pixel 1 (Even, Even) -> should trigger WE
        href = 1;
        data = 8'hF8; // R=11111, G=000
        #40;
        data = 8'h00; // G=000, B=00000 -> output RGB444 should be F00
        #40;
        // Line 1, Pixel 2 (Odd, Even) -> should NOT trigger WE
        data = 8'h07; // R=00000, G=111
        #40;
        data = 8'hE0; // G=111, B=00000 -> not written
        #40;
        
        href = 0;
        #100;
        
        // Line 2 (Odd y) -> shouldn't trigger WE
        href = 1;
        data = 8'h00;
        #40;
        data = 8'h1F; // B=11111
        #40;
        data = 8'h00;
        #40;
        data = 8'h1F;
        #40;
        href = 0;
        #100;

        // Line 3 (Even y) -> should trigger WE for pixel 1
        href = 1;
        data = 8'h07;
        #40;
        data = 8'hE0; // G=111111 -> output RGB444 should be 0F0
        #40;
        data = 8'h00;
        #40;
        data = 8'h00;
        #40;
        href = 0;

        #200;
        $finish;
    end

    // Monitor for verification
    initial begin
        $monitor("Time: %0t | VSYNC: %b | HREF: %b | WE: %b | Addr: %0d | Data: %h", 
                 $time, vsync, href, we, wr_addr, wr_data);
    end

endmodule
