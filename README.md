# MXFP8 32x16 Frontend RTL Baseline

This workspace is in a frontend-only RTL phase for the MXFP8 32x16 compute-array
contest task.

Current scope:

- write clean synthesizable Verilog RTL
- run deterministic simulations with Icarus Verilog
- keep a lightweight Python reference and dataset generator
- keep acceptance reports for each completed frontend batch
- do not run synthesis, PPA, netlist, SDC, packaging, or old report flows

Top module:

- `rtl/mx_array_32x16.v`

## What Is Implemented

- `rtl/llmt_col.v`: one MXFP8 dot32 column with FP32 accumulation.
- `rtl/mx_array_32x16.v`: 16-column array; A block broadcast, B block per column.
- `rtl/fixed_to_fp32.v`: fixed-point dot result to FP32 with gradual underflow and RNE.
- `rtl/fp32_add_rne.v`: FP32 add helper for the accumulator path.
- `tools/mx_ref.py`: Python reference, dataset generation, and sampled 4096 stats.

## Current Usability Status

As of the latest frontend acceptance pass, the code is usable for RTL simulation
and frontend verification. It is not yet a synthesis handoff package.

Passing gates:

- Python reference self-test.
- Icarus build/run for 10 Verilog testbenches.
- VCD smoke generation for LLMT and array basics.
- Sampled `4096x4096x4096` precision statistics.
- Multi-seed sampled `4096x4096x4096` precision evidence.

Known limits:

- No synthesis, SDC, netlist, timing, area, or power report in this phase.
- `4096x4096x4096` is sampled precision statistics, not a full output dump.
- More seeds and broader precision sweeps are still recommended before backend work.

## Run The Frontend Checks

Recommended one-shot entry:

```powershell
.\sim\run_frontend_regression.ps1
```

This wrapper runs the current frontend acceptance chain in order: Python
self-test, directed RTL regression, waveform smoke, and sampled matmul stats.

```powershell
python .\tools\mx_ref.py --selftest
.\sim\run_iverilog.ps1
.\sim\run_waveform_smoke.ps1
.\sim\run_matmul_stats.ps1
```

Useful generated artifacts:

- `build/tb_llmt_col_basic.vcd`
- `build/tb_mx_array_basic.vcd`
- `reports/matmul_stats_4096x4096x4096_sampled.json`

Optional multi-seed precision evidence:

```powershell
.\sim\run_matmul_stats_multiseed.ps1
```

The default multi-seed run uses three seeds with 256 sampled row/column points
per seed and writes `reports/matmul_stats_4096x4096x4096_multiseed.json`.
It checks default frontend guardrails of `mean_rel_error <= 1.0e-5` and
`max_rel_error <= 1.0e-3`. Override with `-Seeds`, `-Samples`, `-M`, `-N`,
`-K`, `-Out`, `-MeanRelErrorLimit`, `-MaxRelErrorLimit`, or
`-NoThresholdCheck` when needed.

Optional precision-profile sweep:

```powershell
.\sim\run_matmul_precision_profiles.ps1
```

The default profile run evaluates `baseline`, `narrow-scale`, and `wide-scale`
over the same three-seed sampled `4096x4096x4096` shape and writes:

- `reports/matmul_stats_4096x4096x4096_profiles.json`
- `reports/matmul_stats_4096x4096x4096_baseline_multiseed.json`
- `reports/matmul_stats_4096x4096x4096_narrow-scale_multiseed.json`
- `reports/matmul_stats_4096x4096x4096_wide-scale_multiseed.json`

`baseline` preserves the existing finite sampled distribution. `narrow-scale`
uses E8M0 scales from `2^-1` through `2^1`. `wide-scale` uses the same finite
E4M3 element set with a wider E8M0 scale profile from `2^-6` through `2^6`.
Use `-Profiles`, `-Seeds`, `-Samples`, `-M`, `-N`, `-K`, `-Out`,
`-MeanRelErrorLimit`, `-MaxRelErrorLimit`, or `-NoThresholdCheck` to change the
run.

Use the individual commands when you only need one part of the frontend flow.

## Dataset Regeneration

The checked-in generated datasets can be regenerated with:

```powershell
python .\tools\mx_ref.py --emit-matmul-dataset --out-dir .\vectors\matmul_3x20x64_smoke --m 3 --n 20 --k-blocks 2
python .\tools\mx_ref.py --emit-matmul-dataset --out-dir .\vectors\matmul_2x17x32_nonfinite --m 2 --n 17 --k-blocks 1 --inject-nonfinite
python .\tools\mx_ref.py --emit-matmul-dataset --out-dir .\vectors\matmul_4x33x96_random --m 4 --n 33 --k-blocks 3 --random --seed 20260508
```

Acceptance reports are under `reports/acceptance_*.md`.
