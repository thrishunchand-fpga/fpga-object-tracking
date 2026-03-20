module ov7670_config(
    input wire clk, // 25MHz
    input wire rst_n,
    inout wire sda,
    output wire scl,
    output reg config_done
);

    wire sccb_ready;
    wire sccb_done;
    reg sccb_start;
    reg [7:0] sccb_reg_addr;
    reg [7:0] sccb_reg_data;

    sccb_master sccb_inst(
        .clk(clk),
        .rst_n(rst_n),
        .slv_addr(8'h42), // SCCB address for OV7670 write
        .reg_addr(sccb_reg_addr),
        .reg_data(sccb_reg_data),
        .start(sccb_start),
        .sda(sda),
        .scl(scl),
        .done(sccb_done),
        .ready(sccb_ready)
    );

    reg [7:0] rom_addr;
    reg [15:0] rom_data;
    
    // Very basic OV7670 initialization for VGA RGB565
    always @(*) begin
        case(rom_addr)
            0 : rom_data = 16'h1280; // COM7: Reset
            1 : rom_data = 16'h1204; // COM7: VGA, RGB
            2 : rom_data = 16'h40d0; // COM15: RGB565, full output range
            3 : rom_data = 16'h8c00; // RGB444: disable
            4 : rom_data = 16'h1100; // CLKRC: Internal clock prescaler (use default)
            5 : rom_data = 16'h0c00; // COM3: default
            6 : rom_data = 16'h3e00; // COM14: default
            7 : rom_data = 16'h0400; // COM1: default
            8 : rom_data = 16'h1e37; // MVFP: mirror/vflip etc, standard
            9 : rom_data = 16'h3a04; // TSLB: YUYV sequence
            10: rom_data = 16'hb084; // Reserved parameter (color related)
            11: rom_data = 16'h13e5; // COM8: Enable AGC, AWB, AEC
            12: rom_data = 16'h0000; // COM13: defaults
            13: rom_data = 16'hffff; // End of config
            default: rom_data = 16'hffff;
        endcase
    end

    reg [2:0] state; // 0=init, 1=wait_ready, 2=start, 3=wait_done, 4=delay, 5=finish
    reg [19:0] delay_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            rom_addr <= 0;
            sccb_start <= 0;
            config_done <= 0;
            delay_cnt <= 0;
        end else begin
            case(state)
                0: begin // Wait a bit after reset
                    if (delay_cnt == 20'hFFFFF) begin
                        state <= 1;
                        delay_cnt <= 0;
                    end else delay_cnt <= delay_cnt + 1;
                end
                1: begin
                    if (rom_data == 16'hffff) begin
                        state <= 5; // Finish
                    end else if (sccb_ready) begin
                        sccb_reg_addr <= rom_data[15:8];
                        sccb_reg_data <= rom_data[7:0];
                        sccb_start <= 1;
                        state <= 2;
                    end
                end
                2: begin
                    sccb_start <= 0; // Clear start
                    state <= 3;
                end
                3: begin
                    if (sccb_done) begin
                        rom_addr <= rom_addr + 1;
                        state <= 4;
                    end
                end
                4: begin
                    // Add a tiny delay between commands
                    if (delay_cnt == 20'h3FFF) begin
                        state <= 1;
                        delay_cnt <= 0;
                    end else delay_cnt <= delay_cnt + 1;
                end
                5: begin
                    config_done <= 1;
                end
            endcase
        end
    end
endmodule