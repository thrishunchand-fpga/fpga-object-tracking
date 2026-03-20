module clock_generator(
    input wire clk_125M,
    input wire reset,
    output wire clk_25M,
    output wire clk_250M,
    output wire clk_24M,
    output wire locked
);

    wire clkfb_out;
    wire clkfb_in;
    wire clk_25M_unbuf;
    wire clk_250M_unbuf;
    wire clk_24M_unbuf;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT_F(6.000),    // 125 MHz * 6 = 750 MHz VCO
        .CLKFBOUT_PHASE(0.000),
        .CLKIN1_PERIOD(8.000),
        .CLKOUT0_DIVIDE_F(30.000),  // 750 MHz / 30 = 25 MHz
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT0_PHASE(0.000),
        .CLKOUT1_DIVIDE(6),         // 750 MHz / 6 = 125 MHz (for OSERDES DDR Clock)
        .CLKOUT1_DUTY_CYCLE(0.500),
        .CLKOUT1_PHASE(0.000),
        .CLKOUT2_DIVIDE(31),        // 750 MHz / 31 = ~24.19 MHz
        .CLKOUT2_DUTY_CYCLE(0.500),
        .CLKOUT2_PHASE(0.000),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010)
    )
    mmcm_inst (
        .CLKOUT0(clk_25M_unbuf),
        .CLKOUT1(clk_250M_unbuf),
        .CLKOUT2(clk_24M_unbuf),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUT(clkfb_out),
        .CLKFBOUTB(),
        .LOCKED(locked),
        .CLKIN1(clk_125M),
        .PWRDWN(1'b0),
        .RST(reset),
        .CLKFBIN(clkfb_in)
    );

    BUFG bufg_fb (.I(clkfb_out), .O(clkfb_in));
    BUFG bufg_25M (.I(clk_25M_unbuf), .O(clk_25M));
    BUFG bufg_250M (.I(clk_250M_unbuf), .O(clk_250M));
    BUFG bufg_24M (.I(clk_24M_unbuf), .O(clk_24M));

endmodule