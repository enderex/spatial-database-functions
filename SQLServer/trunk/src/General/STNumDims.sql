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
END;
GO

