#' @import dplyr
#' @importFrom tibble tibble
#' @importFrom purrr walk2 map_lgl
#' @importFrom readr write_csv
#' @importFrom rlang .data

required_packages <- c("tibble", "dplyr", "purrr", "rlang")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop(
    "Required packages not installed: ",
    paste(missing_packages, collapse = ", "),
    "\nInstall with: install.packages(c(",
    paste0('"', missing_packages, '"', collapse = ", "),
    "))"
  )
}

#' Compare selective endometrial evaluation strategies before LeFort
#' colpocleisis with efficiency-frontier analysis
#'
#' @description
#' Runs a threshold-style expected-value decision analysis for selective
#' endometrial evaluation in women planning LeFort colpocleisis.
#'
#' Modeled strategies:
#' \itemize{
#'   \item no routine testing,
#'   \item selective TVUS,
#'   \item selective office Pipelle biopsy,
#'   \item selective concurrent D&C at surgery.
#' }
#'
#' The function computes:
#' \itemize{
#'   \item full strategy table,
#'   \item ICERs versus no testing,
#'   \item net monetary benefit,
#'   \item removal of duplicate and strongly dominated strategies,
#'   \item removal of extendedly dominated strategies,
#'   \item sequential ICERs on the efficiency frontier.
#' }
#'
#' @param surgery_count Numeric scalar. Total modeled cohort size.
#'   Default is 10000.
#' @param high_risk_fraction Numeric scalar between 0 and 1. Fraction
#'   classified as higher risk and therefore selectively tested.
#'   Default is 0.30.
#' @param high_risk_prevalence Numeric scalar between 0 and 1.
#'   Endometrial cancer prevalence in the higher-risk subgroup.
#'   Default is 0.0056.
#' @param low_risk_prevalence Numeric scalar between 0 and 1.
#'   Endometrial cancer prevalence in the lower-risk subgroup.
#'   Default is 0.0022.
#' @param baseline_capture Numeric scalar between 0 and 1. Baseline
#'   proportion of cancers detected without routine testing.
#'   Default is 0.10.
#' @param tvus_sensitivity Numeric scalar between 0 and 1. Default is
#'   0.941.
#' @param tvus_specificity Numeric scalar between 0 and 1. Default is
#'   0.668.
#' @param tvus_cost Numeric scalar. Per-patient TVUS cost. Default is
#'   125.23.
#' @param tvus_abnormal_workup_cost Numeric scalar. Cost of follow-up
#'   workup after an abnormal TVUS. Default is 172.55.
#' @param pipelle_conditional_sensitivity Numeric scalar between 0 and
#'   1. Sensitivity among adequate Pipelle samples. Default is 1.00.
#' @param pipelle_conditional_specificity Numeric scalar between 0 and
#'   1. Specificity among adequate Pipelle samples. Default is 0.98.
#' @param pipelle_inadequate_rate Numeric scalar between 0 and 1.
#'   Default is 0.291.
#' @param pipelle_cost Numeric scalar. Per-patient office Pipelle cost.
#'   Default is 172.55.
#' @param pipelle_false_positive_followup_cost Numeric scalar.
#'   Additional cost after a false-positive Pipelle. Default is 172.55.
#' @param pipelle_inadequate_followup_rate Numeric scalar between 0
#'   and 1. Fraction of inadequate Pipelles that proceed to further
#'   workup. Default is 0.50.
#' @param pipelle_inadequate_followup_cost Numeric scalar. Cost of
#'   follow-up workup after an inadequate Pipelle. Default is 2310.
#' @param pipelle_inadequate_followup_sensitivity Numeric scalar
#'   between 0 and 1. Sensitivity of follow-up workup after an
#'   inadequate Pipelle. Default is 0.88.
#' @param concurrent_dnc_sensitivity Numeric scalar between 0 and 1.
#'   Default is 0.88.
#' @param concurrent_dnc_specificity Numeric scalar between 0 and 1.
#'   Default is 0.984.
#' @param concurrent_dnc_incremental_cost Numeric scalar. Marginal
#'   cost of adding D&C to the LeFort case. Default is 800.
#' @param concurrent_dnc_effective_detection_credit Numeric scalar
#'   between 0 and 1. QALY credit for concurrent detection relative
#'   to true preoperative detection. Default is 0.50.
#' @param concurrent_dnc_false_positive_cost Numeric scalar.
#'   Additional cost of a false-positive concurrent D&C. Default is 0.
#' @param delayed_cancer_cost Numeric scalar. Cost of delayed cancer
#'   diagnosis. Default is 20000.
#' @param qaly_gain_early_detection Numeric scalar. QALY gain per
#'   fully early detection. Default is 0.10.
#' @param willingness_to_pay Numeric scalar. WTP threshold per QALY.
#'   Default is 100000.
#' @param output_dir Character scalar. Directory for optional CSV
#'   export. Default is `base::getwd()`.
#' @param save_csv Logical scalar. If `TRUE`, saves timestamped CSV
#'   files for both the full strategy table and the frontier table.
#'   Default is `FALSE`.
#'
#' @return
#' A named list with:
#' \describe{
#'   \item{strategy_table}{Full strategy comparison table.}
#'   \item{frontier_table}{Non-dominated frontier table with sequential
#'   ICERs.}
#'   \item{summary_sentence}{Dynamic summary sentence.}
#'   \item{strategy_csv_path}{Saved strategy CSV path, or
#'   `NA_character_`.}
#'   \item{frontier_csv_path}{Saved frontier CSV path, or
#'   `NA_character_`.}
#'   \item{assumptions}{Tibble of assumptions used.}
#' }
run_colpocleisis_selective_testing_model <- function(
  surgery_count = 10000,
  high_risk_fraction = 0.30,
  high_risk_prevalence = 0.0056,
  low_risk_prevalence = 0.0022,
  baseline_capture = 0.10,
  tvus_sensitivity = 0.941,
  tvus_specificity = 0.668,
  tvus_cost = 125.23,
  tvus_abnormal_workup_cost = 172.55,
  pipelle_conditional_sensitivity = 1.00,
  pipelle_conditional_specificity = 0.98,
  pipelle_inadequate_rate = 0.291,
  pipelle_cost = 172.55,
  pipelle_false_positive_followup_cost = 172.55,
  pipelle_inadequate_followup_rate = 0.50,
  pipelle_inadequate_followup_cost = 2310,
  pipelle_inadequate_followup_sensitivity = 0.88,
  concurrent_dnc_sensitivity = 0.88,
  concurrent_dnc_specificity = 0.984,
  concurrent_dnc_incremental_cost = 800,
  concurrent_dnc_effective_detection_credit = 0.50,
  concurrent_dnc_false_positive_cost = 0,
  delayed_cancer_cost = 20000,
  qaly_gain_early_detection = 0.10,
  willingness_to_pay = 100000,
  output_dir = base::getwd(),
  save_csv = FALSE
) {
  validate_probability <- function(numeric_value, value_name) {
    if (!base::is.numeric(numeric_value) ||
        length(numeric_value) != 1 ||
        base::is.na(numeric_value) ||
        numeric_value < 0 ||
        numeric_value > 1) {
      base::stop(value_name, " must be one number between 0 and 1.")
    }
  }

  validate_non_negative <- function(numeric_value, value_name) {
    if (!base::is.numeric(numeric_value) ||
        length(numeric_value) != 1 ||
        base::is.na(numeric_value) ||
        numeric_value < 0) {
      base::stop(value_name, " must be one non-negative number.")
    }
  }

  validate_positive <- function(numeric_value, value_name) {
    if (!base::is.numeric(numeric_value) ||
        length(numeric_value) != 1 ||
        base::is.na(numeric_value) ||
        numeric_value <= 0) {
      base::stop(value_name, " must be one positive number.")
    }
  }

  scalar_pull_chr <- function(table_name, strategy_name, column_name) {
    row_index <- base::which(table_name$strategy == strategy_name)

    if (length(row_index) != 1) {
      base::stop(
        "Expected exactly one row for strategy '",
        strategy_name,
        "'."
      )
    }

    if (!column_name %in% base::names(table_name)) {
      base::stop("Column '", column_name, "' not found in table.")
    }

    table_name[[column_name]][[row_index]]
  }

  remove_duplicate_or_weak_rows <- function(strategy_tbl) {
    strategy_tbl %>%
      dplyr::arrange(.data$total_cost, dplyr::desc(.data$qaly_gained)) %>%
      dplyr::group_by(.data$total_cost) %>%
      dplyr::slice_max(
        order_by = .data$qaly_gained,
        n = 1,
        with_ties = FALSE
      ) %>%
      dplyr::ungroup() %>%
      dplyr::arrange(.data$qaly_gained, .data$total_cost) %>%
      dplyr::group_by(.data$qaly_gained) %>%
      dplyr::slice_min(
        order_by = .data$total_cost,
        n = 1,
        with_ties = FALSE
      ) %>%
      dplyr::ungroup() %>%
      dplyr::arrange(.data$total_cost, .data$qaly_gained)
  }

  compute_sequential_icers <- function(frontier_candidate_tbl) {
    frontier_candidate_tbl %>%
      dplyr::arrange(.data$total_cost, .data$qaly_gained) %>%
      dplyr::mutate(
        incremental_cost_frontier = .data$total_cost -
          dplyr::lag(.data$total_cost),
        incremental_qaly_frontier = .data$qaly_gained -
          dplyr::lag(.data$qaly_gained),
        sequential_icer = dplyr::case_when(
          base::is.na(.data$incremental_qaly_frontier) ~ NA_real_,
          .data$incremental_qaly_frontier <= 0 ~ Inf,
          TRUE ~ .data$incremental_cost_frontier /
            .data$incremental_qaly_frontier
        )
      )
  }

  remove_strongly_dominated_strategies <- function(strategy_tbl) {
    candidate_tbl <- strategy_tbl %>%
      remove_duplicate_or_weak_rows() %>%
      dplyr::arrange(.data$total_cost, dplyr::desc(.data$qaly_gained))

    keep_indicator <- purrr::map_lgl(
      seq_len(nrow(candidate_tbl)),
      function(row_index) {
        current_cost <- candidate_tbl$total_cost[[row_index]]
        current_qaly <- candidate_tbl$qaly_gained[[row_index]]

        dominating_exists <- purrr::map_lgl(
          seq_len(nrow(candidate_tbl)),
          function(other_index) {
            if (other_index == row_index) {
              return(FALSE)
            }

            other_cost <- candidate_tbl$total_cost[[other_index]]
            other_qaly <- candidate_tbl$qaly_gained[[other_index]]

            lower_or_equal_cost <- other_cost <= current_cost
            higher_or_equal_qaly <- other_qaly >= current_qaly
            strictly_better_in_one <- (other_cost < current_cost) ||
              (other_qaly > current_qaly)

            lower_or_equal_cost &&
              higher_or_equal_qaly &&
              strictly_better_in_one
          }
        ) %>%
          any()

        !dominating_exists
      }
    )

    candidate_tbl %>%
      dplyr::mutate(on_frontier_strong = keep_indicator) %>%
      dplyr::filter(.data$on_frontier_strong) %>%
      dplyr::select(-.data$on_frontier_strong) %>%
      dplyr::arrange(.data$total_cost, .data$qaly_gained)
  }

  remove_extended_dominance <- function(frontier_candidate_tbl) {
    working_tbl <- frontier_candidate_tbl %>%
      dplyr::arrange(.data$total_cost, .data$qaly_gained)

    repeat {
      working_tbl <- compute_sequential_icers(working_tbl)

      if (nrow(working_tbl) <= 2) {
        break
      }

      removable_index <- NA_integer_

      for (row_index in seq(3, nrow(working_tbl))) {
        current_icer <- working_tbl$sequential_icer[[row_index]]
        prior_icer <- working_tbl$sequential_icer[[row_index - 1]]

        if (base::is.finite(current_icer) &&
            base::is.finite(prior_icer) &&
            current_icer < prior_icer) {
          removable_index <- row_index - 1
          break
        }
      }

      if (base::is.na(removable_index)) {
        break
      }

      working_tbl <- working_tbl[-removable_index, , drop = FALSE]
    }

    compute_sequential_icers(working_tbl)
  }

  build_efficiency_frontier <- function(strategy_tbl) {
    strategy_tbl %>%
      remove_strongly_dominated_strategies() %>%
      remove_extended_dominance()
  }

  base::message("Starting selective testing model with frontier analysis.")
  base::message("Logging inputs.")

  assumptions_tbl <- tibble::tibble(
    parameter = c(
      "surgery_count",
      "high_risk_fraction",
      "high_risk_prevalence",
      "low_risk_prevalence",
      "baseline_capture",
      "tvus_sensitivity",
      "tvus_specificity",
      "tvus_cost",
      "tvus_abnormal_workup_cost",
      "pipelle_conditional_sensitivity",
      "pipelle_conditional_specificity",
      "pipelle_inadequate_rate",
      "pipelle_cost",
      "pipelle_false_positive_followup_cost",
      "pipelle_inadequate_followup_rate",
      "pipelle_inadequate_followup_cost",
      "pipelle_inadequate_followup_sensitivity",
      "concurrent_dnc_sensitivity",
      "concurrent_dnc_specificity",
      "concurrent_dnc_incremental_cost",
      "concurrent_dnc_effective_detection_credit",
      "concurrent_dnc_false_positive_cost",
      "delayed_cancer_cost",
      "qaly_gain_early_detection",
      "willingness_to_pay"
    ),
    value = c(
      surgery_count,
      high_risk_fraction,
      high_risk_prevalence,
      low_risk_prevalence,
      baseline_capture,
      tvus_sensitivity,
      tvus_specificity,
      tvus_cost,
      tvus_abnormal_workup_cost,
      pipelle_conditional_sensitivity,
      pipelle_conditional_specificity,
      pipelle_inadequate_rate,
      pipelle_cost,
      pipelle_false_positive_followup_cost,
      pipelle_inadequate_followup_rate,
      pipelle_inadequate_followup_cost,
      pipelle_inadequate_followup_sensitivity,
      concurrent_dnc_sensitivity,
      concurrent_dnc_specificity,
      concurrent_dnc_incremental_cost,
      concurrent_dnc_effective_detection_credit,
      concurrent_dnc_false_positive_cost,
      delayed_cancer_cost,
      qaly_gain_early_detection,
      willingness_to_pay
    )
  )

  purrr::walk2(
    .x = assumptions_tbl$parameter,
    .y = assumptions_tbl$value,
    .f = ~ base::message("  ", .x, " = ", .y)
  )

  validate_probability(high_risk_fraction, "high_risk_fraction")
  validate_probability(high_risk_prevalence, "high_risk_prevalence")
  validate_probability(low_risk_prevalence, "low_risk_prevalence")

  if (high_risk_prevalence < low_risk_prevalence) {
    base::stop(
      "high_risk_prevalence (", high_risk_prevalence,
      ") must be >= low_risk_prevalence (", low_risk_prevalence,
      "). The high-risk subgroup should have equal or higher ",
      "cancer prevalence than the low-risk subgroup."
    )
  }
  validate_probability(baseline_capture, "baseline_capture")
  validate_probability(tvus_sensitivity, "tvus_sensitivity")
  validate_probability(tvus_specificity, "tvus_specificity")
  validate_probability(
    pipelle_conditional_sensitivity,
    "pipelle_conditional_sensitivity"
  )
  validate_probability(
    pipelle_conditional_specificity,
    "pipelle_conditional_specificity"
  )
  validate_probability(pipelle_inadequate_rate, "pipelle_inadequate_rate")
  validate_probability(
    pipelle_inadequate_followup_rate,
    "pipelle_inadequate_followup_rate"
  )
  validate_probability(
    pipelle_inadequate_followup_sensitivity,
    "pipelle_inadequate_followup_sensitivity"
  )
  validate_probability(
    concurrent_dnc_sensitivity,
    "concurrent_dnc_sensitivity"
  )
  validate_probability(
    concurrent_dnc_specificity,
    "concurrent_dnc_specificity"
  )
  validate_probability(
    concurrent_dnc_effective_detection_credit,
    "concurrent_dnc_effective_detection_credit"
  )

  validate_positive(surgery_count, "surgery_count")
  validate_non_negative(tvus_cost, "tvus_cost")
  validate_non_negative(
    tvus_abnormal_workup_cost,
    "tvus_abnormal_workup_cost"
  )
  validate_non_negative(pipelle_cost, "pipelle_cost")
  validate_non_negative(
    pipelle_false_positive_followup_cost,
    "pipelle_false_positive_followup_cost"
  )
  validate_non_negative(
    pipelle_inadequate_followup_cost,
    "pipelle_inadequate_followup_cost"
  )
  validate_non_negative(
    concurrent_dnc_incremental_cost,
    "concurrent_dnc_incremental_cost"
  )
  validate_non_negative(
    concurrent_dnc_false_positive_cost,
    "concurrent_dnc_false_positive_cost"
  )
  validate_non_negative(delayed_cancer_cost, "delayed_cancer_cost")
  validate_non_negative(
    qaly_gain_early_detection,
    "qaly_gain_early_detection"
  )
  validate_positive(willingness_to_pay, "willingness_to_pay")

  if (!base::dir.exists(output_dir) && isTRUE(save_csv)) {
    base::message("Creating output directory: ", output_dir)
    base::dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  base::message("Calculating cohort structure.")
  high_risk_count <- surgery_count * high_risk_fraction
  low_risk_count <- surgery_count - high_risk_count

  cancers_high_risk <- high_risk_count * high_risk_prevalence
  cancers_low_risk <- low_risk_count * low_risk_prevalence
  cancers_total <- cancers_high_risk + cancers_low_risk

  non_cancers_high_risk <- high_risk_count - cancers_high_risk

  baseline_detected_high_risk <- cancers_high_risk * baseline_capture
  baseline_detected_low_risk <- cancers_low_risk * baseline_capture
  baseline_detected_total <- baseline_detected_high_risk +
    baseline_detected_low_risk
  baseline_missed_total <- cancers_total - baseline_detected_total

  base::message(
    "  high_risk_count = ",
    format(round(high_risk_count, 2), big.mark = ",")
  )
  base::message(
    "  low_risk_count = ",
    format(round(low_risk_count, 2), big.mark = ",")
  )
  base::message(
    "  cancers_total = ",
    format(round(cancers_total, 2), big.mark = ",")
  )

  base::message("Calculating no testing arm.")
  detected_none_effective <- baseline_detected_total
  missed_none_true <- baseline_missed_total
  cost_none <- missed_none_true * delayed_cancer_cost
  qaly_none <- detected_none_effective * qaly_gain_early_detection

  base::message("Calculating selective TVUS arm.")
  tvus_true_positive_all <- cancers_high_risk * tvus_sensitivity

  tvus_incremental_detected_high_risk <- cancers_high_risk *
    (1 - baseline_capture) *
    tvus_sensitivity

  tvus_true_detected_total <- baseline_detected_total +
    tvus_incremental_detected_high_risk

  tvus_true_missed_total <- cancers_total - tvus_true_detected_total

  tvus_false_positive <- non_cancers_high_risk *
    (1 - tvus_specificity)

  tvus_abnormal_count <- tvus_true_positive_all + tvus_false_positive

  cost_tvus <- (high_risk_count * tvus_cost) +
    (tvus_abnormal_count * tvus_abnormal_workup_cost) +
    (tvus_true_missed_total * delayed_cancer_cost)

  qaly_tvus <- tvus_true_detected_total * qaly_gain_early_detection

  base::message(
    "  tvus_abnormal_count = ",
    format(round(tvus_abnormal_count, 2), big.mark = ",")
  )

  base::message("Calculating selective office Pipelle arm.")
  pipelle_adequate_rate <- 1 - pipelle_inadequate_rate

  pipelle_incremental_detected_direct <- cancers_high_risk *
    (1 - baseline_capture) *
    pipelle_adequate_rate *
    pipelle_conditional_sensitivity

  pipelle_inadequate_cancer_pool_incremental <- cancers_high_risk *
    (1 - baseline_capture) *
    pipelle_inadequate_rate

  pipelle_inadequate_cancer_pool_baseline <- cancers_high_risk *
    baseline_capture *
    pipelle_inadequate_rate

  pipelle_inadequate_cancer_pool_all <- pipelle_inadequate_cancer_pool_incremental +
    pipelle_inadequate_cancer_pool_baseline

  pipelle_detected_via_inadequate_followup <- pipelle_inadequate_cancer_pool_incremental *
    pipelle_inadequate_followup_rate *
    pipelle_inadequate_followup_sensitivity

  pipelle_true_detected_total <- baseline_detected_total +
    pipelle_incremental_detected_direct +
    pipelle_detected_via_inadequate_followup

  pipelle_true_missed_total <- cancers_total -
    pipelle_true_detected_total

  pipelle_false_positive <- non_cancers_high_risk *
    pipelle_adequate_rate *
    (1 - pipelle_conditional_specificity)

  pipelle_inadequate_non_cancer <- non_cancers_high_risk *
    pipelle_inadequate_rate

  pipelle_inadequate_followup_count <- (
    pipelle_inadequate_non_cancer + pipelle_inadequate_cancer_pool_all
  ) * pipelle_inadequate_followup_rate

  cost_pipelle <- (high_risk_count * pipelle_cost) +
    (pipelle_false_positive * pipelle_false_positive_followup_cost) +
    (pipelle_inadequate_followup_count *
       pipelle_inadequate_followup_cost) +
    (pipelle_true_missed_total * delayed_cancer_cost)

  qaly_pipelle <- pipelle_true_detected_total *
    qaly_gain_early_detection

  base::message(
    "  pipelle_inadequate_followup_count = ",
    format(round(pipelle_inadequate_followup_count, 2), big.mark = ",")
  )

  base::message("Calculating selective concurrent D&C arm.")
  dnc_incremental_true_detected_high_risk <- cancers_high_risk *
    (1 - baseline_capture) *
    concurrent_dnc_sensitivity

  dnc_true_detected_total <- baseline_detected_total +
    dnc_incremental_true_detected_high_risk

  dnc_true_missed_total <- cancers_total - dnc_true_detected_total

  dnc_false_positive <- non_cancers_high_risk *
    (1 - concurrent_dnc_specificity)

  dnc_effective_detected_total <- baseline_detected_total +
    (
      dnc_incremental_true_detected_high_risk *
        concurrent_dnc_effective_detection_credit
    )

  cost_dnc <- (high_risk_count * concurrent_dnc_incremental_cost) +
    (dnc_false_positive * concurrent_dnc_false_positive_cost) +
    (dnc_true_missed_total * delayed_cancer_cost)

  qaly_dnc <- dnc_effective_detected_total * qaly_gain_early_detection

  base::message(
    "  dnc_effective_detected_total = ",
    format(round(dnc_effective_detected_total, 2), big.mark = ",")
  )

  base::message("Assembling full strategy table.")
  strategy_table <- tibble::tibble(
    strategy = c(
      "no_testing",
      "selective_tvus",
      "selective_office_pipelle",
      "selective_concurrent_dnc"
    ),
    tested_count = c(
      0,
      high_risk_count,
      high_risk_count,
      high_risk_count
    ),
    cancers_total = c(
      cancers_total,
      cancers_total,
      cancers_total,
      cancers_total
    ),
    cancers_true_detected = c(
      baseline_detected_total,
      tvus_true_detected_total,
      pipelle_true_detected_total,
      dnc_true_detected_total
    ),
    cancers_effectively_early_detected = c(
      detected_none_effective,
      tvus_true_detected_total,
      pipelle_true_detected_total,
      dnc_effective_detected_total
    ),
    cancers_true_missed = c(
      missed_none_true,
      tvus_true_missed_total,
      pipelle_true_missed_total,
      dnc_true_missed_total
    ),
    false_positive_tests = c(
      0,
      tvus_false_positive,
      pipelle_false_positive,
      dnc_false_positive
    ),
    cost_testing = c(
      0,
      high_risk_count * tvus_cost,
      high_risk_count * pipelle_cost,
      high_risk_count * concurrent_dnc_incremental_cost
    ),
    cost_followup = c(
      0,
      tvus_abnormal_count * tvus_abnormal_workup_cost,
      (pipelle_false_positive *
         pipelle_false_positive_followup_cost) +
        (pipelle_inadequate_followup_count *
           pipelle_inadequate_followup_cost),
      dnc_false_positive * concurrent_dnc_false_positive_cost
    ),
    cost_delayed_cancer = c(
      missed_none_true * delayed_cancer_cost,
      tvus_true_missed_total * delayed_cancer_cost,
      pipelle_true_missed_total * delayed_cancer_cost,
      dnc_true_missed_total * delayed_cancer_cost
    ),
    total_cost = c(
      cost_none,
      cost_tvus,
      cost_pipelle,
      cost_dnc
    ),
    qaly_gained = c(
      qaly_none,
      qaly_tvus,
      qaly_pipelle,
      qaly_dnc
    )
  ) %>%
    dplyr::mutate(
      no_testing_cost = scalar_pull_chr(
        .,
        "no_testing",
        "total_cost"
      ),
      no_testing_qaly = scalar_pull_chr(
        .,
        "no_testing",
        "qaly_gained"
      ),
      incremental_cost_vs_none = .data$total_cost - .data$no_testing_cost,
      incremental_qaly_vs_none = .data$qaly_gained - .data$no_testing_qaly,
      icer_vs_none = dplyr::case_when(
        .data$strategy == "no_testing" ~ NA_real_,
        .data$incremental_qaly_vs_none <= 0 ~ Inf,
        TRUE ~ .data$incremental_cost_vs_none /
          .data$incremental_qaly_vs_none
      ),
      net_monetary_benefit = (
        .data$qaly_gained * willingness_to_pay
      ) - .data$total_cost,
      cost_effective_vs_none = dplyr::case_when(
        .data$strategy == "no_testing" ~ TRUE,
        !base::is.finite(.data$icer_vs_none) ~ FALSE,
        .data$icer_vs_none <= willingness_to_pay ~ TRUE,
        TRUE ~ FALSE
      )
    ) %>%
    dplyr::select(-.data$no_testing_cost, -.data$no_testing_qaly) %>%
    dplyr::arrange(dplyr::desc(.data$net_monetary_benefit), .data$total_cost)

  base::message("Building efficiency frontier.")
  frontier_table <- build_efficiency_frontier(strategy_table) %>%
    dplyr::select(
      -.data$incremental_cost_vs_none,
      -.data$incremental_qaly_vs_none,
      -.data$icer_vs_none,
      -.data$net_monetary_benefit,
      -.data$cost_effective_vs_none
    ) %>%
    dplyr::mutate(
      frontier_net_monetary_benefit = (
        .data$qaly_gained * willingness_to_pay
      ) - .data$total_cost,
      frontier_transition_cost_effective = dplyr::case_when(
        base::is.na(.data$sequential_icer) ~ TRUE,
        !base::is.finite(.data$sequential_icer) ~ FALSE,
        .data$sequential_icer <= willingness_to_pay ~ TRUE,
        TRUE ~ FALSE
      ),
      frontier_path_cost_effective = base::unlist(base::Reduce(
        f = function(previous_value, current_value) {
          previous_value && current_value
        },
        x = .data$frontier_transition_cost_effective,
        accumulate = TRUE
      ))
    )

  preferred_strategy_nmb <- strategy_table %>%
    dplyr::arrange(
      dplyr::desc(.data$net_monetary_benefit),
      .data$total_cost
    ) %>%
    dplyr::slice(1) %>%
    dplyr::pull(.data$strategy)

  frontier_ce_count <- frontier_table %>%
    dplyr::filter(.data$frontier_path_cost_effective) %>%
    nrow()

  if (frontier_ce_count == 0) {
    preferred_strategy_frontier <- NA_character_
  } else {
    preferred_strategy_frontier <- frontier_table %>%
      dplyr::filter(.data$frontier_path_cost_effective) %>%
      dplyr::arrange(.data$total_cost, .data$qaly_gained) %>%
      dplyr::slice_tail(n = 1) %>%
      dplyr::pull(.data$strategy)
  }

  tvus_gain_vs_none <- scalar_pull_chr(
    strategy_table,
    "selective_tvus",
    "cancers_effectively_early_detected"
  ) - scalar_pull_chr(
    strategy_table,
    "no_testing",
    "cancers_effectively_early_detected"
  )

  pipelle_gain_vs_none <- scalar_pull_chr(
    strategy_table,
    "selective_office_pipelle",
    "cancers_effectively_early_detected"
  ) - scalar_pull_chr(
    strategy_table,
    "no_testing",
    "cancers_effectively_early_detected"
  )

  dnc_gain_vs_none <- scalar_pull_chr(
    strategy_table,
    "selective_concurrent_dnc",
    "cancers_effectively_early_detected"
  ) - scalar_pull_chr(
    strategy_table,
    "no_testing",
    "cancers_effectively_early_detected"
  )

  summary_sentence <- paste0(
    "In this modeled cohort of ",
    format(surgery_count, big.mark = ","),
    " women undergoing LeFort colpocleisis, the strategy with the ",
    "highest net monetary benefit at a willingness-to-pay threshold ",
    "of $",
    format(willingness_to_pay, big.mark = ","),
    " per QALY was ",
    preferred_strategy_nmb,
    ". On formal efficiency-frontier analysis, the preferred ",
    "non-dominated strategy was ",
    preferred_strategy_frontier,
    ". Compared with no testing, selective TVUS yielded ",
    format(round(tvus_gain_vs_none, 2), big.mark = ","),
    " additional effective early detections, selective office Pipelle ",
    "yielded ",
    format(round(pipelle_gain_vs_none, 2), big.mark = ","),
    ", and selective concurrent D&C yielded ",
    format(round(dnc_gain_vs_none, 2), big.mark = ","),
    "."
  )

  base::message("Dynamic summary sentence:")
  base::message("  ", summary_sentence)

  strategy_csv_path <- NA_character_
  frontier_csv_path <- NA_character_

  if (isTRUE(save_csv)) {
    timestamp_value <- format(base::Sys.time(), "%Y%m%d_%H%M%S")

    strategy_csv_path <- file.path(
      output_dir,
      paste0(
        "colpocleisis_selective_testing_strategy_table_",
        timestamp_value,
        ".csv"
      )
    )

    frontier_csv_path <- file.path(
      output_dir,
      paste0(
        "colpocleisis_selective_testing_frontier_table_",
        timestamp_value,
        ".csv"
      )
    )

    base::message("Saving strategy table to: ", strategy_csv_path)
    readr::write_csv(strategy_table, strategy_csv_path)

    base::message("Saving frontier table to: ", frontier_csv_path)
    readr::write_csv(frontier_table, frontier_csv_path)
  }

  base::message("Model complete.")
  base::message("Full strategy rows: ", nrow(strategy_table))
  base::message("Frontier rows: ", nrow(frontier_table))

  return(
    list(
      strategy_table = strategy_table,
      frontier_table = frontier_table,
      summary_sentence = summary_sentence,
      strategy_csv_path = strategy_csv_path,
      frontier_csv_path = frontier_csv_path,
      assumptions = assumptions_tbl
    )
  )
}
