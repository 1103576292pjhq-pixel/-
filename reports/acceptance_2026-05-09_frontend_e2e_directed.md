# 批次验收报告：MXFP8 前端 LLMT / Array 端到端 directed 验证

## 基本信息

- 日期：2026-05-09
- 工作区：`D:\github\-`
- 阶段：前端 RTL 编写、测试、仿真
- 明确不做：综合、SDC、网表、面积、功耗、PPA 报告

## 三 Agent 结果

- 规划 lane：将第三批收敛为 LLMT 与 array 的端到端 directed 验证，不再扩随机数据集。
- 进行 lane：新增 `tb_llmt_col_boundary.v`、`tb_mx_array_col_independence.v`，并接入 `sim/run_iverilog.ps1`。
- 审核 lane：指出必须补 LLMT min subnormal / min normal，以及 array per-column clear；主线已补齐 array 局部清零检查并回归通过。

## 改动范围

- `tb/tb_llmt_col_boundary.v`
  - 新增 LLMT 边界 directed testbench。
  - 覆盖 min subnormal、negative min subnormal、min normal、scale NaN、element NaN、idle clear、连续三次累加。
- `tb/tb_mx_array_col_independence.v`
  - 新增 16 列独立性 directed testbench。
  - 第一拍所有列清零加载：前 8 列输出 1.0，后 8 列输出 2.0。
  - 第二拍 `acc_clear_i=16'h5555`：偶数列清零重算，奇数列继续累加。
- `sim/run_iverilog.ps1`
  - 默认回归从 8 个 testbench 扩展为 10 个 testbench。

## 数值语义核对

- `tb_llmt_col_boundary` 的 min subnormal 构造：
  - `a_elem=1.0`，`b_elem=1.0`，32 lane dot sum 为 32。
  - 两个 E8M0 scale 选为指数 -77 和 -77，使输出为 `32 * 2^-154 = 2^-149`。
  - 期望输出 `0x00000001`。
- negative min subnormal 使用 `-1.0 * +1.0`，期望 `0x80000001`。
- min normal 构造使用 scale 指数 -66 和 -65，使输出为 `32 * 2^-131 = 2^-126`，期望 `0x00800000`。
- array 独立性通过每列只激活一个不同 lane 构造，避免所有列同值掩盖列切片错误。
- per-column clear 通过 `16'h5555` 明确区分偶数列清零与奇数列累加。

## 回归结果

- `python .\tools\mx_ref.py --selftest`：PASS
- `.\sim\run_iverilog.ps1`：PASS
  - `tb_fixed_to_fp32_boundary`
  - `tb_fp32_add_basic`
  - `tb_fp32_add_subnormal`
  - `tb_llmt_col_basic`
  - `tb_llmt_col_boundary`
  - `tb_mx_array_basic`
  - `tb_mx_array_col_independence`
  - `tb_mx_array_dataset_3x20x64`
  - `tb_mx_array_dataset_2x17x32_nonfinite`
  - `tb_mx_array_dataset_4x33x96_random`
- `.\sim\run_waveform_smoke.ps1`：PASS
  - `build/tb_llmt_col_basic.vcd`
  - `build/tb_mx_array_basic.vcd`
- `.\sim\run_matmul_stats.ps1`：PASS
  - `reports/matmul_stats_4096x4096x4096_sampled.json`

## 4096 采样统计

- 矩阵规模：4096 x 4096 x 4096
- 采样点数：256
- seed：20260508
- mean_abs_error：0.00013804063200950623
- mean_rel_error：9.391798466636242e-07
- max_abs_error：0.0008134841918945312
- max_rel_error：8.614648161471103e-05

## 收尾检查

- 未发现遗留 `vvp.exe` 或 `iverilog.exe` 仿真进程。
- `git diff --check` 对第三批触及文件未报告 whitespace error；仅有 Windows CRLF 处理提示。
- 第三批没有触碰综合、SDC、网表、面积或功耗文件。

## 审核结论

本批通过。当前前端已经具备：

- 单模块数值边界 directed tests。
- LLMT 端到端边界 directed tests。
- Array 16 列独立性与 per-column clear directed tests。
- 小矩阵 dataset / nonfinite / random 回归。
- 4096x4096x4096 采样统计入口。

下一批建议扩展多 seed / 更大样本数统计，并整理 README 中的前端运行说明。
