SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '************************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))' ;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSplitCircularStringByLength]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STSplitCircularStringByLength];
  PRINT 'Dropped [$(lrsowner)].[STSplitCircularStringByLength] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STSplitCircularStringByLength] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STSplitCircularStringByLength] 
(
  @p_circular_arc geometry,
  @p_start_length float,
  @p_end_length   float,
  @p_offset       float = 0.0,
  @p_round_xy     int   = 3,
  @p_round_zm     int   = 2
)
Returns geometry 
As
/****f* LRS/STSplitCircularStringByLength (2012)
 *  NAME
 *    STLocateBetween -- Extracts, and possibly offets, that part of the supplied (single) CircularString identified by the @p_start_length and @p_end_length parameters.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STSplitCircularStringByLength] (
 *               @p_circular_arc geometry,
 *               @p_start_length Float,
 *               @p_end_length   Float = null,
 *               @p_offset       Float = 0.0,
 *               @p_round_xy     int   = 3,
 *               @p_round_zm     int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a start and end length, this function extracts a new CircularString segment from the @p_circular_arc.
 *    If a non-zero value is suppied for @p_offset, the extracted circularSting is then offset to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *    If the circularString @p_offset value causes the CircularString to disappear, NULL is returned.
 *  NOTES
 *    Supports a single (3-point) CircularString element only.
 *  INPUTS
 *    @p_circular_arc (geometry) - A single, 3 point, CircularString.
 *    @p_start_length    (float) - Measure defining start point of located geometry.
 *    @p_end_length      (float) - Measure defining end point of located geometry.
 *    @p_offset          (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_round_xy          (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm          (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    CircularString  (geometry) - New CircularString between start/end measure with optional offset.
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('CIRCULARSTRING (-3 6.3246, 0 7, 3 6.3246)',0) as linestring
 *      union all
 *      select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
 *    )
 *    select [lrs].[STSplitCircularStringByLength](a.linestring,0.5,2.0,0.0,3,2).AsTextZM() as split
 *      from data as a;
 *    
 *    split
 *    CIRCULARSTRING (-2.541 6.523, -1.829 6.757, -1.096 6.914)
 *    CIRCULARSTRING (2.541 6.523 NULL 0.5, 1.829 6.757 NULL 1.24, 1.096 6.914 NULL 1.98)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_wkt            varchar(max),
    @v_Dimensions     varchar(4),
    @v_round_xy       int,
    @v_round_zm       int,
    @v_circle         geometry,
    @v_start_point    geometry,
    @v_mid_point      geometry,
    @v_end_point      geometry,
    @v_start_length   float,
    @v_mid_length     float,
    @v_end_length     float,
    @v_temp           float,
    @v_angle          float,
    @v_offset         float;
  Begin
    IF ( @p_circular_arc is null )
      Return NULL;
    IF ( @p_Circular_arc.STGeometryType() <> 'CircularString' )
      Return NULL;
    IF ( @p_circular_arc.STNumCurves() > 1 )  -- We only process a single CircularString
      Return @p_Circular_arc;
    IF ( @p_start_length   is null and @p_end_length   is null )
      Return @p_circular_arc;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_offset   = ISNULL(@p_offset,0.0);

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_circular_arc.HasZ=1 then 'Z' else '' end 
                       + case when @p_circular_arc.HasM=1 then 'M' else '' end;

    -- *********************************
    -- Normalise start/end lengths to passed in linestring
    SET @v_start_length   = ROUND(case when @p_start_length is null 
                                       then 0.0
                                       else @p_start_length  
                                   end,
                                 @v_round_xy
                            );
    SET @v_end_length     = ROUND(case when @p_end_length is null 
                                       then @p_circular_arc.STLength()
                                       else case when @p_end_length > @p_circular_arc.STLength()
                                                 then @p_circular_arc.STLength()
                                                 else @p_end_length  
                                             end
                                   end,
                                  @v_round_xy
                            );
    -- Ensure distances increment...
    SET @v_temp         = case when @v_start_length <= @v_end_length 
                               then @v_start_length
                               else @v_end_length
                          end;
    SET @v_end_length   = case when @v_start_length <= @v_end_length 
                               then @v_end_length
                               else @v_start_length
                          end;
    SET @v_start_length = @v_temp;
    -- *********************************

    IF ( @v_start_length   > @p_circular_arc.STLength() )
      Return NULL;

    -- Get Circle Centre and Radius
    SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @p_circular_arc );

    -- Start point will be at v_start_length from first point...
    -- 
    SET @v_start_point = [$(lrsowner)].[STFindArcPointByLength] (
                             /* @p_circular_arc */ @p_circular_arc,
                             /* @p_length       */ @v_start_length,
                             /* @p_offset       */ @v_offset,
                             /* @p_round_xy     */ @v_round_xy,
                             /* @p_round_zm     */ @v_round_zm   
                         );

    -- If start=end we have a single point
    --
    IF ( @v_start_length = @v_end_length ) 
      Return @v_start_point;

    -- Now compute End Point
    --
    SET @v_end_point  = [$(lrsowner)].[STFindArcPointByLength] (
                           /* @p_circular_arc */ @p_circular_arc,
                           /* @p_length       */ @v_end_length,
                           /* @p_offset       */ @v_offset,
                           /* @p_round_xy     */ @v_round_xy,
                           /* @p_round_zm     */ @v_round_zm   
                       );

    -- We need to compute a mid point between the two start/end points
    -- Try and reuse existing mid point

    -- Compute subtended angle between start point and existing mid point of arc
    --
    SET @v_angle      = [$(cogoowner)].[STDegrees] (
                          [$(cogoowner)].[STSubtendedAngle] (
                           /* @p_startX  */ @p_circular_arc.STStartPoint().STX,
                           /* @p_startY  */ @p_circular_arc.STStartPoint().STY, 
                           /* @p_centreX */ @v_circle.STX,
                           /* @p_centreY */ @v_circle.STY,
                           /* @p_endX    */ @p_circular_arc.STPointN(2).STX,
                           /* @p_endY    */ @p_circular_arc.STPointN(2).STY
                         )
                        );

    -- Compute distance from start point to mid point.
    SET @v_mid_length = ABS( [$(cogoowner)].[STComputeArcLength] ( 
                              /* Radius */ @v_circle.Z,
                              /* Angle  */ @v_angle
                             )
                        );

    -- If v_mid_length is between v_start_length and v_end_length then we can reuse the existing point.
    IF ( @v_mid_length BETWEEN @v_start_length
                           AND @v_end_length )
    BEGIN
      SET @v_mid_point = @p_circular_arc.STPointN(2);
    END
    ELSE
    BEGIN
      -- Compute new point at mid way between start and end points
      SET @v_mid_length = @v_start_length + ((@v_end_length - @v_start_length) / 2.0);
      SET @v_mid_point  =  [$(lrsowner)].[STFindArcPointByLength] (
                             /* @p_circular_arc */ @p_circular_arc,
                             /* @p_length       */ @v_mid_length,
                             /* @p_offset       */ @v_offset,
                             /* @p_round_xy     */ @v_round_xy,
                             /* @p_round_zm     */ @v_round_zm
                         );
    END;

    -- Now construct and return new CircularArc
    -- 
    SET @v_wkt = 'CIRCULARSTRING(' 
                 +
                 [$(owner)].[STPointAsText] (
                     /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                     /* @p_X          */ @v_start_point.STX,
                     /* @p_Y          */ @v_start_point.STY,
                     /* @p_Z          */ @v_start_point.Z,
                     /* @p_M          */ @v_start_point.M,
                     /* @p_round_x    */ @v_round_xy,
                     /* @p_round_y    */ @v_round_xy,
                     /* @p_round_z    */ @v_round_zm,
                     /* @p_round_m    */ @v_round_zm
                 ) 
                 +
                 ', '
                 +
                 [$(owner)].[STPointAsText] (
                     /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                     /* @p_X          */ @v_mid_point.STX,
                     /* @p_Y          */ @v_mid_point.STY,
                     /* @p_Z          */ @v_mid_point.Z,
                     /* @p_M          */ @v_mid_point.M,
                     /* @p_round_x    */ @v_round_xy,
                     /* @p_round_y    */ @v_round_xy,
                     /* @p_round_z    */ @v_round_zm,
                     /* @p_round_m    */ @v_round_zm
                 ) 
                 +
                 ', '
                 +
                 [$(owner)].[STPointAsText] (
                     /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                     /* @p_X          */ @v_end_point.STX,
                     /* @p_Y          */ @v_end_point.STY,
                     /* @p_Z          */ @v_end_point.Z,
                     /* @p_M          */ @v_end_point.M,
                     /* @p_round_x    */ @v_round_xy,
                     /* @p_round_y    */ @v_round_xy,
                     /* @p_round_z    */ @v_round_zm,
                     /* @p_round_m    */ @v_round_zm
                 ) 
                 +
                 ')';
    -- Now construct, possibly offset, and return new LineString
    -- 
    RETURN CASE WHEN @v_offset = 0.0
                THEN geometry::STGeomFromText(@v_wkt,@p_circular_arc.STSrid)
                ELSE [$(owner)].[STOffsetSegment] (
                        /* @p_linestring */ geometry::STGeomFromText(@v_wkt,@p_circular_arc.STSrid),
                        /* @p_offset     */ @v_offset,
                        /* @p_round_xy   */ @v_round_xy,
                        /* @p_round_zm   */ @v_round_zm 
                      )
            END;
  End;
End;
GO


