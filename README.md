# marketing-mix-modeling-Robyn

# 📊 Marketing Mix Modeling & Incrementality Testing
### Company A — Digital Marketing Campaign Optimization

---

## 🗂 Project Overview

This project demonstrates a full marketing measurement framework applied to Company A's digital marketing campaigns across **Email, SMS, Social Media, and Paid Search** channels over **104 weeks (Jan 2023 – Dec 2024)**.

The goal was to move beyond last-click attribution and build a holistic, data-driven understanding of how media investment drives revenue — from upper-funnel brand awareness to lower-funnel conversion.

The project covers three core workstreams:

1. **Exploratory Data Analysis (EDA)** — understanding spend patterns, seasonality, and channel correlations
2. **Incrementality Testing** — geo-lift experiment to measure the causal impact of email campaigns
3. **Marketing Mix Modeling (MMM)** — Robyn-based full-funnel model with budget optimization

> **Note:** Company A is an anonymized client. The dataset used in this project is simulated to reflect realistic marketing dynamics including adstock decay, saturation curves, and seasonal patterns.

---

## 📁 Repository Structure

```
company-a-mmm-campaign-optimization/
│
├── data/
│   └── company_a_marketing_data.csv   # Simulated weekly marketing dataset
│
├── notebooks/
│   ├── 01_eda.R                        # Exploratory data analysis
│   ├── 02_incrementality_geolift.R     # Geo-lift incrementality test
│   └── 03_mmm_robyn.R                  # MMM with Meta's Robyn
│
├── outputs/
│   ├── 01_revenue_trend.png
│   ├── 02_spend_by_channel.png
│   ├── 03_spend_vs_revenue.png
│   ├── 04_correlation_heatmap.png
│   ├── 05_geolift_test_vs_control.png
│   ├── 06_incremental_lift_summary.png
│   └── robyn_plots/                    # Robyn one-pagers and Pareto plots
│
└── README.md
```
> Dashboard visualization of these results available in the Power BI project (https://github.com/azar2020/Marketing-Performance-Dashboard).
---

## 📦 Dataset

| Field | Description |
|---|---|
| `date` | Week start date (Monday) |
| `week` | Week index (1–104) |
| `email_spend` | Weekly email marketing spend ($) |
| `sms_spend` | Weekly SMS marketing spend ($) |
| `social_spend` | Weekly social media spend ($) |
| `search_spend` | Weekly paid search spend ($) |
| `revenue` | Weekly total revenue ($) |
| `conversions` | Weekly number of conversions |

**Key stats:**
- 📅 Date range: Jan 2, 2023 – Dec 23, 2024
- 📈 Average weekly revenue: ~$110,000
- 🔁 Average weekly conversions: ~56
- 💰 Total media spend: ~$4.07M over 104 weeks

> **Note on time index:** The original dataset did not include a date column. A synthetic weekly time index was generated assuming each row represents one week of marketing activity.

---

## 🔍 Part 1 — Exploratory Data Analysis

**Notebook:** `01_eda.R`

Key findings from EDA:

- **Seasonal patterns** are clearly visible — revenue peaks in Q4 each year, consistent with publishing industry dynamics
- **Paid Search has the highest weekly spend**  (~$15K/week), followed by Social Media (~$12K/week)
- **Correlation with revenue:**
  - Search: 0.47 — moderate positive relationship
  - Social: 0.23 — weak positive relationship
  - Email: 0.31 — moderate positive relationship
  - SMS: 0.18 — weak positive relationship

> Raw correlations understate true channel impact due to adstock and saturation effects — this is exactly why MMM is needed.

### Revenue Trend (2023–2024)
<img width="1354" height="555" alt="image" src="https://github.com/user-attachments/assets/c0299914-c9e1-46ca-ab84-57c7a179cbe3" />


### Correlation: Media Channels vs Revenue
<img width="715" height="617" alt="image" src="https://github.com/user-attachments/assets/dfa349db-4627-460d-be28-1b83fabdf426" />


---

## 🧪 Part 2 — Incrementality Testing (Geo-Lift)

**Notebook:** `02_incrementality_geolift.R`

### Methodology

A **geo-lift test** was designed to measure the causal incremental revenue driven by email campaigns, beyond what would have occurred organically.

- **Test region:** Received boosted email campaign (weeks 79–104)
- **Control region:** No change in email activity
- **Method:** Difference-in-differences — comparing the revenue gap between regions before and during treatment

### Test vs Control Region Revenue
<img width="1352" height="544" alt="image" src="https://github.com/user-attachments/assets/8b166b64-066d-491a-8aaa-f2a122cb6d5d" />


### Incremental Lift Summary
<img width="823" height="613" alt="image" src="https://github.com/user-attachments/assets/92e010f6-6c3a-4f13-94b9-1fc1b7cee8cc" />

### Results

| Metric | Value |
|---|---|
| Pre-treatment avg revenue gap | $4,248 / week |
| Treatment period avg revenue gap | $7,202 / week |
| **Incremental lift** | **$2,954 / week** |
| Incremental lift % | ~12.4% |
| Statistical significance | p < 0.05 ✅ |

### Interpretation

The revenue gap between the test and control regions widened by **$2,954 per week** during the treatment period. This represents the **causally attributable** incremental revenue from the email campaign — revenue that would not have occurred without it.

This finding validated that email campaigns were generating genuine incremental lift, not just capturing demand that would have converted through other channels.

---

## 📈 Part 3 — Marketing Mix Modeling (Robyn)

**Notebook:** `03_mmm_robyn.R`

### Methodology

A full Marketing Mix Model was built using **Meta's open-source Robyn framework** with the following configuration:

| Parameter | Value |
|---|---|
| Model window | Jan 2023 – Dec 2024 (104 weeks) |
| Adstock type | Geometric decay |
| Prophet components | Trend, seasonality, Canadian holidays |
| Optimization algorithm | TwoPointsDE (Nevergrad) |
| Trials | 3 |
| Iterations per trial | 1,000 |

### Model One-Pager — Selected Model `1_276_1`
<img width="531" height="625" alt="image" src="https://github.com/user-attachments/assets/55bb8d50-8bd1-4b38-b3d6-217932967599" />


### Model Performance

| Metric | Value |
|---|---|
| Adjusted R² | 0.9862 |
| NRMSE | 0.0311 |
| DECOMP.RSSD | 0.0306 |
| Total ROAS | 0.951 |

### Channel Decomposition

Revenue decomposition across predictors:

| Predictor | Revenue Contribution |
|---|---|
| Base (intercept) | 66.3% |
| Paid Search | 12.3% |
| Social Media | 10.1% |
| Email | 7.1% |
| SMS | 4.1% |
| Seasonality & holidays | 0.2% |

### Channel ROAS & Adstock

| Channel | ROAS | Adstock Decay | Immediate Response |
|---|---|---|---|
| SMS | 1.12 | 22.6% | 24% |
| Email | 1.01 | 42.3% | 61% |
| Social | 0.92 | 22.7% | 19% |
| Search | 0.90 | 17.7% | 11% |

**Key insights:**
- **SMS has the highest ROAS (1.12)** — most efficient channel despite lowest spend
- **Email has the highest adstock decay (42.3%)** — ads continue working for ~6 weeks after delivery
- **Search and Social have the most carryover effect** — 89% and 81% of response is delayed

---

## 💰 Part 4 — Budget Optimization

Using Robyn's budget allocator with a `max_response` scenario and the same total budget ($39,168/week):

| Channel | Current Weekly Spend | Optimized Weekly Spend | Change |
|---|---|---|---|
| Email | $7,807 | $9,050 | **+16% ↑** |
| Search | $15,146 | $15,936 | **+5% ↑** |
| SMS | $4,054 | $4,471 | **+10% ↑** |
| Social | $12,161 | $9,711 | **-20% ↓** |

### Recommendation

> Reallocate **$2,450/week from Social to Email and SMS** to maximize revenue response without increasing total budget. Social Media is operating in a diminishing returns zone — reducing spend here and redirecting to underleveraged channels (Email, SMS) improves overall portfolio efficiency.

---

## 🛠 Tech Stack

| Tool | Purpose |
|---|---|
| R | Primary analysis language |
| Meta Robyn | Marketing Mix Modeling |
| Prophet | Trend & seasonality decomposition |
| ggplot2 | Data visualization |
| tidyverse | Data manipulation |
| Python (via reticulate) | Nevergrad optimization backend |

---

## 🚀 How to Run

1. Clone the repository
2. Install dependencies:
```r
install.packages(c("tidyverse", "ggplot2", "corrplot", "scales", "gridExtra"))
remotes::install_github("facebookexperimental/Robyn/R")
```
3. Run notebooks in order:
```
01_eda.R → 02_incrementality_geolift.R → 03_mmm_robyn.R
```

---

## 👤 Author

**Azar Taheri**
[LinkedIn](https://linkedin.com/in/azar-taheri) 

