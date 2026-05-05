# 00 一周学习路线：从零读懂这个 MXFP8 NPU

## 先看一个具体目标

这套设计要做的事情可以先说成一句话：

```text
把 A 矩阵和 B 矩阵相乘，输出 FP32 的 Y 矩阵。
```

和软件不同，硬件不能只写一个 `for` 循环就结束。硬件要决定：数据怎么表示、一次算多少个乘加、什么时候输入有效、什么时候输出有效、怎么证明结果可信、最后怎么交给后端继续做综合和版图。

## 一周安排

| 天数 | 目标 | 必读文件 | 当天验收 |
| --- | --- | --- | --- |
| Day 1 | 知道 NPU、MAC、矩阵乘是什么 | `01_npu_basics.md` | 能手算一个 2x2 矩阵乘 |
| Day 2 | 知道 `32x16` 和 tile 是什么 | `02_dataflow_and_tiling.md` | 能解释 `N=20` 为什么有 tail tile |
| Day 3 | 知道 MXFP8 数据怎么变成 dot32 | `03_mxfp8_numeric_path.md` | 能说清 E4M3 和 E8M0 分工 |
| Day 4 | 能读最小 Verilog 语法 | `04_verilog_survival_guide.md` | 能看懂 module、端口、位切片、always |
| Day 5 | 能读列单元和阵列顶层 | `docs/teaching/01_llmt_col_pipeline.md`、`03_mx_array_top.md` | 能复述 valid/reset/acc_clear 的作用 |
| Day 6 | 能跑回归和看证据 | `05_verification_and_error_metrics.md` | 能指出 PASS 日志、VCD、4096 统计各证明什么 |
| Day 7 | 能讲交付边界 | `06_backend_handoff_boundary.md`、`docs/report/09_submission_checklist.md` | 能说哪些可以提交，哪些不能伪称完成 |

## 推荐学习方法

每一章按四步走：

1. 先看例子，不急着背名词。
2. 用纸笔手算一个很小的数值例子。
3. 回到 RTL 或 testbench 找对应信号。
4. 用自己的话复述，不照抄文档。

## 常见错误

- 直接打开 `rtl/llmt_col.v` 从第一行硬读，容易被位宽和流水线吓住。
- 把 `32x16` 误解成 32 行、16 列的完整 systolic array。
- 看到 `reports/synthesis/` 就以为已经有真实 28nm PPA。
- 只看 smoke PASS，就说矩阵级、异常值和 tail tile 全都没问题。

## 自测题

1. 为什么本项目需要先学矩阵乘，再学 Verilog？
2. 为什么验证材料要同时有日志、固定向量、统计 JSON 和波形？
3. 如果答辩老师问“面积是多少”，在没有真实 28nm 库时应该怎么答？

## 用自己的话复述

“我会先把它当作一个矩阵乘硬件来学：第一天理解 MAC，第二天理解数据流，第三天理解 MXFP8，第四天补 Verilog，第五天读 RTL，第六天看验证，第七天讲清前端交付和后端缺口。”
