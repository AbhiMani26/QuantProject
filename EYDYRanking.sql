-------------------------(17) Accelerating Buybacks------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
Declare @tradingItemID INT
DECLARE @divYield FLOAT
DECLARE @earningYield FLOAT

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#EYDY') IS NOT NULL DROP TABLE #EYDY;
CREATE TABLE #EYDY (
    tickerSymbol VARCHAR(255),
	earningYield FLOAT,
    divYield Float,
	asOfDate DATE
)


-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN

	SET @divYield =null
	SET @earningYield =null
    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol,
		@tradingItemID = tradingItemID
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY CompanyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter


select top 1  @earningYield=(fd.dataitemvalue/pe.priceclose) * 100, 
from ciqcompany c
left join ciqlatestinstancefinperiod lfp on lfp.companyid = c.companyid
left join ciqfinancialdata fd on fd.financialperiodid = lfp.financialperiodid 
left join ciqsecurity s on s.companyid = c.companyid and s.primaryflag =1 
left join ciqtradingitem ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join ciqpriceequity pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and lfp.periodtypeid = 2 -- Quarterly
and fd.dataitemid = 8 --EPS
and 
and lfp.latestperiodflag = 1
and c.companyid=@companyId
order by pe.pricingDate desc , lfp.calendarYear desc

  SELECT TOP 1  @divYield=(ch.dataItemValue / er1.priceclose) / (pe.priceClose / er.priceclose) * 100 
FROM ciqIADividendChain ch
JOIN ciqPriceEquity pe ON pe.tradingItemId = ch.tradingItemId
Join ciqSecurity s on s.companyId = ti.
JOIN ciqTradingItem ti ON ti.tradingItemId = pe.tradingItemId
JOIN ciqExchangeRate er ON er.currencyId = ti.currencyId
    AND er.priceDate = pe.pricingDate
JOIN ciqCurrency cu ON cu.currencyId = er.currencyId
JOIN ciqExchangeRate er1 ON er1.currencyId = ch.currencyId
    AND er1.snapId = er.snapId
    AND er1.pricedate BETWEEN ch.startDate AND ISNULL(ch.endDate, GETUTCDATE())
    AND er1.pricedate = pe.pricingDate
WHERE ch.companyId = @companyId
  AND ti.tradingItemId= @tradingItemID
ORDER BY pe.pricingDate DESC;

INSERT INTO #EYDY (tickerSymbol,earningYield,divYield,asOfDate)
  VALUES (@tickerSymbol,@earningYield, @divYield,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

select * from #EYDY


---------Standardize and Rank--------------

;WITH Ranked AS (
    SELECT *,
    (divYield - MIN(divYield) OVER ()) / (MAX(divYield) OVER () - MIN(divYield) OVER ()) AS standardized_DY,
    (earningYield - MIN(earningYield) OVER ()) / (MAX(earningYield) OVER () - MIN(earningYield) OVER ()) AS standardized_EY,
	RANK() OVER (ORDER BY divYield DESC) AS DY_Individual_Rank,
    RANK() OVER (ORDER BY earningYield DESC) AS EY_Individual_Rank
    FROM #EYDY where divYield is not null and earningYield is not null
)
SELECT *,
       RANK() OVER (ORDER BY (standardized_DY + standardized_EY ) DESC) AS Rank_Standardized,
	   RANK() OVER (ORDER BY (DY_Individual_Rank + EY_Individual_Rank ) ASC) AS Rank_Individual
	   INTO #EYDYrank
FROM Ranked
ORDER BY Rank_Standardized ASC;

select * from #EYDYrank order by Rank_Standardized asc

--select * into [QIAR_TEST].[dbo].[snEYDYRanking] from #EYDYrank


select *, DY_Individual_Rank + EY_Individual_Rank as rankSum from [QIAR_TEST].[dbo].[snEYDYRanking] order by rankSum asc







