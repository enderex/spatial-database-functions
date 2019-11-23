USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STEndPoint]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STEndPoint];
  PRINT 'Dropped [$(owner)].[STEndPoint] ...';
END;
GO

PRINT 'Creating [$(owner)].[STEndPoint] ...';
GO

CREATE FUNCTION [$(owner)].[STEndPoint]
(
  @p_geometry geometry
)
Returns geometry
As
/****f* INSPECT/STEndPoint (2008)
 *  NAME
 *    STEndPoint - Function which returns last point in supplied geometry.
 *  SYNOPSIS
 *    Function STEndPoint (
 *                @p_geometry geometry
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT STEndPoint (
 *             ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0)
 *           ).STAsText() as endPoint;
 *    # endPoint
 *    'POINT(1.4 45.2)'
 *  DESCRIPTION
 *    Function that returns last point in the supplied geometry.
 *  INPUTS
 *    @p_geometry (geometry) - supplied geometry of any type.
 *  RESULT
 *    point      (geometry) - Last point in Geometry
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  IF ( @p_geometry.STIsValid() <> 1 ) 
  BEGIN
    RETURN @p_geometry;
  END;
  RETURN @p_geometry.STPointN(@p_geometry.STNumPoints());
End;
Go

PRINT 'Testing [$(owner)].[STEndPoint] ...';
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('POINT(0 0 0)',0)).AsTextZM() as ENDPOINT
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('MULTIPOINT((0 0 0),(1 1 1))',0)).AsTextZM() as ENDPOINT
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0)).AsTextZM() as ENDPOINT
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('MULTILINESTRING((2 3, 3 4), (1 1, 2 2))',0)).AsTextZM() as ENDPOINT
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0)).AsTextZM() as ENDPOINT
GO

select [$(owner)].[STEndPoint](geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0)).AsTextZM() as ENDPOINT
GO


