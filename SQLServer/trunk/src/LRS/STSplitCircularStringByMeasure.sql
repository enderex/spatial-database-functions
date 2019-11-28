SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSplitCircularStringByMeasure]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STSplitCircularStringByMeasure];
  PRINT 'Dropped [$(lrsowner)].[STSplitCircularStringByMeasure] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STSplitCircularStringByMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STSplitCircularStringByMeasure] 
(
  @p_circular_arc  geometry,
  @p_start_measure float,
  @p_end_measure   float,
  @p_offset        float = 0.0,
  @p_round_xy      int   = 3,
  @p_round_zm      int   = 2
)
Returns geometry
As
/****f* LRS/STSplitCircularStringByMeasure (2012)
 *  NAME
 *    STSplitCircularStringByMeasure -- Extracts, and possibly offets, that part of the supplied (single) CircularString identified by the @p_start_measure and @p_end_measure parameters.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STSplitCircularStringByMeasure] (
 *               @p_circular_arc  geometry,
 *               @p_start_measure Float,
 *               @p_end_measure   Float = null,
 *               @p_offset        Float = 0.0,
 *               @p_round_xy      int   = 3,
 *               @p_round_zm      int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given start and end measures, this function extracts a new CircularString segment from the @p_circular_arc.
 *    If a non-zero value is suppied for @p_offset, the extracted circularSting is then offset to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *    If the circularString offset causes the CircularString to disappear, NULL is returned.
 *  NOTES
 *    Supports a single (3-point) CircularString element only.
 *    Currently only supports Increasing measures.
 *  INPUTS
 *    @p_circular_arc (geometry) - A single, 3 point, CircularString.
 *    @p_start_measure   (float) - Measure defining start point of located geometry.
 *    @p_end_measure     (float) - Measure defining end point of located geometry.
 *    @p_offset          (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_round_xy          (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm          (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    CircularString  (geometry) - New CircularString between start/end measure with optional offset.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_wkt           varchar(max),
    @v_Dimensions    varchar(4),
    @v_offset        float,
    @v_start_measure float,
    @v_mid_measure   float,
    @v_end_measure   float,
    @v_round_xy      int,
    @v_round_zm      int,
    @v_circle        geometry,
    @v_start_point   geometry,
    @v_mid_point     geometry,
    @v_end_point     geometry,
    @v_return_geom   geometry;
  Begin
    IF ( @p_circular_arc is null )
      Return NULL;
    IF ( @p_Circular_arc.STGeometryType() <> 'CircularString' ) -- This function is for CircularArcs
      Return NULL;
    IF ( @p_circular_arc.STNumCurves() > 1 )                    -- We only process a single CircularString
      Return @p_Circular_arc;
    IF ( @p_circular_arc.HasM = 0 )                             -- And we only process measured CircularStrings
      Return @p_Circular_arc;
    IF ( @p_start_measure is null and @p_end_measure is null )
      Return @p_circular_arc;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_offset   = ISNULL(@p_offset,0.0);

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_circular_arc.HasZ=1 then 'Z' else '' end 
                       + case when @p_circular_arc.HasM=1 then 'M' else '' end;

    -- Set up distances ....
    SET @v_start_measure = case when @p_start_measure is null 
                                then @p_circular_arc.STPointN(1).M
                                else case when @p_start_measure < @p_circular_arc.STStartPoint().M
                                          then @p_circular_arc.STStartPoint().M
                                          else @p_start_measure
                                      end
                            end;
    SET @v_end_measure   = case when @p_end_measure is null 
                                then @p_circular_arc.STEndPoint().M
                                else case when @p_end_measure > @p_circular_arc.STEndPoint().M
                                          then @p_circular_arc.STLength()
                                          else @p_end_measure
                                      end
                            end;
    -- Simple (fast) check if measures are descending 
    IF ( ROUND(@v_start_measure,@v_round_zm) > ROUND(@p_circular_arc.STEndPoint().M,@v_round_zm) )
      Return NULL;

    -- Get Circle Centre and Radius
    SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @p_circular_arc );

    -- Start point will be at v_start_measure from first point...
    -- 
    SET @v_start_point = [$(lrsowner)].[STFindArcPointByMeasure] (
                             /* @p_circular_arc */ @p_circular_arc,
                             /* @p_measure      */ @v_start_measure,
                             /* @p_offset       */ @v_offset,
                             /* @p_round_xy     */ @v_round_xy,
                             /* @p_round_zm     */ @v_round_zm   
                         );

    -- If start=end we have a single point
    --
    IF ( ROUND(@v_start_measure,@v_round_zm) = ROUND(@v_end_measure,@v_round_zm) ) 
      Return @v_start_point;

    -- Compute Mid Point ...
    -- If v_mid_measure is between v_start_measure and v_end_measure then we will reuse existing point.
    --
    IF ( @p_circular_arc.STPointN(2).M BETWEEN @v_start_measure AND @v_end_measure )
    BEGIN
      SET @v_mid_point = @p_circular_arc.STPointN(2);
    END
    ELSE
    BEGIN
      SET @v_mid_measure = @v_start_measure + ( (@v_end_measure - @v_start_measure) / 2.0 );
      -- Compute new point at mid way between distances
      SET @v_mid_point =  [$(lrsowner)].[STFindArcPointByMeasure] (
                             /* @p_circular_arc */ @p_circular_arc,
                             /* @p_measure      */ @v_mid_measure,
                             /* @p_offset       */ @v_offset,
                             /* @p_round_xy     */ @v_round_xy,
                             /* @p_round_zm     */ @v_round_zm   
                         );
    END;

    -- Now compute End Point
    --
    SET @v_end_point = [$(lrsowner)].[STFindArcPointByMeasure] (
                           /* @p_circular_arc */ @p_circular_arc,
                           /* @p_measure      */ @v_end_measure,
                           /* @p_offset       */ @v_offset,
                           /* @p_round_xy     */ @v_round_xy,
                           /* @p_round_zm     */ @v_round_zm   
                       );

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
    IF ( @v_offset = 0.0 )
      SET @v_return_geom = geometry::STGeomFromText(@v_wkt,@p_circular_arc.STSrid)
    ELSE
      SET @v_return_geom = [$(lrsowner)].[STOffsetSegment] (
                              /* @p_linestring */ geometry::STGeomFromText(@v_wkt,@p_circular_arc.STSrid),
                              /* @p_offset     */ @v_offset,
                              /* @p_round_xy   */ @v_round_xy,
                              /* @p_round_zm   */ @v_round_zm 
                            );
    Return @v_return_geom;
  End;
End;
GO
 

