# 代码讲解 02：矩阵级数据集回归与尾 tile

这篇文档讲 `tb/tb_mx_array_dataset.v` 在做什么，以及它为什么是当前 P3 主线里最重要的 testbench 之一。

## 1. 这个 testbench 的职责
单列 testbench 只能证明一个 `llmt_col` 会算。  
矩阵级 testbench 要证明的是：

- 同一行 `A block` 广播给 16 个列核时，阵列结果是否一致
- 同一个 tile 的多个 `K_BLOCKS` 连续每拍送入时，流水是否还能对齐
- 最后一个 tile 不满 `16` 列时，未使用的 lane 会不会留下脏结果

所以它不是“再包一层循环”而已，而是在验证阵列级调度语义。

## 2. 参数和数据文件怎么对应
这个 testbench 通过宏指定矩阵大小和数据文件：

- `TB_M`
- `TB_N`
- `TB_K_BLOCKS`
- `TB_A_BLOCKS_HEX`
- `TB_A_SCALES_HEX`
- `TB_B_BLOCKS_HEX`
- `TB_B_SCALES_HEX`
- `TB_EXPECTED_Y_HEX`

例如 [tb_mx_array_dataset_5x20x96.v](/D:/github/-/tb/tb_mx_array_dataset_5x20x96.v) 只是先把这些宏定义好，再 `include "tb_mx_array_dataset.v"`。

这样做的好处是：同一份主 testbench 可以复用到多组固定数据集，不需要复制粘贴大量主体逻辑。

## 3. `load_step_inputs` 在做什么
`load_step_inputs(row, tile, kb)` 负责把“某一行、某一个 tile、某一个 `K` block”的输入装到阵列端口上。

关键点有两个：

- `A` 侧按 `row_idx * K_BLOCKS + kb_idx` 取一整行当前 block
- `B` 侧按 `global_col * K_BLOCKS + kb_idx` 给 16 个 lane 分别取列数据

如果 `global_col < N`，说明这个 lane 对应真实输出列，就从内存里读数据。  
如果 `global_col >= N`，说明已经越过矩阵真实宽度了，这个 lane 会被喂入：

- 全零 `b_elems`
- `0x7f` 这个零贡献 scale

这就是“尾 tile 零填充”。

## 4. 为什么要 burst 送完整个 tile
`drive_tile_burst` 不再在每个 `K block` 之间插空拍，而是把同一个 tile 的 `K_BLOCKS` 连续每拍送进去。

这样更接近真实阵列吞吐场景，也更容易暴露：

- `valid` 对齐错误
- 累加器清零时序错误
- 多 block 连续输入时的流水问题

如果这里只用“打一拍，停一拍”的保守驱动，很多时序问题会被 testbench 自己掩盖掉。

## 5. `check_tile_results` 为什么先等整串 `valid_o`
这个 testbench 不在第一个结果出来时立刻逐拍比较，而是：

1. 先等 `valid_o` 拉高
2. 再等这一串 `valid_o` 拉低
3. 最后一次性读取 `acc_o`

原因是当前阵列验证的重点是“tile 最终结果对不对”，不是做逐拍波形级 scoreboard。

对真实列：

- 从 `expected_y.hex` 取参考值
- 与 `acc_o` 对比

对尾 tile 里被填充的空 lane：

- 直接要求输出等于 `FP32 zero`

这能防止前一个 tile 的结果残留在没用到的 lane 里。

## 6. `5x20x96` 这组数据为什么有价值
这组新数据集同时覆盖了三种之前没一起出现过的边界：

- `M=5`：奇数行
- `N=20`：第二个列 tile 只有前 4 个 lane 真正有效
- `K=96`：一共 3 个 `K_BLOCKS`

它比再加一组 `16x32x128` 这种整齐矩阵更能验证 testbench 和阵列驱动的边界语义。

## 7. 读完这篇后应该记住什么
- `tb_mx_array_dataset` 是当前矩阵级主回归，不只是“读文件然后比较”
- 尾 tile 的核心做法是“固定宽度接口 + 空 lane 零填充 + 最终输出清零检查”
- `tb_mx_array_dataset_5x20x96.v` 的作用是把这套边界覆盖纳入默认回归，而不是手工偶尔跑一次
