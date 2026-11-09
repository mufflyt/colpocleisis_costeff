#' Shared screening decision model with procedure-specific consequences
#'
#' This is a transparent expected-value research scaffold, not a
#' clinically calibrated cost-effectiveness model.
#'
#' @param procedures One row per procedure and pathology state, with
#'   procedure, pathology, post_detection_prob, cost_pre,
#'   cost_post, cost_missed, qaly_pre, qaly_post, qaly_missed.
#' @param screening One row per strategy, with strategy,
#'   sensitivity_ein, sensitivity_cancer, specificity,
#'   testing_cost, positive_followup_cost, false_positive_cost.
#'   Sensitivities are for the full prespecified screening pathway.
#' @param prevalence Named numeric vector: ein, cancer.
#' @param surgery_count Hypothetical number undergoing each procedure.
#' @param willingness_to_pay Dollars per incremental QALY.
#' @return Tibble of expected outcomes by procedure and strategy.
run_shared_preop_screening_model <- function(
  procedures,
  screening,
  prevalence,
  surgery_count = 10000,
  willingness_to_pay = 100000
) {
  base::message("Validating procedure, screening, and prevalence inputs.")
  required_procedure <- c(
    "procedure", "pathology", "post_detection_prob", "cost_pre",
    "cost_post", "cost_missed", "qaly_pre", "qaly_post",
    "qaly_missed"
  )
  required_screen <- c(
    "strategy", "sensitivity_ein", "sensitivity_cancer",
    "specificity", "testing_cost", "positive_followup_cost",
    "false_positive_cost"
  )
  if (!base::is.data.frame(procedures) ||
      !base::all(required_procedure %in% base::names(procedures))) {
    base::stop("procedures lacks required columns.")
  }
  if (!base::is.data.frame(screening) ||
      !base::all(required_screen %in% base::names(screening))) {
    base::stop("screening lacks required columns.")
  }
  if (!base::identical(base::sort(base::names(prevalence)),
                       c("cancer", "ein"))) {
    base::stop("prevalence must be named c(ein=..., cancer=...).")
  }
  if (base::anyNA(procedures) || base::anyNA(screening) ||
      base::anyNA(prevalence)) {
    base::stop(
      "Unpopulated assumptions: fill every input before computing."
    )
  }
  probabilities <- c(
    prevalence, procedures$post_detection_prob,
    screening$sensitivity_ein, screening$sensitivity_cancer,
    screening$specificity
  )
  if (base::any(!base::is.finite(probabilities)) ||
      base::any(probabilities < 0 | probabilities > 1) ||
      base::sum(prevalence) > 1) {
    base::stop("All probabilities must be in [0,1], and total <= 1.")
  }
  numeric_values <- c(
    procedures$cost_pre, procedures$cost_post,
    procedures$cost_missed, screening$testing_cost,
    screening$positive_followup_cost,
    screening$false_positive_cost
  )
  if (base::any(!base::is.finite(numeric_values)) ||
      base::any(numeric_values < 0)) {
    base::stop("All cost parameters must be finite and nonnegative.")
  }
  if (base::any(!base::is.finite(
    c(procedures$qaly_pre, procedures$qaly_post,
      procedures$qaly_missed)
  ))) {
    base::stop("All QALY values must be finite.")
  }
  if (!base::is.numeric(surgery_count) ||
      base::length(surgery_count) != 1 ||
      !base::is.finite(surgery_count) || surgery_count <= 0 ||
      !base::is.finite(willingness_to_pay) ||
      willingness_to_pay < 0) {
    base::stop("Invalid cohort size or willingness-to-pay.")
  }
  procedure_ids <- base::unique(procedures$procedure)
  if (base::anyDuplicated(procedures[c("procedure", "pathology")]) ||
      base::anyDuplicated(screening$strategy) ||
      !base::all(procedures$pathology %in% c("ein", "cancer"))) {
    base::stop("Duplicate identifiers or invalid pathology category.")
  }
  for (procedure_id in procedure_ids) {
    pathology_ids <- procedures$pathology[
      procedures$procedure == procedure_id
    ]
    if (!base::setequal(pathology_ids, c("ein", "cancer"))) {
      base::stop("Each procedure requires EIN and cancer rows.")
    }
  }
  no_screen <- screening |>
    dplyr::filter(.data$strategy == "no_screen")
  if (base::nrow(no_screen) != 1 ||
      no_screen$sensitivity_ein != 0 ||
      no_screen$sensitivity_cancer != 0 ||
      no_screen$specificity != 1 ||
      no_screen$testing_cost != 0 ||
      no_screen$positive_followup_cost != 0 ||
      no_screen$false_positive_cost != 0) {
    base::stop("Provide a zero-cost, zero-detection no_screen row.")
  }
  base::message("Expanding every screening strategy across procedures.")
  scenario_grid <- tidyr::crossing(
    procedure = procedure_ids,
    screening
  )
  pathology_grid <- tidyr::crossing(
    scenario_grid,
    pathology = c("ein", "cancer")
  ) |>
    dplyr::left_join(
      procedures, by = c("procedure", "pathology")
    ) |>
    dplyr::mutate(
      prevalence_pathology = dplyr::if_else(
        .data$pathology == "ein",
        unname(prevalence[["ein"]]),
        unname(prevalence[["cancer"]])
      ),
      sensitivity = dplyr::if_else(
        .data$pathology == "ein",
        .data$sensitivity_ein, .data$sensitivity_cancer
      ),
      cases = surgery_count * .data$prevalence_pathology,
      detected_pre = .data$cases * .data$sensitivity,
      not_detected_pre = .data$cases - .data$detected_pre,
      detected_post = .data$not_detected_pre *
        .data$post_detection_prob,
      not_detected_post = .data$not_detected_pre -
        .data$detected_post,
      disease_cost = .data$detected_pre * .data$cost_pre +
        .data$detected_post * .data$cost_post +
        .data$not_detected_post * .data$cost_missed,
      disease_qaly = .data$detected_pre * .data$qaly_pre +
        .data$detected_post * .data$qaly_post +
        .data$not_detected_post * .data$qaly_missed,
      true_positive_followup_cost = .data$detected_pre *
        .data$positive_followup_cost
    )
  base::message("Aggregating expected disease and testing outcomes.")
  disease_summary <- pathology_grid |>
    dplyr::group_by(.data$procedure, .data$strategy) |>
    dplyr::summarise(
      expected_pre_detections = base::sum(.data$detected_pre),
      expected_post_detections = base::sum(.data$detected_post),
      expected_undetected = base::sum(.data$not_detected_post),
      disease_cost = base::sum(.data$disease_cost),
      disease_qaly = base::sum(.data$disease_qaly),
      positive_workup_cost =
        base::sum(.data$true_positive_followup_cost),
      .groups = "drop"
    )
  comparison_table <- scenario_grid |>
    dplyr::left_join(
      disease_summary, by = c("procedure", "strategy")
    ) |>
    dplyr::mutate(
      expected_false_positives =
        surgery_count * (1 - base::sum(prevalence)) *
        (1 - .data$specificity),
      screening_cost = surgery_count * .data$testing_cost,
      false_positive_cost = .data$expected_false_positives *
        .data$false_positive_cost,
      total_cost = .data$disease_cost + .data$screening_cost +
        .data$positive_workup_cost + .data$false_positive_cost,
      total_qaly = .data$disease_qaly,
      nmb = willingness_to_pay * .data$total_qaly -
        .data$total_cost
    ) |>
    dplyr::group_by(.data$procedure) |>
    dplyr::mutate(
      incremental_cost = .data$total_cost -
        .data$total_cost[.data$strategy == "no_screen"],
      incremental_qaly = .data$total_qaly -
        .data$total_qaly[.data$strategy == "no_screen"],
      incremental_nmb = .data$nmb -
        .data$nmb[.data$strategy == "no_screen"]
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$procedure,
      dplyr::desc(.data$nmb)
    )
  base::message(
    "Model complete: ", base::nrow(comparison_table),
    " procedure-strategy combinations."
  )
  return(comparison_table)
}

#' Create required inputs without inventing evidence-based values
#'
#' All clinical downstream inputs are NA on purpose. Complete and
#' validate them against evidence or explicit expert elicitation.
make_shared_preop_screening_inputs <- function() {
  procedure_ids <- c(
    "tvh_usls", "usls_hysteropexy", "ssls_hysteropexy",
    "tlh_scp", "sch_scp", "sacral_hysteropexy"
  )
  procedure_inputs <- tidyr::crossing(
    procedure = procedure_ids,
    pathology = c("ein", "cancer")
  ) |>
    dplyr::mutate(
      post_detection_prob = NA_real_,
      cost_pre = NA_real_,
      cost_post = NA_real_,
      cost_missed = NA_real_,
      qaly_pre = NA_real_,
      qaly_post = NA_real_,
      qaly_missed = NA_real_
    )
  screening_inputs <- tibble::tibble(
    strategy = c("no_screen", "tvus_pathway", "biopsy_pathway"),
    sensitivity_ein = c(0, NA_real_, NA_real_),
    sensitivity_cancer = c(0, NA_real_, NA_real_),
    specificity = c(1, NA_real_, NA_real_),
    testing_cost = c(0, NA_real_, NA_real_),
    positive_followup_cost = c(0, NA_real_, NA_real_),
    false_positive_cost = c(0, NA_real_, NA_real_)
  )
  base::message(
    "Created blank clinical parameter tables for 6 procedures."
  )
  return(base::list(
    procedures = procedure_inputs,
    screening = screening_inputs,
    prevalence = c(ein = NA_real_, cancer = NA_real_)
  ))
}
