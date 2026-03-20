`timescale 1ns / 1ps

module top(
    input wire clk,          // 125MHz PYNQ clock

    // OV7670
    input wire [7:0] cam_data,
    input wire cam_pclk,
    input wire cam_href,
    input wire cam_vsync,
    output wire cam_xclk,
    inout wire cam_sda,
    output wire cam_scl,

    // HDMI
    output wire hdmi_clk_p,
    output wire hdmi_clk_n,
    output wire [2:0] hdmi_tx_p,
    output wire [2:0] hdmi_tx_n
);

    wire rst = 1'b0; // No reset button mapped, use power-on reset

    // Clock generation
    wire clk_25M, clk_250M, clk_24M, locked;
    clock_generator clk_gen (
        .clk_125M(clk),
        .reset(rst),
        .clk_25M(clk_25M),
        .clk_250M(clk_250M), // We use clk (125MHz) directly for DDR TMDS, clk_250M is kept for completeness as a 10x
        .clk_24M(clk_24M),
        .locked(locked)
    );

    wire rst_n = locked;
    assign cam_xclk = clk_24M;

    // OV7670 configuration
    wire config_done;
    ov7670_config cam_config (
        .clk(clk_25M),
        .rst_n(rst_n),
        .sda(cam_sda),
        .scl(cam_scl),
        .config_done(config_done)
    );

    // Camera Capture
    wire [16:0] wr_addr;
    wire [11:0] wr_data;
    wire we;
    
    ov7670_capture cam_cap (
        .pclk(cam_pclk),
        .vsync(cam_vsync),
        .href(cam_href),
        .d(cam_data),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .we(we)
    );

    // Dual Port RAM Frame Buffer (320x240 RGB444)
    wire [16:0] rd_addr;
    wire [11:0] rd_data;

    frame_buffer fb (
        .pclk(cam_pclk),
        .we(we),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .clk_vga(clk_25M),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    // VGA Timing Generator (640x480 Output Domain)
    wire hsync, vsync, active;
    wire [9:0] x, y;
    
    video_timing vga_timing (
        .clk(clk_25M),
        .rst_n(rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .active(active),
        .x(x),
        .y(y)
    );

    // Read address logic (upsampling 320x240 to 640x480 on-the-fly)
    assign rd_addr = (y[9:1] * 320) + x[9:1];

    wire [23:0] rgb888;
    rgb565_to_rgb888 color_conv (
        .rgb444(rd_data),
        .rgb888(rgb888)
    );

    // Image Tracking
    wire detect;
    image_threshold thr (
        .r(rgb888[23:16]),
        .g(rgb888[15:8]),
        .b(rgb888[7:0]),
        .detect(detect)
    );

    wire [9:0] cx, cy;
    centroid_tracker tracker (
        .clk(clk_25M),
        .rst_n(rst_n),
        .active_video(active),
        .detect(detect),
        .x(x),
        .y(y),
        .cx(cx),
        .cy(cy)
    );

    wire box;
    bbox_overlay bbox (
        .x(x),
        .y(y),
        .cx(cx),
        .cy(cy),
        .box(box)
    );

    // Combine Video & Overlay
    wire [7:0] out_r = box ? 8'hFF : rgb888[23:16];
    wire [7:0] out_g = box ? 8'h00 : rgb888[15:8];
    wire [7:0] out_b = box ? 8'h00 : rgb888[7:0];

    // OSERDESE2 needs 125MHz DDR clock to serialize 10:1 data from 25MHz domain.
    // clk_250M is actually generating 125MHz perfectly phase aligned to the 25MHz pixel clock!
    // (We changed the divider in clock_generator.v from 3 to 6).
    wire clk_tmds_aligned = clk_250M;

    // HDMI 8b/10b TMDS Encoder Output
    hdmi_encoder hdmi (
        .clk_pixel(clk_25M),
        .clk_tmds(clk_tmds_aligned), // 125MHz DDR = 5x pixel clock
        .rst_n(rst_n),
        .red(out_r),
        .green(out_g),
        .blue(out_b),
        .hsync(hsync),
        .vsync(vsync),
        .active(active),
        .tmds_p(hdmi_tx_p),
        .tmds_n(hdmi_tx_n),
        .clk_p(hdmi_clk_p),
        .clk_n(hdmi_clk_n)
    );

endmodule
