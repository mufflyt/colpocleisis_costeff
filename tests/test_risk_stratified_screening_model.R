# Adversarial synthetic tests; do not treat numbers as clinical evidence.
base::source("R/risk_stratified_screening_model.R")
base::source("R/shared_preop_screening_model.R")
inputs <- make_risk_stratified_screening_inputs()
inputs$procedures$post_detection_prob <- 0.5
inputs$procedures$cost_pre <- 100
inputs$procedures$cost_post <- 200
inputs$procedures$cost_missed <- 300
inputs$procedures$qaly_pre <- 0
inputs$procedures$qaly_post <- -0.01
inputs$procedures$qaly_missed <- -0.02

inputs$risk_groups$proportion <- c(0.75, 0.25)
inputs$risk_groups$prevalence_ein <- c(0.001, 0.01)
inputs$risk_groups$prevalence_cancer <- c(0.002, 0.02)
inputs$policies$sensitivity_ein <- 0.8
inputs$policies$sensitivity_cancer <- 0.9
inputs$policies$specificity <- 0.95
inputs$policies$inadequate_rate <- 0.2
inputs$policies$followup_fraction <- 0.5
inputs$policies$followup_sensitivity_ein <- 0.9
inputs$policies$followup_sensitivity_cancer <- 0.95
inputs$policies$followup_specificity <- 0.99
inputs$policies$initial_test_cost <- 100
inputs$policies$inadequate_followup_cost <- 200
inputs$policies$positive_workup_cost <- 50
inputs$policies$false_positive_cost <- 80
inputs$policies$test_qaly_loss <- 0.00001
inputs$policies$inadequate_followup_qaly_loss <- 0.00002
inputs$policies$false_positive_qaly_loss <- 0.0001
inputs$policies$test_fraction <- dplyr::case_when(
  inputs$policies$policy == "no_screen" ~ 0,
  inputs$policies$policy == "selective_tvus" &
    inputs$policies$risk_group == "average" ~ 0,
  inputs$policies$policy == "selective_biopsy" &
    inputs$policies$risk_group == "average" ~ 0,
  TRUE ~ 1
)

run_model <- function(values) {
  run_risk_stratified_screening_model(
    procedures = values$procedures,
    policies = values$policies,
    risk_groups = values$risk_groups,
    surgery_count = 10000
  )
}
base::message("Testing basic branch conservation.")
bundle <- run_model(inputs)
base::stopifnot(
  base::nrow(bundle$comparison) == 30,
  base::all(base::abs(
    bundle$branch_audit$cases -
      bundle$branch_audit$detected_pre -
      bundle$branch_audit$detected_post -
      bundle$branch_audit$missed_at_horizon
  ) < 1e-8)
)
base::message("Checking test counts per policy.")
sch <- bundle$comparison |>
  dplyr::filter(.data$procedure == "sch_scp")
get_metric <- function(key, metric = "tested", tbl = sch) {
  tbl[[metric]][tbl$policy == key]
}
base::stopifnot(
  get_metric("no_screen") == 0,
  get_metric("selective_tvus") == 2500,
  get_metric("routine_tvus") == 10000,
  get_metric("selective_biopsy") == 2500,
  get_metric("universal_biopsy") == 10000,
  get_metric("selective_tvus", "detected_pre") <
    get_metric("routine_tvus", "detected_pre")
)
base::message("Checking inadequate sampling creates follow-up only.")
base::stopifnot(
  get_metric("routine_tvus", "inadequate") == 2000,
  get_metric("routine_tvus", "followed_up") == 1000,
  get_metric("no_screen", "false_positives") == 0
)
base::message("Checking zero coverage matches no-screen comparator.")
zero <- inputs
zero$policies$test_fraction[zero$policies$policy != "no_screen"] <- 0
zero_bundle <- run_model(zero)
zero_sch <- zero_bundle$comparison |>
  dplyr::filter(.data$procedure == "sch_scp")
base::stopifnot(
  base::all(base::abs(
    zero_sch$total_cost - zero_sch$total_cost[
      zero_sch$policy == "no_screen"
    ]
  ) < 1e-8),
  base::all(base::abs(
    zero_sch$total_qaly - zero_sch$total_qaly[
      zero_sch$policy == "no_screen"
    ]
  ) < 1e-8)
)
base::message("Checking identical strata, all tested, equal policies.")
same <- inputs
same$risk_groups$prevalence_ein <- 0.004
same$risk_groups$prevalence_cancer <- 0.006
same$policies$test_fraction[
  same$policies$policy == "selective_tvus"
] <- 1
same_bundle <- run_model(same)
same_sch <- same_bundle$comparison |>
  dplyr::filter(.data$procedure == "sch_scp")
base::stopifnot(base::isTRUE(base::all.equal(
  get_metric("selective_tvus", "total_cost", same_sch),
  get_metric("routine_tvus", "total_cost", same_sch)
)))
base::message("Checking procedure-specific consequences are isolated.")
changed <- inputs
changed$procedures$cost_post[
  changed$procedures$procedure == "sch_scp"
] <- 5000
changed_bundle <- run_model(changed)
unmodified <- bundle$comparison |>
  dplyr::filter(.data$procedure == "tvh_usls") |>
  dplyr::arrange(.data$policy)
modified <- changed_bundle$comparison |>
  dplyr::filter(.data$procedure == "tvh_usls") |>
  dplyr::arrange(.data$policy)
base::stopifnot(base::identical(
  unmodified$total_cost, modified$total_cost
))
base::message("Checking invalid stratum prevalence is rejected.")
bad <- inputs
bad$risk_groups$prevalence_ein[1] <- 1
base::stopifnot(base::inherits(
  base::try(run_model(bad), silent = TRUE), "try-error"
))
base::message("Checking incomplete policy coverage is rejected.")
bad <- inputs
bad$policies <- bad$policies[-1, ]
base::stopifnot(base::inherits(
  base::try(run_model(bad), silent = TRUE), "try-error"
))
base::message("Checking negative costs are rejected.")
bad <- inputs
bad$policies$initial_test_cost[1] <- -1
base::stopifnot(base::inherits(
  base::try(run_model(bad), silent = TRUE), "try-error"
))
base::message("Risk-stratified structural tests passed.")
