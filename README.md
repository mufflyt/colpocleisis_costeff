# Cost-Effectiveness of Selective Endometrial Evaluation Before LeFort Colpocleisis

A threshold-style decision analysis comparing four preoperative endometrial evaluation strategies before LeFort colpocleisis for detection of occult endometrial cancer.

## Documentation and project status

Start with [the implemented model specification](docs/MODEL_SPECIFICATION.md)
to understand the code's cost/QALY equations, what is assumed, and what
clinical pathways are **not** simulated. See
[reproducibility and extension notes](docs/REPRODUCIBILITY_AND_EXTENSION.md)
for manuscript handoff, figure regeneration, a pre-submission checklist,
and the proposed LeFort-versus-hysteropexy/SCH sensitivity analysis.

**Status:** This repository contains a decision-model implementation,
figure-generation code, and a **structured abstract with figure legends**
(`manuscript.txt`); it does not contain a finished full-length manuscript.
The October 2026 AUGS slide deck and spoken script were prepared separately
and are not tracked here. Numerical findings are conditional on model
assumptions and should be re-run at a pinned commit before submission.

## New research scaffold: common screening model across procedures

The proposed AUGS consensus extension is **in development**. See
[the shared screening study protocol](docs/SHARED_SCREENING_STUDY_PLAN.md)
and [the new R implementation](R/shared_preop_screening_model.R).

This **separate** model evaluates no routine screening versus screening
pathways within each intended prolapse procedure (TVH/USLS,
USLS/SSLS hysteropexy, TLH/SCP, SCH/SCP, and mesh sacral hysteropexy).
Occult **EIN and invasive cancer** have distinct postoperative
consequences; the model reports expected costs, QALYs, detection counts
and incremental net monetary benefit.

**Do not use it for clinical recommendations yet:** procedure-specific
inputs intentionally default to `NA` until evidence or explicitly
labeled expert assumptions are supplied. Anatomic distinctions are
plausible but their quantitative effects have not been validated.
The first version addresses prevalent disease over an explicit common
horizon, not lifetime incident cancer or fully selective screening.

The structural smoke-test script is
`tests/test_shared_preop_screening_model.R`, using **illustrative**
values only. It must be run and independently validated before making
claims about results. The original LeFort model is unchanged.

## Clinical Question

Should women undergoing LeFort colpocleisis receive preoperative endometrial evaluation, and if so, which diagnostic strategy is most cost-effective?

LeFort colpocleisis obliterates the vaginal canal, making subsequent uterine evaluation difficult. Surgeons worry about missing occult endometrial cancer, but the prevalence is low (0.22%–2.6%). Despite weak evidence for routine screening, 68% of colpocleisis surgeons report performing preoperative endometrial evaluation.

## Strategies Compared

1. **No routine testing** — proceed to surgery without endometrial evaluation
2. **Selective transvaginal ultrasound** — screen higher-risk women; abnormal results trigger office biopsy
3. **Selective office Pipelle biopsy** — direct tissue sampling in higher-risk women; inadequate samples may trigger further workup
4. **Selective concurrent dilation and curettage** — tissue sampling performed during the colpocleisis itself (shares anesthetic); results return postoperatively so they cannot change the surgical plan

## Key Findings

- At base-case cancer prevalence (0.56%), **no testing is preferred** — testing costs far exceed the benefit of early detection
- Only no testing and transvaginal ultrasound survive on the efficiency frontier; Pipelle and concurrent D&C are **dominated** (higher cost, fewer QALYs)
- Transvaginal ultrasound becomes the preferred strategy when high-risk prevalence exceeds **0.72%** in the current documented analysis (verify against the
  exact code revision used for publication). This is **high-risk subgroup
  prevalence**, not individual predicted risk; risk factors alone do not
  establish that a particular patient crosses the threshold
- Results are most sensitive to **cancer prevalence** and **delayed diagnosis cost**

## Repository Structure

```
colpocleisis_costeff/
├── colpocleisis_selective_testing_model.R   # Main model function
├── run_example.R                            # Quick-start script (runs base case, prints results)
├── generate_figures.R                       # Generates all 3 publication figures
├── manuscript.txt                           # Abstract text (393 words) + figure legends
├── output/                                  # Generated figures and CSV tables (gitignored)
│   ├── figure1_ce_plane.jpeg
│   ├── figure2_tornado.jpeg
│   ├── figure3_threshold.jpeg
│   └── *.csv (strategy and frontier tables)
└── .gitignore
```

## How to Run

### Prerequisites

R (tested on 4.4.x) with these packages:

```r
install.packages(c("tibble", "dplyr", "purrr", "rlang", "readr", "ggplot2", "scales", "forcats", "tidyr"))
```

### Run the base-case model

```r
source("colpocleisis_selective_testing_model.R")
strategy_bundle <- run_colpocleisis_selective_testing_model()
strategy_bundle$strategy_table
strategy_bundle$frontier_table
strategy_bundle$summary_sentence
```

### Run with CSV output

```r
strategy_bundle <- run_colpocleisis_selective_testing_model(save_csv = TRUE, output_dir = "output")
```

### Generate figures

From the repository root in an R session:

```r
base::source("generate_figures.R")
```

Produces three JPEG files (300 DPI) in `output/`.

### Run the example and figures

From the repository root in an R session:

```r
base::source("run_example.R")
base::source("generate_figures.R")
```

The model's CSV filenames contain timestamps; the figure script currently
uses fixed JPEG filenames and overwrites them on subsequent runs.
See the [reproducibility guide](docs/REPRODUCIBILITY_AND_EXTENSION.md)
for a run-record checklist.

## Model Parameters and Defaults

Defaults combine literature-derived estimates with explicit modeling
assumptions. This distinction matters for interpretation. Key inputs:

| Parameter | Default | Source |
|---|---|---|
| Occult cancer prevalence (high-risk) | 0.56% | 2025 prolapse hysterectomy cohort |
| Occult cancer prevalence (low-risk) | 0.22% | 2021 meta-analysis |
| High-risk fraction tested | 30% | Modeled from practice pattern surveys |
| Baseline detection without testing | 10% | Modeled assumption — cancers found without any preoperative evaluation |
| TVUS sensitivity / specificity | 94.1% / 66.8% | Postmenopausal bleeding diagnostic review (4mm threshold) |
| Pipelle sensitivity / specificity | 100% / 98% | Conditional on adequate sample |
| Pipelle inadequate sample rate | 29.1% | 2025 office biopsy cohort |
| Pipelle inadequate-sample follow-up rate | 50% | Modeled assumption — proportion undergoing further workup |
| Pipelle inadequate-sample follow-up sensitivity | 88% | Modeled — set equal to D&C sensitivity |
| D&C sensitivity / specificity | 88% / 98.4% | 2023 systematic review/meta-analysis |
| TVUS cost | $125.23 | 2022 CMS nonfacility estimate |
| TVUS abnormal-result workup cost | $172.55 | Office biopsy cost applied to an abnormal TVUS |
| Pipelle cost | $172.55 | 2022 prolapse preop evaluation study |
| Pipelle false-positive follow-up cost | $172.55 | Repeat office biopsy cost |
| Pipelle inadequate-sample follow-up cost | $2,310 | Modeled assumption — operative workup after an inadequate sample |
| Concurrent D&C incremental cost | $800 | Marginal OR cost estimate |
| Concurrent D&C false-positive cost | $0 | Modeled assumption — sampling shares the surgical anesthetic |
| D&C effective detection credit | 50% | Modeled (results return post-procedure) |
| Delayed cancer diagnosis cost | $20,000 | Anchored to 90-day endometrial cancer costs |
| QALY gain per early detection | 0.10 | Conservative estimate |
| Willingness-to-pay threshold | $100,000/QALY | Standard US threshold |

To override any parameter:

```r
run_colpocleisis_selective_testing_model(
  high_risk_prevalence = 0.02,
  delayed_cancer_cost = 50000
)
```

## Figures

- **Figure 1** — Cost-effectiveness plane with efficiency frontier
- **Figure 2** — One-way sensitivity tornado diagram with parameter value labels
- **Figure 3** — Threshold analysis showing strategy preference across cancer prevalence (0.1%–5%)

## Model Features

- Efficiency frontier with strong and extended dominance removal
- Sequential ICERs on the frontier
- Net monetary benefit ranking
- Pipelle inadequate-sample follow-up pathway (with recovery detection)
- Concurrent D&C modeled with partial QALY credit (results return after surgery)
- Input validation including cross-parameter consistency checks

## Important structural limitation

The model has no explicit postoperative uterine-access pathway. The
`delayed_cancer_cost` and `qaly_gain_early_detection` terms bundle broad
consequences of missing versus detecting cancer early, and **cannot**
be interpreted as a measured access penalty specifically caused by
LeFort closure. The proposed hysteropexy/SCH comparison requires new,
procedure-specific pathways; simply setting those terms to zero would
be misleading. Details: [model specification](docs/MODEL_SPECIFICATION.md).

## What This Is Not

This is a threshold-style expected-value model for abstract development and rapid scenario testing. It is not a full Markov model, microsimulation, or lifetime cost-effectiveness analysis. Test accuracy parameters are drawn from postmenopausal bleeding literature, not specifically from asymptomatic colpocleisis candidates.

## Abstract Status

Manuscript (393 words) is in `manuscript.txt` with figure legends appended.

## Methodological source

The decision-model architecture in this repository — single self-contained R file, explicit parameter defaults, efficiency-frontier analysis with strong and extended dominance removal, one-way sensitivity, and threshold analysis — is patterned after the companion code published with:

> Larose TL, Meheus F, Brennan P, Johansson M, Robbins HA. **Assessment of biomarker testing for lung cancer screening eligibility.** *JAMA Netw Open.* 2020;3(3):e200409. doi:[10.1001/jamanetworkopen.2020.0409](https://doi.org/10.1001/jamanetworkopen.2020.0409).
>
> Companion code: [hilaryrobbins/costeff_lung_biom_public](https://github.com/hilaryrobbins/costeff_lung_biom_public)

The clinical domain is unrelated (lung cancer screening), but the analytic structure is what we borrowed. Manuscripts based on this repository should cite Larose et al. 2020 in the Methods section when describing the cost-effectiveness framework.

## Contact

Tyler Muffly
