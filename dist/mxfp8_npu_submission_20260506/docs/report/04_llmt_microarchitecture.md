# 04 LLMT 微架构

## 1. 模块职责

`rtl/llmt_col.v` 是阵列的列级计算原语。它接收一个 A block 和一个 B block，计算 32 个 MXFP8 元素的 dot product，并把结果累加到列内 FP32 accumulator。

模块接口保持简洁：

- `valid_i` 标识输入 block 有效。
- `acc_clear_i` 清除本列 accumulator。
- `a_elems_i/a_scale_i` 与 `b_elems_i/b_scale_i` 分别携带 MXFP8 元素和 E8M0 scale。
- `valid_o/acc_o` 输出流水后的累加结果。

## 2. 当前三级流水

当前实现是保守但已回归验证的三级流水：

| 阶段 | 主要逻辑 | 设计目的 |
| --- | --- | --- |
| S1 | 32 lane 解码、乘法、按 `4 x 8` 分组归约，寄存 4 个 partial sums | 避免完整 32 lane 归约树直接压在一个组合阶段 |
| S2 | 4 个 partial sums 做 final merge，并进入 `fixed_to_fp32` | 把前端归约和 FP32 化拆开，形成更清晰的时序边界 |
| S3 | `fp32_add_rne` 与列内 accumulator 相加并写回 | 输出 FP32 累加结果，保持列级 output-stationary 语义 |

`valid_s1`、`valid_s2`、`valid_o` 形成与数据路径一致的 valid 管线。`acc_clear_i && !valid_i` 时，模块清空 accumulator 和 valid 状态，避免清累加与有效输入混用。

## 3. 数值语义

LLMT 路径执行的是项目定义的 projected FP32 accumulation：

1. E4M3 元素和 E8M0 scale 由 Verilog 解码。
2. scale 后的乘积在固定点/扩展整数域中完成 dot32 归约。
3. dot32 结果经 `fixed_to_fp32` 转换为 FP32。
4. 列内 accumulator 使用 `fp32_add_rne` 进行 RNE 加法。

Python golden model `tools/mx_ref.py` 同时用于向量生成和统计分析。非有限值导出统一 canonical QNaN，避免 NaN payload 差异污染 RTL 比对。

## 4. 已完成的竞赛化改进

- 从单段 dot32 组合路径改为显式 `4 x 8` partial-sum 归约。
- 只在 S1 寄存 4 个 partial sums，把 final merge 推到 S2。
- 保持 `llmt_col` 外部接口不变，所有阵列级 testbench 无需改接口。
- 默认 Verilog 回归覆盖 back-to-back 输入，证明流水能接受连续有效 block。

## 5. 仍可优化方向

- 更细粒度的 reduction tree retiming：例如 8-lane 内部再拆分。
- FP32 add 旁路或多周期约束：需要真实综合时序报告后再决定。
- 多列共享资源：可能降低面积，但会降低吞吐，当前不建议在初赛基线中引入。
- 更完善的异常标志：当前输出只对齐数值结果，未暴露 IEEE exception flags。

## 6. 当前结论

`llmt_col` 已经是可验证、可交接的列级基线。它不是最终 PPA 最优实现，但已经具备比赛报告所需的清晰微架构：分组归约、流水寄存、FP32 累加和稳定接口。
