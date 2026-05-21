# MXFP8 Array Delivery Notes

## Delivered top

- RTL top module: `mxfp8_array_top`
- Constraint file: `synth/constraints.sdc`
- DC script template: `synth/dc.tcl`
- Genus script template: `synth/genus.tcl`
- Yosys generic synthesis script: `synth/yosys.ys`

## Current local tool status

Detected locally:

- Python: available
- Icarus Verilog: available

Not detected locally:

- make
- yosys
- dc_shell
- genus

Because no synthesis tool and no 28nm standard-cell library are available in this environment, a real 28nm technology-mapped gate netlist cannot be produced here yet.

## How to generate netlist later

### With Synopsys Design Compiler

Set the real 28nm `.db` library in `synth/dc.tcl`, then run from `synth/`:

```sh
dc_shell -f dc.tcl
```

Expected outputs:

- `build/mxfp8_array_top_mapped.v`
- `build/mxfp8_array_top.sdc`
- `reports/timing_max.rpt`
- `reports/timing_min.rpt`
- `reports/area.rpt`
- `reports/power.rpt`

### With Cadence Genus

Set the real 28nm Liberty file list in `synth/genus.tcl`, then run from `synth/`:

```sh
genus -f genus.tcl
```

Expected outputs:

- `build/mxfp8_array_top_mapped.v`
- `build/mxfp8_array_top.sdc`
- `reports/timing.rpt`
- `reports/area.rpt`
- `reports/power.rpt`

### With Yosys for generic non-28nm netlist

If Yosys is installed, run from `synth/`:

```sh
yosys yosys.ys
```

Expected output:

- `build/mxfp8_array_top_generic_netlist.v`

This generic netlist is not a 28nm mapped netlist and must not be used for competition area/power claims.

## Verified locally

The following checks passed with Icarus Verilog/Python:

- `tb_fp8_decode`
- `tb_llmt32_dot`
- `tb_llmt_array16`
- `tb_mxfp8_array_top` with 16 generated vector cases
- 4096-point random MAC reference generation

## Numeric assumptions

- E4M3 uses exponent bias 7.
- E4M3 exponent zero is treated as subnormal/zero.
- E4M3 has no infinity encoding; `S.1111.110` is max finite and `S.1111.111` is NaN.
- E8M0 scale is interpreted as `2^(scale - 127)` for encodings `0x00` through `0xfe`.
- E8M0 `0xff` is treated as NaN.
- The RTL LLMT uses a tree reduction, so reference vectors are generated with the same pairwise FP32 addition order.
