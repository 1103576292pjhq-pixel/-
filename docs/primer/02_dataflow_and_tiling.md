# NPU 背景教程 02：数据流、tile 与阵列为什么这样组织

## 1. 先从矩阵乘公式开始

矩阵乘的核心公式是：

```text
Y[i][j] = A[i][0] * B[0][j]
        + A[i][1] * B[1][j]
        + ...
        + A[i][K-1] * B[K-1][j]
```

对固定的 `i` 和 `j`，这就是一个长度为 K 的点积。本项目把 K 每 32 个元素切成一个 block，所以一次列级计算叫 `dot32`。

## 2. 为什么是 32 x 16

可以把 `32 x 16` 理解成：

- `32`：一次点积吃 32 个 K 方向元素。
- `16`：同一拍并行算 16 个输出列。

也就是说，同一个 A block 会广播给 16 列 B block：

```text
            B col0   B col1   ...   B col15
              |        |              |
A block ---> dot32   dot32    ...   dot32
              |        |              |
           acc[0]   acc[1]          acc[15]
```

这就是 `mx_array_32x16` 顶层的组织方式。

## 3. 什么是 output-stationary

`stationary` 的意思是“某类数据尽量停在本地不动”。本项目使用 output-stationary：

- 输入 A/B block 持续流过阵列。
- 每一列的输出累加值留在本列 accumulator 中。
- K 方向所有 block 处理完后，accumulator 就是最终输出。

这样做的好处是：输出不需要每个 K block 都写回外部存储，可以减少输出搬运。

## 4. 为什么要切 tile

阵列一次只能输出 16 列，但真实矩阵的 N 可能远大于 16。例如 N=65：

```text
tile0: col  0..15
tile1: col 16..31
tile2: col 32..47
tile3: col 48..63
tile4: col 64..64  + 15 个 padding lane
```

所以 `9x65x192` 这个回归用例很重要：它证明设计能处理 5 个列 tile，最后一个 tile 只有 1 个真实列。

## 5. 尾 tile 怎么验证

尾 tile 的原则是：

- 真实列照常比对 expected output。
- 超出 N 的 padding lane 不应该残留旧值。
- 如果输入中有 NaN，padding lane 的语义要和 golden model 一致。

`tb/tb_mx_array_dataset.v` 会检查 `valid_o` 在所有列保持一致，并按 manifest 中的 M/N/K 信息逐行逐 tile 比对。

## 6. 一周复述要点

你需要能讲清楚：

1. `32` 是 K block 长度，不是阵列行数。
2. `16` 是并行输出列数。
3. A block 广播，B block 每列不同。
4. output-stationary 表示输出 accumulator 留在列内。
5. tile 是为了处理任意 N，tail tile 是为了处理 N 不整除 16。
