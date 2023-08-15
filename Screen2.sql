----------------------------(2) Nets Nets Strategy------------------------
IF OBJECT_ID ( 'tempdb..#stocks' ) IS NOT NULL DROP TABLE #stocks
-- Create the #stocks table
CREATE TABLE #stocks (
  tickerSymbol VARCHAR(50),
  marketCap Float,
  netCurrentAssest Float,
  debtEquityRatio Float,
  asOfDate DATE
);

-- Declare variables for looping
DECLARE @tickerSymbol VARCHAR(50);
DECLARE @companyId INT;

-- Create a cursor to iterate over the #snp500Consitutent table
DECLARE stockCursor CURSOR FOR
SELECT tickerSymbol, companyId
FROM [QIAR_TEST].[dbo].[snSnP500Consitutents];

-- Open the cursor
OPEN stockCursor;

-- Fetch the first row
FETCH NEXT FROM stockCursor INTO @tickerSymbol, @companyId;

-- Loop through the rows
WHILE @@FETCH_STATUS = 0
BEGIN

  DECLARE @marketCap DECIMAL(18, 2);
  DECLARE @netCurrentAssest DECIMAL(18, 2);
  SET @netCurrentAssest=null
  DECLARE @debtEquityRatio DECIMAL(18, 2);
  SET @debtEquityRatio=null

    --marketCap for the company----------
  SELECT TOP 1 @marketCap = marketCap
  FROM [Xpressfeed].[dbo].[ciqMarketCap]
  WHERE companyId = @companyId
  ORDER BY pricingDate DESC;

----netCurrentAssestValue for each stock------------
  SELECT  @netCurrentAssest=fd2.dataItemValue-fd.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd2 on fd2.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=1009 -- Total Current Liabilities
and fd2.dataItemId=1008 -- Total Current Assets
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

 ---- Fetch debtEquityRatio----------------

SELECT  @debtEquityRatio=e.dataItemValue/e2.dataItemValue
FROM ciqFinPeriod a
JOIN ciqFinInstance b ON a.financialPeriodId = b.financialPeriodId
JOIN ciqFinInstanceToCollection c ON b.financialInstanceId = c.financialInstanceId
JOIN ciqFinCollection d ON c.financialCollectionId = d.financialCollectionId
JOIN ciqFinCollectionData e ON d.financialCollectionId = e.financialCollectionId
JOIN ciqFinCollectionData e2 ON d.financialCollectionId = e2.financialCollectionId
JOIN ciqCompany f ON a.companyId = f.companyId
JOIN ciqDataItem g ON e.dataItemId = g.dataItemId
WHERE a.latestPeriodFlag = 1
AND a.periodTypeId = '2' --- Quarterly
AND a.companyId = @companyId
AND e.dataItemId=4173 --Total Debt
AND e2.dataItemId=1275 -- Total Equity

  -- Insert the data into the #stocks table
  INSERT INTO #stocks (tickerSymbol, marketCap, netCurrentAssest, debtEquityRatio,asOfDate)
  VALUES (@tickerSymbol, @marketCap, @netCurrentAssest, @debtEquityRatio,GETDATE());

  -- Fetch the next row
  FETCH NEXT FROM stockCursor INTO @tickerSymbol, @companyId;
END

-- Close and deallocate the cursor
CLOSE stockCursor;
DEALLOCATE stockCursor;

-------------Stock Selection---------
--SELECT * FROM [QIAR_TEST].[dbo].[snNetNets] WHERE netCurrentAssest > marketCap ORDER BY (netCurrentAssest - marketCap) DESC;

--select * into [QIAR_TEST].[dbo].[snNetNets] from #stocks

--drop table [QIAR_TEST].[dbo].[snNetNets]

select * from #stocks


-------------Ranking As Per Strategy--------------------
SELECT *,
       RANK() OVER (ORDER BY (netCurrentAssest / marketCap) DESC) AS Rank
FROM [QIAR_TEST].[dbo].[snNetNets] where marketCap is not null and netCurrentAssest is not null and debtEquityRatio is not null
ORDER BY Rank;

--------------Ranking 2: Normalization and Ranking----------------
WITH Normalized AS (
    SELECT *,
           (netCurrentAssest - MIN(netCurrentAssest) OVER ()) / (MAX(netCurrentAssest) OVER () - MIN(netCurrentAssest) OVER ()) AS Normalized_netCurrentAssest,
           (marketCap - MIN(marketCap) OVER ()) / (MAX(marketCap) OVER () - MIN(marketCap) OVER ()) AS Normalized_marketCap,
           (debtEquityRatio - MIN(debtEquityRatio) OVER ()) / (MAX(debtEquityRatio) OVER () - MIN(debtEquityRatio) OVER ()) AS Normalized_debtEquityRatio
    FROM [QIAR_TEST].[dbo].[snNetNets]
)
SELECT *,
       Normalized_netCurrentAssest + Normalized_marketCap - Normalized_debtEquityRatio AS CombinedNormalizedValues,
       RANK() OVER (ORDER BY (Normalized_netCurrentAssest + Normalized_marketCap - Normalized_debtEquityRatio) DESC) AS Rank
FROM Normalized
ORDER BY Rank;

-----------------Ranking separately and then adding the ranks------------
WITH Ranks AS (
    SELECT
        *,
        RANK() OVER (ORDER BY marketCap DESC) AS rankMarketCap,
        RANK() OVER (ORDER BY netCurrentAssest DESC) AS rankNetCurrentAssest,
        RANK() OVER (ORDER BY debtEquityRatio ASC) AS rankDebtEquityRatio
    FROM
        [QIAR_TEST].[dbo].[snNetNets] where marketCap is not null and netCurrentAssest is not null and debtEquityRatio is not null
)
SELECT
    *,
    rankMarketCap + rankNetCurrentAssest + rankDebtEquityRatio AS sumRanks,
    RANK() OVER (ORDER BY rankMarketCap + rankNetCurrentAssest + rankDebtEquityRatio ASC) AS finalRank
FROM
    Ranks;
