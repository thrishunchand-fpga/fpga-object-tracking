module sccb_master(
    input wire clk,         // 25Mhz clock
    input wire rst_n,
    input wire [7:0] slv_addr,
    input wire [7:0] reg_addr,
    input wire [7:0] reg_data,
    input wire start,
    inout wire sda,
    output wire scl,
    output reg done,
    output reg ready
);

    reg [7:0] timer_cnt;
    wire timer_tick = (timer_cnt == 50); // 25Mhz / 50 = 500kHz (for 4 phases of 125kHz I2C)
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) timer_cnt <= 0;
        else if (timer_tick) timer_cnt <= 0;
        else if (!ready) timer_cnt <= timer_cnt + 1;
        else timer_cnt <= 0;
    end

    reg [2:0] phase;
    reg [5:0] step_cnt;
    reg sda_out;
    reg sda_dir;
    reg scl_out;

    assign sda = sda_dir ? sda_out : 1'bz;
    assign scl = scl_out;

    wire [8:0] byte1 = {slv_addr, 1'b1}; // 1'b1 is ACK phase (don't care for SCCB tx)
    wire [8:0] byte2 = {reg_addr, 1'b1};
    wire [8:0] byte3 = {reg_data, 1'b1};
    wire [26:0] tx_data = {byte1, byte2, byte3};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1;
            done <= 0;
            phase <= 0;
            step_cnt <= 0;
            sda_out <= 1;
            sda_dir <= 1;
            scl_out <= 1;
        end else begin
            if (ready && start) begin
                ready <= 0;
                done <= 0;
                phase <= 0;
                step_cnt <= 0;
                sda_dir <= 1;
                sda_out <= 1;
                scl_out <= 1;
            end else if (!ready && timer_tick) begin
                if (step_cnt == 0) begin // Start condition
                    case (phase)
                        0: begin sda_out <= 1; scl_out <= 1; phase <= 1; end
                        1: begin sda_out <= 0; scl_out <= 1; phase <= 2; end
                        2: begin sda_out <= 0; scl_out <= 1; phase <= 3; end
                        3: begin sda_out <= 0; scl_out <= 0; phase <= 0; step_cnt <= 1; end
                    endcase
                end else if (step_cnt >= 1 && step_cnt <= 27) begin // Data and ACK
                    case (phase)
                        0: begin 
                               sda_dir <= (step_cnt % 9 == 0) ? 0 : 1; // ACK phase
                               sda_out <= tx_data[27 - step_cnt];
                               scl_out <= 0;
                               phase <= 1; 
                           end
                        1: begin scl_out <= 1; phase <= 2; end
                        2: begin scl_out <= 1; phase <= 3; end
                        3: begin scl_out <= 0; phase <= 0; step_cnt <= step_cnt + 1; end
                    endcase
                end else if (step_cnt == 28) begin // Stop condition
                    case (phase)
                        0: begin sda_dir <= 1; sda_out <= 0; scl_out <= 0; phase <= 1; end
                        1: begin sda_out <= 0; scl_out <= 1; phase <= 2; end
                        2: begin sda_out <= 1; scl_out <= 1; phase <= 3; end
                        3: begin sda_out <= 1; scl_out <= 1; ready <= 1; done <= 1; end
                    endcase
                end
            end else if (ready) begin
                done <= 0; // Clear done when not busy and start not asserted
            end
        end
    end

endmodule