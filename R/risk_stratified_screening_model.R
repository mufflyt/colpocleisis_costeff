#' Model risk-stratified preoperative endometrial screening
#'
#' This implementation is a research scaffold, not a calibrated CEA.
#' It represents an initial test, insufficient samples, conditional
#' follow-up, and procedure-specific consequences of detection timing.
#'
#' @param procedures Required columns: procedure, pathology,
#'   post_detection_prob, cost_pre, cost_post, cost_missed,
#'   qaly_pre, qaly_post, qaly_missed.
#' @param risk_groups One row per stratum: risk_group, proportion,
#'   prevalence_ein, prevalence_cancer.
#' @param policies One row per policy and risk stratum: policy,
#'   risk_group, test_fraction, sensitivity_ein, sensitivity_cancer,
#'   specificity, inadequate_rate, followup_fraction,
#'   followup_sensitivity_ein, followup_sensitivity_cancer,
#'   followup_specificity, initial_test_cost, inadequate_followup_cost,
#'   positive_workup_cost, false_positive_cost, test_qaly_loss,
#'   inadequate_followup_qaly_loss, false_positive_qaly_loss.
#'   Sensitivity and specificity refer to adequate initial tests.
#'   Follow-up characteristics refer to insufficient samples.
#' @param surgery_count Number of patients per procedure.
#' @param willingness_to_pay Dollars per QALY.
#' @return List with per-procedure policy totals and branch audit table.
run_risk_stratified_screening_model <- function(
  procedures,
  risk_groups,
  policies,
  surgery_count = 10000,
  willingness_to_pay = 100000
) {
  base::message("Validating risk groups, policy branches, and procedures.")
  req_risk <- c(
    "risk_group", "proportion", "prevalence_ein",
    "prevalence_cancer"
  )
  req_policy <- c(
    "policy", "risk_group", "test_fraction",
    "sensitivity_ein", "sensitivity_cancer",
    "specificity", "inadequate_rate", "followup_fraction",
    "followup_sensitivity_ein", "followup_sensitivity_cancer",
    "followup_specificity", "initial_test_cost",
    "inadequate_followup_cost", "positive_workup_cost",
    "false_positive_cost", "test_qaly_loss",
    "inadequate_followup_qaly_loss",
    "false_positive_qaly_loss"
  )
  req_proc <- c(
    "procedure", "pathology", "post_detection_prob",
    "cost_pre", "cost_post", "cost_missed",
    "qaly_pre", "qaly_post", "qaly_missed"
  )
  for (entry in base::list(
    base::list(value = procedures, cols = req_proc),
    base::list(value = risk_groups, cols = req_risk),
    base::list(value = policies, cols = req_policy)
  )) {
    if (!base::is.data.frame(entry$value) ||
        !base::all(entry$cols %in% base::names(entry$value))) {
      base::stop("A model input lacks required columns.")
    }
    if (base::nrow(entry$value) == 0L ||
        base::anyNA(entry$value[, entry$cols, drop = FALSE])) {
      base::stop("Blank or missing input values are prohibited.")
    }
  }
  if (base::anyDuplicated(risk_groups$risk_group) ||
      base::anyDuplicated(policies[c("policy", "risk_group")]) ||
      base::anyDuplicated(procedures[c("procedure", "pathology")])) {
    base::stop("Duplicate risk, policy-stratum, or procedure-state key.")
  }
  if (!base::setequal(procedures$pathology, c("ein", "cancer"))) {
    base::stop("Allowed pathology types are EIN and cancer.")
  }
  for (id in base::unique(procedures$procedure)) {
    if (!base::setequal(
      procedures$pathology[procedures$procedure == id],
      c("ein", "cancer")
    )) {
      base::stop("Each procedure needs EIN and cancer branches.")
    }
  }
  expected_keys <- tidyr::crossing(
    policy = base::unique(policies$policy),
    risk_group = risk_groups$risk_group
  )
  if (base::nrow(expected_keys) != base::nrow(policies) ||
      !base::all(base::paste(
        expected_keys$policy, expected_keys$risk_group
      ) %in% base::paste(policies$policy, policies$risk_group))) {
    base::stop("Every policy must specify every risk group.")
  }
  if (!"no_screen" %in% policies$policy) {
    base::stop("The no_screen policy is required.")
  }
  prob_risk <- c(
    risk_groups$proportion, risk_groups$prevalence_ein,
    risk_groups$prevalence_cancer
  )
  prob_policy <- base::unlist(
    policies[, c(
      "test_fraction", "sensitivity_ein", "sensitivity_cancer",
      "specificity", "inadequate_rate", "followup_fraction",
      "followup_sensitivity_ein", "followup_sensitivity_cancer",
      "followup_specificity"
    )],
    use.names = FALSE
  )
  prob_all <- c(
    prob_risk, prob_policy, procedures$post_detection_prob
  )
  if (!base::is.numeric(prob_all) ||
      base::any(!base::is.finite(prob_all)) ||
      base::any(prob_all < 0 | prob_all > 1)) {
    base::stop("Probabilities must be finite and between zero and one.")
  }
  if (!base::isTRUE(base::all.equal(
    base::sum(risk_groups$proportion), 1,
    tolerance = 1e-9
  ))) {
    base::stop("Stratum proportions must add to one.")
  }
  if (base::any(
    risk_groups$prevalence_ein +
      risk_groups$prevalence_cancer > 1
  )) {
    base::stop("Disease prevalences sum above one in a stratum.")
  }
  cost_cols <- c(
    "initial_test_cost", "inadequate_followup_cost",
    "positive_workup_cost", "false_positive_cost",
    "test_qaly_loss", "inadequate_followup_qaly_loss",
    "false_positive_qaly_loss"
  )
  numeric_inputs <- c(
    base::unlist(policies[, cost_cols], use.names = FALSE),
    procedures$cost_pre, procedures$cost_post,
    procedures$cost_missed, procedures$qaly_pre,
    procedures$qaly_post, procedures$qaly_missed
  )
  if (base::any(!base::is.finite(numeric_inputs)) ||
      base::any(
        base::unlist(policies[, cost_cols], use.names = FALSE) < 0
      ) ||
      base::any(c(
        procedures$cost_pre, procedures$cost_post,
        procedures$cost_missed
      ) < 0)) {
    base::stop("Invalid cost, disutility, or QALY values.")
  }
  if (base::length(surgery_count) != 1L ||
      !base::is.numeric(surgery_count) ||
      !base::is.finite(surgery_count) ||
      surgery_count <= 0 ||
      base::length(willingness_to_pay) != 1L ||
      !base::is.numeric(willingness_to_pay) ||
      !base::is.finite(willingness_to_pay) ||
      willingness_to_pay < 0) {
    base::stop("Invalid cohort size or willingness to pay.")
  }
  no_screen <- policies |>
    dplyr::filter(.data$policy == "no_screen")
  if (base::any(no_screen$test_fraction != 0)) {
    base::stop("no_screen cannot administer routine tests.")
  }
  base::message("Calculating screened, adequate, and follow-up counts.")
  strata <- policies |>
    dplyr::left_join(
      risk_groups, by = "risk_group"
    ) |>
    dplyr::mutate(
      patients = surgery_count * .data$proportion,
      tested = .data$patients * .data$test_fraction,
      inadequate = .data$tested * .data$inadequate_rate,
      adequate = .data$tested - .data$inadequate,
      followed_up = .data$inadequate * .data$followup_fraction,
      base_test_cost = .data$tested * .data$initial_test_cost +
        .data$followed_up * .data$inadequate_followup_cost,
      base_test_qaly_loss =
        .data$tested * .data$test_qaly_loss +
        .data$followed_up *
        .data$inadequate_followup_qaly_loss
    )
  disease_rows <- tidyr::crossing(
    strata,
    pathology = c("ein", "cancer")
  ) |>
    dplyr::mutate(
      disease_prevalence = dplyr::if_else(
        .data$pathology == "ein",
        .data$prevalence_ein,
        .data$prevalence_cancer
      ),
      adequate_sens = dplyr::if_else(
        .data$pathology == "ein",
        .data$sensitivity_ein, .data$sensitivity_cancer
      ),
      followup_sens = dplyr::if_else(
        .data$pathology == "ein",
        .data$followup_sensitivity_ein,
        .data$followup_sensitivity_cancer
      ),
      cases = .data$patients * .data$disease_prevalence,
      detected_adequate = .data$cases *
        .data$test_fraction *
        (1 - .data$inadequate_rate) * .data$adequate_sens,
      detected_followup = .data$cases *
        .data$test_fraction * .data$inadequate_rate *
        .data$followup_fraction * .data$followup_sens,
      detected_pre = .data$detected_adequate +
        .data$detected_followup,
      undetected_pre = .data$cases - .data$detected_pre,
      positive_workup_cost_total =
        .data$detected_pre * .data$positive_workup_cost
    )
  negative_rows <- strata |>
    dplyr::mutate(
      no_disease = .data$patients *
        (1 - .data$prevalence_ein - .data$prevalence_cancer),
      false_positive_adequate = .data$no_disease *
        .data$test_fraction * (1 - .data$inadequate_rate) *
        (1 - .data$specificity),
      false_positive_followup = .data$no_disease *
        .data$test_fraction * .data$inadequate_rate *
        .data$followup_fraction *
        (1 - .data$followup_specificity),
      false_positives = .data$false_positive_adequate +
        .data$false_positive_followup,
      false_positive_cost_total =
        .data$false_positives * .data$false_positive_cost,
      false_positive_qaly_loss_total =
        .data$false_positives *
        .data$false_positive_qaly_loss
    ) |>
    dplyr::select(
      .data$policy, .data$risk_group, .data$patients,
      .data$tested, .data$inadequate, .data$followed_up,
      .data$base_test_cost, .data$base_test_qaly_loss,
      .data$false_positives, .data$false_positive_cost_total,
      .data$false_positive_qaly_loss_total
    )
  base::message("Applying surgery-specific detection and treatment.")
  branch_audit <- tidyr::crossing(
    procedure = base::unique(procedures$procedure),
    disease_rows
  ) |>
    dplyr::left_join(
      procedures, by = c("procedure", "pathology")
    ) |>
    dplyr::mutate(
      detected_post = .data$undetected_pre *
        .data$post_detection_prob,
      missed_at_horizon = .data$undetected_pre -
        .data$detected_post,
      disease_cost =
        .data$detected_pre * .data$cost_pre +
        .data$detected_post * .data$cost_post +
        .data$missed_at_horizon * .data$cost_missed,
      disease_qaly =
        .data$detected_pre * .data$qaly_pre +
        .data$detected_post * .data$qaly_post +
        .data$missed_at_horizon * .data$qaly_missed
    )
  disease_totals <- branch_audit |>
    dplyr::group_by(.data$procedure, .data$policy) |>
    dplyr::summarise(
      cases = base::sum(.data$cases),
      detected_pre = base::sum(.data$detected_pre),
      detected_post = base::sum(.data$detected_post),
      missed_at_horizon = base::sum(.data$missed_at_horizon),
      disease_cost = base::sum(.data$disease_cost),
      disease_qaly = base::sum(.data$disease_qaly),
      positive_workup_cost_total = base::sum(
        .data$positive_workup_cost_total
      ),
      .groups = "drop"
    )
  testing_totals <- negative_rows |>
    dplyr::group_by(.data$policy) |>
    dplyr::summarise(
      tested = base::sum(.data$tested),
      inadequate = base::sum(.data$inadequate),
      followed_up = base::sum(.data$followed_up),
      false_positives = base::sum(.data$false_positives),
      base_test_cost = base::sum(.data$base_test_cost),
      base_test_qaly_loss = base::sum(
        .data$base_test_qaly_loss
      ),
      false_positive_cost_total = base::sum(
        .data$false_positive_cost_total
      ),
      false_positive_qaly_loss_total = base::sum(
        .data$false_positive_qaly_loss_total
      ),
      .groups = "drop"
    )
  comparison <- disease_totals |>
    dplyr::left_join(testing_totals, by = "policy") |>
    dplyr::mutate(
      total_cost = .data$disease_cost +
        .data$positive_workup_cost_total +
        .data$base_test_cost +
        .data$false_positive_cost_total,
      total_qaly = .data$disease_qaly -
        .data$base_test_qaly_loss -
        .data$false_positive_qaly_loss_total,
      net_monetary_benefit =
        willingness_to_pay * .data$total_qaly - .data$total_cost
    ) |>
    dplyr::group_by(.data$procedure) |>
    dplyr::mutate(
      incremental_cost = .data$total_cost -
        .data$total_cost[.data$policy == "no_screen"],
      incremental_qaly = .data$total_qaly -
        .data$total_qaly[.data$policy == "no_screen"],
      incremental_nmb = .data$net_monetary_benefit -
        .data$net_monetary_benefit[
          .data$policy == "no_screen"
        ]
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(.data$procedure, .data$policy)
  base::message(
    "Risk-stratified model complete: ",
    base::nrow(comparison), " procedure-policy combinations."
  )
  return(base::list(
    comparison = comparison,
    branch_audit = branch_audit,
    negative_audit = negative_rows
  ))
}

#' Construct blank risk-stratified inputs with six operations
#'
#' All numerical clinical assumptions except the no-screen policy are
#' missing on purpose. Do not interpret until values are evidence-based.
#' @return List of procedures, risk_groups, and policies.
make_risk_stratified_screening_inputs <- function() {
  base::source("R/shared_preop_screening_model.R")
  parent_inputs <- make_shared_preop_screening_inputs()
  group_ids <- c("average", "elevated")
  policy_ids <- c(
    "no_screen", "selective_tvus", "routine_tvus",
    "selective_biopsy", "universal_biopsy"
  )
  risk_groups <- tibble::tibble(
    risk_group = group_ids,
    proportion = NA_real_,
    prevalence_ein = NA_real_,
    prevalence_cancer = NA_real_
  )
  policies <- tidyr::crossing(
    policy = policy_ids,
    risk_group = group_ids
  ) |>
    dplyr::mutate(
      test_fraction = NA_real_,
      sensitivity_ein = NA_real_,
      sensitivity_cancer = NA_real_,
      specificity = NA_real_,
      inadequate_rate = NA_real_,
      followup_fraction = NA_real_,
      followup_sensitivity_ein = NA_real_,
      followup_sensitivity_cancer = NA_real_,
      followup_specificity = NA_real_,
      initial_test_cost = NA_real_,
      inadequate_followup_cost = NA_real_,
      positive_workup_cost = NA_real_,
      false_positive_cost = NA_real_,
      test_qaly_loss = NA_real_,
      inadequate_followup_qaly_loss = NA_real_,
      false_positive_qaly_loss = NA_real_
    ) |>
    dplyr::mutate(
      test_fraction = dplyr::if_else(
        .data$policy == "no_screen", 0, .data$test_fraction
      ),
      inadequate_rate = dplyr::if_else(
        .data$policy == "no_screen", 0, .data$inadequate_rate
      ),
      followup_fraction = dplyr::if_else(
        .data$policy == "no_screen", 0, .data$followup_fraction
      )
    )
  base::message(
    "Created blank stratified inputs for ",
    base::length(policy_ids), " policies and ",
    base::length(group_ids), " groups."
  )
  return(base::list(
    procedures = parent_inputs$procedures,
    risk_groups = risk_groups,
    policies = policies
  ))
}
