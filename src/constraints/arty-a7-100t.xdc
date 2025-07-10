set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports rst_btn]

set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports updi]
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports programmer_busy]
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports programmer_start]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports error]
