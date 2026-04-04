# Cost-Effectiveness of Selective Endometrial Evaluation Before LeFort Colpocleisis

A threshold-style decision analysis comparing four preoperative endometrial evaluation strategies before LeFort colpocleisis for detection of occult endometrial cancer.

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
- Transvaginal ultrasound becomes the preferred strategy when high-risk prevalence exceeds **approximately 0.8%**, achievable in women with postmenopausal bleeding, obesity, tamoxifen use, or Lynch syndrome
- Results are most sensitive to **cancer prevalence** and **delayed diagnosis cost**

## Repository Structure

```
colpocleisis_costeff/
├── colpocleisis_selective_testing_model.R   # Main model function
├── run_example.R                            # Quick-start script (runs base case, prints results)
├── generate_figures.R                       # Generates all 3 publication figures
├── manuscript.txt                           # Abstract text (423 words) + figure legends
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

```bash
Rscript generate_figures.R
```

Produces three JPEG files (300 DPI) in `output/`.

### Run everything at once

```bash
Rscript run_example.R      # model + CSV tables
Rscript generate_figures.R  # all 3 figures
```

## Model Parameters and Defaults

All defaults are literature-based. Key sources:

| Parameter | Default | Source |
|---|---|---|
| Occult cancer prevalence (high-risk) | 0.56% | 2025 prolapse hysterectomy cohort |
| Occult cancer prevalence (low-risk) | 0.22% | 2021 meta-analysis |
| High-risk fraction tested | 30% | Modeled from practice pattern surveys |
| TVUS sensitivity / specificity | 94.1% / 66.8% | Postmenopausal bleeding diagnostic review (4mm threshold) |
| Pipelle sensitivity / specificity | 100% / 98% | Conditional on adequate sample |
| Pipelle inadequate sample rate | 29.1% | 2025 office biopsy cohort |
| D&C sensitivity / specificity | 88% / 98.4% | 2023 systematic review/meta-analysis |
| TVUS cost | $125.23 | 2022 CMS nonfacility estimate |
| Pipelle cost | $172.55 | 2022 prolapse preop evaluation study |
| Concurrent D&C incremental cost | $800 | Marginal OR cost estimate |
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

## What This Is Not

This is a threshold-style expected-value model for abstract development and rapid scenario testing. It is not a full Markov model, microsimulation, or lifetime cost-effectiveness analysis. Test accuracy parameters are drawn from postmenopausal bleeding literature, not specifically from asymptomatic colpocleisis candidates.

## Abstract Status

Manuscript (423 words) is in `manuscript.txt` with figure legends appended.

## Contact

Tyler Muffly
