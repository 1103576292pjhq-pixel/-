# FP32 辅助模块和列级 testbench 讲解

这篇补齐 `fixed_to_fp32`、`fp32_add_rne` 和列级 testbench。读完后，零基础队友应该能解释：dot32 的固定点结果怎样变成 FP32、FP32 累加为什么单独成模块、列级测试为什么要分 smoke、corner 和 back-to-back。

## 1. `rtl/fixed_to_fp32.v`

`fixed_to_fp32` 的任务是把 dot32 归约后的有符号固定点数转换成 IEEE-754 单精度格式。它不负责做矩阵调度，也不负责累加历史输出，只处理“一次 dot32 的结果”。

阅读时按三个问题看：

1. 输入是不是 0。
2. 符号位是什么。
3. 最高有效位在哪里。

固定点转 FP32 的关键是规格化。模块先找到绝对值中的最高有效 1，再根据这个位置生成 exponent，并把剩余有效位放进 mantissa。这样硬件输出就能进入后面的 FP32 累加路径。

常见误区：

- 不要把它理解成“除以一个小数”。RTL 中主要是在做移位、找最高位和拼 FP32 字段。
- 它只把当前 dot32 结果格式化，不知道矩阵的 M、N、K。
- 如果后端综合发现这里是关键路径，优化方向通常是分段 priority encoder 或加流水，而不是改数值语义。

## 2. `rtl/fp32_add_rne.v`

`fp32_add_rne` 负责把新的 FP32 dot32 结果加到历史累加值上。RNE 表示 round to nearest even，是常见的 IEEE 浮点舍入方式。

可以按下面流程理解：

1. 拆字段：取出 sign、exponent、mantissa。
2. 对阶：把指数小的数右移，让两个数的小数点对齐。
3. 加减：同号做加法，异号做减法。
4. 规格化：把结果重新调整成 FP32 的 exponent 和 mantissa。
5. 舍入：根据 guard、round、sticky 位做 nearest-even 判断。

这个模块是数值正确性的核心之一。测试时不能只看普通有限数，还要看 Inf、NaN、正负号和接近 0 的情况，因为这些最容易暴露舍入和特殊值传播问题。

当前 RTL 已支持 FP32 subnormal 输出。`fixed_to_fp32` 会在 dot32 结果低于 normal FP32 下界时生成 subnormal mantissa；`fp32_add_rne` 也会在累加结果进入 subnormal 区间时继续按 nearest-even 舍入。`tb_llmt_col_corner` 中新增了最小 FP32 subnormal dot 和两个最小 subnormal 累加的 directed case。

## 3. `tb/tb_llmt_col_smoke.v`

smoke test 是最低成本的“能不能跑通”测试。它通常只覆盖少量固定输入，目的不是证明所有边界都正确，而是快速确认：

- `valid_i` 能触发计算。
- `valid_o` 能在预期流水延迟后出现。
- 输出 FP32 与 golden 值匹配。
- reset 后状态没有残留。

如果 smoke 失败，优先检查接口连接、时钟/reset、include 路径和基础数据格式，不要一开始就怀疑复杂矩阵调度。

## 4. `tb/tb_llmt_col_corner.v`

corner test 专门看边界值。对 MXFP8 路径来说，重点包括：

- 0 和符号。
- 最大/最小有限值。
- Inf 和 NaN。
- scale 边界。
- 固定点归约后接近 FP32 舍入边界的值。

这类测试的价值是提前锁住数值语义。报告中提到非有限值传播、canonical QNaN 或动态范围边界时，需要能追到这类测试或 Python 参考模型。

## 5. `tb/tb_llmt_col_back_to_back.v`

back-to-back test 检查连续输入能力。三级流水的 `llmt_col` 不能只在“打一拍、停几拍”的场景下正确，还要在连续 `valid_i` 下保持输出顺序。

它主要回答三个问题：

- 连续两个输入会不会互相覆盖。
- `valid_o` 是否按流水节奏连续返回。
- 输出顺序是否和输入顺序一致。

这个测试对比赛项目很重要，因为阵列顶层会按 tile 连续喂列单元。如果列单元只能处理稀疏输入，矩阵吞吐就会被高估。

## 6. 和矩阵级回归的关系

列级 testbench 验证单个 `llmt_col` 的局部正确性；矩阵级 dataset testbench 验证多个列、多个 tile、tail padding 和累加调度。两者不能互相替代。

推荐排查顺序：

1. `tb_llmt_col_smoke` 失败：先看基础接口和单次 dot32。
2. `tb_llmt_col_corner` 失败：先看特殊值、舍入、decode 或 FP32 helper。
3. `tb_llmt_col_back_to_back` 失败：先看流水 valid 和寄存器推进。
4. 只有矩阵 dataset 失败：先看 tile 调度、padding、manifest 和 expected hex。

## 7. 一句话复述

`fixed_to_fp32` 把一次 dot32 固定点结果包装成 FP32，`fp32_add_rne` 把它按 IEEE 舍入规则累加进输出，三个列级 testbench 分别守住“能跑通、边界正确、连续输入不乱序”。
