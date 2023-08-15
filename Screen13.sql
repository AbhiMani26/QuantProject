-------------------------------------------------(13) Low PEG and High Earning Quality-----------------------------------------

DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
Declare @tradingItemID INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @earningQuality FLOAT
DECLARE @PE_Ratio_by_growth FLOAT

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#lowPEGHighEQ') IS NOT NULL DROP TABLE #lowPEGHighEQ;
CREATE TABLE #lowPEGHighEQ (
    tickerSymbol VARCHAR(255),
    earningQuality FLOAT,
    PE_Ratio_by_growth  FLOAT,
	asOfDate DATE
)

-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN
	SET @earningQuality = null
	SET @PE_Ratio_by_growth = null
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

select top 1 @earningQuality = (fd3.dataitemvalue - fd4.dataItemValue)/fd5.dataItemValue
, @PE_Ratio_by_growth = (pe.priceclose/fd.dataitemvalue)/fd2.dataItemValue 
from [Xpressfeed].[dbo].[ciqcompany] c
left join [Xpressfeed].[dbo].[ciqlatestinstancefinperiod] lfp on lfp.companyid = c.companyid
left join [Xpressfeed].[dbo].[ciqfinancialdata] fd on fd.financialperiodid = lfp.financialperiodid
left join [Xpressfeed].[dbo].[ciqfinancialdata] fd2 on fd2.financialperiodid = lfp.financialperiodid 
left join [Xpressfeed].[dbo].[ciqfinancialdata] fd3 on fd3.financialperiodid = lfp.financialperiodid
left join [Xpressfeed].[dbo].[ciqfinancialdata] fd4 on fd4.financialperiodid = lfp.financialperiodid
left join [Xpressfeed].[dbo].[ciqfinancialdata] fd5 on fd5.financialperiodid = lfp.financialperiodid
left join [Xpressfeed].[dbo].[ciqsecurity] s on s.companyid = c.companyid and s.primaryflag =1 
left join [Xpressfeed].[dbo].[ciqtradingitem] ti on ti.securityid = s.securityid and ti.primaryflag = 1
left join [Xpressfeed].[dbo].[ciqpriceequity] pe on pe.tradingitemid = ti.tradingitemid 
where 1=1
and lfp.periodtypeid = 2 --Q 
and fd.dataitemid = 8 --EPS
and fd2.dataItemId = 4387 ---long term eps growth rate (used as earning grwoth rate)
and fd3.dataItemId = 2006 ---Cash Flow from Operation
and fd4.dataItemid=15 -- Net Income
and fd5.dataItemid = 1007 -- Total Assets
and lfp.latestperiodflag = 1
and ti.tradingItemId=@tradingItemID
and c.companyid=@companyId
order by pe.pricingDate desc


INSERT INTO #lowPEGHighEQ (tickerSymbol, earningQuality,PE_Ratio_by_growth , asOfDate)
  VALUES (@tickerSymbol, @earningQuality, @PE_Ratio_by_growth,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

select * from #lowPEGHighEQ

SELECT *
FROM [QIAR_TEST].[dbo].[snLowPEGHighEQ] where PE_Ratio_by_growth is not null and earningQuality is not null
ORDER BY PE_Ratio_by_growth ASC, earningQuality DESC;


--select * into [QIAR_TEST].[dbo].[snLowPEGHighEQ] from #lowPEGHighEQ

-- drop table [QIAR_TEST].[dbo].[snLowPEGHighEQ]


--------------Standardize and Rank--------------
;WITH Standardized AS (
    SELECT *,
           (PE_Ratio_by_growth - Min(PE_Ratio_by_growth) OVER ()) / (Max(PE_Ratio_by_growth) OVER () - Min(PE_Ratio_by_growth) OVER ()) AS Standardized_PEG,
           (earningQuality - Min(earningQuality) OVER ()) / (Max(earningQuality) OVER () - Min(earningQuality) OVER ()) AS Standardized_EQ
    FROM [QIAR_TEST].[dbo].[snLowPEGHighEQ] where PE_Ratio_by_growth is not null and earningQuality is not null
)
SELECT *,
       RANK() OVER (ORDER BY (Standardized_EQ - Standardized_PEG) DESC) AS Rank
FROM Standardized
ORDER BY Rank;

--------------Rank and Add-------------
;WITH Ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY PE_Ratio_by_growth ASC) as rank_PEG,
           RANK() OVER (ORDER BY earningQuality DESC) as rank_EQ
    FROM [QIAR_TEST].[dbo].[snLowPEGHighEQ]
)
SELECT *,
       RANK() OVER (ORDER BY (rank_PEG + rank_EQ) ASC) AS Total_Rank
FROM Ranked
ORDER BY Total_Rank;

