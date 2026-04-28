# 关键用例清单

## 列级用例

| 用例 | 文件 | 目的 |
| --- | --- | --- |
| LLMT smoke | `tb/tb_llmt_col_smoke.v` | 基本 dot32 到 FP32 accumulator 路径 |
| LLMT corner | `tb/tb_llmt_col_corner.v` | corner 输入和 accumulator 行为 |
| LLMT back-to-back | `tb/tb_llmt_col_back_to_back.v` | 连续 `valid_i` 输入，验证流水吞吐和顺序 |

## 阵列级与矩阵级用例

| 用例 | 向量目录 | 覆盖点 |
| --- | --- | --- |
| 4x16x64 smoke | `vectors/matmul_4x16x64_smoke` | 单列 tile、有限值基线 |
| 5x20x96 tail | `vectors/matmul_5x20x96_tail` | 尾 tile、padding lane、K_BLOCKS=3 |
| 8x32x128 smoke | `vectors/matmul_8x32x128_smoke` | 双列 tile、有限值矩阵 |
| 9x65x192 five tiles | `vectors/matmul_9x65x192_five_tiles` | 5 个列 tile、单 lane 尾 tile、K_BLOCKS=6 |
| 3x18x64 nonfinite | `vectors/matmul_3x18x64_nonfinite` | mixed finite/Inf/NaN、尾 tile |
| 6x33x160 nonfinite | `vectors/matmul_6x33x160_nonfinite` | 三列 tile、K_BLOCKS=5、mixed nonfinite |
| 7x49x224 sparse nonfinite | `vectors/matmul_7x49x224_sparse_nonfinite` | sparse element/scale NaN、四列 tile、K_BLOCKS=7 |

## 评审推荐展示

若只能挑少量 case 展示，建议选择：

1. `tb_llmt_col_back_to_back`：证明列级流水不是单次脉冲 demo。
2. `matmul_5x20x96_tail`：证明尾 tile 和 padding lane。
3. `matmul_9x65x192_five_tiles`：证明多列 tile 调度。
4. `matmul_7x49x224_sparse_nonfinite`：证明 sparse nonfinite 传播。
