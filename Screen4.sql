------------(4) Unloved Stocks with Favorable Signals--------------------------------

DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @tradingItemId INT
DECLARE @epsgrowth FLOAT 
DECLARE @stockUpside FLOAT
DECLARE @earningQuality FLOAT
DECLARE @numberOfCeoChanges FLOAT
DECLARE @shortInterest FLOAT
Declare @buyRating Float

--Create a temporary table to store the results

IF OBJECT_ID('tempdb..#unlovedStocks') IS NOT NULL DROP TABLE #unlovedStocks;
CREATE TABLE #unlovedStocks (
    tickerSymbol VARCHAR(255),
    epsgrowth FLOAT,
	stockUpside FLOAT,
	earningQuality FLOAT,
	numberOfCeoChanges INT,
	shortInterest FLOAT,
	buyRating FLOAT,
	asOfDate Date

)

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
	SET @epsgrowth =null 
	SET @stockUpside=null
	SET @earningQuality =null
	SET @numberOfCeoChanges =null
	SET @shortInterest =null
	Set @buyRating=null
    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
		@tradingItemId = tradingItemID,
        @tickerSymbol = tickerSymbol
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY companyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter

	----------------------------last 12 Months Upside of a Stocks---------------------

;WITH LTMPrices AS (
    SELECT TOP 252 pe.pricingDate, pe.priceClose
    FROM [Xpressfeed].[dbo].[ciqCompany] c
    JOIN [Xpressfeed].[dbo].[ciqSecurity] s ON c.companyId = s.companyId
    JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON s.securityId = ti.securityId
    JOIN [Xpressfeed].[dbo].[ciqPriceEquity] pe ON ti.tradingItemId = pe.tradingItemId
    WHERE c.companyId = @companyId
        AND ti.tickerSymbol = @tickerSymbol
        AND pe.tradingItemId = @tradingItemId
    ORDER BY pe.pricingDate DESC
),
LTMData AS (
    SELECT 
        MIN(LTMPrices.pricingDate) AS StartDate,
        MIN(LTMPrices.priceClose) AS StartPrice,
        MAX(LTMPrices.priceClose) AS MaxPrice
    FROM LTMPrices
)
SELECT 
    
    @stockUpside=(LTMData.MaxPrice / LTMData.StartPrice) - 1
FROM LTMData;



-------------------------Number of Ceo changes since 2000--------------------
SELECT @numberOfCeoChanges = COUNT(*)
FROM [Xpressfeed].[dbo].[ciqProfessional] p
JOIN [Xpressfeed].[dbo].[ciqProToProFunction] pf ON p.proId = pf.proId
WHERE p.companyId = @companyId
  AND pf.proFunctionId IN (1, 3, 8, 9)
  AND pf.startYear >= YEAR(GETDATE()) - 2;



---------------eps growth,earning Quality and shortInterest---------------
SELECT top 1 @epsgrowth=fd3.dataItemValue ,@shortInterest=fd5.dataItemValue , @earningQuality= (fd4.dataItemValue - fd.dataItemValue )/fd6.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd3 on fd3.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd4 on fd4.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd5 on fd5.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd6 on fd6.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE fd.dataItemId =15 --Net Income
and fd3.dataItemId=4385 -- 3 year EPS growth %
and fd4.dataItemId=2006 -- Cash Flow from Operation Accrual = (NetIncome - OperatingCashFlow) 
and fd5.dataItemId=100104 -- Last Close Short Interest (if high then more stocks are bein shorted)
AND fd6.dataItemId = 1007 --Total Assets
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

select top 1 @buyRating= nd.dataitemvalue 
from [Xpressfeed].[dbo].[ciqcompany] c
left join [Xpressfeed].[dbo].[ciqestimateperiod] ep on ep.companyid = c.companyid
left join [Xpressfeed].[dbo].[ciqEstimateperiodrelconst] epr on epr.estimateperiodid = ep.estimateperiodid and epr.periodtypeid = ep.periodtypeid
left join [Xpressfeed].[dbo].[ciqEstimateConsensus] ec on ec.estimateperiodid = ep.estimateperiodid
left join [Xpressfeed].[dbo].[ciqEstimateNumericData] nd on nd.estimateconsensusid = ec.estimateconsensusid --(financial forecasting measures in ciqEstimateNumericData)
left join [Xpressfeed].[dbo].[ciqsecurity] s on s.companyid = c.companyid and s.primaryflag =1 
left join [Xpressfeed].[dbo].[ciqtradingitem] ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join [Xpressfeed].[dbo].[ciqpriceequity] pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and nd.dataitemid = 100313 --# of Analysts Buy Recommendation - (In-Consensus)
and nd.todate > '1-JAN-2079' 
and c.companyid=@companyId
order by pe.pricingdate desc

 INSERT INTO #unlovedStocks (tickerSymbol,epsgrowth,stockUpside ,earningQuality,numberOfCeoChanges,shortInterest,buyRating,asOfDate)
  VALUES (@tickerSymbol, @epsgrowth,@stockUpside ,@earningQuality,@numberOfCeoChanges,@shortInterest,@buyRating,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END
SELECT *
FROM #unlovedStocks
ORDER BY  stockUpside DESC, numberOfCeoChanges ASC, earningQuality DESC, epsgrowth DESC, shortInterest ASC

--select * into [QIAR_TEST].[dbo].[snUnlovedStocks] from #unlovedStocks

-- drop table [QIAR_TEST].[dbo].[snUnlovedStocks]

select * from #unlovedStocks

---------------Ranking Stock Selection Strategy--------------
SELECT *
FROM [QIAR_TEST].[dbo].[snUnlovedStocks]
WHERE (epsgrowth > 0) -- Positive EPS growth
AND (stockUpside > 0) -- Positive stock upside
AND (earningQuality > 0) -- Positive earning quality
AND (shortInterest < (SELECT AVG(shortInterest) FROM [QIAR_TEST].[dbo].[snUnlovedStocks])) -- Below average short interest
AND (buyRating <= 4) -- Less than or equal to 40% buy ratings
AND numberOfCeoChanges >= 2
ORDER BY epsgrowth DESC, stockUpside DESC, earningQuality DESC, numberOfCeoChanges ASC, shortInterest ASC;


-------------------Ranking 1: Normalize the data and then Rank----------------

WITH Normalized AS (
    SELECT *,
           (epsgrowth - MIN(epsgrowth) OVER ()) / (MAX(epsgrowth) OVER () - MIN(epsgrowth) OVER ()) AS Normalized_epsgrowth,
           (stockUpside - MIN(stockUpside) OVER ()) / (MAX(stockUpside) OVER () - MIN(stockUpside) OVER ()) AS Normalized_stockUpside,
           (earningQuality - MIN(earningQuality) OVER ()) / (MAX(earningQuality) OVER () - MIN(earningQuality) OVER ()) AS Normalized_earningQuality,
           (numberOfCeoChanges - MIN(numberOfCeoChanges) OVER ()) / (MAX(numberOfCeoChanges) OVER () - MIN(numberOfCeoChanges) OVER ()) AS Normalized_numberOfCeoChanges,
           (shortInterest - MIN(shortInterest) OVER ()) / (MAX(shortInterest) OVER () - MIN(shortInterest) OVER ()) AS Normalized_shortInterest,
           (buyRating - MIN(buyRating) OVER ()) / (MAX(buyRating) OVER () - MIN(buyRating) OVER ()) AS Normalized_buyRating
    FROM [QIAR_TEST].[dbo].[snUnlovedStocks]
)
SELECT *,
       Normalized_epsgrowth + Normalized_stockUpside + Normalized_earningQuality + Normalized_numberOfCeoChanges - Normalized_shortInterest + Normalized_buyRating AS CombinedNormalizedValues,
       RANK() OVER (ORDER BY (Normalized_epsgrowth + Normalized_stockUpside + Normalized_earningQuality + Normalized_numberOfCeoChanges - Normalized_shortInterest + Normalized_buyRating) DESC) AS Rank
FROM Normalized
ORDER BY Rank;


------------------Rank Individually and Add Rank------------------------
;WITH Ranks AS (
    SELECT
        tickerSymbol,epsgrowth,stockUpside ,earningQuality,numberOfCeoChanges,shortInterest,buyRating,
        RANK() OVER (ORDER BY epsgrowth DESC) AS rankEpsgrowth,
        RANK() OVER (ORDER BY stockUpside DESC) AS rankStockUpside,
        RANK() OVER (ORDER BY earningQuality DESC) AS rankEarningQuality,
        RANK() OVER (ORDER BY numberOfCeoChanges DESC) AS rankNumberOfCeoChanges,
        RANK() OVER (ORDER BY shortInterest ASC) AS rankShortInterest,
        RANK() OVER (ORDER BY buyRating DESC) AS rankBuyRating,
        asOfDate
    FROM
        [QIAR_TEST].[dbo].[snUnlovedStocks]
)
SELECT
    tickerSymbol,epsgrowth,stockUpside ,earningQuality,numberOfCeoChanges,shortInterest,buyRating,
    rankEpsgrowth + rankStockUpside + rankEarningQuality + rankNumberOfCeoChanges + rankShortInterest + rankBuyRating AS sumRanks,
    asOfDate,
    RANK() OVER (ORDER BY rankEpsgrowth + rankStockUpside + rankEarningQuality + rankNumberOfCeoChanges + rankShortInterest + rankBuyRating ASC) AS finalRank
FROM
    Ranks;


