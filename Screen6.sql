-------------------------(6) Out of Favour Stocks------------------------------------------

IF OBJECT_ID('tempdb..#outOfFavourStocks') IS NOT NULL
    DROP TABLE #outOfFavourStocks;

CREATE TABLE #outOfFavourStocks (
    companyId INT,
    tickerSymbol VARCHAR(50),
    RSI DECIMAL(18, 2),
    momentum DECIMAL(18, 2),
    peRatio DECIMAL(18, 2),
	asOfDate DATE
);

DECLARE @companyId INT;
DECLARE @tickerSymbol VARCHAR(50);
DECLARE @tradingItemID INT;
DECLARE @RSI DECIMAL(18, 2);
DECLARE @momentum DECIMAL(18, 2);
DECLARE @peRatio DECIMAL(18, 2);

DECLARE companyCursor CURSOR FOR
    SELECT companyId, tickerSymbol, tradingItemID
    FROM [QIAR_TEST].[dbo].[snSnP500Consitutents];

OPEN companyCursor;

FETCH NEXT FROM companyCursor INTO @companyId, @tickerSymbol,@tradingItemID;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Calculate RSI
    DECLARE @date AS DATE
    SET @date = GETDATE()
    DECLARE @COMPANYID2 AS INT
    SET @COMPANYID2 = @companyId

    DECLARE @dateMinus2months AS DATE
    SET @dateMinus2months = DATEADD(MONTH, -3, @date)

    IF OBJECT_ID('tempdb..#demo') IS NOT NULL DROP TABLE #demo
    IF OBJECT_ID('tempdb..#MovingAverage') IS NOT NULL  DROP TABLE #MovingAverage
    IF OBJECT_ID('tempdb..#DynamicAverage') IS NOT NULL DROP TABLE #DynamicAverage

    CREATE TABLE #DynamicAverage (
        AVG_GAIN FLOAT,
        AVG_LOSS FLOAT,
        Pricingdate DATE,
        rank INT,
        gain FLOAT,
        loss FLOAT,
        CompanyID INT
    )

    ;WITH CTE_DATE_RANGE (PricingDate, PriceClose, ROW_NUM, companyId)
    AS (
        SELECT E.pricingDate, E.priceClose, ROW_NUMBER() OVER (ORDER BY pricingDate DESC) AS ROW_NUM, C.companyId
        FROM [Xpressfeed].[dbo].[ciqPriceEquity] E
        JOIN [Xpressfeed].[dbo].[ciqTradingItem] T ON T.tradingItemId = E.tradingItemId
        JOIN [Xpressfeed].[dbo].[ciqSecurity] S ON S.securityId = T.securityId
        JOIN [Xpressfeed].[dbo].[ciqCompany] C ON C.companyId = S.companyId
        WHERE C.companyId = @COMPANYID2
        AND T.primaryflag = 1
        AND S.primaryflag = 1
		AND T.tradingItemId=@tradingItemID
        AND E.pricingDate BETWEEN @dateMinus2months AND @date
    ),
    CTE_FINAL_DATERANGE
    AS (
        SELECT *
        FROM CTE_DATE_RANGE
        WHERE ROW_NUM BETWEEN 1 AND 33
    ),
    CTE_PRICECLOSE_CALCULATION
    AS (
        SELECT *, PriceClose - LAG(PriceClose, 1) OVER (ORDER BY pricingdate) CalculationPriceClose
        FROM CTE_FINAL_DATERANGE
    ),
    CTE_LOSS_GAIN (pricingdate, priceclose, Companyid, Rank, Loss, Gain)
    AS (
        SELECT PricingDate, PriceClose, COmpanyid, ROW_NUMBER() OVER (ORDER BY ROW_NUM DESC) rank,
        CASE WHEN 0 > CalculationPriceClose THEN CalculationPriceClose END Loss, 
        CASE WHEN 0 < CalculationPriceClose THEN CalculationPriceClose END gain
        FROM CTE_PRICECLOSE_CALCULATION
    )
    SELECT LG.*, SUB.AVG_GAIN AVG_GAIN_WORKING_COLUMN_NEED_TO_TWEAK, ABS(SUB.AVG_LOSS) AVG_LOSS into #demo
    FROM (
        SELECT LG1.Companyid, CAST(LG.pricingdate AS DATE) PricingDate, SUM(LG1.Gain) / NULLIF((COUNT(LG.pricingdate) - 1), 0) AVG_GAIN,
        SUM(LG1.loss) / NULLIF((COUNT(LG.pricingdate) - 1), 0) AVG_LOSS
        FROM CTE_LOSS_GAIN LG
        JOIN CTE_LOSS_GAIN LG1 ON LG.pricingdate >= LG1.pricingdate
        GROUP BY LG.pricingdate, LG1.Companyid
    ) SUB
    JOIN CTE_LOSS_GAIN LG ON SUB.PricingDate = LG.pricingdate
    ORDER BY PricingDate DESC;

    DECLARE @rowcount AS INT;
    DECLARE @i AS INT = 15;
    DECLARE @MedianValue_Gain AS FLOAT;
    DECLARE @MedianValue_Loss AS FLOAT;
    DECLARE @MovingAverage_Gain AS FLOAT;
    DECLARE @MovingAverage_Loss AS FLOAT;
    DECLARE @gain AS FLOAT;
    DECLARE @loss AS FLOAT;
    DECLARE @pricingdate AS DATE;

    SET @rowcount = (SELECT MAX(rank) FROM #demo);

    INSERT INTO #DynamicAverage
    SELECT AVG_GAIN_WORKING_COLUMN_NEED_TO_TWEAK, AVG_LOSS, pricingdate, rank, ISNULL(Gain, 0), ABS(ISNULL(LOSS, 0)) LOSS, Companyid
    FROM #demo;

    WHILE @i <= @rowcount
    BEGIN
        SET @MedianValue_Gain = (SELECT AVG_GAIN FROM #DynamicAverage WHERE Rank = @i);
        SET @MedianValue_Loss = (SELECT AVG_LOSS FROM #DynamicAverage WHERE Rank = @i);
        SET @gain = (SELECT gain FROM #DynamicAverage WHERE rank = @i + 1);
        SET @loss = (SELECT loss FROM #DynamicAverage WHERE rank = @i + 1);
        SET @pricingdate = (SELECT pricingdate FROM #DynamicAverage WHERE rank = @i);
        SET @MovingAverage_Gain = ((@MedianValue_Gain * 13) + @gain) / 14;
        SET @MovingAverage_Loss = ((@MedianValue_Loss * 13) + @loss) / 14;

        UPDATE #DynamicAverage SET avg_GAIN = @MovingAverage_Gain WHERE rank = @i + 1;
        UPDATE #DynamicAverage SET avg_Loss = @MovingAverage_Loss WHERE rank = @i + 1;

        SET @i = @i + 1;
    END;

    SELECT TOP 1 CompanyID, PricingDate, Gain, Loss, AVG_GAIN, AVG_LOSS, AVG_GAIN / AVG_LOSS AS RS,
    CASE WHEN AVG_LOSS = 0 THEN 100 ELSE 100 - (100 / (1 + AVG_GAIN / AVG_LOSS)) END AS RSI
    INTO #RSI_temp
    FROM #DynamicAverage
    WHERE rank >= 15
    ORDER BY Pricingdate DESC;

    -- Calculate PE ratio
DECLARE @PE_Ratio DECIMAL(18, 2);
SET @PE_Ratio=null

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

 ----------------------Momentum of a stock(12M-1M)-----------------------------
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

    INSERT INTO #outOfFavourStocks (companyId, tickerSymbol, RSI, momentum, peRatio,asOfDate)
    VALUES (@companyId, @tickerSymbol, (SELECT RSI FROM #RSI_temp), @momentum, @PE_Ratio,GETDATE());

    DROP TABLE IF EXISTS #RSI_temp;

    FETCH NEXT FROM companyCursor INTO @companyId, @tickerSymbol, @tradingItemID;
END;

CLOSE companyCursor;
DEALLOCATE companyCursor;

SELECT tickerSymbol, RSI, momentum, peRatio
FROM #outOfFavourStocks;



--------------------strategy for out of favour stocks----------------------------------

SELECT tickerSymbol, RSI, momentum, peRatio
FROM (
  SELECT tickerSymbol, RSI, momentum, peRatio,
    ROW_NUMBER() OVER (ORDER BY peRatio ASC) AS rank_valuation
  FROM [QIAR_TEST].[dbo].[snOutOfFavourStocks]
  WHERE RSI <= (
    SELECT MAX(RSI)
    FROM (
      SELECT RSI, NTILE(100) OVER (ORDER BY RSI) AS percentile
      FROM [QIAR_TEST].[dbo].[snOutOfFavourStocks]
    ) AS percentiles
    WHERE percentile <= 25
  )
    AND momentum <= (
      SELECT MAX(momentum)
      FROM (
        SELECT momentum, NTILE(100) OVER (ORDER BY momentum) AS percentile
        FROM [QIAR_TEST].[dbo].[snOutOfFavourStocks]
      ) AS percentiles
      WHERE percentile <= 25
    )
    AND peRatio < (
      SELECT AVG(peRatio)
      FROM [QIAR_TEST].[dbo].[snOutOfFavourStocks]
    )
) AS filtered_stocks
WHERE rank_valuation <= (SELECT COUNT(*) / 4 FROM [QIAR_TEST].[dbo].[snOutOfFavourStocks]) order by peRatio asc


--select * into [QIAR_TEST].[dbo].[snOutOfFavourStocks] from #outOfFavourStocks

select * from #outOfFavourStocks

drop table [QIAR_TEST].[dbo].[snOutOfFavourStocks]

-----------------Ranking 1: Standardise and then add them together followed by Ranking-----------------
;WITH Normalized AS (
    SELECT
        tickerSymbol, RSI, momentum, peRatio,
        (RSI - MIN(RSI) OVER ()) / (MAX(RSI) OVER () - MIN(RSI) OVER ()) AS normalizedRSI,
        (momentum - MIN(momentum) OVER ()) / (MAX(momentum) OVER () - MIN(momentum) OVER ()) AS normalizedMomentum,
        (peRatio - MIN(peRatio) OVER ()) / (MAX(peRatio) OVER () - MIN(peRatio) OVER ()) AS normalizedPeRatio,
        asOfDate
    FROM
        [QIAR_TEST].[dbo].[snOutOfFavourStocks]
)
SELECT
    tickerSymbol, RSI, momentum, peRatio,
    normalizedRSI + normalizedMomentum + normalizedPeRatio AS combinedNormalizedValues,
    asOfDate,
    RANK() OVER (ORDER BY normalizedRSI + normalizedMomentum + normalizedPeRatio DESC) AS rank
FROM
    Normalized;

--------------Ranking 2: Rank Individually and Add Ranks-------------
;WITH Ranks AS (
    SELECT
        tickerSymbol, RSI, momentum, peRatio,
        RANK() OVER (ORDER BY RSI DESC) AS rankRSI,
        RANK() OVER (ORDER BY momentum DESC) AS rankMomentum,
        RANK() OVER (ORDER BY peRatio ASC) AS rankPeRatio,
        asOfDate
    FROM
        [QIAR_TEST].[dbo].[snOutOfFavourStocks]
)
SELECT
    tickerSymbol, RSI, momentum, peRatio,
    rankRSI + rankMomentum + rankPeRatio AS sumRanks,
    asOfDate,
    RANK() OVER (ORDER BY rankRSI + rankMomentum + rankPeRatio ASC) AS finalRank
FROM
    Ranks;






