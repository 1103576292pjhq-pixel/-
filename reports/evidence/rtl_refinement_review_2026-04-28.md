# RTL 收口审查记录（2026-04-28）

## 审查范围

- `rtl/llmt_col.v`
- `rtl/mx_array_32x16.v`
- `rtl/mx_defs.vh`
- `rtl/mx_funcs.vh`

目标是判断是否存在不改变顶层接口、低风险且值得立即执行的 RTL 竞赛化改进。

## 当前判断

本轮不修改 RTL。理由：

- `llmt_col` 已经完成从单段 dot32 到 `4 x 8` partial-sum 的保守流水化，且 2026-04-28 回归全绿。
- `mx_array_32x16` 顶层接口清晰，16 列实例化和 bit slicing 逻辑直接，不存在明显低风险重构收益。
- 更激进的 reduction retiming、FP32 add pipeline、资源共享或 valid/clear 协议调整都会扩大验证面，应该等真实综合时序报告指出瓶颈后再做。
- 比赛当前更缺报告、证据和 handoff 包完整性，而不是在没有 PPA 反馈的情况下继续改 RTL。

## 可保留的后续优化项

| 方向 | 潜在收益 | 风险 | 触发条件 |
| --- | --- | --- | --- |
| 8-lane 内部再拆 partial sum | 缩短 S1 组合路径 | 增加寄存器和 valid 对齐验证 | 综合报告显示 S1 reduction 是关键路径 |
| FP32 add 多周期或 pipeline | 提升频率 | 改变 accumulator latency，影响 testbench | 综合报告显示 `fp32_add_rne` 是关键路径 |
| 列间资源共享 | 降面积 | 降吞吐，调度复杂度上升 | 面积成为主要评分瓶颈 |
| 异常 flag 外显 | 增强可观测性 | 改接口，不适合当前稳定基线 | 主办方要求 IEEE exception 细节 |

## 本轮验证依据

- `reports/verification/iverilog_default.log`：PASS。
- `reports/verification/python_ref_default.log`：PASS。
- `reports/precision/matmul_stats_4096x4096x4096_profiles.json`：profile 统计已刷新。

## 结论

当前 RTL 作为比赛初赛 handoff 基线应保持稳定。后续 RTL 改进应由真实综合/PPA 或新增赛题约束驱动，而不是为了形式上“继续优化”而改动已通过回归的计算路径。
