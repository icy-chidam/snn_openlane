create_clock -name clk -period 10 [get_ports clk]
set_clock_uncertainty 0.1 [get_clocks clk]
set_input_delay 1.0 -clock clk [all_inputs]
set_output_delay 1.0 -clock clk [all_outputs]