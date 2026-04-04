library(tibble)
library(dplyr)
library(purrr)
library(readr)

source("colpocleisis_selective_testing_model.R")

strategy_bundle <- run_colpocleisis_selective_testing_model(
  surgery_count = 10000,
  save_csv = TRUE,
  output_dir = "output"
)

cat("\n=== Strategy Table ===\n")
print(strategy_bundle$strategy_table)

cat("\n=== Efficiency Frontier ===\n")
print(strategy_bundle$frontier_table)

cat("\n=== Summary ===\n")
cat(strategy_bundle$summary_sentence, "\n")

cat("\n=== Assumptions ===\n")
print(strategy_bundle$assumptions)
