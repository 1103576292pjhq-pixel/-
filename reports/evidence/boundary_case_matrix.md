# Boundary Case Matrix

This matrix connects required boundary cases to concrete RTL, testbench, vector, JSON, log, or report evidence. It is meant for final submission review, not for teaching expansion.

| Boundary case | Evidence path | Covered mechanism | Current result |
| --- | --- | --- | --- |
| Zero block | `tb/tb_llmt_col_corner.v`, `reports/verification/iverilog_default.log` | `tb_llmt_col_corner` checks an all-zero input block against `FP32_ZERO`. | PASS in Verilog default regression. |
| E4M3 subnormal | `tb/tb_llmt_col_corner.v`, `rtl/e4m3_decode.v`, `docs/report/02_mx_format_and_numeric_rules.md` | Directed subnormal path uses `E4M3_SUB_ONE` and verifies the accumulated `0.0625` result. | PASS in `tb_llmt_col_corner`. |
| FP32 subnormal | `tb/tb_llmt_col_corner.v`, `rtl/fixed_to_fp32.v`, `rtl/fp32_add_rne.v` | Directed `E8M0_EXP_NEG77` cases check `FP32_MIN_SUB` and `FP32_TWO_MIN_SUB`. | PASS in `tb_llmt_col_corner`. |
| Max finite / finite dynamic range | `tools/mx_ref.py`, `reports/precision/matmul_stats_4096x4096x4096_finite_exp64_sweep.json`, `docs/report/06_precision_results.md` | finite_exp64 profile stresses larger exponent range and records projected FP32 dynamic-range differences. | Release-rerun precision evidence; not a PPA claim. |
| Element NaN | `tb/tb_llmt_col_corner.v`, `rtl/e4m3_decode.v`, `reports/verification/iverilog_default.log` | Directed `E4M3_NAN` input must propagate to `FP32_QNAN`. | PASS in `tb_llmt_col_corner`. |
| Scale-NaN | `tb/tb_llmt_col_corner.v`, `rtl/e8m0_scale_decode.v`, `vectors/matmul_7x49x224_sparse_nonfinite/manifest.json` | Directed `E8M0_NAN` and sparse dataset scale-NaN injection cover scale nonfinite behavior. | PASS in directed regression; dataset manifest records scale-NaN injections. |
| Tail tile | `vectors/matmul_5x20x96_tail/manifest.json`, `tb/tb_mx_array_dataset_5x20x96.v`, `reports/verification/iverilog_default.log` | N=20 creates one full 16-column tile plus a 4-column tail tile. | PASS in matrix dataset regression. |
| Back-to-back valid | `tb/tb_llmt_col_back_to_back.v`, `reports/evidence/waveforms/tb_llmt_col_back_to_back_wave.vcd`, `reports/evidence/waveform_screenshots/tb_llmt_col_back_to_back.png` | Continuous valid input verifies column pipeline ordering and throughput. | PASS log and reproducible VCD/PNG. |
| Sparse nonfinite | `vectors/matmul_7x49x224_sparse_nonfinite/manifest.json`, `reports/precision/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json` | Sparse element/scale NaN injection covers nonfinite propagation without making every sample nonfinite. | Dataset PASS; 4096 sparse sweep records 107 matched NaN and 0 nonfinite mismatch. |
| Padding lane | `vectors/matmul_5x20x96_tail/manifest.json`, `tb/tb_mx_array_dataset.v`, `reports/evidence/key_case_list.md` | Dataset wrapper checks inactive lanes in non-16-aligned column tiles. | PASS in tail and nonfinite dataset regressions. |
| 4096 sampled stats | `reports/precision/matmul_stats_4096x4096x4096_profiles.json`, `reports/verification/matmul_stats_profiles.log`, `sim/run_submission_regression.ps1` | Profile sweep covers finite_exp8, finite_exp32, finite_exp64, and sparse_nonfinite. Release mode reruns scripts; fast acceptance checks only that the baseline evidence exists. | Release acceptance reran the statistics on 2026-05-06. |

## Notes

- Tail tile and padding lane correctness are checked through fixed vectors and the dataset testbench, not through large VCD files.
- Dynamic-range finite_exp64 results document numeric category behavior of the projected FP32 path; they must not be rewritten as real hardware timing, area, or power evidence.
- Gate-level X propagation, SDF timing, and power waveform checks remain backend tasks after real mapped netlist generation.
