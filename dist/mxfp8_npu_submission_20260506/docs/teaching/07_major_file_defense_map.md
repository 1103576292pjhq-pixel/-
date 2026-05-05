# 代码讲解 07：主要文件答辩复述地图

这篇不是逐行注释，而是给零基础读者和答辩准备者一张“问到哪个文件就怎么讲”的地图。真正按源码行号展开的教材放在 `docs/line_by_line/`；本篇只负责快速定位、复述和答辩口径。

## RTL 文件

| 文件 | 目的 | 端口/信号重点 | 组合逻辑 | 时序逻辑 | 为什么存在 | 答辩复述 |
| --- | --- | --- | --- | --- | --- | --- |
| `rtl/mx_defs.vh` | 定义全局规模和常量 | `MX_BLOCK_K=32`、`MX_COLS=16`、元素/乘积/dot 位宽、FP32 常量 | 无 | 无 | 避免每个 RTL 重复写位宽 | “它是全项目的尺寸表，决定 block 长度、阵列列数和内部定点位宽。” |
| `rtl/mx_funcs.vh` | 提供 E4M3/E8M0 helper function | `e4m3_to_fixed`、`e4m3_is_nan`、`e8m0_unbiased_exp` | function 内组合计算 | 无 | 把格式解析从主流水中拆出来 | “它把 MXFP8 的元素和 scale 解释成 RTL 可用的 fixed 值和 exponent。” |
| `rtl/e4m3_decode.v` | 单元素 E4M3 解码模块 | `elem_i`、zero/subnormal/nan/fixed 输出 | 解码 sign/exponent/mantissa | 无 | 便于单独复用和教学展示 | “它回答一个 8 bit E4M3 元素是不是特殊值，以及对应 fixed 表示是什么。” |
| `rtl/e8m0_scale_decode.v` | E8M0 scale 解码模块 | `scale_i`、`is_nan_o`、`unbiased_exp_o` | scale 特殊值判断和指数转换 | 无 | 明确 block scale 语义 | “它把共享 scale 变成指数偏移，同时标记 scale NaN。” |
| `rtl/fixed_to_fp32.v` | dot32 fixed 结果转 FP32 | `value_i`、`exp_shift_i`、`nan_i`、`fp32_o` | 找最高有效位、规格化、舍入、拼字段 | 无 | dot32 内部是 fixed，输出累加要用 FP32 | “它把一次 dot32 的定点和按 scale 对齐后转换成 IEEE FP32 bit pattern。” |
| `rtl/fp32_add_rne.v` | FP32 accumulator 加法 | `a_i`、`b_i`、`sum_o` | 特殊值、对阶、加减、规格化、RNE | 无 | 实现列内 FP32 累加语义 | “它负责把新 dot32 FP32 加到历史 accumulator，并使用 round-to-nearest-even。” |
| `rtl/llmt_col.v` | 单列 dot32 + accumulator | `valid_i`、`acc_clear_i`、A/B block、scale、`valid_o`、`acc_o` | 32 lane fixed 乘加、4 组 partial sums、scale exponent | 三级流水寄存、valid/acc_clear 延迟、acc 写回 | 是阵列的基本列单元 | “它每拍接收一个 MXFP8 A/B block，做 dot32，再转 FP32 并累加；`valid_o` 表示流水线输出对齐完成。” |
| `rtl/mx_array_32x16.v` | 16 列顶层阵列 | A block 广播、16 个 B block、16 个 accumulator 输出 | generate 切片和连线 | 无新增状态 | 把 16 个列单元并排 | “顶层不改数值语义，只把同一个 A block 广播给 16 列，每列使用自己的 B block 和清零控制。” |

## Testbench 文件

| 文件 | 目的 | 关键输入/信号 | 检查点 | 为什么存在 | 答辩复述 |
| --- | --- | --- | --- | --- | --- |
| `tb/tb_llmt_col_smoke.v` | 最小列级通路 | 32 个 E4M3 1.0、scale 1.0 | 第一次输出 32，第二次累计 64 | 快速证明基本 dot32/accumulator 路径 | “它用 32 个 1 乘 1 手算出 32，再不清 accumulator 得到 64。” |
| `tb/tb_llmt_col_back_to_back.v` | 连续输入吞吐 | 连续三拍 `valid_i` | 输出按 32、64、96 顺序返回 | 防止流水线只能处理稀疏输入 | “它证明列单元在连续 valid 下不丢拍、不乱序。” |
| `tb/tb_llmt_col_corner.v` | 数值边界 | zero、符号、NaN/Inf、scale 边界 | 特殊值和 corner 输出 | 锁住 MXFP8/FP32 语义 | “它守住异常值和边界条件，不让 smoke 掩盖数值问题。” |
| `tb/tb_mx_array_smoke.v` | 最小阵列通路 | A 广播、16 列 B 全 1 | 所有列输出 32，再累计 64 | 证明顶层切片和列实例连接正确 | “它把单列 smoke 扩到 16 列，确认每列输出一致且顶层连线正确。” |
| `tb/tb_mx_array_dataset.v` | 矩阵级固定向量回归 | manifest、A/B hex、expected Y、M/N/K | tile、tail tile、nonfinite、valid 同步 | 证明阵列调度而不只是单列计算 | “它按固定向量驱动真实矩阵尺寸，逐 tile 比对输出，并检查 padding lane 和异常值传播。” |

## Python 与脚本

| 文件 | 目的 | 输入/输出 | 关键逻辑 | 答辩复述 |
| --- | --- | --- | --- | --- |
| `tools/mx_ref.py` | golden model、向量生成、4096 统计 | 输入 profile/seed/尺寸；输出 hex、JSON | E4M3/E8M0 解释、dot32、FP32 bit、nonfinite 分类 | “它是独立于 RTL 的参考模型，用于生成固定向量和统计误差。” |
| `sim/run_iverilog.ps1` | 默认 Verilog 回归 | 编译 RTL + testbench；输出 `.vvp` 和日志 | 逐个运行列级、阵列级、dataset case | “它是一键可复验入口，证明 RTL 默认回归 PASS。” |
| `sim/run_waveform_smoke.ps1` | 小波形证据生成 | `-DDUMP_VCD` 编译三个 smoke case；输出 VCD 和日志 | 只在 opt-in 宏下打开 `$dumpfile/$dumpvars` | “它不改变默认回归，只为答辩展示生成小 VCD。” |
| `sim/run_python_ref.ps1` | Python 自检/向量生成 | 运行 `mx_ref.py` | 检查 golden model 基础语义 | “它证明参考模型可运行，并刷新基础向量。” |
| `sim/run_matmul_stats*.ps1` | 4096 抽样统计 | profile、seed、样本配置；输出 JSON/log | finite 误差和 nonfinite 分类 | “它用于证明大矩阵抽样误差趋势，而不是替代 RTL 回归。” |

## 复述顺序建议

答辩时不要从 `fp32_add_rne.v` 的细节开始。建议顺序：

1. 先讲 `mx_defs.vh` 定义规模。
2. 再讲 `mx_funcs.vh` 和 decode 文件解释 MXFP8。
3. 然后讲 `llmt_col.v` 完成 dot32 与累加。
4. 再讲 `mx_array_32x16.v` 复制 16 列。
5. 最后用 testbench、Python 和脚本证明结果可复验。

## 常见被问问题

- 为什么不用 SystemVerilog？答：当前交付要求保持纯 Verilog，所有新增 testbench dumping 也使用 Verilog-2001 兼容写法。
- 为什么没有真实 28nm PPA？答：当前是前端 RTL handoff，真实 PPA 需要后端库、corner、约束、工具和原始日志。
- 为什么 VCD 不是默认生成？答：默认回归应快速、稳定、少文件；波形是 opt-in 展示证据。
- 为什么 Python golden model 可信？答：它独立实现 MXFP8 语义并生成固定向量，RTL 只读取和比对这些向量，避免 testbench 随机性。
