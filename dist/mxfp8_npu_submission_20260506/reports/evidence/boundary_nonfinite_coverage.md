# 边界与非有限值覆盖

## 覆盖目标

本项目不只验证有限值 smoke case，还覆盖以下边界：

- 尾 tile：N 不是 16 的整数倍。
- 多列 tile：最多已覆盖 5 个列 tile。
- 连续输入：`valid_i` back-to-back。
- mixed nonfinite：输入或 scale 导致 Inf/NaN。
- sparse nonfinite：在有限值底座上稀疏注入 NaN。
- 动态范围边界：scale exponent 扩大到 `[-32, 32]` 和 `[-64, 64]`。

## 有限值覆盖

有限值矩阵数据集覆盖：

- `4x16x64`
- `5x20x96`
- `8x32x128`
- `9x65x192`

baseline 4096 sweep 覆盖 6144 个 finite samples，0 nonfinite mismatch。

## Tail tile 覆盖

`5x20x96`、`3x18x64_nonfinite`、`6x33x160_nonfinite`、`7x49x224_sparse_nonfinite`、`9x65x192_five_tiles` 都包含 N 非 16 对齐场景。testbench 会检查 inactive lane 的 padding 输出语义。

## Nonfinite 覆盖

固定向量覆盖：

- `3x18x64_nonfinite`
- `6x33x160_nonfinite`
- `7x49x224_sparse_nonfinite`

4096 profile 覆盖：

- sparse nonfinite 三 seed：6037 finite、107 matched NaN、0 mismatched nonfinite。
- finite_exp64：记录 projected FP32 与 ideal double accumulator 的 dynamic range category differences。

## 当前未覆盖

- 门级仿真后的 X 传播和 SDF 时序。
- 真实后端功耗波形窗口。
- 主办方指定 benchmark，如后续提供需新增独立证据。
