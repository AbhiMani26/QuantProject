----------------------------------(7) Low EV / Sales vs. History--------------------------

DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @tradingItemId INT
DECLARE @enterpriseValueSalesRatio FLOAT 
DECLARE @sales TABLE (financialPeriodId INT, salesRevenue FLOAT)
DECLARE @evSalesRatios TABLE ( evSalesRatio FLOAT)
-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#lowEVSalesRatio') IS NOT NULL DROP TABLE #lowEVSalesRatio;
CREATE TABLE #lowEVSalesRatio (
    tickerSymbol VARCHAR(255),
    enterpriseValueSalesRatio FLOAT,
	asOfDate DATE
)

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
 -- Initialize the values for each iteration
	SET @enterpriseValueSalesRatio=NULL;
    DELETE FROM @sales;
    DELETE FROM @evSalesRatios;
    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
		@tradingItemId = tradingItemID,
        @tickerSymbol = tickerSymbol
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY companyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter

------------------------EV/Sales ratio Latest-----------------
SELECT @enterpriseValueSalesRatio=mc.TEV/fp.dataItemValue
FROM (
    SELECT TOP 1 *
    FROM [Xpressfeed].[dbo].[ciqMarketCap]
    WHERE companyId = @companyId
    ORDER BY pricingDate DESC
) mc
JOIN (
	SELECT top 1 fd.dataItemValue AS dataItemValue , c.companyId
	FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
	join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
	join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
	join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
	join ciqDataItem di on di.dataItemId = fd.dataItemId
	WHERE 1=1
	and fd.dataItemId=300 -- sales
	AND fp.periodTypeId = 2 --Q
	AND fp.latestPeriodFlag=1
	AND c.companyId=@companyId
	ORDER BY fp.periodEndDate desc
) fp ON mc.companyId = fp.companyId



 INSERT INTO #lowEVSalesRatio (tickerSymbol,enterpriseValueSalesRatio,asOfDate)
  VALUES (@tickerSymbol, @enterpriseValueSalesRatio,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

---------------strategy for sorting--------------------

--select * into [QIAR_TEST].[dbo].[snLowEVSalesRatio] from #lowEVSalesRatio

select * from [QIAR_TEST].[dbo].[snLowEVSalesRatio]

--drop table [QIAR_TEST].[dbo].[snLowEVSalesRatio]

select * from #lowEVSalesRatio

-------------Ranking By strategy------------
SELECT tickerSymbol, enterpriseValueSalesRatio,averageEvSalesRatio,
       RANK() OVER (ORDER BY enterpriseValueSalesRatio ASC) AS rank
FROM [QIAR_TEST].[dbo].[snLowEVSalesRatio] where enterpriseValueSalesRatio is not null
ORDER BY enterpriseValueSalesRatio ASC;

---------------Ranking with Normalised Data-----------
;WITH Normalized AS (
    SELECT tickerSymbol,enterpriseValueSalesRatio,
           (enterpriseValueSalesRatio - MIN(enterpriseValueSalesRatio) OVER ()) / (MAX(enterpriseValueSalesRatio) OVER () - MIN(enterpriseValueSalesRatio) OVER ()) AS normalizedEV
    FROM [QIAR_TEST].[dbo].[snLowEVSalesRatio]
), SumNormalized AS (
    SELECT tickerSymbol,enterpriseValueSalesRatio, normalizedEV  AS sumNormalized
    FROM Normalized
)
SELECT tickerSymbol,enterpriseValueSalesRatio, sumNormalized,
       RANK() OVER (ORDER BY sumNormalized ASC) AS rank
FROM SumNormalized where enterpriseValueSalesRatio is not null
ORDER BY sumNormalized ASC;

--------------Ranking Individually and Adding Together------------
WITH Ranked AS (
    SELECT tickerSymbol,enterpriseValueSalesRatio,averageEvSalesRatio,
           RANK() OVER (ORDER BY enterpriseValueSalesRatio ASC) AS rankEV,
           RANK() OVER (ORDER BY averageEvSalesRatio ASC) AS rankAvgEV
    FROM [QIAR_TEST].[dbo].[snLowEVSalesRatio] where enterpriseValueSalesRatio is not null
)
SELECT tickerSymbol,enterpriseValueSalesRatio,averageEvSalesRatio, rankEV + rankAvgEV AS sumRanks
FROM Ranked
ORDER BY sumRanks ASC;





