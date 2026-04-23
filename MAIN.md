# MXFP8 NPU Project Mainline

## Overall Goal
完整完成“MXFP8 NPU 计算阵列”赛题，形成一套可综合 Verilog 工程、完整验证工具链、综合/PPA脚本骨架、正式技术报告、使用文档，以及面向 0 基础读者的背景教程和代码讲解文档。

## Primary Technical Line
- 数据流：`output-stationary`
- 块粒度：`K = 32`
- 阵列规模：`32 x 16`
- 数值主线：`scale 后置 + dot32 归约 + FP32 累加`
- 代码语言：纯 Verilog-2001
- 真值源：Python `MXFP8` 黄金模型

## Deliverables
1. `rtl/`：最终版可综合 RTL
2. `tb/`：单元、列级、阵列级 testbench
3. `tools/`：黄金模型、向量生成、统计工具
4. `sim/`：一键仿真与参考模型脚本
5. `synth/`、`constraints/`、`reports/`：综合/PPA骨架
6. `docs/report/`：正式技术报告
7. `docs/usage/`：工程使用文档
8. `docs/primer/`：NPU 与 MXFP8 背景教程
9. `docs/teaching/`：逐文件逐段代码讲解

## Batch Plan
- P0：工程骨架、状态文件、目录与文档入口
- P1：黄金模型、格式说明、向量输出能力
- P2：竞赛版 `LLMT` 微架构 RTL
- P3：阵列级与 `4096x4096` 验证
- P4：综合/PPA脚本与约束
- P5：正式技术报告与使用文档
- P6：NPU 背景与原理教程
- P7：逐文件逐段代码讲解

## Current Repo Reality
- 已有：纯 Verilog 三级流水 RTL（`llmt_col` 的 Stage-1 已收敛为只寄存 `4x8` partial sums，final merge 挪到下一段再进入 `fixed_to_fp32`）、单列/阵列 smoke 与 corner test、`4x16x64` / `5x20x96` / `8x32x128` 有限值矩阵数据集回归，以及 `3x18x64` / `6x33x160` mixed nonfinite 矩阵数据集回归（覆盖单 tile、尾 tile、双/三列 tile、finite / inf / NaN 语义）；`tb_mx_array_dataset` 现会显式检查 `valid_o` 只能整向量同时拉高/拉低，Python 参考模型也已把导出的 `NaN` 统一规范化到 canonical `0x7fc00000`
- 缺少：更激进的竞赛版微架构切分、更多四列以上/更大 `M,N` 组合的硬件回归、综合脚本实测结果、正式报告扩写、更多逐段讲解文档

## Immediate Next Targets
- 基于当前 `4x8` partial-sum 寄存化的三级流水 `llmt_col` 继续推进更接近竞赛目标的 reduction / issue 微架构
- 扩大 P3 覆盖：在现有单 tile / 尾 tile / 双/三列 tile 基础上继续增加更多 `M,N` 组合与更强边界场景，并继续保留 `4096x4096` 抽样统计
- 把流水划分、tail tile 回归结论和代码讲解继续写进报告/usage/primer/teaching 文档
