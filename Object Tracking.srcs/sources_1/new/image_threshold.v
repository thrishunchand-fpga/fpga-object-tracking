`timescale 1ns / 1ps

module image_threshold(
    input wire [7:0] r,
    input wire [7:0] g,
    input wire [7:0] b,
    output wire detect
);

    // Simple red color threshold: high red, low green and blur
    assign detect = (r > 8'd150 && g < 8'd100 && b < 8'd100);

endmodule
