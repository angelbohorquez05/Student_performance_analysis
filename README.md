## Exploratory Statistical Analysis

![R](https://img.shields.io/badge/R-4.x-276DC3?style=flat&logo=r&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat)
![Dataset](https://img.shields.io/badge/Dataset-Kaggle-20BEFF?style=flat&logo=kaggle&logoColor=white)

An exploratory statistical analysis of a public dataset of 1,000 U.S. high school students. The project combines **exploratory data analysis**, **hypothesis testing**, and **multivariate regression** to surface patterns and associations between student background variables and exam scores.

---

## Table of Contents

- [Overview](#overview)
- [Dataset](#dataset)
- [Research Questions](#research-questions)
- [Methodology](#methodology)
- [Summary of Observations](#summary-of-observations)
- [Visualizations](#visualizations)
- [Project Structure](#project-structure)
- [How to Run](#how-to-run)
- [Tech Stack](#tech-stack)
- [Notes on Scope](#notes-on-scope)
- [Author](#author)

---

## Overview

This project explores how variables such as **parental education level**, **lunch type**, **test preparation course completion**, and **gender** relate to student exam scores in math, reading, and writing within a public Kaggle dataset.

The analysis follows a **hypothesis-testing structure**: each research question is framed as a null and alternative hypothesis, matched to the appropriate statistical test, and reported alongside an **effect size metric** so that both statistical and practical significance are visible.

The aim is descriptive — to identify and quantify patterns in the data, not to establish causation.

---

## Dataset

**Source:** [Students Performance in Exams — Kaggle](https://www.kaggle.com/datasets/spscientist/students-performance-in-exams)  
**Observations:** 1,000 students · **Variables:** 8 · **Missing values:** 0

| Variable | Type | Description |
|---|---|---|
| `gender` | Categorical | Student gender (female / male) |
| `race/ethnicity` | Categorical | Ethnic group (A–E) |
| `parental level of education` | Categorical | Parent's highest education degree (6 levels) |
| `lunch` | Categorical | Lunch subsidy type (standard / free or reduced) |
| `test preparation course` | Categorical | Whether the student completed a prep course |
| `math score` | Numerical | Math exam score (0–100) |
| `reading score` | Numerical | Reading exam score (0–100) |
| `writing score` | Numerical | Writing exam score (0–100) |

> **Engineered features:** `avg_score` (mean across subjects) · `performance` (Low / Medium / High categorical level)

---

## Research Questions

| # | Research Question | Statistical Test | Effect Size |
|---|---|---|---|
| 1 | Is there a difference in average scores between students who completed the prep course and those who did not? | Welch T-test | Cohen's d |
| 2 | Do average scores differ between lunch-type groups? | Welch T-test | Cohen's d |
| 3 | Do mean scores differ across parental education levels? | One-way ANOVA + Tukey HSD | Eta-squared (η²) |
| 4 | Is there a linear correlation between math and reading scores? | Pearson's r | r coefficient |
| 5 | Is there an association between gender and performance level? | Chi-square | Cramér's V |
| 6 | What is the joint structure when all factors are modeled together? | Multivariate Linear Regression | Adjusted R² |

---

## Methodology

```
Raw Data
   │
   ├── 1. Exploration         → head(), str(), summary()
   ├── 2. Anomaly Detection   → NA counts, range checks, category validation
   ├── 3. Cleaning            → column renaming, factor ordering, new variables
   ├── 4. Descriptive Stats   → proportions, group means, standard deviations
   ├── 5. Visualizations      → 7 ggplot2 plots (boxplots, violin, scatter, heatmap)
   ├── 6. Hypothesis Testing  → T-tests, ANOVA, Pearson, Chi-square
   │       └── Effect sizes   → Cohen's d, η², Cramér's V
   └── 7. Regression Model    → lm() with all predictors + assumption checks
```

Each test is accompanied by:
- Explicit **H₀ / H₁** formulation
- **p-value** interpretation at α = 0.05
- **Effect size** to assess practical relevance beyond statistical significance

---

## Summary of Observations

| Variable | Test | Result | Effect |
|---|---|---|---|
| Prep course completion | T-test | Significant difference | Medium–Large (Cohen's d) |
| Lunch type | T-test | Significant difference | Medium (Cohen's d) |
| Parental education level | ANOVA | Significant differences | Small–Medium (η²) |
| Math ↔ Reading | Pearson | Strong positive correlation | r > 0.80 |
| Gender ↔ Performance level | Chi-square | Significant association | Weak (Cramér's V < 0.20) |

**Highlights:**
- The three exam subjects are **highly correlated**, suggesting that academic outcomes across subjects tend to move together rather than develop independently.
- Among the four background predictors, **prep course completion** is the one most directly tied to a concrete, modifiable action, and shows a meaningful group-level effect.
- The multivariate regression confirms that each predictor retains a significant partial association when modeled jointly.

---

## Visualizations

The script generates **7 plots** using `ggplot2`:

| Plot | Description |
|---|---|
| Boxplot | Average score by prep course status |
| Violin + Boxplot | Average score by lunch type |
| Bar chart | Mean score by parental education level |
| Scatter + LM fit | Math vs Reading by gender |
| Grouped bar | Performance level distribution by gender |
| Heatmap | Correlation matrix — math, reading, writing |
| Density | Score distribution by ethnicity |

---

## Project Structure

```
.
├── student_performance_analysis.R   # Main analysis script (8 sections)
├── StudentsPerformance.csv           # Raw dataset (from Kaggle)
└── README.md
```

---

## How to Run

**Requirements:** R ≥ 4.0 and RStudio (recommended)

**1. Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/student-performance-analysis.git
cd student-performance-analysis
```

**2. Install dependencies** (run once in the R console)
```r
install.packages(c("rio", "dplyr", "ggplot2", "rcompanion", "reshape2", "car"))
```

**3. Run the analysis**

Open `student_performance_analysis.R` in RStudio and run it section by section,  
or execute the full script:
```r
source("student_performance_analysis.R")
```

> The script is self-contained. All sections print annotated output to the console and render plots inline.

---

## Tech Stack

| Package | Role |
|---|---|
| [`rio`](https://cran.r-project.org/package=rio) | Flexible dataset import |
| [`dplyr`](https://dplyr.tidyverse.org/) | Data manipulation and group summaries |
| [`ggplot2`](https://ggplot2.tidyverse.org/) | All visualizations |
| [`rcompanion`](https://cran.r-project.org/package=rcompanion) | Cramér's V (chi-square effect size) |
| [`reshape2`](https://cran.r-project.org/package=reshape2) | Correlation matrix reshaping for heatmap |
| [`car`](https://cran.r-project.org/package=car) | Levene's test & non-constant variance test |

---

## Notes on Scope

- The findings describe **associations within this specific sample** of 1,000 students. They do not establish causation and are not predictions for any individual.
- The dataset records a **limited set of variables**. Many factors that plausibly relate to academic outcomes — study habits, school quality, individual circumstances, access to learning resources — are not represented here.
- Statistical significance and practical relevance are reported separately (via effect sizes), since large samples can produce significant p-values for differences that are small in real terms.

---

## Author

**Angel Bohorquez**  
Industrial Engineer · AI/ML  
ITS Program in Artificial Intelligence & Machine Learning — Milan, Italy

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat&logo=linkedin)](https://www.linkedin.com/in/YOUR_PROFILE)
[![GitHub](https://img.shields.io/badge/GitHub-Profile-181717?style=flat&logo=github)](https://github.com/YOUR_USERNAME)

---

*Dataset provided by [Kaggle](https://www.kaggle.com/datasets/spscientist/students-performance-in-exams) under public use license.*
