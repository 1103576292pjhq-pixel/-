# NPU 背景教程 04：为什么验证和误差统计这么设计

## 1. 为什么不能只跑一个 smoke test

一个 smoke test 只能说明“最简单路径可能能跑”。比赛项目还要证明：

- 单列流水能连续接收输入。
- 阵列 16 列切片没有接错。
- 矩阵 tile 调度正确。
- 尾 tile 不残留旧结果。
- NaN/Inf 传播语义正确。
- 大矩阵抽样误差可解释。

所以本项目把验证分成多层。

## 2. 验证层级

| 层级 | 看什么 | 代表文件 |
| --- | --- | --- |
| 列级 | 一个 `llmt_col` 是否会算 dot32 和累加 | `tb_llmt_col_*` |
| 阵列级 | 16 列是否正确连起来 | `tb_mx_array_smoke.v` |
| 矩阵级 | row/tile/K block 调度是否正确 | `tb_mx_array_dataset*.v` |
| Python 参考 | golden model 是否自洽 | `tools/mx_ref.py` |
| 统计级 | 大矩阵误差趋势 | `sim/run_matmul_stats*.ps1` |

## 3. PASS 日志怎么看

当前最重要的日志在：

- `reports/verification/iverilog_default.log`
- `reports/verification/python_ref_default.log`
- `reports/verification/matmul_stats_profiles.log`

如果你向别人解释项目，不要只说“我觉得能跑”，要说“哪个命令、哪个日志、哪一天、覆盖了哪些 case”。

## 4. mean_rel_error 和 max_rel_error

`mean_rel_error` 是平均相对误差，代表总体趋势。

`max_rel_error` 是最大相对误差，常常来自输出值很小的 case。因为分母小，相对误差会被放大。所以报告里应该同时看 absolute error 和 relative error。

## 5. nonfinite mismatch

如果 project 输出 NaN，而 ideal 输出 finite，或者反过来，就是 nonfinite mismatch。它通常比普通误差更严重，因为输出类别都不同了。

当前 sparse nonfinite 三 seed sweep 的 `total_mismatched_nonfinite_count = 0`，这是异常值传播语义对齐的重要证据。

## 6. 一周复述要点

你需要能讲清楚：

1. smoke、corner、back-to-back、dataset、4096 sampling 分别证明什么。
2. 为什么固定向量比临时随机更适合评审复验。
3. finite 误差和 nonfinite mismatch 是两类指标。
4. `finite_exp64` 的类别差异是动态范围边界，不是默认 RTL 回归失败。
