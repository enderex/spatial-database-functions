SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '********************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), Owner($(owner))';
GO

IF EXISTS (SELECT * 
            FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STIsPseudoMultiCurve]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STIsPseudoMultiCurve];
  PRINT 'Dropped [$(owner)].[STIsPseudoMultiCurve] ...';
END;
GO

PRINT 'Creating [$(owner)].[STIsPseudoMultiCurve] ...';
GO

Create Function [$(owner)].[STIsPseudoMultiCurve]
(
  @p_geometry geometry
)
Returns bit 
As
/****f* INSPECT/STIsPseudoMultiCurve (2012)
 *  NAME
 *    STIsPseudoMultiCurve -- Checks if supplied @p_geometry is a GeometryCollection object containing only LineString, CircularString and CompoundCurve elements.
 *  SYNOPSIS
 *    Function [$(owner)].[STIsPseudoMultiCurve] (
 *       @p_geometry geometry
 *    )
 *    Returns bit
 *  DESCRIPTION
 *    This function checks if the supplied @p_geometry is a GeometryCollection object containing only LineString, CircularString and CompoundCurve elements.
 *
 *    One cannot create a MultiLineString object where an element is a CircularString or CompoundCurve.
 *
 *    Any attempt to do so causes the GeometryType to be set to GeometryCollection rather than MultiLineString or MultiCurve.
 *
 *    If these sorts of GeometryCollection objects are not supported, it is impossible to represent a MultiLine object with a mix of CircularCurve and LineString types.
 *
 *    Function returns 1 (true) if provided geometry is a pseudo MultiCurve (or MultiLineString)
 *  INPUTS
 *    @p_geometry (geometry) - GeometryCollection or MultiLineString.
 *  RESULT
 *    1/0              (bit) - 1 (true) if pseudo MultiCurve, 0 (false) otherwise.
 *  EXAMPLE
 *    -- This is how SQL Server merges a LineString and a CircularString that do not touch
 *    -- 
 *    SELECT geometry::STGeomFromText('LINESTRING(0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6)',0)
 *           .STUnion(
 *             geometry::STGeomFromText('CIRCULARSTRING(-0.5 -0.5 0 5.6,-0.2 -0.4 0 5.5, -0.1 -0.1 0 5.65)',0)
 *           ).AsTextZM() as MultiCurve;
 *    GO
 *
 *    MultiCurve
 *    --------------------------------------------------------------------------------------------------
 *    GEOMETRYCOLLECTION (LINESTRING (5 10, 5 5, 0 0), CIRCULARSTRING (-0.5 -0.5, -0.2 -0.4, -0.1 -0.1))
 *
 *    -- Note that STUnion removes Z and M ordinates
 *
 *    -- Now put result through STIsPseudoMultiCurve
 *    -- 
 *    SELECT [$(owner)].STIsPseudoMultiCurve ( geometry::STGeomFromText('GEOMETRYCOLLECTION (LINESTRING (5 10, 5 5, 0 0), CIRCULARSTRING (-0.5 -0.5, -0.2 -0.4, -0.1 -0.1))',0)) as isMultiCurve
 *    GO
 *
 *    isMultiCurve
 *    ------------
 *    1
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2018 - Original coding for SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_geomn    int,
    @v_numGeoms int,
    @v_geom     geometry;
  Begin
    IF ( @p_geometry is null ) 
      Return 0;
    IF ( @p_geometry.STGeometryType() = 'MultiLineString' )
      Return 1;
    IF ( @p_geometry.STGeometryType() <> 'GeometryCollection' )
      Return 0;
    -- Check all elements
    SET @v_geomn    = 1;
    SET @v_NumGeoms = @p_geometry.STNumGeometries();
    -- Loop over all elements or curves ....
    WHILE ( @v_geomn <= @v_NumGeoms )
    BEGIN
      SET @v_geom = @p_geometry.STGeometryN(@v_geomn);
      IF ( @v_geom.STGeometryType() NOT IN ('LineString','CircularString','CompoundCurve') )
        Return 0;
      SET @v_geomn = @v_geomn + 1;
    END;
    Return 1;
  End;
End;
GO
 
PRINT '***********************************************';
PRINT 'Testing [$(owner)].[STIsPseudoMultiCurve]....';
GO

-- Produces 2D pseudo MultiCurve
select         geometry::STGeomFromText('MULTILINESTRING((-5 0 0 1,-2.5 -2.5 0 1.5,-0.5 -0.5 0 5.6), (0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6))',0)
      .STUnion(geometry::STGeomFromText('CIRCULARSTRING(-0.5 -0.5 0 5.6,-0.2 -0.4 0 5.5, -0.1 -0.1 0 5.65)',0)).AsTextZM() as MultiCurve;
GO

select f.MultiCurve.STGeometryType() as gType,
       [$(owner)].[STIsPseudoMultiCurve] ( f.MultiCurve ) as isPseudoMultiCurve
  from (select geometry::Point(0,0,0) as MultiCurve
        union all
        select geometry::STGeomFromText('LINESTRING(-5 0 0 1,-2.5 -2.5 0 1.5,-0.5 -0.5 0 5.6)',0) as MultiCurve
        union all
        select geometry::STGeomFromText('MULTILINESTRING((-5 0 0 1,-2.5 -2.5 0 1.5,-0.5 -0.5 0 5.6), (0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6))',0) as MultiCurve
        union all
        select geometry::STGeomFromText('GEOMETRYCOLLECTION (LINESTRING (5 10, 5 5, 0 0), COMPOUNDCURVE ((-5 0, -2.5 -2.5, -0.5 -0.5), CIRCULARSTRING (-0.5 -0.5, -0.2 -0.4, -0.1 -0.1)))',0) as MultiCurve
        union all
        select geometry::STGeomFromText('GEOMETRYCOLLECTION (LINESTRING (5 10 0 0, 5 5, 0 0 0 5), COMPOUNDCURVE ((-5 0 0 10, -2.5 -2.5 0 11.2, -0.5 -0.5 0 12.1), CIRCULARSTRING (-0.5 -0.5 0 12.1, -0.2 -0.4 0 13.4, -0.1 -0.1 0 14.2)))',0) as MultiCurve
       ) as f;
GO


