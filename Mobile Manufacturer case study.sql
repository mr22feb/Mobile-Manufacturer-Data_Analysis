select * from DIM_CUSTOMER
select * from DIM_DATE
select * from DIM_MANUFACTURER
select * from DIM_LOCATION
select * from DIM_MODEL
SELECT * FROM FACT_TRANSACTIONS

--Q1  List all the states in which we have customers who have bought cellphones from 2005 till today.


SELECT y.State ,year(date) as year_purchase 
FROM FACT_TRANSACTIONS AS X 
INNER JOIN DIM_LOCATION AS Y 
ON X.IDLocation = Y.IDLocation
where YEAR(date) >=2005 and year(date) < =GETDATE()


--Q2 2. What state in the US is buying the most 'Samsung' cell phones?

SELECT State,Model_Name ,COUNT(MODEL_NAME) AS COUNTT
FROM FACT_TRANSACTIONS AS X 
INNER JOIN DIM_LOCATION AS Y 
ON X.IDLocation = Y.IDLocation

INNER JOIN DIM_MODEL AS Z
ON X.IDModel =Z.IDModel

WHERE Country ='US'
AND 
Model_Name LIKE 'GAL%'
GROUP BY State , Model_Name 
ORDER BY COUNTT DESC

--3. Show the number of transactions for each model per zip code per state. 


SELECT ZipCode ,IDModel ,COUNT(IDMODEL) AS COUNTT
FROM FACT_TRANSACTIONS AS X
INNER JOIN DIM_LOCATION Y 
ON X.IDLocation = Y.IDLocation
GROUP BY IDModel,ZipCode

--4. Show the cheapest cellphone (Output should contain the price also)


SELECT TOP 1 Model_Name , (Unit_price) AS PRICE
FROM FACT_TRANSACTIONS AS X 
INNER JOIN DIM_MODEL AS Y 
ON X.IDModel = Y.IDModel
ORDER BY PRICE ASC


/*5. Find out the average price for each model in the top5 manufacturers in
terms of sales quantity and order by average price*/

SELECT TOP 5  Model_Name , AVG(TOTALPRICE) AVG_AMT ,SUM(QUANTITY) AS QTY
FROM FACT_TRANSACTIONS AS X 
INNER JOIN DIM_MODEL AS Y 
ON X.IDModel = Y.IDModel
GROUP BY Model_Name
ORDER BY QTY DESC

/*6. List the names of the customers and the average amount spent in 2009,
where the average is higher than 500 */

SELECT Y.Customer_Name,  AVG(X.TotalPrice) AS AVG_AMT 
FROM FACT_TRANSACTIONS AS X 
INNER JOIN DIM_CUSTOMER AS Y 
ON X.IDCustomer = Y.IDCustomer
WHERE YEAR(X.Date) = 2009
GROUP BY Y.Customer_Name 
HAVING AVG(X.TotalPrice)>500
ORDER BY AVG_AMT DESC


/* 7. List if there is any model that was in the top 5 in terms of quantity,
simultaneously in 2008, 2009 and 2010  */

SELECT TOP 5  Model_Name ,SUM(QUANTITY) AS QTY
FROM FACT_TRANSACTIONS AS X 
INNER JOIN DIM_MODEL AS Y 
ON X.IDModel = Y.IDModel
WHERE YEAR(X.Date) IN (2008,2009,2010)
GROUP BY Model_Name
ORDER BY QTY DESC


/* 8. Show the manufacturer with the 2nd top sales in the year of 2009 and the
manufacturer with the 2nd top sales in the year of 2010 */




WITH SalesRanking AS (
    SELECT
        Model_Name,
        SUM(Quantity) AS QTY,
        ROW_NUMBER() OVER (ORDER BY SUM(Quantity) DESC) AS Rank
    FROM
        FACT_TRANSACTIONS AS X
    INNER JOIN
        DIM_MODEL AS Y ON X.IDModel = Y.IDModel
    WHERE YEAR(X.Date) = 2009
	GROUP BY Model_Name

    UNION ALL

    SELECT
        Model_Name,
        SUM(Quantity) AS QTY,
        ROW_NUMBER() OVER (ORDER BY SUM(Quantity) DESC) AS Rank
    FROM
        FACT_TRANSACTIONS AS X
    INNER JOIN
        DIM_MODEL AS Y ON X.IDModel = Y.IDModel
    WHERE
        YEAR(X.Date) = 2010
    GROUP BY
        Model_Name
)
SELECT
    Model_Name,
    SUM(QTY) AS Total_Qty
FROM
    SalesRanking
WHERE
    Rank = 2
GROUP BY
    Model_Name;

/* 9. Show the manufacturers that sold cellphones in 2010 but did not in 2009. */ 


SELECT Z.Manufacturer_Name
FROM FACT_TRANSACTIONS AS X
INNER JOIN DIM_MODEL AS Y 
ON X.IDModel = Y.IDModel
INNER JOIN DIM_MANUFACTURER AS Z 
ON Y.IDManufacturer = Z.IDManufacturer
WHERE YEAR(X.Date) = 2010

EXCEPT 

SELECT Z.Manufacturer_Name
FROM FACT_TRANSACTIONS AS X
INNER JOIN DIM_MODEL AS Y 
ON X.IDModel = Y.IDModel
INNER JOIN DIM_MANUFACTURER AS Z 
ON Y.IDManufacturer = Z.IDManufacturer
WHERE YEAR(X.Date) = 2009

/*
10. Find top 100 customers and their average spend, average quantity by each
year. Also find the percentage of change in their spend.
*/


WITH CustomerSummary AS (
    SELECT
        IDCustomer,
        YEAR(Date) AS SalesYear,
        AVG(TotalPrice) AS AvgSpend,
        AVG(Quantity) AS AvgQuantity,
        ROW_NUMBER() OVER (PARTITION BY YEAR(Date) ORDER BY AVG(TotalPrice) DESC) AS Rank
    FROM
        FACT_TRANSACTIONS -- Replace YourTableNameHere with the actual name of your table
    GROUP BY
        IDCustomer,
        YEAR(Date)
)
SELECT
    IDCustomer,
    SalesYear,
    AvgSpend,
    AvgQuantity,
    CASE
        WHEN LAG(AvgSpend) OVER (PARTITION BY IDCustomer ORDER BY SalesYear) IS NULL THEN NULL
        ELSE ((AvgSpend - LAG(AvgSpend) OVER (PARTITION BY IDCustomer ORDER BY SalesYear)) / LAG(AvgSpend) OVER (PARTITION BY IDCustomer ORDER BY SalesYear)) * 100
    END AS SpendChangePercentage
FROM
    CustomerSummary
WHERE
    Rank <= 100;
