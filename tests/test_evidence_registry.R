# Registry evidence smoke tests; no source is a clinical base-case value.
base::source("R/evidence_registry.R")
evidence <- read_screening_evidence_registry()

base::message("Checking study counts and exact 95% intervals.")
base::stopifnot(base::nrow(evidence$study_counts) >= 19)
base::stopifnot(base::nrow(evidence$registry) >= 33)
base::stopifnot(base::all(
  evidence$study_counts$ci_lower <=
    evidence$study_counts$point_estimate
))
base::stopifnot(base::all(
  evidence$study_counts$ci_upper >=
    evidence$study_counts$point_estimate
))

cancer_row <- evidence$study_counts |>
  dplyr::filter(
    .data$study_id == "gruner2025",
    .data$outcome == "invasive_ec"
  )
base::stopifnot(base::nrow(cancer_row) == 1)
base::stopifnot(cancer_row$events == 30)
base::stopifnot(cancer_row$denominator == 5376)
base::stopifnot(base::abs(
  cancer_row$ci_lower - 0.003768117
) < 1e-7)
base::stopifnot(base::abs(
  cancer_row$ci_upper - 0.007956798
) < 1e-7)

staging_row <- evidence$study_counts |>
  dplyr::filter(
    .data$study_id == "gruner2025",
    .data$outcome == "additional_staging_given_incidental_ec"
  )
base::stopifnot(base::abs(
  staging_row$point_estimate - 1 / 3
) < 1e-10)

sch_row <- evidence$study_counts |>
  dplyr::filter(
    .data$study_id == "sch_combined",
    .data$outcome == "trachelectomy_given_incidental_ec"
  )
base::stopifnot(base::abs(
  sch_row$ci_lower - 0.094299324
) < 1e-7)
base::stopifnot(base::abs(
  sch_row$ci_upper - 0.991596241
) < 1e-7)

base::message("Checking provisional scenarios retain source labels.")
scenarios <- get_provisional_prevalence_scenarios(evidence)
base::stopifnot(base::nrow(scenarios) == 2)
base::stopifnot(base::all(
  base::grepl("provisional", scenarios$evidence_status)
))
base::stopifnot(base::all(
  scenarios$point_estimate >= scenarios$lower_bound
))
base::stopifnot(base::all(
  scenarios$point_estimate <= scenarios$upper_bound
))

base::message("Checking that registry loads do not fill model inputs.")
base::source("R/shared_preop_screening_model.R")
blank_inputs <- make_shared_preop_screening_inputs()
base::stopifnot(base::all(base::is.na(blank_inputs$prevalence)))
base::stopifnot(base::all(base::is.na(
  blank_inputs$procedures$post_detection_prob
)))
base::message("All registry evidence smoke tests passed.")
