-----------------------------(21) 2nd Quntile Divi Yield and Attractive Valuation-----------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
Declare @divYield Float
Declare @marketCap Float
Declare @NTM_PE_Ratio Float
Declare @tradingItemID int


-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#highDivYieldAndValuation') IS NOT NULL DROP TABLE #highDivYieldAndValuation;
CREATE TABLE #highDivYieldAndValuation (
    tickerSymbol VARCHAR(255),
	divYield FLOAT,
	marketCap FLOAT,
	NTM_PE_Ratio FLOAT,
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
	SET @divYield  = Null
	SET @marketCap  = Null
	SET @NTM_PE_Ratio  = Null
    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol,
		@tradingItemID=tradingItemID
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY companyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter


---------------------Dividend Yield----------------------
  SELECT top 1  @divYield=(ch.dataItemValue /pe.priceClose) * 100
FROM ciqIADividendChain ch
JOIN ciqPriceEquity pe ON pe.tradingItemId = ch.tradingItemId
JOIN ciqTradingItem ti ON ti.tradingItemId = pe.tradingItemId
JOIN ciqExchangeRate er1 ON er1.currencyId = ch.currencyId
    AND er1.pricedate BETWEEN ch.startDate AND ISNULL(ch.endDate, GETUTCDATE())
    AND er1.pricedate = pe.pricingDate
WHERE ch.companyId = @companyId
 AND ti.tradingItemId= @tradingItemID
ORDER BY pe.pricingDate DESC;

----marketCap for company-----------
select top 1 @marketCap= c.marketCap from [Xpressfeed].[dbo].[ciqMarketCap] c where c.companyId=@companyId order by pricingDate desc

-----------NTM PE Ratio -----------------

select top 1  @NTM_PE_Ratio= pe.priceclose/nd.dataitemvalue 
from [Xpressfeed].[dbo].[ciqcompany] c
left join [Xpressfeed].[dbo].[ciqestimateperiod] ep on ep.companyid = c.companyid
left join [Xpressfeed].[dbo].[ciqEstimateperiodrelconst] epr on epr.estimateperiodid = ep.estimateperiodid and epr.periodtypeid = ep.periodtypeid
left join [Xpressfeed].[dbo].[ciqEstimateConsensus] ec on ec.estimateperiodid = ep.estimateperiodid
left join [Xpressfeed].[dbo].[ciqEstimateNumericData] nd on nd.estimateconsensusid = ec.estimateconsensusid --(financial forecasting measures in ciqEstimateNumericData)
left join [Xpressfeed].[dbo].[ciqsecurity] s on s.companyid = c.companyid and s.primaryflag =1 
left join [Xpressfeed].[dbo].[ciqtradingitem] ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join [Xpressfeed].[dbo].[ciqpriceequity] pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and ep.periodtypeid = 1 --Annual
and nd.dataitemid = 100173 --EPS Normalized Consensus Mean (the average prediction of a company's future earnings per share, as made by financial analysts)
--and pe.pricingdate = To_date(trunc(sysdate, 'YYYY')-1)
and nd.todate > '1-JAN-2079' 
and c.companyid=@companyId
and epr.relativeconstant -1000 = 1
and ti.tradingItemId=@tradingItemID
order by pe.pricingdate desc


INSERT INTO #highDivYieldAndValuation (tickerSymbol, divYield,marketCap,NTM_PE_Ratio,asOfDate)
  VALUES (@tickerSymbol, @divYield,@marketCap,@NTM_PE_Ratio,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END



----------------Standardize and Rank-----------
;WITH Standardized AS (
    SELECT *,
           (divYield - Min(divYield) OVER ()) / (Max(divYield) OVER () - Min(divYield) OVER ()) AS Standardized_divYield,
           (marketCap - Min(marketCap) OVER ()) / (Max(marketCap) OVER () - Min(marketCap) OVER ()) AS Standardized_marketCap,
           (NTM_PE_Ratio - Min(NTM_PE_Ratio) OVER ()) / (Max(NTM_PE_Ratio) OVER () - Min(NTM_PE_Ratio) OVER ()) AS Standardized_NTM_PE_Ratio
    FROM [QIAR_TEST].[dbo].[snHighDivYieldAndValuation]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_divYield + Standardized_marketCap + Standardized_NTM_PE_Ratio ) DESC) AS Rank
FROM Standardized
ORDER BY Rank;

 ----------------------Implemeting Stock Selection Algorithm---------------
SELECT 
tickerSymbol, 
divYield,
marketCap,
NTM_PE_Ratio,
asOfDate
FROM (
    SELECT 
    tickerSymbol, 
    divYield,
    marketCap,
    NTM_PE_Ratio,
    asOfDate,
    NTILE(5) OVER(ORDER BY divYield DESC) AS DivYieldQuintile,
    NTILE(5) OVER(ORDER BY NTM_PE_Ratio ASC) AS PEQuintile
    FROM [QIAR_TEST].[dbo].[snHighDivYieldAndValuation]
    WHERE divYield IS NOT NULL AND NTM_PE_Ratio IS NOT NULL
) AS T
WHERE DivYieldQuintile = 2 AND PEQuintile = 1



--select * into [QIAR_TEST].[dbo].[snHighDivYieldAndValuation] from #highDivYieldAndValuation

-- drop table [QIAR_TEST].[dbo].[snHighDivYieldAndValuation]

-- select * from [QIAR_TEST].[dbo].[snHighDivYieldAndValuation]
