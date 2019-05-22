/* Section 6. Beyond SQL Server 
					SQL Source code*/

USE AdventureWorks

--Activate query store 
ALTER DATABASE AdventureWorks SET QUERY_STORE = ON

--If you want to see more detailed information of what is in the "Query store", run this query
SELECT T3.query_text_id, T3.query_sql_text, T2.plan_id, T1.*
FROM sys.query_store_query AS T1
	JOIN sys.query_store_plan AS T2
		ON T2.query_id = T1.query_id
	JOIN sys.query_store_query_text AS T3
		ON T1.query_text_id = T3.query_text_id

--Maximum storage size is fixed to 150 MB
ALTER DATABASE AdventureWorks
SET QUERY_STORE( MAX_STORAGE_SIZE_MB = 150)


--Maximum size of query store and size based clean up mode is set to AUTO
ALTER DATABASE AdventureWorks
SET QUERY_STORE(
MAX_STORAGE_SIZE_MB = 150,
SIZE_BASED_CLEANUP_MODE = AUTO,
CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 15))


--Purge all the data inside the Query Store
ALTER DATABASE AdventureWorks SET QUERY_STORE CLEAR



SELECT 	P.LastName, P.FirstName, EA.EmailAddress, PP.PhoneNumber, CC.CardNumber,P.FirstName+'.'+P.LastName,
		SUBSTRING (REVERSE (P.LastName),2,4)+
		SUBSTRING (REVERSE (P.FirstName),2,2)+
		SUBSTRING (CAST (P.rowguid AS nvarchar (100)),10,6)
FROM Person.Person AS P
	INNER JOIN Person.EmailAddress AS EA
		ON P.BusinessEntityID = EA.BusinessEntityID
	INNER JOIN 	Person.PersonPhone AS PP
		ON P.BusinessEntityID = PP.BusinessEntityID
	LEFT JOIN Sales.PersonCreditCard AS PCC
		ON PP.BusinessEntityID = PCC.BusinessEntityID
LEFT JOIN Sales.CreditCard AS CC
		ON PCC.CreditCardID = CC.CreditCardID
		
SELECT T2.plan_id,T1.query_id, LEFT (T3.query_sql_text,15)
FROM sys.query_store_query AS T1
	JOIN sys.query_store_plan AS T2
		ON T2.query_id = T1.query_id
	JOIN sys.query_store_query_text AS T3
		ON T1.query_text_id = T3.query_text_id


--Unforcing plan_id 1 to query_id 2
EXEC sp_query_store_unforce_plan  @query_id = 1, @plan_id =1

USE Sandbox

--Creating pair of System-versioning tables
CREATE TABLE Users (
	UserID int NOT NULL PRIMARY KEY CLUSTERED, 
	LastName varchar(10) NOT NULL,
	FirstName varchar(10) NOT NULL,
	Email varchar(20) NULL,
	SysStartTime datetime2 
GENERATED ALWAYS AS ROW START NOT NULL,  
SysEndTime datetime2 GENERATED ALWAYS AS ROW END NOT NULL,  
PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime)     
) 
WITH
(SYSTEM_VERSIONING = ON 
(HISTORY_TABLE = dbo.UsersHistory)) 


--Checking the tables trough sys.tabeles, system catalog view
USE Sandbox

SELECT name, temporal_type_desc
FROM sys.tables

-- Adding new record
INSERT INTO Users
VALUES (1, 'Marty', 'McFly', NULL, DEFAULT, DEFAULT)


-- Checking content of the temporal table
SELECT UserID, SysStartTime, SysEndTime  
FROM Users

--Cheking content of history table
SELECT *
FROM UsersHistory

--Now, we will update Marty’s email address
UPDATE Users
SET Email = 'Marty@HillValley.com'
WHERE UserID = 1

--Disable temporal tables feature on Users table

USE Sandbox


--Permanently removes SYSTEM_VERSIONING 
ALTER TABLE Users 
SET (SYSTEM_VERSIONING = OFF)


--Checking the status of tables
SELECT name, temporal_type_desc
FROM sys.tables

--Optionally, removes the period columns property   
ALTER TABLE Users   
DROP PERIOD FOR SYSTEM_TIME




