SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STNumDims]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STNumDims];
  Print 'Dropped [$(owner)].[STNumDims] ...';
END;
GO

Print 'Creating [$(owner)].[STNumDims] ...';
GO

CREATE FUNCTION [$(owner)].[STNumDims]
( 
  @p_geometry geometry 
)
Returns Int
As
/****f* INSPECT/STNumDims (2012)
 *  NAME
 *    STCoordDim -- Function that returns the coordinate dimension of a geometry object.
 *  SYNOPSIS
 *    Function STNumDims (
 *               @p_point geometry,
 *             )
 *     Returns int 
 *  USAGE
 *    SELECT [$(owner)].[STNumDims] (
               geometry::STGeomFromText('MULTIPOINT((1 1 1))',0) 
 *           ) as coordDim;
 *    coordDim
 *    3
 *  DESCRIPTION
 *    This function processes geometry types other than a point (STCoordDim)
 *    If only XY ordinates, 2 is returned.
 *    If only XYZ or XYM ordinates, 3 is returned.
 *    If XYZM ordinates, 4 is returned.
 *  INPUTS
 *    @p_geometry (geometry) - Supplied geometry.
 *  RESULT
 *    dimensionality (int) - 2,3 or 4.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
    Declare
      @v_ndims Int;
    Begin
        SELECT @v_ndims = (2 + 
                           case when c.point.Z IS NULL then 0 else 1 end + 
                           case when c.point.M IS NULL then 0 else 1 end )
          FROM (SELECT geometry::STGeomFromText(b.PointText,0) as point
                  FROM (select Top 1
                               case when geom.STGeometryType() = 'Point'           then geom.AsTextZM()
                                    when geom.STGeometryType() = 'MultiPoint'      then geom.STGeometryN(1).AsTextZM()
                                    when geom.STGeometryType() = 'LineString'      then geom.STPointN(1).AsTextZM()
                                    when geom.STGeometryType() = 'MultiLineString' then geom.STGeometryN(1).STPointN(1).AsTextZM()
                                    when geom.STGeometryType() = 'Polygon'         then geom.STExteriorRing().STPointN(1).AsTextZM()
                                    when geom.STGeometryType() = 'MultiPolygon'    then geom.STGeometryN(1).STExteriorRing().STPointN(1).AsTextZM()
                                    else geom.STPointN(1).AsTextZM()
                                 end as pointText
                          from (select case when @p_geometry.STGeometryType() = 'GeometryCollection' 
                                            then @p_geometry.STGeometryN(1) 
                                            else @p_geometry 
                                         end as geom 
                               ) as a
                ) as b
          ) as c;
         RETURN @v_ndims;
    END;
END
GO

Print 'Testing [$(owner)].[STNumDims] ...';
GO

With Geoms As (
            select 1 as id, geometry::STGeomFromText('POINT(4 5)',0) as geom
  union all select 2 as id, geometry::STGeomFromText('MULTIPOINT((1 1 1))',0) as geom
  union all select 3 as id, geometry::STGeomFromText('MULTIPOINT((1 1 1),(2 2 2),(3 3 3))',0) as geom
  union all select 4 as id, geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0) as geom
  union all select 5 as id, geometry::STGeomFromText('MULTILINESTRING((2 3, 3 4), (1 1, 2 2))',0) as geom
  union all select 5.1 as id, geometry::STGeomFromText('MULTILINESTRING((1 1 2 3,2 2 3 4),(3 3 4 5,4 4 5 6))',0) as geom
  union all select 5.2 as id, geometry::STGeomFromText('MULTILINESTRING((4 4 5 6,3 3 4 5),(2 2 3 4,1 1 2 3))',0) as geom
  union all select 6 as id, geometry::STGeomFromText('CIRCULARSTRING(0 -23.43778, 0 0, 0 23.43778)',0) as geom
  union all select 7 as id, geometry::STGeomFromText('COMPOUNDCURVE(
    CIRCULARSTRING(0 -23.43778, 0 0, 0 23.43778),
    CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),
    CIRCULARSTRING(-90 23.43778, -90 0, -90 -23.43778),
    CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))',0) as geom
  union all select 8 as id, geometry::STGeomFromText('COMPOUNDCURVE(
    (0 -23.43778, 0 23.43778),
    CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), 
    (-90 23.43778, -90 -23.43778),
    CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))
  ',0) as geom
  union all select  9 as id, geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0) as geom
  union all select 10 as id, geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0) as geom
  union all select 11 as id, geometry::STGeomFromText('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((30 30, 50 30, 50 50, 30 50, 30 30)), ((0 30, 20 30, 20 50, 0 50, 0 30)), ((30 0,31 0,31 1,30 1,30 0)))',0) as geom
  union all select 12 as id, geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5))',0) as geom
  union all select 13 as id, geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0) as geom
  union all select 14 as id, geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 50, 50 100, 100 50, 50 0, 0 50))',0) as geom
  union all select 15 as id, GEOMETRY::STGeomFromText('
  CURVEPOLYGON(
    COMPOUNDCURVE(
      (0 -23.43778, 0 23.43778),
      CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), 
      (-90 23.43778, -90 -23.43778),
      CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)
    )
  )
',0) as geom 
)
select a.geom.AsTextZM() as geom, [$(owner)].[STNumDims](a.geom) as nDims
 from Geoms as a
GO


