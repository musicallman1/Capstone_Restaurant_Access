WITH 
-- ===== ALL-BUSINESS REVIEW/RATING TRAJECTORY =====
all_rating_cohort_businesses AS (
    SELECT
        business_id,
        EXTRACT(YEAR FROM MIN(date)) AS cohort_year
    FROM `yelp-analysis-503216.Philly_yelp.philadelphia_reviews`
    GROUP BY business_id
),

all_business_year_reviews AS (
    SELECT
        business_id,
        EXTRACT(YEAR FROM date) AS review_year,
        AVG(stars) AS avg_rating,
        COUNT(*) AS review_count
    FROM `yelp-analysis-503216.Philly_yelp.philadelphia_reviews`
    GROUP BY business_id, review_year
),

all_rating_trajectory AS (
    SELECT
        cb.business_id,
        cb.cohort_year,
        byr.review_year - cb.cohort_year AS years_since_start,
        byr.avg_rating,
        byr.review_count
    FROM all_rating_cohort_businesses cb
    JOIN all_business_year_reviews byr
        ON cb.business_id = byr.business_id
    WHERE cb.cohort_year BETWEEN 2012 AND 2018
      AND byr.review_year - cb.cohort_year BETWEEN 1 AND 4
),

all_rating_final AS (
    SELECT
        cohort_year,
        years_since_start,
        COUNT(DISTINCT business_id) AS all_business_count,
        ROUND(AVG(avg_rating), 3) AS all_business_rating,
        ROUND(AVG(review_count), 2) AS all_business_avg_review_count
    FROM all_rating_trajectory
    GROUP BY cohort_year, years_since_start
),

-- ===== RESTAURANT-ONLY REVIEW/RATING TRAJECTORY =====
rest_rating_cohort_businesses AS (
    SELECT
        r.business_id,
        EXTRACT(YEAR FROM MIN(r.date)) AS cohort_year
    FROM `yelp-analysis-503216.Philly_yelp.philadelphia_reviews` r
    JOIN `yelp-analysis-503216.Philly_yelp.philly_businesses` b
        ON r.business_id = b.business_id
    WHERE b.categories LIKE '%Restaurants%'
    GROUP BY r.business_id
),

rest_business_year_reviews AS (
    SELECT
        business_id,
        EXTRACT(YEAR FROM date) AS review_year,
        AVG(stars) AS avg_rating,
        COUNT(*) AS review_count
    FROM `yelp-analysis-503216.Philly_yelp.philadelphia_reviews`
    GROUP BY business_id, review_year
),

rest_rating_trajectory AS (
    SELECT
        cb.business_id,
        cb.cohort_year,
        byr.review_year - cb.cohort_year AS years_since_start,
        byr.avg_rating,
        byr.review_count
    FROM rest_rating_cohort_businesses cb
    JOIN rest_business_year_reviews byr
        ON cb.business_id = byr.business_id
    WHERE cb.cohort_year BETWEEN 2012 AND 2018
      AND byr.review_year - cb.cohort_year BETWEEN 1 AND 4
),

rest_rating_final AS (
    SELECT
        cohort_year,
        years_since_start,
        COUNT(DISTINCT business_id) AS restaurant_business_count,
        ROUND(AVG(avg_rating), 3) AS restaurant_rating,
        ROUND(AVG(review_count), 2) AS restaurant_avg_review_count
    FROM rest_rating_trajectory
    GROUP BY cohort_year, years_since_start
)

SELECT
    a.cohort_year,
    a.years_since_start,
    a.all_business_count,
    a.all_business_rating,
    a.all_business_avg_review_count,
    r.restaurant_business_count,
    r.restaurant_rating,
    r.restaurant_avg_review_count
FROM all_rating_final a
LEFT JOIN rest_rating_final r
    USING (cohort_year, years_since_start)
ORDER BY a.cohort_year, a.years_since_start
