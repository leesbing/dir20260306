# ==========================================
# 1. 定义数据
# ==========================================
data_matrix <- matrix(
  c(344, 23, 179,   
    314, 33, 231),  
  nrow = 2,
  byrow = TRUE
)

# ==========================================
# 2. 定义手算 Cramér's V 的函数
# ==========================================
calc_cramer_v <- function(mat) {
  chi_test <- chisq.test(mat, correct = FALSE)
  chi_sq <- chi_test$statistic
  n <- sum(mat)
  n_row <- nrow(mat)
  n_col <- ncol(mat)
  k <- min(n_row - 1, n_col - 1)
  if (k == 0 || n == 0) return(0)
  v <- sqrt(chi_sq / (n * k))
  return(v)
}

# ==========================================
# 3. 计算点估计值
# ==========================================
cat("正在计算点估计值...\n")
v_observed <- calc_cramer_v(data_matrix)
cat(sprintf("观测到的 Cramér's V: %.4f\n", v_observed))

# ==========================================
# 4. Bootstrap 法计算 95% 置信区间
# ==========================================
cat("正在进行 Bootstrap 重采样 (B=20000)... (请稍候)\n")

set.seed(2026) 
B <- 20000     
n_total <- sum(data_matrix)
v_boot <- numeric(B) 
probs <- as.vector(data_matrix) / n_total

for (i in 1:B) {
  new_counts <- rmultinom(1, size = n_total, prob = probs)
  new_mat <- matrix(new_counts, nrow = nrow(data_matrix), ncol = ncol(data_matrix))
  v_boot[i] <- calc_cramer_v(new_mat)
}

alpha <- 0.05
ci_lower <- quantile(v_boot, probs = alpha / 2)
ci_upper <- quantile(v_boot, probs = 1 - alpha / 2)

# ==========================================
# 5. 输出结果 & 修复后的强度判断逻辑
# ==========================================
cat("\n=== 最终分析结果 ===\n")
cat(sprintf("样本量 (N): %d\n", n_total))
cat(sprintf("Cramér's V (点估计): %.4f\n", v_observed))
cat(sprintf("95%% 置信区间 (Bootstrap): [%.4f, %.4f]\n", ci_lower, ci_upper))

chi_sim <- chisq.test(data_matrix, simulate.p.value = TRUE, B = 20000)
cat(sprintf("模拟 P 值: %.6f\n", chi_sim$p.value))

cat("\n结论解读:\n")
if (chi_sim$p.value < 0.05) {
  cat("统计显著 (P < 0.05)\n")
} else {
  cat("统计不显著 (P >= 0.05)\n")
}

# --- 【修复重点】强度判断部分 ---
# 方法：将整个 if-else 结构包裹在大括号中，或者将 else 紧跟在 } 后面
strength <- {
  if (v_observed < 0.1) {
    "微弱"
  } else if (v_observed < 0.3) {
    "中等"
  } else {
    "强"
  }
}

cat(sprintf("关联强度: %s (V = %.4f)\n", strength, v_observed))
cat(sprintf("我们有 95%% 的把握认为，真实的 Cramér's V 值落在 [%.4f, %.4f] 之间。\n", ci_lower, ci_upper))