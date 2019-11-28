PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STNumCircularStrings]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STNumCircularStrings];
  PRINT 'Dropped [$(owner)].[STNumCircularStrings] ...';
END;
GO

PRINT 'Creating [$(owner)].[STNumCircularStrings] ...';
GO

CREATE FUNCTION [$(owner)].[STNumCircularStrings](
  @p_geometry geometry
)
RETURNS integer
AS 
/****f* INSPECTION/STNumCircularStrings (2012)
 *  NAME
 *    STNumCircularStrings-- Returns number of CircularString elements in provided CircularString
 *  SYNOPSIS
 *    Function [$(owner)].[STNumCircularStrings] (
 *                @p_geometry geometry
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    A CircularString can have more than one 3-point string encoded within it.
 *    For example if a circularString has 3 points it only has one circularString in it.
 *    If a circularString has 5 points then it has two CircularStrings in it (Point 3 if end of first and start of second).
 *    This function counts the number of individual CircularStrings in @p_geometry .
 *  INPUTS
 *    @p_geometry       (geometry) -- CircularString
 *  RESULT
 *    NumCircularStrings (integer) -- Number of 3-point CircularStrings within @p_geometry.
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) as cGeom
 *    )
 *    SELECT [$(owner)].[STNumCircularStrings](a.cGeom) as numStrings
 *      FROM data as a
 *    GO
 * 
 *    numStrings
 *    3
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - November 2019 - Ported to SQL Server TSQL from PostgreSQL
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  RETURN CASE WHEN @p_geometry is not null
              THEN (@p_geometry.STNumPoints() - 1) / 2
			  ELSE 0
          END;
END;
GO

PRINT 'Testing [$(owner)].[STNumCircularStrings] ...';
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) as cGeom
)
SELECT [$(owner)].[STNumCircularStrings](a.cGeom) as numStrings
  from data as a;
GO

