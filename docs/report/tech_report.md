# MXFP8 计算阵列技术报告（初稿）

## 1. 赛题目标
本项目面向“块浮点 MXFP8 计算阵列”的赛题，目标是设计并实现一个支持 `32x16` 阵列规模的矩阵乘计算核心。输入矩阵 `A` 和 `B` 采用 `MXFP8` 表示，输出累加结果采用 `FP32`。

## 2. 设计主线
本项目采用以下总体策略：

- 用纯 Verilog 实现可综合 RTL
- 使用 Python 黄金模型作为唯一数值真值源
- 在微架构上采用 `output-stationary` 数据流
- 把块级 `scale` 后置到指数路径，避免每个 lane 重复放大量化/缩放逻辑
- 以 `dot32 + FP32 accumulator` 为列级基本计算原语

## 3. 当前实现状态
当前仓库已经具备：

- `E4M3` / `E8M0` 基础解码模块
- 三级流水版 `dot32` 列级原型 `llmt_col`
- `32x16` 顶层阵列原型
- 单列 smoke test、corner test、阵列 smoke test
- 文件驱动矩阵级 testbench `tb_mx_array_dataset`
- Python 参考模型自检、向量导出、`4096x4096` 抽样误差统计

当前仍需完成：

- 面向比赛频率目标的更激进 `LLMT` 微架构
- 更大覆盖面的阵列级回归与正式验证结论
- 综合脚本、约束与PPA报告
- 完整报告图表和结论

## 4. 已落地的验证链路
- `llmt_col` 当前采用三段流水：`S1` 寄存 `dot32` 整数和与指数偏移，`S2` 寄存 `fixed_to_fp32` 结果，`S3` 做 `FP32` 累加写回；接口与数值语义保持不变。
- `sim/run_iverilog.ps1` 当前默认运行 5 个 testbench，其中矩阵级回归覆盖：
  - `vectors/matmul_4x16x64_smoke/`：`M=4`、`N=16`、`K=64`，验证单 tile、`K_BLOCKS=2`
  - `vectors/matmul_8x32x128_smoke/`：`M=8`、`N=32`、`K=128`，验证双 tile、`K_BLOCKS=4`
- `tools/mx_ref.py --emit-matmul-dataset` 已支持 `--finite-only`，便于生成稳定的硬件回归数据集。
- `sim/run_matmul_stats.ps1` 默认会生成 `reports/matmul_stats_4096x4096x4096.json`，用于快速查看大矩阵抽样误差摘要。

## 5. 当前固定数据集回归结论
本轮默认 Verilog 回归对两组固定数据集均已通过：

- `4x16x64`：用于快速确认基础 tile 驱动与两段 block 累加
- `8x32x128`：用于确认更长 `K`、双 tile 读数和流水 `valid_o` 时序

这意味着当前列核虽然仍是保守版三级流水，但已经能在更贴近矩阵级场景的固定数据集上稳定跑通。

## 6. 当前 `4096x4096` 抽样结果
以 `seed = 20260423`、`samples = 2048`、有限值输入为例，当前参考实现得到：

- `finite_count = 2048`，`nan_count = 0`，`inf_count = 0`
- `mean_rel_error = 3.90e-7`
- `max_rel_error = 7.92e-5`
- `mean_abs_error = 341.06`
- `max_abs_error = 6442.18`

这些数字说明：当前“每个 block 做 dot32，再做 FP32 累加”的参考数值路径，相对未逐步舍入的理想双精度累加，误差量级已经比较可控，后续可以把重点转向竞赛版微架构与更系统的验证覆盖。

## 7. 报告后续章节规划
- MXFP8 格式与数值语义
- 总体架构与数据流
- `LLMT` 微架构与流水线划分
- 阵列接口与调度方式
- 验证方法与误差分析
- 综合、时序、面积、功耗评估
- 优化方向与决赛延展
