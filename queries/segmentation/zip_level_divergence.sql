WITH zip_all_business AS (
  SELECT
    CAST(b.postal_code AS STRING) AS postal_code,
    COUNT(DISTINCT b.business_id) AS business_count,
    AVG(b.stars) AS avg_rating,
    AVG(b.review_count) AS avg_review_count
  FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
  GROUP BY b.postal_code
),

zip_all_loans AS (
  SELECT
    CAST(BorrZip AS STRING) AS postal_code,
    COUNT(*) AS loan_count
  FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
  WHERE ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
  GROUP BY BorrZip
),

-- Per-ZIP: restaurants only
zip_restaurant_business AS (
  SELECT
    CAST(b.postal_code AS STRING) AS postal_code,
    COUNT(DISTINCT b.business_id) AS restaurant_business_count,
    AVG(b.stars) AS restaurant_avg_rating,
    AVG(b.review_count) AS restaurant_avg_review_count
  FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
  WHERE b.categories LIKE '%Restaurants%'
  GROUP BY b.postal_code
),

zip_restaurant_loans AS (
  SELECT
    CAST(BorrZip AS STRING) AS postal_code,
    COUNT(*) AS restaurant_loan_count
  FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
  WHERE CAST(NaicsCode AS STRING) LIKE '7225%'
    AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
  GROUP BY BorrZip
),

-- Combine into one row per real ZIP
per_zip AS (
  SELECT
    a.postal_code,
    a.business_count,
    a.avg_rating,
    a.avg_review_count,
    ROUND(COALESCE(al.loan_count, 0) / a.business_count * 100, 2) AS loan_prct,
    COALESCE(al.loan_count, 0) AS loan_count,
    r.restaurant_business_count,
    r.restaurant_avg_rating,
    r.restaurant_avg_review_count,
    ROUND(COALESCE(rl.restaurant_loan_count, 0) / r.restaurant_business_count * 100, 2) AS restaurant_loan_prct,
    COALESCE(rl.restaurant_loan_count, 0) AS restaurant_loan_count,
    ROUND(
      (COALESCE(al.loan_count, 0) / a.business_count * 100)
        - (COALESCE(rl.restaurant_loan_count, 0) / r.restaurant_business_count * 100)
      , 2) AS divergence_loan_prct
  FROM zip_all_business a
  LEFT JOIN zip_all_loans al ON a.postal_code = al.postal_code
  LEFT JOIN zip_restaurant_business r ON a.postal_code = r.postal_code
  LEFT JOIN zip_restaurant_loans rl ON a.postal_code = rl.postal_code
  WHERE r.restaurant_business_count IS NOT NULL  -- drop ZIPs with zero restaurants to avoid divide-by-zero
),

citywide AS (
  SELECT
    'CITYWIDE' AS postal_code,
    COUNT(DISTINCT b.business_id) AS business_count,
    AVG(b.stars) AS avg_rating,
    AVG(b.review_count) AS avg_review_count,
    ROUND((SELECT COUNT(*) FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
           WHERE ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31')
          / COUNT(DISTINCT b.business_id) * 100, 2) AS loan_prct,
    (SELECT COUNT(*) FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
     WHERE ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31') AS loan_count,
    (SELECT COUNT(DISTINCT business_id) FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
     WHERE categories LIKE '%Restaurants%') AS restaurant_business_count,
    (SELECT AVG(stars) FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
     WHERE categories LIKE '%Restaurants%') AS restaurant_avg_rating,
    (SELECT AVG(review_count) FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
     WHERE categories LIKE '%Restaurants%') AS restaurant_avg_review_count,
    1.86 AS restaurant_loan_prct,   
    (SELECT COUNT(*) FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
     WHERE CAST(NaicsCode AS STRING) LIKE '7225%'
       AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31') AS restaurant_loan_count,
    ROUND(
      ((SELECT COUNT(*) FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
        WHERE ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31')
        / COUNT(DISTINCT b.business_id) * 100) -
      ((SELECT COUNT(*) FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
        WHERE CAST(NaicsCode AS STRING) LIKE '7225%'
          AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31')
        / (SELECT COUNT(DISTINCT business_id) FROM `yelp-analysis-503216.Philly_yelp.philly_businesses`
      WHERE categories LIKE '%Restaurants%') * 100)
    , 2) AS divergence_loan_prct
  FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
)

SELECT * FROM citywide
UNION ALL
SELECT * FROM per_zip
