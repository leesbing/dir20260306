install.packages("stringr")
install.packages("dplyr")
install.packages("tidyr")
install.packages("lme4")
install.packages("broom")
install.packages("broom.mixed")
install.packages("knitr")



library(stringr)
library(dplyr)
library(tidyr)
library(lme4)
library(broom)
library(broom.mixed)
library(knitr)
library(readxl)

#Step 1: Put your IDs into a vector
clean_ids <- c(
  "4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20",
  "21","22","23","24","25","26","27","28","29","30","31","32","33","35","36","37",
  "38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53",
  "54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69",
  "70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85",
  "86","87","88","89","90","91","92","93","94","95","96","97","98","100","101","102",
  "103","104","105","106","107","108","109","110","111","112","113","114","115","116",
  "117","118","119","120","121","122","124","125","126","127","128","129","130","131",
  "132","133","134","135","137","138","139","140","141","142","143","144","145","146",
  "147","148","149","150","151","152","153","154","155","157","159","160","161","162",
  "163","164","165","167","168","169","170","171","172","173","174","175","176","178",
  "179","180","181","182","183","184","185","186","187","188","190","191","192","193",
  "194","195","196","197","198","199","200","201","202","203","204","205","207","208",
  "209","210","211","212","213","214","215","216","217","218","219","220","222","223",
  "224","225","226","227","228","229","230","231","232","233","234","235","236","237",
  "238","239","240","241","242","243","244","245","246","247","248","249","250","251",
  "252","253","254","255","256","257","258","259","260","261","262","263","264","265",
  "266","267","268","269","270","271","273","274","275","276","277","278","279","280",
  "281","282","283","284","285","286","287","288","289","290","291","292","293","294",
  "295","296","297","298","299","300","301","302","303","304","305","306","307","308",
  "309","310","311","312","313","314","315","316","317","318","319","320","321","322",
  "323","325","326","327","328","329","330","331","332","333","334","335","336","337",
  "338","339","340","341","342","343"
)


#Step 2: Read your Excel (use openxlsx since readxl broke)

library(openxlsx)

df <- read.xlsx("/Users/peichen/Desktop/subtract and adding project/Power and idea generation/study 1 ra coding results/row_format_finalcoded_ideas_replaced_with_final_category.xlsx")


#Step 3: Clean ID column (critical)
df$synthetic_id <- trimws(as.character(df$synthetic_id))
clean_ids <- trimws(as.character(clean_ids))


#Step 4: Filter
dv_test_category_dataset <- df[df$synthetic_id %in% clean_ids, ]


#check
length(unique(dv_test_category_dataset$synthetic_id))
length(clean_ids)

setdiff(clean_ids, unique(dv_test_category_dataset$synthetic_id))


#correct, 0 character

write.xlsx(
  dv_test_category_dataset,
  "/Users/peichen/Desktop/subtract and adding project/Power and idea generation/study 1 ra coding results/dv_test_category_dataset.xlsx",
  rowNames = FALSE
)


#idea analysis begin here
# --------------------------
# 1. Read data
# --------------------------
#RA CODING

# 在 R 语言中，read.csv 的这两个参数主要解决了两个痛点：
# 1. stringsAsFactors = FALSE：防止字符串（如 ID、类别）自动变成因子（Factor），保持为字符型。
# 2. check.names = TRUE：自动修正列名（例如将空格变为点 .，或处理重复列名），防止后续代码报错。
# file_path <- "/Users/peichen/Desktop/subtract and adding project/Power and idea generation/study 1:pilot 1 results/dv_test_category_dataset.csv"
# data <- read.csv(file_path, header = TRUE, stringsAsFactors = FALSE, check.names = TRUE)



file_path <- "Z:/李玲珑_data/玲珑 at UCSD/20260306/20260402/dv_test_category_dataset.xlsx"


# 读取excel文件，且行为方式与上面的read.csv函数指定的参数相同
# 1. read_excel 默认读取的字符串就是 character 类型（不会变成 factor），所以不需要像 read.csv 那样专门设置 stringsAsFactors = FALSE。
# 2. read_excel 的设计逻辑与 read.csv 不同：它默认总是会读取第一行作为表头。

data <- read_excel(
  file_path, 
  col_types = "guess",    # 对应 read.csv 的默认行为：自动猜测类型（但也包含把字符串当文本读）
  .name_repair = "unique" # 对应 check.names = TRUE：确保列名唯一且符合 R 命名规范
)

# 查看数据
View(data)
colnames(data)

# 验证 synthetic_id 类型（如果是纯数字ID，read_excel可能会猜成numeric，建议手动转char）
class(data$synthetic_id)
data$synthetic_id <- as.character(data$synthetic_id)



#way 1 of Identify condition for each participant
# --------------------------
# 2. Identify condition for each participant
# --------------------------

# 下两行代码的作用是利用正则表达式，批量筛选并提取出所有以特定前缀开头的列名。
# 简单来说，你正在把原本混在一起的 80 多个列，按照名字归类成了两组：“高权力（high）”组和“低权力（low）”组。
## 这两行代码非常高效地帮你完成了“列名分组”的工作。运行后，high_cols 变量里就存了所有高权力相关的列名，low_cols 里存了所有低权力相关的列名
# 以下是详细的代码拆解：
# . 代码逻辑拆解
##  第一行：提取“高权力”相关的列
##  names(data): 获取数据框中所有的列名（等同于 colnames(data)）。
##  "^high_power_ideas": 这是一个正则表达式。
##  ^ 符号代表“以……开头”。
##  这意味着它只会匹配那些名字以 high_power_ideas 开始的列（例如 high_power_ideas#1_1_1），而不会匹配中间或结尾包含这个词的列。
##  value = TRUE: 这是关键参数。
##  如果不加这个参数，grep 返回的是列的位置索引（比如 2, 4, 6...）。
##  加上 value = TRUE 后，它直接返回列名的具体内容（字符向量）。
##  high_cols <-: 将提取出来的所有列名（例如 "high_power_ideas#1_1_1", "high_power_ideas#1_2_1" 等）存储到一个名为 high_cols 的向量中。

high_cols <- grep("^high_power_ideas", names(data), value = TRUE)
low_cols  <- grep("^low_power_ideas", names(data), value = TRUE)

# 将筛选出来的“高权力”和“低权力”相关的数据列，转换为纯净的（去除首尾空格）字符型矩阵。
# 这是一个非常典型的数据预处理步骤，通常是为了后续进行文本分析或字符串匹配做准备。
# 以下是详细的步骤拆解：
#    第一步：提取子集 data[, high_cols]
# 作用：从原始数据框 data 中，只提取出之前定义的 high_cols（即所有以 high_power_ideas 开头的列）所包含的数据。
# 结果：得到一个只包含高权力相关列的小型数据框。
#    第二步：转换为矩阵 as.matrix(...)
# 作用：将数据框（Data Frame）强制转换为矩阵（Matrix）。
# 关键细节：
# 矩阵要求所有元素必须是同一种数据类型。
# 如果你的 high_cols 中包含任何字符型数据（比如文本内容），或者混合了数字和文本，as.matrix() 会强制将所有内容（包括数字）都变成字符型（字符串）。
# 注意： 如果数据中包含因子（Factor），直接转矩阵可能会变成因子的内部数字编码（如 1, 2, 3），而不是原本的文本。但考虑到你之前处理过 synthetic_id，且这是文本分析场景，这里大概率已经是字符型了。
#    第三步：去除首尾空格 trimws(...)
# 作用：trimws 是 "trim white space" 的缩写。它会遍历矩阵中的每一个单元格，去掉字符串开头和结尾的空格。
# 目的：清洗数据。例如，将 "  Great Idea " 清洗为 "Great Idea"。
# 为什么重要：在文本分析中，"apple" 和 "apple "（后面带空格）会被计算机视为两个完全不同的词。清洗空格能保证统计的准确性。

high_mat <- trimws(as.matrix(data[, high_cols]))
low_mat  <- trimws(as.matrix(data[, low_cols]))

View(high_mat)
View(low_mat)

# 统计每一行（即每一个样本/被试）在“高权力”和“低权力”这两组变量中，分别填写了多少个有效（既不是缺失值，也不是空字符串）的内容。
# 详细的逻辑拆解：
# 1.  !is.na(high_mat)：
#   检查矩阵中的每个单元格是否不是缺失值（NA）。
#   结果是一个逻辑矩阵（TRUE/FALSE），如果是 NA 则为 FALSE，否则为 TRUE。
# 2. high_mat != ""：
#   检查矩阵中的每个单元格是否不等于空字符串。
#   这一步是为了排除那些虽然填了，但只是敲了空格或者完全没写字的单元格。
#   结果也是一个逻辑矩阵。
# 3. &：
#   将上述两个条件进行“逻辑与”运算。
#   只有当一个单元格既不是 NA 又 不是空字符串时，结果才为 TRUE。
# 4. rowSums(...)：
#   对逻辑矩阵按行求和。
#   在 R 语言中，逻辑值求和时，TRUE 被视为 1，FALSE 被视为 0。
#   因此，这一步就是在数每一行里有多少个 TRUE（即多少个有效填写的格子）。
# 5. data$n_high_filled <- ...：
#   将统计好的数字作为一个新列 n_high_filled 添加回原始数据框 data 中。

data$n_high_filled <- rowSums(!is.na(high_mat) & high_mat != "")
data$n_low_filled  <- rowSums(!is.na(low_mat)  & low_mat  != "")

# 通过嵌套的 ifelse 语句，将样本分为了三类：“只填了高权力”、“只填了低权力”、“两边都填了”，以及“都没填”（标记为 NA）
data$condition <- ifelse(
  data$n_high_filled > 0 & data$n_low_filled == 0, "high",
  ifelse(
    data$n_low_filled > 0 & data$n_high_filled == 0, "low",
    ifelse(data$n_high_filled > 0 & data$n_low_filled > 0, "both_filled", NA)
  )
)

# 统计 condition 列中各个分组的样本数量，并显示缺失值（NA）的统计结果。
# table(data$condition)
#   这是 R 语言中用于创建频数表（列联表）的基础函数。
#   它会计算 data$condition 向量中每个唯一值（即 "high", "low", "both_filled"）出现的次数。
# useNA = "ifany"
#   这是 table() 函数的一个参数，专门用来控制如何处理缺失值（NA）。
#   默认情况：如果不加这个参数，table() 通常会忽略 NA 值，不显示在结果中。
# "ifany"：意思是“如果有 NA，就显示出来”。它会在表格的最后增加一行 <NA>，显示有多少个样本的 condition 是空的。

table(data$condition, useNA = "ifany")

# 删除了那些“两边都没填”的无效样本（即上一轮对话中 table 结果显示为 <NA> 的那些行）。
data <- subset(data, !is.na(condition))

# 保留 synthetic_id 不是 99 的所有样本
data <- subset(data, synthetic_id != 99)

# 再次检查分组
table(data$condition, useNA = "ifany")

#id 99 has been removed already



#way2 of Identify condition for each participant

# --------------------------
# 2. Identify condition for each participant
# --------------------------
#  将way1中零散的步骤（提取列名、矩阵转换、计数、分组）整合成了一个流畅的 dplyr 管道操作
data <- data %>%
  mutate(
    n_high_filled = rowSums(!is.na(select(., starts_with("high_power_ideas"))) & 
                              select(., starts_with("high_power_ideas")) != ""),
    n_low_filled  = rowSums(!is.na(select(., starts_with("low_power_ideas"))) & 
                              select(., starts_with("low_power_ideas")) != ""),
    condition = case_when(
      n_high_filled > 0 & n_low_filled == 0 ~ "high",
      n_low_filled > 0 & n_high_filled == 0 ~ "low",
      n_high_filled > 0 & n_low_filled > 0 ~ "both_filled",
      TRUE ~ NA_character_
    )
  )

# Optional check
table(data$condition, useNA = "ifany")

#check which row is na
data <- data %>%
filter(!is.na(condition))

#synthetic_id = 99 has empty idea fields, then the clean solution is simply to remove that row before doing the analyses.
data <- data %>%
  filter(synthetic_id != 99)


table(data$condition, useNA = "ifany")








# --------------------------
# 1. Participant-level counts
# --------------------------

# 将字符串 "category_" 与数字序列 1 到 20 拼接在一起，形成一个包含 20 个列名的字符向量
high_cat_cols <- paste0("category_", 1:20)
low_cat_cols  <- paste0("category_", 21:40)

# 给data增加了四列，分别是 additive_n，subtractive_n，change_n，invalid_n。 
# 分别包含每个参与者（synthetic_id）在不同维度（Additive, Subtractive, Change, Invalid）上的数量。
data <- data %>%
  rowwise() %>%
  mutate(
    additive_n = if (condition == "high") {
      sum(c_across(all_of(high_cat_cols)) == 1, na.rm = TRUE)
    } else {
      sum(c_across(all_of(low_cat_cols)) == 1, na.rm = TRUE)
    },
    subtractive_n = if (condition == "high") {
      sum(c_across(all_of(high_cat_cols)) == 2, na.rm = TRUE)
    } else {
      sum(c_across(all_of(low_cat_cols)) == 2, na.rm = TRUE)
    },
    change_n = if (condition == "high") {
      sum(c_across(all_of(high_cat_cols)) == 3, na.rm = TRUE)
    } else {
      sum(c_across(all_of(low_cat_cols)) == 3, na.rm = TRUE)
    },
    invalid_n = if (condition == "high") {
      sum(c_across(all_of(high_cat_cols)) == 4, na.rm = TRUE)
    } else {
      sum(c_across(all_of(low_cat_cols)) == 4, na.rm = TRUE)
    }
  ) %>%
  ungroup()

# --------------------------
# 2. Create participant-level DVs
# --------------------------
# 给data增加了四列，分别是 any_subtractive, any_additive, valid_ideas_n 。
# any_subtractive, any_additive 列分别保存该行是否存在对应分类的数据。
# valid_ideas_n 列保存有效建议的总数，排除了 invalid_n 列数据（即类别为4的无意义建议）。
data <- data %>%
  mutate(
    any_subtractive = ifelse(subtractive_n >= 1, 1, 0),
    any_additive = ifelse(additive_n >= 1, 1, 0),
    valid_ideas_n = additive_n + subtractive_n + change_n
  )

# --------------------------
# 3. Descriptive table
# --------------------------
desc_condition <- data %>%
  group_by(condition) %>%
  summarise(
    n_participants = n(), # <--- 意思是：告诉我当前这个组里一共有多少行数据
    total_additive = sum(additive_n, na.rm = TRUE),
    total_subtractive = sum(subtractive_n, na.rm = TRUE),
    total_change = sum(change_n, na.rm = TRUE),
    total_invalid = sum(invalid_n, na.rm = TRUE),
    mean_additive = mean(additive_n, na.rm = TRUE),
    mean_subtractive = mean(subtractive_n, na.rm = TRUE),
    mean_change = mean(change_n, na.rm = TRUE),
    mean_invalid = mean(invalid_n, na.rm = TRUE),
    .groups = "drop"  # <--- 意思是：“算完收工，把分组撤掉，给我个清净的表格。”
  )

desc_condition





# --------------------------
# 4. Final participant-level binary models
# --------------------------
model_sub_bin_control <- glm(
  any_subtractive ~ condition + valid_ideas_n,
  data = data,
  family = binomial
)

summary(model_sub_bin_control)
exp(coef(model_sub_bin_control))
exp(confint(model_sub_bin_control))

model_add_bin_control <- glm(
  any_additive ~ condition + valid_ideas_n,
  data = data,
  family = binomial
)

summary(model_add_bin_control)
exp(coef(model_add_bin_control))
exp(confint(model_add_bin_control))

# --------------------------
# 5. Build idea-level dataset (valid ideas only)
# --------------------------
high_cat_long <- data %>%
  filter(condition == "high") %>%
  select(synthetic_id, condition, all_of(high_cat_cols)) %>%
  pivot_longer(
    cols = all_of(high_cat_cols),
    names_to = "category_col",
    values_to = "category"
  )

low_cat_long <- data %>%
  filter(condition == "low") %>%
  select(synthetic_id, condition, all_of(low_cat_cols)) %>%
  pivot_longer(
    cols = all_of(low_cat_cols),
    names_to = "category_col",
    values_to = "category"
  )

ideas_long <- bind_rows(high_cat_long, low_cat_long) %>%
  mutate(category = as.numeric(category)) %>%
  filter(category %in% c(1, 2, 3)) %>%   # keep valid ideas only
  mutate(
    is_subtractive = ifelse(category == 2, 1, 0),
    is_additive = ifelse(category == 1, 1, 0)
  )

# --------------------------
# 6. Final idea-level mixed models
# --------------------------
model_sub_ml <- glmer(
  is_subtractive ~ condition + (1 | synthetic_id),
  data = ideas_long,
  family = binomial
)

summary(model_sub_ml)
exp(fixef(model_sub_ml))
exp(confint(model_sub_ml, parm = "beta_", method = "Wald"))

model_add_ml <- glmer(
  is_additive ~ condition + (1 | synthetic_id),
  data = ideas_long,
  family = binomial
)

summary(model_add_ml)
exp(fixef(model_add_ml))
exp(confint(model_add_ml, parm = "beta_", method = "Wald"))

# --------------------------
# 7. APA table for the 4 final models
# --------------------------

format_p <- function(p) {
  ifelse(p < .001, "< .001", sub("^0", "", sprintf("%.3f", p)))
}

extract_glm <- function(model, model_name) {
  broom::tidy(model, conf.int = TRUE) %>%
    filter(term != "(Intercept)") %>%
    mutate(
      Model = model_name,
      Predictor = recode(
        term,
        "conditionlow" = "Condition (low vs. high)",
        "valid_ideas_n" = "Valid ideas"
      ),
      b = round(estimate, 2),
      SE = round(std.error, 2),
      z = round(statistic, 2),
      p = format_p(p.value),
      OR = round(exp(estimate), 2),
      `95% CI` = paste0(
        "[", round(exp(conf.low), 2), ", ", round(exp(conf.high), 2), "]"
      )
    ) %>%
    select(Model, Predictor, b, SE, z, p, OR, `95% CI`)
}

extract_glmer <- function(model, model_name) {
  # fixed effects
  fixed <- broom.mixed::tidy(model, effects = "fixed") %>%
    filter(term != "(Intercept)")
  
  # Wald CIs from model
  ci_mat <- confint(model, parm = "beta_", method = "Wald")
  ci_df <- data.frame(
    term = rownames(ci_mat),
    conf.low = ci_mat[, 1],
    conf.high = ci_mat[, 2],
    row.names = NULL
  )
  
  # clean term names to match broom output
  ci_df$term <- gsub("^beta_", "", ci_df$term)
  
  fixed %>%
    left_join(ci_df, by = "term") %>%
    mutate(
      Model = model_name,
      Predictor = recode(
        term,
        "conditionlow" = "Condition (low vs. high)"
      ),
      b = round(estimate, 2),
      SE = round(std.error, 2),
      z = round(statistic, 2),
      p = format_p(p.value),
      OR = round(exp(estimate), 2),
      `95% CI` = paste0(
        "[", round(exp(conf.low), 2), ", ", round(exp(conf.high), 2), "]"
      )
    ) %>%
    select(Model, Predictor, b, SE, z, p, OR, `95% CI`)
}

apa_table_final <- bind_rows(
  extract_glm(model_sub_bin_control, "Any subtractive + valid ideas"),
  extract_glmer(model_sub_ml, "Idea-level subtractive (mixed)"),
  extract_glm(model_add_bin_control, "Any additive + valid ideas"),
  extract_glmer(model_add_ml, "Idea-level additive (mixed)")
)

apa_table_final








#test,no need to run 

install.packages("logistf")
library(logistf)

model_add_firth <- logistf(
  any_additive ~ condition + valid_ideas_n,
  data = data
)

summary(model_add_firth)