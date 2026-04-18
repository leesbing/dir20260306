### 使用rcompanion包

# 如果没有安装，请先运行以下命令安装
# install.packages("rcompanion")

library(rcompanion)

# 1. 构建数据矩阵 (使用你的 2x3 数据)
data_matrix <- matrix(
  c(344, 23, 179,   
    314, 33, 231),  
  nrow = 2,
  byrow = TRUE,
  dimnames = list(
    Group = c("Group_1", "Group_2"),
    Category = c("Cat_1", "Cat_2", "Cat_3")
  )
)

# 2. 计算 Cramér's V
# simulate.p.value = TRUE: 使用模拟法计算P值，更准确
# ci = TRUE: 计算置信区间
result <- rcompanion::cramerV(data_matrix, simulate.p.value = TRUE, B = 20000, ci = TRUE, conf = 0.95)

# 3. 输出结果
cat("=== Cramér's V 效应量分析 ===\n")
cat(sprintf("Cramér's V 值: %.4f\n", cramer_result$CramersV))
cat(sprintf("95% 置信区间: [%.4f, %.4f]\n", cramer_result$lower.ci, cramer_result$upper.ci))
cat(sprintf("P值: %.4e\n", cramer_result$p.value))

# 4. 效应量解读
v_val <- cramer_result$CramersV
cat("\n--- 效应量解读 ---\n")
if (v_val < 0.1) {
  cat("效应量等级：微弱 (Negligible)\n")
} else if (v_val < 0.3) {
  cat("效应量等级：小 (Small)\n")
} else if (v_val < 0.5) {
  cat("效应量等级：中 (Medium)\n")
} else {
  cat("效应量等级：大 (Large)\n")
}

### 使用 DescTools 包
# 安装 DescTools (如果还没装)
install.packages("DescTools")
library(DescTools)

cv_value <- DescTools::CramerV(data_matrix, conf.level = 0.95)
cv_value

