-------------------------(25)Stocks commonly held by hedge fund investors------------------------
DECLARE @Counter INT
DECLARE @TotalRows INT
DECLARE @companyId INT
DECLARE @tickerSymbol VARCHAR(255)
DECLARE @numberOfHedgeFundOwners INT


-- Create a temporary table to store the results

IF OBJECT_ID('tempdb..#hedgeFundOwners') IS NOT NULL DROP TABLE #hedgeFundOwners;
CREATE TABLE #hedgeFundOwners(
    tickerSymbol VARCHAR(255),
	numberOfHedgeFundOwners INT,
	asOfDate DATE
)


-- Initialize the variables
SET @Counter = 1

-- Get the total number of rows
SELECT @TotalRows = COUNT(*) FROM [QIAR_TEST].[dbo].[snSnP500Consitutents]

-- Start the loop
WHILE @Counter <= @TotalRows
BEGIN

	SET @numberOfHedgeFundOwners=null
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

SELECT @numberOfHedgeFundOwners=count(ch.ownerObjectId) 
FROM ciqOwnCompanyHolding ch
JOIN ciqOwnHoldingPeriod hp ON ch.periodId = hp.periodId
JOIN ciqCompany c ON ch.ownedCompanyId = c.companyId
Join ciqOwnCompanyToInstType ci on ci.companyId = ch.ownerObjectId and ci.institutionTypeId=3 --Hedge Funds
WHERE ch.ownedCompanyId = @companyId-- Company Identifier
AND CAST(hp.periodStartDate AS DATE) = '2017'
AND ch.rankSharesHeld is not null

 INSERT INTO #hedgeFundOwners (tickerSymbol,numberOfHedgeFundOwners,asOfDate)
  VALUES (@tickerSymbol,@numberOfHedgeFundOwners,GETDATE());

    -- Increment the counter
    SET @Counter = @Counter + 1
END

select * from #hedgeFundOwners order by numberOfHedgeFundOwners desc
--select * into [QIAR_TEST].[dbo].[snHedgeFundOwnership] from #hedgeFundOwners
-- drop table [QIAR_TEST].[dbo].[snHedgeFundOwnership]

select * , RANK() OVER (ORDER BY numberOfHedgeFundOwners DESC) as Rank from [QIAR_TEST].[dbo].[snHedgeFundOwnership]