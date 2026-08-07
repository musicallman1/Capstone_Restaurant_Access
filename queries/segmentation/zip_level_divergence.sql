WITH business_reputation AS
(SELECT 
  postal_code,
  COUNT(*) AS business_count,
  AVG(stars) AS business_rating, 
  SUM(review_count) AS total_reviews, 
FROM`yelp-analysis-503216`.Philly_yelp.philly_businesses
GROUP BY postal_code), 

loan_activity AS 
(SELECT
  BorrZip AS postal_code,
  COUNT(*) AS loan_count,
  SUM(GrossApproval) AS total_loan_value,
  AVG(GrossApproval) AS avg_loan_size,
FROM `yelp-analysis-503216`.Philly_yelp.sba_loans
GROUP BY BorrZip)

SELECT *
FROM business_reputation br
LEFT JOIN loan_activity la USING (postal_code)
ORDER BY br.postal_code
