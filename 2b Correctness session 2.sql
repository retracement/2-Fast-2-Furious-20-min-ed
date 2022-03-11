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
/* 2b Correctness session 2.sql */
/********************************
The following script demonstrates correctness is a real concern for
developers in current database workloads*/



/******************************************************/
/* In this example we will look at inconsistent reads */
/******************************************************/
-- Run a while loop to insert all visible records to a temp table and BREAK
-- if record count is not equal to 10.
-- Excecute this several times until you are happy
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
SET NOCOUNT ON
DECLARE @Cars TABLE (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), 
	lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000));
DECLARE @ConsistentResults INT = 0
WHILE @ConsistentResults < 100
BEGIN
	DELETE FROM @Cars
	INSERT INTO @Cars SELECT * FROM Cars --with (holdlock) --with (serializable)
	IF @@ROWCOUNT <> 10
		BREAK

	SET @ConsistentResults = @ConsistentResults + 1
	WAITFOR DELAY '00:00:00.013'
END
SELECT @ConsistentResults AS SuccessfulPriorRuns
SELECT * FROM @Cars

-- Note the biggest trigger for this problem is the table Cluster GUID
-- and the way SQL accesses mixed extents
-- See my post "Inconsistent result sets and another case against pessimistic isolation"
-- found at https://tenbulls.co.uk/2020/04/27/inconsistent-results/


-- Let's repeat under SERIALIZABLE
-- Excecute this several times until you are happy
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
SET NOCOUNT ON
DECLARE @Cars TABLE (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), 
	lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000));
DECLARE @ConsistentResults INT = 0
WHILE @ConsistentResults < 100
BEGIN
	BEGIN TRY
		DELETE FROM @Cars
		INSERT INTO @Cars SELECT * FROM Cars WITH (SERIALIZABLE)
		IF @@ROWCOUNT <> 10
			BREAK

		SET @ConsistentResults = @ConsistentResults + 1
		WAITFOR DELAY '00:00:00.013'
	END TRY
	BEGIN CATCH -- we need catch in this scenario to output runs on DL
		SELECT @ConsistentResults AS SuccessfulPriorRuns
		SELECT * FROM @Cars
		SELECT ERROR_MESSAGE() 
		BREAK
	END CATCH
END
SELECT @ConsistentResults AS SuccessfulPriorRuns
SELECT * FROM @Cars


-- Let's transition to a new OPTIMISTIC default
-- of READ_COMMITTED_SNAPSHOT
USE MASTER
GO
ALTER DATABASE [2Fast2Furious] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
GO
USE [2Fast2Furious];
GO


/***************************************WARNING**********************************/
/* You'll need to SWITCH BACK to SESSION 1 and RERUN the loop before continuing */
/********************************************************************************/


-- Run again using the new default of READ_COMMITTED_SNAPSHOT
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
SET NOCOUNT ON
DECLARE @Cars TABLE (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), 
	lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000));
DECLARE @ConsistentResults INT = 0
WHILE @ConsistentResults < 100
BEGIN
	DELETE FROM @Cars
	INSERT INTO @Cars SELECT * FROM Cars --with (holdlock) --with (serializable)
	IF @@ROWCOUNT <> 10
		BREAK

	SET @ConsistentResults = @ConsistentResults + 1
	WAITFOR DELAY '00:00:00.013'
END
SELECT @ConsistentResults AS SuccessfulPriorRuns
SELECT * FROM @Cars



-- Finally let's repeat under SNAPSHOT
-- and cancel once you are happy
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
SET NOCOUNT ON
DECLARE @Cars TABLE (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), 
	lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000));
DECLARE @ConsistentResults INT = 0
WHILE @ConsistentResults < 100
BEGIN
	DELETE FROM @Cars
	INSERT INTO @Cars SELECT * FROM Cars --SNAPSHOT HINT ONLY RELEVANT TO IMTABLES
	IF @@ROWCOUNT <> 10
		BREAK

	SET @ConsistentResults = @ConsistentResults + 1
	WAITFOR DELAY '00:00:00.013'
END
SELECT @ConsistentResults AS SuccessfulPriorRuns
SELECT * FROM @Cars


-- Let's transition back to READ COMMITTED default
USE MASTER
GO
ALTER DATABASE [2Fast2Furious] SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE;
GO
USE [2Fast2Furious];
GO


-- set isolation level back to read committed
SET TRANSACTION ISOLATION LEVEL READ COMMITTED



-- Switch back to session 1 (stop the while loop *if* still running)



/******************************************************/
/* In this example we will look at atomicity concerns */
/******************************************************/
-- and attempt to solve them
SET NOCOUNT OFF
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK


-- Set a lock timeout to avoid any waiting on lock
SET LOCK_TIMEOUT 10


-- Run a transaction to insert a new record
-- and DELETE any records with an ID of 1
BEGIN TRAN
    INSERT INTO t1 VALUES ('2');
    DELETE FROM t1 WHERE c1 = 1; --wait (block) on X lock
COMMIT


-- Check transaction has rolled back (or committed...)
SELECT @@TRANCOUNT AS Trancount


-- Switch back to session 1
--fin.