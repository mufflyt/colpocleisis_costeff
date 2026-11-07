# Reproducibility, manuscript handoff, and proposed extension

## Source-of-truth inventory

- `colpocleisis_selective_testing_model.R`: computational implementation.
- `generate_figures.R`: three figure-generation routines.
- `run_example.R`: small example runner.
- `manuscript.txt`: structured abstract plus figure legends; **not**
  a complete journal manuscript.
- `ONBOARDING.md`: earlier manuscript-development notes, useful for
  context but not a substitute for source-code verification.
- `README.md`: entry point.

The October 2026 AUGS rapid-fire slide deck and speaking script were
previously prepared separately; they are **not committed in this repo**.
A draft, abstract, or talk should not be labeled as the accepted or
published manuscript without checking submission status.

## Run in R, from the repository root

Install the dependencies listed in the README, then run:

```r
base::source("colpocleisis_selective_testing_model.R")

model_bundle <- run_colpocleisis_selective_testing_model(
  save_csv = TRUE,
  output_dir = "output"
)

base::print(model_bundle$strategy_table)
base::print(model_bundle$frontier_table)
base::message(model_bundle$summary_sentence)

base::source("generate_figures.R")
```

The model saves timestamped strategy and frontier CSV filenames
when `save_csv = TRUE`. The figure script currently writes fixed names
(`figure1_ce_plane.jpeg`, `figure2_tornado.jpeg`,
`figure3_threshold.jpeg`) in `output/` and will overwrite
files with those names. Archive figures with an external timestamp
or change the script in a separately reviewed code PR if preservation
is needed. `output/` is not committed by default.

The script creates `output/`, but for model-only CSV runs ensure
the folder exists first, for example:

```r
base::dir.create("output", showWarnings = FALSE, recursive = TRUE)
```

Capture R version, `utils::sessionInfo()`, git commit SHA, run date,
input overrides, and output filenames in a run record. Do not silently
change default assumptions while recreating conference figures.

## Pre-submission reconciliation checklist

- [ ] Re-run the base case at a pinned commit.
- [ ] Confirm preferred strategy and full efficiency frontier.
- [ ] Recalculate the TVUS switch threshold using sufficiently fine
      prevalence increments (not only visual inspection of Figure 3).
- [ ] Verify the claim of 0.72% high-risk prevalence against the code,
      presentation, abstract, and manuscript.
- [ ] Verify all quoted ICERs, NMBs, and 'dominated' classifications.
- [ ] Check absolute versus subgroup risk wording.
- [ ] Check the clinical pathway, units, base years, and sources for
      every cost and utility.
- [ ] Decide whether model limitations warrant structural revisions.
- [ ] Compare each presentation figure to the regenerated figure.
- [ ] Expand the abstract into a full manuscript with full references,
      tables, limitations, and a reproducibility statement.
- [ ] Apply an appropriate health-economic reporting checklist (e.g.,
      CHEERS 2022) before submission.

## A tractable first extension: postoperative accessibility

**Not implemented.** The current model has only a combined missed-cancer
cost and early-detection QALY credit; there is no explicit excess
penalty attributable to obliterative vaginal closure.

Before comparing procedures, create explicit state/pathway definitions:

1. Undetected pathology at surgery (cancer versus EIN versus neither).
2. Subsequent symptom onset, evaluation attempts, test success/failure,
   and elapsed time to diagnosis.
3. Procedure-specific diagnostic access and costs.
4. Stage at diagnosis, oncologic management, and outcomes *if supported
   by evidence*.
5. Surgical-management change resulting from preoperative detection.

Predefine scenarios with an unchanged general cancer pathway and
different **incremental access** probabilities/costs. Do not simply
zero `delayed_cancer_cost` or `qaly_gain_early_detection` and call it a
hysteropexy model: that would erase general cancer harms as well.

For hysteropexy, the uterine corpus remains and later access is
typically retained. Its patients' age, risk, life expectancy, and
ability to undergo future evaluation may differ from LeFort patients.
For SCH + sacrocolpopexy, the uterine corpus is removed; assess occult
malignancy, specimen extraction/morcellation, cervical retention,
incidental pathology, and need for additional cancer surgery.
These require distinct postoperative branches.

## Reproducible extension acceptance criteria

- Preserve all baseline outputs when extension parameters are set to
  their original-equivalent values.
- Declare each new probability, cost, time unit, utility, and citation;
  explicitly label elicited assumptions.
- Keep general cancer harms separate from procedure-specific access costs.
- Compare base case and accessible-uterus scenario while holding other
  inputs constant *before* changing population-level risk assumptions.
- Conduct one-way, two-way, and probabilistic sensitivity analyses where
  data support distributions; report structural uncertainty separately.
- Do not publish new thresholds before independent implementation
  checks and clinical review.
- Save code, inputs, and reproducible outputs together, retaining the
  original LeFort results without overwriting them.
