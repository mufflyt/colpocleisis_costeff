# Implemented model specification and interpretation

Status: documentation of the current `master` implementation, not a
prospective clinical guideline. Inspect the exact source-code revision before
using numerical statements in a manuscript.

## Research question and population

The decision analysis compares four selective preoperative endometrial
evaluation policies for a hypothetical cohort of 10,000 patients planning
LeFort colpocleisis. It is an expected-value threshold model, not a
patient-level simulation, a longitudinal cancer model, or a validated
decision tool for an individual patient.

The default cohort has a 30% higher-risk group (cancer prevalence 0.56%)
and a 70% lower-risk group (prevalence 0.22%). Screening applies only to
the higher-risk group. The risk categories are model inputs, not a
validated prediction algorithm for assigning patients to categories.
The base-case risk values and proportions must not be presented as
measured prevalence for all colpocleisis patients.

## Strategies represented in code

1. No routine testing: a modeled 10% baseline capture of prevalent cancer.
2. Selective TVUS: only the high-risk group is tested; abnormal scans
   incur a follow-up cost and incremental detection is determined by
   sensitivity after accounting for baseline capture.
3. Selective Pipelle: inadequate samples, incomplete follow-up of those
   samples, and conditional adequacy-specific sensitivity are explicit.
4. Selective concurrent D&C: tissue is collected at surgery; because
   results return after the operation, incremental detections receive a
   50% QALY-credit factor in the base case.

Code entry point:
`run_colpocleisis_selective_testing_model()` in
`colpocleisis_selective_testing_model.R`, beginning near line 122.
The strategy-specific cost/QALY arithmetic is near lines 477-614;
the assembled strategy table and cost components are near lines 621-697.

## Endpoint definitions

For each strategy, the model computes:

- Number of prevalent cancers, true detections, effective early
  detections, and true misses.
- Test costs, modeled follow-up costs, and missed-cancer costs.
- **Total cost** = testing + follow-up + number of true missed cancers
  times `delayed_cancer_cost`.
- **QALYs gained** = effective early detections times
  `qaly_gain_early_detection`.
- **Net monetary benefit (NMB)** = QALYs gained times
  `willingness_to_pay` minus total cost.
- ICERs and an efficiency frontier after dominance evaluation.

These are *incremental QALY credits for early detection*, not absolute
lifetime QALYs for the cohort. The model does not simulate cancer stage,
survival, or progression. The 50% D&C credit affects QALYs; the D&C
missed-cancer cost uses the count of true misses. Thus its effectiveness
credit and its cost logic are not identical.

## Default inputs to scrutinize

| Input | Default | Interpretation |
| --- | ---: | --- |
| High-risk fraction | 30% | Assumed screening eligibility |
| High-risk cancer prevalence | 0.56% | Model assumption from literature |
| Low-risk cancer prevalence | 0.22% | Model assumption from literature |
| Baseline capture | 10% | Modeled detection without routine testing |
| TVUS sensitivity / specificity | 94.1% / 66.8% | External diagnostic literature |
| Pipelle inadequate sample | 29.1% | External estimate |
| Pipelle inadequate follow-up | 50% | Assumed |
| Concurrent D&C effective-detection credit | 50% | Assumed post-surgical timing penalty |
| Delayed cancer diagnosis cost | $20,000 | Aggregated missed-cancer cost |
| QALY gain per early detection | 0.10 | Aggregated assumed benefit |
| Willingness to pay | $100,000/QALY | Decision threshold |

All precise defaults are in the function signature. The README and
`ONBOARDING.md` give source notes, but their citation claims and
numeric results should be independently checked before journal submission.
In particular, do not describe all inputs as empirically estimated.

## What the current model does *not* contain

There is **no separate parameter or explicit clinical decision branch**
for difficult uterine access after obliterative surgery. Specifically,
there is no modeled postoperative TVUS/office biopsy/hysteroscopy route,
no time-to-cancer diagnosis, no stage-specific therapy, no survival
transition, and no procedure-specific reoperation pathway.

The broad `delayed_cancer_cost = 20000` and
`qaly_gain_early_detection = 0.10` terms aggregate consequences of missed
versus early diagnosis. They cannot be interpreted as an isolated
'LeFort access penalty'. Setting either term to zero is **not** an
identified structural sensitivity analysis of postoperative access.

Similarly, the study does **not** directly estimate the clinical
effectiveness of routine screening in asymptomatic hysteropexy or
supracervical hysterectomy (SCH) populations. The test sensitivity
and specificity inputs are largely from symptomatic diagnostic
populations, so transportability is uncertain.

## Scope and clinical interpretation

The model answers a cost-effectiveness question *conditional on its
assumptions*. It does not replace guideline-directed evaluation of
abnormal uterine bleeding, known risk factors, or suspected malignancy.
'No routine testing' is not a recommendation to ignore symptoms.

An additional caveat: risk thresholds are defined in terms of
**high-risk subgroup prevalence**, not the prevalence of the entire
modeled cohort. Do not translate these thresholds directly into an
individual patient screening recommendation without a validated way
to estimate that person's risk.

## Questions for manuscript review

- What clinical pathway justifies the 10% baseline capture rate?
- What evidence supports assigning 0.10 QALY per early detection?
- Does $20,000 represent all costs of missed cancer, only excess costs,
  or costs specifically associated with LeFort-related restricted access?
- Does the partial D&C QALY credit need a corresponding adjustment to
  postoperative management costs?
- Have cancer/EIN definitions, competing mortality, and incidental
  pathology at surgery been consistently distinguished?
- Can the TVUS and Pipelle accuracy estimates be transported from
  postmenopausal-bleeding cohorts to asymptomatic preoperative patients?
- Are the prevalence threshold and figure outputs reproducible from
  the same source revision used for the AUGS presentation?

These questions are open review items, not established errors.
