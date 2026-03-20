module hdmi_encoder(
    input wire clk_pixel,   // 25MHz
    input wire clk_tmds,    // 125MHz (DDR 5x)
    input wire rst_n,
    
    // Pixel data
    input wire [7:0] red,
    input wire [7:0] green,
    input wire [7:0] blue,
    
    // Sync signals
    input wire hsync,
    input wire vsync,
    input wire active,
    
    // TMDS Outputs to pins (差分)
    output wire [2:0] tmds_p,
    output wire [2:0] tmds_n,
    output wire clk_p,
    output wire clk_n
);

    wire [9:0] tmds_r, tmds_g, tmds_b;
    
    tmds_encoder enc_r (.clk(clk_pixel), .VD(red),   .CD(2'b00), .VDE(active), .TMDS(tmds_r));
    tmds_encoder enc_g (.clk(clk_pixel), .VD(green), .CD(2'b00), .VDE(active), .TMDS(tmds_g));
    tmds_encoder enc_b (.clk(clk_pixel), .VD(blue),  .CD({vsync, hsync}), .VDE(active), .TMDS(tmds_b));

    wire [2:0] tmds_serial;

    oserdes_10b1 ser_r (.clk_pixel(clk_pixel), .clk_tmds(clk_tmds), .rst_n(rst_n), .data_in(tmds_r), .seq_out(tmds_serial[2]));
    oserdes_10b1 ser_g (.clk_pixel(clk_pixel), .clk_tmds(clk_tmds), .rst_n(rst_n), .data_in(tmds_g), .seq_out(tmds_serial[1]));
    oserdes_10b1 ser_b (.clk_pixel(clk_pixel), .clk_tmds(clk_tmds), .rst_n(rst_n), .data_in(tmds_b), .seq_out(tmds_serial[0]));

    // Output buffering
    genvar i;
    generate
        for(i=0; i<3; i=i+1) begin : diff_buffer
            OBUFDS obufds_data(.I(tmds_serial[i]), .O(tmds_p[i]), .OB(tmds_n[i]));
        end
    endgenerate

    // Forward the pixel clock to HDMI display
    OBUFDS obufds_clk(.I(clk_pixel), .O(clk_p), .OB(clk_n));

endmodule

// TMDS 8b/10b encoder state machine
module tmds_encoder(
    input wire clk,
    input wire [7:0] VD,
    input wire [1:0] CD,
    input wire VDE,
    output reg [9:0] TMDS = 0
);

  wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];
  wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);
  
  wire [8:0] q_m;
  assign q_m[0] = VD[0];
  assign q_m[1] = (q_m[0] ^ VD[1]) ^ XNOR;
  assign q_m[2] = (q_m[1] ^ VD[2]) ^ XNOR;
  assign q_m[3] = (q_m[2] ^ VD[3]) ^ XNOR;
  assign q_m[4] = (q_m[3] ^ VD[4]) ^ XNOR;
  assign q_m[5] = (q_m[4] ^ VD[5]) ^ XNOR;
  assign q_m[6] = (q_m[5] ^ VD[6]) ^ XNOR;
  assign q_m[7] = (q_m[6] ^ VD[7]) ^ XNOR;
  assign q_m[8] = ~XNOR;

  reg signed [4:0] balance_acc = 0;
  wire [3:0] q_m_1s = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
  wire signed [4:0] balance = q_m_1s - 4'd4;
  wire balance_sign_eq = (balance[4] == balance_acc[4]); // same sign
  wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
  wire signed [4:0] balance_acc_inc = balance - ({4'b0, q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
  wire signed [4:0] balance_acc_new = invert_q_m ? balance_acc - balance_acc_inc : balance_acc + balance_acc_inc;
  wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
  wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100) : (CD[0] ? 10'b0010101011 : 10'b1101010100);

  always @(posedge clk) TMDS <= VDE ? TMDS_data : TMDS_code;
  always @(posedge clk) balance_acc <= VDE ? balance_acc_new : 5'h0;

endmodule

// 10:1 DDR Serialization using two OSERDESE2 instances (Master/Slave pair)
module oserdes_10b1 (
    input wire clk_pixel,
    input wire clk_tmds,
    input wire rst_n,
    input wire [9:0] data_in,
    output wire seq_out
);
    wire shiftout1;
    wire shiftout2;

    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),       
        .DATA_RATE_TQ("SDR"),       
        .DATA_WIDTH(10),            
        .SERDES_MODE("MASTER"),     
        .TRISTATE_WIDTH(1)          
    ) oserdes_master (
        .OQ(seq_out),           
        .TQ(),                 
        .CLK(clk_tmds),         
        .CLKDIV(clk_pixel),       
        // In DDR mode, Master transmits on rising edges contextually, handling the even bits
        .D1(data_in[0]),        
        .D2(data_in[2]),        
        .D3(data_in[4]),        
        .D4(data_in[6]),        
        .D5(data_in[8]),        
        .D6(1'b0),        
        .D7(1'b0),        
        .D8(1'b0),          
        .RST(~rst_n),           
        .T1(1'b0),              
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .OCE(1'b1),             
        .TCE(1'b0),             
        // MASTER receives shifted data from SLAVE
        .SHIFTIN1(shiftout1),        
        .SHIFTIN2(shiftout2),
        .SHIFTOUT1(),
        .SHIFTOUT2()
    );

    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH(10),
        .SERDES_MODE("SLAVE"),
        .TRISTATE_WIDTH(1)
    ) oserdes_slave (
        .OQ(), // Slave OQ is unconnected
        .TQ(),
        .CLK(clk_tmds),
        .CLKDIV(clk_pixel),
        // Slave handles the odd bits
        .D1(data_in[1]),
        .D2(data_in[3]),
        .D3(data_in[5]),
        .D4(data_in[7]),
        .D5(data_in[9]),
        .D6(1'b0),
        .D7(1'b0),
        .D8(1'b0),
        .RST(~rst_n),
        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .OCE(1'b1),
        .TCE(1'b0),
        // SLAVE shifts data out TO the MASTER
        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0),
        .SHIFTOUT1(shiftout1),
        .SHIFTOUT2(shiftout2)
    );
endmodule