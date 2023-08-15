-- Create the new table
IF OBJECT_ID('tempdb..#StockRanks') IS NOT NULL DROP TABLE #StockRanks;
CREATE TABLE #StockRanks (
    tickerSymbol VARCHAR(255),
	MC_ROE_EQ_SI_IFCF Int,
	IFCF_ROE_IGR_SCD Int,
	EB_RB_PM Int,
	NHFO Int

);

-----------22------------
;WITH Normalized AS (
    SELECT *,
           (marketCap - Min(marketCap) OVER ()) / (Max(marketCap) OVER () - Min(marketCap) OVER ()) AS Standardized_marketCap,
           (returnOnEquity - Min(returnOnEquity) OVER ()) / (Max(returnOnEquity) OVER () - Min(returnOnEquity) OVER ()) AS Standardized_returnOnEquity,
		   (earningQuality - Min(earningQuality) OVER ()) / (Max(earningQuality) OVER () - Min(earningQuality) OVER ()) AS Standardized_earningQuality,
           (shortInterest - Min(shortInterest) OVER ()) / (Max(shortInterest) OVER () - Min(shortInterest) OVER ()) AS Standardized_shortInterest,
           (incrementalFreeCashFlow - Min(incrementalFreeCashFlow) OVER ()) / (Max(incrementalFreeCashFlow) OVER () - Min(incrementalFreeCashFlow) OVER ()) AS Standardized_incrementalFreeCashFlow
    FROM [QIAR_TEST].[dbo].[snHighIncrementalFCF]
)
INSERT INTO #StockRanks (tickerSymbol, MC_ROE_EQ_SI_IFCF)
SELECT tickerSymbol,
       CASE 
           WHEN Standardized_marketCap IS NULL or Standardized_returnOnEquity is null or Standardized_earningQuality is null
		   or Standardized_shortInterest is null or Standardized_incrementalFreeCashFlow is null   THEN NULL
           ELSE RANK() OVER (ORDER BY (Standardized_marketCap + Standardized_returnOnEquity  + Standardized_earningQuality + Standardized_incrementalFreeCashFlow - Standardized_shortInterest) DESC)
       END AS Rank
FROM Normalized;


-----------23--------------

;WITH Normalized AS (
    SELECT *,
           (incrementalFreeCashFlow - Min(incrementalFreeCashFlow) OVER ()) / (Max(incrementalFreeCashFlow) OVER () - Min(incrementalFreeCashFlow) OVER ()) AS Standardized_incrementalFreeCashFlow,
           (returnOnEquity - Min(returnOnEquity) OVER ()) / (Max(returnOnEquity) OVER () - Min(returnOnEquity) OVER ()) AS Standardized_returnOnEquity,
		   (internalGrowthRate - Min(internalGrowthRate) OVER ()) / (Max(internalGrowthRate) OVER () - Min(internalGrowthRate) OVER ()) AS Standardized_internalGrowthRate,
           (shareCountDecline - Min(shareCountDecline) OVER ()) / (Max(shareCountDecline) OVER () - Min(shareCountDecline) OVER ()) AS Standardized_shareCountDecline,
           (ROIC - Min(ROIC) OVER ()) / (Max(ROIC) OVER () - Min(ROIC) OVER ()) AS Standardized_ROIC
    FROM [QIAR_TEST].[dbo].[snhighICEAndCashusage] 
), Strategy2 AS (
    SELECT tickerSymbol,
	RANK() OVER (ORDER BY (Standardized_incrementalFreeCashFlow + Standardized_returnOnEquity  + Standardized_internalGrowthRate + Standardized_shareCountDecline + Standardized_ROIC) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET IFCF_ROE_IGR_SCD  = Strategy2.Rank
FROM Strategy2
WHERE #StockRanks.tickerSymbol = Strategy2.tickerSymbol;


----------24-----------------
;WITH Normalized AS (
  SELECT *,
           (earningBeats - Min(earningBeats) OVER ()) / (Max(earningBeats) OVER () - Min(earningBeats) OVER ()) AS Standardized_earningBeats,
		   (revenueBeats - Min(revenueBeats) OVER ()) / (Max(revenueBeats) OVER () - Min(revenueBeats) OVER ()) AS Standardized_revenueBeats,
		   (priceMovement - Min(priceMovement) OVER ()) / (Max(priceMovement) OVER () - Min(priceMovement) OVER ()) AS Standardized_priceMovement
    FROM [QIAR_TEST].[dbo].[snDoubleBeatsScreen]
), Strategy3 AS (
    SELECT tickerSymbol,
 RANK() OVER (ORDER BY (Standardized_earningBeats + Standardized_revenueBeats + Standardized_priceMovement ) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET EB_RB_PM  = Strategy3.Rank
FROM Strategy3
WHERE #StockRanks.tickerSymbol = Strategy3.tickerSymbol;


--------------------25----------------

;WITH Normalized AS (
    SELECT *,
           (numberOfHedgeFundOwners - Min(numberOfHedgeFundOwners) OVER ()) / (Max(numberOfHedgeFundOwners) OVER () - Min(numberOfHedgeFundOwners) OVER ()) AS Standardized_numberOfHedgeFundOwners
    FROM [QIAR_TEST].[dbo].[snHedgeFundOwnership]
), Strategy4 AS (
    SELECT tickerSymbol,
	RANK() OVER (ORDER BY (numberOfHedgeFundOwners) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET NHFO  = Strategy4.Rank
FROM Strategy4
WHERE #StockRanks.tickerSymbol = Strategy4.tickerSymbol;




--select * into [QIAR_TEST].[dbo].[snCrossSectionalRanksCapitalCreation] from #StockRanks

--select * from  [QIAR_TEST].[dbo].[snCrossSectionalRanksCapitalCreation] order by DY_ADG_LTDYA_PELTM  asc

--drop table [QIAR_TEST].[dbo].[snCrossSectionalRanksCapitalCreation]

-- select * from #StockRanks

SELECT top 50 tickerSymbol 
INTO [QIAR_TEST].[dbo].[cap_stocks]
FROM [QIAR_TEST].[dbo].[snCrossSectionalRanksCapitalCreation]
ORDER BY (ISNULL(MC_ROE_EQ_SI_IFCF, 0) + ISNULL(IFCF_ROE_IGR_SCD, 0) + ISNULL(EB_RB_PM, 0) + ISNULL(NHFO, 0)) ASC

select * from [QIAR_TEST].[dbo].[cap_stocks]
