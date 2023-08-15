--------------------------------(1) Free Cash Flow Yield-----------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @freeCashFlow FLOAT
DECLARE @marketCap FLOAT
Declare @tradingItemID Int

-- Create a temporary table to store the results
IF OBJECT_ID('tempdb..#freeCashFlowYield') IS NOT NULL DROP TABLE #freeCashFlowYield;
CREATE TABLE #freeCashFlowYield (
    tickerSymbol VARCHAR(255),
    freeCashFlow FLOAT,
    marketCap  float,
	freeCFYield FLOAT,
	asOfDate DATETIME
)


-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
 -- Initialize the variables for each iteration
	SET @freeCashFlow  = Null
	SET @marketCap  = Null
    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol,
		@tradingItemID=tradingItemID
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY CompanyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter

SELECT @freeCashFlow=fd.dataItemValue 
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag = 1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =4422 -- Free Cash Flow (Levered i.e after paying taxes and debt obligation)
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId =@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc


select top 1 @marketCap=m.marketCap
from [Xpressfeed].[dbo].[ciqMarketCap] m where companyId=@companyId order by pricingDate desc


 INSERT INTO #freeCashFlowYield (tickerSymbol,freeCashFlow, marketCap,asOfDate)
  VALUES (@tickerSymbol, @freeCashFlow,@marketCap,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END
-- alter table #freeCashFlowYield drop column freeCashFlowYield
UPDATE #freeCashFlowYield
SET freeCFYield = freeCashFlow / marketCap

-- drop table [QIAR_TEST].[dbo].[snFreeCashFlowYield]
--select * into [QIAR_TEST].[dbo].[snFreeCashFlowYield] from #freeCashFlowYield
--select * from #freeCashFlowYield


------------Ranking as per strategy----------

SELECT *,
       RANK() OVER (ORDER BY freeCFYield DESC) AS Rank
FROM [QIAR_TEST].[dbo].[snFreeCashFlowYield]
ORDER BY Rank;

--------------Ranking 2: Standardize and Rank--------------
WITH Normalized AS (
    SELECT *,
           (freeCashFlow - MIN(freeCashFlow) OVER ()) / (MAX(freeCashFlow) OVER () - MIN(freeCashFlow) OVER ()) AS Normalized_freeCashFlow,
           (marketCap - MIN(marketCap) OVER ()) / (MAX(marketCap) OVER () - MIN(marketCap) OVER ()) AS Normalized_marketCap
    FROM [QIAR_TEST].[dbo].[snFreeCashFlowYield]
)
SELECT *,
       Normalized_freeCashFlow + Normalized_marketCap AS CombinedNormalizedValues,
       RANK() OVER (ORDER BY (Normalized_freeCashFlow + Normalized_marketCap) DESC) AS Rank
FROM Normalized
ORDER BY Rank;


------------------Ranking 3: Rank Individually-----------
WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY freeCashFlow DESC) AS Rank_freeCashFlow,
           RANK() OVER (ORDER BY marketCap DESC) AS Rank_marketCap
    FROM [QIAR_TEST].[dbo].[snFreeCashFlowYield]
)
SELECT *,
       Rank_freeCashFlow + Rank_marketCap AS CombinedRanks,
       RANK() OVER (ORDER BY (Rank_freeCashFlow + Rank_marketCap) ASC) AS Rank
FROM Ranked
ORDER BY Rank;





