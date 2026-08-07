SELECT
    'Restaurants' AS industry, 
    COUNT(DISTINCT b.business_id) AS business_count,
    COALESCE(l.loan_count, 0) AS loan_count,
    ROUND(COALESCE(l.loan_count, 0) / 
    COUNT(DISTINCT b.business_id) * 100, 2) AS citywide_restaurant_loan_prct
FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
CROSS JOIN (
    SELECT COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '7225%'
      AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
) l
WHERE b.categories LIKE '%Restaurants%'
GROUP BY l.loan_count

UNION ALL

SELECT
    'Automotive' AS industry, 
    COUNT(DISTINCT b.business_id) AS business_count,
    COALESCE(l.loan_count, 0) AS loan_count,
    ROUND(COALESCE(l.loan_count, 0) / 
    COUNT(DISTINCT b.business_id) * 100, 2) AS citywide_automotive_loan_prct
FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
CROSS JOIN (
    SELECT COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '8111%'
      AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
) l
WHERE b.categories LIKE '%Auto Repair%' OR b.categories LIKE '%Body Shops%'
GROUP BY l.loan_count

UNION ALL 

SELECT
    'Optometrists' AS industry, 
    COUNT(DISTINCT b.business_id) AS business_count,
    COALESCE(l.loan_count, 0) AS optometrist_loan_count,
    ROUND(COALESCE(l.loan_count, 0) / 
    COUNT(DISTINCT b.business_id) * 100, 2) AS citywide_optometrist_loan_prct
FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
CROSS JOIN (
    SELECT COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '621320%'
      AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
) l
WHERE b.categories LIKE '%Optometrists%'
GROUP BY l.loan_count

UNION ALL

SELECT
    'Primary_Care' AS industry, 
    COUNT(DISTINCT b.business_id) AS business_count,
    COALESCE(l.loan_count, 0) AS primary_care_loan_count,
    ROUND(COALESCE(l.loan_count, 0) / 
    COUNT(DISTINCT b.business_id) * 100, 2) AS citywide_primary_care_loan_prct
FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
CROSS JOIN (
    SELECT COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '621111%'
      AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
) l
WHERE b.categories LIKE '%Family Practice%' OR b.categories LIKE '%Pediatricians%'
GROUP BY l.loan_count

UNION ALL

SELECT
    'Dentists' AS industry, 
    COUNT(DISTINCT b.business_id) AS business_count,
    COALESCE(l.loan_count, 0) AS dentist_loan_count,
    ROUND(COALESCE(l.loan_count, 0) / 
    COUNT(DISTINCT b.business_id) * 100, 2) AS citywide_dentist_loan_prct
FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
CROSS JOIN (
    SELECT COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '621210%'
      AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
) l
WHERE b.categories LIKE '%Dentists%' OR 
    b.categories LIKE '%General Dentistry%' OR 
    b.categories LIKE '%Orthodontist%'
GROUP BY l.loan_count

UNION ALL 

SELECT
    'Veterinarians' AS industry, 
    COUNT(DISTINCT b.business_id) AS business_count,  -- adjust to actual business ID column name
    COALESCE(loan_count, 0) AS vet_loan_count,
    ROUND(COALESCE(loan_count, 0) / 
    COUNT(DISTINCT b.business_id) * 100, 2) AS citywide_vet_loan_prct
FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
CROSS JOIN (
    SELECT COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '541940%'
      AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
) l
WHERE b.categories LIKE '%Veterinarian%'
GROUP BY loan_count

UNION ALL

SELECT
    'Accountants' AS industry, 
    COUNT(DISTINCT b.business_id) AS business_count,  -- adjust to actual business ID column name
    COALESCE(loan_count, 0) AS acct_loan_count,
    ROUND(COALESCE(loan_count, 0) / 
    COUNT(DISTINCT b.business_id) * 100, 2) AS citywide_acct_loan_prct
FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
CROSS JOIN (
    SELECT COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE CAST(NaicsCode AS STRING) LIKE '541211%'
      AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
) l
WHERE b.categories LIKE '%Accountant%'
GROUP BY loan_count

UNION ALL

SELECT
    'Beauty_Shops' AS industry, 
    COUNT(DISTINCT b.business_id) AS business_count,
    COALESCE(loan_count, 0) AS beauty_loan_count,
    ROUND(COALESCE(loan_count, 0) / 
    COUNT(DISTINCT b.business_id) * 100, 2) AS citywide_beauty_loan_prct
FROM `yelp-analysis-503216.Philly_yelp.philly_businesses` b
CROSS JOIN (
    SELECT COUNT(*) AS loan_count
    FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
    WHERE (
        CAST(NaicsCode AS STRING) LIKE '812111%' OR 
        CAST(NaicsCode AS STRING) LIKE '812112%' OR
        CAST(NaicsCode AS STRING) LIKE '812113%'
    )
    AND ApprovalDate BETWEEN '2018-01-01' AND '2022-12-31'
) l
WHERE b.categories LIKE '%Beauty & Spas%' OR 
    b.categories LIKE '%Hair Salons%'
GROUP BY loan_count
