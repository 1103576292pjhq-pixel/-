# 代码讲解 03：mx_array_32x16 顶层怎么连

## 1. 文件位置

目标文件：`rtl/mx_array_32x16.v`

这个文件不做复杂运算，它的职责是把 16 个 `llmt_col` 并排连成阵列。

## 2. 输入输出

| 信号 | 含义 |
| --- | --- |
| `valid_i` | 本拍所有列输入有效 |
| `acc_clear_i[15:0]` | 每列独立清 accumulator |
| `a_elems_i/a_scale_i` | 广播给 16 列的 A block |
| `b_elems_i/b_scale_i` | 打包在一起的 16 个 B block |
| `valid_o[15:0]` | 每列输出有效 |
| `acc_o` | 16 个 FP32 输出打包 |

## 3. 关键 generate

代码使用：

```verilog
for (col = 0; col < `MX_COLS; col = col + 1)
```

每次循环实例化一个 `llmt_col`。第 `col` 列从打包输入中切出自己的 B block：

```verilog
b_elems_i[(col*`MX_BLOCK_K*`MX_ELEM_W) +: (`MX_BLOCK_K*`MX_ELEM_W)]
b_scale_i[(col*8) +: 8]
```

这里的 `+:` 是 Verilog part-select 写法，意思是“从起点开始取固定宽度”。

## 4. 为什么 A 广播、B 分列

矩阵乘中，同一个 A row block 会和多个 B column block 相乘：

```text
A row block * B col0 -> Y col0
A row block * B col1 -> Y col1
...
A row block * B col15 -> Y col15
```

所以 A 只需要一份，B 需要 16 份。

## 5. 读代码时看什么

读这个文件时重点看三件事：

1. `MX_COLS` 控制列数，目前是 16。
2. B 输入和输出 accumulator 都是按列打包。
3. 顶层不改变 `llmt_col` 的计算语义，只负责复制和连线。

## 6. 自测题

1. 如果 `MX_COLS` 从 16 改成 8，哪些总线宽度会跟着变？
2. 为什么 `a_elems_i` 不按列切片？
3. `valid_o` 为什么是 16 bit，而不是 1 bit？
