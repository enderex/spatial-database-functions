SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindPointByMeasure]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindPointByMeasure];
  PRINT 'Dropped [$(lrsowner)].[STFindPointByMeasure] ...';
END;
GO

Print 'Creating [$(lrsowner)].[STFindPointByMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFindPointByMeasure] 
(
  @p_linestring geometry,
  @p_measure    Float,
  @p_offset     Float = 0.0,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
Returns geometry 
AS
/****f* LRS/STFindPointByMeasure (2012)
 *  NAME
 *    STFindPointByMeasure -- Returns (possibly offset) point geometry at supplied measure along linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFindPointByMeasure] (
 *               @p_linestring geometry,
 *               @p_measure    Float,
 *               @p_offset     Float = 0.0,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a measure, this function returns a geometry point at that measure.
 *
 *    If @p_linestring is not measured, the original geometry is returned.
 *
 *    If a non-zero/null value is suppied for @p_offset, the found point is offset (perpendicular to line) to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *
 *    The returned point has its ordinate values rounded using the supplied @p_round_xy/@p_round_zm decimal place values.
 *  NOTES
 *    Supports LineStrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry with measures.
 *    @p_measure       (float) - Measure defining position of point to be located.
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point         (geometry) - Point at provided measure offset to left or right.
 *  EXAMPLE
 *    -- Handle non-measured linestring
 *    with data as (
 *      select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
 *    )
 *    select f.linestring.STEquals(f.fpoint) as equals
 *      from (select [lrs].[STFindPointByMeasure](a.linestring,0,0,3,2) as fPoint,
 *                   a.linestring
 *              from data as a
 *           ) f
 *    go
 *    
 *    equals
 *    1
 *    
 *    -- Process different linestrings
 *    with data as (
 *      select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
 *      union all
 *      select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
 *      union all 
 *      select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 NULL 0, 0 7 NULL 3.08, -3 6.3246 NULL 6.15),(-3 6.3246 NULL 6.15, 0 0 NULL 10.1, 3 6.3246 NULL 20.2))',0) as linestring
 *    )
 *    select a.linestring.STGeometryType() as curve_type,
 *           g.intValue as measure,
 *           o.IntValue as offset,
 *           [lrs].[STFindPointByMeasure](a.linestring,g.IntValue,o.IntValue,3,2).AsTextZM() as fPoint
 *      from data as a
 *           cross apply
 *           [dbo].[generate_series](a.lineString.STPointN(1).M,
 *                                   round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1),
 *                                   [lrs].[STMeasureRange](a.linestring) / 4.0 ) as g
 *           cross apply
 *           [dbo].[generate_series](-1, 1, 1) as o
 *    order by curve_type, measure
 *    GO
 *    
 *    curve_type     measure offset fPoint
 *    CircularString       0     -1 POINT (3.428 7.229 NULL 0)
 *    CircularString       0      0 POINT (3 6.325 NULL 0)
 *    CircularString       0      1 POINT (2.572 5.421 NULL 0)
 *    CircularString       1     -1 POINT (2.355 7.646 NULL 1)
 *    CircularString       1      0 POINT (2.061 6.69 NULL 1)
 *    CircularString       1      1 POINT (1.767 5.734 NULL 1)
 *    CircularString       2     -1 POINT (1.234 7.904 NULL 2)
 *    CircularString       2      0 POINT (1.08 6.916 NULL 2)
 *    CircularString       2      1 POINT (0.925 5.928 NULL 2)
 *    CircularString       3     -1 POINT (0.086 8 NULL 3)
 *    CircularString       3      0 POINT (0.076 7 NULL 3)
 *    CircularString       3      1 POINT (0.065 6 NULL 3)
 *    CircularString       4     -1 POINT (-1.063 7.929 NULL 4)
 *    CircularString       4      0 POINT (-0.93 6.938 NULL 4)
 *    CircularString       4      1 POINT (-0.797 5.947 NULL 4)
 *    CircularString       5     -1 POINT (-2.19 7.695 NULL 5)
 *    CircularString       5      0 POINT (-1.916 6.733 NULL 5)
 *    CircularString       5      1 POINT (-1.643 5.771 NULL 5)
 *    CircularString       6     -1 POINT (-3.271 7.301 NULL 6)
 *    CircularString       6      0 POINT (-2.863 6.388 NULL 6)
 *    CircularString       6      1 POINT (-2.454 5.476 NULL 6)
 *    CompoundCurve        0     -1 POINT (3.429 7.228 NULL 0)
 *    CompoundCurve        0      0 POINT (3 6.3246 NULL 0)
 *    CompoundCurve        0      1 POINT (2.571 5.421 NULL 0)
 *    CompoundCurve        5     -1 POINT (-2.19 7.694 NULL 5)
 *    CompoundCurve        5      0 POINT (-1.916 6.733 NULL 5)
 *    CompoundCurve        5      1 POINT (-1.642 5.771 NULL 5)
 *    CompoundCurve       10     -1 POINT (-7 5.325 NULL 10)
 *    CompoundCurve       10      0 POINT (-7 6.325 NULL 10)
 *    CompoundCurve       10      1 POINT (-7 7.325 NULL 10)
 *    CompoundCurve       15     -1 POINT (-12 5.325 NULL 15)
 *    CompoundCurve       15      0 POINT (-12 6.325 NULL 15)
 *    CompoundCurve       15      1 POINT (-12 7.325 NULL 15)
 *    CompoundCurve       20     -1 POINT (-17 5.325 NULL 20)
 *    CompoundCurve       20      0 POINT (-17 6.325 NULL 20)
 *    CompoundCurve       20      1 POINT (-17 7.325 NULL 20)
 *    LineString           1     -1 POINT (-0.707 0.707 NULL 1)
 *    LineString           1      0 POINT (-4 -4 0 1)
 *    LineString           1      1 POINT (0.707 -0.707 NULL 1)
 *    LineString           7     -1 POINT (1.4 1 NULL 7)
 *    LineString           7      0 POINT (1.4 0 NULL 7)
 *    LineString           7      1 POINT (1.4-1 NULL 7)
 *    LineString          13     -1 POINT (7.4 1 NULL 13)
 *    LineString          13      0 POINT (7.4 0 NULL 13)
 *    LineString          13      1 POINT (7.4-1 NULL 13)
 *    LineString          19     -1 POINT (9 3.39 NULL 19)
 *    LineString          19      0 POINT (10 3.39 NULL 19)
 *    LineString          19      1 POINT (11 3.39 NULL 19)
 *    LineString          25     -1 POINT (9 9.39 NULL 25)
 *    LineString          25      0 POINT (10 9.39 NULL 25)
 *    LineString          25      1 POINT (11 9.39 NULL 25)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_gtype              varchar(100),
    @v_dimensions         varchar(4),
    @v_round_xy           int,
    @v_round_zm           int,

    @v_reversed_measure   int,
    @v_measure_point      geometry,

    @v_bearing_from_start Float,
    @v_measure_from_start Float,
    @v_offset_bearing     Float,
    @v_offset_distance    Float = ISNULL(@p_offset,0.0),

    /* segment Variables */
    @v_id                 int,
    @v_element_id         int,
    @v_prev_element_id    int,
    @v_subelement_id      int,
    @v_segment_id         int, 
    @v_sx                 float,  /* Start Point */
    @v_sy                 float,
    @v_sz                 float,
    @v_sm                 float,
    @v_mx                 float,  /* Mid Point */
    @v_my                 float,
    @v_mz                 float,
    @v_mm                 float,
    @v_ex                 float,  /* End Point */
    @v_ey                 float,
    @v_ez                 float,
    @v_em                 float,
    @v_length             float,
    @v_start_length       float,
    @v_measure_range      float,
    @v_line_geom          geometry;

  BEGIN
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( @p_measure is null )
      Return @p_linestring;

    If ( @p_linestring.HasM <> 1 )
      Return @p_linestring;

    SET @v_round_xy   = ISNULL(@p_round_xy,3);
    SET @v_round_zm   = ISNULL(@p_round_zm,2);
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end +
                       + 'M';

    SET @v_reversed_measure = case when [$(lrsowner)].[STIsMeasureDecreasing](@p_linestring) = 'TRUE' 
                                   then -1
                                   else 1
                                end;

    SET @v_gtype = @p_linestring.STGeometryType();

    IF ( @v_gtype NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return @p_linestring;

    -- Shortcircuit:
    -- If same point as start/end
    -- 
    IF ( @v_offset_distance = 0.0
      and ( @p_measure = @p_linestring.STPointN(1).M 
         or @p_measure = @p_linestring.STPointN(@p_linestring.STNumPoints()).M ) )
    BEGIN
      Return case when @p_measure = @p_linestring.STPointN(1).M
                  then @p_linestring.STPointN(1)
                  else @p_linestring.STPointN(@p_linestring.STNumPoints())
              end;
    END;

    -- Filter to find affected segments
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
           @v_length        = v.Length,
           @v_start_length  = v.StartLength,
           @v_measure_range = v.measureRange,
           @v_line_geom     = v.geom
      FROM [$(lrsowner)].[STFilterLineSegmentByMeasure] (
               @p_linestring,
               @p_measure,
               @p_measure,
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
    -- Use STFindArcPointByMeasure function
    --
    IF ( @v_line_geom.STGeometryType() = 'CircularString' )
    BEGIN
      SET @v_measure_point = [$(lrsowner)].[STFindArcPointByMeasure] (
                               @v_line_geom       /* @p_circular_arc */,
                               @p_measure         /* @p_measure */,
                               @v_offset_distance /* @p_offset */,
                               @v_round_xy        /* @p_round_xy */,
                               @v_round_zm        /* @p_round_zm */
                            );
      IF ( @v_measure_point is not null)
        RETURN @v_measure_point;
    END;

    -- This segment, (first filtered segment) always contains required?
    --

    -- Compute common bearing ...
    SET @v_bearing_from_start = [$(cogoowner)].[STBearing] (
                                   @v_sx,
                                   @v_sy,
                                   @v_ex,
                                   @v_ey
                                );

    -- Short circuit calculations if @p_measure = start or end measures
    --
    IF ( @p_measure = @v_sm 
      or @p_measure = @v_em )
    BEGIN
      SET @v_measure_point = geometry::STPointFromText(
                             'POINT(' 
                             +
                             [$(owner)].[STPointAsText] (
                                      /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                                      /* @p_X          */ case when @p_measure = @v_sx then @v_sx else @v_ex end,
                                      /* @p_Y          */ case when @p_measure = @v_sy then @v_sy else @v_ey end,
                                      /* @p_Z          */ case when @p_measure = @v_sz then @v_sz else @v_ez end,
                                      /* @p_M          */ @p_measure,
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
      -- Compute point within segment by bearing/distance and measure from start point.
      SET @v_measure_from_start = ABS( @p_measure - (@v_sm * @v_reversed_measure) );
      SET @v_measure_point = [$(cogoowner)].[STPointFromBearingAndDistance] ( 
                                @v_sx,
                                @v_sy,
                                @v_bearing_from_start,
                                @v_measure_from_start,
                                @v_round_xy,
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

      -- compute offset point from measure point
      SET @v_measure_point = [$(cogoowner)].[STPointFromCOGO] ( 
                                @v_measure_point,
                                @v_offset_bearing,
                                abs(@v_offset_distance),
                                @v_round_xy
                             );
    END; 
    SET @v_measure_point = [$(lrsowner)].[STSetMeasure] (  
                              /* @p_point    */ @v_measure_point, 
                              /* @p_measure  */ @p_measure,
                              /* @p_round    */ @v_round_xy,
                              /* @p_round_zm */ @v_round_zm 
                           );
    Return @v_measure_point;
  END;  
  Return NULL;
END;
GO


