WITH categorized AS (
  SELECT
    CASE
      WHEN BusinessAge = 'Startup, Loan Funds will Open Business' THEN 'Startup'
      ELSE 'Non-Startup'
    END AS business_age_group,
    CASE
      WHEN STARTS_WITH(CAST(NaicsCode AS STRING), '7225') THEN 'Restaurant'
      ELSE 'Non-restaurant'
    END AS industry_type
  FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
),

observed AS (
  SELECT
    business_age_group,
    industry_type,
    COUNT(*) AS observed_count
  FROM categorized
  GROUP BY business_age_group, industry_type
),

expected AS (
  SELECT
    business_age_group,
    industry_type,
    observed_count,
    SUM(observed_count) OVER (PARTITION BY business_age_group) AS row_total,
    SUM(observed_count) OVER (PARTITION BY industry_type) AS col_total,
    SUM(observed_count) OVER () AS grand_total,
    SAFE_DIVIDE(
      SUM(observed_count) OVER (PARTITION BY business_age_group)
        * SUM(observed_count) OVER (PARTITION BY industry_type),
      SUM(observed_count) OVER ()
    ) AS expected_count
  FROM observed
)

SELECT
  SUM(POWER(observed_count - expected_count, 2) / expected_count) AS chi_squared,
  (COUNT(DISTINCT business_age_group) - 1) * (COUNT(DISTINCT industry_type) - 1) AS degrees_of_freedom
FROM expected
