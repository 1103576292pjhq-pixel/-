# 02 Synthesis Environment Check

This guide tells a teammate or backend engineer how to check whether the current machine can go beyond RTL handoff into generic synthesis or real 28nm implementation.

## Three Different Deliverables

| Deliverable | What it is | Current status |
| --- | --- | --- |
| RTL handoff package | Pure Verilog RTL, testbench, vectors, Python golden model, SDC, synthesis templates, verification logs, reports, and evidence. | Available in this repository. |
| Generic netlist | A technology-independent structural netlist or JSON/stat result from a tool such as Yosys. | Not generated locally because `yosys` is not on PATH. |
| 28nm mapped netlist | A gate-level netlist mapped to a real 28nm standard-cell library, with timing/area/power reports. | Blocked until real backend tools and real `.db/.lib` libraries are provided. |

Do not call a generic netlist a 28nm result. Do not call an RTL handoff package a signoff package.

## Quick Tool Check

Run from the repository root:

```powershell
Get-Command iverilog,vvp,python,gtkwave,yosys,openroad,verilator,dc_shell,genus,innovus -ErrorAction SilentlyContinue
```

Expected local status for this 2026-05-06 handoff:

- `iverilog`, `vvp`, `python`, and `gtkwave` are available.
- `yosys`, `openroad`, `verilator`, `dc_shell`, `genus`, and `innovus` are not available.
- No real 28nm `.db` or `.lib` file is present in the workspace.

The recorded check is `reports/synthesis/environment_check_2026-05-06.md`.

## Frontend Acceptance Check

For fast submission hygiene:

```powershell
.\sim\run_submission_regression.ps1 -Fast
```

Fast mode reruns functional and waveform evidence, but treats 4096 statistics as existing baseline evidence. It must not be described as a fresh release rerun of long statistics.

For release mode:

```powershell
.\sim\run_submission_regression.ps1
```

Release mode reruns the long 4096 sampled statistics scripts before checking the final evidence/package index.

## If Yosys Becomes Available

Use `synth/rtl_filelist.f` as the canonical RTL read order when creating or editing synthesis commands. The current Yosys reference script mirrors that order manually.

Use the existing generic script:

```powershell
yosys -s synth/run_yosys_generic.ys
```

Archive the raw command output under `reports/synthesis/` before updating reports. A Yosys generic stat can prove structural readability and hierarchy sanity, but it is not a 28nm area, timing, or power result.

## If Design Compiler Or Genus Becomes Available

Before running commercial synthesis, the backend must provide:

- real 28nm `.db` or `.lib` standard-cell libraries,
- corner, voltage, temperature, and library naming,
- target clock period and I/O timing assumptions,
- any required wire-load, RC, or physical guidance,
- a synthesis tool/version and an RTL read setup based on `synth/rtl_filelist.f`,
- load/drive assumptions and switching/activity source for power,
- report output policy for timing, area, power, and generated netlist.

Then update `synth/run_dc_template.tcl` or create a Genus equivalent, run the tool, and archive raw logs and reports under `reports/synthesis/`.

## What To Report If Blocked

Use these exact blockers:

```text
BLOCKED_NO_SYNTH_TOOL
BLOCKED_NO_28NM_LIB
```

Write them in `STATUS.md`, `reports/synthesis/environment_check_2026-05-06.md`, and `docs/admin/final_submission_manifest.md`. Do not invent area, power, frequency, WNS, TNS, or mapped-netlist evidence.
