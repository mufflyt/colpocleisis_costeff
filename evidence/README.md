# Evidence and assumptions registry

The machine-readable input registry is
[`screening_assumptions_registry.csv`](screening_assumptions_registry.csv).
It describes each input required by the shared screening model, evidence
status, source population, applicable procedure or pathology, and the next
adjudication step. **Blank numerical cells are intentionally unresolved.**

## Research extraction update (November 2026)

This repository now includes:
- [`occult_pathology_study_counts.csv`](occult_pathology_study_counts.csv),
  a source-level table of study numerators and denominators for
  occult invasive cancer, EIN/atypical hyperplasia, and selected
  *conditional* postoperative procedures.
- [`R/evidence_registry.R`](../R/evidence_registry.R), which reads both
  CSV files, validates the counts, and calculates study-level
  Clopper-Pearson **exact binomial 95% confidence intervals**.
- [`tests/test_evidence_registry.R`](../tests/test_evidence_registry.R),
  which checks event totals, CI values, and that no clinical model
  parameters are silently filled.

The input registry currently records **provisional** pooled invasive
endometrial-cancer prevalence 0.535% (95% CI 0.398%-0.718%),
and EIN/atypical hyperplasia 1.35% (95% CI 0.36%-4.95%).
These came from a preliminary research synthesis; the complete
meta-analytic study-selection and fitting code has **not** been
reproduced in this repository. They are not direct estimates for
asymptomatic postmenopausal women with stage III uterovaginal prolapse.

An EIN alternative prevalence of 0.70% (0.17%-2.82%) excludes the high
SCH cohort as an **exploratory sensitivity scenario**, not as an
automatic base case.

The additional-staging pooled estimate of 62% (19%-92%) is likewise
provisional and based on only 35 occult cancers across three cohorts.
The directly observed 10/30 (33.3%; exact 95% CI 17.3%-52.8%)
is separately preserved. Completion surgery after occult cancer in
SCH is only 2/3 (66.7%; exact 95% CI 9.4%-99.2%) across two small
series; this is too sparse for robust procedure-specific inference.

Historical CMS nonfacility unit estimates of **$125.23 per TVUS**
and **$172.55 per office endometrial biopsy** are recorded from
https://pubmed.ncbi.nlm.nih.gov/36276784/.
These are **unit prices, not all-in screening-pathway costs**,
and must be reconciled to a common price year and diagnostic
follow-up pathway.

The $10,000/$20,000/$35,000 downstream cost entries are
**scenario low/base/high bounds, not a confidence interval**.
The `interval_kind` column distinguishes exact binomial 95% CIs,
provisional pooled CIs, scenarios, and unavailable intervals.

### R usage

```r
base::source("R/evidence_registry.R")
evidence <- read_screening_evidence_registry()
base::print(evidence$study_counts)
scenarios <- get_provisional_prevalence_scenarios(evidence)
base::print(scenarios)
```

Neither function runs the clinical CEA or changes the
`NA` values in `make_shared_preop_screening_inputs()`.
A formal synthesis should verify all denominators, overlapping
cohorts, symptom definitions, staging indications, and publication
status before updating the model.

## What was established

- A surgical POP series reported 30 occult endometrial cancers in
  5,376 procedures (0.56%). Ten of the 30 women underwent a subsequent
  staging operation (33.3% conditional on identified occult EC).
  Source: https://pmc.ncbi.nlm.nih.gov/articles/PMC12681478/
  This does not automatically give prevalence in postmenopausal stage III
  prolapse candidates or individual hysteropexy procedures.
- A 2026 systematic review including 33 studies reported 0.6%
  pooled malignant pathology (95% CI 0.0%-1.0%) with substantial
  heterogeneity (I2=93.5%). Its outcome is *any malignancy*, not
  necessarily endometrial cancer or EIN, and pooling is sensitive to
  surgical selection.
  Source: https://pubmed.ncbi.nlm.nih.gov/42811185/
- A retrospective series of secondary cervical stump surgery documents
  feasibility and indications, including some unexpected malignancies,
  but is **not** a directly transferable probability for SCH performed
  specifically with sacrocolpopexy.
  Source: https://pmc.ncbi.nlm.nih.gov/articles/PMC8553675/

The 0.56% and 0.6% estimates come from different populations and
outcomes. **Do not combine them into one EIN + cancer prevalence.**

## Essential data missing for causal screening conclusions

1. Prevalence of asymptomatic EIN **separate from** invasive cancer,
   ideally among postmenopausal stage III prolapse candidates.
2. Intention-to-screen sensitivity and specificity of complete TVUS
   and endometrial sampling pathways in this population, including
   failed/inadequate tests and diagnostic follow-up.
3. Procedure/pathology-specific probability that an unrecognized
   lesion is diagnosed postoperatively within the same horizon.
4. Consequences of preoperative diagnosis versus unexpected pathology
   on surgery performed, staging, reoperation, retained cervix,
   treatment, costs, quality of life, and subsequent health.
5. Perspective, price year, model time horizon, and discounted
   longer-term outcomes if incident disease is added.

## Assumption hierarchy

1. **Direct estimate:** reported numerator/denominator from an
   asymptomatic postmenopausal stage III POP cohort with the same
   surgical pathway and relevant outcome.
2. **Transported estimate:** related POP cohorts, flagged for
   selection and diagnostic applicability.
3. **Indirect evidence:** other benign surgery cohorts or mixed
   gynecologic populations; use only in broad scenarios.
4. **Expert elicitation:** explicitly identify experts, question,
   range, agreement method, and analysis impact.
5. **Unidentified:** leave parameter blank, test thresholds and
   value of information instead of fabricating precision.

For every input, record whether it is marginal or conditional.
For example 10/30 = 33.3% is conditional on occult cancer among
women already known to have occult disease, NOT the risk of a
second operation in all asymptomatic prolapse patients.

## Model design and acceptance gate

The shared model currently has six operation labels, three broad
anatomic consequence groups, and a single shared screening
strategy definition. The registry is **not** yet a model-ready
calibration file: it is a source audit.

A procedure-specific recommendation is not allowed until:

- All mandatory input rows have adjudicated numeric estimates.
- EIN and invasive cancer are distinct and mutually exclusive
  baseline pathology categories for this first model.
- The horizon matches across procedures and costs/utilities.
- Clinical screening guidance does not extend to patients with
  bleeding, suspicious imaging, or other diagnostic indications.
- The CI adversarial and structural test suites pass.
- The clinical team reviews oncologic pathways and uncertainties.
- Sensitivity analysis demonstrates whether procedure-specific
  decisions are robust over credible ranges.

## Review assignments

Clinical investigators: adjudicate disease prevalence, unexpected
postoperative diagnoses, operative conversions, and cervix pathways.

Health economists: determine incremental costs, utility consequences,
model horizon, and avoidable downstream expense without double-counting.

Methodologists: verify conditional denominators, transportability,
sensitivity scenarios, and reproducible model checks.

Update the CSV with source-level estimates and a citation before
running clinical calibration. Preserve missing inputs as missing
until reviewed.
