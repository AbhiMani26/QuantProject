---------------------- (15) Buy Back Cash Usage-----------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @buyBackLast24Months FLOAT
DECLARE @periodEndDate datetime

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#buyBackCashUsage') IS NOT NULL DROP TABLE #buyBackCashUsage;
CREATE TABLE #buyBackCashUsage (
    tickerSymbol VARCHAR(255),
    buyBackLast24Months FLOAT,
	asOfDate DATE
)

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
	SET @buyBackLast24Months =null
    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY CompanyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter

SELECT top 8  @buyBackLast24Months= SUM(fd.dataItemValue)  
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =2164 --Repurchase of common stocks
AND fp.periodTypeId =2--Q
AND c.companyId=@companyId


 INSERT INTO #buyBackCashUsage (tickerSymbol,buyBackLast24Months,asOfDate)
  VALUES (@tickerSymbol,@buyBackLast24Months,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

select * from #buyBackCashUsage
select * from [QIAR_TEST].[dbo].[snBuyBackCashUsage]

--select * into [QIAR_TEST].[dbo].[snBuyBackCashUsage] from #buyBackCashUsage
-- drop table [QIAR_TEST].[dbo].[snBuyBackCashUsage]

----------Ranking---------
SELECT *,
       RANK() OVER (ORDER BY buyBackLast24Months Desc) AS Rank
FROM [QIAR_TEST].[dbo].[snBuyBackCashUsage] where buyBackLast24Months is not null
ORDER BY Rank;


