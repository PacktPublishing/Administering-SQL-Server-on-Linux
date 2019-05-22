/* Section 3. Implementing Data Protection 
						SQL Source code*/

--Service master key can be view with following system catalog view
SELECT name, create_date
FROM sys.symmetric_keys

--Back up your SMK 
USE master

--In the real scenarios your password should be more complicated
BACKUP SERVICE MASTER KEY TO FILE = '/var/opt/mssql/backup/smk'
ENCRYPTION BY PASSWORD = 'S0m3C00lp4sw00rd'

--Restore SMK from the backup location:
USE master

RESTORE SERVICE MASTER KEY 
FROM FILE = '/var/opt/mssql/backup/smk'
DECRYPTION BY PASSWORD = 'S0m3C00lp4sw00rd'

--Next code show how to create DMK in the Sandbox database
CREATE DATABASE Sandbox

USE Sandbox
CREATE MASTER KEY 
ENCRYPTION BY PASSWORD = 'S0m3C00lp4sw00rd'

--Check DMK 
SELECT name, algorithm_desc
FROM sys.symmetric_keys

--Alter  DMK
ALTER MASTER KEY REGENERATE 
WITH ENCRYPTION BY PASSWORD = 'S0m3C00lp4sw00rdforN3wK3y'

--Open DMK for use
OPEN MASTER KEY 
DECRYPTION BY PASSWORD = 'S0m3C00lp4sw00rdforN3wK3y'

--Close DMK after using
CLOSE MASTER KEY

--Backing up DMK
OPEN MASTER KEY 
DECRYPTION BY PASSWORD = 'S0m3C00lp4sw00rdforN3wK3y';
BACKUP MASTER KEY 
TO FILE = '/var/opt/mssql/backup/Snadbox-dmk' 
ENCRYPTION BY PASSWORD = 'fk58smk@sw0h%as2'
 
--Restoring DMK
RESTORE MASTER KEY 
FROM FILE = '/var/opt/mssql/backup/Snadbox-dmk'
DECRYPTION BY PASSWORD = 'fk58smk@sw0h%as2' 
ENCRYPTION BY PASSWORD = 'S0m3C00lp4sw00rdforN3wK3y'

--Dropping DMK

DROP MASTER KEY 

/*	To implement TDE, we need to follow these steps:
	•	Create a master key in the master database
	•	Create a certificate protected by using the master key
	•	Create a database encryption key and protect it by using the certificate
	•	Set the database to use encryption */

USE master

CREATE MASTER KEY ENCRYPTION 
BY PASSWORD = 'Some3xtr4Passw00rd'

SELECT name, create_date
FROM sys.symmetric_keys

CREATE CERTIFICATE TDE 
WITH SUBJECT = 'TDE-Certificate'

SELECT name, expiry_date 
FROM sys.certificates
WHERE name = 'TDE'

USE Sandbox 

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDE

ALTER DATABASE Sandbox
SET ENCRYPTION ON

/* In the following steps, we’ll create a backup certificate, 
  create a backup file of our Sandbox database, and do compression 
  and encryption with the certificate*/

USE master  
  
CREATE CERTIFICATE BackupCert   
WITH SUBJECT = 'Database encrypted backups'
 
BACKUP DATABASE Sandbox  
TO DISK = '/var/opt/mssql/backup/Sandbox.bak'  
WITH  
  COMPRESSION,  
  ENCRYPTION   
   (  
   ALGORITHM = AES_256,  
   SERVER CERTIFICATE = BackupCert  
   ),  
STATS = 10   
  
--Symmetric data encryption

USE Sandbox

CREATE MASTER KEY 
ENCRYPTION BY PASSWORD = 'Some3xtr4Passw00rd';


-- Create new table for encryption process
CREATE TABLE EncryptedCustomer(
	CustomerID   int NOT NULL PRIMARY KEY,
	FirstName    varbinary(200),
	MiddleName   varbinary(200),
	LastName     varbinary(200),
	EmailAddress varbinary(200),
	Phone        varbinary(150))

-- Create a certificate
CREATE CERTIFICATE Cert4SymKey
ENCRYPTION BY PASSWORD = 'pGFD4bb925DGvbd2439587y'
WITH SUBJECT = 'Protection of symmetric key', 
EXPIRY_DATE = '20201031'

-- Create a AES 256 symmetric key
CREATE SYMMETRIC KEY CustomerSymKey
WITH ALGORITHM = AES_256,
IDENTITY_VALUE = 'NTK2016'
ENCRYPTION BY CERTIFICATE Cert4SymKey

-- Open the key that's protected by certificate
OPEN SYMMETRIC KEY CustomerSymKey
DECRYPTION BY CERTIFICATE Cert4SymKey
WITH PASSWORD = 'pGFD4bb925DGvbd2439587y'


-- Encrypt the data
INSERT INTO EncryptedCustomer(
	CustomerID,
	FirstName,
	MiddleName,
	LastName,
	EmailAddress,
	Phone)
SELECT
	P.BusinessEntityID,
	EncryptByKey(Key_Guid('CustomerSymKey'),FirstName),
	EncryptByKey(Key_Guid('CustomerSymKey'),MiddleName),
	EncryptByKey(Key_Guid('CustomerSymKey'),LastName),
	EncryptByKey(Key_Guid('CustomerSymKey'),EA.EmailAddress),
	EncryptByKey(Key_Guid('CustomerSymKey'), PP.PhoneNumber)
FROM AdventureWorks.Person.Person AS P
	INNER JOIN AdventureWorks.Person.EmailAddress AS EA
		ON P.BusinessEntityID = EA.BusinessEntityID
	INNER JOIN AdventureWorks.Person.PersonPhone AS PP
	ON P.BusinessEntityID = PP.BusinessEntityID

-- Close the key
CLOSE SYMMETRIC KEY CustomerSymKey
 
-- View encrypted binary data
SELECT FirstName
FROM EncryptedCustomer

-- Open the key again and decrypt column side by side
OPEN SYMMETRIC KEY CustomerSymKey
DECRYPTION BY CERTIFICATE Cert4SymKey
WITH PASSWORD = 'pGFD4bb925DGvbd2439587y'

SELECT 
	CAST(DecryptByKey(FirstName) AS nvarchar(100)) AS 
	DecryptedFirstName, FirstName
FROM EncryptedCustomer

--Row-level security implementation

USE Sandbox

--Create three users without logins
CREATE USER Manager WITHOUT LOGIN;
CREATE USER Sales1 WITHOUT LOGIN;
CREATE USER Sales2 WITHOUT LOGIN;

-- Create Sales table
CREATE TABLE Sales
(
	OrderID int,
	SalesRep sysname,
	Product varchar(10),
	Qty int 
)

-- Add some sample data
INSERT Sales VALUES 
	(1, 'Sales1', 'Valve', 5), 
	(2, 'Sales1', 'Wheel', 2), 
	(3, 'Sales1', 'Valve', 4),
	(4, 'Sales2', 'Bracket', 2), 
	(5, 'Sales2', 'Wheel', 5), 
	(6, 'Sales2', 'Seat', 5)

-- Execute SELECT statement under your permission 
SELECT * FROM Sales


-- Give to all users necessary read permissions
GRANT SELECT ON Sales TO Manager

GRANT SELECT ON Sales TO Sales1

GRANT SELECT ON Sales TO Sales2

-- Create new schema
CREATE SCHEMA Security


--Creating new function which will user SalesRep as input
CREATE FUNCTION Security.fn_securitypredicate(@SalesRep AS sysname)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_securitypredicate_result 
WHERE @SalesRep = USER_NAME() OR USER_NAME() = 'Manager'


--Creating security policy for the data filtering
CREATE SECURITY POLICY SalesFilter
ADD FILTER PREDICATE 
Security.fn_securitypredicate(SalesRep) 
ON dbo.Sales
WITH (STATE = ON)

--Now execute SELECT in the context of the new users
EXECUTE AS USER = 'Sales1'
SELECT * FROM Sales
REVERT

EXECUTE AS USER = 'Sales2'
SELECT * FROM Sales
REVERT

EXECUTE AS USER = 'Manager'
SELECT * FROM Sales
REVERT

-- If you need you can turn off this policy
ALTER SECURITY POLICY SalesFilter
WITH (STATE = OFF)

--Dynamic data masking

-- You will use content of AdventureWorks sample database
USE AdventureWorks

-- Add masked future to the Email column
ALTER TABLE Person.EmailAddress
ALTER COLUMN EmailAddress
ADD MASKED WITH (FUNCTION = 'email()') 

--New user without login and read permission
CREATE USER UnauthorizedUser WITHOUT LOGIN
 
GRANT SELECT ON Person.EmailAddress TO UnauthorizedUser

--Execute SELECT in the contenxrt of UnauthorizedUser
EXECUTE AS USER = 'UnauthorizedUser'   
SELECT TOP 5 EmailAddressID, EmailAddress 
FROM Person.EmailAddress
REVERT

--Execute SELECT in the context of the sa user
SELECT TOP 5 EmailAddressID, EmailAddress 
FROM Person.EmailAddress



