install.packages(c("tidyverse", "ggplot2", "corrplot", "scales"))
library(tidyverse)
library(ggplot2)
library(corrplot)
library(scales)
library(gridExtra)
setwd("C:/Users/user/MMM_ROBYN")

df <- read_csv("C:/Users/user/MMM_ROBYN/marketing_data.csv")
df$date <- as.Date(df$date)
cat("Rows:", nrow(df), "\n")
cat("Date range:", as.character(min(df$date)), "to", as.character(max(df$date)), "\n")
cat("Avg weekly revenue: $", round(mean(df$revenue), 0), "\n")
cat("Avg weekly conversions:", round(mean(df$conversions), 0), "\n")
summary(df)

##  Plot 1: Revenue over time:
p1 <- ggplot(df, aes(x = date, y = revenue)) +
  geom_line(color = "#2C3E50", linewidth = 0.8) +
  geom_smooth(method = "loess", color = "#E74C3C", se = TRUE, alpha = 0.2) +
  scale_y_continuous(labels = dollar_format()) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  labs(
    title = "Company A — Weekly Revenue (2022–2024)",
    subtitle = "Red line shows trend. Seasonal peaks visible in Q4 each year.",
    x = "Date", y = "Revenue"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

print(p1)
ggsave("01_revenue_trend.png", p1, width = 12, height = 5, dpi = 150)


## Plot 2: Media spend by channel:
# Reshape to long format
df_long <- df %>%
  select(date, email_spend, sms_spend, social_spend, search_spend) %>%
  pivot_longer(-date, names_to = "channel", values_to = "spend") %>%
  mutate(channel = recode(channel,
                          "email_spend"  = "Email",
                          "sms_spend"    = "SMS",
                          "social_spend" = "Social Media",
                          "search_spend" = "Paid Search"
  ))

p2 <- ggplot(df_long, aes(x = date, y = spend, color = channel)) +
  geom_line(alpha = 0.8, linewidth = 0.7) +
  facet_wrap(~channel, scales = "free_y", ncol = 2) +
  scale_y_continuous(labels = dollar_format()) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  scale_color_manual(values = c(
    "Email"       = "#3498DB",
    "SMS"         = "#E67E22",
    "Social Media"= "#2ECC71",
    "Paid Search" = "#9B59B6"
  )) +
  labs(
    title = "Weekly Media Spend by Channel (2022–2024)",
    subtitle = "Paid Search has highest spend; SMS lowest.",
    x = "Date", y = "Spend"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold"))

print(p2)
ggsave("02_spend_by_channel.png", p2, width = 12, height = 7, dpi = 150)


##  Plot 3: Spend vs Revenue scatter:
p3 <- df %>%
  select(date, email_spend, sms_spend, social_spend, search_spend, revenue) %>%
  pivot_longer(-c(date, revenue), names_to = "channel", values_to = "spend") %>%
  mutate(channel = recode(channel,
                          "email_spend"  = "Email",
                          "sms_spend"    = "SMS",
                          "social_spend" = "Social Media",
                          "search_spend" = "Paid Search"
  )) %>%
  ggplot(aes(x = spend, y = revenue, color = channel)) +
  geom_point(alpha = 0.4, size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1) +
  facet_wrap(~channel, scales = "free_x", ncol = 2) +
  scale_y_continuous(labels = dollar_format()) +
  scale_x_continuous(labels = dollar_format()) +
  scale_color_manual(values = c(
    "Email"       = "#3498DB",
    "SMS"         = "#E67E22",
    "Social Media"= "#2ECC71",
    "Paid Search" = "#9B59B6"
  )) +
  labs(
    title = "Media Spend vs Revenue by Channel",
    subtitle = "Steeper slope = stronger revenue relationship",
    x = "Weekly Spend", y = "Revenue"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold"))

print(p3)
ggsave("03_spend_vs_revenue.png", p3, width = 12, height = 7, dpi = 150)


## Plot 4: Correlation heatmap:

cor_data <- df %>%
  select(email_spend, sms_spend, social_spend, search_spend, revenue, conversions)

cor_matrix <- cor(cor_data)

png("04_correlation_heatmap.png", width = 800, height = 700, res = 120)
corrplot(cor_matrix,
         method = "color",
         type = "upper",
         addCoef.col = "black",
         tl.col = "black",
         tl.srt = 45,
         col = colorRampPalette(c("#EBF5FB", "#2E86C1", "#1A5276"))(200),
         title = "Correlation: Media Channels vs KPIs",
         mar = c(0, 0, 2, 0))
dev.off()

cat("✅ All EDA plots saved to outputs/ folder\n")
