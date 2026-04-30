# 05 验证与误差指标：怎么证明它不是只会跑 smoke

## 为什么不能只看一个 PASS

`tb_llmt_col_smoke.v` 能证明“32 个 1 乘 1 可以得到 32，再累加得到 64”。但比赛交付还要证明：

- 连续输入不会丢拍。
- 16 列阵列连线没有错。
- tail tile 不残留旧结果。
- NaN/Inf 传播类别正确。
- 4096 规模抽样误差可解释。

## 验证层级

| 层级 | 代表文件 | 证明什么 |
| --- | --- | --- |
| 列级 smoke | `tb/tb_llmt_col_smoke.v` | dot32 和 accumulator 基本路径 |
| 连续输入 | `tb/tb_llmt_col_back_to_back.v` | valid 连续输入和输出顺序 |
| corner | `tb/tb_llmt_col_corner.v` | 零、符号、异常边界 |
| 阵列 smoke | `tb/tb_mx_array_smoke.v` | 16 列顶层连接 |
| dataset | `tb/tb_mx_array_dataset*.v` | 矩阵 tile、tail tile、nonfinite |
| Python | `tools/mx_ref.py` | golden model、向量、统计 |
| 波形 | `sim/run_waveform_smoke.ps1` | valid/accumulator 时序展示 |

## 日志、VCD、JSON 各有什么用

- `reports/verification/iverilog_default.log`：证明默认 Verilog 回归 PASS。
- `reports/evidence/waveforms/*.vcd`：用于打开波形，观察 valid、acc_clear、acc_o 的时序关系。
- `reports/precision/*.json`：保存 4096 抽样的误差统计。

它们不是互相替代的关系。日志证明脚本跑过，VCD 方便答辩展示，JSON 证明统计结果可追溯。

## 误差指标怎么讲

finite 输出可以讲：

```text
absolute error = |project - ideal|
relative error = |project - ideal| / |ideal|
```

如果 ideal 很接近 0，relative error 可能被放大，所以报告要同时看 absolute 和 relative。

NaN/Inf 不适合算普通误差，要看类别：

```text
project NaN, ideal NaN -> matched nonfinite
project finite, ideal NaN -> mismatched nonfinite
```

## 常见错误

- 只把 VCD 当成正确性证据。VCD 是展示材料，核心仍是可复验日志和固定向量。
- 只报告 mean error，不报告 max error 和 nonfinite mismatch。
- 把 profile sweep 中的动态范围边界误解成默认 RTL 回归失败。

## 自测题

1. back-to-back test 比 smoke 多证明什么？
2. tail tile 为什么必须测？
3. NaN 输出为什么不能用 relative error 评价？

## 用自己的话复述

“这个仓库用分层验证证明设计：列级看 dot32 和流水，阵列级看 16 列连线，dataset 看矩阵 tile 和异常值，4096 JSON 看统计趋势，VCD 用来展示关键时序。finite 和 nonfinite 要分开评价。”
