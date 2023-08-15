-- Create the new table
IF OBJECT_ID('tempdb..#StockRanks') IS NOT NULL DROP TABLE #StockRanks;
CREATE TABLE #StockRanks (
    tickerSymbol VARCHAR(255),
	DY_PE_LR_FCF_ROE_PR Int,
	BuyBack Int,
	FCFY_SCD Int,
	ABB_FCF_CR_CE_NI Int

);

------------14 Cash Usage Screen-------------
;WITH Normalized AS (
    SELECT *,
           (divYield - Min(divYield) OVER ()) / (Max(divYield) OVER () - Min(divYield) OVER ()) AS Standardized_divYield,
           1 - ((PE_Ratio - Min(PE_Ratio) OVER ()) / (Max(PE_Ratio) OVER () - Min(PE_Ratio) OVER ())) AS Standardized_PE_Ratio,
           1 - ((debtEquityRatio - Min(debtEquityRatio) OVER ()) / (Max(debtEquityRatio) OVER () - Min(debtEquityRatio) OVER ())) AS Standardized_debtEquityRatio,
           (freeCashFlow - Min(freeCashFlow) OVER ()) / (Max(freeCashFlow) OVER () - Min(freeCashFlow) OVER ()) AS Standardized_freeCashFlow,
           (returnOnEquity - Min(returnOnEquity) OVER ()) / (Max(returnOnEquity) OVER () - Min(returnOnEquity) OVER ()) AS Standardized_returnOnEquity,
           1 - ((payoutRatio - Min(payoutRatio) OVER ()) / (Max(payoutRatio) OVER () - Min(payoutRatio) OVER ())) AS Standardized_payoutRatio
    FROM [QIAR_TEST].[dbo].[snCashUsageScreen]
)
INSERT INTO #StockRanks (tickerSymbol, DY_PE_LR_FCF_ROE_PR)
SELECT tickerSymbol,
       CASE 
           WHEN Standardized_divYield IS NULL or Standardized_PE_Ratio is null or Standardized_debtEquityRatio is null
		   or Standardized_freeCashFlow is null or  Standardized_returnOnEquity is null or Standardized_payoutRatio is null  THEN NULL
           ELSE RANK() OVER (ORDER BY (Standardized_divYield + Standardized_PE_Ratio + Standardized_debtEquityRatio + Standardized_freeCashFlow + Standardized_returnOnEquity
		   + Standardized_payoutRatio) DESC)
       END AS Rank
FROM Normalized;



----(15) Buybacks: Change in Capital Deployment Strategy-----------
;WITH Normalized AS (
    SELECT *,
           (buyBackLast24Months - Min(buyBackLast24Months) OVER ()) / (Max(buyBackLast24Months) OVER () - Min(buyBackLast24Months) OVER ()) AS Standardized_buyBackLast24Months
    FROM [QIAR_TEST].[dbo].[snBuyBackCashUsage]
), Strategy2 AS (
    SELECT tickerSymbol,
	RANK() OVER (ORDER BY (buyBackLast24Months) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET BuyBack  = Strategy2.Rank
FROM Strategy2
WHERE #StockRanks.tickerSymbol = Strategy2.tickerSymbol;

--------------16 Large Net Buyback with High FCFF Yld-------------------
;WITH Normalized AS (
    SELECT *,
           (freeCFYield - Min(freeCFYield) OVER ()) / (Max(freeCFYield) OVER () - Min(freeCFYield) OVER ()) AS Standardized_freeCFYield,
           (shareCountDecline - Min(shareCountDecline) OVER ()) / (Max(shareCountDecline) OVER () - Min(shareCountDecline) OVER ()) AS Standardized_shareCountDecline
    FROM [QIAR_TEST].[dbo].[snLargeBuyBack]
), Strategy3 AS (
    SELECT tickerSymbol,
       RANK() OVER (ORDER BY (Standardized_freeCFYield + Standardized_shareCountDecline) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET FCFY_SCD  = Strategy3.Rank
FROM Strategy3
WHERE #StockRanks.tickerSymbol = Strategy3.tickerSymbol;

------------------17 Accelerating Buybacks--------------
;WITH Normalized AS (
    SELECT *,
           (acclerationOfBuyBack - Min(acclerationOfBuyBack) OVER ()) / (Max(acclerationOfBuyBack) OVER () - Min(acclerationOfBuyBack) OVER ()) AS Standardized_acclerationOfBuyBack,
           (freeCashFlow - Min(freeCashFlow) OVER ()) / (Max(freeCashFlow) OVER () - Min(freeCashFlow) OVER ()) AS Standardized_freeCashFlow,
           (currentRatio - Min(currentRatio) OVER ()) / (Max(currentRatio) OVER () - Min(currentRatio) OVER ()) AS Standardized_currentRatio,
           (cashEquivalent - Min(cashEquivalent) OVER ()) / (Max(cashEquivalent) OVER () - Min(cashEquivalent) OVER ()) AS Standardized_cashEquivalent,
           (netIncome - Min(netIncome) OVER ()) / (Max(netIncome) OVER () - Min(netIncome) OVER ()) AS Standardized_netIncome
    FROM [QIAR_TEST].[dbo].[snAcceleratingBuyBack]
), Strategy4 AS (
    SELECT tickerSymbol,
       RANK() OVER (ORDER BY (Standardized_acclerationOfBuyBack + Standardized_freeCashFlow + Standardized_currentRatio + Standardized_cashEquivalent + Standardized_netIncome) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET ABB_FCF_CR_CE_NI  = Strategy4.Rank
FROM Strategy4
WHERE #StockRanks.tickerSymbol = Strategy4.tickerSymbol;



--select * into [QIAR_TEST].[dbo].[snCrossSectionalRanksCash] from #StockRanks

--select * from  [QIAR_TEST].[dbo].[snCrossSectionalRanksCash] order by DY_PE_LR_FCF_ROE_PR  asc

--drop table [QIAR_TEST].[dbo].[snCrossSectionalRanksCash]

-- select * from #StockRanks
