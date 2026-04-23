# STATUS

- 当前批次：P3 sparse mixed-nonfinite 回归与统计补强
- 本批已完成：`tools/mx_ref.py` 新增 `--elem-nan-stride` / `--scale-nan-stride`，可在有限值底座上稳定注入 sparse nonfinite；`sim/run_matmul_stats*.ps1` 已接通对应参数并修正 `-Seeds 1,2,3` 的 PowerShell 解析；默认 `iverilog` 回归新增 `7x49x224_sparse_nonfinite`，覆盖四列 tile、单 lane 尾 tile、`K=224` 与 scale-NaN，数据集当前为 `222` 个 finite / `121` 个 `NaN` / `0` 个 `inf`；同时补出 `reports/matmul_stats_4096x4096x4096_sparse_nonfinite.json`，其 `2048` 个样本中有 `2004` 个 finite、`44` 个 `NaN`、`0` 个 nonfinite mismatch，finite 子集 `mean_rel_error ≈ 3.91e-7`
- 下一步：继续推进 `LLMT` 的 issue / reduction 微架构，并把 sparse mixed-nonfinite 从单点 spot-check 扩展到多 seed sweep 或更极端硬件回归
- 阻塞项：无；当前为交互会话内推进，未启动独立长期 runner
