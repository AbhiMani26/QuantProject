-----------------------------(5) High Net Cash Stocks---------------------------------------

DECLARE @counter INT;
DECLARE @rowCount INT;
DECLARE @companyId INT;
DECLARE @tickerSymbol VARCHAR(50);
DECLARE @totalDebt Float;
DECLARE @cashAndCashEquivalent FLoat;
Declare @shortTermInvestment Float
Declare @netCash Float
Declare @marketCap Float

IF OBJECT_ID('tempdb..#highCashStocks') IS NOT NULL
    DROP TABLE #highCashStocks;

CREATE TABLE #highCashStocks (
    tickerSymbol VARCHAR(50),
    totalDebt Float,
    cashAndCashEquivalent Float,
	shortTermInvestment Float,
	netCash Float,
	marketCap Float,
	asOfDate DATE
);



SELECT @counter = 1, @rowCount = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents];

WHILE @counter <= @rowCount
BEGIN
    SELECT @companyId = companyId, @tickerSymbol = tickerSymbol
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY companyId) AS rownum, companyId, tickerSymbol
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS temp
    WHERE rownum = @counter;

	set @totalDebt = null
    set @cashAndCashEquivalent = null
	set @shortTermInvestment = null
	set @netCash = null
	set @marketCap = null


SELECT @totalDebt= e. dataItemValue
FROM ciqFinPeriod a
JOIN ciqFinInstance b ON a.financialPeriodId = b.financialPeriodId
JOIN ciqFinInstanceToCollection c ON b.financialInstanceId = c.financialInstanceId
JOIN ciqFinCollection d ON c.financialCollectionId = d.financialCollectionId
JOIN ciqFinCollectionData e ON d.financialCollectionId = e.financialCollectionId
JOIN ciqCompany f ON a.companyId = f.companyId
JOIN ciqDataItem g ON e.dataItemId = g.dataItemId
WHERE a.latestPeriodFlag = 1
AND a.periodTypeId = '2' --- Quarterly
AND a.companyId = @companyId
AND e.dataItemId=4173 --Total Debt

  SELECT TOP 1 @cashAndCashEquivalent= fd.dataItemValue , @shortTermInvestment=fd2.dataItemValue
  FROM [Xpressfeed].[dbo].[ciqCompany] c 
  JOIN [Xpressfeed].[dbo].[ciqSecurity] s ON c.companyId = s.companyId and s.primaryFlag=1
  JOIN [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp ON fp.companyId = c.companyId
  JOIN [Xpressfeed].[dbo].[ciqPeriodType] pt ON pt.periodTypeId = fp.periodTypeId
  JOIN [Xpressfeed].[dbo].[ciqFinancialData] fd ON fd.financialPeriodId=fp.financialPeriodId
  JOIN [Xpressfeed].[dbo].[ciqFinancialData] fd2 ON fd2.financialPeriodId=fp.financialPeriodId
  WHERE 1=1
    AND fd.dataItemId=1096 -- Cash And Equivalents
	AND fd2.dataItemId=1069 --Short Term Investments
    AND fp.periodTypeId = 2 --Q
    AND c.companyId=@companyId
	and fp.latestPeriodFlag=1
  ORDER BY fp.periodEndDate DESC

 set @netCash = @cashAndCashEquivalent + @shortTermInvestment - @totalDebt

  ----marketCap for company-----------
select top 1 @marketCap=m.marketCap from ciqMarketCap m where companyId=@companyId order by pricingDate desc


      INSERT INTO #highCashStocks (tickerSymbol, totalDebt, cashAndCashEquivalent, shortTermInvestment, netCash,marketCap,asOfDate)
	    VALUES (@tickerSymbol,@totalDebt, @cashAndCashEquivalent, @shortTermInvestment, @netCash,@marketCap,GETDATE());

    SET @counter = @counter + 1; 
END;

--select * from #highCashStocks  where netCash is not null and marketCap is not null order by netCash/marketCap desc


--drop table [QIAR_TEST].[dbo].[snHighCashStocks]

-- select * into [QIAR_TEST].[dbo].[snHighCashStocks] from #highCashStocks

select * from #highCashStocks

---------------stock rank selection as per strategy---------------------
SELECT *,
       RANK() OVER (ORDER BY netCash/marketCap DESC) AS rank
FROM [QIAR_TEST].[dbo].[snHighCashStocks]
WHERE netCash IS NOT NULL
  AND marketCap IS NOT NULL
ORDER BY netCash/marketCap DESC;

-----------------Ranking 2: Normalise and Rank--------------
;WITH Normalized AS (
    SELECT *,
           (netCash - MIN(netCash) OVER ()) / (MAX(netCash) OVER () - MIN(netCash) OVER ()) AS Normalized_NetCash,
           (marketCap - MIN(marketCap) OVER ()) / (MAX(marketCap) OVER () - MIN(marketCap) OVER ()) AS Normalized_MarketCap
    FROM [QIAR_TEST].[dbo].[snHighCashStocks]
)
SELECT *,
    Normalized_NetCash + Normalized_MarketCap AS CombinedNormalizedValues,
    RANK() OVER (ORDER BY (Normalized_NetCash + Normalized_MarketCap) DESC) AS NormalizedRank
FROM
    Normalized
ORDER BY
    NormalizedRank;
---------------Rank Individually------------------
;WITH IndividualRanks AS (
    SELECT *,
           RANK() OVER (ORDER BY netCash DESC) AS Rank_NetCash,
           RANK() OVER (ORDER BY marketCap DESC) AS Rank_MarketCap
    FROM [QIAR_TEST].[dbo].[snHighCashStocks]
)
SELECT *,
    Rank_NetCash + Rank_MarketCap AS CombinedIndividualRanks,
    RANK() OVER (ORDER BY (Rank_NetCash + Rank_MarketCap) ASC) AS IndividualRanksRank
FROM
    IndividualRanks
ORDER BY
    IndividualRanksRank;

--select * into [QIAR_TEST].[dbo].[snHighCashStocks] from #highCashStocks

--select * from [QIAR_TEST].[dbo].[snHighCashStocks] 