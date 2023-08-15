-- Create the new table
IF OBJECT_ID('tempdb..#StockRanks') IS NOT NULL DROP TABLE #StockRanks;
CREATE TABLE #StockRanks (
    tickerSymbol VARCHAR(255),
	CAGR_EPS_Revenue Int,
	NTM_Market_EPS_EQ_TA Int,
	ROE_EPS_EQ_SI Int,
	PEG_EQ Int
);

------------10 Secular Growth-------------
WITH Normalized AS (
    SELECT *,
           (lt_CAGR - Min(lt_CAGR) OVER ()) / (Max(lt_CAGR) OVER () - Min(lt_CAGR) OVER ()) AS Standardized_lt_CAGR,
           (lt_EPS_CAGR - Min(lt_EPS_CAGR) OVER ()) / (Max(lt_EPS_CAGR) OVER () - Min(lt_EPS_CAGR) OVER ()) AS Standardized_lt_EPS_CAGR,
           (st_revenue_CAGR - Min(st_revenue_CAGR) OVER ()) / (Max(st_revenue_CAGR) OVER () - Min(st_revenue_CAGR) OVER ()) AS Standardized_st_revenue_CAGR
    FROM [QIAR_TEST].[dbo].[snSecularGrowth] 
)
INSERT INTO #StockRanks (tickerSymbol, CAGR_EPS_Revenue)
SELECT tickerSymbol,
       CASE 
           WHEN Standardized_lt_CAGR IS NULL or Standardized_lt_EPS_CAGR is null or Standardized_st_revenue_CAGR is null  THEN NULL
           ELSE RANK() OVER (ORDER BY (Standardized_lt_CAGR + Standardized_lt_EPS_CAGR + Standardized_st_revenue_CAGR) DESC)
       END AS Rank
FROM Normalized;

------------11 Acclerating Growth------------
WITH Normalized AS (
    SELECT *,
           (mrqEpsGrowth - Min(mrqEpsGrowth) OVER ()) / (Max(mrqEpsGrowth) OVER () - Min(mrqEpsGrowth) OVER ()) AS Standardized_mrqEpsGrowth,
           (secondDerivativeEPSGrowth - Min(secondDerivativeEPSGrowth) OVER ()) / (Max(secondDerivativeEPSGrowth) OVER () - Min(secondDerivativeEPSGrowth) OVER ()) AS Standardized_secondDerivativeEPSGrowth,
           (NTM_EPS - Min(NTM_EPS) OVER ()) / (Max(NTM_EPS) OVER () - Min(NTM_EPS) OVER ()) AS Standardized_NTM_EPS,
           (earningQuality - Min(earningQuality) OVER ()) / (Max(earningQuality) OVER () - Min(earningQuality) OVER ()) AS Standardized_earningQuality,
           (totalAssets - Min(totalAssets) OVER ()) / (Max(totalAssets) OVER () - Min(totalAssets) OVER ()) AS Standardized_totalAssets
    FROM [QIAR_TEST].[dbo].[snAccelaratedGrowth] where mrqEpsGrowth is not null and secondDerivativeEPSGrowth is not null and NTM_EPS is not null and earningQuality is not null 
	and totalAssets is not null
), Strategy2 AS (
    SELECT tickerSymbol,
           RANK() OVER (ORDER BY (Standardized_mrqEpsGrowth + Standardized_secondDerivativeEPSGrowth + Standardized_NTM_EPS + Standardized_earningQuality + Standardized_totalAssets) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET NTM_Market_EPS_EQ_TA  = Strategy2.Rank
FROM Strategy2
WHERE #StockRanks.tickerSymbol = Strategy2.tickerSymbol;

------------------(12) High ROE & Consisent EPS Growth-------------
WITH Normalized AS (
    SELECT *,
           (returnOnEquity - Min(returnOnEquity) OVER ()) / (Max(returnOnEquity) OVER () - Min(returnOnEquity) OVER ()) AS Standardized_returnOnEquity,
           (epsgrowth - Min(epsgrowth) OVER ()) / (Max(epsgrowth) OVER () - Min(epsgrowth) OVER ()) AS Standardized_epsgrowth,
           (earningQuality - Min(earningQuality) OVER ()) / (Max(earningQuality) OVER () - Min(earningQuality) OVER ()) AS Standardized_earningQuality,
           (shortInterest - Min(shortInterest) OVER ()) / (Max(shortInterest) OVER () - Min(shortInterest) OVER ()) AS Standardized_shortInterest
    FROM [QIAR_TEST].[dbo].[snHighROEAndEPSGrowth] where returnOnEquity is not null and epsgrowth is not null and earningQuality is not null and shortInterest is not null
), Strategy3 AS (
    SELECT tickerSymbol,
          RANK() OVER (ORDER BY (Standardized_returnOnEquity + Standardized_epsgrowth + Standardized_earningQuality - Standardized_shortInterest) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET ROE_EPS_EQ_SI  = Strategy3.Rank
FROM Strategy3
WHERE #StockRanks.tickerSymbol = Strategy3.tickerSymbol;

----------------13 Low PEG and High Earnings Quality------------
WITH Normalized AS (
    SELECT *,
           (PE_Ratio_by_growth - Min(PE_Ratio_by_growth) OVER ()) / (Max(PE_Ratio_by_growth) OVER () - Min(PE_Ratio_by_growth) OVER ()) AS Standardized_PEG,
           (earningQuality - Min(earningQuality) OVER ()) / (Max(earningQuality) OVER () - Min(earningQuality) OVER ()) AS Standardized_EQ
    FROM [QIAR_TEST].[dbo].[snLowPEGHighEQ] where PE_Ratio_by_growth is not null and earningQuality is not null
), Strategy4 AS (
    SELECT tickerSymbol,
           RANK() OVER (ORDER BY (Standardized_EQ - Standardized_PEG) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET PEG_EQ  = Strategy4.Rank
FROM Strategy4
WHERE #StockRanks.tickerSymbol = Strategy4.tickerSymbol;

--select * from #StockRanks

--select * into [QIAR_TEST].[dbo].[snCrossSectionalRanksGrowth] from #StockRanks

--select * from  [QIAR_TEST].[dbo].[snCrossSectionalRanksGrowth] order by case when PEG_EQ is null then 1 else 0 end,  PEG_EQ asc


--drop table [QIAR_TEST].[dbo].[snCrossSectionalRanksGrowth]


SELECT top 50 tickerSymbol 
INTO [QIAR_TEST].[dbo].[growth_stocks]
FROM [QIAR_TEST].[dbo].[snCrossSectionalRanksGrowth]
ORDER BY (ISNULL(CAGR_EPS_Revenue, 0) + ISNULL(NTM_Market_EPS_EQ_TA, 0) + ISNULL(ROE_EPS_EQ_SI, 0) + ISNULL(PEG_EQ, 0)) ASC

select * from [QIAR_TEST].[dbo].[growth_stocks]