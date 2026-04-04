#!/usr/bin/env Rscript
# generate_figures.R
# Generates publication-quality figures for colpocleisis selective testing model

required_pkgs <- c("ggplot2", "dplyr", "tibble", "tidyr", "scales", "forcats")
missing_pkgs <- required_pkgs[
  !vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_pkgs) > 0) {
  stop(
    "Missing packages: ", paste(missing_pkgs, collapse = ", "),
    "\nInstall with: install.packages(c(",
    paste0('"', missing_pkgs, '"', collapse = ", "), "))"
  )
}

library(tibble)
library(dplyr)
library(purrr)

base::message("Sourcing model...")
script_dir <- tryCatch(
  base::dirname(base::sys.frame(1)$ofile),
  error = function(e) base::getwd()
)
source(
  file.path(script_dir, "colpocleisis_selective_testing_model.R"),
  local = FALSE
)

# Ensure output directory exists
output_path <- file.path(base::getwd(), "output")
if (!base::dir.exists(output_path)) {
  base::dir.create(output_path, recursive = TRUE)
}

# Journal-quality theme
theme_journal <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.border = ggplot2::element_rect(fill = NA, colour = "grey70"),
      axis.ticks = ggplot2::element_line(colour = "grey70"),
      legend.position = "bottom",
      plot.title = ggplot2::element_text(face = "bold", size = 11),
      plot.subtitle = ggplot2::element_text(size = 8, colour = "grey40", lineheight = 1.2),
      plot.title.position = "plot"
    )
}

# Nice strategy labels
strategy_labels <- c(
  "no_testing" = "No Testing",
  "selective_tvus" = "Transvaginal Ultrasound",
  "selective_office_pipelle" = "Office Pipelle Biopsy",
  "selective_concurrent_dnc" = "Concurrent Dilation and Curettage"
)

# ============================================================
# Run base case
# ============================================================
base::message("Running base case model...")
base_case <- run_colpocleisis_selective_testing_model(surgery_count = 10000)

strategy_tbl <- base_case$strategy_table
frontier_tbl <- base_case$frontier_table

# ============================================================
# Figure 1: Cost-effectiveness plane
# ============================================================
base::message("Generating Figure 1: Cost-effectiveness plane...")

plane_tbl <- strategy_tbl |>

  dplyr::select(strategy, total_cost, qaly_gained) |>
  dplyr::mutate(
    label = strategy_labels[strategy]
  )

frontier_line_tbl <- frontier_tbl |>
  dplyr::select(strategy, total_cost, qaly_gained) |>
  dplyr::arrange(total_cost)

fig1 <- ggplot2::ggplot(plane_tbl, ggplot2::aes(x = total_cost, y = qaly_gained)) +
  ggplot2::geom_line(
    data = frontier_line_tbl,
    ggplot2::aes(x = total_cost, y = qaly_gained),
    colour = "grey50", linetype = "dashed", linewidth = 0.6
  ) +
  ggplot2::geom_point(ggplot2::aes(colour = label), size = 3.5) +
  ggplot2::geom_text(
    ggplot2::aes(label = label),
    vjust = -1, hjust = 0.5, size = 2.8, check_overlap = FALSE
  ) +
  ggplot2::scale_x_continuous(
    labels = scales::dollar_format(),
    expand = ggplot2::expansion(mult = c(0.05, 0.15))
  ) +
  ggplot2::scale_colour_brewer(palette = "Set1", name = "Strategy") +
  ggplot2::labs(
    title = NULL,
    subtitle = NULL,
    x = "Total Cost ($)",
    y = "Quality-Adjusted Life-Years Gained"
  ) +
  theme_journal()

ggplot2::ggsave(
  file.path(output_path, "figure1_ce_plane.jpeg"),
  plot = fig1, width = 9, height = 7, device = "jpeg", dpi = 300
)
base::message("  Saved figure1_ce_plane.jpeg")

# ============================================================
# Figure 2: Tornado diagram (one-way sensitivity analysis)
# ============================================================
base::message("Generating Figure 2: Tornado diagram...")

wtp_value <- 100000

# Identify preferred strategy at base case
preferred_strategy <- strategy_tbl |>
  dplyr::arrange(dplyr::desc(net_monetary_benefit)) |>
  dplyr::slice(1) |>
  dplyr::pull(strategy)

base::message("  Preferred strategy at base case: ", preferred_strategy)

# Base case NMB for preferred strategy
base_nmb <- strategy_tbl |>
  dplyr::filter(strategy == preferred_strategy) |>
  dplyr::pull(net_monetary_benefit)

# Parameters to vary
sensitivity_params <- tibble::tibble(
  param_name = c(
    "high_risk_prevalence",
    "delayed_cancer_cost",
    "tvus_cost",
    "pipelle_inadequate_rate",
    "concurrent_dnc_incremental_cost",
    "concurrent_dnc_effective_detection_credit"
  ),
  low_val = c(0.0022, 10000, 72, 0.10, 400, 0.10),
  high_val = c(0.026, 50000, 250, 0.50, 1500, 0.90),
  display_label = c(
    "High-risk cancer prevalence",
    "Delayed cancer diagnosis cost",
    "Transvaginal ultrasound cost",
    "Pipelle biopsy inadequate sample rate",
    "Concurrent dilation and curettage incremental cost",
    "Dilation and curettage effective detection credit"
  ),
  format_type = c("pct", "dollar", "dollar", "pct", "dollar", "pct")
)

get_preferred_nmb <- function(param_name, param_value) {
  args_list <- list(surgery_count = 10000)
  args_list[[param_name]] <- param_value
  run_result <- do.call(run_colpocleisis_selective_testing_model, args_list)
  run_result$strategy_table |>
    dplyr::filter(strategy == preferred_strategy) |>
    dplyr::pull(net_monetary_benefit)
}

tornado_rows <- list()
for (idx in seq_len(nrow(sensitivity_params))) {
  p_name <- sensitivity_params$param_name[idx]
  p_low <- sensitivity_params$low_val[idx]
  p_high <- sensitivity_params$high_val[idx]
  p_label <- sensitivity_params$display_label[idx]

  nmb_low <- get_preferred_nmb(p_name, p_low)
  nmb_high <- get_preferred_nmb(p_name, p_high)

  tornado_rows[[idx]] <- tibble::tibble(
    parameter = p_label,
    param_low_val = p_low,
    param_high_val = p_high,
    param_format = sensitivity_params$format_type[idx],
    nmb_low = nmb_low,
    nmb_high = nmb_high,
    spread = abs(nmb_high - nmb_low)
  )
}

tornado_tbl <- dplyr::bind_rows(tornado_rows) |>
  dplyr::mutate(
    parameter = forcats::fct_reorder(parameter, spread),
    bar_left = pmin(nmb_low, nmb_high),
    bar_right = pmax(nmb_low, nmb_high),
    left_is_low = nmb_low <= nmb_high,
    val_left = dplyr::if_else(left_is_low, param_low_val, param_high_val),
    val_right = dplyr::if_else(left_is_low, param_high_val, param_low_val),
    label_left = dplyr::case_when(
      param_format == "dollar" ~ paste0("$", formatC(val_left, format = "f", digits = 0, big.mark = ",")),
      param_format == "pct" ~ paste0(formatC(val_left * 100, format = "f", digits = 1), "%")
    ),
    label_right = dplyr::case_when(
      param_format == "dollar" ~ paste0("$", formatC(val_right, format = "f", digits = 0, big.mark = ",")),
      param_format == "pct" ~ paste0(formatC(val_right * 100, format = "f", digits = 1), "%")
    )
  )

fig2 <- ggplot2::ggplot(tornado_tbl) +
  ggplot2::geom_segment(
    ggplot2::aes(
      y = parameter, yend = parameter,
      x = bar_left,
      xend = bar_right
    ),
    linewidth = 6, colour = "#4A90D9", alpha = 0.8
  ) +
  ggplot2::geom_text(
    ggplot2::aes(x = bar_left, y = parameter, label = label_left),
    hjust = 1.1, size = 2.8, colour = "grey30"
  ) +
  ggplot2::geom_text(
    ggplot2::aes(x = bar_right, y = parameter, label = label_right),
    hjust = -0.1, size = 2.8, colour = "grey30"
  ) +
  ggplot2::geom_vline(xintercept = base_nmb, linetype = "dashed", colour = "grey30") +
  ggplot2::scale_x_continuous(
    labels = scales::dollar_format(),
    expand = ggplot2::expansion(mult = c(0.15, 0.15))
  ) +
  ggplot2::labs(
    title = NULL,
    subtitle = NULL,
    x = "Net Monetary Benefit ($)",
    y = NULL
  ) +
  theme_journal() +
  ggplot2::theme(legend.position = "none")

ggplot2::ggsave(
  file.path(output_path, "figure2_tornado.jpeg"),
  plot = fig2, width = 9, height = 7, device = "jpeg", dpi = 300
)
base::message("  Saved figure2_tornado.jpeg")

# ============================================================
# Figure 3: Threshold plot (high_risk_prevalence)
# ============================================================
base::message("Generating Figure 3: Threshold plot...")

prevalence_grid <- seq(0.001, 0.05, length.out = 150)
threshold_rows <- list()

for (idx in seq_along(prevalence_grid)) {
  prev_val <- prevalence_grid[idx]
  # high_risk_prevalence must be >= low_risk_prevalence; set low_risk to min of itself and prev_val
  low_risk_val <- min(0.0022, prev_val)
  run_result <- run_colpocleisis_selective_testing_model(
    surgery_count = 10000,
    high_risk_prevalence = prev_val,
    low_risk_prevalence = low_risk_val
  )
  nmb_by_strategy <- run_result$strategy_table |>
    dplyr::select(strategy, net_monetary_benefit) |>
    dplyr::mutate(high_risk_prevalence = prev_val)
  threshold_rows[[idx]] <- nmb_by_strategy
}

threshold_tbl <- dplyr::bind_rows(threshold_rows) |>
  dplyr::mutate(
    label = strategy_labels[strategy]
  )

fig3 <- ggplot2::ggplot(
  threshold_tbl,
  ggplot2::aes(
    x = high_risk_prevalence,
    y = net_monetary_benefit,
    colour = label
  )
) +
  ggplot2::geom_line(linewidth = 0.8) +
  ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  ggplot2::scale_y_continuous(labels = scales::dollar_format()) +
  ggplot2::scale_colour_brewer(palette = "Set1", name = "Strategy") +
  ggplot2::labs(
    title = NULL,
    subtitle = NULL,
    x = "High-Risk Endometrial Cancer Prevalence",
    y = "Net Monetary Benefit ($)"
  ) +
  theme_journal()

ggplot2::ggsave(
  file.path(output_path, "figure3_threshold.jpeg"),
  plot = fig3, width = 9, height = 7, device = "jpeg", dpi = 300
)
base::message("  Saved figure3_threshold.jpeg")

base::message("All figures generated successfully.")
