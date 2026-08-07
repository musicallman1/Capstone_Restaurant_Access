WITH business_reputation AS
(SELECT 
  postal_code,
  COUNT(*) AS business_count,
  AVG(stars) AS business_rating, 
  SUM(review_count) AS total_reviews
FROM`yelp-analysis-503216`.Philly_yelp.philly_businesses
GROUP BY postal_code), 

loan_activity AS 
(SELECT
  BorrZip AS postal_code,
  COUNT(*) AS loan_count,
  SUM(GrossApproval) AS total_loan_value,
  AVG(GrossApproval) AS avg_loan_size
FROM `yelp-analysis-503216`.Philly_yelp.sba_loans
WHERE ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31' 
GROUP BY BorrZip),

business_loan_prct AS 
(SELECT 
  postal_code, 
  business_count, 
  ROUND(business_rating,3) AS business_rating,
  total_reviews, 
  total_loan_value,
  coalesced_loan_count,
  ROUND(coalesced_loan_count/business_count * 100,2) AS business_loan_prct

FROM (
  SELECT 
    br.postal_code, 
    br.business_count, 
    br.business_rating,
    br.total_reviews, 
    COALESCE(la.total_loan_value, 0) AS total_loan_value,
    COALESCE(la.loan_count, 0) AS coalesced_loan_count
  FROM business_reputation br
    LEFT JOIN loan_activity la USING (postal_code)
    WHERE br.business_count >= 10
  )
  ORDER BY business_loan_prct DESC),

 restaurant_ratings AS 
(SELECT 
  postal_code,
  COUNT(*) AS restaurant_count,
  AVG(stars) AS avg_rating,
  SUM(review_count) AS total_reviews
FROM`yelp-analysis-503216`.Philly_yelp.philly_businesses
  WHERE categories LIKE '%Restaurants%'
  GROUP BY postal_code
  ),

restaurant_loans AS 
(SELECT
  BorrZip AS postal_code,
  COUNT(*) AS loan_count,
  SUM(GrossApproval) AS total_loan_volume
FROM `yelp-analysis-503216`.Philly_yelp.sba_loans
  WHERE CAST(NaicsCode AS STRING) LIKE '7225%'
  AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31' 
  GROUP BY BorrZip
  ),

restaurant_loan_prct AS 
(SELECT 
  postal_code, 
  restaurant_count, 
  ROUND(avg_rating,3) AS avg_rating,
  total_reviews, 
  total_loan_volume,
  coalesced_loan_count,
  ROUND(coalesced_loan_count/restaurant_count * 100,2) AS rest_loan_prct

FROM (
  SELECT 
    rr.postal_code,
    rr.restaurant_count, 
    rr.avg_rating,
    rr.total_reviews, 
    COALESCE(rl.total_loan_volume, 0) AS total_loan_volume,
    COALESCE(rl.loan_count, 0) AS coalesced_loan_count
  FROM restaurant_ratings rr
    LEFT JOIN restaurant_loans rl USING (postal_code)
    WHERE rr.restaurant_count >= 10
  )
  ORDER BY rest_loan_prct DESC)

  SELECT 
CAST(blp.postal_code AS STRING) AS postal_code,
blp.business_count,
rlp.restaurant_count,
blp.business_rating,
rlp.avg_rating,
blp.total_reviews AS business_total_reviews,
rlp.total_reviews AS restaurant_total_reviews,
blp.total_loan_value,
rlp.total_loan_volume,
blp.coalesced_loan_count AS coal_bus_loan_count,
rlp.coalesced_loan_count AS coal_rest_loan_count,
blp.business_loan_prct,
rlp.rest_loan_prct,
ROUND(rlp.restaurant_count/blp.business_count * 100,2) AS restaurant_share_prct,
ROUND(blp.business_loan_prct - rlp.rest_loan_prct,2) AS divergence_loan_prct,
ROUND(blp.business_rating - rlp.avg_rating,4) AS divergence_rating

  FROM
  business_loan_prct blp
  JOIN
  restaurant_loan_prct rlp 
  USING (postal_code)
  ORDER BY divergence_loan_prct DESC
