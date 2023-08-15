----------------(23) High ICE and Cash Usage---------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
declare @PE_Ratio Float
declare @shareCountDecline Float

-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#financials') IS NOT NULL DROP TABLE #financials;
CREATE TABLE #financials (
    tickerSymbol VARCHAR(255),
	PE_Ratio Float,
	shareCountDecline Float,
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
	set @PE_Ratio = null
	set @shareCountDecline=null


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



SELECT TOP 1 @shareCountDecline=mc2.sharesOutstanding - mc1.sharesOutstanding ----to make positive values higher in rank
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



INSERT INTO #financials (tickerSymbol,PE_Ratio,shareCountDecline,asOfDate)
  VALUES (@tickerSymbol,@PE_Ratio,@shareCountDecline,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

-- select * from #financials
--select * from [QIAR_TEST].[dbo].[snFinancial]

--select * into [QIAR_TEST].[dbo].[snFinancial]  from #financials

--drop table [QIAR_TEST].[dbo].[snFinancial]

;WITH Standardized AS (
    SELECT *,
           (PE_Ratio - Min(PE_Ratio) OVER ()) / (Max(PE_Ratio) OVER () - Min(PE_Ratio) OVER ()) AS Standardized_PE_Ratio,
		   (shareCountDecline - Min(shareCountDecline) OVER ()) / (Max(shareCountDecline) OVER () - Min(shareCountDecline) OVER ()) AS Standardized_shareCountDecline
    FROM [QIAR_TEST].[dbo].[snFinancial]
)
SELECT *,
       RANK() OVER (ORDER BY (shareCountDecline - Standardized_PE_Ratio ) DESC) AS Rank
FROM Standardized
ORDER BY Rank;