DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @tradingItemID INT
DECLARE @companyName VARCHAR(255)
Declare @barraid VARCHAR(255)
DECLARE @marketCap FLOAT
DECLARE @TEV FLOAT
DECLARE @stockPrice FLOAT
DECLARE @sharesOutstanding FLOAT
DECLARE @totalCurrentLiabilities FLOAT
DECLARE @totalCurrentAssest FLOAT
DECLARE @netCurrentAssest FLOAT
DECLARE @totalDebt FLOAT
DECLARE @totalEquity FLOAT
DECLARE @debtEquityRatio FLOAT
DECLARE @netIncome FLOAT
DECLARE @commonOutstandingShares FLOAT
DECLARE @earningYield FLOAT
DECLARE @annualizedDivUSD FLOAT 
DECLARE @divYield FLOAT
DECLARE @earningPerShare FLOAT
DECLARE @PE_Ratio FLOAT
DECLARE @revenueGrowth FLOAT
DECLARE @momentum FLOAT
DECLARE @AVG_GAIN FLOAT
DECLARE @AVG_LOSS FLOAT
DECLARE @RSI  FLOAT
DECLARE @EBITDA FLOAT
DECLARE @ROIC FLOAT
DECLARE @PBV FLOAT
DECLARE @lt_CAGR FLOAT
DECLARE @lt_EPS_CAGR FLOAT
DECLARE @st_revenue_CAGR FLOAT
DECLARE @cashFlowOperations FLOAT
DECLARE @PE_Ratio_by_growth FLOAT
DECLARE @returnOnEquity FLOAT
DECLARE @epsgrowth FLOAT
DECLARE @shortInterest FLOAT
DECLARE @netCapitalExpenditure FLOAT 
DECLARE @RnD_Stock_Factor_Recent_12_Quarters FLOAT
DECLARE @cashAquisitions FLOAT
DECLARE @dividendPerShare5YearCAGR FLOAT
DECLARE @debtRepayment FLOAT
DECLARE @buyBackCashUsage FLOAT
DECLARE @epsGrowth3Year FLOAT
DECLARE @numberOfExecutiveChangesLast22Years FLOAT
DECLARE @salesRevenue FLOAT
DECLARE @enterpriseValueSalesRatio FLOAT
DECLARE @currentRatio FLOAT
DECLARE @cashEquivalent FLOAT
DECLARE @sharePurchasedlastQuater FLOAT
DECLARE @divGrowthLast22Years FLOAT
DECLARE @MonthlyDividendYield FLOAT
DECLARE @LTDivYieldAverage FLOAT
DECLARE @payoutRatio FLOAT
DECLARE @freeCashFlow FLOAT
DECLARE @NTM_PE_Ratio FLOAT
DECLARE @incrementalFreeCashFlow FLOAT
Declare @securityId Int
Declare @buyRating FLOAT
Declare @ROCE Float
Declare @freeCashFlowYield Float
Declare @acclerationOfBuyBack Float
Declare @annualDivGrowth Float
Declare @PE_Ratio_12_Mo Float
Declare @earningQuality Float
Declare @totalAsset Float
Declare @intangibleAsset Float
Declare @ROTA Float

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#CrossSectionalUniverseDescriptors') IS NOT NULL DROP TABLE #CrossSectionalUniverseDescriptors;
CREATE TABLE #CrossSectionalUniverseDescriptors (
	asOfDate DATE,
	companyName VARCHAR(255),
	tickerSymbol VARCHAR(255),
	tradingItemID INT,
	--barraid VARCHAR(255),
	marketCap FLOAT,
	TEV FLOAT,
	stockPrice FLOAT,
	sharesOutstanding FLOAT,
	totalCurrentLiabilities FLOAT,
	totalCurrentAssest FLOAT,
	netCurrentAssest FLOAT,
	totalDebt FLOAT,
	totalEquity FLOAT,
	debtEquityRatio FLOAT,
	netIncome FLOAT,
	commonOutstandingShares FLOAT,
	earningYield FLOAT,
	annualizedDivUSD FLOAT ,
	divYield FLOAT,
	earningPerShare FLOAT,
	PE_Ratio FLOAT,
	revenueGrowth FLOAT,
	momentum FLOAT,
	AVG_GAIN FLOAT,
	AVG_LOSS FLOAT,
	RSI  FLOAT,
	EBITDA FLOAT,
	ROIC FLOAT,
	PBV FLOAT,
	lt_CAGR FLOAT,
	lt_EPS_CAGR FLOAT,
	st_revenue_CAGR FLOAT,
	cashFlowOperations FLOAT,
	PE_Ratio_by_growth FLOAT,
	returnOnEquity FLOAT,
	epsgrowth FLOAT,
	shortInterest FLOAT,
	netCapitalExpenditure FLOAT ,
	RnD_Stock_Factor_Recent_12_Quarters FLOAT,
	cashAquisitions FLOAT,
	dividendPerShare5YearCAGR FLOAT,
	debtRepayment FLOAT,
	buyBackCashUsage FLOAT,
	epsGrowth3Year FLOAT,
	numberOfExecutiveChangesLast22Years FLOAT,
	salesRevenue FLOAT,
	enterpriseValueSalesRatio FLOAT,
	currentRatio FLOAT,
	cashEquivalent FLOAT,
	sharePurchasedlastQuater FLOAT,
	divGrowthLast22Years FLOAT,
	MonthlyDividendYield FLOAT,
	LTDivYieldAverage FLOAT,
	payoutRatio FLOAT,
	freeCashFlow FLOAT,
	NTM_PE_Ratio FLOAT,
	incrementalFreeCashFlow FLOAT,
	buyRating Float,
	ROCE Float,
	freeCashFlowYield Float,
	acclerationOfBuyBack Float,
	annualDivGrowth Float,
	PE_Ratio_12_Mo Float,
	earningQuality Float,
	totalAsset Float,
	intangibleAsset Float,
	ROTA Float
)


-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
 -- Initialize the variables for each iteration
	SET @companyName = null
	SET @marketCap = null
	SET @TEV = null
	SET @stockPrice = null
	SET @sharesOutstanding = null
	SET @totalCurrentLiabilities = null
	SET @totalCurrentAssest = null
	SET @netCurrentAssest = null
	SET @totalDebt = null
	SET @totalEquity = null
	SET @debtEquityRatio = null
	SET @netIncome = null
	SET @commonOutstandingShares = null
	SET @earningYield = null
	SET @annualizedDivUSD = null 
	SET @divYield = null
	SET @earningPerShare = null
	SET @PE_Ratio = null
	SET @revenueGrowth = null
	SET @momentum = null
	SET @AVG_GAIN = null
	SET @AVG_LOSS = null
	SET @RSI  = null
	SET @EBITDA = null
	SET @ROIC = null
	SET @PBV = null
	SET @lt_CAGR = null
	SET @lt_EPS_CAGR = null
	SET @st_revenue_CAGR = null
	SET @cashFlowOperations = null
	SET @PE_Ratio_by_growth = null
	SET @returnOnEquity = null
	SET @epsgrowth = null
	SET @shortInterest = null
	SET @netCapitalExpenditure = null 
	SET @RnD_Stock_Factor_Recent_12_Quarters = null
	SET @cashAquisitions = null
	SET @dividendPerShare5YearCAGR = null
	SET @debtRepayment = null
	SET @buyBackCashUsage = null
	SET @epsGrowth3Year = null
	SET @numberOfExecutiveChangesLast22Years = null
	SET @salesRevenue = null
	SET @enterpriseValueSalesRatio = null
	SET @currentRatio = null
	SET @cashEquivalent = null
	SET @sharePurchasedlastQuater = null
	SET @divGrowthLast22Years = null
	SET @MonthlyDividendYield = null
	SET @LTDivYieldAverage = null
	SET @payoutRatio = null
	SET @freeCashFlow = null
	SET @NTM_PE_Ratio = null
	SET @incrementalFreeCashFlow = null
	SET @buyRating = null
	SET @ROCE=null
	SET @freeCashFlowYield=null
	set @acclerationOfBuyBack = null
	Set @annualDivGrowth=null
	Set @PE_Ratio_12_Mo = null 
	Set @earningQuality = null
	Set @totalAsset= null
	Set @intangibleAsset = null
	Set @ROTA = null

    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol,
		@tradingItemID = tradingItemID,
		@securityId = securityId
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY companyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter

----marketCap for company-----------
select top 1 @marketCap=m.marketCap,@TEV= m.TEV,@sharesOutstanding=m.sharesOutstanding from ciqMarketCap m where companyId=@companyId order by pricingDate desc


-----netCurrentAssestValue of each stock--
  SELECT @totalCurrentLiabilities = fd.dataItemValue, @totalCurrentAssest=fd2.dataItemValue  , @netCurrentAssest=fd2.dataItemValue-fd.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd2 on fd2.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=1009 -- Total Current Liabilities
and fd2.dataItemId=1008 -- Total Current Assets
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

------------------Earning Yield---------------------------------------
SELECT @netIncome=fd.dataItemValue, @commonOutstandingShares=fd2.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd2 on fd2.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=15 --NetIncome
and fd2.dataItemId=1070  --common outstanding shares
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

select top 1  @earningYield=(fd.dataitemvalue/pe.priceclose) * 100
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


---------------------price to earning ratio--------------------
select top 1 @companyName= c.companyname
, @earningPerShare=fd.dataitemvalue 
, @PE_Ratio=(pe.priceclose/fd.dataitemvalue) 
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


-------------------------Revenue Growth------------------------------------
 
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

------------------Net Income 7 Year CAGR-----------------
SELECT @lt_CAGR=fd.dataItemValue , @lt_EPS_CAGR=fd2.dataItemValue , @st_revenue_CAGR=fd3.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd2 on fd2.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd3 on fd3.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=4251 --long term CAGR
and fd2.dataItemId=4387 -- long term EPS CAGR
and fd3.dataItemId=4207 -- short term revenue growth (CAGR)
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

-----------------PE Ratio/Growth-----------------

select top 1  @cashFlowOperations=fd3.dataitemvalue 
, @PE_Ratio_by_growth=(pe.priceclose/fd.dataitemvalue)/fd2.dataItemValue  
from ciqcompany c
left join ciqlatestinstancefinperiod lfp on lfp.companyid = c.companyid
left join ciqfinancialdata fd on fd.financialperiodid = lfp.financialperiodid
left join ciqfinancialdata fd2 on fd2.financialperiodid = lfp.financialperiodid 
left join ciqfinancialdata fd3 on fd3.financialperiodid = lfp.financialperiodid
left join ciqsecurity s on s.companyid = c.companyid and s.primaryflag =1 
left join ciqtradingitem ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join ciqpriceequity pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and lfp.periodtypeid = 2 --Quarterly
and fd.dataitemid = 8 --EPS
and fd2.dataItemId = 4387 ---long term eps growth rate
and fd3.dataItemId = 2006 ---Cash Flow from Operation
and lfp.latestperiodflag = 1
and c.companyid=@companyId
order by pe.pricingDate desc


----------------Return on Equity, net Income, EPS Growth, Short Interest, Cash Flow from Operation---------------
SELECT top 1 @returnOnEquity=fd.dataItemValue/fd2.dataItemId   ,@epsgrowth=fd3.dataItemValue ,@shortInterest=fd5.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd2 on fd2.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd3 on fd3.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd4 on fd4.financialPeriodId=fp.financialPeriodId
join ciqFinancialData fd5 on fd5.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE fd.dataItemId =15 --Net Income
and fd2.dataItemId=48859 -- shareholder equity
and fd3.dataItemId=4385 -- 3 year EPS growth %
and fd4.dataItemId=2006 -- Cash Flow from Operation Used as Earning Quality Metrics
and fd5.dataItemId=100104 -- Last Close Short Interest (if high then more stocks are bein shorted)
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc




----------------Net Capital Expenditure---------------
SELECT top 1 @netCapitalExpenditure=fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =2008 --Net Capital Expenditure
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc



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


----------------------Debt Repayment-------------------
SELECT @debtRepayment=fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag = 1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =48986 -- Total Debt Repaid
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId =@companyId 
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

--------------------current Ratio and cash equivalent----------------
select top 1 @currentRatio= fd.dataItemValue 
,@cashEquivalent=fd2.dataItemValue 
from ciqcompany c
left join ciqlatestinstancefinperiod lfp on lfp.companyid = c.companyid
left join ciqfinancialdata fd on fd.financialperiodid = lfp.financialperiodid
left join ciqfinancialdata fd2 on fd2.financialperiodid = lfp.financialperiodid
left join ciqsecurity s on s.companyid = c.companyid and s.primaryflag =1 
left join ciqtradingitem ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join ciqpriceequity pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and lfp.periodtypeid = 2 --Q
and fd.dataitemid = 4030 --Current Ratio
and fd2.dataitemid = 1096 --Cash
and lfp.latestperiodflag = 1
and c.companyid=@companyId
order by pe.pricingDate desc


  ----------------Buy Back Cash Usage---------------
SELECT top 1 @buyBackCashUsage=fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =2164 --Repurchase of common stocks
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

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

---------------3 year EPS growth %---------------
SELECT top 1 @epsGrowth3Year=fd3.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd3 on fd3.financialPeriodId=fp.financialPeriodId
WHERE fd3.dataItemId=4385 -- 3 year EPS growth %
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
AND pt.periodTypeId=2 -- Quarterly
ORDER BY fp.periodEndDate desc

----------------sales revenue--------------------
SELECT @salesRevenue= d.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag = 1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
JOIN ciqFinancialData d ON fp.financialPeriodId = d.financialPeriodId
WHERE 1=1 
and c.companyId = @companyId
AND d.dataItemId = 300 --- sales revenue
AND fp.periodTypeId = 2 --Quarterly
AND fp.latestPeriodFlag=1
 order by fp.filingDate desc
------------------------EV/Sales ratio Latest-----------------
SELECT TOP 1  @enterpriseValueSalesRatio=mc.TEV / d.dataItemValue
FROM ciqMarketCap mc
JOIN ciqCompany c ON mc.companyId = c.companyId
JOIN ciqSecurity s ON c.companyId = s.companyId and s.primaryFlag=1
JOIN ciqLatestInstanceFinPeriod fp ON c.companyId = fp.companyId
JOIN ciqFinancialData d ON fp.financialPeriodId = d.financialPeriodId
WHERE mc.companyId = @companyId
  AND d.dataItemId = 300 -- sales revenue
  AND fp.periodTypeId = 2 --Quarterly
  AND fp.latestPeriodFlag = 1
ORDER BY mc.pricingDate DESC, fp.filingDate DESC

-----------------------------Cash Acquisition Costs of a Company (Last Twelve Months)-------------------------------------
SELECT top 1 @cashAquisitions=fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag = 1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =2057 --Cash Acquisitions
AND fp.periodTypeId = 4 --Last Twelve Months
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc




--------------Daily stock price of a company-------------------
    SELECT top 1 @stockPrice = pe.priceClose
    FROM ciqCompany c
    JOIN ciqSecurity s ON c.companyId = s.companyId and s.primaryFlag=1
	join ciqTradingItem ti on s.securityId = ti.securityId
	join ciqPriceEquity pe on ti.tradingItemId = pe.tradingItemId
    WHERE c.companyId = @companyId
	and ti.tickerSymbol=@tickerSymbol
	and pe.tradingItemId=@tradingItemID
    ORDER BY pe.pricingDate desc






----------------debtEquityratio, total debt, total equity------------------------------
    SELECT @totalDebt= e. dataItemValue ,
@totalEquity=e2.dataItemValue , @debtEquityRatio=e.dataItemValue/e2.dataItemValue
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

-------------------------EBITDA of a company-----------------------------

SELECT top 1 @EBITDA=fcd.dataitemvalue 
FROM ciqfinperiod fp
JOIN ciqFinInstance fi ON fp.financialPeriodId = fi.financialPeriodId
JOIN ciqFinInstanceToCollection fitc ON fi.financialInstanceId = fitc.financialInstanceId
JOIN ciqFinCollection fc ON fitc.financialCollectionId = fc.financialCollectionId
JOIN ciqFinCollectionData fcd ON fc.financialCollectionId = fcd.financialCollectionId
WHERE fp.companyId = @companyId
  AND fcd.dataitemId = '4051' -- EBITDA
  AND fp.latestPeriodFlag=1
  And fp.periodTypeId=2 --Quarterly
  AND fi.latestFilingForInstanceFlag=1
  Order by fi.periodEndDate desc

-------------------Price to book value------------------
  SELECT TOP 1
   @PBV= (SELECT TOP 1 pe.priceClose
     FROM ciqCompany c
     JOIN ciqSecurity s ON c.companyId = s.companyId and s.primaryFlag=1
     JOIN ciqTradingItem ti ON s.securityId = ti.securityId
     JOIN ciqPriceEquity pe ON ti.tradingItemId = pe.tradingItemId
     WHERE c.companyId = @companyId
       AND ti.tickerSymbol = @tickerSymbol
       AND pe.tradingItemId = @tradingItemID
     ORDER BY pe.pricingDate DESC) / fcd.dataitemvalue
FROM ciqfinperiod fp
JOIN ciqFinInstance fi ON fp.financialPeriodId = fi.financialPeriodId
JOIN ciqFinInstanceToCollection fitc ON fi.financialInstanceId = fitc.financialInstanceId
JOIN ciqFinCollection fc ON fitc.financialCollectionId = fc.financialCollectionId
JOIN ciqFinCollectionData fcd ON fc.financialCollectionId = fcd.financialCollectionId
WHERE fp.companyId = @companyId
  AND fcd.dataitemId = 4020 -- BVPS
  AND fp.latestPeriodFlag = 1
  AND fp.periodTypeId = 2 --Quarterly
  AND fi.latestFilingForInstanceFlag = 1
ORDER BY fi.periodEndDate DESC

-----Calculate ROCE for the current company-------------
  SELECT @ROCE= fd.dataItemValue  
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=43905 -- ROCE
AND fp.periodTypeId = 2 --Q
AND fp.latestPeriodFlag=1
AND c.companyId=@companyId
ORDER BY fp.periodEndDate desc

---------------------Dividend Yield----------------------
  SELECT TOP 1 
   @annualizedDivUSD= ch.dataItemValue / er1.priceclose,
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

-----------------------------Div Yield ciqFinancial Data-------------------------------------
SELECT top 1 @divYield=fd.dataItemValue 
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag = 1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =4038 --Dividend Yield %
AND fp.periodTypeId = 2 -- Q
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc


-----------------------Momentum of a stock(12M-1M)-----------------------------
;WITH price_data AS (
    SELECT c.companyName, c.companyId, pe.pricingDate, pe.priceClose
    FROM ciqCompany c
    JOIN ciqSecurity s ON c.companyId = s.companyId and s.primaryFlag=1
    JOIN ciqTradingItem ti ON s.securityId = ti.securityId
    JOIN ciqPriceEquity pe ON ti.tradingItemId = pe.tradingItemId
    WHERE c.companyId = @companyId
    AND ti.tickerSymbol = @tickerSymbol
    AND pe.tradingItemId = @tradingItemID
    AND pe.pricingDate BETWEEN DATEADD(MONTH, -12, GETDATE()) AND DATEADD(MONTH, -1, GETDATE())
), daily_returns AS (
    SELECT pricingDate, priceClose - LAG(priceClose) OVER (ORDER BY pricingDate) AS daily_return
    FROM price_data
)
SELECT @momentum = SUM(daily_return)
FROM daily_returns;

--------------------------------RSI--------------------------
declare @date as date
SET @date = getdate()
 
 
Declare @dateMinus2months as date
Set @dateMinus2months = DATEADD(MONTH,-3,@date)
 
If object_id('tempdb.dbo.#demo', 'U')IS NOT NULL
drop table #demo
If object_id('tempdb.dbo.#MovingAverage', 'U')IS NOT NULL
drop table #MovingAverage
If object_id('tempdb.dbo.#DynamicAverage', 'U')IS NOT NULL
drop table #DynamicAverage
Create Table #DynamicAverage
(
AVG_GAIN  float,
AVG_LOSS float,
Pricingdate  date,
rank int,
gain float,
loss float,
CompanyID INT
)
 
;WITH CTE_DATE_RANGE(PricingDate,PriceClose,ROW_NUM,companyId) 
AS
(
SELECT  E.pricingDate,E.priceClose,ROW_NUMBER()OVER(ORDER BY pricingDate DESC) AS ROW_NUM,C.companyId
 
 
FROM ciqPriceEquity E
JOIN ciqTradingItem T
ON T.tradingItemId=E.tradingItemId 
JOIN  ciqSecurity S
ON S.securityId=T.securityId
JOIN ciqCompany C
ON C.companyId=S.companyId
WHERE C.companyId =@companyId 
and T.primaryflag = 1 and  S.primaryflag = 1
AND E.pricingDate BETWEEN @dateMinus2months and @date
),
CTE_FINAL_DATERANGE
AS
(
select * from CTE_DATE_RANGE where ROW_NUM between 1 and 33
)
,CTE_PRICECLOSE_CALCULATION
AS
(
select *, PriceClose - LAG(PriceClose,1) over(order by pricingdate)  CalculationPriceClose  from CTE_FINAL_DATERANGE
)
,CTE_LOSS_GAIN (pricingdate,priceclose,Companyid,Rank,Loss,Gain)
AS
(
select PricingDate,PriceClose,COmpanyid, ROW_NUMBER() over(order by ROW_NUM DESC) rank,case when 0> CalculationPriceClose then CalculationPriceClose END Loss, 
case when 0< CalculationPriceClose then CalculationPriceClose END gain from CTE_PRICECLOSE_CALCULATION
)
select LG.* ,SUB.AVG_GAIN AVG_GAIN_WORKING_COLUMN_NEED_TO_TWEAK,ABS(SUB.AVG_LOSS) AVG_LOSS INTO #demo
from (
select LG1.Companyid,CAST(LG.pricingdate as date) PricingDate, SUM(LG1.Gain)/NULLIF((COUNT(LG.pricingdate) - 1),0) AVG_GAIN,SUM(LG1.loss)/NULLIF((COUNT(LG.pricingdate) - 1),0) AVG_LOSS from CTE_LOSS_GAIN  LG
JOIN CTE_LOSS_GAIN LG1 
ON LG.pricingdate >= LG1.pricingdate
--where LG.RANK = 15
group by LG.pricingdate,LG1.Companyid) SUB
JOIN CTE_LOSS_GAIN LG on SUB.PricingDate = LG.pricingdate
 
order by PricingDate DEsc
 
 
declare @rowcount as int
declare @i as int = 15
declare @MedianValue_Gain as float
declare @MedianValue_Loss as float
declare @MovingAverage_Gain as float
declare @MovingAverage_loss as float
declare @gain as float
declare @loss as float
declare @pricingdate as date
 
 
Set @rowcount = (select max(rank) from #demo)
---set @MedianValue_Gain = (select AVG_GAIN_WORKING_COLUMN_NEED_TO_TWEAK,pricingdate from #demo where Rank = 15)
INSERT INTO #DynamicAverage
select AVG_GAIN_WORKING_COLUMN_NEED_TO_TWEAK,AVG_LOSS,pricingdate,rank,ISNULL(Gain,0),ABS(ISNULL(LOSS,0)) LOSS, Companyid from #demo ---where Rank = 15
 
WHILE @I <= @rowcount
 
BEGIN
 
 
set @MedianValue_Gain = (select AVG_GAIN from #DynamicAverage where Rank = @i)
set @MedianValue_Loss = (select AVG_LOSS from #DynamicAverage where Rank = @i)
 
set @gain = (select gain from #DynamicAverage where rank = @i + 1 )
set @loss = (select loss from #DynamicAverage where rank = @i + 1 )
set @date = (select pricingdate from #DynamicAverage where rank = @i)
set @MovingAverage_Gain  = ((@MedianValue_Gain * 13) + @gain )/14
set @MovingAverage_Loss  = ((@MedianValue_Loss * 13) + @loss )/14
 
update #DynamicAverage set avg_GAIN = @MovingAverage_Gain where rank = @i + 1
update #DynamicAverage set avg_Loss = @MovingAverage_Loss where rank = @i + 1
 
 
set @i = @i + 1
 
END
 
--select * from #demo order by rank
select top 1 @AVG_GAIN=AVG_GAIN,@AVG_LOSS=AVG_LOSS, @RSI=CASE WHEN AVG_LOSS =0 THEN 100 ELSE 100-(100/(1+AVG_GAIN/AVG_LOSS))  END 
from #DynamicAverage where rank >= 15 order by Pricingdate Desc




-------------------------Return on Invested Capital for a company (ROIC)-----------------------
SELECT top 1 @ROIC= (b.ibcom / b.icapt)
FROM ciqCompany a
join ciqGvkeyIID gv on gv.relatedCompanyId=a.companyId
JOIN co_afnd1 b ON gv.gvkey = b.gvkey
WHERE a.companyId = @companyId
AND b.datafmt = 'STD'
ORDER BY b.datadate DESC



--------------------Returns Cumulative Twelve Quarter R&D Spending With Linear Decay Weighting----------

;WITH CTE_DATA
AS
(

select top 12
  C.companyname,
  F.companyid,
  F.periodtypeid,
  E.periodenddate,
  F.fiscalchainseriesid,
  pt.periodTypeName,
  fiscalquarter,
  calendaryear,
  dataItemValue Research_And_Development_Expense ,
  ROW_NUMBER() OVER(partition by C.companyid order by periodenddate DESC) Row_number,
  ABS(ROW_NUMBER() OVER(partition by C.companyid order by periodenddate DESC) - 13) Num
from
  CIQCOMPANY C
  JOIN ciqFinPeriod F on C.companyId = F.companyId
  JOIN ciqFinInstance e on e.financialPeriodId = F.financialPeriodId
  JOIN ciqFinInstanceToCollection FI on FI.financialInstanceId = E.financialInstanceId
  JOIN ciqFinCollection FC on FI.financialCollectionId = FC.financialCollectionId
  JOIN ciqfincollectiondata FD on FD.financialCollectionId = FC.financialCollectionId
  join ciqDataItem D on FD.dataItemId = D.dataItemId
  join ciqPeriodType pt on F.periodTypeId = pt.periodTypeId
where 1=1
  and c.companyId = @companyId
  and FD.dataItemId=100
  and F.periodTypeId = 2 -- Quaterly
  --and latestForFinancialPeriodFlag = 1
  --and latestForFinancialPeriodFlag = 1
  --and F.latestPeriodFlag=1
  order by F.calendarYear desc
 ) 
 SELECT distinct @RnD_Stock_Factor_Recent_12_Quarters=
 SUM(CAL)  OVER(partition by SUB.companyId)
 FROM
 (
 select *
 , CASE WHEN NUM = 12 THEN Research_And_Development_Expense ELSE (Research_And_Development_Expense * NUM)/12 END CAL from CTE_DATA where ROW_NUMBER <= 12 --Current quarter R&D expense + prior_quater R&D*11/12 + two_quarter_ago R&D*10/12+…+ eleven_quarter_ago R&D*1/12
 ) SUB





-------------------num of ceo changed since 2000--------

SELECT @numberOfExecutiveChangesLast22Years=COUNT(*)
FROM ciqProfessional p
JOIN ciqProToProFunction pf ON p.proId = pf.proId
WHERE p.companyId = @companyId
  AND pf.endYear IS NOT NULL
  AND pf.proFunctionId IN (1, 3, 8, 9)
  AND pf.startYear > 2000;





---------------Average EV/Sales calculation for last 5 years------------------
-- Calculate EV for the latest year
DECLARE @latestEV FLOAT
SELECT TOP 1 @latestEV = TEV
FROM ciqMarketCap
WHERE companyId = @companyId
ORDER BY pricingDate DESC

-- Calculate Sales for each year over the past five years
DECLARE @sales TABLE (financialPeriodId INT, salesRevenue FLOAT)
INSERT INTO @sales (financialPeriodId, salesRevenue)
SELECT f.financialPeriodId, d.dataItemValue AS salesRevenue
FROM ciqLatestInstanceFinPeriod f
JOIN ciqFinancialData d ON f.financialPeriodId = d.financialPeriodId
WHERE f.companyId = @companyId
  AND d.dataItemId = 300 -- Sales Revenue
  AND YEAR(f.periodEndDate) >= YEAR(DATEADD(YEAR, -5, GETDATE()))
  AND f.financialPeriodId IN (
    SELECT financialPeriodId
    FROM ciqLatestInstanceFinPeriod
    WHERE companyId = @companyId
	and latestPeriodFlag=1 and periodTypeId=3 --year to date
  )
ORDER BY f.periodEndDate DESC

-- Calculate the EV/Sales ratio for each year
DECLARE @evSalesRatios TABLE ( evSalesRatio FLOAT)
INSERT INTO @evSalesRatios ( evSalesRatio)
SELECT  @latestEV / s.salesRevenue AS evSalesRatio
FROM @sales s
JOIN ciqFinPeriod fp ON s.financialPeriodId = fp.financialPeriodId

-- Calculate the average EV/Sales ratio
DECLARE @averageEvSalesRatio FLOAT
SELECT @averageEvSalesRatio = AVG(evSalesRatio)
FROM @evSalesRatios


-------------------shares purchased each Quater----------
SELECT TOP 1 @sharePurchasedlastQuater= mc1.sharesOutstanding - mc2.sharesOutstanding
FROM (
    SELECT sharesOutstanding, ROW_NUMBER() OVER (ORDER BY pricingDate DESC) AS RowNum
    FROM ciqMarketCap
    WHERE companyId = @companyId
) mc1
JOIN (
    SELECT sharesOutstanding, ROW_NUMBER() OVER (ORDER BY pricingDate DESC) AS RowNum
    FROM ciqMarketCap
    WHERE companyId = @companyId AND pricingDate < DATEADD(MONTH, -3, GETDATE())
) mc2 ON mc1.RowNum = 1 AND mc2.RowNum = 1



--------Divdend Yield Growth Last 22 Years---------------
-- Create a temporary table to store dividend per share growth values
IF OBJECT_ID('tempdb..#dividendGrowth') IS NOT NULL DROP TABLE #dividendGrowth;
CREATE TABLE #dividendGrowth (
    calendarYear INT,
    dividendPerShareGrowth FLOAT
)
-- Insert the dividend per share growth values for the past 22 years into the temporary table
INSERT INTO #dividendGrowth (calendarYear, dividendPerShareGrowth)
 SELECT f.calendarYear as calenderYear, d.dataItemValue as divdendPerShareGrowth
FROM ciqLatestInstanceFinPeriod f
JOIN ciqFinancialData d ON f.financialPeriodId = d.financialPeriodId
WHERE f.companyId = @companyId
  --AND f.periodTypeId = 3
  AND d.dataItemId = 4206 ---divdend per share growth annual
  AND f.financialPeriodId in (
    SELECT TOP 22  financialPeriodId
    FROM ciqLatestInstanceFinPeriod
    WHERE companyId = @companyId
      AND periodTypeId = 1 -- Annual
    ORDER BY calendarYear DESC
  ) order by calendarYear desc
-- Calculate the CAGR
Declare @begining Float
Declare @ending Float
Declare @NumberOfYears INT
set @begining = null
set @ending = null 
set @NumberOfYears = null
set @NumberOfYears = (select count(*) from #dividendGrowth)
set @begining = (select top 1 dividendPerShareGrowth  from #dividendGrowth where dividendPerShareGrowth > 0 order by calendarYear asc)
set @ending = (select top 1 dividendPerShareGrowth  from #dividendGrowth  order by calendarYear desc)
BEGIN TRY
    SET @divGrowthLast22Years = POWER((@ending / @begining), (1.0 / (@NumberOfYears - 1))) - 1
END TRY
BEGIN CATCH
    SET @divGrowthLast22Years = 0
END CATCH
----------------Long Term Dividend Yield Average-------------
IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1;
SELECT
    YEAR(pe.pricingDate) AS Year,
    MONTH(pe.pricingDate) AS Month,
    AVG(ch.dataItemValue / er1.priceclose) AS MonthlyDividendYield
	into #temp1
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
    AND pe.pricingDate >= DATEADD(YEAR, -10, GETUTCDATE())
GROUP BY YEAR(pe.pricingDate), MONTH(pe.pricingDate)
ORDER BY Year DESC, Month DESC;

select @MonthlyDividendYield=MonthlyDividendYield from #temp1
--select * from #temp1
set @LTDivYieldAverage = ( select avg(MonthlyDividendYield) from #temp1)
DROP TABLE #temp1




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

-----------------------Incremental Free Cash Flow (Quaterly)-----------------

-- Create a temp table to store the free cash flow data
IF OBJECT_ID('tempdb..#FreeCashFlow') IS NOT NULL DROP TABLE #FreeCashFlow;
CREATE TABLE #FreeCashFlow (
    freeCashFlow DECIMAL(18, 2),
    periodEndDate DATE
);

-- Insert the free cash flow data into the temp table
INSERT INTO #FreeCashFlow (freeCashFlow, periodEndDate)
SELECT TOP 2
    fd.dataItemValue AS freeCashFlow,
    fp.periodEndDate
FROM
    ciqCompany c
    JOIN ciqSecurity s ON c.companyId = s.companyId AND s.primaryFlag = 1
    JOIN ciqLatestInstanceFinPeriod fp ON fp.companyId = c.companyId
    JOIN ciqPeriodType pt ON pt.periodTypeId = fp.periodTypeId
    JOIN ciqFinancialData fd ON fd.financialPeriodId = fp.financialPeriodId
WHERE
    fd.dataItemId = 4422 -- Free Cash Flow (Levered i.e after paying taxes and debt obligation)
    AND fp.periodTypeId = 2 --Quarterly
    AND c.companyId = @companyId
ORDER BY
    fp.periodEndDate DESC;

-- Calculate the incremental cash flow
SELECT
    @incrementalFreeCashFlow=(SELECT TOP 1 freeCashFlow FROM #FreeCashFlow ORDER BY periodEndDate DESC) -
    (SELECT TOP 1 freeCashFlow FROM #FreeCashFlow ORDER BY periodEndDate ASC);

-- Drop the temp table
DROP TABLE #FreeCashFlow;
----------------------New Added Descriptors-----------------

---Buy ratings------------------
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
and nd.dataitemid = 100313 -- # of Analysts Buy Recommendation - (In-Consensus)
and nd.todate > '1-JAN-2079' 
and c.companyid=@companyId
order by pe.pricingdate desc

IF OBJECT_ID('tempdb..#Buybacks') IS NOT NULL DROP TABLE #Buybacks;
CREATE TABLE #Buybacks (
	id int,
    buyBack FLOAT
)
INSERT INTO #Buybacks (id, buyBack)
SELECT top 3 ROW_NUMBER() OVER (ORDER BY fp.filingDate DESC), fd.dataItemValue  
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =2164 --Repurchase of common stocks
AND fp.periodTypeId =2--Annual
AND c.companyId=@companyId
order by fp.fiscalYear DESC, fp.fiscalQuarter desc

Declare @s1 float
Declare @s3 float
select top 1 @s1 = buyback from #Buybacks
SELECT @s3 = buyBack FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY id ASC) AS rn
    FROM #Buybacks
) AS Numbered
WHERE rn =3

set @acclerationOfBuyBack = @s1 + @s3

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
-------PE ratio Last twelve months---------------
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


SELECT top 1  @earningQuality=(fd4.dataItemValue-fd.dataItemValue)/fd6.dataItemvalue
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd4 on fd4.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd6 on fd6.financialPeriodId=fp.financialPeriodId
WHERE fd.dataItemId =15 --Net Income
and fd4.dataItemId=2006 -- Cash Flow from Operation Used as Earning Quality Metrics
AND fd6.dataItemId = 1007 --Total Assets
AND fp.periodTypeId = 2 --Q
AND c.companyId=@companyId



SELECT top 1 @totalAsset = fd6.dataItemValue
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd6 on fd6.financialPeriodId=fp.financialPeriodId
WHERE 1=1
AND fd6.dataItemId = 1007 --Total Assets
AND fp.periodTypeId = 2 --Q
And fp.latestPeriodFlag=1
AND c.companyId=@companyId order by periodEndDate desc

SELECT top 1 @intangibleAsset = fd4.dataItemValue
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd4 on fd4.financialPeriodId=fp.financialPeriodId
WHERE 1=1
and fd4.dataItemId=3089 -- Goodwill and Intangible asset
AND fp.periodTypeId = 2 --Q
and fp.latestPeriodFlag=1
AND c.companyId=@companyId order by periodEndDate desc

set @ROTA = @netIncome/(@totalAsset- @intangibleAsset)


INSERT INTO #CrossSectionalUniverseDescriptors (
    asOfDate,
    companyName,
	tickerSymbol,
	tradingItemID,
    marketCap,
    TEV,
    stockPrice,
    sharesOutstanding,
    totalCurrentLiabilities,
    totalCurrentAssest,
    netCurrentAssest,
    totalDebt,
    totalEquity,
    debtEquityRatio,
    netIncome,
    commonOutstandingShares,
    earningYield,
    annualizedDivUSD,
    divYield,
	earningPerShare,
    PE_Ratio,
    revenueGrowth,
    momentum,
    AVG_GAIN,
    AVG_LOSS,
    RSI,
    EBITDA,
    ROIC,
    PBV,
    lt_CAGR,
    lt_EPS_CAGR,
    st_revenue_CAGR,
    cashFlowOperations,
    PE_Ratio_by_growth,
    returnOnEquity,
    epsgrowth,
    shortInterest,
    netCapitalExpenditure,
    RnD_Stock_Factor_Recent_12_Quarters,
    cashAquisitions,
    dividendPerShare5YearCAGR,
    debtRepayment,
    buyBackCashUsage,
    epsGrowth3Year,
    numberOfExecutiveChangesLast22Years,
    salesRevenue,
    enterpriseValueSalesRatio,
    currentRatio,
    cashEquivalent,
    sharePurchasedlastQuater,
    divGrowthLast22Years,
    MonthlyDividendYield,
    LTDivYieldAverage,
    payoutRatio,
    freeCashFlow,
    NTM_PE_Ratio,
    incrementalFreeCashFlow,
	buyRating,
	ROCE,
	freeCashFlowYield,
	acclerationOfBuyBack,
	annualDivGrowth,
	PE_Ratio_12_Mo,
	earningQuality,
	totalAsset,
	intangibleAsset,
	ROTA

)
VALUES (
	GETDATE(),
    @companyName,
	@tickerSymbol,
	@tradingItemID,
    @marketCap,
    @TEV,
    @stockPrice,
    @sharesOutstanding,
    @totalCurrentLiabilities,
    @totalCurrentAssest,
    @netCurrentAssest,
    @totalDebt,
    @totalEquity,
    @debtEquityRatio,
    @netIncome,
    @commonOutstandingShares,
    @earningYield,
    @annualizedDivUSD,
    @divYield,
    @earningPerShare,
    @PE_Ratio,
    @revenueGrowth,
    @momentum,
    @AVG_GAIN,
    @AVG_LOSS,
    @RSI,
    @EBITDA,
    @ROIC,
    @PBV,
    @lt_CAGR,
    @lt_EPS_CAGR,
    @st_revenue_CAGR,
    @cashFlowOperations,
    @PE_Ratio_by_growth,
    @returnOnEquity,
    @epsgrowth,
    @shortInterest,
    @netCapitalExpenditure,
    @RnD_Stock_Factor_Recent_12_Quarters,
    @cashAquisitions,
    @dividendPerShare5YearCAGR,
    @debtRepayment,
    @buyBackCashUsage,
    @epsGrowth3Year,
    @numberOfExecutiveChangesLast22Years,
    @salesRevenue,
    @enterpriseValueSalesRatio,
    @currentRatio,
    @cashEquivalent,
    @sharePurchasedlastQuater,
    @divGrowthLast22Years,
    @MonthlyDividendYield,
    @LTDivYieldAverage,
    @payoutRatio,
    @freeCashFlow,
    @NTM_PE_Ratio,
    @incrementalFreeCashFlow,
	@buyRating,
	@ROCE,
	@freeCashFlowYield,
	@acclerationOfBuyBack,
	@annualDivGrowth,
	@PE_Ratio_12_Mo,
	@earningQuality,
	@totalAsset,
	@intangibleAsset,
	@ROTA
);


    -- Increment the counter
    SET @Counter = @Counter + 1
END

select * from #CrossSectionalUniverseDescriptors	



--insert  into [QIAR_TEST].[dbo].[snCrossSectionalUniverseDescriptors]  
--select * into [QIAR_TEST].[dbo].[snCrossSectionalUniverseDescriptors] from #CrossSectionalUniverseDescriptors

--select * from [QIAR_TEST].[dbo].[snCrossSectionalUniverseDescriptors] where tickerSymbol = 'MNST'


--select * from [QIAR_TEST].[dbo].[snCrossSectionalUniverseCoverage]

-- drop table [QIAR_TEST].[dbo].[snCrossSectionalUniverseDescriptors]


