# Clock constraints
create_clock -name {CLOCK_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLOCK_50}]
create_clock -name {clk_out} -period 286.000 -waveform { 0.000 143.000 } [get_registers {clk_div:clk_div|clk_out clk_div:clk_div|clk_out~_Duplicate_1}]
create_clock -name {vga_clk} -period 40.000 -waveform { 0.000 20.000 } [get_registers {vdp:vdp|vga_timing:vga_timing|vga_clk}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty
