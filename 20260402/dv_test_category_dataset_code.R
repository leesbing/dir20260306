
library(stringr)

library(dplyr)
library(tidyr)
library(lme4)
library(broom)
library(broom.mixed)
library(knitr)

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

file_path <- "/Users/peichen/Desktop/subtract and adding project/Power and idea generation/study 1:pilot 1 results/dv_test_category_dataset.csv"
data <- read.csv(file_path, header = TRUE, stringsAsFactors = FALSE, check.names = TRUE)
colnames(data)

data$synthetic_id <- as.character(data$synthetic_id)







#way 1
# --------------------------
# 2. Identify condition for each participant
# --------------------------

high_cols <- grep("^high_power_ideas", names(data), value = TRUE)
low_cols  <- grep("^low_power_ideas", names(data), value = TRUE)

high_mat <- trimws(as.matrix(data[, high_cols]))
low_mat  <- trimws(as.matrix(data[, low_cols]))

data$n_high_filled <- rowSums(!is.na(high_mat) & high_mat != "")
data$n_low_filled  <- rowSums(!is.na(low_mat)  & low_mat  != "")

data$condition <- ifelse(
  data$n_high_filled > 0 & data$n_low_filled == 0, "high",
  ifelse(
    data$n_low_filled > 0 & data$n_high_filled == 0, "low",
    ifelse(data$n_high_filled > 0 & data$n_low_filled > 0, "both_filled", NA)
  )
)

table(data$condition, useNA = "ifany")

data <- subset(data, !is.na(condition))
data <- subset(data, synthetic_id != 99)

table(data$condition, useNA = "ifany")

#id 99 has been removed already



#way2

# --------------------------
# 2. Identify condition for each participant
# --------------------------
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
high_cat_cols <- paste0("category_", 1:20)
low_cat_cols  <- paste0("category_", 21:40)

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
    n_participants = n(),
    total_additive = sum(additive_n, na.rm = TRUE),
    total_subtractive = sum(subtractive_n, na.rm = TRUE),
    total_change = sum(change_n, na.rm = TRUE),
    total_invalid = sum(invalid_n, na.rm = TRUE),
    mean_additive = mean(additive_n, na.rm = TRUE),
    mean_subtractive = mean(subtractive_n, na.rm = TRUE),
    mean_change = mean(change_n, na.rm = TRUE),
    mean_invalid = mean(invalid_n, na.rm = TRUE),
    .groups = "drop"
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