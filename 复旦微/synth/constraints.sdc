# MXFP8 32x16 compute array core constraints
# Target: 1 GHz core clock placeholder for 28nm synthesis.
# Update IO delay, uncertainty, loads and operating conditions with the real library and top-level integration budget.

create_clock -name core_clk -period 1.000 [get_ports clk]

set_clock_uncertainty 0.080 [get_clocks core_clk]
set_clock_transition 0.050 [get_clocks core_clk]

set_input_delay  0.150 -clock core_clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 0.150 -clock core_clk [all_outputs]

set_false_path -from [get_ports rst_n]

set_max_fanout 32 [current_design]
