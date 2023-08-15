----------------(23) High ICE and Cash Usage---------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
declare @incrementalFreeCashFlow Float
declare @returnOnEquity Float
Declare @shareCountDecline INT
Declare @ROIC Float
Declare @payoutRatio Float
Declare @internalGrowthRate Float

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#highICEAndCashusage') IS NOT NULL DROP TABLE #highICEAndCashusage;
CREATE TABLE #highICEAndCashusage (
    tickerSymbol VARCHAR(255),
	incrementalFreeCashFlow Float,
	returnOnEquity Float,
	internalGrowthRate Float,
	shareCountDecline Int,
	ROIC Float,
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
	set @incrementalFreeCashFlow = null
	set @returnOnEquity  = null
	set @shareCountDecline  = null
	set @ROIC  = null
	set @internalGrowthRate = null

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

-----------------------Incremental Free Cash Flow (Quaterly)-----------------


;WITH CTE AS (
    SELECT
        e.dataItemValue AS freeCashFlow,
        LEAD(e.dataItemValue) OVER (ORDER BY b.periodEndDate DESC) AS nextFreeCashFlow
    FROM [Xpressfeed].[dbo].[ciqFinPeriod] a
    JOIN [Xpressfeed].[dbo].[ciqFinInstance] b ON a.financialPeriodId = b.financialPeriodId
    JOIN [Xpressfeed].[dbo].[ciqFinInstanceToCollection] c ON b.financialInstanceId = c.financialInstanceId
    JOIN [Xpressfeed].[dbo].[ciqFinCollection] d ON c.financialCollectionId = d.financialCollectionId
    JOIN [Xpressfeed].[dbo].[ciqFinCollectionData] e ON d.financialCollectionId = e.financialCollectionId
    JOIN [Xpressfeed].[dbo].[ciqCompany] f ON a.companyId = f.companyId
    JOIN [Xpressfeed].[dbo].[ciqDataItem] g ON e.dataItemId = g.dataItemId
    WHERE a.periodTypeId = 2 -- Q
	and b.latestForFinancialPeriodFlag=1
        AND a.companyId = @companyId
        AND g.dataItemId = 4422 -- Free Cash Flow (Levered)
)
SELECT top 1
    @incrementalFreeCashFlow = freeCashFlow - nextFreeCashFlow
FROM CTE;

---roe---------
SELECT top 1 @returnOnEquity=fd.dataItemValue/fd2.dataItemId
FROM [Xpressfeed].[dbo].[ciqCompany] c join [Xpressfeed].[dbo].[ciqSecurity] s on c.companyId = s.companyId and s.primaryFlag=1
join [Xpressfeed].[dbo].[ciqLatestInstanceFinPeriod] fp on fp.companyId = c.companyId
join [Xpressfeed].[dbo].[ciqPeriodType] pt on pt.periodTypeId = fp.periodTypeId
join [Xpressfeed].[dbo].[ciqFinancialData] fd on fd.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqFinancialData] fd2 on fd2.financialPeriodId=fp.financialPeriodId
join [Xpressfeed].[dbo].[ciqDataItem] di on di.dataItemId = fd.dataItemId
WHERE fd.dataItemId =15 --Net Income
and fd2.dataItemId=48859 -- shareholder equity
AND c.companyId=@companyId
and fp.latestPeriodFlag = 1
and pt.periodTypeId=2 --Q
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

Set @internalGrowthRate = @returnOnEquity*(1-@payoutRatio)


-------------------------Return on Invested Capital for a company (ROIC)-----------------------
SELECT top 1 @ROIC=(b.ibcom / b.icapt)
FROM [Xpressfeed].[dbo].[ciqCompany] a
join [Xpressfeed].[dbo].[ciqGvkeyIID] gv on gv.relatedCompanyId=a.companyId
JOIN [Xpressfeed].[dbo].[co_afnd1] b ON gv.gvkey = b.gvkey
WHERE a.companyId = @companyId
AND b.datafmt = 'STD'
ORDER BY b.datadate DESC

---------share buy back--------------
SELECT TOP 1 @shareCountDecline=   mc2.sharesOutstanding - mc1.sharesOutstanding
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


INSERT INTO #highICEAndCashusage (tickerSymbol,incrementalFreeCashFlow,returnOnEquity,internalGrowthRate,shareCountDecline,ROIC,asOfDate)
  VALUES (@tickerSymbol,@incrementalFreeCashFlow,@returnOnEquity,@internalGrowthRate,@shareCountDecline,@ROIC,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

select * from #highICEAndCashusage

--select * from [QIAR_TEST].[dbo].[snhighICEAndCashusage]

--select * into [QIAR_TEST].[dbo].[snhighICEAndCashusage] from #highICEAndCashusage

--drop table [QIAR_TEST].[dbo].[snhighICEAndCashusage] 

---- Ranking---------------
;WITH Standardized AS (
    SELECT *,
           (incrementalFreeCashFlow - Min(incrementalFreeCashFlow) OVER ()) / (Max(incrementalFreeCashFlow) OVER () - Min(incrementalFreeCashFlow) OVER ()) AS Standardized_incrementalFreeCashFlow,
           (returnOnEquity - Min(returnOnEquity) OVER ()) / (Max(returnOnEquity) OVER () - Min(returnOnEquity) OVER ()) AS Standardized_returnOnEquity,
		   (internalGrowthRate - Min(internalGrowthRate) OVER ()) / (Max(internalGrowthRate) OVER () - Min(internalGrowthRate) OVER ()) AS Standardized_internalGrowthRate,
           (shareCountDecline - Min(shareCountDecline) OVER ()) / (Max(shareCountDecline) OVER () - Min(shareCountDecline) OVER ()) AS Standardized_shareCountDecline,
           (ROIC - Min(ROIC) OVER ()) / (Max(ROIC) OVER () - Min(ROIC) OVER ()) AS Standardized_ROIC
    FROM [QIAR_TEST].[dbo].[snhighICEAndCashusage] 
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_incrementalFreeCashFlow + Standardized_returnOnEquity  + Standardized_internalGrowthRate + Standardized_shareCountDecline + Standardized_ROIC) DESC) AS Rank
FROM Standardized
ORDER BY Rank;




