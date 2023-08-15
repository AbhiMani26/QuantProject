-- Create the new table
IF OBJECT_ID('tempdb..#StockRanks') IS NOT NULL DROP TABLE #StockRanks;
CREATE TABLE #StockRanks (
    tickerSymbol VARCHAR(255),
	DY_ADG_LTDYA_PELTM Int,
	DY_PR_LR Int,
	DCGAR_MC_FCF_PELTM_SCD_FCFY Int,
	DY_MC_PENTM Int

);

------------(18) Consistent Dividend Growth with Attractive Valuation-------------
;WITH Normalized AS (
    SELECT *,
           (divYield - Min(divYield) OVER ()) / (Max(divYield) OVER () - Min(divYield) OVER ()) AS Standardized_divYield,
           (annualDivGrowth - Min(annualDivGrowth) OVER ()) / (Max(annualDivGrowth) OVER () - Min(annualDivGrowth) OVER ()) AS Standardized_annualDivGrowth,
           (LTAverage - Min(LTAverage) OVER ()) / (Max(LTAverage) OVER () - Min(LTAverage) OVER ()) AS Standardized_LTAverage,
		   (PE_Ratio_12_Mo - Min(PE_Ratio_12_Mo) OVER ()) / (Max(PE_Ratio_12_Mo) OVER () - Min(PE_Ratio_12_Mo) OVER ()) AS Standardized_PE_Ratio_12_Mo
    FROM [QIAR_TEST].[dbo].[snConsistentDivGrowth]
)
INSERT INTO #StockRanks (tickerSymbol, DY_ADG_LTDYA_PELTM)
SELECT tickerSymbol,
       CASE 
           WHEN Standardized_divYield IS NULL or Standardized_annualDivGrowth is null or Standardized_LTAverage is null
		   or Standardized_PE_Ratio_12_Mo is null   THEN NULL
           ELSE  RANK() OVER (ORDER BY (Standardized_divYield + Standardized_annualDivGrowth + Standardized_LTAverage + Standardized_PE_Ratio_12_Mo) DESC)
       END AS Rank
FROM Normalized;

----(19) High Dividend Yield, Lower Payout Ratio and Not High Leverage-----------
;WITH Normalized AS (
    SELECT *,
           (divYield - Min(divYield) OVER ()) / (Max(divYield) OVER () - Min(divYield) OVER ()) AS Standardized_divYield,
           (payoutRatio - Min(payoutRatio) OVER ()) / (Max(payoutRatio) OVER () - Min(payoutRatio) OVER ()) AS Standardized_payoutRatio,
           (debtEquityRatio - Min(debtEquityRatio) OVER ()) / (Max(debtEquityRatio) OVER () - Min(debtEquityRatio) OVER ()) AS Standardized_debtEquityRatio
    FROM [QIAR_TEST].[dbo].[snHighYieldLowPRLowLeverage]
), Strategy2 AS (
    SELECT tickerSymbol,
	RANK() OVER (ORDER BY (Standardized_divYield - Standardized_payoutRatio - Standardized_debtEquityRatio) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET DY_PR_LR  = Strategy2.Rank
FROM Strategy2
WHERE #StockRanks.tickerSymbol = Strategy2.tickerSymbol;


----(20) High Dividend Growth and High FCFF Yield-----------
;WITH Normalized AS (
    SELECT *,
           (dividendPerShare5YearCAGR - Min(dividendPerShare5YearCAGR) OVER ()) / (Max(dividendPerShare5YearCAGR) OVER () - Min(dividendPerShare5YearCAGR) OVER ()) AS Standardized_dividendPerShare5YearCAGR,
           (marketCap - Min(marketCap) OVER ()) / (Max(marketCap) OVER () - Min(marketCap) OVER ()) AS Standardized_marketCap,
           (freeCashFlow - Min(freeCashFlow) OVER ()) / (Max(freeCashFlow) OVER () - Min(freeCashFlow) OVER ()) AS Standardized_freeCashFlow,
		   (PE_Ratio_12_Mo - Min(PE_Ratio_12_Mo) OVER ()) / (Max(PE_Ratio_12_Mo) OVER () - Min(PE_Ratio_12_Mo) OVER ()) AS Standardized_PE_Ratio_12_Mo,
		   (shareCountDecline - Min(shareCountDecline) OVER ()) / (Max(shareCountDecline) OVER () - Min(shareCountDecline) OVER ()) AS Standardized_shareCountDecline,
		   (freeCashFlowYield - Min(freeCashFlowYield) OVER ()) / (Max(freeCashFlowYield) OVER () - Min(freeCashFlowYield) OVER ()) AS Standardized_freeCashFlowYield
    FROM [QIAR_TEST].[dbo].[snHighDivGrowthHighFCFFYield]
), Strategy3 AS (
    SELECT tickerSymbol,
	RANK() OVER (ORDER BY (Standardized_dividendPerShare5YearCAGR + Standardized_marketCap + Standardized_freeCashFlow + Standardized_PE_Ratio_12_Mo
	   +Standardized_shareCountDecline + Standardized_freeCashFlowYield ) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET DCGAR_MC_FCF_PELTM_SCD_FCFY  = Strategy3.Rank
FROM Strategy3
WHERE #StockRanks.tickerSymbol = Strategy3.tickerSymbol;




----(21) 2nd Quntile Divi Yield and Attractive Valuation-----------
;WITH Normalized AS (
    SELECT *,
           (divYield - Min(divYield) OVER ()) / (Max(divYield) OVER () - Min(divYield) OVER ()) AS Standardized_divYield,
           (marketCap - Min(marketCap) OVER ()) / (Max(marketCap) OVER () - Min(marketCap) OVER ()) AS Standardized_marketCap,
           (NTM_PE_Ratio - Min(NTM_PE_Ratio) OVER ()) / (Max(NTM_PE_Ratio) OVER () - Min(NTM_PE_Ratio) OVER ()) AS Standardized_NTM_PE_Ratio
    FROM [QIAR_TEST].[dbo].[snHighDivYieldAndValuation]
), Strategy4 AS (
    SELECT tickerSymbol,
	RANK() OVER (ORDER BY (Standardized_divYield + Standardized_marketCap + Standardized_NTM_PE_Ratio ) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET DY_MC_PENTM  = Strategy4.Rank
FROM Strategy4
WHERE #StockRanks.tickerSymbol = Strategy4.tickerSymbol;


--select * into [QIAR_TEST].[dbo].[snCrossSectionalRanksDividend] from #StockRanks

--select * from  [QIAR_TEST].[dbo].[snCrossSectionalRanksDividend] order by DY_ADG_LTDYA_PELTM  asc

--drop table [QIAR_TEST].[dbo].[snCrossSectionalRanksDividend]

-- select * from #StockRanks


SELECT top 50 tickerSymbol 
INTO [QIAR_TEST].[dbo].[div_stocks]
FROM [QIAR_TEST].[dbo].[snCrossSectionalRanksDividend] 
ORDER BY (ISNULL(DY_ADG_LTDYA_PELTM, 0) + ISNULL(DY_PR_LR, 0) + ISNULL(DCGAR_MC_FCF_PELTM_SCD_FCFY, 0) + ISNULL(DY_MC_PENTM, 0)) ASC

select * from [QIAR_TEST].[dbo].[div_stocks]
