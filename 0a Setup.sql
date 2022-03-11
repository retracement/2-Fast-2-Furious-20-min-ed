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

/****************/
/* 0a Setup.sql */
/****************
The following script drops the 2Fast2Furious if it exists and recreates 
it with all the necessary tables, data, and procedures*/



/*******************************/
/* Drop Database 2Fast2Furious */
/*******************************/
USE master
GO
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = '2Fast2Furious')
BEGIN
	ALTER DATABASE [2Fast2Furious] 
		SET READ_ONLY WITH ROLLBACK IMMEDIATE;
		DROP DATABASE [2Fast2Furious];
END

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = '2Fast2Furious')
BEGIN
	PRINT 'Warning 2Fast2Furious database still exists'
END

/*********************************/
/* Create Database 2Fast2Furious */
/*********************************/
USE master
GO
-- Change these paths for your environment
-- DECLARE @defaultdatapath NVARCHAR(512) = 'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA' --SQL2016
-- DECLARE @defaultlogpath NVARCHAR(512) = 'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA'
DECLARE @defaultdatapath NVARCHAR(512) = 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA' --SQL2016
DECLARE @defaultlogpath NVARCHAR(512) = 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA' -- SQL2017

DECLARE @createdb VARCHAR(MAX)=
'CREATE DATABASE [2Fast2Furious]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N''2Fast2Furious_data'', FILENAME = N''' + @defaultdatapath + '\2Fast2Furious_data.mdf'' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N''2Fast2Furious_log'', FILENAME = N''' + @defaultlogpath + '\2Fast2Furious_log.ldf'' , SIZE = 1GB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )'
EXEC(@createdb)
GO
ALTER DATABASE [2Fast2Furious] SET RECOVERY SIMPLE
ALTER DATABASE [2Fast2Furious] SET AUTO_CREATE_STATISTICS OFF;
GO

-- Allow the use of on-disk SNAPSHOT ISOLATION in the database
-- this is used in one of the demos and is set to allow ahead
-- of time for convenience
ALTER DATABASE [2Fast2Furious] SET ALLOW_SNAPSHOT_ISOLATION ON
GO

--for ref only
/*
ALTER DATABASE [2Fast2Furious] SET READ_COMMITTED_SNAPSHOT ON WITH NO_WAIT
GO
*/

/*********************/
/* Create Table Cars */
/*********************/
USE [2Fast2Furious]
GO
CREATE TABLE Cars (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000) CONSTRAINT [PK__Cars] PRIMARY KEY CLUSTERED ([id]))
GO


/*********************/
/* Create Table table1 */
/*********************/
USE [2Fast2Furious]
GO
SET NOCOUNT ON
CREATE TABLE table1 (id INT, batchid INT, inv INT)
GO
DECLARE @x INT = 1
WHILE @x < 51000
BEGIN
	INSERT INTO table1 VALUES (@x,0, ABS(50998-@x))
	SET @x = @x+1
END