module video_timing(
    input wire clk,       // 25 MHz
    input wire rst_n,
    output reg hsync,
    output reg vsync,
    output reg active,
    output reg [9:0] x,
    output reg [9:0] y
);

    reg [9:0] hcount;
    reg [9:0] vcount;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hcount <= 0;
            vcount <= 0;
            hsync <= 1;
            vsync <= 1;
            active <= 0;
            x <= 0;
            y <= 0;
        end else begin
            if (hcount == 799) begin
                hcount <= 0;
                if (vcount == 524)
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
            end else begin
                hcount <= hcount + 1;
            end

            // Sync pulses (VGA standard 640x480 @ 60Hz)
            hsync <= ~(hcount >= 656 && hcount < 752);
            vsync <= ~(vcount >= 490 && vcount < 492);
            active <= (hcount < 640 && vcount < 480);
            
            x <= (hcount < 640) ? hcount : 10'd0;
            y <= (vcount < 480) ? vcount : 10'd0;
        end
    end

endmodule