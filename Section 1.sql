/* Section 1. Backup Operations 
				SQL Source code*/


--Check recovery models of all your databases 
SELECT name, recovery_model, recovery_model_desc
FROM sys.databases


--Change recovery model for "model" database from full to simple
ALTER DATABASE model
SET RECOVERY SIMPLE

--Create full database backup of out "University" database
BACKUP DATABASE University
TO DISK = '/var/opt/mssql/data/University.bak'

--Check content of the table "Students"
USE University                                                                                              
                                                                                                         
SELECT LastName, FirstName
FROM Students

--Now simulate a large import
DROP INDEX UQ_user_name
ON dbo.Students
GO
INSERT INTO Students (LastName, FirstName, Email, Phone, UserName)
SELECT T1.LastName, T1.FirstName, T2.PhoneNumber, NULL, 'user.name'
FROM AdventureWorks.Person.Person AS T1
INNER JOIN AdventureWorks.Person.PersonPhone AS T2
ON T1.BusinessEntityID = T2.BusinessEntityID
WHERE LEN (T2.PhoneNumber) < 13
AND LEN (T1.LastName) < 15 AND LEN (T1.FirstName)< 10
GO

--Check new number of rows
SELECT COUNT (*) 
FROM Students

--Create differential backup of "University" database
BACKUP DATABASE University
TO DISK = '/var/opt/mssql/data/University-diff.bak'
WITH DIFFERENTIAL

--Make some changes inside "Students" table
UPDATE Students
SET Phone = 'N/A'
WHERE Phone IS NULL

--Create transaction log backup of "University" database log file
BACKUP LOG University
TO DISK = '/var/opt/mssql/data/University-log.bak'


--Restore full database backup of University database
ALTER DATABASE University
SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE University
FROM DISK = '/var/opt/mssql/data/University.bak'
WITH REPLACE
ALTER DATABASE University SET MULTI_USER

--You should have 4 rows inside the table
SELECT COUNT (*) 
FROM Students

--Restore content of differential backup 
ALTER DATABASE University 
SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE University 
FROM DISK = N'/var/opt/mssql/data/University.bak' 
WITH FILE = 1, NORECOVERY, NOUNLOAD, REPLACE, STATS = 5
RESTORE DATABASE University 
FROM DISK = N'/var/opt/mssql/data/University-diff.bak' 
WITH FILE = 1, NOUNLOAD, STATS = 5
ALTER DATABASE University SET MULTI_USER

--Compression backup feature
BACKUP DATABASE University
TO DISK = '/var/opt/mssql/data/University-compress.bak' 
WITH NOFORMAT, INIT, SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10








