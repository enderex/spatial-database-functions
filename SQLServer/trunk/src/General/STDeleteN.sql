SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STDeleteN]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STDeleteN];
  Print 'Dropped [$(owner)].[STDeleteN] ...';
END;
GO

PRINT 'Creating [$(owner)].[STDeleteN] ...';
GO

CREATE FUNCTION [$(owner)].[STDeleteN]
(
  @p_geometry geometry,
  @p_position int = 1,
  @p_round_xy int = 3,
  @p_round_zm int = 2
)
Returns geometry
As
/****f* EDITOR/STDeleteN (2008)
 *  NAME
 *    STDeleteN -- Function which deletes referenced coordinate from the supplied geometry.
 *  SYNOPSIS
 *    Function STDeleteN (
 *               @p_geometry geometry,
 *               @p_position int, 
 *               @p_round_xy int = 3,
 *               @p_round_zm int = 2 
 *             (
 *     Returns geometry 
 *  USAGE
 *    SELECT STDeleteN(STGeomFromText('LINESTRING(0.1 0.2,1.4 45.2,120 394.23)',0),2,3,2).STAsText() as deleteGeom; 
 *    # deleteGeom
 *    'LINESTRING(0.1 0.2,120 394.23)'
 *  DESCRIPTION
 *    Function that removes a single, nominated, coordinates from the supplied geometry.
 *    The function does not process POINT or GEOMETRYCOLLECTION geometries.
 *    The point to be deleted is supplied as a single integer.
 *    The point number can be supplied as -1 (last number), or 1 to the total number of points in a WKT representation of the object.
 *    A point number does not refer to a specific point within a specific sub-geometry eg point number 1 in the 2nd interiorRing in a polygon object.
 *  INPUTS
 *    @p_geometry   (geometry) - supplied geometry of any type.
 *    @p_position   (int) - Valid point number in geometry.
 *    @p_round_xy   (int) - Rounding value for XY ordinates.
 *    @p_round_zm   (int) - Rounding value for ZM ordinates.
 *  RESULT
 *    modified geom (geometry) - With referenced point deleted. 
 *  NOTES
 *    May throw error message STGeomFromText error if point deletion invalidates the geometry.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Return [$(owner)].[STDelete] (
            @p_geometry,
            CAST(ISNULL(@p_position,1) as varchar(10)),
            @p_round_xy,
            @p_round_zm
         );
End;
GO

