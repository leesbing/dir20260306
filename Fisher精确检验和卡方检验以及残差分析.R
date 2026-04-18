# 1. 构建数据矩阵 (2行 x 3列)
# 注意：你提供的数据只有3列，这里按 2x3 构建
data_matrix <- matrix(
  c(344, 23, 179,   # 第一组数据 (Group 1)
    314, 33, 231),  # 第二组数据 (Group 2)
  nrow = 2,
  byrow = TRUE,
  dimnames = list(
    Group = c("Group_1", "Group_2"),
    Category = c("Cat_1", "Cat_2", "Cat_3")
  )
)

# 查看矩阵
cat("=== 观察频数表 ===\n")
print(data_matrix)

# ---------------------------------------------------------
# 第一步：执行 Fisher 精确检验 (获取准确的 P 值)
# ---------------------------------------------------------
cat("\n=== 1. Fisher 精确检验结果 ===\n")
# 使用蒙特卡洛模拟以确保准确性
result_fisher <- fisher.test(data_matrix, simulate.p.value = TRUE, B = 20000)

cat(sprintf("P值 (Fisher): %.4e\n", result_fisher$p.value))
if (result_fisher$p.value < 0.05) {
  cat("结论：两组人员的分类分布存在【显著差异】。\n")
  cat("-> 继续进行残差分析以定位差异来源...\n")
} else {
  cat("结论：无显著差异。\n")
  cat("-> 残差分析仅供参考，可能无显著异常点。\n")
}

# ---------------------------------------------------------
# 第二步:卡方检验 
# ---------------------------------------------------------
# 注意：fisher.test 不返回残差。我们使用 chisq.test 来计算残差。
# 即使做了 Fisher 检验，在大样本或期望频数>5的情况下，
# 卡方检验的残差仍然是定位“哪个单元格导致差异”的标准方法。

chi_result <- chisq.test(data_matrix)

cat("\n=== 卡方检验结果 ===\n")
cat(sprintf("卡方统计量 (χ2): %.4f\n", chi_result$statistic))
cat(sprintf("自由度 (df): %d\n", chi_result$parameter))
cat(sprintf("P值 (p-value): %.4e\n", chi_result$p.value))

# 判断显著性
alpha <- 0.05
if (chi_result$p.value < alpha) {
  cat(sprintf("\n结论：P值 < %.2f，拒绝零假设。\n", alpha))
  cat("-> 两组人员的分类分布存在【显著差异】。\n")
} else {
  cat(sprintf("\n结论：P值 >= %.2f，无法拒绝零假设。\n", alpha))
  cat("-> 尚无证据表明两组人员的分类分布存在差异。\n")
}


# ---------------------------------------------------------
# 第二步：计算标准化残差 (定位差异来源)
# ---------------------------------------------------------

# 提取观察值、期望值和残差
observed <- chi_result$observed
expected <- chi_result$expected
# residuals: 皮尔逊残差 (Pearson Residuals) = (O-E)/sqrt(E)
# stdres: 调整残差 (Adjusted Residuals) ~ N(0,1)，更适合判断显著性
adjusted_residuals <- chi_result$stdres 

cat("\n=== 2. 期望频数表 (假设无差异) ===\n")
print(round(expected, 2))

cat("\n=== 3. 调整残差表 (关键分析) ===\n")
print(round(adjusted_residuals, 3))

# ---------------------------------------------------------
# 第三步：自动识别“高风险”差异点
# ---------------------------------------------------------
cat("\n=== 4. 显著差异点诊断 (|残差| > 1.96) ===\n")

# 初始化标记矩阵
significance_map <- matrix("", nrow=nrow(adjusted_residuals), ncol=ncol(adjusted_residuals))
dimnames(significance_map) <- dimnames(adjusted_residuals)

found_significant <- FALSE

for (i in 1:nrow(adjusted_residuals)) {
  for (j in 1:ncol(adjusted_residuals)) {
    val <- adjusted_residuals[i, j]
    abs_val <- abs(val)
    
    label <- ""
    if (abs_val > 2.58) {
      label <- ifelse(val > 0, "显著偏多 (***)", "显著偏少 (***)")
      found_significant <- TRUE
    } else if (abs_val > 1.96) {
      label <- ifelse(val > 0, "显著偏多 (*)", "显著偏少 (*)")
      found_significant <- TRUE
    }
    
    significance_map[i, j] <- label
  }
}

if (found_significant) {
  print(significance_map)
  
  # 详细解读
  cat("\n--- 详细解读 ---\n")
  for (i in 1:nrow(adjusted_residuals)) {
    for (j in 1:ncol(adjusted_residuals)) {
      val <- adjusted_residuals[i, j]
      if (abs(val) > 1.96) {
        direction <- ifelse(val > 0, "多于预期", "少于预期")
        cat(sprintf(">> [%s, %s]: 观察值(%d) %s 期望值(%.1f)。残差 = %.2f\n", 
                    rownames(adjusted_residuals)[i], 
                    colnames(adjusted_residuals)[j],
                    observed[i, j], 
                    direction, 
                    expected[i, j],
                    val))
      }
    }
  }
} else {
  cat("未发现具有统计学意义的单一单元格差异 (所有 |残差| < 1.96)。\n")
  cat("这意味着整体的显著性可能是由多个微小的偏差共同累积而成的。\n")
}

# ---------------------------------------------------------
# (可选) 第四步：可视化热力图
# ---------------------------------------------------------
# 如果安装了 ggplot2 和 reshape2，可以取消以下注释来画图
# install.packages(c("ggplot2", "reshape2"))
if (requireNamespace("ggplot2", quietly = TRUE) && requireNamespace("reshape2", quietly = TRUE)) {
  library(ggplot2)
  library(reshape2)
  
  df_res <- melt(adjusted_residuals)
  colnames(df_res) <- c("Group", "Category", "Residual")
  
  ggplot(df_res, aes(x=Category, y=Group, fill=Residual)) +
    geom_tile(color="white") +
    geom_text(aes(label=round(Residual, 2)), color="black", size=5) +
    scale_fill_gradient2(low="blue", high="red", mid="white", 
                         midpoint=0, limit=c(-max(abs(df_res$Residual)), max(abs(df_res$Residual))),
                         name="调整残差") +
    theme_minimal() +
    labs(title="分类差异残差热力图 (红色:偏多, 蓝色:偏少)",
         subtitle="绝对值 > 1.96 表示显著差异")
}


# ---------------------------------------------------------
# 第五步：自行计算效应量
# ---------------------------------------------------------

# === 无需安装包的 Cramér's V 计算脚本 ===

# 1. 准备数据
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

# 2. 执行卡方检验 (获取卡方值)
# correct = FALSE 对于大于 2x2 的表格是标准设置
chi_test <- chisq.test(data_matrix, correct = FALSE)

# 3. 提取关键参数
chi2_val <- chi_test$statistic      # 卡方统计量
n_total <- sum(data_matrix)         # 总样本量
n_rows <- nrow(data_matrix)         # 行数
n_cols <- ncol(data_matrix)         # 列数

# 4. 计算 Cramér's V
# 公式: V = sqrt( chi2 / (n * (min(rows, cols) - 1)) )
k_min <- min(n_rows, n_cols)
cramers_v <- sqrt(chi2_val / (n_total * (k_min - 1)))

# 5. 输出结果
cat("=== Cramér's V 效应量计算结果 ===\n")
cat(sprintf("总样本量 (n): %d\n", n_total))
cat(sprintf("卡方值 (χ2): %.4f\n", chi2_val))
cat(sprintf("自由度因子 (k-1): %d\n", k_min - 1))
cat("--------------------------------\n")
cat(sprintf("Cramér's V = %.4f\n", cramers_v))
cat("--------------------------------\n")

# 6. 效应量等级解读
if (cramers_v < 0.1) {
  cat("解读：效应量微弱 (Negligible/Small)\n")
  cat("说明：虽然可能有统计显著性，但实际关联强度很低。")
} else if (cramers_v < 0.3) {
  cat("解读：效应量小到中等 (Small to Medium)\n")
} else if (cramers_v < 0.5) {
  cat("解读：效应量中等到大 (Medium to Large)\n")
} else {
  cat("解读：效应量非常大 (Very Large)\n")
}



# ---------------------------------------------------------
# 第六步：用rcompanion pkg计算效应量
# ---------------------------------------------------------


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
cramer_result <- cramersV(data_matrix, simulate.p.value = TRUE, B = 20000, ci = TRUE, conf = 0.95)

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