
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
Declare @tradingItemID INT
DECLARE @epsEstimatePreQ1 FLOAT
DECLARE @epsEstimatePreQ2 FLOAT
DECLARE @actualEPSPrevQ1 FLOAT
DECLARE @actualEPSPrevQ2 FLOAT
DECLARE @actualRevenuePrevQ1 FLOAT
DECLARE @actualRevenuePrevQ2 FLOAT
DECLARE @revenueEstimatePreQ1 FLOAT
DECLARE @revenueEstimatePreQ2 FLOAT
DECLARE @startPriceQ1 FLOAT
DECLARE @endPriceQ1 FLOAT
DECLARE @startPriceQ2 FLOAT
DECLARE @endPriceQ2 FLOAT
DECLARE @priceMovementQ2 FLOAT
DECLARE @priceMovementQ1 FLOAT
Declare @earningBeats Float
Declare @revenueBeats Float
Declare @priceMovement Float
Declare @filingDateEPSPQ1 Date
Declare @filingDateEPSPQ2 Date
Declare @filingDateEPSAQ1 Date
Declare @filingDateEPSAQ2 Date
Declare @filingDateRevAQ1 Date
Declare @filingDateRevAPQ2 Date
Declare @filingDateRevPQ1 Date
Declare @filingDateRevPQ2 Date
-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#doubleBeats') IS NOT NULL DROP TABLE #doubleBeats;
CREATE TABLE #doubleBeats (
    tickerSymbol VARCHAR(255),
	epsEstimatePreQ1 FLOAT,
	filingDateEPSPQ1 Date,
 epsEstimatePreQ2 FLOAT,
 filingDateEPSPQ2 Date,
 actualEPSPrevQ1 FLOAT,
 filingDateEPSAQ1 Date,
 actualEPSPrevQ2 FLOAT,
 filingDateEPSAQ2 Date,
 actualRevenuePrevQ1 FLOAT,
 filingDateRevAQ1 date,
 actualRevenuePrevQ2 FLOAT,
 filingDateRevAPQ2 Date,
 revenueEstimatePreQ1 FLOAT,
 filingDateRevPQ1 date,
 revenueEstimatePreQ2 FLOAT,
 filingDateRevPQ2 date,
 startPriceQ1 FLOAT,
 endPriceQ1 FLOAT,
 startPriceQ2 FLOAT,
 endPriceQ2 FLOAT,
 priceMovementQ2 FLOAT,
 priceMovementQ1 FLOAT,
 earningBeats Float,
 revenueBeats Float,
 priceMovement Float,
	asOfDate DATETIME,
)

DECLARE @CurrentQuarter INT
DECLARE @prevQuarter1 INT
DECLARE @prevQuarter2 INT
DECLARE @year1 INT
DECLARE @year2 INT

SET @CurrentQuarter = DATEPART(QUARTER, GETDATE()) - 1
SET @year1 = DATEPART(YEAR, GETDATE())
SET @year2 = DATEPART(YEAR, GETDATE())

IF @CurrentQuarter = 0
BEGIN
    SET @year1 = DATEPART(YEAR, GETDATE()) - 1
    SET @year2 = DATEPART(YEAR, GETDATE()) - 1
    SET @prevQuarter1 = 3
    SET @prevQuarter2 = 2
END
IF @CurrentQuarter = 1
BEGIN
    SET @year1 = DATEPART(YEAR, GETDATE()) - 1
    SET @year2 = DATEPART(YEAR, GETDATE()) - 1
    SET @prevQuarter1 = 4
    SET @prevQuarter2 = 3
END
ELSE IF @CurrentQuarter = 2
BEGIN
    SET @prevQuarter1 = 1
    SET @prevQuarter2 = 4
    SET @year2 = DATEPART(YEAR, GETDATE()) - 1
END
ELSE IF @CurrentQuarter > 2
BEGIN
    SET @prevQuarter1 = @CurrentQuarter - 1
    SET @prevQuarter2 = @CurrentQuarter - 2
    SET @year2 = @year1
END

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
 -- Initialize the variables for each iteration
SET @epsEstimatePreQ1=null
SET @epsEstimatePreQ2 = null
SET @actualEPSPrevQ1  = null
SET @actualEPSPrevQ2  = null
SET @actualRevenuePrevQ1  = null
SET @actualRevenuePrevQ2  = null
SET @revenueEstimatePreQ1  = null
SET @revenueEstimatePreQ2  = null
SET @startPriceQ1  = null
SET @endPriceQ1  = null
SET @startPriceQ2  = null
SET @endPriceQ2  = null
SET @priceMovementQ2  = null
SET @priceMovementQ1  = null
SET @earningBeats = null
SET @revenueBeats = null
SET @priceMovement = null

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


select top 1  @epsEstimatePreQ1=nd.dataitemvalue, @filingDateEPSPQ1 = ep.periodEndDate
from [Xpressfeed].[dbo].[ciqcompany] c
left join [Xpressfeed].[dbo].[ciqestimateperiod] ep on ep.companyid = c.companyid
left join [Xpressfeed].[dbo].[ciqEstimateperiodrelconst] epr on epr.estimateperiodid = ep.estimateperiodid and epr.periodtypeid = ep.periodtypeid
left join [Xpressfeed].[dbo].[ciqEstimateConsensus] ec on ec.estimateperiodid = ep.estimateperiodid
left join [Xpressfeed].[dbo].[ciqEstimateNumericData] nd on nd.estimateconsensusid = ec.estimateconsensusid --(financial forecasting measures in ciqEstimateNumericData)
left join [Xpressfeed].[dbo].[ciqsecurity] s on s.companyid = c.companyid and s.primaryflag =1 
left join [Xpressfeed].[dbo].[ciqtradingitem] ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join [Xpressfeed].[dbo].[ciqpriceequity] pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and ep.periodtypeid = 2 --Quaterly
and nd.dataitemid = 100173	 --EPS Normalized Consensus Mean (the average prediction of a company's future earnings per share, as made by financial analysts)
and nd.todate > '1-JAN-2079' 
and c.companyid=@companyId
AND ep.calendarYear = @year1
AND ep.calendarQuarter = @prevQuarter1
order by pe.pricingdate desc , ep.calendarYear desc

select top 1  @epsEstimatePreQ2=nd.dataitemvalue, @filingDateEPSPQ2 = ep.periodEndDate
from [Xpressfeed].[dbo].[ciqcompany] c
left join [Xpressfeed].[dbo].[ciqestimateperiod] ep on ep.companyid = c.companyid
left join [Xpressfeed].[dbo].[ciqEstimateperiodrelconst] epr on epr.estimateperiodid = ep.estimateperiodid and epr.periodtypeid = ep.periodtypeid
left join [Xpressfeed].[dbo].[ciqEstimateConsensus] ec on ec.estimateperiodid = ep.estimateperiodid
left join [Xpressfeed].[dbo].[ciqEstimateNumericData] nd on nd.estimateconsensusid = ec.estimateconsensusid --(financial forecasting measures in ciqEstimateNumericData)
left join [Xpressfeed].[dbo].[ciqsecurity] s on s.companyid = c.companyid and s.primaryflag =1 
left join [Xpressfeed].[dbo].[ciqtradingitem] ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join [Xpressfeed].[dbo].[ciqpriceequity] pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and ep.periodtypeid = 2 --Quaterly
and nd.dataitemid = 100173	 --EPS Normalized Consensus Mean (the average prediction of a company's future earnings per share, as made by financial analysts)
and nd.todate > '1-JAN-2079' 
and c.companyid=@companyId
AND ep.calendarYear = @year2
AND ep.calendarQuarter = @prevQuarter2
order by pe.pricingdate desc , ep.calendarYear desc



SELECT top 1  @actualEPSPrevQ1 =e.dataItemValue, @filingDateEPSAQ1 = b.periodEndDate
FROM [Xpressfeed].[dbo].[ciqFinPeriod] a
JOIN [Xpressfeed].[dbo].[ciqFinInstance] b ON a.financialPeriodId = b.financialPeriodId
JOIN [Xpressfeed].[dbo].[ciqFinInstanceToCollection] c ON b.financialInstanceId = c.financialInstanceId
JOIN [Xpressfeed].[dbo].[ciqFinCollection] d ON c.financialCollectionId = d.financialCollectionId
JOIN [Xpressfeed].[dbo].[ciqFinCollectionData] e ON d.financialCollectionId = e.financialCollectionId
JOIN [Xpressfeed].[dbo].[ciqCompany] f ON a.companyId = f.companyId
JOIN [Xpressfeed].[dbo].[ciqDataItem] g ON e.dataItemId = g.dataItemId
WHERE 1=1
AND a.companyId = @companyId
AND g.dataItemId= 8 -- EPS (Net EPS)
and a.calendarYear=@year1
and a.calendarQuarter = @prevQuarter1
and a.periodTypeId = 2 -- Quaterly
order by  b.periodEndDate desc

SELECT top 1 @actualEPSPrevQ2= e.dataItemValue, @filingDateEPSAQ2 = b.periodEndDate
FROM [Xpressfeed].[dbo].[ciqFinPeriod] a
JOIN [Xpressfeed].[dbo].[ciqFinInstance] b ON a.financialPeriodId = b.financialPeriodId
JOIN [Xpressfeed].[dbo].[ciqFinInstanceToCollection] c ON b.financialInstanceId = c.financialInstanceId
JOIN [Xpressfeed].[dbo].[ciqFinCollection] d ON c.financialCollectionId = d.financialCollectionId
JOIN [Xpressfeed].[dbo].[ciqFinCollectionData] e ON d.financialCollectionId = e.financialCollectionId
JOIN [Xpressfeed].[dbo].[ciqCompany] f ON a.companyId = f.companyId
JOIN [Xpressfeed].[dbo].[ciqDataItem] g ON e.dataItemId = g.dataItemId
WHERE 1=1
AND a.companyId = @companyId
AND g.dataItemId= 8 -- EPS (Net EPS)
and a.calendarYear=@year2
and a.calendarQuarter = @prevQuarter2
and a.periodTypeId = 2 -- Quaterly
order by  b.periodEndDate desc


---revenue actual--------
SELECT top 1   @actualRevenuePrevQ1=e.dataItemValue, @filingDateRevAQ1 = b.periodEndDate
FROM [Xpressfeed].[dbo].[ciqFinPeriod] a
JOIN [Xpressfeed].[dbo].[ciqFinInstance] b ON a.financialPeriodId = b.financialPeriodId
JOIN [Xpressfeed].[dbo].[ciqFinInstanceToCollection] c ON b.financialInstanceId = c.financialInstanceId
JOIN [Xpressfeed].[dbo].[ciqFinCollection] d ON c.financialCollectionId = d.financialCollectionId
JOIN [Xpressfeed].[dbo].[ciqFinCollectionData] e ON d.financialCollectionId = e.financialCollectionId
JOIN [Xpressfeed].[dbo].[ciqCompany] f ON a.companyId = f.companyId
JOIN [Xpressfeed].[dbo].[ciqDataItem] g ON e.dataItemId = g.dataItemId
WHERE 1=1
AND a.companyId = @companyId
AND g.dataItemId= 28 -- Total Revenue (Actual)
and a.calendarYear=@year1
and a.calendarQuarter = @prevQuarter1
and a.periodTypeId = 2 -- Quaterly
order by  b.periodEndDate desc

SELECT top 1 @actualRevenuePrevQ2= e.dataItemValue, @filingDateRevAPQ2 = b.periodEndDate
FROM [Xpressfeed].[dbo].[ciqFinPeriod] a
JOIN [Xpressfeed].[dbo].[ciqFinInstance] b ON a.financialPeriodId = b.financialPeriodId
JOIN [Xpressfeed].[dbo].[ciqFinInstanceToCollection] c ON b.financialInstanceId = c.financialInstanceId
JOIN [Xpressfeed].[dbo].[ciqFinCollection] d ON c.financialCollectionId = d.financialCollectionId
JOIN [Xpressfeed].[dbo].[ciqFinCollectionData] e ON d.financialCollectionId = e.financialCollectionId
JOIN [Xpressfeed].[dbo].[ciqCompany] f ON a.companyId = f.companyId
JOIN [Xpressfeed].[dbo].[ciqDataItem] g ON e.dataItemId = g.dataItemId
WHERE 1=1
AND a.companyId = @companyId
AND g.dataItemId= 28 -- Total Revenue (Actual)
and a.calendarYear=@year2
and a.calendarQuarter = @prevQuarter2
and a.periodTypeId = 2 -- Quaterly
order by  b.periodEndDate desc

------------revenue estimate------------
select top 1 @revenueEstimatePreQ1=nd.dataitemvalue, @filingDateRevPQ1 = ep.periodEndDate
from [Xpressfeed].[dbo].[ciqcompany] c
left join [Xpressfeed].[dbo].[ciqestimateperiod] ep on ep.companyid = c.companyid
left join [Xpressfeed].[dbo].[ciqEstimateperiodrelconst] epr on epr.estimateperiodid = ep.estimateperiodid and epr.periodtypeid = ep.periodtypeid
left join [Xpressfeed].[dbo].[ciqEstimateConsensus] ec on ec.estimateperiodid = ep.estimateperiodid
left join [Xpressfeed].[dbo].[ciqEstimateNumericData] nd on nd.estimateconsensusid = ec.estimateconsensusid --(financial forecasting measures in ciqEstimateNumericData)
left join [Xpressfeed].[dbo].[ciqsecurity] s on s.companyid = c.companyid and s.primaryflag =1 
left join [Xpressfeed].[dbo].[ciqtradingitem] ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join [Xpressfeed].[dbo].[ciqpriceequity] pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and ep.periodtypeid = 2 --Quaterly
and nd.dataitemid = 100180	 --Revenue Consensus Mean (Mean is the arithmetical mean average of the forecasts after suppressed forecasts are excluded.)
and nd.todate > '1-JAN-2079' 
and c.companyid=@companyId
AND ep.calendarYear = @year1
AND ep.calendarQuarter = @prevQuarter1
order by pe.pricingdate desc , ep.calendarYear desc

select top 1 @revenueEstimatePreQ2= nd.dataitemvalue, @filingDateRevPQ2 = ep.periodEndDate
from [Xpressfeed].[dbo].[ciqcompany] c
left join [Xpressfeed].[dbo].[ciqestimateperiod] ep on ep.companyid = c.companyid
left join [Xpressfeed].[dbo].[ciqEstimateperiodrelconst] epr on epr.estimateperiodid = ep.estimateperiodid and epr.periodtypeid = ep.periodtypeid
left join [Xpressfeed].[dbo].[ciqEstimateConsensus] ec on ec.estimateperiodid = ep.estimateperiodid
left join [Xpressfeed].[dbo].[ciqEstimateNumericData] nd on nd.estimateconsensusid = ec.estimateconsensusid --(financial forecasting measures in ciqEstimateNumericData)
left join [Xpressfeed].[dbo].[ciqsecurity] s on s.companyid = c.companyid and s.primaryflag =1 
left join [Xpressfeed].[dbo].[ciqtradingitem] ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join [Xpressfeed].[dbo].[ciqpriceequity] pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and ep.periodtypeid = 2 --Quaterly
and nd.dataitemid = 100180	 --Revenue Consensus Mean (Mean is the arithmetical mean average of the forecasts after suppressed forecasts are excluded.)
and nd.todate > '1-JAN-2079' 
and c.companyid=@companyId
AND ep.calendarYear = @year2
AND ep.calendarQuarter = @prevQuarter2
order by pe.pricingdate desc , ep.calendarYear desc

-- Get the closing price for the start and end of the most recent quarter
SELECT top 1 @startPriceQ1 = pe.priceClose
FROM [Xpressfeed].[dbo].[ciqPriceEquity] pe
JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON pe.tradingItemId = ti.tradingItemId
WHERE ti.tickerSymbol=@tickerSymbol
AND pe.pricingDate in (
    SELECT top 10 pe.pricingDate
    FROM [Xpressfeed].[dbo].[ciqPriceEquity] pe
    JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON pe.tradingItemId = ti.tradingItemId
    WHERE ti.tickerSymbol=@tickerSymbol
    AND DATEPART(QUARTER, pe.pricingDate) = @prevQuarter1
    AND DATEPART(YEAR, pe.pricingDate) = @year1 order by pe.pricingDate asc
)AND ti.tradingItemId=@tradingItemID order by pe.pricingDate asc
SELECT top 1 @endPriceQ1 = pe.priceClose
FROM [Xpressfeed].[dbo].[ciqPriceEquity] pe
JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON pe.tradingItemId = ti.tradingItemId
WHERE ti.tickerSymbol=@tickerSymbol
AND pe.pricingDate in (
    SELECT top 10 pe.pricingDate
    FROM [Xpressfeed].[dbo].[ciqPriceEquity] pe
    JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON pe.tradingItemId = ti.tradingItemId
    WHERE ti.tickerSymbol=@tickerSymbol
    AND DATEPART(QUARTER, pe.pricingDate) = @prevQuarter1
    AND DATEPART(YEAR, pe.pricingDate) = @year1 
	order by pe.pricingDate desc
)
AND ti.tradingItemId=@tradingItemID order by pe.pricingDate desc


SET @priceMovementQ1= @endPriceQ1 - @startPriceQ1
-- Get the closing price for the start and end of the second most recent quarter
SELECT top 1 @startPriceQ2 = pe.priceClose
FROM [Xpressfeed].[dbo].[ciqPriceEquity] pe
JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON pe.tradingItemId = ti.tradingItemId
WHERE ti.tickerSymbol=@tickerSymbol
AND pe.pricingDate in (
    SELECT top 10 pe.pricingDate
    FROM [Xpressfeed].[dbo].[ciqPriceEquity] pe
    JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON pe.tradingItemId = ti.tradingItemId
    WHERE ti.tickerSymbol=@tickerSymbol
    AND DATEPART(QUARTER, pe.pricingDate) = @prevQuarter2
    AND DATEPART(YEAR, pe.pricingDate) = @year2 order by pe.pricingDate asc
)AND ti.tradingItemId=@tradingItemID order by pe.pricingDate asc
SELECT top 1 @endPriceQ2 = pe.priceClose
FROM [Xpressfeed].[dbo].[ciqPriceEquity] pe
JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON pe.tradingItemId = ti.tradingItemId
WHERE ti.tickerSymbol=@tickerSymbol
AND pe.pricingDate in (
    SELECT top 10 pe.pricingDate
    FROM [Xpressfeed].[dbo].[ciqPriceEquity] pe
    JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON pe.tradingItemId = ti.tradingItemId
    WHERE ti.tickerSymbol=@tickerSymbol
    AND DATEPART(QUARTER, pe.pricingDate) = @prevQuarter2
    AND DATEPART(YEAR, pe.pricingDate) = @year2 order by pe.pricingDate desc
)AND ti.tradingItemId=@tradingItemID order by pe.pricingDate desc

SET @priceMovementQ2= @endPriceQ2 - @startPriceQ2

set @earningBeats = (@actualEPSPrevQ1/@epsEstimatePreQ1) + (@actualEPSPrevQ2/@epsEstimatePreQ2)
set @revenueBeats = (@actualRevenuePrevQ1 / @revenueEstimatePreQ1) + (@actualRevenuePrevQ2 /@revenueEstimatePreQ2)
set @priceMovement = @priceMovementQ1 + @priceMovementQ2

INSERT INTO #doubleBeats (tickerSymbol,epsEstimatePreQ1,filingDateEPSPQ1, epsEstimatePreQ2,filingDateEPSPQ2,actualEPSPrevQ1,filingDateEPSAQ1,actualEPSPrevQ2,filingDateEPSAQ2,actualRevenuePrevQ1,filingDateRevAQ1,actualRevenuePrevQ2,filingDateRevAPQ2,
revenueEstimatePreQ1 ,filingDateRevPQ1,revenueEstimatePreQ2 ,filingDateRevPQ2,startPriceQ1 ,endPriceQ1 ,startPriceQ2 ,endPriceQ2 ,priceMovementQ2 ,
priceMovementQ1,earningBeats,revenueBeats,priceMovement,asOfDate)
  VALUES (@tickerSymbol,@epsEstimatePreQ1,@filingDateEPSPQ1,@epsEstimatePreQ2 ,@filingDateEPSPQ2,@actualEPSPrevQ1,@filingDateEPSAQ1,@actualEPSPrevQ2,@filingDateEPSAQ2,@actualRevenuePrevQ1,@filingDateRevAQ1,@actualRevenuePrevQ2 ,@filingDateRevAPQ2,
@revenueEstimatePreQ1 ,@filingDateRevPQ1,@revenueEstimatePreQ2 ,@filingDateRevPQ2,@startPriceQ1 ,@endPriceQ1 ,@startPriceQ2 ,@endPriceQ2 ,@priceMovementQ2 ,
@priceMovementQ1,@earningBeats,@revenueBeats,@priceMovement,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

select * from #doubleBeats

--select * into [QIAR_TEST].[dbo].[snDoubleBeatsScreen] from #doubleBeats



--select * from [QIAR_TEST].[dbo].[snDoubleBeatsScreen]

-- drop table [QIAR_TEST].[dbo].[snDoubleBeatsScreen]

----strategy to select stocks for double beats strategy----------
SELECT *
FROM [QIAR_TEST].[dbo].[snDoubleBeatsScreen]
WHERE 
    -- EPS beat for the past two quarters
    actualEPSPrevQ1 > epsEstimatePreQ1 AND
    actualEPSPrevQ2 > epsEstimatePreQ2 AND
    -- Revenue beat for the past two quarters
    actualRevenuePrevQ1 > revenueEstimatePreQ1 AND
    actualRevenuePrevQ2 > revenueEstimatePreQ2 AND
    -- Positive price action for the past two quarters
    priceMovementQ1 > 0 AND
    priceMovementQ2 > 0

order by priceMovementQ1 desc

;WITH Standardized AS (
    SELECT *,
           (earningBeats - Min(earningBeats) OVER ()) / (Max(earningBeats) OVER () - Min(earningBeats) OVER ()) AS Standardized_earningBeats,
		   (revenueBeats - Min(revenueBeats) OVER ()) / (Max(revenueBeats) OVER () - Min(revenueBeats) OVER ()) AS Standardized_revenueBeats,
		   (priceMovement - Min(priceMovement) OVER ()) / (Max(priceMovement) OVER () - Min(priceMovement) OVER ()) AS Standardized_priceMovement
    FROM [QIAR_TEST].[dbo].[snDoubleBeatsScreen]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_earningBeats + Standardized_revenueBeats + Standardized_priceMovement ) DESC) AS Rank
FROM Standardized
ORDER BY Rank;


