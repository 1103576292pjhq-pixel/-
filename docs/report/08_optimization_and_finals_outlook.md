# 08 优化方向与决赛延展

## 1. 当前基线判断

当前仓库已经具备初赛 handoff 基线：

- 纯 Verilog RTL 可复验。
- 矩阵级 dataset 覆盖 tail tile、多 tile、mixed nonfinite 和 sparse nonfinite。
- 4096 抽样统计已形成 baseline、finite_exp32、finite_exp64、sparse_nonfinite 四档 profile。
- 技术报告、证据包和教学资料已经形成主线。

但它还不是最终 PPA 最优版本。下一阶段优化应由真实综合/PPA 报告、主办方补充规则或指定 benchmark 驱动。

## 2. RTL 微架构优化

| 方向 | 价值 | 前置条件 |
| --- | --- | --- |
| 继续拆分 `llmt_col` reduction tree | 提升频率潜力 | 综合报告显示 S1/S2 reduction 是关键路径 |
| FP32 accumulator pipeline | 缓解 FP32 add 时序 | 允许增加 latency，并更新 testbench |
| 异常 flag 外显 | 提升可解释性 | 赛题要求 IEEE exception 或答辩需要 |
| 参数化列数/K block | 提升复用性 | 不影响初赛固定规格交付 |

当前不建议在没有时序证据的情况下继续改 RTL，因为会扩大验证面并引入报告不稳定性。

## 3. 验证优化

后续可以补：

- VCD/波形截图自动生成开关。
- 更多随机矩阵数据集和 seed sweep。
- 针对 low-magnitude output 的 worst-case 相对误差案例。
- 若工具可用，补覆盖率统计。
- 若后端网表可用，补门级仿真和 SDF 回标。

## 4. 精度分析优化

当前 JSON 已经足够支撑趋势判断，但报告展示还可以增强：

- 把 profile sweep 转成表格和图。
- 单独解释 finite_exp64 的 dynamic range boundary。
- 展示 sparse nonfinite 的 matched NaN 案例。
- 如果主办方提供 benchmark，新增 benchmark-specific profile。

## 5. 后端/PPA 优化

真实后端阶段应补：

1. 指定 28nm 标准单元库和 corner。
2. 运行综合并归档 timing/area/power。
3. 根据最差路径决定是否继续拆流水。
4. 使用 VCD/SAIF 做功耗估计。
5. 对比不同微架构版本的 PPA，而不是只给单点数字。

## 6. 教学与答辩优化

答辩材料建议准备三条线：

- 设计线：为什么是 `32 x 16`、output-stationary、dot32 + FP32 accumulator。
- 验证线：日志、向量、4096 抽样和 nonfinite 覆盖。
- 边界线：哪些是已完成，哪些阻塞于真实 28nm 库和主办方模板。

## 7. 决赛延展建议

如果进入决赛，优先级建议：

1. 拿到真实后端约束后跑第一次综合，找关键路径。
2. 根据关键路径改 `llmt_col`，每次改动都跑完整回归。
3. 把 profile sweep 和 benchmark 结合，避免只优化随机样本。
4. 形成 RTL 版本与 PPA/精度/验证的对照表。

## 8. 结论

当前仓库适合作为初赛提交包和决赛优化起点。后续优化不应盲目堆功能，而应围绕真实时序、真实面积功耗、指定 benchmark 和答辩证据展开。
