set TOP mxfp8_array_top
set RTL_DIR ../rtl
set REPORT_DIR ../reports
set BUILD_DIR ../build

file mkdir $REPORT_DIR
file mkdir $BUILD_DIR

# Fill these with real 28nm library files before running technology-mapped synthesis.
# Example:
# set LIBS /path/to/28nm/typical.lib
if {![info exists LIBS] || $LIBS eq ""} {
  puts "ERROR: LIBS is not set. Provide the 28nm Liberty library before running Genus synthesis."
  exit
}

set_db init_lib_search_path [file dirname [lindex $LIBS 0]]
set_db library $LIBS

read_hdl -sv [list \
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
read_sdc constraints.sdc
syn_generic
syn_map
syn_opt

report_timing > $REPORT_DIR/timing.rpt
report_area > $REPORT_DIR/area.rpt
report_power > $REPORT_DIR/power.rpt

write_hdl > $BUILD_DIR/${TOP}_mapped.v
write_sdc > $BUILD_DIR/${TOP}.sdc
