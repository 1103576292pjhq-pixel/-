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
- 三级流水版 `dot32` 列级原型 `llmt_col`，其 Stage-1 已收敛为寄存 `4x8` partial sums，final merge 挪到下一段
- `32x16` 顶层阵列原型
- 单列 smoke test、corner test、阵列 smoke test
- 支持尾 tile 的文件驱动矩阵级 testbench `tb_mx_array_dataset`
- Python 参考模型自检、向量导出、`4096x4096` 抽样误差统计与 profile sweep

当前仍需完成：

- 面向比赛频率目标的更激进 `LLMT` 微架构
- 更大覆盖面的阵列级回归与正式验证结论
- 综合脚本、约束与PPA报告
- 完整报告图表和结论

## 4. 已落地的验证链路
- `llmt_col` 当前采用三段流水：`S1` 先把 32 个 lane 切成 4 组、各自累加出 partial sums 并寄存；`S2` 再把这 4 组 partial sums 做两级合并后送入 `fixed_to_fp32`，并寄存 `FP32` 点积结果；`S3` 做 `FP32` 累加写回。接口与数值语义保持不变，但前端组合路径已经从“32 项串行加法链”收敛到“8 项组内累加 + 下一级合并”。
- `sim/run_iverilog.ps1` 当前默认运行 11 个 testbench，其中：
  - `tb_llmt_col_back_to_back`：验证三级流水在连续 `valid_i` 输入下仍能按顺序输出 `FP32` 累加结果
  - `vectors/matmul_4x16x64_smoke/`：`M=4`、`N=16`、`K=64`，验证单 tile、`K_BLOCKS=2`
  - `vectors/matmul_3x18x64_nonfinite/`：`M=3`、`N=18`、`K=64`，验证 mixed finite / `inf` / `NaN` 输出与尾 tile 并存的矩阵级语义
  - `vectors/matmul_6x33x160_nonfinite/`：`M=6`、`N=33`、`K=160`，验证三列 tile、末 tile 只剩 1 个有效 lane、`K_BLOCKS=5` 与 mixed finite / `inf` / `NaN` 并存
  - `vectors/matmul_7x49x224_sparse_nonfinite/`：`M=7`、`N=49`、`K=224`，验证四列 tile、末 tile 只剩 1 个有效 lane、`K_BLOCKS=7`，并在有限值底座上稀疏注入 `1` 个 A-side scale NaN、`4` 个 B-side scale NaN 与 `10` 个 B-side element NaN
  - `vectors/matmul_5x20x96_tail/`：`M=5`、`N=20`、`K=96`，验证奇数行、`K_BLOCKS=3` 与尾 tile 只激活前 4 列
  - `vectors/matmul_8x32x128_smoke/`：`M=8`、`N=32`、`K=128`，验证双 tile、`K_BLOCKS=4`
  - `vectors/matmul_9x65x192_five_tiles/`：`M=9`、`N=65`、`K=192`，验证五列 tile、末 tile 只剩 1 个有效 lane、`K_BLOCKS=6` 与更大的 finite-only 组合
- `tb_mx_array_dataset` 现已改成 burst 驱动：同一个 tile 的 `K_BLOCKS` 连续每拍送入阵列，不再插入空拍，再在一整串 `valid_o` 输出结束后核对最终 tile 结果；若最后一个 tile 不满 `16` 列，则用零 block/零贡献 scale 填充未使用 lane，并根据当前行是否带 `NaN` 来建模 padded lane 期望值：有限值行保持 `FP32 zero`，含 `NaN` 的行允许 padded lane 落成 `QNaN`。同时，testbench 还会显式检查 `valid_o` 必须整向量同时拉高/拉低，避免某几列先出结果时被代表性 lane 掩盖。
- `tools/mx_ref.py --emit-matmul-dataset` 已支持 `--finite-only` 与 `--elem-nan-stride` / `--scale-nan-stride`，可以在有限值底座上稳定生成 sparse mixed-nonfinite 数据集；导出的 `NaN` 仍统一规范化为 canonical `0x7fc00000`，便于让软件黄金模型与 RTL 的 `QNaN` 语义保持一致。
- `sim/run_matmul_stats.ps1` 默认会生成 `reports/matmul_stats_4096x4096x4096.json`，用于快速查看大矩阵抽样误差摘要。
- `sim/run_matmul_stats_sweep.ps1` 会额外生成 `reports/matmul_stats_4096x4096x4096_seed*.json` 与 `reports/matmul_stats_4096x4096x4096_sweep.json`，用于比较多组 seed 下的误差波动；脚本现已兼容 `-Seeds 1,2,3` 这类逗号分隔写法。
- `sim/run_matmul_stats_profiles.ps1` 会在此基础上继续生成 baseline `[-8,8]`、`finite_exp32` `[-32,32]`、`finite_exp64` `[-64,64]` 与 `sparse_nonfinite` 四档 profile 摘要，并把 finite 误差统计与 nonfinite mismatch 计数分开写入 JSON。

## 5. 当前固定数据集回归结论
本轮默认 Verilog 回归对七组固定数据集均已通过：

- `4x16x64`：用于快速确认基础 tile 驱动与两段 block 累加
- `3x18x64 nonfinite`：用于确认 mixed finite / `inf` / `NaN` 输出，以及尾 tile padded lane 在非有限值行上的期望语义
- `6x33x160 nonfinite`：用于确认三列 tile、单 lane 尾 tile、`K=160` 五段 block 累加与 mixed nonfinite 语义同时成立，并反向锁定 canonical `QNaN` 导出语义
- `7x49x224 sparse nonfinite`：用于确认四列 tile、单 lane 尾 tile、`K=224` 七段 block 累加，以及 sparse scale-NaN / element-NaN 在大多数输出仍保持 finite 时的传播语义；当前数据集为 `222` 个 finite、`121` 个 `NaN`、`0` 个 `inf`
- `5x20x96`：用于确认尾 tile 零填充、奇数行循环与 `K=96` 三段 block 累加
- `8x32x128`：用于确认更长 `K`、双 tile 读数和流水 `valid_o` 时序
- `9x65x192 finite-only`：用于确认更大的 `M,N,K` 组合、五列 tile、单 lane 尾 tile 与 `K=192` 六段 block 累加
- `tb_llmt_col_back_to_back`：用于确认三级流水具备连续每拍输入、连续每拍输出的基本吞吐能力
- `tb_mx_array_dataset` burst 模式：用于确认阵列级矩阵回归在整 tile、尾 tile、多 tile（当前已到 5 个列 tile）、finite-only、dense mixed nonfinite 与 sparse mixed nonfinite 场景下都能在连续每拍输入时保持最终结果正确，并要求 `valid_o` 只能整向量同步变化

这意味着当前列核虽然仍是保守版三级流水，但已经能在更贴近矩阵级场景的固定数据集上稳定跑通。
同时，`llmt_col` 的前端边界已经从“当拍完成全部 `dot32` 合并”收敛到“先寄存 partial sums、再在下一段做 final merge”，为后续继续推进更深的 reduction / scheduling 微架构留出了更清晰的结构基础。

## 6. 当前 `4096x4096` 抽样结果
以 `seed = 20260423`、`samples = 2048`、有限值输入为例，当前参考实现得到：

- `finite_count = 2048`，`nan_count = 0`，`inf_count = 0`
- `mean_rel_error = 3.90e-7`
- `max_rel_error = 7.92e-5`
- `mean_abs_error = 341.06`
- `max_abs_error = 6442.18`

这些数字说明：当前“每个 block 做 dot32，再做 FP32 累加”的参考数值路径，相对未逐步舍入的理想双精度累加，误差量级已经比较可控，后续可以把重点转向竞赛版微架构与更系统的验证覆盖。

为了避免只盯住一份单点报告，本轮还新增了 3 组 seed 的 finite-only sweep（`20260423`、`20260503`、`20260504`）：

- `mean_of_mean_abs_error = 341.72`
- `mean_of_mean_rel_error = 4.81e-7`
- `max_of_max_abs_error = 6442.18`
- `max_of_max_rel_error = 6.59e-4`，worst seed 为 `20260503`

这说明平均误差量级在多 seed 下仍然稳定，但最坏相对误差会比单份报告更高一些，后续如果继续扩大 exponent 范围或引入 mixed nonfinite sweep，需要继续跟踪这个 worst-case 尾部。

在此基础上，本轮又把统计扩展成三档 exponent profile：

- baseline `[-8,8]`：`6144` 个样本全部保持 finite，`mean_of_mean_rel_error = 4.81e-7`，`max_of_max_rel_error = 6.59e-4`
- `finite_exp32` `[-32,32]`：`6144` 个样本仍全部 finite，`mean_of_mean_rel_error = 8.88e-8`，`max_of_max_rel_error = 1.16e-5`；说明指数范围放宽后，绝对误差显著增大，但 finite 子集上的相对误差仍维持在可读量级
- `finite_exp64` `[-64,64]`：`6144` 个样本里只剩 `2484` 个 finite，同时出现 `2928` 个 `inf`、`732` 个 `NaN` 和 `3660` 个 nonfinite mismatch；例如 `seed=20260423` 的第一处 mismatch 就是 `row=0,col=0` 上 `project_value=-inf`、`ideal_value≈-8.87e40`

这组 profile 结果说明：一旦把 `E8M0` 指数范围放宽到 `[-64,64]`，当前“每个 block 先转 `FP32` 再逐 block 累加”的数值路径会比理想双精度累加更早进入 overflow / invalid 区间。新的统计脚本会把这类样本单独计数，因此即使 sweep 中混入大量 nonfinite 输出，有限值子集上的均值/极值误差仍然可以单独解读。

为了避免高密度随机 `NaN` 把 `4096x4096x4096` 统计迅速打成“几乎全 nonfinite”，本轮额外补了一份 sparse mixed-nonfinite spot-check：`reports/matmul_stats_4096x4096x4096_sparse_nonfinite.json` 使用 `seed=20260423`、`samples=2048`、`elem_nan_stride=524288`、`scale_nan_stride=262144`，得到 `2004` 个 finite、`44` 个 `NaN`、`0` 个 `inf`，且 `matched_nonfinite_count = 44`、`mismatched_nonfinite_count = 0`。这说明在只注入少量异常块时，当前 RTL / 参考模型的非有限值传播语义是对齐的，同时 finite 子集上的 `mean_rel_error ≈ 3.91e-7`、`max_rel_error ≈ 7.92e-5` 也基本保持在 baseline 同一量级。

## 7. 报告后续章节规划
- MXFP8 格式与数值语义
- 总体架构与数据流
- `LLMT` 微架构与流水线划分
- 阵列接口与调度方式
- 验证方法与误差分析
- 综合、时序、面积、功耗评估
- 优化方向与决赛延展
