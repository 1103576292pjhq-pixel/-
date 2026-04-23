# MXFP8 NPU Contest Project

这个仓库用于完成“**大语言模型块浮点计算阵列的设计与实现**”赛题，目标是交付一套可综合的纯 Verilog RTL、完整验证链路、综合/PPA脚本骨架，以及中文技术/教学文档。

当前主线：

- 设计一个 `32x16` 的 `MXFP8` 计算阵列
- 输入 `A/B` 为 `MXFP8`，输出累加为 `FP32`
- 代码语言保持纯 Verilog，当前 `llmt_col` 为三级流水，且 Stage-1 只寄存 `4x8` partial sums
- 默认 Verilog 回归已覆盖 `4x16x64`、`5x20x96` 尾 tile、`8x32x128`、`9x65x192` 四组有限值矩阵数据集，以及 `3x18x64`、`6x33x160` 两组 mixed finite / `inf` / `NaN` 矩阵数据集
- 文档同时覆盖：
  - 面向比赛提交的正式技术报告
  - 面向 0 基础读者的 NPU 背景教程和代码讲解

快速入口：

- 工程总览：[MAIN.md](/D:/github/-/MAIN.md)
- 当前状态：[STATUS.md](/D:/github/-/STATUS.md)
- Verilog 回归脚本：[sim/run_iverilog.ps1](/D:/github/-/sim/run_iverilog.ps1)
- Python 参考模型脚本：[sim/run_python_ref.ps1](/D:/github/-/sim/run_python_ref.ps1)
- `4096x4096` 抽样统计脚本：[sim/run_matmul_stats.ps1](/D:/github/-/sim/run_matmul_stats.ps1)
- 使用说明：[docs/usage/README.md](/D:/github/-/docs/usage/README.md)
