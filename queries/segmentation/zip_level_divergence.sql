WITH restaurant_ratings AS 
(SELECT 
  postal_code,
  COUNT(*) AS restaurant_count,
  AVG(stars) AS avg_rating,
  SUM(review_count) AS total_reviews
FROM`yelp-analysis-503216`.Philly_yelp.philly_businesses
  WHERE categories LIKE '%Restaurants'
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
  )

  SELECT *
  FROM restaurant_ratings rr
  LEFT JOIN restaurant_loans rl USING (postal_code)
  ORDER BY rr.postal_code
