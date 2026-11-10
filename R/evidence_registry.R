#' Read sourced evidence with exact binomial confidence intervals
#'
#' Evidence is NOT automatically substituted into the decision model:
#' pooled rates are provisional and costs can be historical or scenarios.
#'
#' @param registry_path Path to the parameter evidence registry CSV.
#' @param counts_path Path to the study-level numerator/denominator CSV.
#' @param confidence_level Two-sided binomial confidence level.
#' @return List with registry and study_counts tibbles.
read_screening_evidence_registry <- function(
  registry_path = "evidence/screening_assumptions_registry.csv",
  counts_path = "evidence/occult_pathology_study_counts.csv",
  confidence_level = 0.95
) {
  base::message("Loading registry: ", registry_path)
  if (!base::file.exists(registry_path)) {
    base::stop("Evidence registry does not exist: ", registry_path)
  }
  base::message("Loading study counts: ", counts_path)
  if (!base::file.exists(counts_path)) {
    base::stop("Study-count registry does not exist: ", counts_path)
  }
  if (!base::is.numeric(confidence_level) ||
      base::length(confidence_level) != 1L ||
      !base::is.finite(confidence_level) ||
      confidence_level <= 0 || confidence_level >= 1) {
    base::stop("confidence_level must be between zero and one.")
  }
  parameter_registry <- utils::read.csv(
    registry_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA")
  ) |>
    tibble::as_tibble()
  study_counts <- utils::read.csv(
    counts_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA")
  ) |>
    tibble::as_tibble()
  required_registry <- c(
    "parameter_id", "model_field", "evidence_status",
    "point_estimate", "lower_bound", "upper_bound",
    "source", "source_population"
  )
  required_counts <- c(
    "study_id", "outcome", "procedure_group",
    "events", "denominator", "source"
  )
  if (!base::all(required_registry %in%
                 base::names(parameter_registry))) {
    base::stop("The parameter registry is missing required columns.")
  }
  if (!base::all(required_counts %in%
                 base::names(study_counts))) {
    base::stop("The study counts are missing required columns.")
  }
  if (base::anyDuplicated(parameter_registry$parameter_id)) {
    base::stop("Duplicate parameter_id in the evidence registry.")
  }
  if (base::anyDuplicated(
    study_counts[c("study_id", "outcome", "procedure_group")]
  )) {
    base::stop("Duplicate study outcome and procedure group.")
  }
  if (base::anyNA(study_counts$events) ||
      base::anyNA(study_counts$denominator) ||
      base::any(!base::is.finite(study_counts$events)) ||
      base::any(!base::is.finite(study_counts$denominator)) ||
      base::any(study_counts$denominator < 1) ||
      base::any(study_counts$events < 0) ||
      base::any(study_counts$events > study_counts$denominator) ||
      base::any(study_counts$events !=
                base::floor(study_counts$events)) ||
      base::any(study_counts$denominator !=
                base::floor(study_counts$denominator))) {
    base::stop("Study numerators or denominators are invalid.")
  }
  base::message(
    "Computing two-sided Clopper-Pearson intervals at ",
    base::round(100 * confidence_level, 1), "% confidence."
  )
  alpha <- 1 - confidence_level
  study_counts <- study_counts |>
    dplyr::mutate(
      point_estimate = .data$events / .data$denominator,
      ci_lower = dplyr::if_else(
        .data$events == 0, 0,
        stats::qbeta(
          alpha / 2,
          .data$events,
          .data$denominator - .data$events + 1
        )
      ),
      ci_upper = dplyr::if_else(
        .data$events == .data$denominator, 1,
        stats::qbeta(
          1 - alpha / 2,
          .data$events + 1,
          .data$denominator - .data$events
        )
      ),
      ci_method = "Clopper-Pearson exact binomial"
    )
  base::message(
    "Registry entries: ", base::nrow(parameter_registry),
    "; study outcome rows: ", base::nrow(study_counts), "."
  )
  base::message(
    "Evidence is not automatically used as model calibration."
  )
  return(base::list(
    registry = parameter_registry,
    study_counts = study_counts
  ))
}

#' Extract provisional, nonvalidated prevalence scenarios
#'
#' @param evidence A list from read_screening_evidence_registry().
#' @return Tibble with EIN and invasive cancer scenarios.
get_provisional_prevalence_scenarios <- function(evidence) {
  base::message("Extracting provisional prevalence scenarios.")
  required_ids <- c("prev_ein", "prev_cancer")
  if (!base::is.list(evidence) ||
      !base::is.data.frame(evidence$registry)) {
    base::stop("Provide a loaded evidence registry.")
  }
  scenarios <- evidence$registry |>
    dplyr::filter(.data$parameter_id %in% required_ids) |>
    dplyr::select(
      "parameter_id", "point_estimate", "lower_bound",
      "upper_bound", "evidence_status", "source",
      "transportability_concern"
    )
  if (!base::setequal(scenarios$parameter_id, required_ids)) {
    base::stop("Both EIN and invasive EC scenario rows are required.")
  }
  if (base::anyNA(scenarios$point_estimate) ||
      base::anyNA(scenarios$lower_bound) ||
      base::anyNA(scenarios$upper_bound)) {
    base::stop("Provisional prevalence scenario inputs are missing.")
  }
  base::message(
    "Returned provisional research scenarios only; ",
    "clinical calibration remains unvalidated."
  )
  return(scenarios)
}
