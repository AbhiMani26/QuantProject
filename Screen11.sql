--------------------------(11) Accelerating Growth--------------------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
Declare @NTM_Market_EPS Float
Declare @mrqEpsGrowth Float
Declare @secondDerivativeEPSGrowth Float
Declare @NTM_EPS Float
Declare @earningQuality Float
Declare @totalAssets Float


-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#accelaratedGrowth') IS NOT NULL DROP TABLE #accelaratedGrowth;
CREATE TABLE #accelaratedGrowth (
    tickerSymbol VARCHAR(255),
	NTM_Market_EPS FLOAT,
	mrqEpsGrowth Float,
	secondDerivativeEPSGrowth Float,
	NTM_EPS Float,
	earningQuality Float,
	totalAssets Float,
	asOfDate DATETIME
)


-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]


----------NTM Market EPS------------
select   top 1  @NTM_Market_EPS=m.value from 
[Xpressfeed].[dbo].[MSCIIndexMonthlyValue] m 
join [Xpressfeed].[dbo].[MSCIIndexTradingItem] ic on m.tradingItemId = ic.tradingItemId
where 1=1
and m.dataItemId=112227 --12 months forward Index EPS
and ic.indexID = 379976095 -- MSCI Usa Index
order by m.valueDate Desc

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
 -- Initialize the variables for each iteration
	SET @mrqEpsGrowth  = Null
	SET @secondDerivativeEPSGrowth  = Null
	SET @NTM_EPS  = Null
	SET @earningQuality  = Null
	SET @totalAssets = Null
    -- Get the values for each iteration
    SELECT
        @companyId = companyId,
        @tickerSymbol = tickerSymbol
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY companyId) AS RowNum
        FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]
    ) AS Subquery
    WHERE RowNum = @Counter


------MRQ EPS-------------
;WITH latest_eps AS (
  SELECT TOP 1
    fd3.dataItemValue as eps,
    fp.periodEndDate as date
  FROM [Xpressfeed].[dbo].[ciqCompany] c 
  JOIN [Xpressfeed].[dbo].[ciqSecurity] s ON c.companyId = s.companyId
  JOIN [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp ON fp.companyId = c.companyId
  JOIN [Xpressfeed].[dbo].[ciqPeriodType] pt ON pt.periodTypeId = fp.periodTypeId
  JOIN [Xpressfeed].[dbo].[ciqFinancialData] fd3 ON fd3.financialPeriodId=fp.financialPeriodId
  WHERE 1=1
    AND fd3.dataItemId=8 -- EPS
    AND fp.periodTypeId = 2 --Q
    AND c.companyId=@companyId
	AND s.primaryFlag=1
    AND fp.latestPeriodFlag=1
  ORDER BY fp.periodEndDate DESC
),
previous_year_eps AS (
  SELECT TOP 1
    fd3.dataItemValue as eps,
    fp.periodEndDate as date
  FROM [Xpressfeed].[dbo].[ciqCompany] c 
  JOIN [Xpressfeed].[dbo].[ciqSecurity] s ON c.companyId = s.companyId
  JOIN [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp ON fp.companyId = c.companyId
  JOIN [Xpressfeed].[dbo].[ciqPeriodType] pt ON pt.periodTypeId = fp.periodTypeId
  JOIN [Xpressfeed].[dbo].[ciqFinancialData] fd3 ON fd3.financialPeriodId=fp.financialPeriodId
  WHERE 1=1
    AND fd3.dataItemId=8 -- EPS
    AND fp.periodTypeId = 2 --Q
    AND c.companyId=@companyId
	AND s.primaryFlag=1
    AND fp.periodEndDate = DATEADD(year, -1, (SELECT date FROM latest_eps))
  ORDER BY fp.periodEndDate DESC
)
SELECT 
  @mrqEpsGrowth= (latest_eps.eps - previous_year_eps.eps) / previous_year_eps.eps
FROM latest_eps, previous_year_eps;


--------------second derivative of EPS growth-------------
;WITH eps_data AS (
  SELECT TOP 4
    fd3.dataItemValue as eps,
    fp.periodEndDate as date
  FROM [Xpressfeed].[dbo].[ciqCompany] c 
  JOIN [Xpressfeed].[dbo].[ciqSecurity] s ON c.companyId = s.companyId
  JOIN [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp ON fp.companyId = c.companyId
  JOIN [Xpressfeed].[dbo].[ciqPeriodType] pt ON pt.periodTypeId = fp.periodTypeId
  JOIN [Xpressfeed].[dbo].[ciqFinancialData] fd3 ON fd3.financialPeriodId=fp.financialPeriodId
  WHERE 1=1
    AND fd3.dataItemId=8 -- EPS
    AND fp.periodTypeId = 2 --Q
    AND c.companyId=@companyId
	And s.primaryFlag=1
  ORDER BY fp.periodEndDate DESC
),
eps_growth AS (
  SELECT 
    eps,
    date,
    LAG(eps, 1) OVER (ORDER BY date) as prev_eps
  FROM eps_data
),
eps_growth_rate AS (
  SELECT 
    date,
    (eps - prev_eps) / prev_eps as growth_rate
  FROM eps_growth
),
eps_growth_rate_change AS (
  SELECT 
    date,
    growth_rate,
    LAG(growth_rate, 1) OVER (ORDER BY date) as prev_growth_rate
  FROM eps_growth_rate
)
SELECT TOP 1 @secondDerivativeEPSGrowth = (growth_rate - prev_growth_rate) 
FROM eps_growth_rate_change
ORDER BY date DESC;


--------------Next Twelve Months EPS-----------------

select top 1  @NTM_EPS = nd.dataitemvalue
from [Xpressfeed].[dbo].[ciqcompany] c
left join [Xpressfeed].[dbo].[ciqestimateperiod] ep on ep.companyid = c.companyid
left join [Xpressfeed].[dbo].[ciqEstimateperiodrelconst] epr on epr.estimateperiodid = ep.estimateperiodid and epr.periodtypeid = ep.periodtypeid
left join [Xpressfeed].[dbo].[ciqEstimateConsensus] ec on ec.estimateperiodid = ep.estimateperiodid
left join [Xpressfeed].[dbo].[ciqEstimateNumericData] nd on nd.estimateconsensusid = ec.estimateconsensusid --(financial forecasting measures in ciqEstimateNumericData)
left join [Xpressfeed].[dbo].[ciqsecurity] s on s.companyid = c.companyid and s.primaryflag =1 
left join [Xpressfeed].[dbo].[ciqtradingitem] ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join [Xpressfeed].[dbo].[ciqpriceequity] pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and ep.periodtypeid = 12 --NTM
and nd.dataitemid = 100173  --EPS Normalized Consensus Mean (the average prediction of a company's future earnings per share, as made by financial analysts)
and nd.todate > '1-JAN-2079' 
and c.companyid=@companyId
order by pe.pricingdate desc


------Earning Quality---------
SELECT top 1   @earningQuality= (fd4.dataItemValue - fd.dataItemValue )/fd2.dataItemValue , @totalAssets=fd3.dataItemvalue 
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd4 on fd4.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd3 on fd3.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd2 on fd2.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqDataItem] di on di.dataItemId = fd4.dataItemId
WHERE 1=1
and fd4.dataItemId=2006 -- Cash Flow from Operation Used as Earning Quality Metrics
and fd3.dataItemid=1007 -- total Assets
and fd.dataItemId =15 --Net Income
AND fd2.dataItemId = 1007 --Total Assets
AND fp.periodTypeId = 1 --Annual
AND c.companyId=@companyId
ORDER BY fp.periodEndDate desc


INSERT INTO #accelaratedGrowth (tickerSymbol,NTM_Market_EPS, mrqEpsGrowth, secondDerivativeEPSGrowth, NTM_EPS, earningQuality, totalAssets,asOfDate)
  VALUES (@tickerSymbol,@NTM_Market_EPS, @mrqEpsGrowth, @secondDerivativeEPSGrowth, @NTM_EPS, @earningQuality, @totalAssets,GETDATE());
    -- Increment the counter
    SET @Counter = @Counter + 1
END

select * from #accelaratedGrowth order by earningQuality desc

--select * into [QIAR_TEST].[dbo].[snAccelaratedGrowth] from #accelaratedGrowth

--drop table [QIAR_TEST].[dbo].[snAccelaratedGrowth]


SELECT *
FROM [QIAR_TEST].[dbo].[snAccelaratedGrowth]
WHERE 1=1 --NTM_EPS > NTM_Market_EPS
AND earningQuality > 0.02
AND tickerSymbol IN (
  SELECT tickerSymbol
  FROM (
    SELECT tickerSymbol,
      NTILE(5) OVER (ORDER BY mrqEpsGrowth DESC) AS mrqEpsGrowthQuintile,
      NTILE(5) OVER (ORDER BY secondDerivativeEPSGrowth DESC) AS secondDerivativeEPSGrowthQuintile
    FROM #accelaratedGrowth
  ) AS Subquery
  WHERE mrqEpsGrowthQuintile = 1 AND secondDerivativeEPSGrowthQuintile = 1
)

------------Standardize and rank---------
;WITH Standardized AS (
    SELECT *,
           (mrqEpsGrowth - Min(mrqEpsGrowth) OVER ()) / (Max(mrqEpsGrowth) OVER () - Min(mrqEpsGrowth) OVER ()) AS Standardized_mrqEpsGrowth,
           (secondDerivativeEPSGrowth - Min(secondDerivativeEPSGrowth) OVER ()) / (Max(secondDerivativeEPSGrowth) OVER () - Min(secondDerivativeEPSGrowth) OVER ()) AS Standardized_secondDerivativeEPSGrowth,
           (NTM_EPS - Min(NTM_EPS) OVER ()) / (Max(NTM_EPS) OVER () - Min(NTM_EPS) OVER ()) AS Standardized_NTM_EPS,
           (earningQuality - Min(earningQuality) OVER ()) / (Max(earningQuality) OVER () - Min(earningQuality) OVER ()) AS Standardized_earningQuality,
           (totalAssets - Min(totalAssets) OVER ()) / (Max(totalAssets) OVER () - Min(totalAssets) OVER ()) AS Standardized_totalAssets
    FROM [QIAR_TEST].[dbo].[snAccelaratedGrowth]
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_mrqEpsGrowth + Standardized_secondDerivativeEPSGrowth + Standardized_NTM_EPS + Standardized_earningQuality + Standardized_totalAssets) DESC) AS Rank
FROM Standardized
ORDER BY Rank;

-----------Rank Individually-----------------
WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY mrqEpsGrowth DESC) as rank_mrqEpsGrowth,
           RANK() OVER (ORDER BY secondDerivativeEPSGrowth DESC) as rank_secondDerivativeEPSGrowth,
           RANK() OVER (ORDER BY NTM_EPS DESC) as rank_NTM_EPS,
           RANK() OVER (ORDER BY earningQuality DESC) as rank_earningQuality,
           RANK() OVER (ORDER BY totalAssets DESC) as rank_totalAssets
    FROM [QIAR_TEST].[dbo].[snAccelaratedGrowth]
)
SELECT *,
       RANK() OVER (ORDER BY (rank_mrqEpsGrowth + rank_secondDerivativeEPSGrowth + rank_NTM_EPS + rank_earningQuality + rank_totalAssets) ASC) AS Total_Rank
FROM Ranked
ORDER BY Total_Rank;
