module rgb565_to_rgb888(
    input wire [11:0] rgb444, // Using RGB444 now to save BRAM
    output wire [23:0] rgb888
);

    wire [3:0] r = rgb444[11:8];
    wire [3:0] g = rgb444[7:4];
    wire [3:0] b = rgb444[3:0];
    
    // Duplicate the 4 bits to 8 bits for full range (e.g. 0xF -> 0xFF)
    assign rgb888 = {r, r, g, g, b, b};

endmodule