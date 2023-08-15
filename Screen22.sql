---------------------(22) High ICE (Incremental Free Cash Flow ROE) --------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
Declare @marketCap Float
Declare @returnOnEquity Float
Declare @earningQuality Float
Declare @shortInterest Float
Declare @incrementalFreeCashFlow Float


-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#highIncrementalFCF') IS NOT NULL DROP TABLE #highIncrementalFCF;
CREATE TABLE #highIncrementalFCF (
    tickerSymbol VARCHAR(255),
	marketCap FLOAT,
	returnOnEquity Float,
	earningQuality Float,
	shortInterest Float,
	incrementalFreeCashFlow Float,
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
	SET @marketCap  = Null
	SET @returnOnEquity  = Null
	SET @earningQuality  = Null
	SET @shortInterest  = Null
	SET @incrementalFreeCashFlow  = Null
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

----marketCap for company-----------
select top 1 @marketCap=c.marketCap from ciqMarketCap c where c.companyId=@companyId order by pricingDate desc

----------------Return on Equity, Short Interest, Cash Flow from Operation(EQ)---------------
SELECT @returnOnEquity=fd.dataItemValue/fd2.dataItemValue , @earningQuality=(fd4.dataItemValue-fd.dataItemValue)/fd6.dataItemValue ,
@shortInterest=fd5.dataItemValue 
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId AND s.primaryFlag=1 and  GETDATE() BETWEEN s.securityStartDate AND ISNULL(s.securityEndDate, '2070-01-01')
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd2 on fd2.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd3 on fd3.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd4 on fd4.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd5 on fd5.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd6 on fd6.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqDataItem] di on di.dataItemId = fd.dataItemId
WHERE fd.dataItemId =15 --Net Income
and fd2.dataItemId=48859 -- shareholder equity
and fd3.dataItemId=4385 -- 3 year EPS growth %
and fd4.dataItemId=2006 -- Cash Flow from Operation Used in Earning Quality Metrics= (CF - Net Income)/Total Asset
and fd5.dataItemId=100104 -- Last Close Short Interest (if high then more stocks are bein shorted)
AND fd6.dataItemId = 1007 --Total Assets
AND fp.periodTypeId = 2 --Annual
AND fp.latestPeriodFlag=1
AND c.companyId=@companyId
ORDER BY fp.filingDate desc

;WITH CTE AS (
    SELECT
        e.dataItemValue AS freeCashFlow,
        LEAD(e.dataItemValue) OVER (ORDER BY b.periodEndDate DESC) AS nextFreeCashFlow
    FROM [Xpressfeed].[dbo].[ciqFinPeriod] a
    JOIN [Xpressfeed].[dbo].[ciqFinInstance] b ON a.financialPeriodId = b.financialPeriodId
    JOIN [Xpressfeed].[dbo].[ciqFinInstanceToCollection] c ON b.financialInstanceId = c.financialInstanceId
    JOIN [Xpressfeed].[dbo].[ciqFinCollection] d ON c.financialCollectionId = d.financialCollectionId
    JOIN [Xpressfeed].[dbo].[ciqFinCollectionData] e ON d.financialCollectionId = e.financialCollectionId
    JOIN [Xpressfeed].[dbo].[ciqCompany] f ON a.companyId = f.companyId
    JOIN [Xpressfeed].[dbo].[ciqDataItem] g ON e.dataItemId = g.dataItemId
    WHERE a.periodTypeId = 2 -- Q
	and b.latestForFinancialPeriodFlag=1
        AND a.companyId = @companyId
        AND g.dataItemId = 4422 -- Free Cash Flow (Levered)
)
SELECT top 1
    @incrementalFreeCashFlow = freeCashFlow - nextFreeCashFlow
FROM CTE;

INSERT INTO #highIncrementalFCF (tickerSymbol,marketCap,returnOnEquity,earningQuality,shortInterest,incrementalFreeCashFlow,asOfDate)
  VALUES (@tickerSymbol, @marketCap,@returnOnEquity,@earningQuality,@shortInterest,@incrementalFreeCashFlow,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

--select * from [QIAR_TEST].[dbo].[snHighIncrementalFCF]

--select * into [QIAR_TEST].[dbo].[snHighIncrementalFCF] from #highIncrementalFCF

-- drop table [QIAR_TEST].[dbo].[snHighIncrementalFCF] 
----------Standardize and Rank------------
;WITH Standardized AS (
    SELECT *,
           (marketCap - Min(marketCap) OVER ()) / (Max(marketCap) OVER () - Min(marketCap) OVER ()) AS Standardized_marketCap,
           (returnOnEquity - Min(returnOnEquity) OVER ()) / (Max(returnOnEquity) OVER () - Min(returnOnEquity) OVER ()) AS Standardized_returnOnEquity,
		   (earningQuality - Min(earningQuality) OVER ()) / (Max(earningQuality) OVER () - Min(earningQuality) OVER ()) AS Standardized_earningQuality,
           (shortInterest - Min(shortInterest) OVER ()) / (Max(shortInterest) OVER () - Min(shortInterest) OVER ()) AS Standardized_shortInterest,
           (incrementalFreeCashFlow - Min(incrementalFreeCashFlow) OVER ()) / (Max(incrementalFreeCashFlow) OVER () - Min(incrementalFreeCashFlow) OVER ()) AS Standardized_incrementalFreeCashFlow
    FROM [QIAR_TEST].[dbo].[snHighIncrementalFCF]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_marketCap + Standardized_returnOnEquity  + Standardized_earningQuality + Standardized_incrementalFreeCashFlow - Standardized_shortInterest) DESC) AS Rank
FROM Standardized
ORDER BY Rank;

------------Sorting Alorithm to select Stocks----------
DECLARE @EQ_Threshold float, @SI_Threshold float;

SELECT @EQ_Threshold = PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY earningQuality) OVER ()
FROM [QIAR_TEST].[dbo].[snHighIncrementalFCF]
WHERE earningQuality IS NOT NULL;
SELECT @SI_Threshold = PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY shortInterest) OVER ()
FROM [QIAR_TEST].[dbo].[snHighIncrementalFCF]
WHERE shortInterest IS NOT NULL;
SELECT *
FROM [QIAR_TEST].[dbo].[snHighIncrementalFCF]
WHERE marketCap/1000 > 1.5 -- Select only companies with market cap over $1.5 billion
AND earningQuality > @EQ_Threshold -- Use the EQ threshold computed above
AND shortInterest < @SI_Threshold -- Use the SI threshold computed above
AND returnOnEquity IS NOT NULL
AND earningQuality IS NOT NULL
AND shortInterest IS NOT NULL
AND freeCashFlow IS NOT NULL
ORDER BY returnOnEquity DESC; -- Order by Incremental Free Cash Flow ROE (the higher, the better)


