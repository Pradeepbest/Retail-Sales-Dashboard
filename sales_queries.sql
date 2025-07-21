-- Author: Pradeep
-- Purpose: Clean and transform SuperStore Sales data for Retail sales analysis
-- Date: July 2025

-- View sample data
SELECT TOP 1000 * FROM SalesData;

-- Check for duplicate OrderIDs
SELECT OrderID, COUNT(*) 
FROM SalesData 
GROUP BY OrderID 
HAVING COUNT(*) > 1;

-- Format pricing columns
ALTER TABLE SalesData
ALTER COLUMN UnitPrice DECIMAL(10, 2);

ALTER TABLE SalesData
ALTER COLUMN TotalPrice DECIMAL(10, 2);

ALTER TABLE SalesData
ALTER COLUMN ShippingCost DECIMAL(10, 2);

-- Create Customers table from SalesData
SELECT DISTINCT      
    CustomerName,
    CustomerType,
    Region
INTO Customers
FROM SalesData;

-- Add unique CustomerID via CTE
ALTER TABLE Customers ADD CustomerID INT;

WITH RankedCustomers AS (
    SELECT 
        CustomerName,
        CustomerType,
        Region,
        ROW_NUMBER() OVER(ORDER BY CustomerName) AS RowNum
    FROM Customers
)
UPDATE c
SET c.CustomerID = r.RowNum
FROM Customers c
JOIN RankedCustomers r
  ON c.CustomerName = r.CustomerName
 AND c.CustomerType = r.CustomerType
 AND c.Region = r.Region;

-- Add CustomerID to SalesData and update via join
ALTER TABLE SalesData ADD CustomerID INT;

UPDATE s
SET s.CustomerID = c.CustomerID
FROM SalesData s
JOIN Customers c
  ON s.CustomerName = c.CustomerName
 AND s.CustomerType = c.CustomerType
 AND s.Region = c.Region;

-- Drop redundant columns from SalesData
ALTER TABLE SalesData
DROP COLUMN Region, CustomerName, CustomerType, Discount;

-- KPIs and Analysis

-- Total Sales by Region
SELECT c.Region, SUM(s.Quantity * s.UnitPrice) AS TotalSales
FROM SalesData s
JOIN Customers c ON s.CustomerID = c.CustomerID
GROUP BY c.Region;

-- Monthly Sales Trend
SELECT FORMAT(OrderDate, 'yyyy-MM') AS Month, SUM(Quantity * UnitPrice) AS TotalSales 
FROM SalesData
GROUP BY FORMAT(OrderDate, 'yyyy-MM')
ORDER BY Month;

-- Top 5 Customers by Sales
SELECT TOP 5 c.CustomerName, SUM(Quantity * UnitPrice) AS TotalSales
FROM SalesData s
JOIN Customers c ON s.CustomerID = c.CustomerID
GROUP BY c.CustomerName
ORDER BY TotalSales DESC;