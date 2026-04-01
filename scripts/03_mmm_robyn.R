#install.packages("remotes")
#remotes::install_github("facebookexperimental/Robyn/R")
setwd("C:/Users/user/MMM_ROBYN")
library(Robyn)
library(tidyverse)
library(scales)




# ── 1. LOAD DATA ──────────────────────────────────────────────
marketing_data <- read_csv("marketing_data.csv")
marketing_data$date <- as.Date(marketing_data$date)

# Build robyn dataframe (avoid using 'df' — conflicts with R built-in)
df_robyn <- data.frame(
  ds           = marketing_data$date,
  y            = marketing_data$revenue,
  email_spend  = marketing_data$email_spend,
  sms_spend    = marketing_data$sms_spend,
  social_spend = marketing_data$social_spend,
  search_spend = marketing_data$search_spend
)

cat("✅ Data ready for Robyn\n")
cat("Rows:", nrow(df_robyn), "\n")
cat("Date range:", as.character(min(df_robyn$ds)),
    "to", as.character(max(df_robyn$ds)), "\n")
head(df_robyn)

# ── 2. INPUT COLLECT ──────────────────────────────────────────
InputCollect <- robyn_inputs(
  dt_input          = df_robyn,
  dt_holidays       = dt_prophet_holidays,
  date_var          = "ds",
  dep_var           = "y",
  dep_var_type      = "revenue",
  prophet_vars      = c("trend", "season", "holiday"),
  prophet_country   = "CA",
  paid_media_spends = c("email_spend", "sms_spend",
                        "social_spend", "search_spend"),
  paid_media_vars   = c("email_spend", "sms_spend",
                        "social_spend", "search_spend"),
  adstock           = "geometric",
  window_start      = "2023-01-02",  # updated to match new dataset
  window_end        = "2024-12-23"   # updated to match new dataset
)

print(InputCollect)

# ── 3. HYPERPARAMETERS ────────────────────────────────────────
hyperparameters <- list(
  email_spend_alphas  = c(0.5, 3),
  email_spend_gammas  = c(0.3, 1),
  email_spend_thetas  = c(0,   0.5),
  
  sms_spend_alphas    = c(0.5, 3),
  sms_spend_gammas    = c(0.3, 1),
  sms_spend_thetas    = c(0,   0.3),
  
  social_spend_alphas = c(0.5, 3),
  social_spend_gammas = c(0.3, 1),
  social_spend_thetas = c(0,   0.6),
  
  search_spend_alphas = c(0.5, 3),
  search_spend_gammas = c(0.3, 1),
  search_spend_thetas = c(0,   0.3),
  
  train_size          = c(0.5, 0.8)
)

InputCollect <- robyn_inputs(
  InputCollect    = InputCollect,
  hyperparameters = hyperparameters
)

cat("✅ Hyperparameters set!\n")
print(InputCollect$hyperparameters)

# ── 4. RUN MODEL (lighter settings to prevent crash) ──────────
OutputModels <- robyn_run(
  InputCollect = InputCollect,
  iterations   = 1000,  # reduced from 2000
  trials       = 3,     # reduced from 5
  outputs      = FALSE
)

print(OutputModels)

# ── 5. GENERATE PARETO OUTPUTS ────────────────────────────────
dir.create("outputs/robyn_plots", recursive = TRUE, showWarnings = FALSE)

OutputCollect <- robyn_outputs(
  InputCollect  = InputCollect,
  OutputModels  = OutputModels,
  pareto_fronts = "auto",
  plot_folder   = "outputs/robyn_plots",
  plot_pareto   = TRUE
)

cat("✅ Pareto outputs generated!\n")
print(OutputCollect$allSolutions)

# ── 6. BUDGET ALLOCATOR ───────────────────────────────────────
best_model_id <- OutputCollect$allSolutions[1]
cat("Best model ID:", best_model_id, "\n")

total_budget <- sum(
  marketing_data$email_spend +
    marketing_data$sms_spend +
    marketing_data$social_spend +
    marketing_data$search_spend
)

cat("Total budget: $", round(total_budget, 0), "\n")

BudgetAllocator <- robyn_allocator(
  InputCollect  = InputCollect,
  OutputCollect = OutputCollect,
  select_model  = best_model_id,
  scenario      = "max_response",
  total_budget  = total_budget
)

print(BudgetAllocator$dt_optimOut)

# ── 7. SAVE MODEL ─────────────────────────────────────────────
robyn_save(
  InputCollect  = InputCollect,
  OutputCollect = OutputCollect,
  select_model  = best_model_id,
  json_file     = "outputs/company_a_robyn_model.json"
)

cat("✅ Model saved!\n")

