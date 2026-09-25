# FPGA Object Tracking on PYNQ-Z2 + OV7670

OV7670 camera → red-object centroid → bounding-box overlay → HDMI display. Pure Verilog pipeline with testbench for the capture stage.

## Pipeline
```
OV7670 (VGA RGB565) -> ov7670_capture -> frame_buffer (BRAM 320x240)
 -> rgb565_to_rgb888 -> image_threshold (red detect)
 -> centroid_tracker (restoring divider) -> bbox_overlay (40x40 box)
 -> video_timing + hdmi_encoder (TMDS) -> 640x480 HDMI
ov7670_config + sccb_master programs camera over SCCB. clock_generator: 125M -> 25M pixel, 250M TMDS, ~24M cam_xclk.
```

## Files (in `Object Tracking.srcs/`)
| File | Purpose |
|---|---|
| `sources_1/new/top.v` | Top integration |
| `ov7670_capture.v`, `ov7670_config.v`, `sccb_master.v` | Camera interface + init |
| `frame_buffer.v`, `video_timing.v`, `rgb565_to_rgb888.v` | Buffer + timing + convert |
| `image_threshold.v`, `centroid_tracker.v`, `bbox_overlay.v` | Detect + track + draw |
| `hdmi_encoder.v`, `clock_generator.v` | TMDS HDMI + MMCM clocks |
| `sim_1/new/tb_capture.v` | Capture-stage TB (PCLK stimulus, no full-system check) |
| `constrs_1/new/pynq_ov7670.xdc` | PYNQ-Z2 + camera + HDMI pins |

## Pin map (key, see XDC for full)
| Signal | Pin | IO |
|---|---|---|
| sysclk 125 MHz | H16 | LVCMOS33 |
| cam_data[7:0] | V10,V8,W10,W8,V6,Y6,U7,Y8 | LVCMOS33 |
| cam_pclk / href / vsync / xclk | Y9 / U8 / W6 / Y7 | LVCMOS33 |
| cam_sda / scl | V7 / W9 | LVCMOS33 |
| hdmi_clk_p / tx_p[2:0] | L16 / K17,K19,J18 | TMDS_33 |

## Test → expected result
1. `tb_capture`: 25 MHz PCLK, VSYNC/HREF 3-line RGB565 stimulus → `$monitor` shows `we/addr/data` writes; red pixels accumulate toward centroid.
2. Hardware: point camera at red object → green/red 40×40 box follows it on HDMI monitor.

## Build
Vivado → open `Object Tracking.xpr` → Generate Bitstream (`bitstream/top.bit` reference) → program with camera + HDMI connected.

## Status
- Completed: full pipeline RTL, capture TB, XDC, on-board HDMI tracking demo.
- In progress: full-system self-checking TB, centroid accuracy tuning.
- Planned: AXI-stream + PYNQ overlay version.
