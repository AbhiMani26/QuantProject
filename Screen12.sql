----------------------(12) High ROE & Consisent EPS Growth---------------------------


DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @CompanyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @returnOnEquity FLOAT
DECLARE @epsgrowth FLOAT
DECLARE @earningQuality FLOAT
Declare @shortInterest FLOAT

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#highROEAndEPSGrowth') IS NOT NULL DROP TABLE #highROEAndEPSGrowth;
CREATE TABLE #highROEAndEPSGrowth (
    tickerSymbol VARCHAR(255),
    returnOnEquity FLOAT,
    epsgrowth  FLOAT,
	earningQuality FLOAT,
	shortInterest FLOAT,
	asOfDate DATE
)

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
	SET @returnOnEquity = null
	SET @epsgrowth = null
	SET @earningQuality = null
	SET @shortInterest = null

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



SELECT top 1 @returnOnEquity=fd.dataItemValue/fd2.dataItemId ,@epsgrowth=fd3.dataItemValue, @earningQuality=(fd4.dataItemValue-fd.dataItemValue)/fd6.dataItemvalue,
@shortInterest= fd5.dataItemValue
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd2 on fd2.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd3 on fd3.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd4 on fd4.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd5 on fd5.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd6 on fd6.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =15 --Net Income
and fd2.dataItemId=48859 -- shareholder equity
and fd3.dataItemId=4385 -- 3 year EPS growth %
and fd4.dataItemId=2006 -- Cash Flow from Operation Used as Earning Quality Metrics
and fd5.dataItemId=100104 -- Last Close Short Interest (if high then more stocks are being shorted)
AND fd6.dataItemId = 1007 --Total Assets
AND fp.periodTypeId = 2 --Q
AND c.companyId=@companyId
And fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

 INSERT INTO #highROEAndEPSGrowth (tickerSymbol, returnOnEquity,epsgrowth, earningQuality,shortInterest,asOfDate)
  VALUES (@tickerSymbol, @returnOnEquity,@epsgrowth, @earningQuality,@shortInterest,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

select* from [QIAR_TEST].[dbo].[snHighROEAndEPSGrowth] 

--select * into [QIAR_TEST].[dbo].[snHighROEAndEPSGrowth] from #highROEAndEPSGrowth

-- drop table [QIAR_TEST].[dbo].[snHighROEAndEPSGrowth]



--------------------------------final strategy to be applied for (12)------------------------------
;WITH normalized AS (
    SELECT 
        tickerSymbol,
        (returnOnEquity - MIN(returnOnEquity) OVER ()) / (MAX(returnOnEquity) OVER () - MIN(returnOnEquity) OVER ()) AS normalizedROE,
        (epsgrowth - MIN(epsgrowth) OVER ()) / (MAX(epsgrowth) OVER () - MIN(epsgrowth) OVER ()) AS normalizedEPSGrowth,
        (earningQuality - MIN(earningQuality) OVER ()) / (MAX(earningQuality) OVER () - MIN(earningQuality) OVER ()) AS normalizedEQ,
        (shortInterest - MIN(shortInterest) OVER ()) / (MAX(shortInterest) OVER () - MIN(shortInterest) OVER ()) AS normalizedShortInterest
    FROM 
        [QIAR_TEST].[dbo].[snHighROEAndEPSGrowth]
),
scored AS (
    SELECT 
        tickerSymbol,
        (0.4 * normalizedROE) + (0.3 * normalizedEPSGrowth) + (0.2 * normalizedEQ) + (0.1 * (1 - normalizedShortInterest)) AS finalScore
    FROM 
        normalized
)
SELECT 
    h.*,
    s.finalScore
FROM 
    [QIAR_TEST].[dbo].[snHighROEAndEPSGrowth] h
JOIN 
    scored s ON h.tickerSymbol = s.tickerSymbol
ORDER BY 
    s.finalScore DESC;

----------Standardize and Rank------------
;WITH Standardized AS (
    SELECT *,
           (returnOnEquity - Min(returnOnEquity) OVER ()) / (Max(returnOnEquity) OVER () - Min(returnOnEquity) OVER ()) AS Standardized_returnOnEquity,
           (epsgrowth - Min(epsgrowth) OVER ()) / (Max(epsgrowth) OVER () - Min(epsgrowth) OVER ()) AS Standardized_epsgrowth,
           (earningQuality - Min(earningQuality) OVER ()) / (Max(earningQuality) OVER () - Min(earningQuality) OVER ()) AS Standardized_earningQuality,
           (shortInterest - Min(shortInterest) OVER ()) / (Max(shortInterest) OVER () - Min(shortInterest) OVER ()) AS Standardized_shortInterest
    FROM [QIAR_TEST].[dbo].[snHighROEAndEPSGrowth]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_returnOnEquity + Standardized_epsgrowth + Standardized_earningQuality - Standardized_shortInterest) DESC) AS Rank
FROM Standardized
ORDER BY Rank;

-----------------Rank Individually--------------
;WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY returnOnEquity DESC) as rank_returnOnEquity,
           RANK() OVER (ORDER BY epsgrowth DESC) as rank_epsgrowth,
           RANK() OVER (ORDER BY earningQuality DESC) as rank_earningQuality,
           RANK() OVER (ORDER BY shortInterest ASC) as rank_shortInterest
    FROM [QIAR_TEST].[dbo].[snHighROEAndEPSGrowth]
)
SELECT *,
       RANK() OVER (ORDER BY (rank_returnOnEquity + rank_epsgrowth + rank_earningQuality + rank_shortInterest) ASC) AS Total_Rank
FROM Ranked
ORDER BY Total_Rank;


