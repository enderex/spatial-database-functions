SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STStartPoint]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION  [$(owner)].[STStartPoint];
  PRINT 'Dropped [$(owner)].[STStartPoint] ...';
END;
GO

PRINT 'Creating [$(owner)].[STStartPoint] ...';
GO

CREATE FUNCTION [$(owner)].[STStartPoint]
(
  @p_geometry geometry
)
Returns geometry
As
/****f* INSPECT/STStartPoint (2008)
 *  NAME
 *    ST_Start_Point -- Function which returns first point in supplied geometry.
 *  SYNOPSIS
 *    Function STStartPoint (
 *                @p_geometry geometry
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT STStartPoint(
 *             ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0)
 *           ).STAsText() as startPoint;
 *
 *    # startPoint
 *    'POINT(0.1 0.2)'
 *  DESCRIPTION
 *    Function that returns first point in supplied geometry.
 *  INPUTS
 *    @p_geometry (geometry) - supplied geometry of any type.
 *  RESULT
 *    point       (geometry) - First point in Geometry
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  RETURN @p_geometry.STPointN(1);
End;
Go

PRINT 'Testing [$(owner)].[STStartPoint] ...';
GO

select [$(owner)].[STStartPoint](geometry::STGeomFromText('POINT(0 0 0)',0)).AsTextZM() as STARTPOINT;
GO

select [$(owner)].[STStartPoint](geometry::STGeomFromText('MULTIPOINT((0 0 0),(1 1 1))',0)).AsTextZM() as STARTPOINT;
GO

select [$(owner)].[STStartPoint](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0)).AsTextZM() as STARTPOINT;
GO

select [$(owner)].[STStartPoint](geometry::STGeomFromText('MULTILINESTRING((2 3, 3 4), (1 1, 2 2))',0)).AsTextZM() as STARTPOINT;
GO

select [$(owner)].[STStartPoint](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0)).AsTextZM() as STARTPOINT;
GO

select [$(owner)].[STStartPoint](geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0)).AsTextZM() as STARTPOINT;
GO


