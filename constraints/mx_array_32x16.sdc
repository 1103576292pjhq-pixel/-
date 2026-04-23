create_clock -name clk -period 1.000 [get_ports clk]

set_input_delay  0.10 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 0.10 -clock clk [all_outputs]

set_clock_uncertainty 0.05 [get_clocks clk]

# NOTE:
# 1. 这里是项目级占位约束，后续应根据综合工具和28nm工艺库进一步细化。
# 2. reset/valid/acc_clear 的 false path 或 multicycle 约束暂不在这一版默认添加。
