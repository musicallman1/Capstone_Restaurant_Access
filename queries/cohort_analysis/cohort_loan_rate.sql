WITH 
-- ===== ALL-BUSINESS COHORT TRAJECTORY =====
all_cohort_businesses AS (
    SELECT
        r.business_id,
        b.postal_code,
        EXTRACT(YEAR FROM MIN(r.date)) AS cohort_year
    FROM `yelp-analysis-503216.Philly_yelp.philadelphia_reviews` r
    JOIN `yelp-analysis-503216.Philly_yelp.philly_businesses` b
        ON r.business_id = b.business_id
    GROUP BY r.business_id, b.postal_code
),

all_zip_business_counts AS (
    SELECT
        postal_code,
        COUNT(*) AS business_count
    FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
    GROUP BY postal_code
),

all_zip_year_loans AS (
    SELECT
        BorrZip AS postal_code,
        EXTRACT(YEAR FROM ApprovalDate) AS loan_year,
        COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    GROUP BY BorrZip, loan_year
),

all_zip_year_rate AS (
    SELECT
        zyl.postal_code,
        zyl.loan_year,
        zyl.loan_count,
        zbc.business_count,
        ROUND(zyl.loan_count / zbc.business_count * 100, 2) AS loan_rate_pct
    FROM all_zip_year_loans zyl
    JOIN all_zip_business_counts zbc
        ON zyl.postal_code = zbc.postal_code
),

all_business_year_offsets AS (
    SELECT
        cb.business_id,
        cb.cohort_year,
        zyr.loan_year - cb.cohort_year AS years_since_start,
        zyr.loan_rate_pct
    FROM all_cohort_businesses cb
    JOIN all_zip_year_rate zyr
        ON cb.postal_code = zyr.postal_code
    WHERE cb.cohort_year BETWEEN 2007 AND 2018
      AND zyr.loan_year - cb.cohort_year BETWEEN 1 AND 4
),

all_business_final AS (
    SELECT
        cohort_year,
        years_since_start,
        COUNT(DISTINCT business_id) AS all_business_count,
        ROUND(AVG(loan_rate_pct), 2) AS all_business_rate
    FROM all_business_year_offsets
    GROUP BY cohort_year, years_since_start
),

-- ===== RESTAURANT-ONLY COHORT TRAJECTORY =====
rest_cohort_businesses AS (
    SELECT
        r.business_id,
        b.postal_code,
        EXTRACT(YEAR FROM MIN(r.date)) AS cohort_year
    FROM `yelp-analysis-503216.Philly_yelp.philadelphia_reviews` r
    JOIN `yelp-analysis-503216.Philly_yelp.philly_businesses` b
        ON r.business_id = b.business_id
    WHERE b.categories LIKE '%Restaurants%'
    GROUP BY r.business_id, b.postal_code
),

rest_zip_business_counts AS (
    SELECT
        postal_code,
        COUNT(*) AS business_count
    FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
    WHERE categories LIKE '%Restaurants%'
    GROUP BY postal_code
),

rest_zip_year_loans AS (
    SELECT
        BorrZip AS postal_code,
        EXTRACT(YEAR FROM ApprovalDate) AS loan_year,
        COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '7225%'
    GROUP BY BorrZip, loan_year
),

rest_zip_year_rate AS (
    SELECT
        zyl.postal_code,
        zyl.loan_year,
        zyl.loan_count,
        zbc.business_count,
        ROUND(zyl.loan_count / zbc.business_count * 100, 2) AS loan_rate_pct
    FROM rest_zip_year_loans zyl
    JOIN rest_zip_business_counts zbc
        ON zyl.postal_code = zbc.postal_code
),

rest_business_year_offsets AS (
    SELECT
        cb.business_id,
        cb.cohort_year,
        zyr.loan_year - cb.cohort_year AS years_since_start,
        zyr.loan_rate_pct
    FROM rest_cohort_businesses cb
    JOIN rest_zip_year_rate zyr
        ON cb.postal_code = zyr.postal_code
    WHERE cb.cohort_year BETWEEN 2007 AND 2018
      AND zyr.loan_year - cb.cohort_year BETWEEN 1 AND 4
),

rest_cohort_totals AS (
    SELECT
        cohort_year,
        COUNT(*) AS cohort_business_count
    FROM rest_cohort_businesses
    WHERE cohort_year BETWEEN 2007 AND 2018
    GROUP BY cohort_year
),

rest_offset_grid AS (
    SELECT cohort_year, years_since_start
    FROM rest_cohort_totals
    CROSS JOIN UNNEST([1, 2, 3, 4]) AS years_since_start
),

rest_actuals AS (
    SELECT
        cohort_year,
        years_since_start,
        COUNT(DISTINCT business_id) AS businesses,
        AVG(loan_rate_pct) AS avg_rate
    FROM rest_business_year_offsets
    GROUP BY cohort_year, years_since_start
),

rest_business_final AS (
    SELECT
        g.cohort_year,
        g.years_since_start,
        ct.cohort_business_count AS restaurant_business_count,
        COALESCE(a.businesses, 0) AS restaurant_businesses_with_loans,
        ROUND(COALESCE(a.avg_rate, 0), 2) AS restaurant_rate
    FROM rest_offset_grid g
    JOIN rest_cohort_totals ct
        ON g.cohort_year = ct.cohort_year
    LEFT JOIN rest_actuals a
        ON g.cohort_year = a.cohort_year
        AND g.years_since_start = a.years_since_start
)

SELECT
    a.cohort_year,
    a.years_since_start,
    a.all_business_count,
    a.all_business_rate,
    r.restaurant_business_count,
    r.restaurant_businesses_with_loans,
    r.restaurant_rate
FROM all_business_final a
LEFT JOIN rest_business_final r
    USING (cohort_year, years_since_start)
ORDER BY a.cohort_year, a.years_since_start
