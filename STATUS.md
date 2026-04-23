# STATUS

- 当前批次：P2 `llmt_col` partial-sum 寄存化
- 本批已完成：`llmt_col` 现已把 Stage-1 收敛为“只寄存 `4x8` partial sums”，final merge 挪到下一段再进入 `fixed_to_fp32`；外部接口、`valid_o` 协议和默认 Verilog 回归结果保持不变；状态/报告/教学文档/本地 KB 已同步
- 下一步：继续扩大矩阵级极值/非有限值覆盖，并把 `LLMT` 推向更接近竞赛目标的 issue / reduction 微架构；工具环境允许时补综合/PPA实测
- 阻塞项：无；当前为交互会话内推进，未启动独立长期 runner
