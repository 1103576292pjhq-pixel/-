# 批次验收报告：MXFP8 前端 directed corner 扩展

## 基本信息

- 日期：2026-05-09
- 工作区：`D:\github\-`
- 阶段：前端 RTL 编写、测试、仿真
- 明确不做：综合、SDC、网表、面积、功耗、PPA 报告

## 三 Agent 结果

- 规划 lane：完成第二批最小扩展计划，聚焦 `fixed_to_fp32` 与 `fp32_add_rne` 的 directed corner tests。
- 进行 lane：扩展 `tb_fixed_to_fp32_boundary.v` 与 `tb_fp32_add_subnormal.v`，并对 `fp32_add_rne.v` 做 signed-zero 最小修复。
- 审核 lane：指出必须补测负数 subnormal、`nan_i`、overflow、signed-zero；主线已按这些点完成扩展并回归通过。

## 改动范围

- `tb/tb_fixed_to_fp32_boundary.v`
  - 新增负数最小 subnormal。
  - 新增 `nan_i -> QNaN`。
  - 新增正负 overflow 到 Inf。
  - 新增 normal 路径 half-ULP tie-to-even 与 1.5 ULP round-up。
- `tb/tb_fp32_add_subnormal.v`
  - 新增 mixed signed zero 与 `-0 + -0`。
  - 新增 max subnormal + min subnormal 到 min normal。
  - 新增 max subnormal + 2 min subnormal 到 next normal。
  - 新增 Inf + finite。
- `rtl/fp32_add_rne.v`
  - 新增双零输入分支：只有 `-0 + -0` 保留 `-0`，其余双零组合输出 `+0`。

## 数值语义核对

- `fixed_to_fp32` 仍保持 gradual underflow，负数最小 subnormal 输出 `0x80000001`。
- `fixed_to_fp32` normal RNE 通过两个整数缩放样例锁定：
  - `16777217 * 2^-24 -> 1.0`，half-ULP ties to even。
  - `16777219 * 2^-24 -> 1.0 + 2 ULP`。
- `fp32_add_rne` signed-zero 口径已明确：
  - `+0 + -0 -> +0`
  - `-0 + +0 -> +0`
  - `-0 + -0 -> -0`
- NaN 仍按 canonical `MX_FP32_QNAN` 验收。

## 回归结果

- `python .\tools\mx_ref.py --selftest`：PASS
- `.\sim\run_iverilog.ps1`：PASS
  - `tb_fixed_to_fp32_boundary`
  - `tb_fp32_add_basic`
  - `tb_fp32_add_subnormal`
  - `tb_llmt_col_basic`
  - `tb_mx_array_basic`
  - `tb_mx_array_dataset_3x20x64`
  - `tb_mx_array_dataset_2x17x32_nonfinite`
  - `tb_mx_array_dataset_4x33x96_random`
- `.\sim\run_waveform_smoke.ps1`：PASS
  - `build/tb_llmt_col_basic.vcd`
  - `build/tb_mx_array_basic.vcd`
- `.\sim\run_matmul_stats.ps1`：PASS
  - `reports/matmul_stats_4096x4096x4096_sampled.json`

## 4096 采样统计

- 矩阵规模：4096 x 4096 x 4096
- 采样点数：256
- seed：20260508
- mean_abs_error：0.00013804063200950623
- mean_rel_error：9.391798466636242e-07
- max_abs_error：0.0008134841918945312
- max_rel_error：8.614648161471103e-05

## 收尾检查

- 未发现遗留 `vvp.exe` 或 `iverilog.exe` 仿真进程。
- `git diff --check` 对第二批触及文件未报告 whitespace error；仅有 Windows CRLF 处理提示。
- 第二批没有触碰综合、SDC、网表、面积或功耗文件。

## 审核结论

本批通过，可以进入下一批前端验证扩展。下一批建议优先做端到端 directed case：

- `llmt_col` 产生 subnormal、min normal、Inf/NaN 的专门用例。
- `mx_array_32x16` 多列 mixed corner case，验证 A broadcast 与 16 列 B block 独立性。
- 多 seed / 更大 sample 的 4096 统计，并记录误差分布而不只记录最大值。
