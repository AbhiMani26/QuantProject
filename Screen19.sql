----------------------(19) High Dividend Yield, Lower Payout Ratio and Not High Leverage------------

DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @divYield FLOAT
Declare @payoutRatio Float
Declare @debtEquityRatio Float
Declare @tradingItemID int
-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#highYieldLowPRLowLeverage') IS NOT NULL DROP TABLE #highYieldLowPRLowLeverage;
CREATE TABLE #highYieldLowPRLowLeverage (
    tickerSymbol VARCHAR(255),
    divYield FLOAT,
	payoutRatio FLOAT,
	debtEquityRatio FLOAT
)


-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
 -- Initialize the variables for each iteration
    SET @divYield = NULL
    SET @payoutRatio = NULL
    SET @debtEquityRatio = NULL
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


--------------------Payout Ratio----------------
select top 1 @payoutRatio= fd.dataItemValue 
from ciqcompany c
left join ciqlatestinstancefinperiod lfp on lfp.companyid = c.companyid
left join ciqfinancialdata fd on fd.financialperiodid = lfp.financialperiodid
left join ciqsecurity s on s.companyid = c.companyid and s.primaryflag =1 
left join ciqtradingitem ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join ciqpriceequity pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and lfp.periodtypeid = 2 --Quarterly
and fd.dataitemid = 4377 --Payout Ratio
and lfp.latestperiodflag = 1
and c.companyid=@companyId
order by pe.pricingDate desc

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


----------------debtEquityratio (Leverage Ratio)------------------------------
    SELECT @debtEquityRatio=e.dataItemValue/e2.dataItemValue
FROM ciqFinPeriod a
JOIN ciqFinInstance b ON a.financialPeriodId = b.financialPeriodId
JOIN ciqFinInstanceToCollection c ON b.financialInstanceId = c.financialInstanceId
JOIN ciqFinCollection d ON c.financialCollectionId = d.financialCollectionId
JOIN ciqFinCollectionData e ON d.financialCollectionId = e.financialCollectionId
JOIN ciqFinCollectionData e2 ON d.financialCollectionId = e2.financialCollectionId
JOIN ciqCompany f ON a.companyId = f.companyId
JOIN ciqDataItem g ON e.dataItemId = g.dataItemId
WHERE a.latestPeriodFlag = 1
AND a.periodTypeId = 2 --- Quarterly
AND a.companyId = @companyId
AND e.dataItemId=4173 --Total Debt
AND e2.dataItemId=1275 -- total Equity


 INSERT INTO #highYieldLowPRLowLeverage (tickerSymbol,divYield, payoutRatio,debtEquityRatio)
  VALUES (@tickerSymbol, @divYield, @payoutRatio,@debtEquityRatio);

    -- Increment the counter
    SET @Counter = @Counter + 1
END


----------------Standardize and Rank-----------
;WITH Standardized AS (
    SELECT *,
           (divYield - Min(divYield) OVER ()) / (Max(divYield) OVER () - Min(divYield) OVER ()) AS Standardized_divYield,
           (payoutRatio - Min(payoutRatio) OVER ()) / (Max(payoutRatio) OVER () - Min(payoutRatio) OVER ()) AS Standardized_payoutRatio,
           (debtEquityRatio - Min(debtEquityRatio) OVER ()) / (Max(debtEquityRatio) OVER () - Min(debtEquityRatio) OVER ()) AS Standardized_debtEquityRatio
    FROM [QIAR_TEST].[dbo].[snHighYieldLowPRLowLeverage]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_divYield - Standardized_payoutRatio - Standardized_debtEquityRatio) DESC) AS Rank
FROM Standardized
ORDER BY Rank;



-- select * from #highYieldLowPRLowLeverage
--select * into [QIAR_TEST].[dbo].[snHighYieldLowPRLowLeverage] from #highYieldLowPRLowLeverage

-- drop table [QIAR_TEST].[dbo].[snHighYieldLowPRLowLeverage]

--select * from [QIAR_TEST].[dbo].[snHighYieldLowPRLowLeverage] where divYield > 4 and payoutRatio <  4 and debtEquityRatio < 4 order by divYield desc

--select * from [QIAR_TEST].[dbo].[snHighYieldLowPRLowLeverage] where divYield is not null and payOutRatio is not null

--select * into [QIAR_TEST].[dbo].[snHighYieldLowPRLowLeverage] from [QIAR_TEST].[dbo].[highYieldLowPRLowLeverage]