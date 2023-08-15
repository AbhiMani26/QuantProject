-------------------------(17) Accelerating Buybacks------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @freeCashFlow FLOAT
DECLARE @currentRatio FLOAT
DECLARE @cashEquivalent FLOAT
DECLARE @sharePurchasedlastQuater INT
DECLARE @netIncome FLOAT
Declare @acclerationOfBuyBack FLOAT


-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#acceleratingBuyBack') IS NOT NULL DROP TABLE #acceleratingBuyBack;
CREATE TABLE #acceleratingBuyBack (
    tickerSymbol VARCHAR(255),
	acclerationOfBuyBack float,
    freeCashFlow FLOAT,
	currentRatio FLOAT,
	cashEquivalent FLOAT,
	netIncome FLOAT,
	asOfDate DATE
)


-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN

	SET @freeCashFlow =null
	SET @currentRatio =null
	SET @cashEquivalent =null
	SET @netIncome =null
	SET @acclerationOfBuyBack = null
    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY CompanyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter

-- Create a temporary table to store the values
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

set @acclerationOfBuyBack = -1*@s1 + -1*@s3 -----to make buy back cash as positive

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

  ---------------Net Income (latest)-----------------
SELECT @netIncome=fd.dataItemValue
FROM ciqCompany c join ciqSecurity s on c.companyId = s.companyId and s.primaryFlag=1
join ciqLatestInstanceFinPeriod fp on fp.companyId = c.companyId
join ciqPeriodType pt on pt.periodTypeId = fp.periodTypeId
join ciqFinancialData fd on fd.financialPeriodId=fp.financialPeriodId
join ciqDataItem di on di.dataItemId = fd.dataItemId
WHERE 1=1
and fd.dataItemId=15 --NetIncome
AND fp.periodTypeId = 2 --Quarterly
AND c.companyId=@companyId
AND fp.latestPeriodFlag=1
ORDER BY fp.periodEndDate desc

 INSERT INTO #acceleratingBuyBack (tickerSymbol,acclerationOfBuyBack,freeCashFlow,currentRatio,cashEquivalent,netIncome,asOfDate)
  VALUES (@tickerSymbol,@acclerationOfBuyBack, @freeCashFlow,@currentRatio,@cashEquivalent,@netIncome,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END


select * from #acceleratingBuyBack

--select * into [QIAR_TEST].[dbo].[snAcceleratingBuyBack] from #acceleratingBuyBack
-- drop table [QIAR_TEST].[dbo].[snAcceleratingBuyBack]



-------------Strategy Ranking-------------
SELECT tickerSymbol, acclerationOfBuyBack, freeCashFlow, currentRatio, cashEquivalent, netIncome, asOfDate,
       RANK() OVER (ORDER BY acclerationOfBuyBack DESC, freeCashFlow DESC, currentRatio DESC, cashEquivalent DESC, netIncome DESC) AS Rank
FROM [QIAR_TEST].[dbo].[snAcceleratingBuyBack]
ORDER BY Rank;


------------------Standardize and Rank----------------
WITH Standardized AS (
    SELECT *,
           (acclerationOfBuyBack - Min(acclerationOfBuyBack) OVER ()) / (Max(acclerationOfBuyBack) OVER () - Min(acclerationOfBuyBack) OVER ()) AS Standardized_acclerationOfBuyBack,
           (freeCashFlow - Min(freeCashFlow) OVER ()) / (Max(freeCashFlow) OVER () - Min(freeCashFlow) OVER ()) AS Standardized_freeCashFlow,
           (currentRatio - Min(currentRatio) OVER ()) / (Max(currentRatio) OVER () - Min(currentRatio) OVER ()) AS Standardized_currentRatio,
           (cashEquivalent - Min(cashEquivalent) OVER ()) / (Max(cashEquivalent) OVER () - Min(cashEquivalent) OVER ()) AS Standardized_cashEquivalent,
           (netIncome - Min(netIncome) OVER ()) / (Max(netIncome) OVER () - Min(netIncome) OVER ()) AS Standardized_netIncome
    FROM [QIAR_TEST].[dbo].[snAcceleratingBuyBack]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_acclerationOfBuyBack + Standardized_freeCashFlow + Standardized_currentRatio + Standardized_cashEquivalent + Standardized_netIncome) DESC) AS Rank
FROM Standardized
ORDER BY Rank;


----------------Rank Individually-----------------
WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY acclerationOfBuyBack DESC) as rank_acclerationOfBuyBack,
           RANK() OVER (ORDER BY freeCashFlow DESC) as rank_freeCashFlow,
           RANK() OVER (ORDER BY currentRatio DESC) as rank_currentRatio,
           RANK() OVER (ORDER BY cashEquivalent DESC) as rank_cashEquivalent,
           RANK() OVER (ORDER BY netIncome DESC) as rank_netIncome
    FROM [QIAR_TEST].[dbo].[snAcceleratingBuyBack] where acclerationOfBuyBack is not null  and freeCashFlow is not null 
	and currentRatio is not null and cashEquivalent is  not null and netIncome is not null
)
SELECT *,
       RANK() OVER (ORDER BY (rank_acclerationOfBuyBack + rank_freeCashFlow + rank_currentRatio + rank_cashEquivalent + rank_netIncome) ASC) AS Total_Rank
FROM Ranked
ORDER BY Total_Rank;
