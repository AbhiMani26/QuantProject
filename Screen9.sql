-------------------------------(9) Low PBV and High Historical ROIC--------------------


DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @CompanyId INT
DECLARE @tradingItemID INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @PBV FLOAT
DECLARE @ROCE FLOAT

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#PbvRoic') IS NOT NULL DROP TABLE #PbvRoic;
CREATE TABLE #PbvRoic (
    tickerSymbol VARCHAR(255),
    PBV FLOAT,
    ROCE FLOAT,
	asOfDate DATE
)

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
	SET @PBV = null
	SET @ROCE = null
    -- Get the values for each iteration
    SELECT
        @CompanyId = CompanyId,
        @tickerSymbol = tickerSymbol,
		@tradingItemID = tradingItemID
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY CompanyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter

-----Calculate ROCE for the current company-------------
  SELECT @ROCE = fd.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=43905 -- ROCE
AND fp.periodTypeId = 2 --Q
AND fp.latestPeriodFlag=1
AND c.companyId=@CompanyId
ORDER BY fp.periodEndDate desc

SELECT TOP 1
   @PBV= (SELECT TOP 1 pe.priceClose
     FROM ciqCompany c
     JOIN ciqSecurity s ON c.companyId = s.companyId and s.primaryFlag=1
     JOIN ciqTradingItem ti ON s.securityId = ti.securityId
     JOIN ciqPriceEquity pe ON ti.tradingItemId = pe.tradingItemId
     WHERE c.companyId = @companyId
       AND ti.tickerSymbol = @tickerSymbol
       AND pe.tradingItemId = @tradingItemID
     ORDER BY pe.pricingDate DESC) / fcd.dataitemvalue
FROM ciqfinperiod fp
JOIN ciqFinInstance fi ON fp.financialPeriodId = fi.financialPeriodId
JOIN ciqFinInstanceToCollection fitc ON fi.financialInstanceId = fitc.financialInstanceId
JOIN ciqFinCollection fc ON fitc.financialCollectionId = fc.financialCollectionId
JOIN ciqFinCollectionData fcd ON fc.financialCollectionId = fcd.financialCollectionId
WHERE fp.companyId = @companyId
  AND fcd.dataitemId = 4020 -- BVPS
  AND fp.latestPeriodFlag = 1
  AND fp.periodTypeId = 2 --Quarterly
  AND fi.latestFilingForInstanceFlag = 1
ORDER BY fi.periodEndDate DESC

  -- Insert the results into the temporary table
  INSERT INTO #PbvRoic (tickerSymbol, ROCE, PBV,asOfDate)
  VALUES (@tickerSymbol, @ROCE, @PBV,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

-------Ranking As Per Strategy-------------
SELECT *,
       RANK() OVER (ORDER BY ROCE DESC, PBV ASC) AS Rank
FROM [QIAR_TEST].[dbo].[snPbvRoic]
WHERE ROCE > 9 AND PBV < 1.5
ORDER BY Rank;


--------Ranking 2: Standardize, Add and Rank-----------
WITH Standardized AS (
    SELECT *,
           (ROCE - Min(ROCE) OVER ()) / (Max(ROCE) OVER ()) AS Standardized_ROCE,
           (PBV - Min(PBV) OVER ()) / (Max(PBV) OVER ()) AS Standardized_PBV
    FROM [QIAR_TEST].[dbo].[snPbvRoic]
    WHERE ROCE is not null AND PBV is not null
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_ROCE - Standardized_PBV) DESC) AS Rank
FROM Standardized
ORDER BY Rank;

---------Ranking 3: Rank Individually and Add Ranks----------
WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY ROCE DESC) AS Rank_ROCE,
           RANK() OVER (ORDER BY PBV ASC) AS Rank_PBV
    FROM [QIAR_TEST].[dbo].[snPbvRoic]
    WHERE ROCE is not null AND PBV is not null
)
SELECT *,
       RANK() OVER (ORDER BY (Rank_ROCE + Rank_PBV) ASC) AS Rank
FROM Ranked
ORDER BY Rank;


--select * into [QIAR_TEST].[dbo].[snPbvRoic] from #PbvRoic

--drop table [QIAR_TEST].[dbo].[snPbvRoic]
