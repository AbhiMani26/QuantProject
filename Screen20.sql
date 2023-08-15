----------------------------(20) High Dividend Growth and High FCFF Yield-------------------------

DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
Declare @dividendPerShare5YearCAGR Float
Declare @marketCap Float
Declare @freeCashFlow Float
Declare @freeCashFlowYield Float
Declare @PE_Ratio_12_Mo Float
Declare @shareCountDecline Float
Declare @tradingItemID Int


-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#highDivGrowthHighFCFFYield') IS NOT NULL DROP TABLE #highDivGrowthHighFCFFYield;
CREATE TABLE #highDivGrowthHighFCFFYield (
    tickerSymbol VARCHAR(255),
	dividendPerShare5YearCAGR FLOAT,
	marketCap FLOAT,
	freeCashFlow FLOAT,
	PE_Ratio_12_Mo Float,
	shareCountDecline Float,
	freeCashFlowYield FLOAT,
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
	SET @dividendPerShare5YearCAGR  = Null
	SET @marketCap  = Null
	SET @freeCashFlow  = Null
	SET @PE_Ratio_12_Mo  = Null
	SET @shareCountDecline = Null
	Set @freeCashFlowYield = null
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

----------------------------5 year Dividend Per Share Compunded Growth---------------------

SELECT @dividendPerShare5YearCAGR=fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag = 1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =4245 --Dividend Per Share, 5 Yr. CAGR %s
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId =@companyId 
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc



----marketCap for company-----------
select top 1 @marketCap=marketCap from ciqMarketCap where companyId=@companyId order by pricingDate desc

-------------------Free Cash Flow Yield--------------------
SELECT @freeCashFlow=fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag = 1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =4422 -- Free Cash Flow (Levered i.e after paying taxes and debt obligation)
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId =@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

SET @freeCashFlowYield = @freeCashFlow/@marketCap


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
and ti.tradingItemId=@tradingItemID
order by pe.pricingDate desc

SELECT TOP 1 @shareCountDecline= mc2.sharesOutstanding - mc1.sharesOutstanding
FROM (
    SELECT sharesOutstanding, ROW_NUMBER() OVER (ORDER BY pricingDate DESC) AS RowNum
    FROM [Xpressfeed].[dbo].[ciqMarketCap]
    WHERE companyId = @companyId
) mc1
JOIN (
    SELECT sharesOutstanding, ROW_NUMBER() OVER (ORDER BY pricingDate DESC) AS RowNum
    FROM [Xpressfeed].[dbo].[ciqMarketCap]
    WHERE companyId = @companyId AND pricingDate < DATEADD(YEAR, -1, GETDATE())
) mc2 ON mc1.RowNum = 1 AND mc2.RowNum = 1

set @shareCountDecline = -1*@shareCountDecline

 INSERT INTO #highDivGrowthHighFCFFYield (tickerSymbol, dividendPerShare5YearCAGR,marketCap,freeCashFlow,PE_Ratio_12_Mo,shareCountDecline,freeCashFlowYield,asOfDate)
  VALUES (@tickerSymbol, @dividendPerShare5YearCAGR,@marketCap,@freeCashFlow,@PE_Ratio_12_Mo,@shareCountDecline,@freeCashFlowYield,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END


----------------Standardize and Rank-----------
;WITH Standardized AS (
    SELECT *,
           (dividendPerShare5YearCAGR - Min(dividendPerShare5YearCAGR) OVER ()) / (Max(dividendPerShare5YearCAGR) OVER () - Min(dividendPerShare5YearCAGR) OVER ()) AS Standardized_dividendPerShare5YearCAGR,
           (marketCap - Min(marketCap) OVER ()) / (Max(marketCap) OVER () - Min(marketCap) OVER ()) AS Standardized_marketCap,
           (freeCashFlow - Min(freeCashFlow) OVER ()) / (Max(freeCashFlow) OVER () - Min(freeCashFlow) OVER ()) AS Standardized_freeCashFlow,
		   (PE_Ratio_12_Mo - Min(PE_Ratio_12_Mo) OVER ()) / (Max(PE_Ratio_12_Mo) OVER () - Min(PE_Ratio_12_Mo) OVER ()) AS Standardized_PE_Ratio_12_Mo,
		   (shareCountDecline - Min(shareCountDecline) OVER ()) / (Max(shareCountDecline) OVER () - Min(shareCountDecline) OVER ()) AS Standardized_shareCountDecline,
		   (freeCashFlowYield - Min(freeCashFlowYield) OVER ()) / (Max(freeCashFlowYield) OVER () - Min(freeCashFlowYield) OVER ()) AS Standardized_freeCashFlowYield
    FROM [QIAR_TEST].[dbo].[snHighDivGrowthHighFCFFYield]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_dividendPerShare5YearCAGR + Standardized_marketCap + Standardized_freeCashFlow + Standardized_PE_Ratio_12_Mo
	   +Standardized_shareCountDecline + Standardized_freeCashFlowYield ) DESC) AS Rank
FROM Standardized
ORDER BY Rank;


--select * from [QIAR_TEST].[dbo].[snHighDivGrowthHighFCFFYield]

-- select * from #highDivGrowthHighFCFFYield


--select * into [QIAR_TEST].[dbo].[snHighDivGrowthHighFCFFYield] from #highDivGrowthHighFCFFYield

-- drop table [QIAR_TEST].[dbo].[snHighDivGrowthHighFCFFYield]