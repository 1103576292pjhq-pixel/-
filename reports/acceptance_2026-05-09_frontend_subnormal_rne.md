# 批次验收报告：MXFP8 前端 subnormal / RNE 修复

## 基本信息

- 日期：2026-05-09
- 工作区：`D:\github\-`
- 阶段：前端 RTL 编写、测试、仿真
- 明确不做：综合、SDC、网表、面积、功耗、PPA 报告

## 三 Agent 结果

- 规划 lane：完成本批边界定义，限定只修前端 RTL/仿真；计划文件为 `.omx/plans/mxfp8_frontend_batch_plan_2026-05-09.md`。
- 进行 lane：完成 `fixed_to_fp32` 的 Icarus 兼容修复、normal 路径 RNE 补齐，以及 `fp32_add_rne` 的组合输出稳定化。
- 审核 lane：初审指出旧源码仍有动态 range part-select、signed-zero 与 directed case 覆盖不足等风险；主线按当前工作区复核后确认动态 range part-select 已移除，回归已通过。

## 改动范围

- `rtl/fixed_to_fp32.v`
  - 将 `round_shift_right_wide` 中的动态 range part-select 改为循环 sticky bit 归约。
  - 对 normal 输出路径重新使用 RNE 右移，处理舍入进位导致的指数上抬与溢出到 Inf。
  - 保持 subnormal 结果由 `wide_scaled[22:0]` 输出，不做 flush-to-zero。
- `rtl/fp32_add_rne.v`
  - 将预选输出 `sum_pre_o` 与 `sum_cast_o` 的最终选择拆开，避免 Icarus 下组合子模块输出回读引发的仿真卡住。
- `sim/run_iverilog.ps1`
  - 当前回归矩阵包含 8 个 testbench：fixed、fp32 add、LLMT、array、3 组矩阵数据集。
- 相关 testbench / dataset / Python 参考模型已保留在当前前端最小工程中。

## 数值语义核对

- gradual underflow：通过 `tb_fixed_to_fp32_boundary` 覆盖最小 subnormal、真正下溢到 0、最大 subnormal、跨到最小 normal。
- RNE：`fixed_to_fp32` 的右移舍入使用 guard、sticky 和 shifted LSB 实现 tie-to-even。
- `fp32_add_rne`：有限数加法最终仍通过 `fixed_to_fp32` 编码，因此与同一套 subnormal / RNE 出口对齐。
- 非目标：当前没有宣称已完成所有 IEEE-754 corner case 的完整形式化证明。

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
- 说明：统计脚本比较“每个 dot 与 FP32 累加路径”对 Python double ideal 路径的偏差。

## 收尾检查

- `rg` 未发现 `value[shift-2:0]` 这类动态 range part-select；仅保留 `value[shift-1]` 动态单比特索引。
- 未发现遗留 `vvp.exe` 或 `iverilog.exe` 仿真进程。
- `git diff --check` 对本批前端文件未报告 whitespace error；仅提示 Windows CRLF 处理警告。

## 审核结论

本批通过，可以进入下一批前端验证扩展。下一批建议优先补：

- `fixed_to_fp32` 负数、NaN、overflow、更多 tie-to-even directed case；
- `fp32_add_rne` signed-zero、Inf/NaN、subnormal-to-normal 过渡补测；
- `llmt_col` / `mx_array_32x16` 的 subnormal 端到端 directed case；
- 多 seed / 更大样本数的 4096 采样统计。
