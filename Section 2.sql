/* Section 2. Users Management 
				SQL Source code*/
--List sql "sa" login
USE master

SELECT name, is_policy_checked, is_expiration_checked
FROM sys.sql_logins
WHERE name = 'sa'

--Password for sa logins
SELECT password_hash
FROM sys.sql_logins
WHERE name = 'sa'

--Create login "dba" that will require strong password and will not expire
USE master

CREATE LOGIN dba
WITH PASSWORD ='S0m3c00lPa$$',
CHECK_EXPIRATION = OFF,
CHECK_POLICY = ON

--Check the "dba" login
SELECT name, is_policy_checked, is_expiration_checked
FROM sys.sql_logins
WHERE name = 'dba'

--Create user dba from the login dba
CREATE USER dba
FOR LOGIN dba

--Create new login with "dbcreator" fixed serer role
USE master

CREATE LOGIN dbAdmin
WITH PASSWORD = 'S0m3C00lPa$$',
CHECK_EXPIRATION = OFF,
CHECK_POLICY = ON

ALTER SERVER ROLE dbcreator ADD MEMBER dbAdmin

--Login in as a dbAdmin and try to execute following code
CREATE DATABASE TestDB

USE master

DROP DATABASE TesDB

--Login again as "sa"

--Add dba to two fixed database role
USE AdventureWorks

ALTER ROLE db_datareader ADD MEMBER dba

ALTER ROLE db_denydatawriter ADD MEMBER dba

--Now login as dba and test some DML statements on AdventureWorks database






  

