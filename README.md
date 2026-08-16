
## Overview

This project asks a single core question: **does business reputation actually influence access to SBA capital in Philadelphia's small business lending market?**

Short answer: not really, not in the way it should. Philadelphia restaurants face a persistent capital access gap (loan rates run **2.8x–3.4x lower** than the citywide average across four years of business maturity), even though restaurant reputation (Yelp ratings and review volume) tracks closely with the citywide average over the same period. The gap is sharpest for **established, post-startup restaurants** — the exact population Experian's own reputation-scoring research identifies as best positioned to benefit from reputation-aware underwriting, since they've accumulated the review history a startup hasn't yet.

Full analysis, methodology, and citations: **[Written Report](https://docs.google.com/document/d/1dOyz8SyU3f40s-XmVZRsFax28nx8YwV4sAFtZ8QTIk0/edit?usp=sharing)**

Interactive exploration: **[Tableau Dashboard](https://public.tableau.com/app/profile/hakeem.leonard/viz/Restaurant_Capital_Analysis/Overview)**

## Data Sources

- **SBA 7(a)/504 loan data** — from the [SBA FOIA data portal](https://data.sba.gov/dataset/7a-504-foia), filtered to Philadelphia, PA, combined across three fiscal-year files (2012–2022 window used).
- **Yelp Open Dataset** — academic download (2022 vintage), filtered to Philadelphia businesses and their reviews.
- Joined at the **ZIP-code level** (no shared business-level identifier exists between the two sources — see [Limitations](#limitations)).

Raw data files are not included in this repo (size and licensing constraints). See the written report's Data Sources section for full acquisition and cleaning steps.

## Repo Structure

- [/queries/](./queries)
  - segmentation.sql -- cross-industry + ZIP-level comparison (Technique 1)
    - [cross_industry_comparison.sql](./queries/segmentation/cross_industry_comparison.sql)
    - [zip_level_divergence.sql](./queries/segmentation/zip_level_divergence.sql)
  - cohort_analysis.sql -- cohort loan-rate & rating trajectories (Technique 2), corrected version
    - [cohort_loan_rate.sql](./queries/cohort_analysis/cohort_loan_rate.sql)
    - [cohort_reviews_ratings.sql](./queries/cohort_analysis/cohort_reviews_ratings.sql)
  - hypothesis_test.sql -- startup vs. non-startup chi-square test (Technique 3)
    - [Startup_NonStartup.sql](./queries/hypothesis_test/Startup_NonStartup.sql)
    - [chi_squared.sql](./queries/hypothesis_test/chi_squared.sql)
      
 - [/written_report/](https://docs.google.com/document/d/1dOyz8SyU3f40s-XmVZRsFax28nx8YwV4sAFtZ8QTIk0/edit?usp=sharing)
 - [/dashboard/](https://public.tableau.com/app/profile/hakeem.leonard/viz/Restaurant_Capital_Analysis/Overview)
 - [README.md](/README.md)

## Methodology Summary

Three techniques, each answering a different question:

| Technique | Question | Window |
|---|---|---|
| **Segmentation** (cross-industry + ZIP-level) | Where do reputation and lending activity diverge? | 2018–2022 |
| **Cohort analysis** | How does the relationship develop as a business ages? | 2012–2018 (earliest window supporting complete 4-year cohorts) |
| **Hypothesis testing** (chi-square) | Is the observed association statistically meaningful? | April 2012–2022 (widest window with reliable restaurant-loan coverage) |

Restaurants were identified two independent ways — Yelp's `categories` field and SBA's `NaicsCode LIKE '7225%'` — and cross-checked against each other. See `/queries/` for the full SQL behind each technique, with inline comments.

## Key Findings

- Restaurants receive SBA loans at **1.86%** citywide vs. **6.07%** for all businesses — roughly a third of the citywide rate — despite a ratings gap of only ~0.08 points (3.54 vs. 3.62).
- The loan-rate gap **persists** (not widens) as cohorts age: 2.8x–3.4x lower than citywide across all four years tracked since a business's first review.
- Restaurants capture a disproportionate share of **startup-phase** loans (30.21%) but a much smaller share of **non-startup** loans (11.39%) — χ² = 72.36, p < .001. The gap is concentrated in the post-startup phase, exactly where a reputation-based signal becomes usable but isn't currently applied.
- ZIP 19140 is a clear local example: restaurants are the majority business type and rated *above* the ZIP's average, yet receive loans at 1.82% vs. 28.42% for all businesses in the ZIP.
- Beauty shops (and, more severely, dentists) show a comparable underfunding pattern, suggesting the reputation-lending disconnect may not be restaurant-specific.

## Selected Corrections & Known Issues

Documenting corrections made during the analysis, since a few materially changed the results:

| Issue | What was wrong | What changed | Where |
|---|---|---|---|
| False zero-rate cohort years (Day 9) | SBA restaurant loan records don't begin until April 2012; cohort years 2007–2010 showed false 0% loan rates as a coverage artifact, not a real finding | Narrowed the cohort window from 2007–2018 to **2012–2018** | [cohort_loan_rate.sql](./queries/cohort_analysis/cohort_loan_rate.sql) |
| Unweighted cohort average (Day 9) | Citywide cohort rate was computed as an unweighted average of ZIP-level percentages, letting tiny-denominator ZIPs distort it (root cause of a false 2014 spike) | Switched to a weighted citywide rate (sum of loans ÷ sum of businesses) | [cohort_loan_rate.sql](./queries/cohort_analysis/cohort_loan_rate.sql) |
| ZIP-year drop-out (Day 12) | Businesses in ZIP-years with zero recorded loans were silently dropped from the join rather than counted at a true 0%, understating the gap | Recomputed against a complete ZIP × year grid (LEFT JOIN); gap widened from ~1.6x pre-fix to the corrected **2.8x–3.4x**. Also reframed "widens" → "persists," since per-cohort data doesn't consistently support a widening trend | [cohort_loan_rate.sql](./queries/cohort_analysis/cohort_loan_rate.sql) |
| Small-denominator ZIP-years | Very small business counts (e.g., 2 restaurants, 1 loan → 50%) produced unstable rates | ZIP-years with fewer than 10 businesses in the relevant category fall back to that year's citywide rate | [cohort_loan_rate.sql](./queries/cohort_analysis/cohort_loan_rate.sql) |
| Sign-convention bug (Day 14) | Two BigQuery queries feeding the Zip Explorer dashboard computed "Divergence Loan Prct" in opposite subtraction order (map: all-minus-restaurant; KPI card: restaurant-minus-all) — caught via a 19140 spot-check showing +26.60 vs. −26.60 | Standardized both queries on all-minus-restaurant; replaced a hardcoded citywide restaurant rate with a live subquery | [dashboard (Zip Explorer view)](https://public.tableau.com/app/profile/hakeem.leonard/viz/Restaurant_Capital_Analysis/Overview) |
| Two analysis windows | Cross-industry/geographic analysis use 2018–2022; cohort analysis uses 2012–2018 | Documented as a deliberate scoping choice — cohort needed the earliest window supporting full 4-year tracking (SBA restaurant records begin April 2012, not a Yelp-coverage constraint) | [See Methodology](https://docs.google.com/document/d/1dOyz8SyU3f40s-XmVZRsFax28nx8YwV4sAFtZ8QTIk0/edit?usp=sharing) |
| Hypothesis test window mismatch (identified 8/9) | The chi-square test was unintentionally run against the full 2007–2022 SBA dataset rather than the reported 2018–2022 window, including a zero-restaurant-coverage gap (pre-April 2012) that inflated the apparent Startup vs. Non-Startup disparity | Restricted the test to **April 2012–2022**; restaurant counts unchanged (87 Startup / 198 Non-Startup), non-restaurant totals fell, revising the result to χ² = 72.36 and a 30.21% vs. 11.39% split (previously 111.87 and 25.74% vs. 7.63%) | [chi_squared.sql](./queries/hypothesis_test/chi_squared.sql) |
| Anomalous ZIPs (19176, 19195) | 55 and 35 businesses geocoded to a PO-box-only ZIP and a single-entity ZIP, respectively, both showing 0% loan activity | Flagged as likely geocoding artifacts rather than genuine findings; not excluded from data, but caveated | [zip_level_divergence.sql](./queries/segmentation/zip_level_divergence.sql) |

## Limitations

Full detail in the written report's Limitations section. Headline constraints:

- No direct business-to-loan match; all linkage is at the ZIP-code aggregate level (association, not individual-business causation).
- Reputation signal relies on Yelp only — no cross-platform (Google, Facebook) validation.
- Correlational, not causal: this analysis identifies and rules out reputation as an explanation for the gap, but doesn't establish the underlying cause.
- Findings are specific to Philadelphia (2012–2022) and may not generalize to other metro markets or periods.

## Recommendations

1. **Pilot reputation-aware underwriting** for Philadelphia restaurants, building on existing industry precedent (Experian's Social Media Insight product).
2. **Targeted outreach** in high-divergence ZIP codes (e.g., 19140), via the Zip Explorer dashboard.
3. **Address the startup-vs-maturity gap** specifically, using accumulated review history as a predictive input for post-startup restaurants.
4. **Extend the framework** to other underserved industries (dentists, beauty shops) to test whether this pattern is restaurant-specific or broader.
5. **Further research**: isolate causal drivers (loan officer risk models, collateral requirements, revenue volatility), and validate against a second city's data.

Full reasoning for each: see the written report's Recommendations section.
