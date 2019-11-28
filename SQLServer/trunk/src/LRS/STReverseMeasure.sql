SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '************************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(lrsowner)].[STReverseMeasure]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STReverseMeasure];
  PRINT 'Dropped [$(lrsowner)].[STReverseMeasure] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STReverseMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STReverseMeasure] 
(
  @p_geometry geometry,
  @p_round_xy int = 3,
  @p_round_zm int = 2
)
Returns GEOMETRY
As
/****f* LRS/STReverseMeasure (2012)
 *  NAME
 *    STReverseMeasure -- Function that reverses measures assigned to the points of a linestring.
 *  SYNOPSIS
 *    Function STReverseMeasure (
 *       @p_geometry geometry,
 *       @p_round_xy int = 3,
 *       @p_round_zm int = 2
 *     )
 *     Returns geometry 
 *  USAGE
 *    WITH data AS (
 *      select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.4 16.3, 3 6.3 1.6 20.2))',0) as Geom
 *    )
 *    SELECT 'Before' as text, d.geom.AsTextZM() as rGeom from data as d
 *    UNION ALL
 *    SELECT 'After' as text, [$(lrsowner)].[STReverseMeasure](d.geom,3,2).AsTextZM() as rGeom from data as d;
 *    GO
 *    text   rGeom
 *    ------ -------------------------------------------------------------------------------------------------------------------------------
 *    Before COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.4 16.3, 3 6.3 1.6 20.2))
 *    After  COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 20.2, 0 7 1.1 17.1, -3 6.3 1.1 24.9), (-3 6.3 1.1 24.9, 0 0 1.4 17.9, 3 6.3 1.6 0))
 *
 *  DESCRIPTION
 *    Reverses measures assigned to a linestring.
 *    Supports CircularString and CompoundCurve geometry objects and subelements from 2012 onewards.
 *  INPUTS
 *    @p_geometry (geometry) - Supplied Linestring geometry.
 *    @p_round_xy      (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm      (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    Reverse M Geom (geometry) - Input geometry with all points' M ordinates reversed.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Converted to TSQL for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_geometry_type    varchar(100),
    @v_wkt              varchar(max),
    @v_dimensions       varchar(4),
    @v_round_xy         int,
    @v_round_zm         int,
    @v_start_measure    float,
    @v_mid_arc_length   float,
    @v_end_measure      float,
    @v_last_m           float,
    @v_mSign            int = 1,
    @v_geom_length      float,
    /* STSegmentLine Variables*/
    @v_id               int,
    @v_max_id           int,
    @v_multi_tag        varchar(100),
    @v_element_id       int,
    @v_prev_element_id  int,
    @v_element_tag      varchar(100),
    @v_prev_element_tag varchar(100),
    @v_subelement_id    int,
    @v_subelement_tag   varchar(100),
    @v_segment_id       int, 
    @v_sx               float,  /* Start Point */
    @v_sy               float,
    @v_sz               float,
    @v_sm               float,
    @v_mx               float,  /* Mid Point */
    @v_my               float,
    @v_mz               float,
    @v_mm               float,
    @v_ex               float,  /* End Point */
    @v_ey               float,
    @v_ez               float,
    @v_em               float,
    @v_length           float,
    @v_startLength      float,
    @v_measureRange     float,
    @v_SegmentGeom      geometry;
  Begin
    If ( @p_geometry is null ) 
      Return @p_geometry;

    -- Only makes sense to snap a point to a linestring
    If ( @p_geometry.STDimension() <> 1 ) 
      Return @p_geometry;

    /* Nothing to do if not measured */
    IF ( @p_geometry.HasM=0 )
      Return @p_geometry;

    -- Only process linear geometries.
    SET @v_geometry_type = @p_geometry.STGeometryType();
    IF ( @v_geometry_type NOT IN ('LineString','CircularString','CompoundCurve','MultiLineString') )
      Return @p_geometry;

    SET @v_round_xy      = ISNULL(@p_round_xy,3);
    SET @v_round_zm      = ISNULL(@p_round_zm,2);
    SET @v_dimensions    = 'XY' + case when @p_geometry.HasZ=1 then 'Z' else '' end + 'M';
    SET @v_geom_length   = @p_geometry.STLength();

    SET @v_start_measure = ISNULL(@p_geometry.STEndPoint().M,0.0);
    SET @v_end_measure   = @p_geometry.STStartPoint().M;
    -- Do we add or subtract measures when assigning from start to finish?
    SET @v_mSign         = SIGN(@v_end_measure-@v_start_measure);

    -- Walk over all the segments of the linear geometry
    DECLARE cSegments 
     CURSOR FAST_FORWARD 
        FOR
     SELECT max(v.id) over (partition by v.multi_tag) as max_id,
            v.id,            v.multi_tag,
            v.element_id,    v.element_tag,
            v.subelement_id, v.subelement_tag,
            v.segment_id, 
            v.sx, v.sy, v.sz, v.sm,
            v.mx, v.my, v.mz, v.mm,
            v.ex, v.ey, v.ez, v.em,
            v.length,
            v.startLength,
            v.measureRange,
            v.geom
       FROM [$(owner)].[STSegmentLine](@p_geometry) as v
      ORDER by v.element_id, 
               v.subelement_id, 
               v.segment_id

   OPEN cSegments;

   FETCH NEXT 
    FROM cSegments 
    INTO @v_max_id,
         @v_id,            @v_multi_tag,
         @v_element_id,    @v_element_tag, 
         @v_subelement_id, @v_subelement_tag, 
         @v_segment_id, 
         @v_sx, @v_sy, @v_sz, @v_sm, 
         @v_mx, @v_my, @v_mz, @v_mm,
         @v_ex, @v_ey, @v_ez, @v_em,
         @v_length,
         @v_startLength,
         @v_measureRange,
         @v_SegmentGeom;

   SET @v_prev_element_tag = UPPER(@v_element_tag);
   SET @v_prev_element_id  = @v_element_id;
   SET @v_wkt              = UPPER(case when @v_multi_tag is not null then @v_multi_tag else @v_element_tag end) 
                             + 
                             case when @v_multi_tag = 'MultiLineString' then ' ((' else ' (' end
                             + 
                             case when @v_multi_tag = 'CompoundCurve' 
                                  then case when @v_element_tag = 'LineString' then '(' else @v_element_tag + ' (' end 
                                  else '' 
                              end
                             +
                             [$(owner)].[STPointAsText] (
                               /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                               /* @p_X          */ @v_sx,
                               /* @p_Y          */ @v_sy,
                               /* @p_Z          */ @v_sz,
                               /* @p_M          */ @v_start_measure,
                               /* @p_round_x    */ @v_round_xy,
                               /* @p_round_y    */ @v_round_xy,
                               /* @p_round_z    */ @v_round_zm,
                               /* @p_round_m    */ @v_round_zm
                             )
                             + 
                             ',';
   SET @v_last_m = @v_start_measure;

   WHILE @@FETCH_STATUS = 0
   BEGIN

     IF ( @v_element_tag <> @v_prev_element_tag 
       or @v_element_id  <> @v_prev_element_id )
     BEGIN
       SET @v_wkt = @v_wkt + '), ' + case when @v_element_tag = 'CircularString' then 'CIRCULARSTRING(' else '(' end;
       -- First Coord of new element segment.
       --
       SET @v_wkt = @v_wkt + 
                    [$(owner)].[STPointAsText] (
                      /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                      /* @p_X          */ @v_sx,
                      /* @p_Y          */ @v_sy,
                      /* @p_Z          */ @v_sz,
                      /* @p_M          */ @v_last_m,
                      /* @p_round_x    */ @v_round_xy,
                      /* @p_round_y    */ @v_round_xy,
                      /* @p_round_z    */ @v_round_zm,
                      /* @p_round_m    */ @v_round_zm
                    )
                    + 
                    ',';
     END
     ELSE
     BEGIN
       IF ( @v_segment_id > 1 ) 
         SET @v_wkt = @v_wkt + ',';
     END;

     -- Is this a circularArc?
     IF ( @v_SegmentGeom.STGeometryType() = 'CircularString' and @v_mx is not null) 
     BEGIN
       -- compute and write mid vertex of curve
       SET @v_mm  = @v_last_m + @v_mSign*(@v_mm-@v_sm); 
       -- Print out new point
       SET @v_wkt = @v_wkt + 
                    [$(owner)].[STPointAsText] (
                       /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                       /* @p_X          */ @v_mx,
                       /* @p_Y          */ @v_my,
                       /* @p_Z          */ @v_mz,
                       /* @p_M          */ @v_mm,
                       /* @p_round_x    */ @v_round_xy,
                       /* @p_round_y    */ @v_round_xy,
                       /* @p_round_z    */ @v_round_zm,
                       /* @p_round_m    */ @v_round_zm
                    )
                    +
                    ',';
       SET @v_last_m = @v_mm;
       SET @v_sm     = @v_mm;  -- for next calculation
     END;

     -- Compute next/last measure
     SET @v_em     = case when @v_id = @v_max_id 
                          then @v_end_measure
                          else @v_last_m + @v_mSign*(@v_em-@v_sm)
                      end;

     -- Print out new point
     SET @v_wkt = @v_wkt + 
                  [$(owner)].[STPointAsText] (
                    /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                    /* @p_X          */ @v_ex,
                    /* @p_Y          */ @v_ey,
                    /* @p_Z          */ @v_ez,
                    /* @p_M          */ @v_em,
                    /* @p_round_x    */ @v_round_xy,
                    /* @p_round_y    */ @v_round_xy,
                    /* @p_round_z    */ @v_round_zm,
                    /* @p_round_m    */ @v_round_zm
                   );
     SET @v_last_m = @v_em;

     SET @v_prev_element_tag = @v_element_tag;
     SET @v_prev_element_id  = @v_element_id;

     FETCH NEXT 
      FROM cSegments 
      INTO @v_max_id,
           @v_id,            @v_multi_tag,
           @v_element_id,    @v_element_tag, 
           @v_subelement_id, @v_subelement_tag, 
           @v_segment_id, 
           @v_sx, @v_sy, @v_sz, @v_sm, 
           @v_mx, @v_my, @v_mz, @v_mm,
           @v_ex, @v_ey, @v_ez, @v_em,
           @v_length,
           @v_startLength,
           @v_measureRange,
           @v_SegmentGeom;
   END;
   CLOSE cSegments
   DEALLOCATE cSegments
   SET @v_wkt = @v_wkt + ')';
   IF ( @v_multi_tag is not null ) 
     SET @v_wkt = @v_wkt + ')';
   Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  End;
END;
GO


