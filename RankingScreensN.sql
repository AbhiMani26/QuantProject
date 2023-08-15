-- Create the new table
IF OBJECT_ID('tempdb..#StockRanks') IS NOT NULL DROP TABLE #StockRanks;
CREATE TABLE #StockRanks (
    tickerSymbol VARCHAR(255),
    FCFY INT,
	CA_MC_LR INT,
EY_DY_LR_MC_PE_RG INT, EPS_Upside_EQ_SI_BR INT,NC_MC INT,RSI_M_PE INT, EV_Sales INT, EV_EBITDA INT, PBV_ROCE INT,
);


WITH Normalized AS (
    SELECT *,
           (freeCFYield - MIN(freeCFYield) OVER ()) / (MAX(freeCFYield) OVER () - MIN(freeCFYield) OVER ()) AS Normalized_freeCashFlowY
    FROM [QIAR_TEST].[dbo].[snFreeCashFlowYield]
)
INSERT INTO #StockRanks (tickerSymbol, FCFY)
SELECT tickerSymbol, 
       CASE 
           WHEN freeCFYield IS NULL THEN NULL
           ELSE RANK() OVER (ORDER BY Normalized_freeCashFlowY DESC)
       END AS Rank
FROM Normalized;




-- Level 2------------
;WITH Normalized AS (
    SELECT *,
           (netCurrentAssest - MIN(netCurrentAssest) OVER ()) / (MAX(netCurrentAssest) OVER () - MIN(netCurrentAssest) OVER ()) AS Normalized_netCurrentAssest,
           (marketCap - MIN(marketCap) OVER ()) / (MAX(marketCap) OVER () - MIN(marketCap) OVER ()) AS Normalized_marketCap,
           (debtEquityRatio - MIN(debtEquityRatio) OVER ()) / (MAX(debtEquityRatio) OVER () - MIN(debtEquityRatio) OVER ()) AS Normalized_debtEquityRatio
    FROM [QIAR_TEST].[dbo].[snNetNets] where netCurrentAssest is not null and marketCap is not null and debtEquityRatio is not null
) , Strategy2 AS (
    SELECT tickerSymbol,
           RANK() OVER (ORDER BY (Normalized_netCurrentAssest + Normalized_marketCap - Normalized_debtEquityRatio) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET CA_MC_LR  = Strategy2.Rank
FROM Strategy2
WHERE #StockRanks.tickerSymbol = Strategy2.tickerSymbol;


----screen 3---
;WITH Normalized AS (
    SELECT *,
        (earningYields - MIN(earningYields) OVER ()) / (MAX(earningYields) OVER () - MIN(earningYields) OVER ()) AS normalizedEarningYields,
        (dividendYield - MIN(dividendYield) OVER ()) / (MAX(dividendYield) OVER () - MIN(dividendYield) OVER ()) AS normalizedDividendYield,
        (leverageRatio - MIN(leverageRatio) OVER ()) / (MAX(leverageRatio) OVER () - MIN(leverageRatio) OVER ()) AS normalizedLeverageRatio,
        (marketCap - MIN(marketCap) OVER ()) / (MAX(marketCap) OVER () - MIN(marketCap) OVER ()) AS normalizedMarketCap,
        (peRatio - MIN(peRatio) OVER ()) / (MAX(peRatio) OVER () - MIN(peRatio) OVER ()) AS normalizedPeRatio,
        (revenueGrowth - MIN(revenueGrowth) OVER ()) / (MAX(revenueGrowth) OVER () - MIN(revenueGrowth) OVER ()) AS normalizedRevenueGrowth
		    FROM
        [QIAR_TEST].[dbo].[snDeepStocks] where earningYields is not null and dividendYield is not null and leverageRatio is not null and marketCap is not null and 
		peRatio is not null and revenueGrowth is not null
) , Strategy3 AS (
    SELECT tickerSymbol,
            RANK() OVER (ORDER BY normalizedEarningYields + normalizedDividendYield - normalizedLeverageRatio + 
			normalizedMarketCap - normalizedPeRatio +normalizedRevenueGrowth DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET EY_DY_LR_MC_PE_RG  = Strategy3.Rank
FROM Strategy3
WHERE #StockRanks.tickerSymbol = Strategy3.tickerSymbol;

-------Screen 4----------
;WITH Normalized AS (
    SELECT *,
           (epsgrowth - MIN(epsgrowth) OVER ()) / (MAX(epsgrowth) OVER () - MIN(epsgrowth) OVER ()) AS Normalized_epsgrowth,
           (stockUpside - MIN(stockUpside) OVER ()) / (MAX(stockUpside) OVER () - MIN(stockUpside) OVER ()) AS Normalized_stockUpside,
           (earningQuality - MIN(earningQuality) OVER ()) / (MAX(earningQuality) OVER () - MIN(earningQuality) OVER ()) AS Normalized_earningQuality,
           (numberOfCeoChanges - MIN(numberOfCeoChanges) OVER ()) / (MAX(numberOfCeoChanges) OVER () - MIN(numberOfCeoChanges) OVER ()) AS Normalized_numberOfCeoChanges,
           (shortInterest - MIN(shortInterest) OVER ()) / (MAX(shortInterest) OVER () - MIN(shortInterest) OVER ()) AS Normalized_shortInterest,
           (buyRating - MIN(buyRating) OVER ()) / (MAX(buyRating) OVER () - MIN(buyRating) OVER ()) AS Normalized_buyRating
    FROM [QIAR_TEST].[dbo].[snUnlovedStocks] where epsgrowth is not null and stockUpside is not null and
	earningQuality is not null and numberOfCeoChanges is not null and shortInterest is not null and buyRating is not null
) , Strategy4 AS (
    SELECT tickerSymbol,
            RANK() OVER (ORDER BY (Normalized_epsgrowth + Normalized_stockUpside + Normalized_earningQuality + Normalized_numberOfCeoChanges - Normalized_shortInterest
			+ Normalized_buyRating) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET EPS_Upside_EQ_SI_BR  = Strategy4.Rank
FROM Strategy4
WHERE #StockRanks.tickerSymbol = Strategy4.tickerSymbol;

------Screen 5-----------
;WITH Normalized AS (
     SELECT *,
           (netCash - MIN(netCash) OVER ()) / (MAX(netCash) OVER () - MIN(netCash) OVER ()) AS Normalized_NetCash,
           (marketCap - MIN(marketCap) OVER ()) / (MAX(marketCap) OVER () - MIN(marketCap) OVER ()) AS Normalized_MarketCap
    FROM [QIAR_TEST].[dbo].[snHighCashStocks] where netCash is not null and marketCap is not null
) , Strategy5 AS (
    SELECT tickerSymbol,
           RANK() OVER (ORDER BY (Normalized_NetCash + Normalized_MarketCap) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET NC_MC  = Strategy5.Rank
FROM Strategy5
WHERE #StockRanks.tickerSymbol = Strategy5.tickerSymbol;

-----Screen 6---------
;WITH Normalized AS (
    SELECT
        tickerSymbol, RSI, momentum, peRatio,
        (RSI - MIN(RSI) OVER ()) / (MAX(RSI) OVER () - MIN(RSI) OVER ()) AS normalizedRSI,
        (momentum - MIN(momentum) OVER ()) / (MAX(momentum) OVER () - MIN(momentum) OVER ()) AS normalizedMomentum,
        (peRatio - MIN(peRatio) OVER ()) / (MAX(peRatio) OVER () - MIN(peRatio) OVER ()) AS normalizedPeRatio,
        asOfDate
    FROM
        [QIAR_TEST].[dbo].[snOutOfFavourStocks] where RSI is not null and momentum is not null and peRatio is not null
) , Strategy6 AS (
    SELECT tickerSymbol,
             RANK() OVER (ORDER BY normalizedRSI + normalizedMomentum + normalizedPeRatio DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET RSI_M_PE  = Strategy6.Rank
FROM Strategy6
WHERE #StockRanks.tickerSymbol = Strategy6.tickerSymbol;

-------------Screen 7----------------(Not Done)
;WITH Normalized AS (
    SELECT *,
           (enterpriseValueSalesRatio - MIN(enterpriseValueSalesRatio) OVER ()) / (MAX(enterpriseValueSalesRatio) OVER () - MIN(enterpriseValueSalesRatio) OVER ()) AS normalizedEV
    FROM [QIAR_TEST].[dbo].[snLowEVSalesRatio] where enterpriseValueSalesRatio is not null
) , Strategy7 AS (
    SELECT tickerSymbol,
              RANK() OVER (ORDER BY normalizedEV ASC) AS rank
    FROM Normalized
)
UPDATE #StockRanks
SET EV_Sales  = Strategy7.Rank
FROM Strategy7
WHERE #StockRanks.tickerSymbol = Strategy7.tickerSymbol;

------------Screen 8------------
;WITH Normalized AS (
    SELECT *,
           (TEV - Min(TEV) OVER ()) / (Max(TEV) OVER ()) AS Standardized_TEV,
           (EBITDA_10Y_AVG - Min(EBITDA_10Y_AVG) OVER ()) / (Max(EBITDA_10Y_AVG) OVER ()) AS Standardized_EBITDA_10Y_AVG
    FROM [QIAR_TEST].[dbo].[snCheapCyllicallyAdjustedEBITDA] where TEV is not null and EBITDA_10Y_AVG is not null
),
Strategy8 AS ( SELECT tickerSymbol,
       RANK() OVER (ORDER BY (Standardized_TEV + Standardized_EBITDA_10Y_AVG) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET EV_EBITDA  = Strategy8.Rank
FROM Strategy8
WHERE #StockRanks.tickerSymbol = Strategy8.tickerSymbol;


---------------Screen 9-------------

;WITH Normalized AS (
    SELECT *,
           (ROCE - Min(ROCE) OVER ()) / (Max(ROCE) OVER ()) AS Standardized_ROCE,
           (PBV - Min(PBV) OVER ()) / (Max(PBV) OVER ()) AS Standardized_PBV
    FROM [QIAR_TEST].[dbo].[snPbvRoic]
    WHERE ROCE is not null AND PBV is not null
),
Strategy9 AS ( SELECT tickerSymbol,
       RANK() OVER (ORDER BY (Standardized_ROCE - Standardized_PBV) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET PBV_ROCE  = Strategy9.Rank
FROM Strategy9
WHERE #StockRanks.tickerSymbol = Strategy9.tickerSymbol;


select * from #StockRanks


--select * into [QIAR_TEST].[dbo].[snStockCrossSectionalRanksN] from #StockRanks

--select * from  [QIAR_TEST].[dbo].[snStockCrossSectionalRanksN] order by FCFY asc

--drop table [QIAR_TEST].[dbo].[snStockCrossSectionalRanksN]

--select * from [QIAR_TEST].[dbo].[snFreeCashFlowYield] where freeCFYield is  null

SELECT top 50 tickerSymbol 
INTO [QIAR_TEST].[dbo].[value_stocks]
FROM [QIAR_TEST].[dbo].[snStockCrossSectionalRanksN] 
ORDER BY (ISNULL(FCFY, 0) + ISNULL(CA_MC_LR, 0) + ISNULL(EY_DY_LR_MC_PE_RG, 0) + ISNULL(EPS_Upside_EQ_SI_BR, 0) + ISNULL(NC_MC, 0) +
ISNULL(RSI_M_PE, 0) + ISNULL(EV_EBITDA, 0) + ISNULL(EV_EBITDA, 0) + ISNULL(PBV_ROCE, 0)) ASC

select * from [QIAR_TEST].[dbo].[value_stocks]

-- drop table [QIAR_TEST].[dbo].[value_stocks]