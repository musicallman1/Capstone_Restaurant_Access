SELECT
    CASE
        WHEN BusinessAge = 'Startup, Loan Funds will Open Business' THEN 'Startup'
        ELSE 'Non-Startup'
    END AS age_group,
    COUNT(*) AS all_loan_count,
    COUNTIF(CAST(NaicsCode AS STRING) LIKE '7225%') AS restaurant_loan_count,
    ROUND(COUNTIF(CAST(NaicsCode AS STRING) LIKE '7225%') / COUNT(*) * 100, 2) AS restaurant_pct_of_group
FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
GROUP BY age_group
