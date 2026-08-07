WITH categorized AS 
(SELECT
  CASE
    WHEN BusinessAge = 'Startup, Loan Funds will Open Business'THEN 'Startup'
    ELSE 'Non-Startup'
  END AS OnRows,
  CASE 
    WHEN CAST(NaicsCode AS STRING) LIKE '7225%'THEN 'Restaurant'
    ELSE 'Non-restaurant'
  END AS OnCols
FROM `yelp-analysis-503216.Philly_yelp.sba_loans`
), 

ObservedCombinationCTE AS 
(SELECT 
  Onrows,
  Oncols,
  COUNT(*) AS ObservedCombination
FROM categorized
GROUP BY Onrows, Oncols),

ExpectedCombinationCTE AS
(SELECT
  Onrows, Oncols, ObservedCombination, 
  SUM(ObservedCombination) OVER (PARTITION BY OnRows) AS ObservedOnRows, 
  SUM(ObservedCombination) OVER (PARTITION BY OnCols) AS ObservedOnCols, 
  SUM(ObservedCombination) OVER () AS ObservedTotal,
   (SUM(1.0 * ObservedCombination) OVER (PARTITION BY OnRows)
         * SUM(1.0 * ObservedCombination) OVER (PARTITION BY OnCols)
         / SUM(1.0 * ObservedCombination) OVER ()) AS ExpectedCombination
 FROM ObservedCombinationCTE
)

SELECT
    SUM(POWER(ObservedCombination - ExpectedCombination, 2) / ExpectedCombination) AS ChiSquared,
    (COUNT(DISTINCT OnRows) - 1) * (COUNT(DISTINCT OnCols) - 1) AS DegreesOfFreedom
FROM ExpectedCombinationCTE
