SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STRotate]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STRotate];
  Print 'Dropped [$(owner)].[STRotate] ...';
END;
GO

Print 'Creating [$(owner)].[STRotate] ...';
GO

CREATE FUNCTION [$(owner)].[STRotate]
(
 @p_geometry  geometry,
 @p_rX        float = 0.0,
 @p_rY        float = 0.0,
 @p_angle     int   = 0,  -- 0 to 360 degrees
 @p_round_xy  int   = 3,
 @p_round_zm  int   = 2

)
  Returns geometry
As
/****f* AFFINE/STRotate (2008)
 *  NAME
 *    STRotate -- Function which rotates a geometry.
 *  SYNOPSIS
 *    Function STRotate (
 *               @p_geometry geometry,
 *               @p_rX       float,
 *               @p_rY       float,
 *               @p_angle    float,
 *               @p_round_xy int,
 *               @p_round_zm int 
 *             )
 *     Returns geometry 
 *  USAGE
 *    With data as (
 *    select 'Original' as name, geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0) as geom
 *    )
 *    SELECT name, geom.STAsText() as rGeom 
 *      FROM (select name, geom 
 *              from data as d
 *            union all
 *            select '45' + CHAR(176) + ' rotate about 0,0' as name, [$(owner)].[STRotate](d.geom,0.0,0.0,45,3,3) as geomO
 *              from data as d
 *            union all
 *            select '45' + CHAR(176) + ' rotate about MBR centre' as name, [$(owner)].[STRotate](d.geom,(a.minx + a.maxx) / 2.0,(a.miny + a.maxy) / 2.0,45,3,3) as geom
 *              from data as d
 *                   cross apply
 *                   [$(owner)].[STGEOMETRY2MBR](d.geom) as a
 *          ) as f
 *    GO
 *    name    rGeom
 *    Original    POLYGON ((1 1, 1 6, 11 6, 11 1, 1 1))
 *    45° rotate about 0,0    POLYGON ((0 1.414, -3.536 4.95, 3.536 12.021, 7.071 8.485, 0 1.414))
 *    45° rotate about MBR centre    POLYGON ((4.232 -1.803, 0.697 1.732, 7.768 8.803, 11.303 5.268, 4.232 -1.803))
 *
 *  DESCRIPTION
 *    Function which rotates the supplied geometry around a supplied rotation point (X,Y) a required angle in degrees between 0 and 360.
 *    The computed ordinates of the new geometry are rounded to the appropriate decimal digits of precision.
 *  INPUTS
 *    @p_geometry (geometry) - supplied geometry of any type.
 *    @p_rX       (float)    - X ordinate of rotation point.
 *    @p_rY       (float)    - Y ordinate of rotation point.
 *    @p_angle    (float)    - Rotation angle expressed in decimal degrees between 0 and 360.
 *    @p_round_xy (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm (int)      - Decimal degrees of precision to which calculated XM ordinates are rounded.
 *  RESULT
 *    geometry -- Input geometry rotated by supplied values.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGH
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
     @v_cos_angle     Float,
     @v_sin_angle     Float,
     @v_rX            Float = 0,
     @v_rY            Float = 0,
     @v_x             Float = 0,
     @v_y             Float = 0,
     @v_point         geometry;
  Begin
    If ( @p_geometry is NULL ) 
      Return @p_geometry;

    If ( ( @p_angle is NULL ) Or ( @p_angle NOT BETWEEN -360 AND 360 ) )
      Return @p_geometry;

    SET @v_rX        = ISNULL(@p_rX,0.0);
    SET @v_rY        = ISNULL(@p_rY,0.0); 
    SET @v_cos_angle = COS(@p_angle * PI()/180);
    SET @v_sin_angle = SIN(@p_angle * PI()/180);

    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                       + case when @p_geometry.HasZ=1 then 'Z' else '' end 
                       + case when @p_geometry.HasM=1 then 'M' else '' end;

    -- Shortcircuit for simplest case
    IF ( @p_geometry.STGeometryType() = 'Point' ) 
    Begin
      SET @v_x = (@v_rX + ( ((@p_geometry.STX - @v_rX) * @v_cos_angle) - ((@p_geometry.STY - @v_rY) * @v_sin_angle) ));
      SET @v_y = (@v_rY + ( ((@p_geometry.STX - @v_rX) * @v_sin_angle) + ((@p_geometry.STY - @v_rY) * @v_cos_angle) ));
      SET @v_wkt = 'POINT(' 
                   +
                   [$(owner)].[STPointAsText] (
                          /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ 
                                              @v_dimensions,
                          /* @p_X          */ @v_x,
                          /* @p_Y          */ @v_Y,
                          /* @p_Z          */ @p_geometry.Z,
                          /* @p_M          */ @p_geometry.M,
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
         -- Apply Rotation to XY ordinates ....
         SET @v_x     = (@v_rX + (( (@v_point.STX - @v_rX) * @v_cos_angle) - ((@v_point.STY - @v_rY) * @v_sin_angle) ));
         SET @v_y     = (@v_rY + (( (@v_point.STX - @v_rX) * @v_sin_angle) + ((@v_point.STY - @v_rY) * @v_cos_angle) ));
         -- Add to WKT
         SET @v_wkt   = @v_wkt 
                        + 
                        [$(owner)].[STPointAsText] (
                                /* @p_dimensions XY,XYZ,XYM,XYZM or NULL (XY) */ 
                                                    @v_dimensions,
                                /* @p_X          */ @v_x,
                                /* @p_Y          */ @v_y,
                                /* @p_Z          */ @v_point.Z,
                                /* @p_M          */ @v_point.M,
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
         SET @v_wkt           = @v_wkt 
                                + 
                                SUBSTRING(@v_wkt_remainder,1,1);
         SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,2,LEN(@v_wkt_remainder));
       END;
    END; -- Loop
    Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  End
End
Go

