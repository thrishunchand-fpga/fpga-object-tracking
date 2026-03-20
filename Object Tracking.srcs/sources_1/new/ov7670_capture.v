module ov7670_capture(
    input wire pclk,
    input wire vsync,
    input wire href,
    input wire [7:0] d,
    
    output reg [16:0] wr_addr,
    output wire [11:0] wr_data,
    output reg we
);

    reg [9:0] x;
    reg [9:0] y;
    reg byte_sel;
    reg [7:0] d_latch;
    reg vsync_prev;
    
    wire [15:0] rgb565 = {d_latch, d};
    // Convert RGB565 to RGB444: R[4:1], G[5:2], B[4:1]
    assign wr_data = {rgb565[15:12], rgb565[10:7], rgb565[4:1]};
    
    always @(posedge pclk) begin
        vsync_prev <= vsync;
        
        we <= 0;
        
        if (vsync_prev == 1'b1 && vsync == 1'b0) begin
            // Frame start
            x <= 0;
            y <= 0;
            byte_sel <= 0;
            wr_addr <= 0;
        end else begin
            if (href) begin
                if (!byte_sel) begin
                    d_latch <= d;
                    byte_sel <= 1;
                end else begin
                    // We have a full pixel
                    byte_sel <= 0;
                    
                    if (x < 640 && y < 480) begin
                        // Downsample: only write even X and even Y
                        if (x[0] == 0 && y[0] == 0) begin
                            we <= 1;
                        end
                    end
                    
                    x <= x + 1;
                end
            end else begin
                // End of line
                if (x > 0) begin
                    x <= 0;
                    y <= y + 1;
                end
                byte_sel <= 0;
            end
            
            // Increment address after writing
            if (we) begin
                if (wr_addr < 76799)
                    wr_addr <= wr_addr + 1;
            end
        end
    end

endmodule