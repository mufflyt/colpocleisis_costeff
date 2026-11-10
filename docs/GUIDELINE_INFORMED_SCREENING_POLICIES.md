# Guideline-informed testing policies for Jerry's shared screening model

**Status:** preregistered *candidate policies*, not endorsed standards and
not calibrated clinical recommendations. Target population: asymptomatic
postmenopausal women with stage III uterovaginal prolapse, without
postmenopausal bleeding or another independent indication for diagnostic
evaluation. Keep guideline-mandated cervical care separate.

## Policies (within EACH planned prolapse operation)

| ID | Testing policy | Initial test | Trigger for further evaluation | Evidence rationale |
| --- | --- | --- | --- | --- |
| P0 | No **additional routine** endometrial screening | None | New bleeding, concerning clinical findings, or another guideline-based indication prompts evaluation, irrespective of arm | Asymptomatic low-risk screening guidance (ISUOG; SOGC); not a blanket no-workup policy |
| P1 | Selective risk-based TVUS | TVUS only if prespecified elevated risk or indicated by clinical assessment | Endometrial morphology, threshold and individual risk guide histologic sampling; manage inadequate samples | Guideline-informed selective assessment; exact criteria require clinical adjudication |
| P2 | Routine TVUS, conditional histology | TVUS for all | Biopsy or hysteroscopy based on prespecified *asymptomatic* thickness threshold and concerning morphology | Procedure-planning ultrasound approach; evaluate thresholds separately, not an asserted society mandate |
| P3 | Risk-based endometrial biopsy | Office biopsy in a prespecified high-risk group | Inadequate/abnormal biopsy prompts appropriate hysteroscopy or further sampling | Clinical risk selection; do not borrow test accuracy from bleeding populations without sensitivity analysis |
| P4 | Universal endometrial biopsy | Office biopsy for everyone | Repeat/hysteroscopy if inadequate or abnormal | Counterfactual for decision analysis only; no society recommendation claimed |

**Do not conflate** universal biopsy with society-supported care. Maintain
P0 as a *no additional routine* screen, not an absence of indicated
diagnostic care. Patients with bleeding are evaluated outside this comparison.

## Explicit branching logic

1. Assign baseline risk group *before* the screening decision. Initially
   stratify as average versus elevated risk; prospectively specify risk
   criteria, how they are measured, and prevalence within each stratum.
2. For P1 and P3, apply tests only to the eligible subgroup. A tested fraction
   is needed as well as disease prevalence within tested and untested groups.
3. For P1/P2, specify threshold-specific TVUS sensitivity and specificity
   against EIN and cancer **separately**. Assess 11 mm and alternative
   asymptomatic thresholds as scenarios; do not transplant the 4 mm
   postmenopausal-bleeding cutoff as a universal asymptomatic threshold.
4. Route abnormal ultrasound to sampling; include inadequate tissue,
   repeat office sample, hysteroscopy, and definitive management.
5. Distinguish preoperative cancer/EIN discovery from final hysterectomy
   pathology and later diagnosis after hysteropexy. After SCH, allow
   surveillance, medical therapy, or additional surgery when indicated;
   trachelectomy is not automatic.
6. Evaluate each policy within six operation labels, initially pooling
   downstream estimates by three anatomic categories. Do not compare the
   total baseline costs of different prolapse operations.
7. Capture test costs, unnecessary follow-up, delays, subsequent care,
   incremental operative time, incremental QALYs, and detection counts.
8. Model cervical screening/CIN2+/AIS/cervical cancer separately, including
   age- and history-based eligibility and potential trachelectomy after SCH.

## Important limitation of current implementation

`R/shared_preop_screening_model.R` currently permits a single prevalence
vector and one whole-cohort sensitivity/specificity/cost row per screening
strategy. Thus **P1/P3 are not yet computationally implemented**. Encoding
them simply by multiplying testing cost by a tested fraction while leaving
sensitivity unchanged would create a biased comparison. They require a
stratified population expansion and complete conditional test pathways,
with weighted aggregation across risk strata. P0 and simple whole-cohort
P2/P4 can be represented once their actual pathway performance and costs
are obtained, but existing numerical inputs remain incomplete.

### Acceptance tests for the risk-stratified extension

- When both strata have the same disease prevalence and all are tested,
  P1 converges to the equivalent routine test pathway.
- When the tested fraction is zero, P1/P3 coincide with P0, after
  accounting for clinically indicated care common to all policies.
- A more selective policy must reduce testing count and test cost but
  cannot keep whole-cohort detection sensitivity unchanged unless
  empirically justified.
- Disease cases, false positives, insufficient samples, and follow-up
  procedures are conserved across conditional branches.
- No double counting of an additional oncologic operation after
  unexpected pathology.
- Screening histories and age modify future cervical screening only;
  cervical testing is not conflated with endometrial sampling.

## Sources and attribution limits

- SOGC 451 (2024), asymptomatic endometrial thickness:
  https://pubmed.ncbi.nlm.nih.gov/38901794/
- ISUOG consensus (2026), endometrial imaging:
  https://doi.org/10.1002/uog.70163
- DGGG/SGGG/OEGGG (2016), POP surgery:
  https://pmc.ncbi.nlm.nih.gov/articles/PMC5193153/
- U-POP international consensus (2026), uterine preservation:
  https://doi.org/10.1007/s00192-026-06758-6
- NICE NG123, prolapse surgical options:
  https://www.nice.org.uk/guidance/ng123/chapter/Recommendations
- Indian Menopause Society 2026:
  https://pmc.ncbi.nlm.nih.gov/articles/PMC12948155/

These guidance documents address distinct populations and interventions.
The policy definitions are the **study team's operationalizations**, not
verbatim recommendations of any one society.
