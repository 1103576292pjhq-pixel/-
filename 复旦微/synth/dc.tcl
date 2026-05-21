set TOP mxfp8_array_top
set RTL_DIR ../rtl
set REPORT_DIR ../reports
set BUILD_DIR ../build

file mkdir $REPORT_DIR
file mkdir $BUILD_DIR

# Fill these with the real 28nm .db files before running technology-mapped synthesis.
# Example:
# set_app_var target_library "/path/to/28nm/typical.db"
# set_app_var link_library "* $target_library"
if {![info exists target_library] || $target_library eq ""} {
  puts "ERROR: target_library is not set. Provide the 28nm .db library before running DC synthesis."
  quit
}
set_app_var link_library "* $target_library"

analyze -format sverilog [list \
  $RTL_DIR/mxfp8_pkg.sv \
  $RTL_DIR/fp8_e4m3_decode.sv \
  $RTL_DIR/fp8_e8m0_decode.sv \
  $RTL_DIR/mxfp8_mul.sv \
  $RTL_DIR/fp32_mulprod_to_fp32.sv \
  $RTL_DIR/fp32_add_rne.sv \
  $RTL_DIR/llmt32_dot.sv \
  $RTL_DIR/llmt_array16.sv \
  $RTL_DIR/mxfp8_array_top.sv]

elaborate $TOP
current_design $TOP
link
uniquify

read_sdc constraints.sdc
check_design > $REPORT_DIR/check_design.rpt
compile_ultra -retime

report_timing -delay_type max -max_paths 20 > $REPORT_DIR/timing_max.rpt
report_timing -delay_type min -max_paths 20 > $REPORT_DIR/timing_min.rpt
report_area -hierarchy > $REPORT_DIR/area.rpt
report_power -hierarchy > $REPORT_DIR/power.rpt

write -format verilog -hierarchy -output $BUILD_DIR/${TOP}_mapped.v
write_sdc $BUILD_DIR/${TOP}.sdc
