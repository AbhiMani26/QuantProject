-------------------------(18) Consistent Dividend Growth with Attractive Valuation------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
Declare @tradingItemID Int
DECLARE @divYield FLOAT
Declare @annualDivGrowth Float
Declare @LTAverage Float
Declare @PE_Ratio_12_Mo Float

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#consistentDivGrowth') IS NOT NULL DROP TABLE #consistentDivGrowth;
CREATE TABLE #consistentDivGrowth (
    tickerSymbol VARCHAR(255),
    divYield FLOAT,
	annualDivGrowth FLOAT,
	LTAverage FLOAT,
	PE_Ratio_12_Mo FLOAT,
	asOfDate DATE
)


-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN

-------Initialise Variables------
	SET @divYield = Null
	SET @annualDivGrowth =Null
	SET @LTAverage =null
	SET @PE_Ratio_12_Mo =null
    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol,
		@tradingItemID=tradingItemID
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY CompanyId) AS RowNum
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


--------Annual Dividend growth---------------
SELECT @annualDivGrowth=fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=4206 ---divdend per share growth annual 
AND fp.periodTypeId = 1 --A
AND fp.latestPeriodFlag=1
AND c.companyId=@companyId
ORDER BY fp.periodEndDate desc


----------------Long Term Dividend Yield Average-------------
IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1;
SELECT
    YEAR(pe.pricingDate) AS Year,
    MONTH(pe.pricingDate) AS Month,
    AVG(ch.dataItemValue / pe.priceclose)*100 AS MonthlyDividendYield
	into #temp1
FROM [Xpressfeed].[dbo].[ciqIADividendChain] ch
JOIN [Xpressfeed].[dbo].[ciqPriceEquity] pe ON pe.tradingItemId = ch.tradingItemId
JOIN [Xpressfeed].[dbo].[ciqTradingItem] ti ON ti.tradingItemId = pe.tradingItemId
JOIN [Xpressfeed].[dbo].[ciqExchangeRate] er1 ON er1.currencyId = ch.currencyId
    AND er1.pricedate BETWEEN ch.startDate AND ISNULL(ch.endDate, GETUTCDATE())
    AND er1.pricedate = pe.pricingDate
WHERE ch.companyId = @companyId
and ti.tradingItemId=@tradingItemID
    AND pe.pricingDate >= DATEADD(YEAR, -10, GETUTCDATE())
GROUP BY YEAR(pe.pricingDate), MONTH(pe.pricingDate)
ORDER BY Year DESC, Month DESC;

set @LTAverage = ( select avg(MonthlyDividendYield) from #temp1)

-----------PE Ratio--------------------
select top 1 @PE_Ratio_12_Mo=(pe.priceclose/fd.dataitemvalue) 
from [Xpressfeed].[dbo].[ciqcompany] c
left join [Xpressfeed].[dbo].[ciqlatestinstancefinperiod] lfp on lfp.companyid = c.companyid
left join [Xpressfeed].[dbo].[ciqfinancialdata] fd on fd.financialperiodid = lfp.financialperiodid 
left join [Xpressfeed].[dbo].[ciqsecurity] s on s.companyid = c.companyid and s.primaryflag =1 
left join [Xpressfeed].[dbo].[ciqtradingitem] ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join [Xpressfeed].[dbo].[ciqpriceequity] pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and lfp.periodtypeid = 4 --LTM
and fd.dataitemid = 8 --EPS
and lfp.latestperiodflag = 1
and c.companyid=@companyId
order by pe.pricingDate desc 

 INSERT INTO #consistentDivGrowth (tickerSymbol,divYield, annualDivGrowth,LTAverage,PE_Ratio_12_Mo,asOfDate)
  VALUES (@tickerSymbol, @divYield, @annualDivGrowth,@LTAverage,@PE_Ratio_12_Mo,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END


----------------Standardize and Rank-----------
;WITH Standardized AS (
    SELECT *,
           (divYield - Min(divYield) OVER ()) / (Max(divYield) OVER () - Min(divYield) OVER ()) AS Standardized_divYield,
           (annualDivGrowth - Min(annualDivGrowth) OVER ()) / (Max(annualDivGrowth) OVER () - Min(annualDivGrowth) OVER ()) AS Standardized_annualDivGrowth,
           (LTAverage - Min(LTAverage) OVER ()) / (Max(LTAverage) OVER () - Min(LTAverage) OVER ()) AS Standardized_LTAverage,
		   (PE_Ratio_12_Mo - Min(PE_Ratio_12_Mo) OVER ()) / (Max(PE_Ratio_12_Mo) OVER () - Min(PE_Ratio_12_Mo) OVER ()) AS Standardized_PE_Ratio_12_Mo
    FROM [QIAR_TEST].[dbo].[snConsistentDivGrowth]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_divYield + Standardized_annualDivGrowth + Standardized_LTAverage + Standardized_PE_Ratio_12_Mo) DESC) AS Rank
FROM Standardized
ORDER BY Rank;





--select * from [QIAR_TEST].[dbo].[snConsistentDivGrowth] where divYield is not null and annualDivGrowth is not null and LTAverage is not null order by PE_Ratio_12_Mo desc


--select * into [QIAR_TEST].[dbo].[snConsistentDivGrowth] from #consistentDivGrowth (1here)
--drop table [QIAR_TEST].[dbo].[snConsistentDivGrowth]
--Select * from [QIAR_TEST].[dbo].[snConsistentDivGrowth]