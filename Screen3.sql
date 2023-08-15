----------------(3)---------------Deep Value Stocks Strategy--------------------------------------------------

DECLARE @companyId INT, @tickerSymbol VARCHAR(50), @tradingItemID INT;
DECLARE @earningYields DECIMAL(18, 2), @dividendYield DECIMAL(18, 2), @leverageRatio DECIMAL(18, 2);
DECLARE @marketCap DECIMAL(18, 2), @peRatio DECIMAL(18, 2), @revenueGrowth DECIMAL(18, 2);
DECLARE @Counter INT
DECLARE @TotalRows INT

IF OBJECT_ID('tempdb..#deepStocks') IS NOT NULL DROP TABLE #deepStocks;
CREATE TABLE #deepStocks (
    tickerSymbol VARCHAR(50),
    earningYields DECIMAL(18, 2),
    dividendYield DECIMAL(18, 2),
    leverageRatio DECIMAL(18, 2),
    marketCap DECIMAL(18, 2),
    peRatio DECIMAL(18, 2),
    revenueGrowth DECIMAL(18, 2),
	asOfDate DATE
);

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
 -- Initialize the variables for each iteration
Set @earningYields=null
Set @dividendYield=null
Set @leverageRatio=null
Set @peRatio=null
Set @marketCap=null
Set @revenueGrowth=null

    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol,
		@tradingItemID = tradingItemID
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY companyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter

 ----------- Calculate earningYields for the current companyId---------
    SELECT TOP 1 @earningYields = (d.dataItemValue / d2.dataItemValue) / (SELECT TOP 1 priceClose FROM ciqPriceEquity WHERE tradingItemId = @tradingItemID ORDER BY pricingDate DESC)
    FROM [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] f
    JOIN [Xpressfeed].[dbo].[ciqFinancialData] d ON f.financialPeriodId = d.financialPeriodId
    JOIN [Xpressfeed].[dbo].[ciqFinancialData] d2 ON f.financialPeriodId = d2.financialPeriodId
    WHERE f.companyId = @companyId
      AND d.dataItemId = 15 -- NetIncome
      AND d2.dataItemId = 1070 -- Common outstanding shares
      AND f.financialPeriodId = (SELECT TOP 1 financialPeriodId FROM [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] 
	  WHERE companyId = @companyId
	  AND periodTypeId = 2
	  and latestperiodflag = 1 ORDER BY periodEndDate DESC)
	    


    -- Calculate dividendYield for the current companyId
    SELECT TOP 1 @dividendYield = (ch.dataItemValue / er1.priceclose) / (pe.priceClose / er.priceclose) * 100
    FROM [Xpressfeed].[dbo].[ciqIADividendChain] ch
    JOIN [Xpressfeed].[dbo].[ciqPriceEquity] pe ON pe.tradingItemId = ch.tradingItemId
    JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON ti.tradingItemId = pe.tradingItemId
    JOIN [Xpressfeed].[dbo].[ciqExchangeRate] er ON er.currencyId = ti.currencyId
        AND er.priceDate = pe.pricingDate
    JOIN [Xpressfeed].[dbo].[ciqCurrency] cu ON cu.currencyId = er.currencyId
    JOIN [Xpressfeed].[dbo].[ciqExchangeRate] er1 ON er1.currencyId = ch.currencyId
        AND er1.snapId = er.snapId
        AND er1.pricedate BETWEEN ch.startDate AND ISNULL(ch.endDate, GETUTCDATE())
        AND er1.pricedate = pe.pricingDate
    WHERE ch.companyId = @companyId and ti.tradingItemId=@tradingItemID
    ORDER BY pe.pricingDate DESC;

SELECT  @leverageRatio=e.dataItemValue/e2.dataItemValue
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
AND e2.dataItemId=1275 -- total Equity


    -- Calculate marketCap for the current companyId
SELECT TOP 1 @marketCap = marketCap
FROM ciqMarketCap
WHERE companyId = @companyId
ORDER BY pricingDate DESC;

-- Calculate peRatio for the current companyId
select top 1 @peRatio=(pe.priceclose/fd.dataitemvalue) 
from ciqcompany c
left join ciqlatestinstancefinperiod lfp on lfp.companyid = c.companyid
left join ciqfinancialdata fd on fd.financialperiodid = lfp.financialperiodid 
left join ciqsecurity s on s.companyid = c.companyid and s.primaryflag =1 
left join ciqtradingitem ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join ciqpriceequity pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and lfp.periodtypeid = 2 -- Quarterly
and fd.dataitemid = 8 --EPS
and lfp.latestperiodflag = 1
and c.companyid=@companyId
order by pe.pricingDate desc , lfp.calendarYear desc

	----------------revenue growth---------
SELECT @revenueGrowth= fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=4194  -- Total Revenues, 1 Yr. Growth %
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

    -- Insert the calculated values into #deepStocks
INSERT INTO #deepStocks (tickerSymbol, earningYields, dividendYield, leverageRatio, marketCap, peRatio, revenueGrowth,asOfDate)
VALUES (@tickerSymbol, @earningYields, @dividendYield, @leverageRatio, @marketCap, @peRatio, @revenueGrowth,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

SELECT * FROM #deepStocks;

--select * into [QIAR_TEST].[dbo].[snDeepStocks] from #deepStocks

--drop table [QIAR_TEST].[dbo].[snDeepStocks]


----------------Sorting Strategy------------
SELECT *
FROM [QIAR_TEST].[dbo].[snDeepStocks]
WHERE earningYields > (SELECT AVG(earningYields) FROM [QIAR_TEST].[dbo].[snDeepStocks]) -- Above average earning yields
AND dividendYield > (SELECT AVG(dividendYield) FROM [QIAR_TEST].[dbo].[snDeepStocks]) -- Above average dividend yield
AND leverageRatio < (SELECT AVG(leverageRatio) FROM [QIAR_TEST].[dbo].[snDeepStocks]) AND leverageRatio > 0 -- Below average leverage ratio
ORDER BY (earningYields + dividendYield -leverageRatio ) DESC, leverageRatio ASC;

SELECT *,
       RANK() OVER (ORDER BY earningYields DESC, dividendYield DESC, leverageRatio ASC) AS Rank
FROM [QIAR_TEST].[dbo].[snDeepStocks]
ORDER BY Rank;


-------------------Ranking 1: Normalize the data and then Rank----------------

WITH Normalized AS (
    SELECT*,
        (earningYields - MIN(earningYields) OVER ()) / (MAX(earningYields) OVER () - MIN(earningYields) OVER ()) AS normalizedEarningYields,
        (dividendYield - MIN(dividendYield) OVER ()) / (MAX(dividendYield) OVER () - MIN(dividendYield) OVER ()) AS normalizedDividendYield,
        (leverageRatio - MIN(leverageRatio) OVER ()) / (MAX(leverageRatio) OVER () - MIN(leverageRatio) OVER ()) AS normalizedLeverageRatio,
        (marketCap - MIN(marketCap) OVER ()) / (MAX(marketCap) OVER () - MIN(marketCap) OVER ()) AS normalizedMarketCap,
        (peRatio - MIN(peRatio) OVER ()) / (MAX(peRatio) OVER () - MIN(peRatio) OVER ()) AS normalizedPeRatio,
        (revenueGrowth - MIN(revenueGrowth) OVER ()) / (MAX(revenueGrowth) OVER () - MIN(revenueGrowth) OVER ()) AS normalizedRevenueGrowth
    FROM
        [QIAR_TEST].[dbo].[snDeepStocks]
)SELECT *,
    normalizedEarningYields + normalizedDividendYield - normalizedLeverageRatio + normalizedMarketCap - normalizedPeRatio + normalizedRevenueGrowth AS combinedNormalizedValues,
    RANK() OVER (ORDER BY normalizedEarningYields + normalizedDividendYield - normalizedLeverageRatio + normalizedMarketCap - normalizedPeRatio + normalizedRevenueGrowth DESC) AS rank
FROM Normalized;




------------------Rank Individually and Add Rank------------------------
WITH Ranks AS (
    SELECT
        *,
        RANK() OVER (ORDER BY earningYields DESC) AS rankEarningYields,
        RANK() OVER (ORDER BY dividendYield DESC) AS rankDividendYield,
        RANK() OVER (ORDER BY leverageRatio ASC) AS rankLeverageRatio,
        RANK() OVER (ORDER BY marketCap DESC) AS rankMarketCap,
        RANK() OVER (ORDER BY peRatio ASC) AS rankPeRatio,
        RANK() OVER (ORDER BY revenueGrowth DESC) AS rankRevenueGrowth
    FROM
        [QIAR_TEST].[dbo].[snDeepStocks]
)
SELECT
    *,
    rankEarningYields + rankDividendYield + rankLeverageRatio + rankMarketCap + rankPeRatio + rankRevenueGrowth AS sumRanks,
    RANK() OVER (ORDER BY rankEarningYields + rankDividendYield + rankLeverageRatio + rankMarketCap + rankPeRatio + rankRevenueGrowth ASC) AS finalRank
FROM
    Ranks;




