# 代码讲解 02：矩阵级数据集回归与尾 tile

这篇文档讲 `tb/tb_mx_array_dataset.v` 在做什么，以及它为什么是当前 P3 主线里最重要的 testbench 之一。

## 1. 这个 testbench 的职责
单列 testbench 只能证明一个 `llmt_col` 会算。  
矩阵级 testbench 要证明的是：

- 同一行 `A block` 广播给 16 个列核时，阵列结果是否一致
- 同一个 tile 的多个 `K_BLOCKS` 连续每拍送入时，流水是否还能对齐
- 最后一个 tile 不满 `16` 列时，未使用的 lane 会不会留下脏结果，或者在非有限值语义下落成错误的 padded 结果

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

这里虽然仍然拿 `valid_o[0]` 作为“代表 lane”去等待，但 testbench 另外有一条持续检查：`valid_o` 只能是全 0 或全 1。  
也就是说，只要出现“某几列先出结果、某几列还没出”的失步情况，testbench 会直接报错，不会被 `valid_o[0]` 这个简化等待条件掩盖掉。

原因是当前阵列验证的重点是“tile 最终结果对不对”，不是做逐拍波形级 scoreboard。

对真实列：

- 从 `expected_y.hex` 取参考值
- 与 `acc_o` 对比

对尾 tile 里被填充的空 lane：

- 如果这一行的 `A` blocks 都是有限值，要求输出等于 `FP32 zero`
- 如果这一行本身带 `NaN`，则 padded lane 合法结果会变成 `QNaN`

这能同时防止两种错误：

- 前一个 tile 的结果残留在没用到的 lane 里
- 把“行内 `NaN` 传播”误判成“padded lane 应该永远是零”

## 6. 四组关键数据集为什么都有价值
`5x20x96` 这组有限值数据集同时覆盖了三种之前没一起出现过的边界：

- `M=5`：奇数行
- `N=20`：第二个列 tile 只有前 4 个 lane 真正有效
- `K=96`：一共 3 个 `K_BLOCKS`

`3x18x64_nonfinite` 这组数据集则补了另一类问题：

- 输出里同时出现 finite / `inf` / `NaN`
- 第二个 tile 仍然是不满 `16` 列
- 可以验证 padded lane 在非有限值行上是否按预期落成 `QNaN`

`6x33x160_nonfinite` 则把边界再往前推了一步：

- `N=33`：一共 3 个列 tile，最后一个 tile 只剩 1 个真实输出列
- `K=160`：一共 5 个 `K_BLOCKS`，连续 burst 更长
- mixed finite / `inf` / `NaN` 语义继续保留
- 新数据集还顺带暴露出“黄金模型导出的 `QNaN` 必须统一 canonical 化”的问题，避免宿主平台保留 NaN 符号位时造成伪回归失败

`9x65x192_five_tiles` 则补上了另一个方向：

- `N=65`：一共 5 个列 tile，最后一个 tile 同样只剩 1 个真实输出列
- `K=192`：一共 6 个 `K_BLOCKS`
- 仍然保持 finite-only，方便把注意力集中在“更大多 tile 调度 + 更长累加链”而不是 NaN 传播上

这四组数据集一起用，才算把“尾 tile”从纯有限值场景扩到更真实的数值语义，并开始覆盖从 1 个 tile 一直推到 5 个列 tile 的调度边界。

## 7. 读完这篇后应该记住什么
- `tb_mx_array_dataset` 是当前矩阵级主回归，不只是“读文件然后比较”
- 用 `valid_o[0]` 等待只是简化写法，真正的前提是 `valid_o` 必须整向量同步变化；现在 testbench 已把这个前提显式检查掉
- 尾 tile 的核心做法是“固定宽度接口 + 空 lane 零填充 + 按行语义检查 padded 输出”
- `tb_mx_array_dataset_5x20x96.v`、`tb_mx_array_dataset_3x18x64_nonfinite.v`、`tb_mx_array_dataset_6x33x160_nonfinite.v`、`tb_mx_array_dataset_9x65x192.v` 的作用，是把有限值边界、mixed nonfinite 语义和 1 到 5 个列 tile 的组合边界一起纳入默认回归，而不是手工偶尔跑一次
