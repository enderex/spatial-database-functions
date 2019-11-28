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



