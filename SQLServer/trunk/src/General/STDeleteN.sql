USE $(usedbname)
GO

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

Print 'Creating [$(owner)].[STDeleteN] ...';
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
End
GO

/* ************************ TESTING *****************************/

PRINT 'Testing [$(owner)].[STDeleteN] ...';
GO

select 'Single Point - No Action' AS message, 
       [$(owner)].[STDeleteN](geometry::STGeomFromText('POINT(0 0 1 1)',0),1,3,2).AsTextZM() as WKT
GO

select 'MultiPoint - No Action'   as message, 
       [$(owner)].[STDeleteN](geometry::STGeomFromText('MULTIPOINT((0 0 1 1))',0),1,3,2).AsTextZM() as WKT
GO
select 'MultiPoint - All Points'  as message, 
       t.IntValue,
       [$(owner)].[STDeleteN](geometry::STGeomFromText('MULTIPOINT((1 1 1 1),(2 2 2 2),(3 3 3 3))',0),t.IntValue,3,2).AsTextZM() as WKT
  from [$(owner)].[generate_series](-1,4,1) as t
GO

Select 'LineString - All Points' as message, 
       t.IntValue, 
       [$(owner)].[STDeleteN](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),t.IntValue,3,2).AsTextZM() as WKT 
  from [$(owner)].[generate_series](-1,5,1) as t
GO

select 'MultiLineString - All Points' as message, 
       t.IntValue,
       [$(owner)].[STDeleteN](geometry::STGeomFromText('MULTILINESTRING((1 1,2 2,3 3),(4 4,5 5,6 6))',0),t.IntValue,3,2).AsTextZM() as WKT
  from [$(owner)].[generate_series](-1,7,1) as t
GO

with poly as (
  select geometry::STGeomFromText('POLYGON((326000.0 5455000.0,327000.0 5455000.0,326820 5455440,326500.0 5456000.0,326000.0 5455000.0))',0) as poly
)
select 'ExteriorRing -- Sufficient Points - Note first and last point avoided.' as message, 
       t.IntValue,
       [$(owner)].[STDeleteN](a.poly,t.intValue,3,2).AsTextZM() as t
  from poly as a cross apply [$(owner)].[generate_series](2,a.poly.STNumPoints()-1,1) as t
GO

select 'SAME OUT' as message, 
       [$(owner)].[STDeleteN](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0),
                        3,3,2).AsTextZM() as WKT
GO

Select 'LineString - Points' as message, 
       [$(owner)].[STDelete](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),'1,2',3,2).AsTextZM() as WKT 
GO

Select 'LineString - Last Point' as message, 
       [$(owner)].[STDeleteN](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),-1,3,2).AsTextZM() as WKT 
GO


