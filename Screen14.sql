------------------------------(14) CASH USAGE SCREEN----------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tradingItemID INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @divYield FLOAT
DECLARE @PE_Ratio FLOAT
DECLARE @debtEquityRatio FLOAT
DECLARE @freeCashFlow FLOAT
DECLARE @returnOnEquity FLOAT
DECLARE @payoutRatio FLOAT

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#cashUsageScreen') IS NOT NULL DROP TABLE #cashUsageScreen;
CREATE TABLE #cashUsageScreen (
    tickerSymbol VARCHAR(255),
	divYield FLOAT,
	PE_Ratio FLOAT,
	debtEquityRatio FLOAT,
	freeCashFlow FLOAT,
	returnOnEquity FLOAT,
	payoutRatio FLOAT,
	asOfDate DATE
)

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
SET @divYield = null
SET @PE_Ratio = null
SET @debtEquityRatio = null
SET @freeCashFlow = null
SET @returnOnEquity = null
SET @payoutRatio = null
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


 SELECT TOP 1 
    @divYield=(ch.dataItemValue / er1.priceclose) / (pe.priceClose / er.priceclose) * 100 
FROM ciqIADividendChain ch
JOIN ciqPriceEquity pe ON pe.tradingItemId = ch.tradingItemId
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

select top 1  @PE_Ratio=(pe.priceclose/fd.dataitemvalue) 
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
AND a.periodTypeId = '2' --- Quarterly
AND a.companyId = @companyId
AND e.dataItemId=4173 --Total Debt
AND e2.dataItemId=1275 -- total Equity

SELECT @freeCashFlow=fd.dataItemValue , @returnOnEquity=fd2.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag = 1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd2 on fd2.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =4422 -- Free Cash Flow (Levered i.e after paying taxes and debt obligation)
and fd2.dataItemId= 4128
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId =@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

SELECT @returnOnEquity=fd2.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag = 1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd2 on fd2.financialPeriodId=fp.financialPeriodId
WHERE 1=1 
and fd2.dataItemId= 4128 ---ROE
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId =@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc


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


 INSERT INTO #cashUsageScreen (tickerSymbol, divYield,PE_Ratio,debtEquityRatio,freeCashFlow,returnOnEquity,payoutRatio,asOfDate)
  VALUES (@tickerSymbol,@divYield,@PE_Ratio,@debtEquityRatio,@freeCashFlow,@returnOnEquity,@payoutRatio,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

--select * from [QIAR_TEST].[dbo].[snCashUsageScreen]  order by dividendPerShareGrowth desc

select * from #cashUsageScreen

--select * into [QIAR_TEST].[dbo].[snCashUsageScreen] from #cashUsageScreen

-- drop table [QIAR_TEST].[dbo].[snCashUsageScreen]

-----------------Ranking As Per Stategy-----------------------
SELECT *,
       (CASE WHEN divYield > 0 THEN 1 ELSE 0 END +
        CASE WHEN PE_Ratio > 0 THEN 1 ELSE 0 END +
        CASE WHEN debtEquityRatio < 1 THEN 1 ELSE 0 END +
        CASE WHEN freeCashFlow > 0 THEN 1 ELSE 0 END +
        CASE WHEN returnOnEquity > 0 THEN 1 ELSE 0 END +
        CASE WHEN payoutRatio < 1 THEN 1 ELSE 0 END) AS MetricsMet,
       RANK() OVER (ORDER BY (CASE WHEN divYield > 0 THEN 1 ELSE 0 END +
                                CASE WHEN PE_Ratio > 0 THEN 1 ELSE 0 END +
                                CASE WHEN debtEquityRatio < 1 THEN 1 ELSE 0 END +
                                CASE WHEN freeCashFlow > 0 THEN 1 ELSE 0 END +
                                CASE WHEN returnOnEquity > 0 THEN 1 ELSE 0 END +
                                CASE WHEN payoutRatio < 1 THEN 1 ELSE 0 END) DESC) AS Rank
FROM [QIAR_TEST].[dbo].[snCashUsageScreen]
ORDER BY Rank;
----------------Standardize and Rank-----------
WITH Standardized AS (
    SELECT *,
           (divYield - Min(divYield) OVER ()) / (Max(divYield) OVER () - Min(divYield) OVER ()) AS Standardized_divYield,
           1 - ((PE_Ratio - Min(PE_Ratio) OVER ()) / (Max(PE_Ratio) OVER () - Min(PE_Ratio) OVER ())) AS Standardized_PE_Ratio,
           1 - ((debtEquityRatio - Min(debtEquityRatio) OVER ()) / (Max(debtEquityRatio) OVER () - Min(debtEquityRatio) OVER ())) AS Standardized_debtEquityRatio,
           (freeCashFlow - Min(freeCashFlow) OVER ()) / (Max(freeCashFlow) OVER () - Min(freeCashFlow) OVER ()) AS Standardized_freeCashFlow,
           (returnOnEquity - Min(returnOnEquity) OVER ()) / (Max(returnOnEquity) OVER () - Min(returnOnEquity) OVER ()) AS Standardized_returnOnEquity,
           1 - ((payoutRatio - Min(payoutRatio) OVER ()) / (Max(payoutRatio) OVER () - Min(payoutRatio) OVER ())) AS Standardized_payoutRatio
    FROM [QIAR_TEST].[dbo].[snCashUsageScreen]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_divYield + Standardized_PE_Ratio + Standardized_debtEquityRatio + Standardized_freeCashFlow + Standardized_returnOnEquity + Standardized_payoutRatio) DESC) AS Rank
FROM Standardized
ORDER BY Rank;
----------------Rank Individually and Add-------------
WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY divYield DESC) as rank_divYield,
           RANK() OVER (ORDER BY PE_Ratio ASC) as rank_PE_Ratio,
           RANK() OVER (ORDER BY debtEquityRatio ASC) as rank_debtEquityRatio,
           RANK() OVER (ORDER BY freeCashFlow DESC) as rank_freeCashFlow,
           RANK() OVER (ORDER BY returnOnEquity DESC) as rank_returnOnEquity,
           RANK() OVER (ORDER BY payoutRatio ASC) as rank_payoutRatio
    FROM [QIAR_TEST].[dbo].[snCashUsageScreen] where divYield is not null and PE_Ratio is not null and debtEquityRatio is not null 
	and freeCashFlow is not null and returnOnEquity is not null and payoutRatio is not null 
)
SELECT *,
       RANK() OVER (ORDER BY (rank_divYield + rank_PE_Ratio + rank_debtEquityRatio + rank_freeCashFlow + rank_returnOnEquity + rank_payoutRatio) ASC) AS Total_Rank
FROM Ranked
ORDER BY Total_Rank;
