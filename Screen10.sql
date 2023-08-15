----------------------------------------------------------------------(10)   Secular Growth-----------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @CompanyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @lt_CAGR FLOAT
DECLARE @lt_EPS_CAGR FLOAT
DECLARE @st_revenue_CAGR FLOAT

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#secularGrowth') IS NOT NULL DROP TABLE #secularGrowth;
CREATE TABLE #secularGrowth (
    tickerSymbol VARCHAR(255),
    lt_CAGR FLOAT,
    lt_EPS_CAGR FLOAT,
	st_revenue_CAGR FLOAT,
	asOfDate DATE
)

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
	SET @lt_CAGR = null
	SET @lt_EPS_CAGR = null
	SET @st_revenue_CAGR = null
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

SELECT @lt_CAGR=fd.dataItemValue , @lt_EPS_CAGR=fd2.dataItemValue , @st_revenue_CAGR=fd3.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd2 on fd2.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd3 on fd3.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=4251 --long term CAGR
and fd2.dataItemId=4387 -- long term EPS CAGR
and fd3.dataItemId=4207 -- short term revenue growth (CAGR)
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

	    -- Insert the results into the temporary table
  INSERT INTO #secularGrowth (tickerSymbol, lt_CAGR, lt_EPS_CAGR,st_revenue_CAGR,asOfDate)
  VALUES (@tickerSymbol, @lt_CAGR, @lt_EPS_CAGR,@st_revenue_CAGR,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

--strategy---
select * from [QIAR_TEST].[dbo].[snSecularGrowth] g where g.lt_CAGR > 10 and g.lt_CAGR > 15 and g.st_revenue_CAGR > 7


-------------Standardize and Rank---------------
;WITH Standardized AS (
    SELECT *,
           (lt_CAGR - Min(lt_CAGR) OVER ()) / (Max(lt_CAGR) OVER () - Min(lt_CAGR) OVER ()) AS Standardized_lt_CAGR,
           (lt_EPS_CAGR - Min(lt_EPS_CAGR) OVER ()) / (Max(lt_EPS_CAGR) OVER () - Min(lt_EPS_CAGR) OVER ()) AS Standardized_lt_EPS_CAGR,
           (st_revenue_CAGR - Min(st_revenue_CAGR) OVER ()) / (Max(st_revenue_CAGR) OVER () - Min(st_revenue_CAGR) OVER ()) AS Standardized_st_revenue_CAGR
    FROM [QIAR_TEST].[dbo].[snSecularGrowth]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_lt_CAGR + Standardized_lt_EPS_CAGR + Standardized_st_revenue_CAGR) DESC) AS Rank
FROM Standardized
ORDER BY Rank;

-------------Rank Individually and Add-----------

;WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY lt_CAGR DESC) as rank_lt_CAGR,
           RANK() OVER (ORDER BY lt_EPS_CAGR DESC) as rank_lt_EPS_CAGR,
           RANK() OVER (ORDER BY st_revenue_CAGR DESC) as rank_st_revenue_CAGR
    FROM [QIAR_TEST].[dbo].[snSecularGrowth]
)
SELECT *,
       RANK() OVER (ORDER BY (rank_lt_CAGR + rank_lt_EPS_CAGR + rank_st_revenue_CAGR) ASC) AS Total_Rank
FROM Ranked
ORDER BY Total_Rank;


--select * into [QIAR_TEST].[dbo].[snSecularGrowth] from #secularGrowth

-- drop table [QIAR_TEST].[dbo].[snSecularGrowth]


