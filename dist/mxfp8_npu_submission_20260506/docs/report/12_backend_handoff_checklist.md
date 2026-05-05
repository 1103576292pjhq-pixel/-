# 12 Backend Handoff Checklist

This checklist is for the engineer receiving the MXFP8 NPU front-end RTL handoff package.

## 1. Top Module

| Item | Value |
| --- | --- |
| Top module | `mx_array_32x16` |
| Top RTL file | `rtl/mx_array_32x16.v` |
| Main column module | `rtl/llmt_col.v` |
| RTL language | Pure Verilog-2001 |
| Clock | `clk` |
| Reset | `rst_n`, active-low asynchronous reset |
| Control | `valid_i`, `acc_clear_i[15:0]`, `valid_o[15:0]` |
| Data input | `a_elems_i`, `a_scale_i`, `b_elems_i`, `b_scale_i` |
| Data output | `acc_o[16*32-1:0]` |

## 2. Files To Receive

| Category | Paths |
| --- | --- |
| RTL | `rtl/*.v`, `rtl/*.vh` |
| Testbench | `tb/*.v` |
| Python reference | `tools/mx_ref.py` |
| Regression scripts | `sim/run_iverilog.ps1`, `sim/run_python_ref.ps1`, `sim/run_waveform_smoke.ps1`, `sim/run_submission_regression.ps1` |
| Waveform rendering | `sim/render_waveform_screenshots.ps1`, `tools/render_waveform_png.py` |
| Vectors | `vectors/*/manifest.json`, `vectors/*/*.hex` |
| Constraint template | `constraints/mx_array_32x16.sdc` |
| Synthesis templates | `synth/run_dc_template.tcl`, `synth/run_yosys_generic.ys` |
| Verification reports | `reports/verification/*.log` |
| Precision reports | `reports/precision/*.json` |
| Evidence package | `reports/evidence/final_evidence_index_2026-05-06.md`, `reports/evidence/boundary_case_matrix.md`, `reports/evidence/waveforms/*.vcd`, `reports/evidence/waveform_screenshots/*.png` |
| Synthesis environment record | `reports/synthesis/environment_check_2026-05-06.md` |

## 3. Frontend Recheck Commands

Run these first:

```powershell
.\sim\run_iverilog.ps1
.\sim\run_python_ref.ps1
.\sim\run_waveform_smoke.ps1
.\sim\render_waveform_screenshots.ps1
.\sim\run_submission_regression.ps1 -Fast
```

Expected local result after final packaging is `PASS_WITH_EXTERNAL_SYNTH_BLOCKER`: frontend checks pass, but real synthesis/PPA is blocked by environment.

## 4. Constraints And Scripts

Start from:

- `constraints/mx_array_32x16.sdc`
- `synth/run_dc_template.tcl`
- `synth/run_yosys_generic.ys`

Before real synthesis, backend must replace placeholder libraries and tune:

- target clock period,
- input/output delay,
- clock uncertainty,
- reset/valid/clear timing assumptions,
- load/drive/corner assumptions,
- library paths and link libraries.

## 5. Expected Backend Outputs

When a real backend environment is available, produce and archive:

| Output | Required evidence |
| --- | --- |
| Generic structural check | Yosys or equivalent raw log and generated JSON/netlist, if tool is available. |
| 28nm mapped netlist | Tool command, tool version, library version, corner, generated Verilog netlist. |
| Timing report | target period, WNS, TNS, worst paths, path modules. |
| Area report | total cell area, combinational/sequential area, module breakdown. |
| Power report | internal/switching/leakage, activity source, workload window. |
| Gate-level simulation | netlist, optional SDF, command log, PASS/FAIL result. |
| Final signoff material | Any contest-required DRC/LVS/IR/EM or physical reports, if in scope. |

Do not update `docs/report/07_synthesis_and_ppa.md` with numeric PPA until these raw outputs exist.

## 6. Current Blockers

```text
BLOCKED_NO_SYNTH_TOOL
BLOCKED_NO_28NM_LIB
```

These blockers mean the front-end RTL handoff is ready for backend intake, but real mapped netlist and PPA are not completed in this repository.

## 7. Package Hygiene Check

The official package must not contain:

- `.git/`
- `.omx/`
- `.codexpotter/`
- `work/`
- `sim/*.vvp`
- `potter-run.log`
- temporary runner files

The package generator `tools/package_submission.py` enforces these exclusions and writes `dist/mxfp8_npu_submission_20260506/PACKAGE_CONTENTS.txt`.
