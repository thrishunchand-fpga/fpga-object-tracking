module centroid_tracker(
    input wire clk,
    input wire rst_n,
    input wire active_video,
    input wire detect,
    input wire [9:0] x,
    input wire [9:0] y,
    output reg [9:0] cx,
    output reg [9:0] cy
);

    reg [31:0] sum_x, sum_y;
    reg [23:0] count;
    reg active_prev;

    reg [31:0] rem_x, rem_y;
    reg [9:0] quo_x, quo_y;
    reg [23:0] div_den;
    reg [4:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cx <= 320;
            cy <= 240;
            sum_x <= 0;
            sum_y <= 0;
            count <= 0;
            state <= 0;
            active_prev <= 0;
        end else begin
            active_prev <= active_video;
            
            if (active_video && detect) begin
                sum_x <= sum_x + x;
                sum_y <= sum_y + y;
                count <= count + 1;
            end
            
            // Trigger at the end of active video (entering V-Blank)
            if (active_prev && !active_video) begin
                if (count > 0) begin
                    rem_x <= sum_x;
                    rem_y <= sum_y;
                    div_den <= count;
                    quo_x <= 0;
                    quo_y <= 0;
                    state <= 10; // We need up to 10 bits of quotient
                end
                // Reset accumulators for next frame
                sum_x <= 0;
                sum_y <= 0;
                count <= 0;
            end
            
            if (state > 0) begin
                if (rem_x >= ({8'd0, div_den} << (state - 1))) begin
                    rem_x <= rem_x - ({8'd0, div_den} << (state - 1));
                    quo_x <= quo_x | (1 << (state - 1));
                end
                
                if (rem_y >= ({8'd0, div_den} << (state - 1))) begin
                    rem_y <= rem_y - ({8'd0, div_den} << (state - 1));
                    quo_y <= quo_y | (1 << (state - 1));
                end
                
                state <= state - 1;
                
                if (state == 1) begin
                    cx <= quo_x;
                    cy <= quo_y;
                end
            end
        end
    end

endmodule