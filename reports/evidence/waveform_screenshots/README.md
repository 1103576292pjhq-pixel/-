# 波形截图目录

本目录用于放正式报告或答辩中可直接引用的波形截图。截图必须来自 `reports/evidence/waveforms/` 下已经归档的 VCD，不允许手画不可复验波形。

## 建议截图清单

| 文件名 | 来源 VCD | 需要展示的信号 | 图注重点 |
| --- | --- | --- | --- |
| `tb_llmt_col_smoke.png` | `reports/evidence/waveforms/tb_llmt_col_smoke_wave.vcd` | `clk`、`valid_i`、`acc_clear_i`、`valid_o`、`acc_o` | 首个 block 输出 32，第二个 block 累加到 64 |
| `tb_llmt_col_back_to_back.png` | `reports/evidence/waveforms/tb_llmt_col_back_to_back_wave.vcd` | `valid_i`、`valid_o`、`acc_o` | 连续输入下输出 32、64、96，不丢拍 |
| `tb_mx_array_smoke.png` | `reports/evidence/waveforms/tb_mx_array_smoke_wave.vcd` | `valid_i`、`acc_clear_i`、`valid_o`、`acc_o` | 16 列同步输出，证明 A 广播和 B 分列连接正确 |

## 导出规则

1. 用 GTKWave 打开对应 VCD。
2. 只添加表格中列出的关键信号，避免截图过密。
3. 缩放到能同时看到输入 valid、输出 valid 和 accumulator 变化的窗口。
4. 导出 PNG 后放入本目录。
5. 在正式报告中引用 PNG 时，同时保留 VCD 路径作为可复验证据。

## 一键生成

```powershell
.\sim\render_waveform_screenshots.ps1
```

该脚本调用 `tools/render_waveform_png.py`，从已归档 VCD 生成上表三张 PNG。生成的 PNG 是报告展示层，VCD 仍是可复验证据源。

## 当前已生成 PNG

- `tb_llmt_col_smoke.png`
- `tb_llmt_col_back_to_back.png`
- `tb_mx_array_smoke.png`

当前状态：2026-05-06 已从归档 VCD 刷新三张 PNG，可直接放入报告或答辩材料。
