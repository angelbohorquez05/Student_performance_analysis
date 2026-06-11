# Dataset : Students Performance in Exams (Kaggle)
# Source  : https://www.kaggle.com/datasets/spscientist/students-performance-in-exams
#
# PROJECT GOAL:
#   Explore the relationships between student background variables and exam
#   performance in a public dataset of 1,000 high school students. The analysis
#   examines associations at the group level using descriptive statistics,
#   visualizations, and standard hypothesis tests.
#
#   This is an exploratory analysis. Observed associations describe patterns
#   in the data; they do not establish causation and cannot be extrapolated
#   to predict outcomes for any individual student.
# =============================================================================


# ---- 0. SETUP ---------------------------------------------------------------

# Install missing packages if needed (run once)
# install.packages(c("rio", "dplyr", "ggplot2", "rcompanion", "reshape2", "car"))

library(rio)          # flexible data import
library(dplyr)        # data manipulation
library(ggplot2)      # visualizations
library(rcompanion)   # Cramér's V (effect size for chi-square)
library(reshape2)     # melt() for correlation matrix plot
library(car)          # leveneTest() — homogeneity of variance

# Consistent ggplot2 theme for all plots
theme_set(
  theme_minimal(base_size = 13) +
    theme(
      plot.title    = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "grey45", size = 11),
      axis.title    = element_text(size = 11),
      legend.position = "right"
    )
)


# ---- 1. DATA LOADING --------------------------------------------------------

students <- import("StudentsPerformance.csv")

cat("=== INITIAL STRUCTURE ===\n")
head(students)
str(students)
summary(students)

# The dataset has 1,000 observations and 8 variables.
#   Categorical : gender, race/ethnicity, parental level of education,
#                 lunch, test preparation course
#   Numerical   : math score, reading score, writing score
#   No missing values detected at first glance — verified in Section 2.


# ---- 2. MISSING VALUES & ANOMALY DETECTION ----------------------------------

cat("\n=== MISSING VALUES PER COLUMN ===\n")
apply(students, 2, function(x) sum(is.na(x)))

cat("\nTotal missing values:", sum(is.na(students)), "\n")
# Result: 0 — no missing data.

# Check categorical levels for typos or inconsistencies
cat("\n--- Categorical distributions ---\n")
lapply(students[, 1:5], table)

# Validate numerical ranges (scores must be 0–100)
cat("\n--- Score ranges ---\n")
sapply(students[, 6:8], range)
# All scores are within [0, 100]. No impossible values found.


# ---- 3. DATA CLEANING & FEATURE ENGINEERING ---------------------------------

# Rename columns to clean, R-friendly names
students <- rename(students,
  gender      = gender,
  ethnicity   = `race/ethnicity`,
  parent_edu  = `parental level of education`,
  lunch       = lunch,
  prep_course = `test preparation course`,
  math        = `math score`,
  reading     = `reading score`,
  writing     = `writing score`
)

# --- New variables ---

# 3a. Composite average score across all three subjects
students <- mutate(students,
  avg_score = round((math + reading + writing) / 3, 1)
)

# 3b. Ordinal performance level (used in Chi-square analysis)
students <- mutate(students,
  performance = case_when(
    avg_score >= 70 ~ "High",
    avg_score >= 50 ~ "Medium",
    TRUE            ~ "Low"
  ),
  performance = factor(performance, levels = c("Low", "Medium", "High"))
)

# 3c. Recode prep_course for readability
students <- mutate(students,
  prep_course = recode(prep_course,
    "completed" = "Completed",
    "none"      = "Not Completed"
  )
)

# 3d. Order parental education levels logically (low → high)
edu_levels <- c(
  "some high school", "high school", "some college",
  "associate's degree", "bachelor's degree", "master's degree"
)
students$parent_edu <- factor(students$parent_edu, levels = edu_levels)

cat("\n=== TRANSFORMED DATASET ===\n")
head(students)
str(students)


# ---- 4. DESCRIPTIVE STATISTICS ----------------------------------------------

cat("\n=== DESCRIPTIVE STATISTICS ===\n")

# --- 4.1 Categorical distributions ---

cat("\nGender distribution (%):\n")
round(prop.table(table(students$gender)) * 100, 1)

cat("\nPrep course completion (%):\n")
round(prop.table(table(students$prep_course)) * 100, 1)
# 36% of students completed the prep course; 64% did not.

cat("\nLunch type (%):\n")
round(prop.table(table(students$lunch)) * 100, 1)

cat("\nPerformance level (%):\n")
round(prop.table(table(students$performance)) * 100, 1)

# --- 4.2 Numerical summaries ---

score_vars <- c("math", "reading", "writing", "avg_score")

cat("\nSummary statistics for scores:\n")
sapply(students[, score_vars], function(x)
  c(Mean   = round(mean(x), 2),
    Median = median(x),
    SD     = round(sd(x), 2),
    Min    = min(x),
    Max    = max(x))
)

# --- 4.3 Group means by prep course ---

cat("\nMean scores by prep course status:\n")
students %>%
  group_by(prep_course) %>%
  summarise(
    n            = n(),
    mean_math    = round(mean(math), 1),
    mean_reading = round(mean(reading), 1),
    mean_writing = round(mean(writing), 1),
    mean_avg     = round(mean(avg_score), 1)
  )

# --- 4.4 Group means by parental education ---

cat("\nMean average score by parental education level:\n")
students %>%
  group_by(parent_edu) %>%
  summarise(n = n(), mean_avg = round(mean(avg_score), 1)) %>%
  arrange(parent_edu)


# ---- 5. VISUALIZATIONS ------------------------------------------------------

# --- Plot 1: Score distributions by prep course (boxplot) ---
p1 <- ggplot(students, aes(x = prep_course, y = avg_score, fill = prep_course)) +
  geom_boxplot(alpha = 0.75, outlier.alpha = 0.25, width = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = "black") +
  scale_fill_manual(values = c("Completed" = "#2ecc71", "Not Completed" = "#e74c3c")) +
  labs(
    title    = "Average Score by Test Preparation Course",
    subtitle = "Diamond = group mean · Boxes show IQR",
    x        = "Prep Course Status",
    y        = "Average Score (0–100)"
  ) +
  theme(legend.position = "none")
print(p1)

# --- Plot 2: Score distributions by lunch type ---
p2 <- ggplot(students, aes(x = lunch, y = avg_score, fill = lunch)) +
  geom_violin(alpha = 0.5, trim = FALSE) +
  geom_boxplot(width = 0.15, alpha = 0.85, outlier.alpha = 0.2) +
  scale_fill_manual(values = c("standard" = "#3498db", "free/reduced" = "#e67e22")) +
  labs(
    title    = "Average Score Distribution by Lunch Type",
    x        = "Lunch Type",
    y        = "Average Score (0–100)"
  ) +
  theme(legend.position = "none")
print(p2)

# --- Plot 3: Mean score by parental education level (bar chart) ---
p3 <- students %>%
  group_by(parent_edu) %>%
  summarise(mean_avg = round(mean(avg_score), 1), n = n()) %>%
  ggplot(aes(x = parent_edu, y = mean_avg, fill = mean_avg)) +
  geom_col(alpha = 0.85, width = 0.65) +
  geom_text(aes(label = mean_avg), vjust = -0.5, size = 3.5) +
  scale_fill_gradient(low = "#f9ca24", high = "#6c5ce7") +
  scale_y_continuous(limits = c(0, 80)) +
  labs(
    title    = "Mean Average Score by Parental Education Level",
    subtitle = "Ordered from lowest to highest education attainment",
    x        = "Parental Education",
    y        = "Mean Average Score",
    fill     = "Score"
  ) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
print(p3)

# --- Plot 4: Math vs Reading scatter — Pearson correlation by gender ---
p4 <- ggplot(students, aes(x = math, y = reading, color = gender)) +
  geom_point(alpha = 0.35, size = 1.6) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
  scale_color_manual(values = c("female" = "#e84393", "male" = "#1e90ff")) +
  labs(
    title    = "Math Score vs Reading Score",
    subtitle = "Linear fit by gender — Pearson correlation",
    x        = "Math Score",
    y        = "Reading Score",
    color    = "Gender"
  )
print(p4)

# --- Plot 5: Performance level by gender (grouped bar) ---
p5 <- students %>%
  count(gender, performance) %>%
  group_by(gender) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  ggplot(aes(x = gender, y = pct, fill = performance)) +
  geom_col(position = "dodge", alpha = 0.85, width = 0.6) +
  geom_text(aes(label = paste0(pct, "%")),
            position = position_dodge(width = 0.6), vjust = -0.4, size = 3.2) +
  scale_fill_manual(values = c("High" = "#27ae60", "Medium" = "#f39c12", "Low" = "#c0392b")) +
  scale_y_continuous(limits = c(0, 60)) +
  labs(
    title    = "Performance Level Distribution by Gender",
    x        = "Gender",
    y        = "Percentage (%)",
    fill     = "Performance Level"
  )
print(p5)

# --- Plot 6: Correlation matrix — all three exam scores ---
cor_matrix <- cor(students[, c("math", "reading", "writing")])
cat("\nCorrelation matrix:\n")
round(cor_matrix, 3)

melted_cor <- melt(cor_matrix)
p6 <- ggplot(melted_cor, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = round(value, 2)), size = 5, fontface = "bold") +
  scale_fill_gradient2(
    low = "#e74c3c", mid = "white", high = "#2980b9",
    midpoint = 0, limits = c(-1, 1)
  ) +
  labs(
    title = "Correlation Matrix — Exam Scores",
    x = "", y = "", fill = "Pearson r"
  ) +
  coord_fixed()
print(p6)

# --- Plot 7: Distribution of average scores by ethnicity ---
p7 <- ggplot(students, aes(x = avg_score, fill = ethnicity)) +
  geom_density(alpha = 0.55) +
  labs(
    title    = "Average Score Distribution by Ethnicity",
    subtitle = "Kernel density estimates",
    x        = "Average Score",
    y        = "Density",
    fill     = "Ethnic Group"
  )
print(p7)


# ---- 6. STATISTICAL HYPOTHESIS TESTING --------------------------------------

cat("\n\n========================================\n")
cat("   SECTION 6: HYPOTHESIS TESTING\n")
cat("========================================\n")

# ---- 6.1  T-TEST — Prep course and average score ----------------------------
#
#   Question : Is there a difference in average scores between students who
#              completed the prep course and those who did not?
#   IV  : prep_course  (categorical, 2 groups)
#   DV  : avg_score    (numerical, continuous)
#   Test: Independent-samples Welch t-test
#         (Welch's variant is used by default in R — does not assume equal variances)
# ---------------------------------------------------------------------------

cat("\n--- 6.1 T-TEST: Prep Course and Average Score ---\n")

# Group summaries
students %>%
  group_by(prep_course) %>%
  summarise(
    n      = n(),
    mean   = round(mean(avg_score), 2),
    sd     = round(sd(avg_score), 2),
    median = median(avg_score)
  )

# Levene's test for equality of variances (informational)
leveneTest(avg_score ~ as.factor(prep_course), data = students)

# Welch t-test
ttest_prep <- t.test(avg_score ~ prep_course, data = students)
print(ttest_prep)

# Effect size — Cohen's d
means_prep <- students %>%
  group_by(prep_course) %>%
  summarise(m = mean(avg_score), s = sd(avg_score), n = n())
pooled_sd <- sqrt(((means_prep$n[1]-1)*means_prep$s[1]^2 +
                   (means_prep$n[2]-1)*means_prep$s[2]^2) /
                  (sum(means_prep$n) - 2))
cohens_d_prep <- abs(diff(means_prep$m)) / pooled_sd
cat("Cohen's d:", round(cohens_d_prep, 3),
    " (< 0.2 small | 0.2–0.5 medium | > 0.8 large)\n")

# H0: Mean avg_score is equal between the two groups.
# H1: Mean avg_score differs between the two groups.
# Interpretation:
#   With p < 0.05 we reject H0 and observe a statistically significant
#   difference in average scores between students who completed the prep
#   course and those who did not. The Cohen's d quantifies the magnitude
#   of this group-level difference.


# ---- 6.2  T-TEST — Lunch type and average score -----------------------------
#
#   Question : Is there a difference in average scores between students
#              with standard lunch and those with free/reduced lunch?
#   IV  : lunch      (categorical, 2 groups)
#   DV  : avg_score  (numerical)
#   Test: Welch t-test
# ---------------------------------------------------------------------------

cat("\n--- 6.2 T-TEST: Lunch Type and Average Score ---\n")

students %>%
  group_by(lunch) %>%
  summarise(
    n    = n(),
    mean = round(mean(avg_score), 2),
    sd   = round(sd(avg_score), 2)
  )

ttest_lunch <- t.test(avg_score ~ lunch, data = students)
print(ttest_lunch)

# Cohen's d for lunch
means_lunch <- students %>%
  group_by(lunch) %>%
  summarise(m = mean(avg_score), s = sd(avg_score), n = n())
pooled_sd_lunch <- sqrt(((means_lunch$n[1]-1)*means_lunch$s[1]^2 +
                          (means_lunch$n[2]-1)*means_lunch$s[2]^2) /
                         (sum(means_lunch$n) - 2))
cohens_d_lunch <- abs(diff(means_lunch$m)) / pooled_sd_lunch
cat("Cohen's d:", round(cohens_d_lunch, 3), "\n")

# H0: Mean avg_score is equal between the two lunch-type groups.
# H1: Mean avg_score differs between the two lunch-type groups.
# Interpretation:
#   The test indicates a statistically significant difference in mean scores
#   between the two groups. This is a description of the patterns observed
#   in the dataset; it does not identify the underlying mechanisms behind
#   the difference, which would require additional information beyond
#   what this dataset captures.


# ---- 6.3  ONE-WAY ANOVA — Parental education and average score --------------
#
#   Question : Do mean average scores differ across parental education levels?
#   IV  : parent_edu  (categorical, 6 ordered groups)
#   DV  : avg_score   (numerical)
#   Test: One-way ANOVA → post-hoc Tukey HSD
# ---------------------------------------------------------------------------

cat("\n--- 6.3 ANOVA: Parental Education and Average Score ---\n")

students %>%
  group_by(parent_edu) %>%
  summarise(
    n    = n(),
    mean = round(mean(avg_score), 2),
    sd   = round(sd(avg_score), 2)
  ) %>%
  arrange(parent_edu)

anova_edu <- aov(avg_score ~ parent_edu, data = students)
summary(anova_edu)

# Eta-squared (η²) — effect size for ANOVA
ss_between <- summary(anova_edu)[[1]]["parent_edu", "Sum Sq"]
ss_total   <- sum(summary(anova_edu)[[1]][, "Sum Sq"])
eta_sq     <- ss_between / ss_total
cat("Eta-squared (η²):", round(eta_sq, 4),
    " (< 0.06 small | 0.06–0.14 medium | > 0.14 large)\n")

# Post-hoc: Tukey HSD to identify which pairs differ significantly
cat("\nTukey HSD post-hoc test:\n")
tukey_result <- TukeyHSD(anova_edu)
print(tukey_result)

# H0: Mean avg_score is equal across all parental education groups.
# H1: At least one group mean differs from the others.
# Interpretation:
#   The ANOVA detects differences in group means; Tukey HSD identifies
#   which specific group pairs differ. These results describe associations
#   in the sample and do not imply a causal mechanism.


# ---- 6.4  PEARSON CORRELATION — Math and Reading scores ---------------------
#
#   Question : Is there a linear correlation between math and reading scores?
#   Both variables are continuous and numerical.
#   Test: Pearson's r
# ---------------------------------------------------------------------------

cat("\n--- 6.4 PEARSON CORRELATION: Math and Reading ---\n")

cat("Descriptive statistics:\n")
sapply(students[, c("math", "reading", "writing")], function(x)
  c(mean = round(mean(x), 2), sd = round(sd(x), 2)))

cor_result <- cor.test(students$math, students$reading,
                       method = "pearson",
                       use    = "pairwise.complete.obs")
print(cor_result)

cat("\nFull inter-subject correlation matrix:\n")
round(cor(students[, c("math", "reading", "writing")]), 3)

# H0: No linear correlation between math and reading scores (r = 0).
# H1: A significant linear correlation exists.
# Interpretation:
#   The three subject scores show strong positive correlations with each
#   other in this sample. A student scoring high in one subject tends
#   also to score high in the others — academic outcomes across subjects
#   appear to move together.


# ---- 6.5  CHI-SQUARE + CRAMÉR'S V — Gender and performance level ------------
#
#   Question : Is there an association between gender and performance level?
#   IV  : gender       (categorical, nominal)
#   DV  : performance  (categorical, ordinal — Low / Medium / High)
#   Test: Chi-square test of independence + Cramér's V (effect size)
# ---------------------------------------------------------------------------

cat("\n--- 6.5 CHI-SQUARE: Gender and Performance Level ---\n")

# Contingency table
ct <- table(students$gender, students$performance)
cat("\nContingency table:\n")
print(ct)

cat("\nRow proportions (within each gender, %):\n")
round(prop.table(ct, margin = 1) * 100, 1)

chisq_result <- chisq.test(ct)
print(chisq_result)

cat("\nExpected frequencies (should all be > 5 for chi-square to be valid):\n")
round(chisq_result$expected, 1)

# Effect size: Cramér's V
v <- cramerV(ct)
cat("\nCramér's V:", round(v, 4),
    "\n  0.00–0.10: negligible | 0.10–0.30: weak | 0.30–0.50: moderate | > 0.50: strong\n")

# H0: Gender and performance level are independent.
# H1: An association exists between the two variables.
# Interpretation:
#   The test indicates whether the two categorical variables are
#   statistically independent. Cramér's V quantifies the practical
#   strength of the association in this sample.


# ---- 7. MULTIVARIATE LINEAR REGRESSION --------------------------------------
#
#   Goal: Model avg_score using all categorical predictors simultaneously.
#         The bivariate tests above examine one variable at a time. A
#         multivariate model lets us see how each predictor relates to
#         the outcome while holding the others constant.
# ---------------------------------------------------------------------------

cat("\n\n========================================\n")
cat("   SECTION 7: MULTIVARIATE REGRESSION\n")
cat("========================================\n")

model <- lm(avg_score ~ prep_course + lunch + parent_edu + gender,
            data = students)

cat("\nRegression model summary:\n")
summary(model)

# --- 7.1 Model fit metrics ---
r2     <- summary(model)$r.squared
adj_r2 <- summary(model)$adj.r.squared
cat(sprintf("\nR²     : %.4f  (%.1f%% of variance explained)\n", r2, r2 * 100))
cat(sprintf("Adj. R²: %.4f\n", adj_r2))

# --- 7.2 Model assumptions ---

cat("\nResidual diagnostics:\n")

# Normality of residuals (Shapiro-Wilk on a random sample — full 1000 exceeds test limits)
set.seed(42)
sw_test <- shapiro.test(sample(residuals(model), 200))
print(sw_test)

# Homoscedasticity (non-constant variance test)
car::ncvTest(model)

# --- 7.3 Interpretation ---
cat("\n
Interpretation:
  The model estimates the partial association of each predictor with
  average score while controlling for the others. Coefficients reflect
  the average difference in score between a level and the reference
  category, holding all other predictors constant. The adjusted R²
  indicates how much variance in average scores is collectively captured
  by these four predictors in this sample.

  Notably, prep_course remains a significant predictor in the
  multivariate model. Among the four predictors examined, this is the
  one that corresponds to a concrete, modifiable action — and the
  observed group-level difference associated with it is meaningful.
\n")


# ---- 8. CONCLUSIONS ---------------------------------------------------------

cat("\n\n========================================\n")
cat("   SECTION 8: CONCLUSIONS\n")
cat("========================================\n")

cat("
SUMMARY OF OBSERVATIONS
=======================

This exploratory analysis surfaced several patterns at the group level
within the dataset:

1. PREP COURSE COMPLETION
   The t-test detected a statistically significant difference in average
   scores between students who completed the test preparation course and
   those who did not (p < 0.05). Among the variables examined here,
   prep course completion is the one tied to a concrete, modifiable
   action — and the observed group-level gap is meaningful in size.

2. LUNCH TYPE
   Average scores differ across lunch-type groups in this sample
   (t-test, p < 0.05). The observed association raises the question of
   whether differences in resources and support outside the classroom
   could relate to the patterns seen here. The dataset alone does not
   capture the broader context needed to address that question, and
   further information would be required to interpret the finding fully.

3. PARENTAL EDUCATION LEVEL
   The ANOVA detected differences in mean average scores across the six
   parental education categories (p < 0.05); Tukey HSD identifies the
   specific pairs that differ. As with the previous point, this describes
   an association observed in the sample and does not, on its own,
   identify the mechanisms producing it.

4. CROSS-SUBJECT CORRELATION
   The three subject scores (math, reading, writing) show strong positive
   correlations with each other (Pearson r > 0.8, p < 0.05). Performance
   across subjects appears to move together rather than independently.

5. GENDER AND PERFORMANCE LEVEL
   The chi-square test detects a statistically significant association,
   but Cramér's V indicates the association is weak in practical terms.

6. MULTIVARIATE MODEL
   When the four predictors are combined into a single regression model,
   each retains a significant partial effect, with prep_course standing
   out as the most actionable variable in the set.

NOTES ON SCOPE
==============

  - The findings describe associations in this specific sample of 1,000
    students. They do not establish causation and are not predictions
    about any individual.
  - The dataset records a limited set of variables. Many factors that
    plausibly relate to academic outcomes — study habits, school
    quality, individual circumstances, access to learning resources —
    are not represented here.
  - Among the variables analyzed, prep course completion is the one
    that maps most directly to a school-level intervention, and the
    group-level difference associated with it is the most actionable
    finding of this analysis.
")
