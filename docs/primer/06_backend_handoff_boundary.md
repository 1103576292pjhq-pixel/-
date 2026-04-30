# 06 后端交付边界：前端能给什么，不能声称什么

## 先分清前端和后端

前端 RTL 交付主要回答：

```text
电路逻辑是什么？
接口是什么？
仿真是否对？
哪些约束和模板可供后端继续使用？
```

后端实现还要回答：

```text
用哪套 28nm 标准单元库？
目标频率是多少？
真实面积、功耗、时序是多少？
版图、DRC、LVS、signoff 是否通过？
```

当前仓库属于前端 RTL handoff 包，不是完整 28nm 后端结果包。

## 可以交给后端的内容

- `rtl/`：纯 Verilog RTL，顶层是 `mx_array_32x16`。
- `tb/`、`sim/`、`vectors/`：仿真和固定向量。
- `tools/mx_ref.py`：Python golden model 和统计工具。
- `constraints/`、`synth/`：约束和综合脚本模板。
- `docs/report/`、`reports/`：报告、验证日志、精度统计和证据索引。

## 后端必须补齐的内容

- 真实 28nm `.lib/.db` 标准单元库。
- 工艺 corner、RC corner、时钟不确定度、IO 约束。
- 综合、STA、功耗分析、门级仿真日志。
- 真实 workload 或活动率文件。
- 面积、功耗、频率、WNS/TNS 等原始工具输出。

## 禁止声称

在没有真实后端工具日志前，不能写：

- “已完成 28nm PPA signoff”。
- “面积为某个真实平方微米数”。
- “功耗为某个真实 mW 数”。
- “频率已达到某个真实 MHz/GHz”。

可以写：

- “提供了后端 handoff 模板”。
- “真实 PPA 阻塞于外部库和工具”。
- “当前 RTL 回归和 Python golden model 已归档”。

## 常见错误

- 把 generic synthesis 或模板脚本说成真实 28nm 结果。
- 把 `.codexpotter`、`.omx`、`work/`、临时日志放进正式提交包。
- 只交 RTL，不交验证证据和使用说明，导致后端无法复验。

## 自测题

1. 顶层模块名是什么？
2. 为什么 `constraints/` 和 `synth/` 只能叫模板？
3. 官方提交包里为什么不应该包含 `.codexpotter`？

## 用自己的话复述

“当前项目能交付前端 RTL、testbench、golden model、向量、报告和后端模板。真实 28nm 面积、功耗、频率、时序必须由后端在真实库和工具上跑完后才能声明。”
