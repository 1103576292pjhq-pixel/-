# MXFP8 NPU Submission Report

## 1. Problem And Deliverable

This project implements a pure Verilog MXFP8 NPU compute array for block floating-point matrix multiplication. The competition-facing deliverable is an RTL handoff package: RTL, testbench, Python reference model, fixed vectors, verification logs, waveform evidence, precision statistics, synthesis templates, constraints, and backend receiving instructions.

true 28nm PPA is not completed unless real tool/library logs exist. In this workspace, no real synthesis backend and no real 28nm `.db/.lib` library are available, so the package does not claim real area, power, frequency, WNS, TNS, mapped netlist, or signoff.

## 2. MXFP8 Format

The input path uses MXFP8-style block floating point:

- elements are E4M3 8-bit values,
- each block has 32 elements,
- each block has an E8M0 scale byte,
- products are accumulated through a fixed-point dot32 path and projected into FP32 accumulator output.

The numeric rules are implemented in `tools/mx_ref.py` and RTL helpers including `rtl/e4m3_decode.v`, `rtl/e8m0_scale_decode.v`, `rtl/fixed_to_fp32.v`, and `rtl/fp32_add_rne.v`. NaN inputs and scale-NaN paths are intentionally covered by directed testbench cases and sparse nonfinite matrix vectors.

## 3. Architecture

The top module is `mx_array_32x16` in `rtl/mx_array_32x16.v`.

Key structure:

- array shape: 32-lane dot block by 16 output columns,
- dataflow: output-stationary accumulator,
- A block broadcast: one 32-element A block feeds all 16 columns,
- B blocks: 16 independently packed B blocks feed 16 `llmt_col` instances,
- output: 16 FP32 accumulators packed into `acc_o[16*32-1:0]`.

The top-level interface is intentionally stable for backend handoff. The first Potter batch does not rewrite the RTL architecture for optimization.

## 4. LLMT Column Microarchitecture

`rtl/llmt_col.v` is the column compute unit. It performs:

1. E4M3 element decode and E8M0 scale decode.
2. 32-lane product and reduction into fixed-point partial sums.
3. FP32 projection and accumulator update.
4. valid propagation so output timing is testable.

The current implementation is a front-end RTL baseline. More aggressive timing/power optimization should be driven by real synthesis results, not by speculative rewriting.

## 5. Verification Methodology

Verification has three layers:

- directed column tests: smoke, corner, back-to-back valid,
- array and matrix dataset tests: finite, tail tile, mixed nonfinite, sparse nonfinite,
- Python reference and sampled precision statistics.

Primary commands:

```powershell
.\sim\run_iverilog.ps1
.\sim\run_python_ref.ps1
.\sim\run_waveform_smoke.ps1
.\sim\render_waveform_screenshots.ps1
.\sim\run_submission_regression.ps1 -Fast
```

Current logs:

- `reports/verification/iverilog_default.log`
- `reports/verification/python_ref_default.log`
- `reports/verification/waveform_smoke.log`
- `reports/verification/matmul_stats_profiles.log`

The one-command acceptance script returns `PASS_WITH_EXTERNAL_SYNTH_BLOCKER` when functional/evidence/package gates pass and only synthesis/PPA infrastructure is missing.

## 6. Precision Evidence

The 4096 sampled precision evidence is archived under `reports/precision/`.

The profile summary `reports/precision/matmul_stats_4096x4096x4096_profiles.json` covers:

- finite_exp8: 6144 finite samples, no nonfinite mismatch,
- finite_exp32: 6144 finite samples, no nonfinite mismatch,
- finite_exp64: dynamic range stress evidence for projected FP32 behavior,
- sparse_nonfinite: 6037 finite samples, 107 matched NaN, 0 mismatched nonfinite.

Fast acceptance mode treats these as baseline evidence. Release acceptance mode should rerun long statistics without `-SkipLongStats`.

## 7. Waveform Evidence

Waveform evidence is reproducible:

- VCD generation: `sim/run_waveform_smoke.ps1`
- PNG rendering: `sim/render_waveform_screenshots.ps1`
- VCD location: `reports/evidence/waveforms/`
- PNG location: `reports/evidence/waveform_screenshots/`

The three report PNGs cover:

- `tb_llmt_col_smoke`: clear, dot32, valid, accumulator update,
- `tb_llmt_col_back_to_back`: continuous valid input and ordered outputs,
- `tb_mx_array_smoke`: 16-column top-level smoke behavior.

These PNGs are display evidence; the VCD and regression logs remain the reproducible evidence.

## 8. Synthesis And PPA Boundary

Prepared handoff files:

- `constraints/mx_array_32x16.sdc`
- `synth/run_dc_template.tcl`
- `synth/run_yosys_generic.ys`
- `reports/synthesis/environment_check_2026-05-06.md`
- `docs/usage/02_synthesis_environment_check.md`

Current blockers:

```text
BLOCKED_NO_SYNTH_TOOL
BLOCKED_NO_28NM_LIB
```

Therefore no real 28nm mapped netlist, area, power, timing, or signoff result is included. A backend team must supply real 28nm libraries, constraints, tool scripts, and raw logs before any numeric PPA claim can be added.

## 9. Backend Handoff

Backend receivers should start with `docs/report/12_backend_handoff_checklist.md`.

They receive:

- pure Verilog RTL under `rtl/`,
- SDC template under `constraints/`,
- synthesis templates under `synth/`,
- verification evidence under `reports/verification/`, `reports/precision/`, and `reports/evidence/`,
- package manifest under `docs/admin/final_submission_manifest.md`.

They must produce the missing backend artifacts: mapped netlist, timing report, area report, power report, gate-level simulation evidence, and any physical signoff material required by the contest.

## 10. Optimization Outlook

Future optimization should focus on synthesis-measured bottlenecks:

- dot32 reduction tree timing,
- FP32 accumulator path,
- 16-column area and switching activity,
- valid/clear control timing,
- dataset-driven workload activity for power estimation.

No optimization in this first handoff batch changes the top-level interface. The next technical step depends on real backend feedback or new contest benchmark vectors.
