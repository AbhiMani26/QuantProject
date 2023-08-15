-- Create the new table
IF OBJECT_ID('tempdb..#StockRanks') IS NOT NULL DROP TABLE #StockRanks;
CREATE TABLE #StockRanks (
    tickerSymbol VARCHAR(255),
	ROTA Int,
	PE_SCD Int

);

-----------31 ROTA------------
;WITH Normalized AS (
    SELECT *,
           (ROTA - Min(ROTA) OVER ()) / (Max(ROTA) OVER () - Min(ROTA) OVER ()) AS Standardized_ROTA
    FROM [QIAR_TEST].[dbo].[snhighROTA] 
)
INSERT INTO #StockRanks (tickerSymbol, ROTA)
SELECT tickerSymbol,
       CASE 
           WHEN ROTA IS NULL   THEN NULL
           ELSE  RANK() OVER (ORDER BY (Standardized_ROTA) DESC)
       END AS Rank
FROM Normalized;

------------32 Financials: Low P/E and Largest Decline in Share Count---------

;WITH Normalized AS (
    SELECT *,
           (PE_Ratio - Min(PE_Ratio) OVER ()) / (Max(PE_Ratio) OVER () - Min(PE_Ratio) OVER ()) AS Standardized_PE_Ratio,
		   (shareCountDecline - Min(shareCountDecline) OVER ()) / (Max(shareCountDecline) OVER () - Min(shareCountDecline) OVER ()) AS Standardized_shareCountDecline
    FROM [QIAR_TEST].[dbo].[snFinancial]
), Strategy2 AS (
    SELECT tickerSymbol,
	RANK() OVER (ORDER BY (shareCountDecline - Standardized_PE_Ratio ) DESC) AS Rank
    FROM Normalized
)
UPDATE #StockRanks
SET PE_SCD  = Strategy2.Rank
FROM Strategy2
WHERE #StockRanks.tickerSymbol = Strategy2.tickerSymbol;



--select * into [QIAR_TEST].[dbo].[snCrossSectionalRanksFinancial] from #StockRanks

--select * from  [QIAR_TEST].[dbo].[snCrossSectionalRanksFinancial] order by ROTA  asc

--drop table [QIAR_TEST].[dbo].[snCrossSectionalRanksFinancial]

--select * from #StockRanks

SELECT top 50 tickerSymbol 
INTO [QIAR_TEST].[dbo].[fin_stocks]
FROM [QIAR_TEST].[dbo].[snCrossSectionalRanksFinancial] 
ORDER BY (ISNULL(ROTA, 0) + ISNULL(PE_SCD, 0)) ASC

select * from [QIAR_TEST].[dbo].[fin_stocks]

