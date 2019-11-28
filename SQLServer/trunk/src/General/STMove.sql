SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT *
             FROM sysobjects
            WHERE id = object_id (N'[$(owner)].[STMove]')
              AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STMove];
  PRINT 'Dropped [$(owner)].[STMove] ...';
END;
GO

PRINT 'Creating [$(owner)].[STMove] ...';
GO

CREATE FUNCTION [$(owner)].[STMove]
(
  @p_geometry geometry,
  @p_dX       float,
  @p_dY       float,
  @p_dZ       float,
  @p_dM       float,
  @p_round_xy int = 3,
  @p_round_zm int = 2
)
Returns geometry
As
/****f* AFFINE/STMove (2008)
 *  NAME
 *    STMove -- Function which moves a geometry using the supplied delta X, Y, Z and M ordinate values.
 *  SYNOPSIS
 *    Function STMove (
 *               @p_geometry geometry,
 *               @p_dX       float,
 *               @p_dY       float,
 *               @p_dZ       float,
 *               @p_dM       float,
 *               @p_round_xy int = 3,
 *               @p_round_zm int = 2
 *             )
 *     Returns geometry
 *  USAGE
 *    SELECT [$(owner)].[STMove](geometry::ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),-5.0,30.1,default,default,2,1).AsTextZM() as movedGeom;
 *    # movedGeom
 *    'LINESTRING(-4.9 30.2,-3.6 31.5)'
 *  DESCRIPTION
 *    Function that moves the supplied geometry's ordinates the supplied x, y, z and m deltas.
 *    The computed ordinates of the new geometry are rounded to @p_round_xy/@p_round_zm number of decimal digits of precision.
 *  INPUTS
 *    @p_geometry (geometry) - Supplied geometry of any type.
 *    @p_dX          (float) - X ordinate delta shift.
 *    @p_dy          (float) - Y ordinate delta shift.
 *    @p_dZ          (float) - Z ordinate delta shift.
 *    @p_dM          (float) - M ordinate delta shift.
 *    @p_round_xy      (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm      (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    moved geom  (geometry) - Input geometry moved by supplied X and Y ordinate deltas.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
     @v_wkt           varchar(max) = '',
     @v_wkt_remainder varchar(max),
     @v_dimensions    varchar(4),
     @v_round_xy      int = 3,
     @v_round_zm      int = 2,
     @v_pos           int = 0,
     @v_dX            float,
     @v_dY            float,
     @v_dZ            float,
     @v_dM            float,
     @v_x             Float = 0.0,
     @v_y             Float = 0.0,
     @v_z             Float = NULL,
     @v_m             Float = NULL,
     @v_point         geometry;
  Begin
    If ( @p_geometry is NULL )
      Return @p_geometry;

    SET @v_dX = ISNULL(@p_dX,0.0);
    SET @v_dY = ISNULL(@p_dY,0.0);
    SET @v_dZ = ISNULL(@p_dZ,0.0);
    SET @v_dM = ISNULL(@p_dM,0.0);

    If ( @v_dX = 0.0 AND @v_dY = 0.0 AND @v_dZ = 0.0 AND @v_dM = 0.0)
      Return @p_geometry;

    SET @v_dimensions = 'XY'
                        + case when @p_geometry.HasZ=1 then 'Z' else '' end +
                        + case when @p_geometry.HasM=1 then 'M' else '' end;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    -- Shortcircuit for simplest case
    IF ( @p_geometry.STGeometryType() = 'Point' )
    BEGIN
      SET @v_wkt = 'POINT('
                   +
                   [$(owner)].[STPointAsText] (
                          /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                          /* @p_X          */ @p_geometry.STX + @v_dX,
                          /* @p_Y          */ @p_geometry.STY + @v_dY,
                          /* @p_Z          */ @p_geometry.Z   + @v_dZ,
                          /* @p_M          */ @p_geometry.M   + @v_dM,
                          /* @p_round_x    */ @p_round_xy,
                          /* @p_round_y    */ @p_round_xy,
                          /* @p_round_z    */ @p_round_zm,
                          /* @p_round_m    */ @p_round_zm
                   )
                   +
                   ')';
      Return geometry::STPointFromText(@v_wkt,@p_geometry.STSrid);
    END;

    SET @v_wkt_remainder = @p_geometry.AsTextZM();
    SET @v_wkt           = SUBSTRING(@v_wkt_remainder,1,CHARINDEX('(',@v_wkt_remainder));
    SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,  CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));

    WHILE ( LEN(@v_wkt_remainder) > 0 )
    BEGIN
       -- Is the start of v_wkt_remainder a coordinate?
       IF ( @v_wkt_remainder like '[-0-9]%' )
        BEGIN
         -- We have a coord
         -- Now get position of end of coordinate string
         SET @v_pos = case when CHARINDEX(',',@v_wkt_remainder) = 0
                           then CHARINDEX(')',@v_wkt_remainder)
                           when CHARINDEX(',',@v_wkt_remainder) <> 0 and CHARINDEX(',',@v_wkt_remainder) < CHARINDEX(')',@v_wkt_remainder)
                           then CHARINDEX(',',@v_wkt_remainder)
                           else CHARINDEX(')',@v_wkt_remainder)
                       end;
         -- Create a geometry point from WKT coordinate string
         SET @v_point = geometry::STPointFromText(
                          'POINT('
                          +
                          SUBSTRING(@v_wkt_remainder,1,@v_pos-1)
                          +
                          ')',
                          @p_geometry.STSrid);
         -- Apply the delta to the ordinates
         SET @v_x     = @v_point.STX + @v_dX;
         SET @v_y     = @v_point.STY + @v_dY;
         SET @v_z     = @v_point.Z   + @v_dZ;
         SET @v_m     = @v_point.M   + @v_dM;
         -- Add to WKT
         SET @v_wkt   = @v_wkt
                        +
                        [$(owner)].[STPointAsText] (
                                /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                                /* @p_X          */ @v_x,
                                /* @p_Y          */ @v_y,
                                /* @p_Z          */ @v_z,
                                /* @p_M          */ @v_m,
                                /* @p_round_x    */ @p_round_xy,
                                /* @p_round_y    */ @p_round_xy,
                                /* @p_round_z    */ @v_round_zm,
                                /* @p_round_m    */ @v_round_zm
                        );
         -- Now remove the old coord from v_wkt_remainder
         SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,@v_pos,LEN(@v_wkt_remainder));
       END
       ELSE
       BEGIN
         -- Move to next character
         SET @v_wkt           = @v_wkt + SUBSTRING(@v_wkt_remainder,1,1);
         SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,2,LEN(@v_wkt_remainder));
       END;
    END; -- Loop
    Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  End;
End;
GO

PRINT 'Testing [$(owner)].[STMove] ...';
GO

-- Point
select [$(owner)].[STMove](geometry::STPointFromText('POINT(0 0)',0),-5.0,30.1,default,default,2,1).STAsText() as movedGeom;
GO
-- # movedGeom
-- 'POINT(-5 30.1)'

-- MultiPoint
SELECT [$(owner)].[STMove](geometry::STGeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),-100,-3000,default,default,2,1).STAsText() as rGeom;
GO
-- # rGeom
-- 'MULTIPOINT((0.12 -2899.65),(288.84 -2500.6))'

-- Linestring
select [$(owner)].[STMove](geometry::STGeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),-5.0,30.1,default,default,2,1).STAsText() as movedGeom;
GO
-- # movedGeom
-- 'LINESTRING(-4.9 30.2,-3.6 75.3)'

-- Polygon
select [$(owner)].[STMove](geometry::STGeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),-5.0,30.1,default,default,2,1).STAsText() as movedGeom;
GO
-- # movedGeom
-- 'POLYGON((-5 30.1,5 30.1,5 40.1,-5 40.1,-5 30.1))'

select [$(owner)].[STMove](
         geometry::STGeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
          -50,-100,default,default,2,1).STAsText() as movedGeom;
GO
-- # movedGeom
-- 'MULTIPOLYGON(((110 300,150 300,150 380,110 380,110 300)),((50 100,130 200,50 200,50 100)))'


