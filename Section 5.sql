/*Section 5. In-memory OLTP 
			SQL Source code*/

--Create database that is prepared for in-memory tables.
USE master

CREATE DATABASE InMemorySandbox
ON
PRIMARY (NAME = InMemorySandbox_data,
	FILENAME = '/var/opt/mssql/data/InMemorySandbox_data_data.mdf', size=500MB),
FILEGROUP InMemorySandbox_fg 
CONTAINS MEMORY_OPTIMIZED_DATA

(NAME = InMemorySandbox_dir,
FILENAME = '/var/opt/mssql/data/InMemorySandbox_dir')
LOG ON (name = InMemorySandbox_log, 
	FILENAME= '/var/opt/mssql/data/InMemorySandbox_data_data.ldf', 
size=500MB)

--How to convert existing database into memory optimize
--First, we need to check compatibility level of database. Minimum is 130
USE AdventureWorks

SELECT T.compatibility_level
	FROM sys.databases as T
WHERE T.name = Db_Name()

--Change the compatibility level
ALTER DATABASE CURRENT
SET COMPATIBILITY_LEVEL = 130


--Modify the transaction isolation level
ALTER DATABASE CURRENT SET 
MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON

--Finlay create memory optimized filegroup
ALTER DATABASE AdventureWorks 
ADD FILEGROUP AdventureWorks_fg CONTAINS 
MEMORY_OPTIMIZED_DATA

ALTER DATABASE AdventureWorks ADD FILE 
(NAME='AdventureWorks_mem', FILENAME='/var/opt/mssql/data/AdventureWorks_mem') 
TO FILEGROUP AdventureWorks_fg


USE InMemorySandbox  

-- Create a durable memory-optimized table  
CREATE TABLE Basket 
(   
	BasketID INT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,  
	UserID INT NOT NULL INDEX ix_UserID 
	NONCLUSTERED HASH WITH (BUCKET_COUNT=1000000),   
	CreatedDate DATETIME2 NOT NULL,   
	TotalPrice MONEY) WITH (MEMORY_OPTIMIZED=ON)   
  
-- Create a non-durable table.   
CREATE TABLE UserLogs (   
	SessionID INT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT=400000),   
	UserID int NOT NULL,   
	CreatedDate DATETIME2 NOT NULL,  
	BasketID INT,  
	INDEX ix_UserID 
	NONCLUSTERED HASH (UserID) WITH (BUCKET_COUNT=400000))
	WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_ONLY)   
  

-- Add some sample records  
INSERT INTO UserLogs VALUES
	(432, SYSDATETIME(), 1),   
	(231, SYSDATETIME(), 7),   
	(256, SYSDATETIME(), 7),   
	(134, SYSDATETIME(), NULL),   
	(858, SYSDATETIME(), 2),   
	(965, SYSDATETIME(), NULL)
  

INSERT INTO Basket VALUES 
	(231, SYSDATETIME(), 536),   
	(256, SYSDATETIME(), 6547),   
	(432, SYSDATETIME(), 23.6),   
	(134, SYSDATETIME(), NULL)   
  
-- Checking the content of the tables
SELECT SessionID, UserID, BasketID 
FROM UserLogs
   
SELECT BasketID, UserID 
FROM Basket   

USE InMemorySandbox  
  
CREATE PROCEDURE dbo.usp_BasketInsert @InsertCount int 
WITH NATIVE_COMPILATION, SCHEMABINDING AS 
BEGIN ATOMIC 
WITH 
(TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')
DECLARE @i int = 0
WHILE @i < @InsertCount 
BEGIN 
INSERT INTO dbo.Basket VALUES (1, SYSDATETIME() , NULL) 
SET @i += 1 
END
END

--Add 1000000 records
EXEC dbo.usp_BasketInsert 1000000

SELECT COUNT(*) 
FROM dbo.Basket





