# Shared preoperative endometrial screening study: protocol v0

**Status:** architecture and hypothesis-generating implementation only.
No procedure-specific recommendation or prevalence threshold is currently
validated. The model refuses to run with missing clinical inputs.

## Decision problem

For an asymptomatic postmenopausal patient with stage III uterovaginal
prolapse and no independent indication for endometrial workup, what is
the economic value of preoperative evaluation for occult endometrial
intraepithelial neoplasia (EIN) or cancer?

The **decision** is screening versus no routine screening, *conditional
on the intended prolapse procedure*. This is not a comparison of the
operations' total costs, recurrence, or mesh-related outcomes.

### Surgical labels and anatomic groups

| Label | Procedure | Anatomic class |
| --- | --- | --- |
| `tvh_usls` | Vaginal hysterectomy + USLS | Entire uterus removed |
| `usls_hysteropexy` | USLS hysteropexy | Uterus retained |
| `ssls_hysteropexy` | SSLS hysteropexy | Uterus retained |
| `tlh_scp` | TLH + mesh sacrocolpopexy | Entire uterus removed |
| `sch_scp` | SCH + mesh sacrocolpopexy | Corpus removed, cervix retained |
| `sacral_hysteropexy` | Mesh sacral hysteropexy | Uterus retained |

Use TVH/USLS as a clinical reference for vaginal hysteropexy and TLH/SCP
as a clinical reference for abdominal mesh procedures. **Within** each
operation, compare screening strategies. The two reference operations
are not the no-screening counterfactual for other operations.

LeFort is the original separate study, not automatically a seventh
procedure: access and selection differ materially.

## The shared decision tree

For each procedure, each screening pathway, and each disease state:

1. Disease at baseline: neither EIN nor cancer / EIN / invasive cancer.
2. Screening test pathway: positive / negative (sensitivity and
   specificity represent the *complete* testing-and-workup strategy).
3. Preoperative positive disease detection: altered surgical/oncologic
   management with incremental costs and QALYs.
4. After a missed preoperative diagnosis:
   - postoperative diagnosis within a common prespecified horizon;
   - otherwise remaining undetected at that horizon.
5. For negative pathology, a false-positive preoperative result can
   produce further workup, costs, and temporary QALY loss.

One common population prevalence vector and screening table are reused
across all six operations. The operation-specific table supplies the
probability of postoperative detection, and downstream incremental cost
and QALY for each of EIN and cancer under preoperative diagnosis,
postoperative diagnosis, and no diagnosis by horizon.

**Time horizon must be explicit.** First milestone: perioperative
12-month model of *prevalent* EIN/cancer. This does not estimate the
incidence of *new* endometrial cancer during long-term hysteropexy
follow-up. A later lifetime extension requires transition states,
competing mortality, discounting, and stage-specific utilities.

**Cost definition:** all downstream procedure-specific costs are
incremental relative to the chosen prolapse procedure's common
uncomplicated baseline cost, which cancels in within-procedure
comparisons. Do not enter the entire cost of cancer treatment in one
arm unless its comparator includes the same background treatment
cost, or benefits will be exaggerated. Costs of tests and complications
must be counted once. Analytic perspective and price year still need
agreement.

**Utility definition:** enter expected QALYs over the same time horizon,
with common baseline health utilities omitted because they cancel.
`qaly_pre`, `qaly_post`, and `qaly_missed` represent the
incremental consequences of each pathology detection timing, not
published utilities until populated from validated sources or elicitation.

### What the code currently calculates

`R/shared_preop_screening_model.R` defines:

- `make_shared_preop_screening_inputs()`: blank tables; no invented
  clinical inputs.
- `run_shared_preop_screening_model()`: deterministic expected-value
  costs, QALYs, true pre/post detections, false positives, and net
  monetary benefit (NMB). All comparisons are within procedure.
- Incremental NMB and cost/QALYs versus `no_screen` within each
  procedure. There is no extrapolated published prevalence threshold.

The v0 screening strategies are `no_screen`, `tvus_pathway`, and
`biopsy_pathway`. The whole-cohort screening sensitivities and
testing costs in this version correspond to **routine** pathways;
selective testing requires an explicit risk-stratified extension with
screening fractions, subgroup prevalence and costs, rather than
simply multiplying costs and keeping sensitivity constant. Likewise,
D&C is not yet an implemented strategy.

## Evidence screen: what is supported?

| Input or inference | Evidence status | Treatment |
| --- | --- | --- |
| Occult malignant pathology in POP surgery is uncommon | Moderate, heterogeneous | Prior range only, not direct calibration |
| Cancer incidence in a prolapse hysterectomy cohort | Observed cohort | Candidate calibration, assess selection |
| Incidental EIN specifically among asymptomatic women | Not yet extracted | **Missing** |
| TVUS/biopsy screening sensitivity for asymptomatic POP | Not established from PMB studies | **Missing / transportability concern** |
| Benefit of routine screening on mortality/QALYs | Not demonstrated | **Missing** |
| Additional cancer staging after unexpected pathology | Some observational data | Conditional rates, not per-procedure input |
| Procedure-specific post-op detection probability | Mechanistic plausibility, no matched estimates | **Missing** |
| Cost/disutility of retained cervix after SCH cancer | Case series, selected on resection | **Missing population probability** |
| Distinct USLS versus SSLS hysteropexy cancer pathways | No comparative evidence identified | Pool by uterine anatomy initially |
| TVH versus TLH occult pathology management costs | No matched procedure estimates identified | Pool removal class initially |
| Long-term cancer risk after hysteropexy | Insufficient for lifelong screening policy | Later longitudinal model |

### Anchor studies and limitations

1. 2026 global systematic review / consensus:
   https://pubmed.ncbi.nlm.nih.gov/42811185/
   33 studies; pooled malignant pathology 0.6% (95% CI 0.0%-1.0%),
   with I2=93.5%. Six uterus-preserving series observed 0.50% vs
   0.58% malignancy in screened vs unscreened cohorts (p=0.88).
   This is **not evidence of noninferiority of screening outcomes**,
   and the outcome includes malignancies beyond endometrial carcinoma.
2. `Incidence and Outcomes of Occult Uterine Cancer in Uteri Removed
   for Prolapse`:
   https://pmc.ncbi.nlm.nih.gov/articles/PMC12681478/
   0.56% incidental endometrial cancer across 5,376 POP surgeries;
   10/30 cancer patients underwent a second staging procedure.
   That 33.3% is conditional on diagnosed occult cancer and is **not**
   a probability for every patient or every type of prolapse operation.
3. `Incidence of uterine cancer after supracervical hysterectomy`:
   https://pubmed.ncbi.nlm.nih.gov/41995800/
   Benign-SCH cohort, not exclusively POP or asymptomatic PMP:
   0.37% incidental malignancy and 0.14% subsequent malignancy.
   Do not transport these rates to stage III POP without adjustment.
4. `Retrospective analysis of secondary resection of the cervical
   stump after subtotal hysterectomy`:
   https://pmc.ncbi.nlm.nih.gov/articles/PMC8553675/
   Selected stump-resection cases; shows feasibility of downstream
   procedures but not the incidence or causal cost of reoperation.
5. National Cancer Institute screening summary:
   https://www.cancer.gov/types/uterine/hp/endometrial-screening-pdq
   Routine screening of asymptomatic women has not demonstrated
   endometrial cancer mortality reduction; postmenopausal-bleeding
   diagnostic accuracy should not be treated as validated screening
   accuracy in asymptomatic candidates.
6. CHEERS 2022:
   https://pmc.ncbi.nlm.nih.gov/articles/PMC8749494/
   Report model scope, comparators, perspectives, horizon, assumptions,
   structural and parameter uncertainty transparently.

## Evidence-based distinction decision

**Anatomy is a credible reason to propose different clinical pathways,
but data are not yet sufficient to assign six independent numerical
downstream outcomes or six credible procedure-specific thresholds.**

Recommended primary analysis strata until better evidence exists:

- Complete uterus and cervix removed: TVH/USLS and TLH/SCP.
- Uterus retained: USLS, SSLS, and mesh sacral hysteropexy.
- Corpus removed, cervix retained: SCH/SCP.

Keep the individual six procedure labels as reporting strata, but
**share pathway parameters within anatomy groups by default**. Vary
operation-specific costs only where real source data support it.
This is a prespecified pooling choice, not empirical equivalence.

Assess whether procedure distinctions actually matter by running:

1. **Pooled anatomy base case** with independently verified inputs.
2. **One-way and two-way threshold surfaces** for:
   - postop detection probability,
   - avoidable second-procedure costs,
   - cancer/EIN prevalence,
   - biopsy/TVUS false positives and inadequate sample management,
   - incremental QALY from diagnosis timing.
3. **Structural scenarios**: equal post-op access for hysteropexies;
   partial access for SCH; different second-surgery probabilities;
   all hysterectomy specimens examined versus imperfect ascertainment.
4. **VOI analysis** or expected NMB uncertainty, only when joint input
   distributions are evidence-grounded; do not dress guesses as PSA.
5. **Decision robustness**: report if the NMB-preferred policy differs
   between procedures *over credible input ranges*, and state clearly
   when evidence cannot decide.

## Important gaps and work allocation

- **Jerry / clinical evidence team:** collect studies with explicit
  asymptomatic PMP denominators; EIN and cancer separately;
  presence/absence of TVUS and biopsy; stage and subsequent
  management; retained-cervix scenarios; extraction method.
- **Modeling team:** confirm time horizon, perspective, price year;
  standardize full testing pathways, false positives and inadequate
  samples; represent diagnosis timing and calculate NMB.
- **Clinical adjudication:** define the operation actually performed
  after positive screening; which suspected lesions prompt conversion
  to full hysterectomy or oncology referral; distinguish EIN from
  endometrial cancer; ensure cervical pathology/cervical screening
  are not incorrectly conflated with endometrial screening.
- **Methodology:** adjudicate whether a cost-consequence analysis is
  publishable before asserting CEA based on sparse utility estimates.

## Validation criteria before clinical interpretation

- [ ] Each procedure includes separate EIN and cancer pathways.
- [ ] No input `NA` remains; source, source population, uncertainty
      range and provenance are supplied for every parameter.
- [ ] Screening pathways include adequacy and follow-up probabilities.
- [ ] Outcomes are tracked at the same horizon for all procedures.
- [ ] A no-screen row has zero test cost and sensitivity.
- [ ] Adding the same downstream inputs to all six labels makes
      model outputs identical across procedures for each strategy.
- [ ] A change in postoperative detection costs does not alter the
      screening operating characteristics.
- [ ] No numerical claims are made until model runs are executed,
      validated, and checked against an independent implementation.
- [ ] Submit a prespecified analysis plan and CHEERS 2022 checklist.

## Example R entry point (will not run until inputs are populated)

```r
base::source("R/shared_preop_screening_model.R")
model_inputs <- make_shared_preop_screening_inputs()
base::str(model_inputs)

# Populate clinical probabilities, costs, and utilities from
# documented studies or clearly labeled expert elicitation.
# run_shared_preop_screening_model(
#   procedures = model_inputs$procedures,
#   screening = model_inputs$screening,
#   prevalence = model_inputs$prevalence
# )
```
