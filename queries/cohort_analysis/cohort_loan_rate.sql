WITH 
-- ===== ALL-BUSINESS COHORT TRAJECTORY =====
all_cohort_businesses AS (
    SELECT
        r.business_id,
        EXTRACT(YEAR FROM MIN(r.date)) AS cohort_year
    FROM `yelp-analysis-503216.Philly_yelp.philadelphia_reviews` r
    JOIN `yelp-analysis-503216.Philly_yelp.philly_businesses` b
        ON r.business_id = b.business_id
    GROUP BY r.business_id
),

all_zip_business_counts AS (
    SELECT
        postal_code,
        COUNT(*) AS business_count
    FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
    GROUP BY postal_code
),

all_total_business_count AS (
    SELECT SUM(business_count) AS total_business_count
    FROM all_zip_business_counts
),

all_year_loans AS (
    SELECT
        EXTRACT(YEAR FROM ApprovalDate) AS loan_year,
        COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    GROUP BY loan_year
),

all_citywide_year_rate AS (
    SELECT
        yl.loan_year,
        yl.loan_count,
        ROUND(yl.loan_count / tbc.total_business_count * 100, 2) AS loan_rate_pct
    FROM all_year_loans yl
    CROSS JOIN all_total_business_count tbc
),

all_business_year_offsets AS (
    SELECT
        cb.business_id,
        cb.cohort_year,
        cyr.loan_year - cb.cohort_year AS years_since_start,
        cyr.loan_rate_pct
    FROM all_cohort_businesses cb
    JOIN all_citywide_year_rate cyr
        ON cyr.loan_year - cb.cohort_year BETWEEN 1 AND 4
    WHERE cb.cohort_year BETWEEN 2012 AND 2018
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
        EXTRACT(YEAR FROM MIN(r.date)) AS cohort_year
    FROM `yelp-analysis-503216.Philly_yelp.philadelphia_reviews` r
    JOIN `yelp-analysis-503216.Philly_yelp.philly_businesses` b
        ON r.business_id = b.business_id
    WHERE b.categories LIKE '%Restaurants%'
    GROUP BY r.business_id
),

rest_zip_business_counts AS (
    SELECT
        postal_code,
        COUNT(*) AS business_count
    FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
    WHERE categories LIKE '%Restaurants%'
    GROUP BY postal_code
),

rest_total_business_count AS (
    SELECT SUM(business_count) AS total_business_count
    FROM rest_zip_business_counts
),

rest_year_loans AS (
    SELECT
        EXTRACT(YEAR FROM ApprovalDate) AS loan_year,
        COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '7225%'
    GROUP BY loan_year
),

rest_citywide_year_rate AS (
    SELECT
        yl.loan_year,
        yl.loan_count,
        ROUND(yl.loan_count / tbc.total_business_count * 100, 2) AS loan_rate_pct
    FROM rest_year_loans yl
    CROSS JOIN rest_total_business_count tbc
),

rest_cohort_totals AS (
    SELECT
        cohort_year,
        COUNT(*) AS cohort_business_count
    FROM rest_cohort_businesses
    WHERE cohort_year BETWEEN 2012 AND 2018
    GROUP BY cohort_year
),

rest_offset_grid AS (
    SELECT cohort_year, years_since_start
    FROM rest_cohort_totals
    CROSS JOIN UNNEST([1, 2, 3, 4]) AS years_since_start
),

rest_business_final AS (
    SELECT
        g.cohort_year,
        g.years_since_start,
        ct.cohort_business_count AS restaurant_business_count,
        cyr.loan_count AS restaurant_businesses_with_loans,
        cyr.loan_rate_pct AS restaurant_rate
    FROM rest_offset_grid g
    JOIN rest_cohort_totals ct
        ON g.cohort_year = ct.cohort_year
    LEFT JOIN rest_citywide_year_rate cyr
        ON cyr.loan_year = g.cohort_year + g.years_since_start
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
