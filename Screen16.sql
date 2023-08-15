-------------------------(16) Large Net Buyback with High FCFF Yld------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @CompanyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @freeCashFlow FLOAT
DECLARE @freeCFYield FLOAT
DECLARE @marketCap FLOAT
DECLARE @shareCountDecline INT

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#largeBuyBack') IS NOT NULL DROP TABLE #largeBuyBack;
CREATE TABLE #largeBuyBack (
    tickerSymbol VARCHAR(255),
	freeCFYield FLOAT,
	shareCountDecline INT,
	asOfDate DATE
)


-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
	SET @freeCashFlow =null
	SET @freeCFYield =null
	SET @shareCountDecline =null
    -- Get the values for each iteration
    SELECT
        @CompanyId = CompanyId,
        @tickerSymbol = tickerSymbol
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY CompanyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter



SELECT @freeCashFlow=fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag = 1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =4422 -- Free Cash Flow (Levered i.e after paying taxes and debt obligation)
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId =@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc


select top 1 @marketCap=m.marketCap from ciqMarketCap m where companyId=@companyId order by pricingDate desc

Set @freeCFYield = @freeCashFlow/@marketCap

SELECT TOP 1 @shareCountDecline=mc2.sharesOutstanding - mc1.sharesOutstanding ----to make positive values higher in rank
FROM (
    SELECT sharesOutstanding, ROW_NUMBER() OVER (ORDER BY pricingDate DESC) AS RowNum
    FROM [Xpressfeed].[dbo].[ciqMarketCap]
    WHERE companyId = @companyId
) mc1
JOIN (
    SELECT sharesOutstanding, ROW_NUMBER() OVER (ORDER BY pricingDate DESC) AS RowNum
    FROM [Xpressfeed].[dbo].[ciqMarketCap]
    WHERE companyId = @companyId AND pricingDate < DATEADD(YEAR, -1, GETDATE())
) mc2 ON mc1.RowNum = 1 AND mc2.RowNum = 1


 INSERT INTO #largeBuyBack (tickerSymbol, freeCFYield,shareCountDecline,asOfDate)
  VALUES (@tickerSymbol, @freeCFYield,@shareCountDecline,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

select * from #largeBuyBack
------------sorting strategy----------
select * from [QIAR_TEST].[dbo].[snLargeBuyBack] s where s.shareCountDecline is not null order by shareCountDecline asc, freeCFYield desc

--select * into [QIAR_TEST].[dbo].[snLargeBuyBack] from #largeBuyBack
-- drop table [QIAR_TEST].[dbo].[snLargeBuyBack]

----------------Ranking as per Strategy-----------
SELECT *,
       RANK() OVER (ORDER BY freeCFYield DESC, shareCountDecline DESC) AS Rank
FROM [QIAR_TEST].[dbo].[snLargeBuyBack]
ORDER BY Rank;

-----------Standardize and Rank-------------
WITH Standardized AS (
    SELECT *,
           (freeCFYield - Min(freeCFYield) OVER ()) / (Max(freeCFYield) OVER () - Min(freeCFYield) OVER ()) AS Standardized_freeCFYield,
           (shareCountDecline - Min(shareCountDecline) OVER ()) / (Max(shareCountDecline) OVER () - Min(shareCountDecline) OVER ()) AS Standardized_shareCountDecline
    FROM [QIAR_TEST].[dbo].[snLargeBuyBack]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_freeCFYield + Standardized_shareCountDecline) DESC) AS Rank
FROM Standardized
ORDER BY Rank;

-----------------Rank Individually-------------------

WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY freeCFYield DESC) as rank_freeCFYield,
           RANK() OVER (ORDER BY shareCountDecline DESC) as rank_shareCountDecline
    FROM [QIAR_TEST].[dbo].[snLargeBuyBack] where freeCFYield is not null and shareCountDecline is not null
)
SELECT *,
       RANK() OVER (ORDER BY (rank_freeCFYield + rank_shareCountDecline) ASC) AS Total_Rank
FROM Ranked
ORDER BY Total_Rank;

