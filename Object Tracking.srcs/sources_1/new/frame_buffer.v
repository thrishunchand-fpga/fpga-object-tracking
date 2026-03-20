module frame_buffer(
    // Write port (Camera, 24MHz)
    input wire pclk,
    input wire we,
    input wire [16:0] wr_addr, // 320 * 240 = 76800
    input wire [11:0] wr_data, // RGB444

    // Read port (VGA/HDMI, 25MHz)
    input wire clk_vga,
    input wire [16:0] rd_addr,
    output reg [11:0] rd_data
);

    // Zynq 7020 has 140 BRAM36 (4.9Mb). 76800 * 12 bits = 921 Kb = 25 BRAM36.
    // This allows for a full frame buffer of the downsampled image.
    reg [11:0] mem [0:76799];

    always @(posedge pclk) begin
        if (we)
            mem[wr_addr] <= wr_data;
    end

    always @(posedge clk_vga) begin
        rd_data <= mem[rd_addr];
    end

endmodule