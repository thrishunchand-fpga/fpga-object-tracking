###########################################################
# CLOCK
###########################################################
set_property PACKAGE_PIN H16 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 8.0 [get_ports clk]

###########################################################
# CAMERA (OV7670)
###########################################################
set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports cam_pclk]
set_property IOSTANDARD LVCMOS33 [get_ports cam_href]
set_property IOSTANDARD LVCMOS33 [get_ports cam_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports cam_xclk]
set_property IOSTANDARD LVCMOS33 [get_ports cam_sda]
set_property IOSTANDARD LVCMOS33 [get_ports cam_scl]

# Example pins (adjust if needed)
set_property PACKAGE_PIN V10 [get_ports {cam_data[0]}]
set_property PACKAGE_PIN V8  [get_ports {cam_data[1]}]
set_property PACKAGE_PIN W10 [get_ports {cam_data[2]}]
set_property PACKAGE_PIN W8  [get_ports {cam_data[3]}]
set_property PACKAGE_PIN V6  [get_ports {cam_data[4]}]
set_property PACKAGE_PIN Y6  [get_ports {cam_data[5]}]
set_property PACKAGE_PIN U7  [get_ports {cam_data[6]}]
set_property PACKAGE_PIN Y8  [get_ports {cam_data[7]}]

set_property PACKAGE_PIN Y9 [get_ports cam_pclk]
set_property PACKAGE_PIN U8 [get_ports cam_href]
set_property PACKAGE_PIN W6 [get_ports cam_vsync]
set_property PACKAGE_PIN Y7 [get_ports cam_xclk]
set_property PACKAGE_PIN V7 [get_ports cam_sda]
set_property PACKAGE_PIN W9 [get_ports cam_scl]

###########################################################
# HDMI (TMDS DIFFERENTIAL)
###########################################################
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_p[*]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_n[*]}]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_clk_n]

# HDMI CLOCK
set_property PACKAGE_PIN L16 [get_ports hdmi_clk_p]
# N-side pin L17 is automatically inferred by Vivado for OBUFDS

# HDMI DATA
set_property PACKAGE_PIN K17 [get_ports {hdmi_tx_p[0]}]
# N-side pin K18 inferred

set_property PACKAGE_PIN K19 [get_ports {hdmi_tx_p[1]}]
# N-side pin J19 inferred

set_property PACKAGE_PIN J18 [get_ports {hdmi_tx_p[2]}]
# N-side pin H18 inferred