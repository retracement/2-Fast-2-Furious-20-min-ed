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
/* 1a Speed and concurrency.sql */
/********************************
The following script demonstrates how speed is a relative concept
and how this all matters in concurrent work loads*/



/***********************************************************/
/* In this example we will see if a query is "fast" enough */
/***********************************************************/
-- Execute the query (we are returning a single record)
-- Is it fast enough? (note the execution time)
USE [2Fast2Furious]
GO
SET STATISTICS TIME ON
SELECT id, batchid FROM table1 WHERE id = 50999
SET STATISTICS TIME OFF


-- Include actual execution plan
-- Run again
	-- Look at the query cost on the query plan
	-- Look at statistics io
SET STATISTICS IO ON
SELECT id, batchid FROM table1 WHERE id = 50999
SET STATISTICS IO OFF


-- Lets do updates using same access pattern
-- In SqlQueryStress run the following 
-- 100 iterations, 10 threads

-- Update a random rows in parallel
UPDATE table1 SET batchid = batchid 
WHERE id = (1+ ABS(CHECKSUM(NewId())) % 50998)
-- 1000 updates took?
-- The same access pattern searching for your data also exists for updates
-- You can see this if you look at the execution plan


-- Lets create a clustered index to satisfy the query predicate
-- and included columns
CREATE CLUSTERED INDEX IX_table1_id ON table1 (id)


-- Run the update again
-- How long does it take this time?


-- Run SELECT again and look at statistics io
-- Display Estimated query plan
SET STATISTICS IO ON
SELECT batchid FROM table1 WHERE id = 50999
SET STATISTICS IO OFF

-- Better?
-- If quicker, why?  

-- Presenters Note 1:
-- Bad indexing strategy and poorly written queries
-- can substantially effect your data access patterns.
-- Data reads/writes, locking, blocking, and even deadlocking 
-- are ALL exacerbated by concurrency.

-- Presenters Note 2:
-- A QUERY IS FAST ENOUGH IF IT ACCESSES THE MINIMUM
-- AMOUNT OF PAGES POSSIBLE IN ORDER TO SATISFY THE
-- RESULT SET