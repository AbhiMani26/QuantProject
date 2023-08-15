----------------(23) High ICE and Cash Usage---------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
declare @ROTA Float
declare @netIncome Float
declare @totalAsset Float
declare @intangibleAsset Float
-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#highROTA') IS NOT NULL DROP TABLE #highROTA;
CREATE TABLE #highROTA (
    tickerSymbol VARCHAR(255),
	ROTA Float,
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
	set @ROTA = null
	set @netIncome=null
	set @intangibleAsset = null
	set @totalAsset = null


    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY companyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter


SELECT top 1 @netIncome = fd.dataItemValue , @totalAsset = fd6.dataItemValue
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd6 on fd6.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =15 --Net Income
AND fd6.dataItemId = 1007 --Total Assets
AND fp.periodTypeId = 2 --Q
And fp.latestPeriodFlag=1
AND c.companyId=@companyId order by periodEndDate desc

SELECT top 1 @intangibleAsset = fd4.dataItemValue
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd4 on fd4.financialPeriodId=fp.financialPeriodId
WHERE 1=1
and fd4.dataItemId=3089 -- Goodwill and Intangible asset
AND fp.periodTypeId = 2 --Q
and fp.latestPeriodFlag=1
AND c.companyId=@companyId order by periodEndDate desc

set @ROTA = @netIncome/(@totalAsset- @intangibleAsset)

	INSERT INTO #highROTA (tickerSymbol,ROTA,asOfDate)
  VALUES (@tickerSymbol,@ROTA,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

--select * from [QIAR_TEST].[dbo].[snhighROTA] 

--select * into [QIAR_TEST].[dbo].[snhighROTA]  from #highROTA

--drop table [QIAR_TEST].[dbo].[snhighROTA] 

select * from #highROTA where ROTA is not null order by ROTA desc



;WITH Standardized AS (
    SELECT *,
           (ROTA - Min(ROTA) OVER ()) / (Max(ROTA) OVER () - Min(ROTA) OVER ()) AS Standardized_ROTA
    FROM [QIAR_TEST].[dbo].[snhighROTA] 
)
SELECT *,
       RANK() OVER (ORDER BY (ROTA) DESC) AS Rank
FROM Standardized
ORDER BY Rank;