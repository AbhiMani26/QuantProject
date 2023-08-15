
DECLARE @tickerSymbol NVARCHAR(50)
DECLARE @sql NVARCHAR(MAX) = ''
DECLARE @dynamicPivotColumns NVARCHAR(MAX) = ''

-- Cursor to loop through each stock in div_stocks
DECLARE stock_cursor CURSOR FOR 
SELECT tickerSymbol FROM [QIAR_TEST].[dbo].[cap_stocks]

OPEN stock_cursor
FETCH NEXT FROM stock_cursor INTO @tickerSymbol

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @dynamicPivotColumns += '[' + @tickerSymbol + '],'
    FETCH NEXT FROM stock_cursor INTO @tickerSymbol
END

CLOSE stock_cursor
DEALLOCATE stock_cursor

SET @dynamicPivotColumns = LEFT(@dynamicPivotColumns, LEN(@dynamicPivotColumns) - 1)


SET @sql = '
WITH StockPrices AS (
    SELECT 
        v.tickerSymbol,
        s.tradingItemID,
        p.pricingDate,
        p.priceClose,
        LAG(p.priceClose, 1, NULL) OVER (PARTITION BY v.tickerSymbol ORDER BY p.pricingDate) AS prevPriceClose
    FROM 
        [QIAR_TEST].[dbo].[cap_stocks] v
    JOIN 
        [QIAR_TEST].[dbo].[snSnP500Consitutents] s ON v.tickerSymbol = s.tickerSymbol
    JOIN 
        ciqPriceEquity p ON s.tradingItemID = p.tradingItemId
    WHERE 
        p.pricingDate >= DATEADD(MONTH, -3, GETDATE())
),
DailyReturns AS (
    SELECT 
        tickerSymbol,
        pricingDate,
        (priceClose - prevPriceClose) / prevPriceClose AS dailyReturn
    FROM 
        StockPrices
)
SELECT 
    pricingDate, ' + @dynamicPivotColumns + '
	into [QIAR_TEST].[dbo].[daily_cap_stock_returns]
FROM 
    (SELECT tickerSymbol, pricingDate, dailyReturn FROM DailyReturns) AS SourceTable
PIVOT
(
    MAX(dailyReturn)
    FOR tickerSymbol IN (' + @dynamicPivotColumns + ')
) AS PivotTable
ORDER BY pricingDate DESC;'
-- Execute the dynamic SQL
EXEC sp_executesql @sql



--select * from [QIAR_TEST].[dbo].[daily_cap_stock_returns] order by pricingDate desc

-- drop table [QIAR_TEST].[dbo].[daily_cap_stock_returns]

--select * from [QIAR_TEST].[dbo].[daily_cap_stock_returns]

--SELECT * FROM [QIAR_TEST].[dbo].[snSnP500Consitutents] where tickerSymbol='GEHC'

-- drop table [QIAR_TEST].[dbo].[daily_cap_stock_returns]