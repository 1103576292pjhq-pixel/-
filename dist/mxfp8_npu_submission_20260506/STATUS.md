# STATUS

- 当前阶段：2026-05-06 第一次比赛提交与后端 RTL handoff 包已收口为正式提交候选包。
- 本批已完成：已新增一键验收脚本、最终证据索引、边界 case 矩阵、综合环境检查、综合检查使用说明、最终提交 manifest、单入口提交报告、后端接收清单、确定性 RTL filelist、官方打包脚本和 `dist/mxfp8_npu_submission_20260506/` 正式提交候选包。
- 当前验收：`sim/run_submission_regression.ps1` release 口径已跑通；本轮 `sim/run_submission_regression.ps1 -Fast` 也已重新跑通，verdict 为 `PASS_WITH_EXTERNAL_SYNTH_BLOCKER`。
- 下一步：若拿到真实后端工具和 28nm 库，再补真实综合/PPA；若收到主办方模板或答辩规则，再按模板裁剪提交报告。
- 阻塞项：`BLOCKED_NO_SYNTH_TOOL`、`BLOCKED_NO_28NM_LIB`；主办方补充通知、提交模板和答辩规则仍未提供。因此不声明真实 28nm 面积、功耗、频率、时序、WNS/TNS、mapped netlist 或 signoff。

## 当前交付判断

- 交付物名称：`RTL handoff package`。
- RTL 基线：纯 Verilog RTL 存在，顶层为 `mx_array_32x16`，本批未改变顶层接口。
- 验证基线：`sim/run_iverilog.ps1`、`sim/run_python_ref.ps1`、`sim/run_waveform_smoke.ps1`、`sim/render_waveform_screenshots.ps1` 均已由提交验收脚本串联检查。
- 精度基线：4096 sampled profile JSON 和统计日志已由 release 口径重跑；fast 模式只作为后续快验收，不把旧证据伪装成新跑 release 统计。
- 证据基线：最终证据索引在 `reports/evidence/final_evidence_index_2026-05-06.md`，边界矩阵在 `reports/evidence/boundary_case_matrix.md`。
- PPA 基线：只具备 SDC、DC/Yosys 模板和环境检查；真实 PPA 等待后端工具链与 28nm 标准单元库。
- 正式包：`tools/package_submission.py` 生成 `dist/mxfp8_npu_submission_20260506/`，当前作为正式提交候选包；污染检查已确认排除 `.git/`、`.omx/`、`.codexpotter/`、`work/`、`sim/*.vvp`、教学目录和历史 admin 规划文件。

## 关键入口

- 单入口提交报告：`docs/report/submission_report.md`
- 后端接收清单：`docs/report/12_backend_handoff_checklist.md`
- 后端 RTL filelist：`synth/rtl_filelist.f`
- 最终提交 manifest：`docs/admin/final_submission_manifest.md`
- 综合环境检查：`reports/synthesis/environment_check_2026-05-06.md`
- 综合检查说明：`docs/usage/02_synthesis_environment_check.md`
- 一键验收脚本：`sim/run_submission_regression.ps1`
- 官方打包脚本：`tools/package_submission.py`

## 后续触发条件

1. 如果收到主办方模板或答辩规则，先更新 `docs/report/09_submission_checklist.md` 和 `docs/report/submission_report.md`。
2. 如果获得真实 28nm `.db/.lib`、约束要求和综合工具，先归档真实 logs/reports，再更新 `docs/report/07_synthesis_and_ppa.md`、`reports/synthesis/` 和最终 manifest。
3. 如果新增 benchmark 或评分样例，先扩展 `vectors/` 与 `sim/` 回归，再同步 `reports/evidence/` 和 `reports/precision/`。
4. 第二轮教学 Potter 只应在当前正式提交候选包稳定后启动；教学资料继续保留在仓库中，但不进入第一轮正式 handoff 包。
