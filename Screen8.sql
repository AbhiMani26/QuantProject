--------------------------------(8) Cheap EV/Cyllically Adjusted EBITDA----------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @CompanyId INT
DECLARE @tickerSymbol VARCHAR(255)
Declare @tradingItemID int
DECLARE @EBITDA_10Y_AVG FLOAT
DECLARE @TEV FLOAT

select * from [QIAR_TEST].[dbo].[snCrossSectionalUniverseCoverage] where descriptor like '%ceo%'

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;
CREATE TABLE #Results (
    tickerSymbol VARCHAR(255),
    EBITDA_10Y_AVG FLOAT,
    TEV FLOAT,
	asOfDate DATE
)

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
	SET @EBITDA_10Y_AVG = null
	SET @TEV = null
    -- Get the values for each iteration
    SELECT
        @CompanyId = CompanyId,
        @tickerSymbol = tickerSymbol,
		@tradingItemID = tradingItemID
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY CompanyID) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter

    -- Calculate EBITDA for the company
	IF OBJECT_ID('tempdb..#1') IS NOT NULL
  DROP TABLE #1;

SELECT @EBITDA_10Y_AVG= AVG(fd.dataItemValue)
FROM ciqCompany c 
JOIN ciqSecurity s ON c.companyId = s.companyId AND s.primaryFlag=1
JOIN ciqLatestInstanceFinPeriod fp ON fp.companyId = c.companyId
JOIN ciqPeriodType pt ON pt.periodTypeId = fp.periodTypeId
JOIN ciqFinancialData fd ON fd.financialPeriodId=fp.financialPeriodId
JOIN ciqDataItem di ON di.dataItemId = fd.dataItemId
WHERE 1=1
AND fd.dataItemId=4051 -- EBITDA
AND fp.periodTypeId = 1 --Annual
AND c.companyId=@CompanyId
AND fp.calendarYear >= YEAR(GETDATE()) - 10

----TEV for company-----------
select top 1 @TEV= m.TEV
from ciqMarketCap m where companyId=@companyId order by pricingDate desc

---- Insert the result into the temporary table-------
INSERT INTO #Results ( tickerSymbol, EBITDA_10Y_AVG, TEV,asOfDate)
 VALUES ( @tickerSymbol, @EBITDA_10Y_AVG, @TEV,GETDATE())

    -- Increment the counter
    SET @Counter = @Counter + 1
END

-------------Ranking Based on Strategy Suggestion---------------
SELECT *,
       RANK() OVER (ORDER BY (TEV / NULLIF(EBITDA_10Y_AVG, 0)) ASC) AS Rank
FROM [QIAR_TEST].[dbo].[snCheapCyllicallyAdjustedEBITDA] where TEV is not null and EBITDA_10Y_AVG is not null
ORDER BY Rank;

------------Ranking 2: Standardize each column, Add and rank----------
WITH Standardized AS (
    SELECT *,
           (TEV - Min(TEV) OVER ()) / (Max(TEV) OVER ()) AS Standardized_TEV,
           (EBITDA_10Y_AVG - Min(EBITDA_10Y_AVG) OVER ()) / (Max(EBITDA_10Y_AVG) OVER ()) AS Standardized_EBITDA_10Y_AVG
    FROM [QIAR_TEST].[dbo].[snCheapCyllicallyAdjustedEBITDA] where TEV is not null and EBITDA_10Y_AVG is not null
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_TEV + Standardized_EBITDA_10Y_AVG) DESC) AS Rank
FROM Standardized
ORDER BY Rank;

----------Ranking 3: rank them Individually and Add-------
WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY TEV DESC) AS Rank_TEV,
           RANK() OVER (ORDER BY EBITDA_10Y_AVG DESC) AS Rank_EBITDA_10Y_AVG
    FROM [QIAR_TEST].[dbo].[snCheapCyllicallyAdjustedEBITDA]
)
SELECT *,
       RANK() OVER (ORDER BY (Rank_TEV + Rank_EBITDA_10Y_AVG) ASC) AS Rank
FROM Ranked
ORDER BY Rank;



--select * into [QIAR_TEST].[dbo].[snCheapCyllicallyAdjustedEBITDA] from #Results

--drop table [QIAR_TEST].[dbo].[snCheapCyllicallyAdjustedEBITDA]

