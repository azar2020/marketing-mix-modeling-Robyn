setwd("C:/Users/user/MMM_ROBYN")

library(tidyverse)
library(ggplot2)
library(scales)
library(broom)
df <- read_csv("marketing_data.csv")
df$date <- as.Date(df$date)

set.seed(42)
n_weeks <- nrow(df)

# Split into 2 geo regions
# Test region: receives email campaign boost weeks 79-104 (year 3 Q1-Q2)
# Control region: no change

df_geo <- df %>%
  mutate(
    # Base regional split — control gets slightly lower base revenue
    region_test_base    = revenue * 0.52,
    region_control_base = revenue * 0.48,
    
    # Treatment period: weeks 79-104
    is_treatment_period = week >= 79 & week <= 104,
    
    # Email boost only in test region during treatment
    email_lift_effect = ifelse(is_treatment_period,
                               email_spend * 0.35 * rnorm(n_weeks, 1, 0.1),
                               0),
    
    # Final regional revenue
    revenue_test    = region_test_base + email_lift_effect +
      rnorm(n_weeks, 0, 1500),
    revenue_control = region_control_base +
      rnorm(n_weeks, 0, 1500)
  )

cat("✅ Geo data created\n")
cat("Treatment period: weeks 79-104\n")
cat("Avg test region revenue (treatment):",
    round(mean(df_geo$revenue_test[df_geo$is_treatment_period]), 0), "\n")
cat("Avg control region revenue (treatment):",
    round(mean(df_geo$revenue_control[df_geo$is_treatment_period]), 0), "\n")


## Plot: Test vs Control over time:
df_plot <- df_geo %>%
  select(date, week, revenue_test, revenue_control, is_treatment_period) %>%
  pivot_longer(c(revenue_test, revenue_control),
               names_to = "region", values_to = "revenue") %>%
  mutate(region = recode(region,
                         "revenue_test"    = "Test Region",
                         "revenue_control" = "Control Region"
  ))

p1 <- ggplot(df_plot, aes(x = date, y = revenue, color = region)) +
  geom_line(alpha = 0.8, linewidth = 0.7) +
  annotate("rect",
           xmin = df_geo$date[79], xmax = df_geo$date[104],
           ymin = -Inf, ymax = Inf,
           alpha = 0.1, fill = "#E74C3C") +
  annotate("text",
           x = df_geo$date[91], y = max(df_plot$revenue) * 0.97,
           label = "Treatment Period\n(Email Campaign Boost)",
           color = "#E74C3C", fontface = "bold", size = 3.5) +
  scale_y_continuous(labels = dollar_format()) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  scale_color_manual(values = c(
    "Test Region"    = "#2E86C1",
    "Control Region" = "#E67E22"
  )) +
  labs(
    title = "Geo-Lift Test: Test vs Control Region Revenue",
    subtitle = "Company A — Email Campaign Incrementality Test",
    x = "Date", y = "Weekly Revenue", color = "Region"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

print(p1)
ggsave("05_geolift_test_vs_control.png", p1, width = 12, height = 5, dpi = 150)



##  Calculate incremental lift:
# Difference-in-differences approach
pre_period  <- df_geo %>% filter(week < 79)
post_period <- df_geo %>% filter(is_treatment_period)

# Pre-period gap between regions
pre_gap  <- mean(pre_period$revenue_test) - mean(pre_period$revenue_control)

# Post-period gap
post_gap <- mean(post_period$revenue_test) - mean(post_period$revenue_control)

# Incremental lift = change in gap
incremental_lift         <- post_gap - pre_gap
incremental_lift_pct     <- incremental_lift / mean(pre_period$revenue_control) * 100
total_incremental_revenue <- incremental_lift * nrow(post_period)
total_email_spend        <- sum(post_period$email_spend)
incremental_roas         <- total_incremental_revenue / total_email_spend

cat("=== GEO-LIFT RESULTS ===\n")
cat("Pre-period avg gap:  $", round(pre_gap, 0), "\n")
cat("Post-period avg gap: $", round(post_gap, 0), "\n")
cat("Incremental lift:    $", round(incremental_lift, 0), "per week\n")
cat("Incremental lift %:  ", round(incremental_lift_pct, 1), "%\n")
cat("Total incremental revenue:", dollar(round(total_incremental_revenue, 0)), "\n")
cat("Total email spend:        ", dollar(round(total_email_spend, 0)), "\n")
cat("Incremental ROAS:         ", round(incremental_roas, 2), "x\n")


## Statistical significance test:
# T-test comparing lift in test vs control during treatment
lift_test    <- post_period$revenue_test    - post_period$revenue_control
lift_pre     <- pre_period$revenue_test[1:nrow(post_period)] -
  pre_period$revenue_control[1:nrow(post_period)]

t_result <- t.test(lift_test, lift_pre)

cat("\n=== STATISTICAL SIGNIFICANCE ===\n")
cat("p-value:", round(t_result$p.value, 4), "\n")
cat("95% CI: [",
    round(t_result$conf.int[1], 0), ",",
    round(t_result$conf.int[2], 0), "]\n")
cat("Result:", ifelse(t_result$p.value < 0.05,
                      "✅ Statistically significant lift detected",
                      "❌ Lift not statistically significant"), "\n")



##  Plot: Incremental revenue bar chart:
summary_df <- tibble(
  period  = c("Pre-Treatment", "Treatment Period"),
  avg_gap = c(pre_gap, post_gap)
)

p2 <- ggplot(summary_df, aes(x = period, y = avg_gap, fill = period)) +
  geom_col(width = 0.5, show.legend = FALSE) +
  geom_text(aes(label = dollar(round(avg_gap, 0))),
            vjust = -0.5, fontface = "bold", size = 4.5) +
  scale_fill_manual(values = c(
    "Pre-Treatment"    = "#AED6F1",
    "Treatment Period" = "#2E86C1"
  )) +
  scale_y_continuous(labels = dollar_format(),
                     expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Average Revenue Gap: Test vs Control Region",
    subtitle = "Wider gap during treatment = incremental lift from email campaign",
    x = "", y = "Avg Weekly Revenue Gap (Test - Control)"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

print(p2)
ggsave("06_incremental_lift_summary.png", p2, width = 8, height = 6, dpi = 150)

cat("✅ Notebook 02 complete — all outputs saved!\n")
