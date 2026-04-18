# 1. 构建数据矩阵 (2行 x 4列)
# 行名：Group1, Group2
# 列名：Cat1, Cat2, Cat3, Cat4
data_matrix <- matrix(
    c(344, 23, 179, 1,   # 第一组数据
       314, 33, 231, 22), # 第二组数据
  nrow = 2,
  byrow = TRUE,
  dimnames = list(
    Group = c("Group_1", "Group_2"),
    Category = c("Cat_1", "Cat_2", "Cat_3", "Cat_4")
  )
)

# 查看矩阵
print(data_matrix)

# 2. 执行 Fisher 精确检验
# simulate.p.value = TRUE: 当表格较大或数值较大时，使用蒙特卡洛模拟计算P值
#                      这对于 2x4 表格通常更快且足够精确。
# B = 200000: 模拟次数，次数越多结果越精确（默认是2000）
result <- fisher.test(data_matrix, simulate.p.value = TRUE, B = 20000)

# 3. 输出结果
print(result)

# 提取关键指标
cat("\n--- 结论 ---\n")
cat(sprintf("P值: %.4e\n", result$p.value))
if (result$p.value < 0.05) {
  cat("结论：两组人员的分类分布存在【显著差异】。\n")
} else {
  cat("结论：无显著差异。\n")
}