# MXFP8 NPU 零基础教程总入口

本目录面向“只懂一点数字逻辑、还不熟 Verilog 和 NPU”的读者。学习顺序不是先背术语，而是先用小例子理解矩阵乘、乘加、数据流、MXFP8 数值路径，再回到本仓库的 RTL、testbench 和交付边界。

## 建议学习顺序

1. [00_learning_path.md](00_learning_path.md)：一周学习路线和每天验收口径。
2. [01_npu_basics.md](01_npu_basics.md)：从 CPU/GPU/NPU、MAC、矩阵乘和 PE 阵列开始。
3. [02_dataflow_and_tiling.md](02_dataflow_and_tiling.md)：解释 `32x16`、output-stationary、tile、tail tile。
4. [03_mxfp8_numeric_path.md](03_mxfp8_numeric_path.md)：解释 E4M3、E8M0、block scale、dot32、FP32 累加。
5. [04_verilog_survival_guide.md](04_verilog_survival_guide.md)：读懂本仓库 RTL 所需的最小 Verilog。
6. [05_verification_and_error_metrics.md](05_verification_and_error_metrics.md)：看懂 smoke、corner、dataset、4096 抽样和波形证据。
7. [06_backend_handoff_boundary.md](06_backend_handoff_boundary.md)：前端 RTL 能交付什么，后端还缺什么。
8. [07_how_to_read_this_repo.md](07_how_to_read_this_repo.md)：按目录和文件顺序阅读、运行、复述。

## 学完后要能复述

- 赛题目标是 `Y = A * B` 的 MXFP8 `32x16` 计算阵列，不是完整 SoC。
- `32` 是 K 方向 block 长度，`16` 是并行输出列数。
- 一个 A block 广播给 16 个列单元，每列拿不同的 B block，输出在列内 FP32 accumulator 中累加。
- MXFP8 是 32 个 E4M3 元素共享一个 E8M0 scale；本 RTL 先固定点 dot32，再转 FP32 累加。
- 当前交付是纯 Verilog RTL 前端包，真实 28nm 面积、功耗、频率和时序必须等真实后端库和工具。
