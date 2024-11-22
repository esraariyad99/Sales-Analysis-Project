-----------تعديل جدول التكلفه ---------
select * from Production.ProductCostHistory

-----ملي تاريخ نهايه فتره السعر  ----------

UPDATE Production.ProductCostHistory
SET EndDate = '2014-12-29'
WHERE EndDate is null

----- استخراج بيانات البيع مع الاخذ ف الاعتبار سعر التكلفه يختلف كل سنه  ------------
SELECT 
    SOH.SalesOrderID, 
    SOH.OrderDate, 
    SOH.OnlineOrderFlag, 
    SOH.CustomerID, 
    SOH.SalesPersonID, 
    SOH.TerritoryID, 
    SOH.TaxAmt, 
    SOH.TotalDue, 
    SOD.ProductID, 
    SOD.OrderQty, 
    SOD.SalesOrderID AS SalesOrderDetailID, 
    SOD.UnitPrice, 
    SOD.UnitPriceDiscount, 
    SOD.LineTotal,
    PCH.StandardCost AS ProductCost
FROM 
    Sales.SalesOrderHeader SOH
JOIN 
    Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN 
    Production.Product P ON SOD.ProductID = P.ProductID
JOIN 
    Production.ProductCostHistory PCH ON SOD.ProductID = PCH.ProductID
WHERE 
    SOH.OrderDate >= PCH.StartDate 
    AND (SOH.OrderDate <= PCH.EndDate OR PCH.EndDate IS NULL);
	
	------------------استخراج بيانات المنتجات --------------

	SELECT 
    P.Name AS ProductName,
    PC.Name AS CategoryName,
    PSC.Name AS SubcategoryName,
    P.ProductID,
    SOD.SalesOrderID
FROM 
    Production.Product AS P
INNER JOIN 
    Production.ProductSubcategory AS PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
INNER JOIN 
    Production.ProductCategory AS PC ON PSC.ProductCategoryID = PC.ProductCategoryID
INNER JOIN 
    Sales.SalesOrderDetail AS SOD ON P.ProductID = SOD.ProductID;


	----- استخراج بيانات مناديب البيع 
select * from Sales.Store
----اخدت الجدول دا عملت transform 
select * from Person.Person
where  PersonType= 'sp'
-
--==============================================
-------------------انشاء جدول الاجازات ------------------
	--drop TABLE CalendarTable ;
	CREATE TABLE CalendarTable (
    OrderDate DATE PRIMARY KEY,
    IsHoliday VARCHAR(20)
);

select * from  CalendarTable 
where IsHoliday is not null

--------- ملي عمود التاريخ بتاريخ طلب المنتج --------
INSERT INTO CalendarTable (OrderDate)
SELECT DISTINCT OrderDate FROM Sales.SalesOrderHeader;

 -------  اضافه الاجازات الرسميه  --------

 UPDATE CalendarTable
SET IsHoliday = 
    CASE 
        WHEN OrderDate IN ('2011-02-14', '2012-02-14', '2013-02-14', '2014-02-14') THEN 'Valentine''s Day'
        WHEN OrderDate IN ('2011-05-01', '2012-05-01', '2013-05-01', '2014-05-01') THEN 'Labor Day'
        WHEN OrderDate IN ('2011-07-04', '2012-07-04', '2013-07-04', '2014-07-04') THEN 'Independence Day'
        WHEN OrderDate IN ('2011-11-28', '2012-11-28', '2013-11-28', '2014-11-28') THEN 'Thanksgiving'
        WHEN OrderDate IN ('2011-12-25', '2012-12-25', '2013-12-25', '2014-12-25') THEN 'Christmas'
        ELSE NULL
    END
WHERE OrderDate IN ('2011-02-14', '2012-02-14', '2013-02-14', '2014-02-14',
                    '2011-05-01', '2012-05-01', '2013-05-01', '2014-05-01',
                    '2011-07-04', '2012-07-04', '2013-07-04', '2014-07-04',
                    '2011-11-28', '2012-11-28', '2013-11-28', '2014-11-28',
                    '2011-12-25', '2012-12-25', '2013-12-25', '2014-12-25');


--=============================================================================================
----------------------- total Revenue & total Profit  -------------------------------
SELECT 
    SUM(SOD.LineTotal) AS TotalRevenue,  
    SUM((SOD.UnitPrice - PCH.StandardCost) * SOD.OrderQty) AS Profit  
FROM 
    Sales.SalesOrderHeader SOH
JOIN 
    Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN 
    Production.ProductCostHistory PCH ON SOD.ProductID = PCH.ProductID
WHERE 
    SOH.OrderDate >= PCH.StartDate 
    AND (SOH.OrderDate <= PCH.EndDate OR PCH.EndDate IS NULL);

------------------------------------------------------------------------
------ تكلفه البضاعه المباعه ------
SELECT 
    SUM(SOD.OrderQty * PCH.StandardCost) AS TotalCOGS
FROM 
    Sales.SalesOrderDetail SOD
JOIN 
    Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
JOIN 
    Production.ProductCostHistory PCH ON SOD.ProductID = PCH.ProductID
WHERE 
    SOH.OrderDate >= PCH.StartDate 
    AND SOH.OrderDate <= PCH.EndDate;
select* from production.ProductCostHistory

--===========================================================================================
------------------------------ Years and monthly orders Qty ---------------------------
SELECT 
    YEAR(SOH.OrderDate) AS OrderYear, 
    MONTH(SOH.OrderDate) AS OrderMonth, 
    SUM(SOD.OrderQty) AS TotalOrderQty  
FROM 
    Sales.SalesOrderHeader SOH
JOIN 
    Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID  
GROUP BY 
    YEAR(SOH.OrderDate), MONTH(SOH.OrderDate)  
ORDER BY 
    OrderYear DESC, 
    TotalOrderQty DESC;   
  -----------------------------
-- Monthly orders 
	SELECT 
    MONTH(SOH.OrderDate) AS OrderMonth, 
    SUM(SOD.OrderQty) AS TotalOrderQty  
FROM 
    Sales.SalesOrderHeader SOH
JOIN 
    Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID 
GROUP BY 
    MONTH(SOH.OrderDate)  
ORDER BY 
    TotalOrderQty DESC;   

--=======================================================================================
----------------------- Top 10 products by order Qty --------------------------------------- 
SELECT TOP 10
    P.ProductID,                  
    P.Name AS ProductName,         
    SUM(SOD.OrderQty) AS TotalOrderQty  
FROM 
    Sales.SalesOrderDetail SOD     
JOIN 
    Production.Product P            
ON 
    SOD.ProductID = P.ProductID     
GROUP BY 
    P.ProductID, P.Name             
ORDER BY 
    TotalOrderQty DESC;
--========================================================================================
-------------------------------Top 10 product By total Revenue -----------------------------
SELECT TOP 10
    P.ProductID,                  
    P.Name AS ProductName,        
    SUM(SOD.LineTotal) AS TotalRevenue,  
    SUM(SOD.OrderQty) AS TotalQuantity   
FROM 
   Sales.SalesOrderDetail SOD    
JOIN 
    Production.Product P           
ON 
    SOD.ProductID = P.ProductID    
GROUP BY 
    P.ProductID, P.Name           
ORDER BY 
    TotalRevenue DESC;
--======================================================================================
---------------------------- Total sales By Region ------------------------------------
SELECT 
    T.Name AS TerritoryName,             
    SUM(SOH.SubTotal) AS TotalSales,       
    COUNT(SOH.SalesOrderID) AS OrderCount  
FROM 
    Sales.SalesOrderHeader SOH
JOIN 
    Sales.SalesTerritory T ON SOH.TerritoryID = T.TerritoryID
GROUP BY 
    T.Name                                
ORDER BY 
    TotalSales DESC; 
--=======================================================================================
-----------------sales person performance during the current and last year-------------
SELECT 
    SP.BusinessEntityID,                    
    P.FirstName + ' ' + P.LastName AS SalesPersonName, 
    SP.SalesYTD,                            
    SP.SalesLastYear,                        
    (SP.SalesYTD - SP.SalesLastYear) AS SalesGrowth  
FROM 
    Sales.SalesPerson SP                    
JOIN 
    Person.Person P                         
ON 
    SP.BusinessEntityID = P.BusinessEntityID 
--==================================================================================================
----------------------------------------Top 10 store----------------------------------------
SELECT TOP 10
    C.CustomerID,
    C.AccountNumber,
    CASE
        WHEN S.Name IS NOT NULL THEN S.Name  
        ELSE 'Unknown'  
    END AS StoreName,  
    SUM(SOH.SubTotal) AS TotalSales  
FROM 
    Sales.Customer C
LEFT JOIN 
    Sales.SalesOrderHeader SOH 
    ON C.CustomerID = SOH.CustomerID
LEFT JOIN 
    Sales.Store S 
    ON C.StoreID = S.BusinessEntityID 
GROUP BY 
    C.CustomerID, 
    C.AccountNumber,
    S.Name
ORDER BY 
    TotalSales DESC;

--==================================================================================================
-----------------------------Number Of Products Sold in offers---------------------------
SELECT 
    SO.SpecialOfferID,                           
    SO.Description AS SpecialOfferDescription,    
    COUNT(SOD.ProductID) AS NumberOfProductsSold  
FROM 
    Sales.SpecialOffer SO
JOIN 
    Sales.SpecialOfferProduct SOP ON SO.SpecialOfferID = SOP.SpecialOfferID  
JOIN 
    Sales.SalesOrderDetail SOD ON SOP.ProductID = SOD.ProductID  
WHERE 
    SO.Description <> 'No Discount'               
GROUP BY 
    SO.SpecialOfferID,                          
    SO.Description                               
ORDER BY 
    NumberOfProductsSold DESC;   
--=================================================================================================
---------------------------- TotalQuantityDuringOffer & TotalQuantityAfterOffer-----------------------------------
SELECT 
    SO.SpecialOfferID,
    SO.Description,
    SO.StartDate,
    SO.EndDate,
    P.ProductID,
    P.Name AS ProductName,
    SUM(SOD.OrderQty) AS TotalQuantityDuringOffer,
    COALESCE(
        (SELECT SUM(SOD2.OrderQty)
         FROM Sales.SalesOrderDetail SOD2
         INNER JOIN Sales.SalesOrderHeader SOH2 ON SOD2.SalesOrderID = SOH2.SalesOrderID
         WHERE SOD2.ProductID = P.ProductID
         AND SOH2.OrderDate > SO.EndDate
         AND SOH2.OrderDate <= DATEADD(DAY, DATEDIFF(DAY, SO.StartDate, SO.EndDate), SO.EndDate)
        ), 0) AS TotalQuantityAfterOffer
FROM 
    Sales.SpecialOfferProduct SOP
INNER JOIN 
    Production.Product P ON SOP.ProductID = P.ProductID
INNER JOIN 
    Sales.SalesOrderDetail SOD ON P.ProductID = SOD.ProductID
INNER JOIN 
    Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
INNER JOIN 
    Sales.SpecialOffer SO ON SOP.SpecialOfferID = SO.SpecialOfferID
WHERE 
    SOH.OrderDate BETWEEN SO.StartDate AND SO.EndDate
    AND SO.SpecialOfferID BETWEEN 7 AND 16
GROUP BY 
    SO.SpecialOfferID,
    SO.Description,
    SO.StartDate,
    SO.EndDate,
    P.ProductID,
    P.Name;

--==================================================================================================
-------------------- Diff Orderdate & Shipdate----------------------------- 
SELECT 
    SalesOrderID,
    OrderDate,
    ShipDate,
    DATEDIFF(day, OrderDate, ShipDate) AS ProcessingTime 
FROM 
    Sales.SalesOrderHeader
WHERE 
    ShipDate IS NOT NULL;  
-----------------------------------------------------------------------------------------
-------------------------Diff Duedate & Shipdate--------------------------
SELECT 
    SalesOrderID,
    ShipDate,
    DueDate,
    DATEDIFF(day, ShipDate, DueDate) AS DeliveryDelay  
FROM 
    Sales.SalesOrderHeader
WHERE 
    ShipDate IS NOT NULL
    AND DueDate IS NOT NULL
------------------------------------------------------------------------------------------------
-------------------- Diff Duedate & Orderdate -----------------------------
SELECT 
    SalesOrderID,
    OrderDate,
    DueDate,
    DATEDIFF(day, OrderDate, DueDate) AS OrderCompletionTime
FROM 
    Sales.SalesOrderHeader;

	--==---===========----============-----=============-------===========-----======
	
