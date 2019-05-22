/* Section 4. Indexing 
		SQL Source code*/

USE Sandbox

-- This example will automatically create clustered index on PatientID column
CREATE TABLE Patients (
	PatientID int IDENTITY (1,1) PRIMARY KEY,
	LastName nvarchar (15) NOT NULL, 
	FirstName nvarchar (15) NOT NULL,
	Email nvarchar (15) NOT NULL)

-- You can add clustered index after you create the table
CREATE TABLE Telemetry (
	TelemetryID int IDENTITY (1,1),
	TelemetryData xml NOT NULL)

CREATE CLUSTERED INDEX CL_TelemetryID
	ON Telemetry (TelemetryID)

--You can check indexes with this system catalog view
SELECT name FROM sys.indexes
WHERE type = 1 --clustered index 
ORDER BY object_id DESC

--Check ifs there are any heap structures inside a database 
SELECT O.name, O.object_id
FROM sys.objects O
	INNER JOIN sys.partitions P 
		ON P.object_id = O.object_id
WHERE P.index_id =0

--Non-clustered index implementation
USE Sandbox

CREATE TABLE Books ( 
	BookID nvarchar(20) PRIMARY KEY,
	PublisherID int NOT NULL,
	Title nvarchar(50) NOT NULL,
	ReleaseDate date NOT NULL)


--Create nonclusterd composite index on two columns
CREATE NONCLUSTERED INDEX IX_Book_Publisher
	ON Books (PublisherID, ReleaseDate DESC)


--Disabling of an index. 
ALTER INDEX IX_Book_Publisher 
	ON Books
DISABLE

--Dropping of an index
DROP INDEX IX_Book_Publisher
	ON Books


--Creating same index but with included column Title
CREATE NONCLUSTERED INDEX IX_Book_Publisher
	ON Books (PublisherID, ReleaseDate DESC)
	INCLUDE (Title)


--Process of reorganizing an index if fragmentation is low
ALTER INDEX IX_Book_Publisher 
	ON Books
REORGANIZE

--Process of rebuilding an index if fragmentation is high
ALTER INDEX IX_Book_Publisher 
	ON Books
REBUILD

--Uniqe index
CREATE UNIQUE NONCLUSTERED INDEX UQ_Patient_Email 
	ON Patients (Email ASC)

--Columnstore index
USE AdventureWorks

--Check number of rows
SELECT COUNT (*) 
FROM Sales.SalesOrderDetail

SELECT TOP 5 ProductID, SUM(UnitPrice) TotalPrice, 
	AVG(UnitPrice) AvgPrice,
	SUM(OrderQty) SumOrderQty, AVG(OrderQty) AvgOrderQty
FROM Sales.SalesOrderDetail
GROUP BY ProductID
ORDER BY ProductID

--Create Nonclustered columnstore on three columns
CREATE NONCLUSTERED COLUMNSTORE INDEX IX_SalesOrderDetail_ColumnStore
	ON Sales.SalesOrderDetail
	(UnitPrice, OrderQty, ProductID)

--Let’s execute the same query again
SELECT TOP 5 ProductID, SUM(UnitPrice) TotalPrice, 
	AVG(UnitPrice) AvgPrice,
	SUM(OrderQty) SumOrderQty, AVG(OrderQty) AvgOrderQty
FROM Sales.SalesOrderDetail
GROUP BY ProductID
ORDER BY ProductID





