# Final Evidence Index (2026-05-06)

This index maps contest-facing claims to reproducible repository evidence. The delivery is an RTL handoff package: real 28nm PPA and mapped netlist evidence are not present because no synthesis backend or 28nm library is available in this workspace.

## Evidence Summary

| Claim | Date | Source command | Output path | Report section | Blocking |
| --- | --- | --- | --- | --- | --- |
| RTL is pure Verilog-2001 and contains no SystemVerilog package/import/logic/always_ff/task automatic usage in `rtl/` and `tb/`. | 2026-05-06 | `sim/run_submission_regression.ps1 -Fast` Preflight search gate | `sim/run_submission_regression.ps1` | `docs/report/submission_report.md` | Blocking if it fails |
| Default Verilog regression passes all 11 column/array/dataset entries. | 2026-05-06 | `sim/run_iverilog.ps1` | `reports/verification/iverilog_default.log` | `docs/report/05_verification_methodology.md` | Blocking |
| Python MX reference model self-test passes and dot32 smoke vectors are regenerated. | 2026-05-06 | `sim/run_python_ref.ps1` | `reports/verification/python_ref_default.log`, `vectors/dot32_smoke/manifest.json` | `docs/report/06_precision_results.md` | Blocking |
| Waveform evidence is reproducible from VCD and rendered PNGs, not manually drawn. | 2026-05-06 | `sim/run_waveform_smoke.ps1`; `sim/render_waveform_screenshots.ps1` | `reports/verification/waveform_smoke.log`, `reports/evidence/waveforms/*.vcd`, `reports/evidence/waveform_screenshots/*.png` | `reports/evidence/waveform_capture_status.md` | Blocking for final evidence package |
| Matrix dataset coverage includes finite, tail tile, multi-tile, mixed nonfinite, and sparse nonfinite cases. | 2026-05-06 | `sim/run_iverilog.ps1` | `reports/verification/iverilog_default.log`, `vectors/matmul_5x20x96_tail/manifest.json`, `vectors/matmul_7x49x224_sparse_nonfinite/manifest.json` | `reports/evidence/boundary_case_matrix.md` | Blocking |
| Boundary cases include zero, E4M3 subnormal, FP32 subnormal, NaN, scale-NaN, back-to-back valid, padding lane, and 4096 sampled stats. | 2026-05-06 | `sim/run_submission_regression.ps1 -Fast` Index stage | `reports/evidence/boundary_case_matrix.md` | `docs/report/submission_report.md` | Blocking |
| 4096 sampled statistics exist as baseline evidence; fast acceptance mode does not relabel them as freshly rerun release stats. | 2026-05-06 | `sim/run_submission_regression.ps1 -Fast` Precision stage | `reports/precision/matmul_stats_4096x4096x4096_profiles.json`, `reports/verification/matmul_stats_profiles.log` | `docs/report/06_precision_results.md` | Blocking if missing |
| Sparse nonfinite profile matches NaN propagation with zero nonfinite mismatch in the archived 3-seed sweep. | 2026-04-28 baseline, checked 2026-05-06 | `sim/run_matmul_stats_profiles.ps1` | `reports/precision/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json` | `docs/report/submission_report.md` | Blocking if contradicted |
| Backend synthesis/PPA is externally blocked, not completed. | 2026-05-06 | `Get-Command iverilog,vvp,python,gtkwave,yosys,openroad,verilator,dc_shell,genus,innovus`; workspace `.db/.lib` search | `reports/synthesis/environment_check_2026-05-06.md` | `docs/report/07_synthesis_and_ppa.md` | External blocker |
| Official package excludes internal state, generated `.vvp`, task files, and temporary runner files. | 2026-05-06 | `python tools/package_submission.py --date 20260506`; `sim/run_submission_regression.ps1 -Fast` Index stage | `dist/mxfp8_npu_submission_20260506/PACKAGE_CONTENTS.txt`, `docs/admin/final_submission_manifest.md` | `docs/report/11_frontend_handoff_and_packaging.md` | Blocking |

## Verification Logs

| Log | Producer | Current use |
| --- | --- | --- |
| `reports/verification/iverilog_default.log` | `sim/run_iverilog.ps1` | Functional PASS evidence for RTL and testbench. |
| `reports/verification/python_ref_default.log` | `sim/run_python_ref.ps1` | Python reference self-test and vector refresh evidence. |
| `reports/verification/waveform_smoke.log` | `sim/run_waveform_smoke.ps1` | VCD generation evidence for report waveforms. |
| `reports/verification/matmul_stats_default.log` | `sim/run_matmul_stats.ps1` | 4096 finite baseline sampled stats. |
| `reports/verification/matmul_stats_sweep.log` | `sim/run_matmul_stats_sweep.ps1` | 3-seed finite baseline sampled stats. |
| `reports/verification/matmul_stats_profiles.log` | `sim/run_matmul_stats_profiles.ps1` | finite_exp8, finite_exp32, finite_exp64, sparse_nonfinite profile evidence. |

## JSON And Vector Evidence

| Evidence | What it proves |
| --- | --- |
| `vectors/dot32_smoke/manifest.json` | Dot32 smoke vector generation and expected outputs. |
| `vectors/matmul_4x16x64_smoke/manifest.json` | Single column tile finite baseline. |
| `vectors/matmul_5x20x96_tail/manifest.json` | Tail tile and padding lane scenario. |
| `vectors/matmul_9x65x192_five_tiles/manifest.json` | Five column tiles and one-lane tail tile scenario. |
| `vectors/matmul_7x49x224_sparse_nonfinite/manifest.json` | Sparse element/scale NaN injection scenario. |
| `reports/precision/matmul_stats_4096x4096x4096_profiles.json` | 4096 sampled precision profiles and dynamic range behavior. |
| `reports/precision/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json` | 6037 finite samples, 107 matched NaN, and 0 mismatched nonfinite in sparse nonfinite sweep. |

## Waveform Evidence

| PNG | Source VCD | Testbench |
| --- | --- | --- |
| `reports/evidence/waveform_screenshots/tb_llmt_col_smoke.png` | `reports/evidence/waveforms/tb_llmt_col_smoke_wave.vcd` | `tb/tb_llmt_col_smoke.v` |
| `reports/evidence/waveform_screenshots/tb_llmt_col_back_to_back.png` | `reports/evidence/waveforms/tb_llmt_col_back_to_back_wave.vcd` | `tb/tb_llmt_col_back_to_back.v` |
| `reports/evidence/waveform_screenshots/tb_mx_array_smoke.png` | `reports/evidence/waveforms/tb_mx_array_smoke_wave.vcd` | `tb/tb_mx_array_smoke.v` |

## Blocking Policy

Functional, evidence, packaging, and pure-Verilog failures block submission. Missing synthesis backend tools or missing real 28nm `.db/.lib` files do not block the RTL handoff package, but they must remain visible as `BLOCKED_NO_SYNTH_TOOL` and `BLOCKED_NO_28NM_LIB` until a real backend environment is provided.
