# 01 题目与目标

## 1. 题目理解

本项目面向“块浮点 MXFP8 计算阵列”的比赛任务，目标是设计并实现一个用于矩阵乘的低精度计算核心。输入矩阵 `A` 和 `B` 使用 MXFP8 块浮点格式，输出累加结果使用 FP32。

本仓库实现的是计算阵列 RTL 和验证/报告包，不包含完整芯片 SoC、存储层级、DMA、NoC 或真实后端 GDS 流程。

## 2. 设计目标

| 目标 | 当前落点 |
| --- | --- |
| 可综合 RTL | `rtl/`，保持纯 Verilog-2001 |
| 矩阵乘计算核心 | `rtl/mx_array_32x16.v`、`rtl/llmt_col.v` |
| MXFP8 数值路径 | `rtl/mx_funcs.vh`、`rtl/fixed_to_fp32.v`、`rtl/fp32_add_rne.v`、`tools/mx_ref.py` |
| 可复验功能验证 | `tb/`、`vectors/`、`sim/run_iverilog.ps1` |
| Python golden model | `tools/mx_ref.py`、`sim/run_python_ref.ps1` |
| 精度统计 | `sim/run_matmul_stats*.ps1`、`reports/precision/` |
| 综合/PPA 接入 | `constraints/`、`synth/`、`reports/synthesis/` |
| 比赛报告和证据包 | `docs/report/`、`reports/evidence/` |
| 零基础教学资料 | 仓库源树保留，第一轮正式 handoff 包不包含教学目录 |

## 3. 当前实现范围

当前 RTL 的核心参数：

- `MX_BLOCK_K = 32`
- `MX_COLS = 16`
- 输入元素宽度：8 bit E4M3
- block scale：8 bit E8M0
- 输出/累加：FP32
- 数据流：output-stationary

阵列一次对同一 A block 并行计算 16 个 B column block。每列维护一个 FP32 accumulator，K 方向 block 连续输入，最终输出该 row/tile 的 16 个 FP32 结果。

## 4. 交付边界

本项目当前交付边界是 RTL/backend handoff package：

- 可以交付 RTL、testbench、向量、脚本、日志、统计和报告。
- 可以交付 SDC 和综合脚本模板。
- 可以说明后端需要如何补真实 PPA。
- 不能声称已经完成真实 28nm 面积、功耗、频率或时序结果。

## 5. 当前阻塞项

- 主办方补充通知、提交模板和答辩规则未获得。
- 真实 28nm 标准单元库、工艺角和综合工具未获得。
- IEEE 全文细节不可用；报告只使用公开可核查信息和本项目实测日志。

## 6. 本轮完成标准

本轮重启的完成标准不是“做完芯片后端”，而是：

1. 当前 RTL/Python 基线可复验。
2. 报告能按比赛要求组织。
3. 证据包能把结论链接到日志、统计或向量。
4. PPA 章节明确区分模板、方法和真实缺口。
5. 第一轮正式包只包含评审和后端接收所需材料；零基础教学资料留到第二轮教学 Potter。
