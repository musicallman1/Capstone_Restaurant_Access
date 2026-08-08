WITH
-- ===== CITYWIDE FALLBACK RATES =====
citywide_year_loans_all AS (
    SELECT
        EXTRACT(YEAR FROM ApprovalDate) AS loan_year,
        COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    GROUP BY loan_year
),

citywide_total_all AS (
    SELECT COUNT(*) AS total_business_count
    FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
),

citywide_rate_all AS (
    SELECT
        l.loan_year,
        ROUND(l.loan_count / t.total_business_count * 100, 2) AS citywide_rate_pct
    FROM citywide_year_loans_all l
    CROSS JOIN citywide_total_all t
),

citywide_year_loans_rest AS (
    SELECT
        EXTRACT(YEAR FROM ApprovalDate) AS loan_year,
        COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '7225%'
    GROUP BY loan_year
),

citywide_total_rest AS (
    SELECT COUNT(*) AS total_business_count
    FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
    WHERE categories LIKE '%Restaurants%'
),

citywide_rate_rest AS (
    SELECT
        l.loan_year,
        ROUND(l.loan_count / t.total_business_count * 100, 2) AS citywide_rate_pct
    FROM citywide_year_loans_rest l
    CROSS JOIN citywide_total_rest t
),

zip_business_counts AS (
    SELECT postal_code, COUNT(*) AS business_count
    FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
    GROUP BY postal_code
),

relevant_years AS (
    SELECT loan_year
    FROM UNNEST(GENERATE_ARRAY(2013, 2022)) AS loan_year
),

zip_year_grid_all AS (
    SELECT bc.postal_code, bc.business_count, ry.loan_year
    FROM zip_business_counts bc
    CROSS JOIN relevant_years ry
),

zip_year_loans AS (
    SELECT
        BorrZip AS postal_code,
        EXTRACT(YEAR FROM ApprovalDate) AS loan_year,
        COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    GROUP BY postal_code, loan_year
),

zip_year_rate_all AS (
    SELECT
        g.postal_code,
        g.loan_year,
        g.business_count,
        COALESCE(l.loan_count, 0) AS loan_count,
        ROUND(COALESCE(l.loan_count, 0) / g.business_count * 100, 2) AS zip_rate_pct,
        g.business_count >= 10 AS is_reliable
    FROM zip_year_grid_all g
    LEFT JOIN zip_year_loans l
        ON l.postal_code = g.postal_code
       AND l.loan_year = g.loan_year
),

zip_rest_business_counts AS (
    SELECT postal_code, COUNT(*) AS business_count
    FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
    WHERE categories LIKE '%Restaurants%'
    GROUP BY postal_code
),

zip_year_grid_rest AS (
    SELECT bc.postal_code, bc.business_count, ry.loan_year
    FROM zip_rest_business_counts bc
    CROSS JOIN relevant_years ry
),

zip_year_rest_loans AS (
    SELECT
        BorrZip AS postal_code,
        EXTRACT(YEAR FROM ApprovalDate) AS loan_year,
        COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '7225%'
    GROUP BY postal_code, loan_year
),

zip_year_rate_rest AS (
    SELECT
        g.postal_code,
        g.loan_year,
        g.business_count,
        COALESCE(l.loan_count, 0) AS loan_count,
        ROUND(COALESCE(l.loan_count, 0) / g.business_count * 100, 2) AS zip_rate_pct,
        g.business_count >= 10 AS is_reliable
    FROM zip_year_grid_rest g
    LEFT JOIN zip_year_rest_loans l
        ON l.postal_code = g.postal_code
       AND l.loan_year = g.loan_year
),

-- ===== ALL-BUSINESS COHORTS, JOINED TO THEIR OWN ZIP'S RATE (WITH FALLBACK) =====
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

all_business_year_offsets AS (
    SELECT
        cb.business_id,
        cb.cohort_year,
        zyr.loan_year - cb.cohort_year AS years_since_start,
        COALESCE(
            CASE WHEN zyr.is_reliable THEN zyr.zip_rate_pct END,
            cw.citywide_rate_pct
        ) AS loan_rate_pct
    FROM all_cohort_businesses cb
    JOIN zip_year_rate_all zyr
        ON zyr.postal_code = cb.postal_code
       AND zyr.loan_year - cb.cohort_year BETWEEN 1 AND 4
    JOIN citywide_rate_all cw
        ON cw.loan_year = zyr.loan_year
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

-- ===== RESTAURANT-ONLY COHORTS, JOINED TO THEIR OWN ZIP'S RESTAURANT RATE (WITH FALLBACK) =====
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

rest_business_year_offsets AS (
    SELECT
        cb.business_id,
        cb.cohort_year,
        zyr.loan_year - cb.cohort_year AS years_since_start,
        COALESCE(
            CASE WHEN zyr.is_reliable THEN zyr.zip_rate_pct END,
            cw.citywide_rate_pct
        ) AS loan_rate_pct
    FROM rest_cohort_businesses cb
    JOIN zip_year_rate_rest zyr
        ON zyr.postal_code = cb.postal_code
       AND zyr.loan_year - cb.cohort_year BETWEEN 1 AND 4
    JOIN citywide_rate_rest cw
        ON cw.loan_year = zyr.loan_year
    WHERE cb.cohort_year BETWEEN 2012 AND 2018
),

rest_business_final AS (
    SELECT
        cohort_year,
        years_since_start,
        COUNT(DISTINCT business_id) AS restaurant_business_count,
        ROUND(AVG(loan_rate_pct), 2) AS restaurant_rate
    FROM rest_business_year_offsets
    GROUP BY cohort_year, years_since_start
)

SELECT
    a.cohort_year,
    a.years_since_start,
    a.all_business_count,
    a.all_business_rate,
    r.restaurant_business_count,
    r.restaurant_rate
FROM all_business_final a
LEFT JOIN rest_business_final r
    USING (cohort_year, years_since_start)
ORDER BY a.cohort_year, a.years_since_start
