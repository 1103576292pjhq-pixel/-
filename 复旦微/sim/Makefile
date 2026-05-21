PYTHON ?= python
IVERILOG ?= iverilog
VVP ?= vvp

RTL = ../rtl/mxfp8_pkg.sv \
      ../rtl/fp8_e4m3_decode.sv \
      ../rtl/fp8_e8m0_decode.sv \
      ../rtl/mxfp8_mul.sv \
      ../rtl/fp32_mulprod_to_fp32.sv \
      ../rtl/fp32_add_rne.sv \
      ../rtl/llmt32_dot.sv \
      ../rtl/llmt_array16.sv \
      ../rtl/mxfp8_array_top.sv

BUILD = ../build

.PHONY: all unit llmt array vectors rand4096 clean

all: unit llmt array

$(BUILD):
	mkdir -p $(BUILD)

unit: $(BUILD)
	$(IVERILOG) -g2012 -o $(BUILD)/tb_fp8_decode.vvp $(RTL) ../tb/tb_fp8_decode.sv
	$(VVP) $(BUILD)/tb_fp8_decode.vvp

llmt: $(BUILD)
	$(IVERILOG) -g2012 -o $(BUILD)/tb_llmt32_dot.vvp $(RTL) ../tb/tb_llmt32_dot.sv
	$(VVP) $(BUILD)/tb_llmt32_dot.vvp

vectors:
	cd .. && $(PYTHON) model/gen_vectors.py vectors --out sim/array_vectors.hex --cases 16 --seed 7

array: $(BUILD) vectors
	$(IVERILOG) -g2012 -o $(BUILD)/tb_llmt_array16.vvp $(RTL) ../tb/tb_llmt_array16.sv
	$(VVP) $(BUILD)/tb_llmt_array16.vvp
	$(IVERILOG) -g2012 -o $(BUILD)/tb_mxfp8_array_top.vvp $(RTL) ../tb/tb_mxfp8_array_top.sv
	$(VVP) $(BUILD)/tb_mxfp8_array_top.vvp

rand4096:
	cd .. && $(PYTHON) model/ref_mxfp8.py mac4096 --seed 13

clean:
	rm -rf $(BUILD) array_vectors.hex
