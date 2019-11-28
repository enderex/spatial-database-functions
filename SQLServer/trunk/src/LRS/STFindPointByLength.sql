SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS(lrs) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindPointByLength]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindPointByLength];
  PRINT 'Dropped [$(lrsowner)].[STFindPointByLength] ... ';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindPointByRatio]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindPointByRatio];
  PRINT 'Dropped [$(lrsowner)].[STFindPointByRatio] ... ';
END;
GO

-- ***************************************************************************************

Print 'Creating [$(lrsowner)].[STFindPointByLength] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindPointByLength] 
(
  @p_linestring geometry,
  @p_length     Float,
  @p_offset     Float = 0.0,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
Returns geometry 
AS
/****f* LRS/STFindPointByLength (2012)
 *  NAME
 *    STFindPointByLength -- Returns (possibly offset) point geometry at supplied distance along linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFindPointByLength] (
 *               @p_linestring geometry,
 *               @p_length     Float,
 *               @p_offset     Float = 0.0,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a length (0 to @p_linestring.STLength()), this function returns a geometry point at the position described by that length.
 *
 *    If a non-zero/null value is suppied for @p_offset, the found point is offset (perpendicular to line) to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *
 *    The returned point has its ordinate values rounded using the supplied @p_round_xy/@p_round_zm decimal place values.
 *  NOTES
 *    Supports LineStrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry.
 *    @p_length        (float) - Length defining position of point to be located. Valid values between 0.0 and @p_linestring.STLength()
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point         (geometry) - Point at provided distance from start, offset to left or right.
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
 *      union all
 *      select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
 *      union all 
 *      select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 NULL 0, 0 7 NULL 3.08, -3 6.3246 NULL 6.15),(-3 6.3246 NULL 6.15, 0 0 NULL 10.1, 3 6.3246 NULL 20.2))',0) as linestring
 *      union all
 *      select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
 *    )
 *    select a.linestring.STGeometryType() as line_type,
 *           a.linestring.HasM as is_measured,
 *           g.intValue as length,
 *           offset.IntValue as offset,
 *           [$(lrsowner)].[STFindPointByLength](a.linestring,g.IntValue,offset.IntValue,3,2).AsTextZM() as fPoint
 *      from data as a
 *           cross apply
 *           [dbo].[generate_series](0,a.lineString.STLength(),a.linestring.STLength() / 4.0 ) as g
 *           cross apply
 *           [dbo].[generate_series](-1,1,1) as offset
 *    order by line_type, is_measured, length
 *    GO
 *    
 *    line_type      is_measured length offset fPoint
 *    CircularString           1      0     -1 POINT (3.428 7.229 NULL 0)
 *    CircularString           1      0      0 POINT (3 6.325 NULL 0)
 *    CircularString           1      0      1 POINT (2.572 5.421 NULL 0)
 *    CircularString           1      1     -1 POINT (2.364 7.643 NULL 0.99)
 *    CircularString           1      1      0 POINT (2.069 6.687 NULL 0.99)
 *    CircularString           1      1      1 POINT (1.774 5.732 NULL 0.99)
 *    CircularString           1      2     -1 POINT (1.252 7.901 NULL 1.98)
 *    CircularString           1      2      0 POINT (1.096 6.914 NULL 1.98)
 *    CircularString           1      2      1 POINT (0.939 5.926 NULL 1.98)
 *    CircularString           1      3     -1 POINT (0.115 7.999 NULL 2.98)
 *    CircularString           1      3      0 POINT (0.1 6.999 NULL 2.98)
 *    CircularString           1      3      1 POINT (0.086 5.999 NULL 2.98)
 *    CircularString           1      4     -1 POINT (-1.025 7.934 NULL 3.97)
 *    CircularString           1      4      0 POINT (-0.897 6.942 NULL 3.97)
 *    CircularString           1      4      1 POINT (-0.769 5.951 NULL 3.97)
 *    CircularString           1      5     -1 POINT (-2.144 7.707 NULL 4.96)
 *    CircularString           1      5      0 POINT (-1.877 6.744 NULL 4.96)
 *    CircularString           1      5      1 POINT (-1.609 5.78 NULL 4.96)
 *    CircularString           1      6     -1 POINT (-3.22 7.324 NULL 5.95)
 *    CircularString           1      6      0 POINT (-2.818 6.408 NULL 5.95)
 *    CircularString           1      6      1 POINT (-2.415 5.493 NULL 5.95)
 *    CompoundCurve            0      0     -1 POINT (3.429 7.228)
 *    CompoundCurve            0      0      0 POINT (3 6.3246)
 *    CompoundCurve            0      0      1 POINT (2.571 5.421)
 *    CompoundCurve            0      5     -1 POINT (-2.144 7.707)
 *    CompoundCurve            0      5      0 POINT (-1.876 6.744)
 *    CompoundCurve            0      5      1 POINT (-1.608 5.78)
 *    CompoundCurve            0     10     -1 POINT (-0.468 3.321)
 *    CompoundCurve            0     10      0 POINT (-1.372 2.892)
 *    CompoundCurve            0     10      1 POINT (-2.276 2.463)
 *    CompoundCurve            0     15     -1 POINT (-0.133 2.054)
 *    CompoundCurve            0     15      0 POINT (0.771 1.625)
 *    CompoundCurve            0     15      1 POINT (1.675 1.196)
 *    CompoundCurve            0     20     -1 POINT (2.01 6.572)
 *    CompoundCurve            0     20      0 POINT (2.914 6.143)
 *    CompoundCurve            0     20      1 POINT (3.818 5.714)
 *    CompoundCurve            1      0     -1 POINT (3.429 7.228 NULL 0)
 *    CompoundCurve            1      0      0 POINT (3 6.3246 NULL 0)
 *    CompoundCurve            1      0      1 POINT (2.571 5.421 NULL 0)
 *    CompoundCurve            1      5     -1 POINT (-2.144 7.707 NULL 4.96)
 *    CompoundCurve            1      5      0 POINT (-1.876 6.744 NULL 4.96)
 *    CompoundCurve            1      5      1 POINT (-1.608 5.78 NULL 4.96)
 *    CompoundCurve            1     10     -1 POINT (-0.468 3.321 NULL 6.89)
 *    CompoundCurve            1     10      0 POINT (-1.372 2.892 NULL 6.89)
 *    CompoundCurve            1     10      1 POINT (-2.276 2.463 NULL 6.89)
 *    CompoundCurve            1     15     -1 POINT (-0.133 2.054 NULL 11)
 *    CompoundCurve            1     15      0 POINT (0.771 1.625 NULL 11)
 *    CompoundCurve            1     15      1 POINT (1.675 1.196 NULL 11)
 *    CompoundCurve            1     20     -1 POINT (2.01 6.572 NULL 13.5)
 *    CompoundCurve            1     20      0 POINT (2.914 6.143 NULL 13.5)
 *    CompoundCurve            1     20      1 POINT (3.818 5.714 NULL 13.5)
 *    LineString               1      0     -1 POINT (-4.707 -3.293 0 1)
 *    LineString               1      0      0 POINT (-4 -4 0 1)
 *    LineString               1      0      1 POINT (-3.293 -4.707 0 1)
 *    LineString               1      6     -1 POINT (0.343 1 0 5.73)
 *    LineString               1      6      0 POINT (0.343 0 0 5.73)
 *    LineString               1      6      1 POINT (0.343-1 0 5.73)
 *    LineString               1     12     -1 POINT (6.343 1 0 8.07)
 *    LineString               1     12      0 POINT (6.343 0 0 8.07)
 *    LineString               1     12      1 POINT (6.343-1 0 8.07)
 *    LineString               1     18     -1 POINT (9 2.343 0 16.5)
 *    LineString               1     18      0 POINT (10 2.343 0 16.5)
 *    LineString               1     18      1 POINT (11 2.343 0 16.5)
 *    LineString               1     24     -1 POINT (9 8.343 0 18.79)
 *    LineString               1     24      0 POINT (10 8.343 0 18.79)
 *    LineString               1     24      1 POINT (11 8.343 0 18.79)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
******/
BEGIN
  DECLARE
    @v_gtype                varchar(30),
    @v_dimensions           varchar(4),
    @v_round_xy             int,
    @v_round_zm             int,

    @v_reversed_length      int,
    @v_length_point         geometry,
    @v_line_geom            geometry,

    @v_bearing_from_start   Float,
    @v_length_from_start    Float,
      @v_length_ratio         float,
    @v_offset_bearing       Float,
    @v_offset_distance      Float,

    /* segment Variables */
    @v_id                   int,
    @v_element_id           int,
    @v_prev_element_id      int,
    @v_subelement_id        int,
    @v_segment_id           int, 
    @v_sx                   float,  /* Start Point */
    @v_sy                   float,
    @v_sz                   float,
    @v_sm                   float,
    @v_mx                   float,  /* Mid Point */
    @v_my                   float,
    @v_mz                   float,
    @v_mm                   float,
    @v_ex                   float,  /* End Point */
    @v_ey                   float,
    @v_ez                   float,
    @v_em                   float,
    @v_segmentLength        float,
    @v_startLength   float,
    @v_measureRange         float;
  BEGIN
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( @p_length is null )
      Return @p_linestring;

    SET @v_gtype = @p_linestring.STGeometryType();

    IF ( @v_gtype NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return @p_linestring;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_offset_distance   = ISNULL(@p_offset,0.0)

    -- Shortcircuit:
    -- If same point as start/end and no offset
    -- 
    IF ( @v_offset_distance = 0.0 and ( @p_length = 0.0 or @p_length = @p_linestring.STLength() ) )
    BEGIN
      Return case when @p_length = 0.0
                  then @p_linestring.STPointN(1)
                  else @p_linestring.STPointN(@p_linestring.STNumPoints())
              end;
    END;

    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;

    -- Filter to find specific segment containing length position
    --
    SELECT TOP 1
           @v_id            = v.id, 
           @v_element_id    = v.element_id, 
           @v_subelement_id = v.subelement_id, 
           @v_segment_id    = v.segment_id, 
           @v_sx            = v.sx, 
           @v_sy            = v.sy, 
           @v_sz            = v.sz, 
           @v_sm            = v.sm,
           @v_ex            = v.ex, 
           @v_ey            = v.ey, 
           @v_ez            = v.ez, 
           @v_em            = v.em,
           @v_mx            = v.mx, 
           @v_my            = v.my, 
           @v_mz            = v.mz, 
           @v_mm            = v.mm,
           @v_segmentLength = v.Length,
           @v_startLength   = v.StartLength,
           @v_measureRange  = v.measureRange,
           @v_line_geom     = v.geom
      FROM [$(lrsowner)].[STFilterLineSegmentByLength](
                  @p_linestring,
                  @p_length,
                  @p_length,
                  @v_round_xy,
                  @v_round_zm
           ) as v;

    IF  @@ROWCOUNT = 0
    BEGIN
      RETURN NULL;
    END

    -- We have a single row (first filtered segment) and it always contains required length point
    --

    -- If returned @v_line_geom is CircularString (3 point)
    -- Use STFindArcPointBYLength function
    --
    IF ( @v_line_geom.STGeometryType() = 'CircularString' )
    BEGIN
      -- Set length relative to start of returned linestring
      IF ( @p_length > @v_startLength )
        SET @v_length_from_start = @p_length - @v_startLength
      ELSE
        SET @v_length_from_start = @p_length;
      SET @v_length_point = [$(lrsowner)].[STFindArcPointByLength] (
                               /* @p_circular_arc */ @v_line_geom,
                               /* @p_length */       @v_length_from_start,
                               /* @p_offset */       @p_offset,
                               /* @p_round_xy */     @v_round_xy,
                               /* @p_round_zm */     @v_round_zm
                            );
      RETURN @v_length_point;
    END;

    -- Compute common bearing ...
    SET @v_bearing_from_start = [$(cogoowner)].[STBearing] (
                                           @v_sx,
                                           @v_sy,
                                           @v_ex,
                                           @v_ey
                                );

    -- Short circuit calculations if @p_length = start or end lengths
    --
    IF ( @p_length = @v_startLength 
      or @p_length = @v_startLength + @v_segmentLength )
    BEGIN
      SET @v_length_point = geometry::STPointFromText(
                               'POINT('
                                +
                                [$(owner)].[STPointAsText] (
                                         /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                                         /* @p_X          */ case when @p_length = @v_startLength then @v_sx else @v_ex end,
                                         /* @p_Y          */ case when @p_length = @v_startLength then @v_sy else @v_ey end,
                                         /* @p_Z          */ case when @p_length = @v_startLength then @v_sz else @v_ez end,
                                         /* @p_M          */ case when @p_length = @v_startLength then @v_sm else @v_em end,
                                         /* @p_round_x    */ @v_round_xy,
                                         /* @p_round_y    */ @v_round_xy,
                                         /* @p_round_z    */ @v_round_zm,
                                         /* @p_round_m    */ @v_round_zm
                                 )
                                 +
                                 ')',
                                 @p_linestring.STSrid);
      -- To be done: offset bearing is mid angle when start/end between two segments.
      -- see COGO function: STOffsetBetween(first_segment,second_segment);
    END
    ELSE
    BEGIN
      --Compute point within segment by bearing/distance and length from start point.
      SET @v_length_from_start = @p_length - @v_startLength;
      SET @v_length_point      = [$(cogoowner)].[STPointFromBearingAndDistance] (
                                       @v_sx,
                                       @v_sy,
                                       @v_bearing_from_start,
                                       @v_length_from_start,
                                       @V_round_xy,
                                       @p_linestring.STSrid 
                                 );

    END;

    -- Offset the point if required
    IF (    @v_offset_distance is not null 
        and @v_offset_distance <> 0.0 ) 
    BEGIN
      -- Compute offset bearing
      SET @v_offset_bearing = case when (@v_offset_distance < 0) 
                                   then (@v_bearing_from_start-90.0) 
                                   else (@v_bearing_from_start+90.0) 
                               end;

      -- Normalise
      SET @v_offset_bearing = [$(cogoowner)].[STNormalizeBearing](@v_offset_bearing);

      -- compute offset point from length point
      SET @v_length_point = [$(cogoowner)].[STPointFromCOGO] ( 
                               @v_length_point,
                               @v_offset_bearing,
                               abs(@v_offset_distance),
                               @v_round_xy
                            );
    END;
    -- Compute Measure and add to Measure position.
    SET @v_length_ratio   = (@p_length - @v_startLength) / @p_linestring.STLength();
    SET @v_length_point   = geometry::STPointFromText(
                            'POINT(' 
                            + 
                            [$(owner)].[STPointAsText] (
                              /* @p_dimensions */ @v_dimensions,
                              /* @p_X          */ @v_length_point.STX,
                              /* @p_Y          */ @v_length_point.STY,
                              /* @p_Z          */ @v_sZ + ((@v_eZ-@v_sZ)*@v_length_ratio),
                              /* @p_M          */ @v_sM + ((@v_eM-@v_sM)*@v_length_ratio),
                              /* @p_round_x    */ @v_round_xy,
                              /* @p_round_y    */ @v_round_xy,
                              /* @p_round_z    */ @v_round_zm,
                              /* @p_round_m    */ @v_round_zm
                            )
                            + 
                            ')',
                            @p_linestring.STSrid
                          );
    Return @v_length_point;
  END;  
END;
GO

Print 'Creating [$(lrsowner)].[STFindPointByRatio] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindPointByRatio] 
(
  @p_linestring geometry,
  @p_ratio    Float,
  @p_offset   Float = 0.0,
  @p_round_xy int   = 3,
  @p_round_zm int   = 2
)
Returns geometry 
AS
/****f* LRS/STFindPointByRatio (2012)
 *  NAME
 *    STFindPointByRatio -- Returns (possibly offset) point geometry at supplied length ratio along linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFindPointByRatio] (
 *               @p_linestring geometry,
 *               @p_ratio      Float,
 *               @p_offset     Float = 0.0,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a ratio (0 to 1.0), this function returns a geometry point at the position described by that ratio.
 *
 *    Ratio is combined with length, so @p_ratio of 1.0 is equivalent to @p_linestring.STLength() ie @p_linestring.STEndPoint().
 *
 *    For example, @p_ratio value of 0.5 returns point at exact midpoint of linestring (ct centroid).
 *
 *    If a non-zero/null value is suppied for @p_offset, the found point is offset (perpendicular to line) to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *
 *    The returned point has its ordinate values rounded using the supplied @p_round_xy/@p_round_zm decimal place values.
 *  NOTES
 *    Supports LineStrings with CircularString elements.
 *    Wrapper over STFindPointByLength
 *  INPUTS
 *    @p_linestring (geometry) - Linestring (including CircularString) geometry.
 *    @p_ratio         (float) - Length ratio between 0.0 and 1.0. If Null, @p_linestring is returned.
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in STSrid units.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point         (geometry) - Point at provided length ratio from start, with optional offset to left or right.
 *  EXAMPLE
 *    -- LineString test.
 *    select f.ratio,
 *           o.IntValue as offset,
 *           [$(lrsowner)].[STFindPointByRatio] (
 *              geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0),
 *              f.ratio,
 *              o.IntValue,
 *              3,
 *              2
 *           ).AsTextZM() as fPoint
 *      from (select 0.01 * CAST(t.IntValue as numeric) as ratio
 *              from [dbo].[Generate_Series](1,100,10) as t
 *          	) as f
 *          	cross apply 
 *            [dbo].[generate_series](-1,1,1) as o
 *      order by f.ratio
 *    GO
 *
 *    ratio offset fPoint
 *    0.01      -1  POINT (-4.526 -3.112 0 1.05)
 *    0.01       0  POINT (-3.819 -3.819 0 1.05)
 *    0.01       1  POINT (-3.112 -4.526 0 1.05)
 *    0.11      -1  POINT (-2.711 -1.297 0 1.51)
 *    0.11       0  POINT (-2.004 -2.004 0 1.51)
 *    0.11       1  POINT (-1.297 -2.711 0 1.51)
 *    0.21      -1  POINT (-0.897 0.517 0 1.97)
 *    0.21       0  POINT (-0.19 -0.19 0 1.97)
 *    0.21       1  POINT (0.517 -0.897 0 1.97)
 *    0.31      -1  POINT (2.297 1 0 6.5)
 *    0.31       0  POINT (2.297 0 0 6.5)
 *    0.31       1  POINT (2.297 -1 0 6.5)
 *    0.41      -1  POINT (4.862 1 0 7.5)
 *    0.41       0  POINT (4.862 0 0 7.5)
 *    0.41       1  POINT (4.862 -1 0 7.5)
 *    0.51      -1  POINT (7.428 1 0 8.5)
 *    0.51       0  POINT (7.428 0 0 8.5)
 *    0.51       1  POINT (7.428 -1 0 8.5)
 *    0.61      -1  POINT (9.994 1 0 9.5)
 *    0.61       0  POINT (9.994 0 0 9.5)
 *    0.61       1  POINT (9.994 -1 0 9.5)
 *    0.71      -1  POINT (9 2.56 0 16.59)
 *    0.71       0  POINT (10 2.56 0 16.59)
 *    0.71       1  POINT (11 2.56 0 16.59)
 *    0.81      -1  POINT (9 5.125 0 17.57)
 *    0.81       0  POINT (10 5.125 0 17.57)
 *    0.81       1  POINT (11 5.125 0 17.57)
 *    0.91      -1  POINT (9 7.691 0 18.54)
 *    0.91       0  POINT (10 7.691 0 18.54)
 *    0.91       1  POINT (11 7.691 0 18.54)
 *    
 *    -- Circular Curve test.
 *    select f.ratio,
 *           o.IntValue as offset,
 *           [$(lrsowner)].[STFindPointByRatio] (
 *              geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
 *              f.ratio,
 *              o.IntValue,
 *              3,
 *              2
 *           ).AsTextZM() as fPoint
 *      from (select 0.01 * CAST(t.IntValue as numeric) as ratio
 *              from [dbo].[Generate_Series](1,100,10) as t
 *           ) as f
 *           cross apply 
 *           [$(owner)].[generate_series](-1,1,1) as o
 *      order by f.ratio
 *    GO
 *    
 *    ratio offset fPoint
 *    0.01      -1  POINT (3.219 7.324)
 *    0.01       0  POINT (2.816 6.409)
 *    0.01       1  POINT (2.414 5.493)
 *    0.11      -1  POINT (1.001 7.937)
 *    0.11       0  POINT (0.876 6.945)
 *    0.11       1  POINT (0.751 5.953)
 *    0.21      -1  POINT (-1.299 7.894)
 *    0.21       0  POINT (-1.137 6.907)
 *    0.21       1  POINT (-0.974 5.92)
 *    0.31      -1  POINT (-2.07 6.698)
 *    0.31       0  POINT (-2.974 6.269)
 *    0.31       1  POINT (-3.878 5.84)
 *    0.41      -1  POINT (-1.204 4.873)
 *    0.41       0  POINT (-2.108 4.444)
 *    0.41       1  POINT (-3.012 4.015)
 *    0.51      -1  POINT (-0.338 3.048)
 *    0.51       0  POINT (-1.242 2.619)
 *    0.51       1  POINT (-2.146 2.19)
 *    0.61      -1  POINT (0.528 1.223)
 *    0.61       0  POINT (-0.376 0.794)
 *    0.61       1  POINT (-1.28 0.365)
 *    0.71      -1  POINT (-0.415 1.46)
 *    0.71       0  POINT (0.489 1.031)
 *    0.71       1  POINT (1.393 0.602)
 *    0.81      -1  POINT (0.451 3.285)
 *    0.81       0  POINT (1.355 2.856)
 *    0.81       1  POINT (2.259 2.427)
 *    0.91      -1  POINT (1.317 5.111)
 *    0.91       0  POINT (2.221 4.682)
 *    0.91       1  POINT (3.125 4.253)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_gtype  nvarchar(max),
    @v_length float;
  BEGIN
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( @p_ratio is null )
      Return @p_linestring;

    If ( @p_ratio not between 0.0 and 1.0 ) 
      Return @p_linestring;

    SET @v_gtype = @p_linestring.STGeometryType();

    IF ( @v_gtype NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return @p_linestring;

    -- Compute length using ratio
    SET @v_length = @p_linestring.STLength() * @p_ratio;

    -- Now call STFindPointByLength
    Return [$(lrsowner)].[STFindPointByLength](@p_linestring,
                                               @v_length,
                                               @p_offset,
                                               @p_round_xy,
                                               @p_round_zm);
  END; 
END;
GO


