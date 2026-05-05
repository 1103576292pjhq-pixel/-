# 02 Testbench 逐行讲解

本目录用于讲 `tb/*.v`。testbench 不进入综合，但它决定我们怎样证明 RTL 是对的。

## 阅读顺序

| 顺序 | 源文件 | 逐行讲解文件 | 状态 |
| --- | --- | --- | --- |
| 1 | `tb/tb_llmt_col_smoke.v` | `00_tb_llmt_col_smoke_v.md` | 待续写 |
| 2 | `tb/tb_llmt_col_back_to_back.v` | `01_tb_llmt_col_back_to_back_v.md` | 待续写 |
| 3 | `tb/tb_llmt_col_corner.v` | `02_tb_llmt_col_corner_v.md` | 待续写 |
| 4 | `tb/tb_mx_array_smoke.v` | `03_tb_mx_array_smoke_v.md` | 待续写 |
| 5 | `tb/tb_mx_array_dataset.v` | `04_tb_mx_array_dataset_v.md` | 待续写 |
| 6 | `tb/tb_mx_array_dataset_*` wrappers | `05_dataset_wrappers.md` | 待续写 |

## Testbench 先看什么

先看 `initial` 里怎么驱动输入，再看 task 怎么复用，再看检查点。不要先纠结 `$display` 或 `$fatal`，它们只是告诉仿真器成功还是失败。

最短复述：

```text
smoke test 证明最小路径能跑通。
corner test 证明边界值和异常值不乱。
back-to-back test 证明连续 valid 不丢拍。
array smoke 证明 16 列连接正确。
dataset test 证明矩阵级调度、tail tile 和 nonfinite case 可复验。
```
