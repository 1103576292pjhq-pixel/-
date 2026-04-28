# 代码讲解 05：Python 参考模型和脚本怎么配合

## 1. 为什么需要 Python golden model

RTL 负责实现硬件，但验证时必须有一个独立参考。`tools/mx_ref.py` 承担三件事：

1. 自检 MXFP8 数值函数。
2. 生成固定向量到 `vectors/`。
3. 对 4096 规模矩阵乘做抽样统计。

## 2. 常用脚本

| 脚本 | 作用 |
| --- | --- |
| `sim/run_python_ref.ps1` | Python self-test，并生成 `vectors/dot32_smoke` |
| `sim/run_iverilog.ps1` | 编译并运行默认 Verilog 回归 |
| `sim/run_matmul_stats.ps1` | 单 seed 4096 抽样 |
| `sim/run_matmul_stats_sweep.ps1` | 多 seed 4096 抽样 |
| `sim/run_matmul_stats_profiles.ps1` | 多 profile 汇总 |

## 3. 向量目录怎么读

一个矩阵向量目录通常包含：

- `manifest.json`：M/N/K、seed、格式和文件说明。
- `a_blocks.hex`、`a_scales.hex`：A 输入。
- `b_blocks.hex`、`b_scales.hex`：B 输入。
- `expected_y.hex`：期望 FP32 输出。

Verilog testbench 读这些文件，比运行时随机生成更稳定。

## 4. 统计 JSON 怎么读

重点字段：

- `finite_count`：有限值样本数。
- `mean_rel_error`：平均相对误差。
- `max_rel_error`：最大相对误差。
- `matched_nonfinite_count`：project 和 ideal 都是同类非有限值。
- `mismatched_nonfinite_count`：project 和 ideal 的有限/非有限类别不同。

## 5. 自测题

1. 为什么固定向量适合比赛复验？
2. `run_matmul_stats_profiles.ps1` 里的 `sparse_nonfinite` 想证明什么？
3. 为什么不能只用 `mean_rel_error` 判断数值质量？
