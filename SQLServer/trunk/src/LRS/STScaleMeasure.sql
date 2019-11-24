SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '****************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(lrsowner)].[STScaleMeasure]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STScaleMeasure];
  PRINT 'Dropped [$(lrsowner)].[STScaleMeasure] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(lrsowner)].[STUpdateMeasure]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STUpdateMeasure];
  PRINT 'Dropped [$(lrsowner)].[STUpdateMeasure] ...';
END;
GO

-- *********************************************************

PRINT 'Creating [$(lrsowner)].[STScaleMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STScaleMeasure] 
(
  @p_geometry      geometry,
  @p_start_measure Float,
  @p_end_measure   Float,
  @p_shift_measure Float = 0.0,
  @p_round_xy      int   = 3,
  @p_round_zm      int   = 2
)
Returns GEOMETRY
As
/****f* LRS/STScaleMeasure (2012)
 *  NAME
 *    STScaleMeasure -- Rescales geometry measures and optionally offsets them, stretching the geometry.
 *  SYNOPSIS
 *    Function [$(lrsowner)].[STScaleMeasure] (
 *       @p_geometry      geometry,
 *       @p_start_measure Float,
 *       @p_end_measure   Float,
 *       @p_shift_measure Float = 0.0,
 *       @p_round_xy      int = 3,
 *       @p_round_zm      int = 2
 *     )
 *     Returns geometry 
 *  USAGE
 *    WITH data AS (
 *      SELECT [$(lrsowner)].[STAddMeasure] (
 *               geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 1.1, 0 7 1.1, -3 6.3246 1.1),(-3 6.3246 1.1, 0 0 1.4, 3 6.3246 1.55))',0),
 *               0,null,1,1) as aGeom
 *    )
 *    SELECT 'Original' as LineType, 
 *           f.aGeom.AsTextZM() as mLine
 *      FROM data as f
 *    UNION ALL
 *    SELECT 'Scaled' as LineType,
 *           [$(lrsowner)].[STScaleMeasure] ( f.ageom, 100.0, 125.1, 5.0, 3, 2).AsTextZM() as sGeom 
 *      FROM data as f;
 *    GO
 *    LineType mLine
 *    -------- --------------------------------------------------------------------------------------------------------------------------------------------
 *    Original COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 6.2), (-3 6.3 1.1 6.2, 0 0 1.4 13.2, 3 6.3 1.6 20.2))
 *    Scaled   COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 105, 0 7 1.1 108.852, -3 6.3 1.1 112.704), (-3 6.3 1.1 112.704, 0 0 1.4 121.402, 3 6.3 1.6 125.1))
 *  DESCRIPTION
 *    This function can redistribute measure values between the supplied
 *    @p_start_measure (start vertex) and @p_end_measure (end vertex) by adjusting/scaling
 *    the measure values of all in between coordinates. In addition, if @p_shift_measure
 *    is not 0 (zero), the supplied value is added to each modified measure value
 *    performing a translation/shift of those values.
 *  INPUTS
 *    @p_geometry   (geometry) - Supplied Linestring geometry.
 *    @p_start_measure (float) - Measure defining start point for geometry.
 *    @p_end_measure   (float) - Measure defining end point for geometry.
 *    @p_shift_measure (float) - Shift (scale) value applied to all measure. 
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    Scaled M Line (geometry) - Input geometry with all points' M ordinates scaled.
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
    @v_GeometryType      varchar(100) = '',
    @v_wkt               varchar(max) = '',
    @v_dimensions        varchar(4),
    @v_round_xy          int,
    @v_round_zm          int,

    @v_start_measure     float,
    @v_shift_measure     float = ISNULL(@p_shift_measure,0.0),
    @v_delta_measure     Float = 0.0,
    @v_old_measure_range Float = 0.0,
    @v_new_measure_range Float = 0.0,
    @v_sum_new_measure   Float = 0.0,
    @v_last_m            Float = 0.0,

    /* STSegmentLine Variables*/
    @v_id                int,
    @v_max_id            int,
    @v_multi_tag         varchar(100),
    @v_element_id        int,
    @v_prev_element_id   int,
    @v_element_tag       varchar(100),
    @v_prev_element_tag  varchar(100),
    @v_subelement_id     int,
    @v_subelement_tag    varchar(100),
    @v_segment_id        int, 
    @v_sx                float,  /* Start Point */
    @v_sy                float,
    @v_sz                float,
    @v_sm                float,
    @v_mx                float,  /* Mid Point */
    @v_my                float,
    @v_mz                float,
    @v_mm                float,
    @v_ex                float,  /* End Point */
    @v_ey                float,
    @v_ez                float,
    @v_em                float,
    @v_length            float,
    @v_startLength       float,
    @v_measureRange      float,
    @v_segment_geom      geometry;
  Begin
    IF (@p_geometry is null)
      Return @p_geometry;

    If ( @p_start_measure is null OR @p_end_measure is null ) 
      Return @p_geometry;

    -- Only support measured linestrings
    SET @v_GeometryType = @p_geometry.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','CircularString','CompoundCurve','MultiLineString') )
      Return @p_geometry;

    IF ( @p_geometry.HasM = 0 ) -- Not measured
      Return @p_geometry;

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
       FROM [$(owner)].[STSegmentLine] ( @p_geometry ) as v
      ORDER BY v.id;

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
          @v_segment_geom;

   SET @v_dimensions        = 'XY' + case when @p_geometry.HasZ=1 then 'Z' else '' end + 'M';

   SET @v_round_xy          = ISNULL(@p_round_xy,3);
   SET @v_round_zm          = ISNULL(@p_round_zm,2);

   SET @v_new_measure_range = @p_end_measure - @p_start_measure;
   SET @v_old_measure_range = @p_geometry.STEndPoint().M     /* Last measure */
                            - @p_geometry.STStartPoint().M;  /* First measure */

   SET @v_prev_element_tag  = UPPER(@v_element_tag);
   SET @v_prev_element_id   = @v_element_id;
   SET @v_start_measure     = @p_start_measure + @v_shift_measure;
   SET @v_last_m            = @v_start_measure;
   SET @v_wkt               = UPPER(case when @v_multi_tag is not null then @v_multi_tag else @v_element_tag end) 
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

   WHILE ( @@FETCH_STATUS = 0 )
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
     IF ( @v_segment_geom.STGeometryType() = 'CircularString' and @v_mx is not null )
     BEGIN
       -- compute and write mid vertex of curve
       SET @v_delta_measure   = @v_mm /* Current M */ - @v_sm; /* Previous M */
       SET @v_sum_new_measure = @v_sum_new_measure + ( @v_delta_measure / @v_old_measure_range ) * @v_new_measure_range;
       -- Print out new point
       SET @v_wkt = @v_wkt + 
                    [$(owner)].[STPointAsText] (
                          /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                          /* @p_X          */ @v_mx,
                          /* @p_Y          */ @v_my,
                          /* @p_Z          */ @v_mz,
                          /* @p_M          */ @v_start_measure + @v_sum_new_measure, /* Leave v_mm variable alone for use in v_em calculation */
                          /* @p_round_x    */ @v_round_xy,
                          /* @p_round_y    */ @v_round_xy,
                          /* @p_round_z    */ @v_round_zm,
                          /* @p_round_m    */ @v_round_zm
                    )
                    +
                    ',';
     END;

     -- Compute measure of last point in segment (could also be last point in geometry)
     SET @v_delta_measure   = @v_em /* Current M */ 
                            - case when @v_segment_geom.STGeometryType() = 'CircularString' and @v_mx is not null then @v_mm else @v_sm end
                              /* Previous M */;
     SET @v_sum_new_measure = @v_sum_new_measure + ( @v_delta_measure / @v_old_measure_range ) * @v_new_measure_range;
     SET @v_em              = case when @v_id = @v_max_id 
                                   then @p_end_measure
                                   else @v_start_measure + @v_sum_new_measure
                               end;
     SET @v_last_m          = @v_em;  /* Ready for use at start of next loop iteration */

     -- Print out last point
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
           @v_segment_geom;
   END; /* while */
   CLOSE cSegments
   DEALLOCATE cSegments
   SET @v_wkt = @v_wkt + ')';
   IF ( @v_multi_tag is not null ) 
     SET @v_wkt = @v_wkt + ')';
   Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  End;
END
GO

-- *****************************************************************

PRINT 'Creating [$(lrsowner)].[STUpdateMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STUpdateMeasure] 
(
  @p_linestring    geometry,
  @p_start_measure Float,
  @p_end_measure   Float,
  @p_round_xy      int   = 3,
  @p_round_zm      int   = 2
)
Returns GEOMETRY
As
/****f* LRS/STUpdateMeasure (2012)
 *  NAME
 *    STUpdateMeasure -- Rescales (multi)linestring vertex measures from start to end using provided values.
 *  SYNOPSIS
 *    Function [$(lrsowner)].[STUpdateMeasure] (
 *       @p_linestring    geometry,
 *       @p_start_measure Float,
 *       @p_end_measure   Float,
 *       @p_round_xy      int = 3,
 *       @p_round_zm      int = 2
 *     )
 *     Returns geometry 
 *  USAGE
 *    WITH data AS (
 *      SELECT [lrs].[STAddMeasure] (
 *               geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 1.1, 0 7 1.1, -3 6.3246 1.1),(-3 6.3246 1.1, 0 0 1.4, 3 6.3246 1.55))',0),
 *               0,null,1,1) as aGeom
 *    )
 *    SELECT 'Original' as LineType, 
 *           f.aGeom.AsTextZM() as mLine
 *      FROM data as f
 *    UNION ALL
 *    SELECT 'Updated (1)' as LineType,
 *           [lrs].[STUpdateMeasure] ( f.ageom, 1.0, 21.2, 3, 2).AsTextZM() as sGeom 
 *      FROM data as f
 *    UNION ALL
 *    SELECT 'Updated (2)' as LineType,
 *           [lrs].[STUpdateMeasure] ( f.ageom, 100.0, 125.1, 3, 2).AsTextZM() as sGeom 
 *      FROM data as f;
 *    GO
 *
 *   LineType mLine
 *   -------- ---------------------------------------------------------------------------------------------------------------------------------------
 *   Original	COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 6.2), (-3 6.3 1.1 6.2, 0 0 1.4 13.2, 3 6.3 1.6 20.2))
 *   Updated (1)	COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 1, 0 7 1.1 4.1, -3 6.3 1.1 7.2), (-3 6.3 1.1 7.2, 0 0 1.4 14.2, 3 6.3 1.6 21.2))
 *   Updated (2)	COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 100, 0 7 1.1 103.85, -3 6.3 1.1 107.7), (-3 6.3 1.1 107.7, 0 0 1.4 116.4, 3 6.3 1.6 125.1))
 *  DESCRIPTION
 *    This function resets all measures in a measured linestring by applying @p_start_measure to the start vertex and @p_end_measure to the end vertex.
 *    All vertices in between have the measures scaled between the start and end measures by ratio based on length.
 *    All M ordinates are rounded to supplied @p_round_zm.
 *  NOTE
 *    Is a wrapper over [$(lrsowner)].[STScaleMeasure].
 *  INPUTS
 *    @p_linestring (geometry) - Supplied Linestring geometry.
 *    @p_start_measure (float) - Measure defining start point for geometry.
 *    @p_end_measure   (float) - Measure defining end point for geometry.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    Scaled M Line (geometry) - Input linestring with all points' M ordinates updated.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Converted to TSQL for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
    RETURN [$(lrsowner)].[STScaleMeasure] (
               /* @p_geometry      geometry */ @p_linestring,
               /* @p_start_measure Float    */ @p_start_measure,
               /* @p_end_measure   Float    */ @p_end_measure,
               /* @p_shift_measure Float    */ null,
               /* @p_round_xy      int      */ @p_round_xy,
               /* @p_round_zm      int      */ @p_round_zm
           );
END;
GO

-- *****************************************************************

PRINT 'Testing [$(lrsowner)].[STScaleMeasure] ...';
GO

With roads as (
select geometry::STGeomFromText('LINESTRING(6012823.67 2115982.17 NULL 0.0, 
                                            6012802.73 2116135.36 NULL 154.62, 
                                            6012808.02 2116172.29 NULL 191.92, 
                                            6012759.63 2116512.49 NULL 535.55, 
                                            6012710.22 2116859.9  NULL 886.46, 
                                            6012685.05 2117036.86 NULL 1065.2, 
                                            6012662.15 2117197.81 NULL 1227.77, 
                                            6012639.24 2117358.89 NULL 1390.47, 
                                            6012616.49 2117518.83 NULL 1552.02, 
                                            6012595.63 2117677.81 NULL 1712.36, 
                                            6012577.74 2117833.5  NULL 1869.08, 
                                            6012527.85 2118162.97 NULL 2202.3, 
                                            6012481.8  2118483.41 NULL 2526.04, 
                                            6012434.31 2118821.59 NULL 2867.54, 
                                            6012386.77 2119169.05 NULL 3218.24, 
                                            6012339.32 2119507.67 NULL 3560.16, 
                                            6012316.04 2119675.92 NULL 3730.02, 
                                            6012292.06 2119844.61 NULL 3900.4, 
                                            6012247.47 2120184.04 NULL 4242.75, 
                                            6012200.32 2120523.34 NULL 4585.31, 
                                            6012165.96 2120757.08 NULL 4821.56, 
                                            6012208.57 2120826.43 NULL 4902.96)',2872) as geom 
)
Select d.*
  From roads r
       CROSS APPLY 
       [$(owner)].[STDumpPoints] (
           [$(lrsowner)].[STScaleMeasure](r.geom,
                                          1.1,
                                          1682.0,
                                          0.0,
                                          3,
                                          2)
       ) as d
GO

with data as (
select [$(lrsowner)].[STAddMeasure](
         geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 1.1, 0 7 1.1, -3 6.3246 1.1),(-3 6.3246 1.1, 0 0 1.4, 3 6.3246 1.55))',0),
         0,null,1,1) as aGeom
)
select 'Original' as LineType, 
       f.aGeom.AsTextZM() as mLine
  from data as f
UNION ALL
SELECT 'Scaled' as LineType,
       [$(lrsowner)].[STScaleMeasure]( f.ageom, 100.0, 125.1, 5.0, 3, 2).AsTextZM() as sGeom 
  from data as f;
GO

