set TOP mx_array_32x16

# Replace these paths when a real 28nm library is available.
set SEARCH_PATH [list ./rtl ./constraints ./reports]
set TARGET_LIBRARY [list ./libs/replace_with_28nm_tt.db]
set LINK_LIBRARY   "* $TARGET_LIBRARY"

define_design_lib WORK -path ./work

analyze -format verilog {
  ./rtl/e4m3_decode.v
  ./rtl/e8m0_scale_decode.v
  ./rtl/fixed_to_fp32.v
  ./rtl/fp32_add_rne.v
  ./rtl/llmt_col.v
  ./rtl/mx_array_32x16.v
}

elaborate $TOP
link

source ./constraints/mx_array_32x16.sdc

compile_ultra

report_timing > ./reports/dc_timing.rpt
report_area   > ./reports/dc_area.rpt
report_power  > ./reports/dc_power.rpt

write -format verilog -hierarchy -output ./reports/${TOP}_dc_netlist.v
