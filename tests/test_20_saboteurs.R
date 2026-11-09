# Twenty adversarial checks for shared preoperative screening model.
# Every input below is synthetic; NEVER cite as clinical evidence.
# Run from repository root:
# base::source("tests/test_20_saboteurs.R")
base::source("R/shared_preop_screening_model.R")

make_synthetic_inputs <- function() {
  synthetic <- make_shared_preop_screening_inputs()
  synthetic$prevalence <- c(ein = 0.003, cancer = 0.005)
  synthetic$procedures$post_detection_prob <- 0.70
  synthetic$procedures$cost_pre <- 5000
  synthetic$procedures$cost_post <- 12000
  synthetic$procedures$cost_missed <- 15000
  synthetic$procedures$qaly_pre <- 0
  synthetic$procedures$qaly_post <- -0.03
  synthetic$procedures$qaly_missed <- -0.06
  screen_idx <- synthetic$screening$strategy != "no_screen"
  synthetic$screening$sensitivity_ein[screen_idx] <- 0.75
  synthetic$screening$sensitivity_cancer[screen_idx] <- 0.90
  synthetic$screening$specificity[screen_idx] <- 0.90
  synthetic$screening$testing_cost[screen_idx] <- 150
  synthetic$screening$positive_followup_cost[screen_idx] <- 250
  synthetic$screening$false_positive_cost[screen_idx] <- 500
  synthetic$screening$testing_qaly_loss[screen_idx] <- 0.00001
  synthetic$screening$false_positive_qaly_loss[screen_idx] <- 0.001
  return(synthetic)
}

call_model <- function(inputs, cohort = 10000, wtp = 100000) {
  run_shared_preop_screening_model(
    procedures = inputs$procedures,
    screening = inputs$screening,
    prevalence = inputs$prevalence,
    surgery_count = cohort,
    willingness_to_pay = wtp
  )
}

expect_rejected <- function(inputs, cohort = 10000, wtp = 100000) {
  attempt <- base::try(
    base::suppressMessages(call_model(inputs, cohort, wtp)),
    silent = TRUE
  )
  base::stopifnot(base::inherits(attempt, "try-error"))
}

assert_equal <- function(actual, expected, tolerance = 1e-9) {
  base::stopifnot(base::isTRUE(base::all.equal(
    base::unname(actual),
    base::unname(expected),
    tolerance = tolerance,
    check.attributes = FALSE
  )))
}

# Deliberately run all 20 rather than stopping at the first failure.
saboteur_cases <- base::list(
  "01 rejects blank uncalibrated inputs" = function() {
    expect_rejected(make_shared_preop_screening_inputs())
  },
  "02 rejects missing required procedure column" = function() {
    altered <- make_synthetic_inputs()
    altered$procedures$cost_missed <- NULL
    expect_rejected(altered)
  },
  "03 rejects combined disease prevalence above 100%" = function() {
    altered <- make_synthetic_inputs()
    altered$prevalence <- c(ein = 0.60, cancer = 0.50)
    expect_rejected(altered)
  },
  "04 rejects negative prevalence" = function() {
    altered <- make_synthetic_inputs()
    altered$prevalence[["ein"]] <- -0.01
    expect_rejected(altered)
  },
  "05 rejects nonfinite disease prevalence" = function() {
    altered <- make_synthetic_inputs()
    altered$prevalence[["cancer"]] <- Inf
    expect_rejected(altered)
  },
  "06 rejects test sensitivity above one" = function() {
    altered <- make_synthetic_inputs()
    altered$screening$sensitivity_cancer[2] <- 1.01
    expect_rejected(altered)
  },
  "07 rejects negative downstream cost" = function() {
    altered <- make_synthetic_inputs()
    altered$procedures$cost_post[1] <- -1
    expect_rejected(altered)
  },
  "08 rejects duplicate procedure-pathology rows" = function() {
    altered <- make_synthetic_inputs()
    altered$procedures <- dplyr::bind_rows(
      altered$procedures, altered$procedures[1, ]
    )
    expect_rejected(altered)
  },
  "09 rejects missing EIN branch for one procedure" = function() {
    altered <- make_synthetic_inputs()
    altered$procedures <- altered$procedures[-1, ]
    expect_rejected(altered)
  },
  "10 rejects duplicate screening strategy" = function() {
    altered <- make_synthetic_inputs()
    altered$screening <- dplyr::bind_rows(
      altered$screening, altered$screening[2, ]
    )
    expect_rejected(altered)
  },
  "11 rejects contaminated no-screen strategy" = function() {
    altered <- make_synthetic_inputs()
    no_idx <- altered$screening$strategy == "no_screen"
    altered$screening$testing_qaly_loss[no_idx] <- 0.01
    expect_rejected(altered)
  },
  "12 rejects negative cohort size" = function() {
    expect_rejected(make_synthetic_inputs(), cohort = -100)
  },
  "13 rejects negative willingness to pay" = function() {
    expect_rejected(make_synthetic_inputs(), wtp = -1)
  },
  "14 has exactly one row per strategy and procedure" = function() {
    tab <- base::suppressMessages(
      call_model(make_synthetic_inputs())
    )
    base::stopifnot(base::nrow(tab) == 18)
    base::stopifnot(!base::anyDuplicated(
      tab[c("procedure", "strategy")]
    ))
  },
  "15 preserves pathological case counts" = function() {
    tab <- base::suppressMessages(
      call_model(make_synthetic_inputs())
    )
    assert_equal(
      tab$expected_pre_detections +
        tab$expected_post_detections + tab$expected_undetected,
      base::rep(80, base::nrow(tab))
    )
  },
  "16 zero prevalence produces no true detections" = function() {
    altered <- make_synthetic_inputs()
    altered$prevalence <- c(ein = 0, cancer = 0)
    tab <- base::suppressMessages(call_model(altered))
    assert_equal(tab$expected_pre_detections,
                 base::rep(0, base::nrow(tab)))
    assert_equal(tab$expected_post_detections,
                 base::rep(0, base::nrow(tab)))
    assert_equal(tab$expected_undetected,
                 base::rep(0, base::nrow(tab)))
  },
  "17 false positives vanish at specificity one" = function() {
    altered <- make_synthetic_inputs()
    altered$screening$specificity <- 1
    tab <- base::suppressMessages(call_model(altered))
    assert_equal(tab$expected_false_positives,
                 base::rep(0, base::nrow(tab)))
  },
  "18 doubling cohort doubles additive outcomes" = function() {
    altered <- make_synthetic_inputs()
    first <- base::suppressMessages(call_model(altered, 10000))
    second <- base::suppressMessages(call_model(altered, 20000))
    first <- dplyr::arrange(first, .data$procedure, .data$strategy)
    second <- dplyr::arrange(second, .data$procedure, .data$strategy)
    for (metric in c(
      "expected_pre_detections", "expected_post_detections",
      "expected_false_positives", "total_cost", "total_qaly",
      "incremental_nmb"
    )) {
      assert_equal(second[[metric]], 2 * first[[metric]])
    }
  },
  "19 higher sensitivity detects more before surgery" = function() {
    altered <- make_synthetic_inputs()
    base_tab <- base::suppressMessages(call_model(altered))
    biopsy_idx <- altered$screening$strategy == "biopsy_pathway"
    altered$screening$sensitivity_ein[biopsy_idx] <- 1
    altered$screening$sensitivity_cancer[biopsy_idx] <- 1
    changed <- base::suppressMessages(call_model(altered))
    baseline <- base_tab |>
      dplyr::filter(.data$strategy == "biopsy_pathway") |>
      dplyr::arrange(.data$procedure)
    comparison <- changed |>
      dplyr::filter(.data$strategy == "biopsy_pathway") |>
      dplyr::arrange(.data$procedure)
    base::stopifnot(base::all(
      comparison$expected_pre_detections >
        baseline$expected_pre_detections
    ))
    base::stopifnot(base::all(
      comparison$expected_undetected <
        baseline$expected_undetected
    ))
  },
  "20 one procedure cost mutation cannot affect others" = function() {
    altered <- make_synthetic_inputs()
    baseline <- base::suppressMessages(call_model(altered))
    chosen <- altered$procedures$procedure == "sch_scp"
    altered$procedures$cost_post[chosen] <- 25000
    changed <- base::suppressMessages(call_model(altered))
    baseline <- dplyr::arrange(
      baseline, .data$procedure, .data$strategy
    )
    changed <- dplyr::arrange(
      changed, .data$procedure, .data$strategy
    )
    unchanged <- baseline$procedure != "sch_scp"
    changed_group <- baseline$procedure == "sch_scp"
    assert_equal(
      changed$total_cost[unchanged],
      baseline$total_cost[unchanged]
    )
    assert_equal(
      changed$total_qaly[unchanged],
      baseline$total_qaly[unchanged]
    )
    base::stopifnot(base::all(
      changed$total_cost[changed_group] >
        baseline$total_cost[changed_group]
    ))
  }
)

base::stopifnot(base::length(saboteur_cases) == 20)
checks <- base::lapply(base::seq_along(saboteur_cases), function(i) {
  check_name <- base::names(saboteur_cases)[i]
  base::message("SABOTEUR ", check_name)
  issue <- base::tryCatch(
    {
      saboteur_cases[[i]]()
      NULL
    },
    error = function(e) base::conditionMessage(e)
  )
  passed <- base::is.null(issue)
  base::message(
    "  ", if (passed) "PASS" else "FAIL",
    if (!passed) base::paste0(": ", issue) else ""
  )
  tibble::tibble(
    case = check_name,
    passed = passed,
    error = if (passed) "" else issue
  )
})
check_table <- dplyr::bind_rows(checks)
base::message(
  "Summary: ", base::sum(check_table$passed),
  "/20 passed; ", base::sum(!check_table$passed), " failed."
)
base::print(check_table, n = 20)
if (base::any(!check_table$passed)) {
  base::stop("Adversarial checks failed: inspect failures above.")
}
