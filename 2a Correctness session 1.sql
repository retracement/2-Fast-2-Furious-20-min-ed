/*MIT License

Copyright (c) 2017 Mark Broadbent, contactme@sturmovik.net

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

/********************************/
/* 2a Correctness session 1.sql */
/********************************
The following script demonstrates correctness is a real concern for
developers in current database workloads*/



/******************************************************/
/* In this example we will look at inconsistent reads */
/******************************************************/
-- Execute a transaction to delete all records and insert with 10 records.
-- Since this modification is transactional we would expect other sessions
-- to always return 10 records or be blocked.
SET NOCOUNT ON
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
TRUNCATE TABLE Cars

WHILE 1=1
BEGIN 
	BEGIN TRAN
		DELETE FROM Cars

		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Ferrari', 170, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Porsche', 150, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Lamborghini', 175, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Mini', 110, '')	
		WAITFOR DELAY '00:00:00.02'
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Datsun', 90, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Ford', 125, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Audi', 138, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('BMW', 120, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Honda', 87, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Mercedes', 155, '')   
	COMMIT TRAN
END


-- Switch to session 2


-- Stop the running while loop


/******************************************************/
/* In this example we will look at atomicity concerns */
/******************************************************/
-- We want to try and avoid transactions getting
-- blocked - because our API developer apparently says
-- he can replay them. Should we be concerned?

-- Rollback any open transactions
SET NOCOUNT OFF
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK


-- Create our table and insert a record
IF OBJECT_ID('dbo.t1','U') IS NOT NULL DROP TABLE t1
CREATE TABLE t1 (c1 INT)
GO
INSERT INTO t1 (c1) VALUES ('1');


-- Start open ended transaction
-- and update our record
BEGIN TRAN
    UPDATE t1 SET c1 = 3 WHERE c1=1


-- Switch to session 2


-- Commit transaction and query 
-- table records
COMMIT
SELECT * FROM t1

-- Review the number of rows
-- and their values :)

-- Errm!

-- Presenters Note:
-- REMEMBER AS A DEVELOPER YOU ARE BALANCING
-- CONCURRENCY AGAINST CORRECTNESS CONCERNS!

-- See my post "Why don't you go and lock off"
-- found at https://tenbulls.co.uk/2013/07/17/why-dont-you-go-and-lock-off/