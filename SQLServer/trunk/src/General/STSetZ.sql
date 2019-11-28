SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STSetZ]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STSetZ];
  PRINT 'Dropped [$(owner)].[STSetZ] ...';
END;
GO

PRINT 'Creating [$(owner)].[STSetZ] ...';
GO

CREATE FUNCTION [$(owner)].[STSetZ]
(
  @p_geometry geometry,
  @p_z        Float,
  @p_round_xy int   = 3,
  @p_round_zm int   = 2
)
returns geometry 
as
/****f* EDITOR/STSetZ (2012)
 *  NAME
 *    STSetZ -- Function that adds or updates (replaces) Z value of supplied geometry.
 *  SYNOPSIS
 *    Function STSetZ (
 *               @p_geometry geometry,
 *               @p_z        float,
 *               @p_round_xy int = 3,
 *               @p_round_zm int = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT STSetZ(
 *             STPointFromText('POINT(0 0)',0),
 *             1,
 *             3, 2 
 *           ).AsTextZM() as updatedPoint;
 *    # updatedPoint
 *    'POINT(0 0 1)'
 *  DESCRIPTION
 *    Function that adds/updates Z ordinate of the supplied @p_geometry.
 *    If single point, it is updated and returned. 
 *    If Linestring/MultiLinestring, all Z ordinates are set to the supplied value.
 *    The updated coordinate's XY ordinates are rounded to @p_round_xy number of decimal digits of precision.
 *    The updated coordinate's ZM ordinates are rounded to @p_round_ZM number of decimal digits of precision.
 *  INPUTS
 *    @p_point     (geometry) - Supplied geometry.
 *    @p_z         (float)    - Z value.
 *    @p_round_xy  (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm  (int)      - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point with Z (geometry) - Input point geometry with Z set to @p_Z.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_wkt           varchar(max) = '',
    @v_wkt_remainder varchar(max),
    @v_dimensions    varchar(4),
    @v_round_xy      int = 3,
    @v_round_zm      int = 2,
    @v_pos           int = 0,
    @v_point         geometry;
  BEGIN
    If ( @p_geometry is null )
      Return @p_geometry;

    -- Set flag for STPointFromText
    -- @p_dimensions => XY, XYZ, XYM, XYZM or NULL (XY)
    SET @v_dimensions = 'XYZ' 
                       + case when @p_geometry.HasM=1 then 'M' else '' end;
    SET @v_round_xy = ISNULL(@p_round_xy,3); 
    SET @v_round_zm = ISNULL(@p_round_zm,2); 

    -- Shortcircuit for simplest case
    IF ( @p_geometry.STGeometryType() = 'Point' )
    BEGIN
      SET @v_wkt = 'POINT(' 
                   + 
                   [$(owner)].[STPointAsText] (
                     /* @p_dimensions */ @v_dimensions,
                     /* @p_X          */ @p_geometry.STX,
                     /* @p_Y          */ @p_geometry.STY,
                     /* @p_Z          */ @p_Z,
                     /* @p_M          */ @p_geometry.M,
                     /* @p_round_x    */ @v_round_xy,
                     /* @p_round_y    */ @v_round_xy,
                     /* @p_round_z    */ @v_round_zm,
                     /* @p_round_m    */ @v_round_zm
                   )
                   + 
                   ')';
      RETURN geometry::STPointFromText(@v_wkt,@p_geometry.STSrid);
    END;

    -- LineString/MultiLineString
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
         -- Add to WKT but set Z value
         SET @v_wkt   = @v_wkt
                        +
                        [$(owner)].[STPointAsText] (
                                /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                                /* @p_X          */ @v_point.STX,
                                /* @p_Y          */ @v_point.STY,
                                /* @p_Z          */ @p_z,
                                /* @p_M          */ @v_point.M,
                                /* @p_round_x    */ @v_round_xy,
                                /* @p_round_y    */ @v_round_xy,
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
  END;
END
GO

Print 'Testing [$(owner)].[STSetZ] ...';
Print '... Simple Point case ...';
GO

With data as (
  select geometry::Parse('POINT(100.123 100.456 NULL 4.567)') as pointzm
)
SELECT CAST(d.pointzm.STGeometryType() as varchar(20)) as GeomType, 
       d.pointzm.HasZ as z, 
       d.pointzm.HasM as m, 
       CAST([$(owner)].[STSetZ](d.pointzm,99.123,3,1).AsTextZM() as varchar(50)) as rGeom
  FROM data as d; 
GO

Print '... LineStrings ...';
GO

With Data as (
select 'Simple LineString' as lType, geometry::STGeomFromText('LINESTRING (-2 -2, 25 -2)',0) as geom
union all
select 'Simple MultiLineString' as lType, geometry::STGeomFromText('MULTILINESTRING((-2 -2,25 -2),(10 10,11 11))',0) as geom
union all
Select '2D CompoundCurve -> Must have non-NULL Z of same value' as lType,  
       geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as geom
)
select d.lType, 'Before' as status, d.geom.AsTextZM() as geometry from data as d
union all
select d.ltype, 'After'  as status, [$(owner)].[STSetZ] (d.geom,-999,3,1).AsTextZM() as geometry from data as d
order by 1,2 desc;
GO


