# Structural smoke tests. All parameter values here are illustrative.
# They are NOT estimates and MUST NOT be reported as research findings.
base::source("R/shared_preop_screening_model.R")
model_inputs <- make_shared_preop_screening_inputs()

model_inputs$prevalence <- c(ein = 0.003, cancer = 0.005)
model_inputs$procedures$post_detection_prob <- 0.70
model_inputs$procedures$cost_pre <- 5000
model_inputs$procedures$cost_post <- 12000
model_inputs$procedures$cost_missed <- 15000
model_inputs$procedures$qaly_pre <- 0
model_inputs$procedures$qaly_post <- -0.03
model_inputs$procedures$qaly_missed <- -0.06

screened_rows <- model_inputs$screening$strategy != "no_screen"
model_inputs$screening$sensitivity_ein[screened_rows] <- 0.75
model_inputs$screening$sensitivity_cancer[screened_rows] <- 0.90
model_inputs$screening$specificity[screened_rows] <- 0.90
model_inputs$screening$testing_cost[screened_rows] <- 150
model_inputs$screening$positive_followup_cost[screened_rows] <- 250
model_inputs$screening$false_positive_cost[screened_rows] <- 500
model_inputs$screening$testing_qaly_loss[screened_rows] <- 0.00001
model_inputs$screening$false_positive_qaly_loss[screened_rows] <- 0.001

base::message("Checking equal parameters give equal outputs.")
comparison_table <- run_shared_preop_screening_model(
  procedures = model_inputs$procedures,
  screening = model_inputs$screening,
  prevalence = model_inputs$prevalence
)

base::stopifnot(base::nrow(comparison_table) == 18)
per_strategy <- comparison_table |>
  dplyr::group_by(.data$strategy) |>
  dplyr::summarise(
    unique_cost = dplyr::n_distinct(.data$total_cost),
    unique_qaly = dplyr::n_distinct(.data$total_qaly),
    .groups = "drop"
  )
base::stopifnot(base::all(per_strategy$unique_cost == 1))
base::stopifnot(base::all(per_strategy$unique_qaly == 1))

base::message("Checking changes to post-op costs affect only chosen arm.")
alternative_inputs <- model_inputs
changed_arm <- alternative_inputs$procedures$procedure == "sch_scp"
alternative_inputs$procedures$cost_post[changed_arm] <- 20000

changed_table <- run_shared_preop_screening_model(
  procedures = alternative_inputs$procedures,
  screening = alternative_inputs$screening,
  prevalence = alternative_inputs$prevalence
)

unchanged_table <- comparison_table |>
  dplyr::filter(.data$procedure == "tvh_usls") |>
  dplyr::arrange(.data$strategy)
unchanged_new <- changed_table |>
  dplyr::filter(.data$procedure == "tvh_usls") |>
  dplyr::arrange(.data$strategy)
base::stopifnot(base::isTRUE(base::all.equal(
  unchanged_table$total_cost, unchanged_new$total_cost
)))
base::stopifnot(base::isTRUE(base::all.equal(
  unchanged_table$total_qaly, unchanged_new$total_qaly
)))

sch_base <- comparison_table |>
  dplyr::filter(.data$procedure == "sch_scp")
sch_new <- changed_table |>
  dplyr::filter(.data$procedure == "sch_scp")
base::stopifnot(base::all(sch_new$total_cost > sch_base$total_cost))

base::message("Checking missing assumptions are rejected.")
blank_inputs <- make_shared_preop_screening_inputs()
bad_attempt <- base::try(
  run_shared_preop_screening_model(
    procedures = blank_inputs$procedures,
    screening = blank_inputs$screening,
    prevalence = blank_inputs$prevalence
  ),
  silent = TRUE
)
base::stopifnot(base::inherits(bad_attempt, "try-error"))
base::message("All structural checks passed.")
