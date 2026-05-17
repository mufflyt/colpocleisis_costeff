# Onboarding: Cost-Effectiveness of Selective Endometrial Evaluation Before LeFort Colpocleisis

**For:** Michelle Batlle (Michelle.batlle@cuanschutz.edu)
**Lead:** Tyler Muffly, MD — Department of Obstetrics & Gynecology, Denver Health
**Repo:** https://github.com/mufflyt/colpocleisis_costeff (local: `/Users/tylermuffly/colpocleisis_costeff`)
**Status:** The decision model runs end-to-end, all three figures are generated, and a 423-word abstract is drafted. Your job is to turn that abstract into a full manuscript.
**You do not need to run any R code.** Everything you need to write the paper is already in this repo as plain text, CSVs, and image files. Instructions for re-running are included only as a safety net.

---

## 1. The paper in plain language

LeFort colpocleisis is a surgery that closes the vaginal canal to treat severe pelvic organ prolapse, usually in older women who do not want to preserve sexual function. The catch: after a LeFort, you cannot easily get back into the uterus to look for cancer. So surgeons have long debated whether every patient should get an endometrial workup *before* the surgery — even when she has no bleeding and no risk factors.

**Our question:** Is it actually worth the cost to screen these women preoperatively for endometrial cancer, and if so, which test is the best buy?

**What we did:** We built a cost-effectiveness decision model in R comparing four strategies:

1. **No testing** — go straight to surgery.
2. **Transvaginal ultrasound (TVUS)** — non-invasive imaging in higher-risk women; abnormal results trigger a follow-up biopsy.
3. **Office Pipelle biopsy** — in-office tissue sample in higher-risk women.
4. **Concurrent D&C** — tissue sample taken in the operating room during the colpocleisis itself.

For each strategy, the model calculates total cost, quality-adjusted life-years (QALYs) gained, and the incremental cost-effectiveness ratio (ICER). It also identifies which strategies are "dominated" (worse on both axes — strictly inferior).

**Headline finding:** At the base-case occult cancer prevalence (0.56%), **no testing wins.** Only TVUS and no testing are on the efficiency frontier; Pipelle and concurrent D&C are dominated. TVUS only becomes preferable when prevalence rises above **~0.8%**, which is the kind of risk you see in women with postmenopausal bleeding, obesity, tamoxifen use, or Lynch syndrome.

**Clinical implication:** Routine preoperative endometrial evaluation is not cost-effective for low-risk asymptomatic women planning a LeFort. A risk-stratified approach — TVUS only above the prevalence threshold — is the right policy.

---

## 2. Where this code came from

There are **two** prior code sources you must cite. Both go in the Methods section. Both will be expected by reviewers.

### 2a. The published methodological source (cite in Methods)

The decision-model architecture — single self-contained R file, explicit parameter defaults, efficiency-frontier analysis, one-way sensitivity, threshold analysis — is patterned after a published JAMA Network Open cost-effectiveness analysis whose authors deposited their full analytic code as a public companion repository. This was the working template I used to scaffold the colpocleisis model.

**Published paper:**

> Larose TL, Meheus F, Brennan P, Johansson M, Robbins HA. **Assessment of biomarker testing for lung cancer screening eligibility.** *JAMA Netw Open.* 2020;3(3):e200409. doi:10.1001/jamanetworkopen.2020.0409.

**Companion code repository:**

> Robbins HA. *costeff_lung_biom_public*. GitHub. https://github.com/hilaryrobbins/costeff_lung_biom_public

Larose et al. modeled the incremental cost-effectiveness of adding biomarker testing to lung cancer screening eligibility, varying test cost and case-capture parameters against a $50,000-per-life-year-gained willingness-to-pay threshold. The clinical domain (lung-cancer screening) is completely different from ours, but the *structural pattern* is what we borrowed: one well-documented model file that takes a parameter list, returns a strategy table and efficiency frontier, and can be re-run with overridden parameters for sensitivity analysis.

**In the Methods section of our manuscript:** cite Larose et al. 2020 when describing the decision-model framework and explicitly note that the analytic code is adapted from the public companion repository at github.com/hilaryrobbins/costeff_lung_biom_public. This is good scientific practice — it makes the methodological lineage transparent and gives reviewers a reference implementation to compare against.

### 2b. Our own scaffold repo (cite for transparency)

Before this clean version was built, I had a quick-turn scaffold repo with placeholder parameters set up the day before an abstract deadline:

**Parent scaffold repo:** https://github.com/mufflyt/cost_lefort

The current `colpocleisis_costeff` repo is the cleaned-up successor:

- All parameters were replaced with literature-grounded values (see §5 for the Methods table).
- The model gained a proper efficiency-frontier algorithm (strong + extended dominance removal), sequential ICERs, and net monetary benefit ranking.
- Three publication-quality JPEG figures were added.
- The 423-word abstract was drafted.

When you cite "methods" in the paper, the citation is to this repo (`colpocleisis_costeff`), not the parent scaffold. The parent is only relevant if a reviewer asks about the lineage — feel free to mention it as "previously archived at github.com/mufflyt/cost_lefort" if you want to be transparent.

---

## 3. What's already done (what you can pull from)

Every artifact you need to write the paper is already in the repo. You should not need to touch R at all unless you want to re-run a sensitivity analysis.

| Where | What |
|---|---|
| `manuscript.txt` | The full 423-word structured abstract (Intro / Methods / Results / Conclusions) plus all three figure legends. **Start here.** |
| `README.md` | Plain-English summary, full parameter table with literature sources, repo structure. |
| `output/figure1_ce_plane.jpeg` | Figure 1: cost-effectiveness plane with the efficiency frontier. |
| `output/figure2_tornado.jpeg` | Figure 2: one-way sensitivity tornado diagram. |
| `output/figure3_threshold.jpeg` | Figure 3: threshold analysis (the 0.8% prevalence inflection point). |
| `output/*.csv` | Numeric strategy and frontier tables — these are the exact numbers behind the figures, so you can pull any value into the Results section verbatim. |
| `colpocleisis_selective_testing_model.R` | The model itself — ~830 lines of documented R. You should not need to edit this. It is the single source of truth for what the model does. |
| `generate_figures.R` | The script that produces the three JPEGs. You should not need to edit this either. |
| `run_example.R` | A 24-line wrapper that runs the model and prints the strategy table, frontier, and summary sentence. |

---

## 4. What you need to do (the manuscript)

The abstract is in `manuscript.txt`. Build it out to a full short report — probably 2,000–2,500 words plus the three figures and one parameter table. Here is the structure I'd use:

**1. Introduction (~400–600 words).** Burden of pelvic organ prolapse in older women, role of obliterative procedures (LeFort), surgeons' anxiety about occult endometrial cancer, the actual prevalence numbers (0.22%–2.6%), survey evidence that 68% of colpocleisis surgeons do preop testing despite weak evidence, prior guidelines (AUGS, ACOG, AAGL), and the gap this paper fills. End with one objective sentence.

**2. Methods (~500–700 words).**
- Decision model type: threshold-style expected-value decision analysis over a one-year horizon (not a Markov model — be honest about this).
- Hypothetical cohort: 10,000 women planning LeFort colpocleisis.
- Four strategies (list them again from §1 above).
- Higher-risk subgroup: 30% of the cohort gets selectively tested.
- Test characteristics and costs: pull directly from the table in `README.md` (and reproduced in §5 below) — every value has a literature source.
- Outcomes: total cost, QALYs, ICERs, net monetary benefit at $100,000/QALY.
- Efficiency frontier with removal of dominated strategies (both strong and extended dominance).
- One-way sensitivity analysis (Figure 2) and threshold analysis on cancer prevalence (Figure 3).
- Concurrent D&C explicitly receives only 50% QALY credit because pathology results return *after* the obliterative procedure is completed — so a positive result cannot change the surgical plan. This is a meaningful modeling choice and reviewers will ask about it.
- IRB statement: not human subjects research (modeling study, no patient-level data).

**3. Results (~400–600 words + the three figures + 1 table).** Use the headline numbers from §1 and the CSV tables in `output/`. The key sentences are already drafted in `manuscript.txt`.

**4. Discussion (~700–900 words).**
- Restate the finding: at base-case prevalence, no testing wins; TVUS only wins above ~0.8%.
- Compare to existing practice (the 68% surveyed-surgeon number is the rhetorical hook).
- Why Pipelle is dominated: 29.1% inadequate-sample rate undermines its high theoretical accuracy.
- Why concurrent D&C is dominated: results return after the obliterative procedure, so partial QALY credit.
- Implications for shared decision-making: a checklist of risk factors (postmenopausal bleeding, obesity, tamoxifen use, Lynch syndrome) that crosses the 0.8% threshold.
- **Limitations:** parameters drawn from postmenopausal-bleeding literature, not specifically from asymptomatic colpocleisis candidates; not a full lifetime Markov model; expected-value framework cannot capture rare-event tail risk well; Medicare-anchored costs may not generalize to commercial payers; QALY gain per early detection (0.10) is a conservative estimate; high-risk-fraction (30%) is modeled, not empiric.
- Future directions: Markov extension, microsimulation, prospective validation in a colpocleisis cohort.

**5. Conclusion (~100 words).** Two or three sentences.

**6. References.** Pull the citations from the parameter table sources (§5).

---

## 5. The parameter table you'll need for Methods

This is straight from `README.md` and is the canonical version. Reproduce it as Table 1 in the manuscript.

| Parameter | Default | Source |
|---|---|---|
| Occult cancer prevalence (high-risk) | 0.56% | 2025 prolapse hysterectomy cohort |
| Occult cancer prevalence (low-risk) | 0.22% | 2021 meta-analysis |
| High-risk fraction tested | 30% | Modeled from practice pattern surveys |
| TVUS sensitivity / specificity | 94.1% / 66.8% | Postmenopausal bleeding diagnostic review (4 mm threshold) |
| Pipelle sensitivity / specificity | 100% / 98% | Conditional on adequate sample |
| Pipelle inadequate sample rate | 29.1% | 2025 office biopsy cohort |
| D&C sensitivity / specificity | 88% / 98.4% | 2023 systematic review / meta-analysis |
| TVUS cost | $125.23 | 2022 CMS nonfacility estimate |
| Pipelle cost | $172.55 | 2022 prolapse preop evaluation study |
| Concurrent D&C incremental cost | $800 | Marginal OR cost estimate |
| D&C effective detection credit | 50% | Modeled (results return post-procedure) |
| Delayed cancer diagnosis cost | $20,000 | Anchored to 90-day endometrial cancer costs |
| QALY gain per early detection | 0.10 | Conservative estimate |
| Willingness-to-pay threshold | $100,000/QALY | Standard US threshold |

For the manuscript, each parameter needs a real citation. The "Source" column above is descriptive; you'll need to populate the actual reference list. If you cannot find a source for a row, ping me and I'll point you to the article I used.

---

## 6. Prior literature — the decade-old precedent you must address

There is one published precedent in *Urogynecology* (then *Female Pelvic Medicine & Reconstructive Surgery*) that asked nearly the same question we are asking, 12 years earlier. You **must** cite and engage with this paper — both because reviewers will demand it, and because the convergence between our findings and theirs is the rhetorical hook for the Discussion.

**Kandadai P, Flynn M, Zweizig S, Patterson D.** *Cost-utility of routine endometrial evaluation before Le Fort colpocleisis.* Female Pelvic Med Reconstr Surg. 2014;20(3):168–173. doi:10.1097/SPV.0000000000000043. PMID 24763159. [LWW abstract](https://journals.lww.com/fpmrs/Abstract/2014/05000/Cost_Utility_of_Routine_Endometrial_Evaluation.10.aspx) · [PubMed](https://pubmed.ncbi.nlm.nih.gov/24763159/)

**What they did.** Three-strategy decision-analysis (cost-utility) model in low-risk women undergoing LeFort colpocleisis: (1) endometrial biopsy, (2) transvaginal ultrasound, (3) no evaluation. Single cohort, no risk stratification, no efficiency frontier.

**What they found.** At standard WTP thresholds ($50,000 and $100,000 per QALY), **no evaluation dominated both biopsy and TVUS**. Biopsy became preferred only at an implausible 64% cancer probability.

**What our paper agrees with them on.** The headline finding — routine preoperative endometrial evaluation is not cost-effective in low-risk women undergoing LeFort. Our analysis independently replicates their central conclusion 12 years later with updated cost and accuracy parameters. This is *confirmatory*, not redundant.

**What our paper does that theirs did not (this is the contribution).**

| Dimension | Kandadai 2014 | Our paper |
|---|---|---|
| Strategies modeled | 3: biopsy, TVUS, no evaluation | **4**: no testing, selective TVUS, selective Pipelle, **concurrent D&C** |
| Application of testing | Universal in the modeled cohort | **Selective** — applied only to a 30% higher-risk subgroup, which is how clinicians actually decide |
| Concurrent D&C strategy | Not modeled | Modeled with **50% QALY credit** because pathology returns after the obliterative procedure is complete — so a positive result cannot change the surgical plan |
| Pipelle inadequate-sample pathway | Not modeled | **29.1% inadequate-sample rate** is what dominates the Pipelle pathway — this is the mechanism prior analyses missed |
| Efficiency frontier analysis | Not reported | Strong + extended dominance removal; sequential ICERs on the frontier; net monetary benefit ranking |
| Clinically actionable threshold | 64% cancer probability (uninterpretable in practice) | **~0.8% prevalence** — a number that maps directly to postmenopausal bleeding, obesity, tamoxifen use, or Lynch syndrome |
| Cost parameters | 2014 reimbursement landscape | 2022 CMS estimates: Pipelle $172.55, TVUS $125.23, concurrent D&C incremental $800 |
| Test accuracy sources | Era-specific (pre-2014) | Updated to 2021 meta-analysis (low-risk prevalence), 2023 D&C systematic review, 2025 office biopsy cohort (Pipelle inadequate rate), 2025 prolapse hysterectomy cohort (high-risk prevalence) |

**Recommended Discussion paragraph (use or adapt verbatim):**

> A decade ago, Kandadai et al. examined a similar question with a three-strategy cost-utility model and concluded that no evaluation dominated both biopsy and TVUS at standard willingness-to-pay thresholds in low-risk women planning Le Fort colpocleisis.¹ Our analysis confirms that core finding with updated cost and test-accuracy parameters and extends it in four important ways. First, we model *selective* preoperative testing in a higher-risk subgroup rather than universal testing, mirroring contemporary practice. Second, we identify a clinically actionable prevalence threshold of approximately 0.8% at which TVUS becomes the preferred strategy — a threshold mapped to identifiable risk factors including postmenopausal bleeding, obesity, tamoxifen use, and Lynch syndrome — rather than the uninterpretable 64% cancer probability reported in 2014. Third, we add concurrent dilation and curettage as a fourth strategy and demonstrate that it is dominated because pathology results return after the obliterative procedure is complete, limiting any decision-changing value. Fourth, we incorporate the 29.1% Pipelle inadequate-sample rate documented in contemporary office-biopsy literature, which dominates the Pipelle pathway in a way prior analyses did not capture. The convergence between the 2014 and 2026 conclusions — that routine preoperative endometrial evaluation is not cost-effective in average-risk women — is strengthened, not weakened, by a decade of additional literature and an updated cost landscape.

**For the Introduction:** mention Kandadai et al. once, briefly, as the prior cost-utility analysis. Save the full comparison for the Discussion.

**For the parameter table (Table 1):** if you can find the exact parameter values Kandadai used (cancer prevalence, test sensitivities/specificities, costs), consider adding a footnote column showing how each parameter has changed since 2014. That's a small thing reviewers love.

---

## 7. Target journal

**Primary submission target: *Urogynecology* (the AUGS journal, formerly *Female Pelvic Medicine & Reconstructive Surgery*).** The paper is squarely in AUGS scope: surgical decision-making in obliterative prolapse repair, with a cost-effectiveness angle. Format the manuscript to *Urogynecology* author guidelines from the outset.

Backup options if rejected:
- *International Urogynecology Journal* — also a strong audience match.
- *Obstetrics & Gynecology* ("Green Journal").
- *American Journal of Obstetrics & Gynecology* (AJOG).
- *Value in Health* — if reframed primarily as a cost-effectiveness methodology paper.

---

## 8. Open questions to resolve before submission

1. **Cohort size sensitivity.** We modeled n=10,000. Does the conclusion change at smaller realistic clinical cohorts? Probably not (results are deterministic), but worth a sentence.
2. **High-risk fraction.** The 30% figure is modeled. If you can pull a real-world estimate from a colpocleisis cohort (postmenopausal bleeding rates + obesity + tamoxifen + Lynch), the paper gets stronger.
3. **Willingness-to-pay threshold.** $100,000/QALY is standard but conservative; consider showing $150,000/QALY as a secondary analysis.
4. **Equity discussion.** Older women in rural areas may have very different access to TVUS — worth a paragraph in Discussion if you want a broader policy framing.
5. **Authorship order and contributions** — coordinate with me before submission.

---

## 9. If you do want to re-run the model (you probably won't need to)

You can write the entire paper without ever opening RStudio. But if you want to run a custom scenario (e.g., what if we set high-risk prevalence to 1.5%?), here is the minimum:

**Install R** (≥ 4.2) from cran.r-project.org. Then in R:

```r
install.packages(c("tibble", "dplyr", "purrr", "rlang", "readr",
                   "ggplot2", "scales", "forcats", "tidyr"))
```

In a terminal:

```bash
cd /path/to/colpocleisis_costeff
Rscript run_example.R       # runs base case, prints tables, saves CSVs
Rscript generate_figures.R  # produces all three JPEG figures
```

To run a custom scenario, open R and:

```r
source("colpocleisis_selective_testing_model.R")
custom <- run_colpocleisis_selective_testing_model(
  high_risk_prevalence = 0.015,   # 1.5% instead of the default 0.56%
  delayed_cancer_cost = 50000     # raise penalty for missed cancer
)
print(custom$strategy_table)
print(custom$frontier_table)
cat(custom$summary_sentence, "\n")
```

If any of that errors, send me the error message — don't try to fix it yourself.

---

## 10. Working agreement

- Drop drafts in a shared folder (Google Drive or Dropbox — your preference, just send me the link).
- Don't push directly to `main` on GitHub. If you want to edit the manuscript text or change a parameter, send me the change and I'll commit it. The repo itself should stay a stable methods deposit.
- Ping me early with questions — easier to course-correct in Week 1 than Week 6.

---

## 11. Contact

- **Tyler Muffly, MD** — tyler.muffly@dhha.org — PI, Denver Health Ob/Gyn
- **Michelle Batlle** — Michelle.batlle@cuanschutz.edu — manuscript lead
