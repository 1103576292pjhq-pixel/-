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
- 已有：纯 Verilog 参考 RTL、单列/阵列 smoke 与 corner test、文件驱动矩阵级数据集回归、Python 参考模型与 `4096x4096` 抽样统计脚本
- 缺少：竞赛版微架构、长流水 `LLMT` 切分、更多矩阵规模的硬件回归、综合脚本实测结果、正式报告扩写、逐段讲解文档

## Immediate Next Targets
- 把 `llmt_col` 从参考版单拍实现推进到更接近竞赛目标的流水微架构
- 扩大 P3 覆盖：增加更长 `K` 和更多 tile 组合的阵列级回归
- 把验证结果、脚本入口和代码讲解继续写进报告/usage/teaching 文档
