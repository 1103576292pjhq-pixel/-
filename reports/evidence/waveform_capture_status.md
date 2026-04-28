# 波形证据状态

## 当前状态

当前已有可复验日志、固定向量和精度 JSON，但还没有可直接插入报告的波形截图。缺少截图不影响 PASS 日志本身，但会影响报告展示效果。

## 建议捕获场景

| 场景 | 目的 | 关注信号 |
| --- | --- | --- |
| `tb_llmt_col_smoke` | 单列基本流水 | `valid_i`、`valid_s1`、`valid_s2`、`valid_o`、`acc_o` |
| `tb_llmt_col_back_to_back` | 连续输入吞吐 | 连续 `valid_i`、输出顺序、accumulator 更新 |
| `tb_mx_array_dataset_5x20x96` | tail tile | `acc_clear_i`、`valid_o`、padding lane 输出 |
| `tb_mx_array_dataset_7x49x224_sparse_nonfinite` | sparse nonfinite | NaN 相关输出、tile 边界、`valid_o` uniform |

## 捕获方法建议

当前 testbench 尚未统一加入 `$dumpfile/$dumpvars`。推荐后续新增一个轻量开关，例如：

```verilog
`ifdef DUMP_VCD
initial begin
  $dumpfile("reports/evidence/<case>.vcd");
  $dumpvars(0, <tb_module_name>);
end
`endif
```

然后使用类似命令重新编译目标 case：

```powershell
iverilog -g2001 -DDUMP_VCD -I rtl -I tb -o sim/tb_llmt_col_smoke.vvp rtl/*.v tb/tb_llmt_col_smoke.v
vvp sim/tb_llmt_col_smoke.vvp
```

## 截图规则

- 截图应标出输入有效、输出有效和 accumulator 更新之间的延迟。
- tail tile 截图应标出真实列和 padding lane。
- nonfinite 截图应结合向量 manifest 和 expected output 一起解释。
- 截图只能作为展示材料；最终正确性仍以回归日志和固定向量为准。
