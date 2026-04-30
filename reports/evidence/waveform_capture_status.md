# 波形证据状态

## 当前状态

2026-04-30 已加入轻量 opt-in VCD 捕获路径。默认回归不生成波形；需要展示时运行：

```powershell
.\sim\run_waveform_smoke.ps1
```

该脚本使用 `-DDUMP_VCD` 重新编译代表性 smoke case，并把 VCD 放在：

```text
reports/evidence/waveforms/
```

已生成的 VCD：

| VCD | 来源 testbench | 目的 |
| --- | --- | --- |
| `tb_llmt_col_smoke_wave.vcd` | `tb/tb_llmt_col_smoke.v` | 单列 dot32、acc_clear、valid 延迟、32/64 累加 |
| `tb_llmt_col_back_to_back_wave.vcd` | `tb/tb_llmt_col_back_to_back.v` | 连续 `valid_i` 输入和 32/64/96 顺序输出 |
| `tb_mx_array_smoke_wave.vcd` | `tb/tb_mx_array_smoke.v` | 16 列 A 广播、B 分列、所有列输出一致 |

运行日志：

```text
reports/verification/waveform_smoke.log
```

## 捕获实现

代表性 testbench 中加入了 Verilog-2001 兼容的预处理保护：

```verilog
`ifdef DUMP_VCD
  initial begin
    $dumpfile(...);
    $dumpvars(0, <tb_module_name>);
  end
`endif
```

因此：

- 默认 `sim/run_iverilog.ps1` 不生成 VCD，回归速度和行为保持不变。
- `sim/run_waveform_smoke.ps1` 才打开 VCD。
- VCD 文件路径由 `+VCD_FILE=...` plusarg 传入，便于稳定归档。

## 建议截图场景

| 场景 | 关注信号 | 截图要说明 |
| --- | --- | --- |
| 单列 smoke | `valid_i`、`acc_clear_i`、`valid_o`、`acc_o` | 首块输出 32，第二块累计到 64 |
| 连续输入 | 连续 `valid_i`、`valid_o`、`acc_o` | 输出顺序为 32、64、96，不丢拍 |
| 阵列 smoke | `valid_i`、`acc_clear_i[15:0]`、`valid_o[15:0]`、`acc_o` | 16 列同步输出，A 广播和 B 分列连接正确 |

## 仍未包含的波形

当前没有默认生成大型 dataset VCD，因为矩阵级 VCD 体积更大。tail tile 和 sparse nonfinite 的最终正确性仍以固定向量、dataset testbench 和回归日志为准；如最终答辩需要，可再单独扩展一个小尺寸 dataset waveform case。

## 使用规则

- VCD 是展示和调试证据，不替代 `reports/verification/iverilog_default.log`。
- 报告截图应同时标注输入有效、输出有效和 accumulator 更新。
- 如果截图涉及 tail tile 或 nonfinite，必须同时引用 manifest、expected output 或对应回归日志。
