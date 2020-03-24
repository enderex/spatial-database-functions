SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '*************************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) COGO Owner([$(cogoowner)])';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STIntersectCircularArc]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STIntersectCircularArc];
  PRINT 'Dropped [$(owner)].[STIntersectCircularArc] ...';
END;
GO

PRINT 'Creating [$(owner)].[STIntersectCircularArc] ...';
GO

CREATE FUNCTION [$(owner)].[STIntersectCircularArc] (
  @SELF      geometry,
  @p_segment geometry
)
Returns geometry
As
Begin
  Declare
    @c_dPrecision             integer = 8,
    @v_centre                 geometry,
    @v_p1                     geometry,
    @v_p2                     geometry,
    @v_a                      Float,
    @v_abScalingFactor1       Float,
    @v_abScalingFactor2       Float,
    @v_bBy2                   Float,
    @v_baX                    Float,
    @v_baY                    Float,
    @v_c                      Float,
    @v_caX                    Float,
    @v_caY                    Float,
    @v_disc                   Float,
    @v_pBy2                   Float,
    @v_q                      Float,
    @v_tmpSqrt                Float,

    -- Compute nearest point on @SELF and @p_segment
    @v_dist_int_pt2lineStart  Float,
    @v_dist_int_pt2lineEnd    Float, 
    @v_dist_int_pt2CurveStart Float,
    @v_dist_int_pt2CurveEnd   Float,
    @v_dist_int_pt2CurveMid   Float,
    @v_within_arc             bit,
    @v_pt1_line               Float,
    @v_pt1_arc                Float,
    @v_arc_length             Float,
    @v_arc_length_2           Float,
    @v_line_length            Float,
    @v_line_segment           geometry,
    @v_circular_arc           geometry,
    @v_circular_arc_2         geometry,
    @v_iPoints_StartPoint     geometry,
    @v_iPoints_MidPoint       geometry,
    @v_iPoints_EndPoint       geometry,
    @v_vertex                 geometry;

  IF (      @SELF.STGeometryType() = 'CircularString' AND 
       @p_segment.STGeometryType() = 'CircularString' ) 
    -- Two CircularArcs: Call STIntersect2CircularArcs');
    RETURN [$(owner)].[STIntersect2CircularArcs](@SELF,@p_segment)
  ELSE
    IF (      @SELF.STGeometryType() <> 'CircularString' AND 
         @p_segment.STGeometryType() <> 'CircularString' ) 
      -- One is a CircularArc: Call SQL Server STIntersection (Z and M?)
      RETURN @SELF.STIntersection(@p_segment);

    -- We have a single LineString and CircularArc.
  SET @v_circular_arc = CASE WHEN @SELF.STGeometryType()  = 'CircularString' THEN @SELF ELSE @p_segment END;
  SET @v_line_segment = CASE WHEN @SELF.STGeometryType() <> 'CircularString' THEN @SELF ELSE @p_segment END;
  SET @v_arc_length   = @v_circular_arc.STLength();
  SET @v_line_length  = @v_line_segment.STLength();
  SET @v_centre       = [$(cogoowner)].[STFindCircleFromArc](@v_circular_arc); -- We have already checked if p_circular_arc is indeed a circular arc.

  IF ( @v_centre.STStartPoint().STX = -1 and @v_centre.STStartPoint().STY = -1 and @v_centre.STStartPoint().Z = -1 )
    Return NULL;

  SET @v_baX  = @v_line_segment.STEndPoint().STX - @v_line_segment.STStartPoint().STX;
  SET @v_baY  = @v_line_segment.STEndPoint().STY - @v_line_segment.STStartPoint().STY;
  SET @v_caX  = @v_centre.STX      - @v_line_segment.STStartPoint().STX;
  SET @v_caY  = @v_centre.STY      - @v_line_segment.STStartPoint().STY;
  SET @v_a    = POWER(@v_baX,2) + POWER(@v_baY,2);
  SET @v_bBy2 = @v_baX * @v_caX  + @v_baY * @v_caY;
  SET @v_c    = POWER(@v_caX,2) + POWER(@v_caY,2) - POWER(@v_centre.Z,2);
  SET @v_pBy2 = @v_bBy2 / @v_a;
  SET @v_q    = @v_c    / @v_a;
  SET @v_disc = @v_pBy2 * @v_pBy2 - @v_q;
    
  IF (@v_disc < 0) 
    Return geometry::STGeomFromText('LINESTRING EMPTY',@SELF.STSrid);

  -- if @v_disc == 0 .. dealt with later
  SET @v_tmpSqrt          = SQRT(@v_disc);
  SET @v_abScalingFactor1 = -@v_pBy2 + @v_tmpSqrt;
  SET @v_abScalingFactor2 = -@v_pBy2 - @v_tmpSqrt;
  SET @v_p1               = geometry::Point( 
                              @v_line_segment.STStartPoint().STX - @v_baX * @v_abScalingFactor1,
                              @v_line_segment.STStartPoint().STY - @v_baY * @v_abScalingFactor1,
                              @v_line_segment.STSrid
                            );
                            
  IF (@v_disc = 0) 
  BEGIN
    -- TODO: Why return?
    -- abScalingFactor1 == abScalingFactor2
    Return @v_p1;
  END;

  SET @v_p2 = geometry::Point (
                @v_line_segment.STStartPoint().STX - @v_baX * @v_abScalingFactor2,
                @v_line_segment.STStartPoint().STY - @v_baY * @v_abScalingFactor2,
                @SELF.STSrid
              );
    
  -- Computations are based on a circle.
  -- Which point is within the actual circular segment?
  -- Will be one nearest end/start points           
  SET @v_circular_arc_2 = [$(owner)].[STMakeCircularLine] (
                             /* @p_start_point */ @v_circular_arc.STStartPoint(),
                             /* @p_mid_point   */ @v_p2,
                             /* @p_end_point   */ @v_circular_arc.STEndPoint(),
                             15,15,15
                          );
  SET @v_arc_length_2 = @v_circular_arc_2.STLength();

  SET @v_iPoints_StartPoint = geometry::Point (
                                CASE WHEN ROUND(@v_arc_length,ISNULL(@c_dPrecision,6)) = ROUND(@v_arc_length_2,ISNULL(@c_dPrecision,6)) THEN @v_p1.STX ELSE @v_p2.STX END,
                                CASE WHEN ROUND(@v_arc_length,ISNULL(@c_dPrecision,6)) = ROUND(@v_arc_length_2,ISNULL(@c_dPrecision,6)) THEN @v_p1.STY ELSE @v_p2.STY END,
                                @SELF.STSrid
                              );

  SET @v_within_arc = 0;
  IF ( ROUND(@v_arc_length,6) = ROUND(@v_arc_length_2,6) ) 
  BEGIN
    SET @v_within_arc = 1;
    IF ( @SELF.STGeometryType() = 'CircularString' ) 
        -- @SELF is circular arc
      SET @v_iPoints_midPoint = @v_p1;
    ELSE 
      -- @p_segment is Circular Arc
      SET @v_iPoints_EndPoint = @v_p1;
  END;

  SET @v_dist_int_pt2lineStart = @v_iPoints_StartPoint.STDistance(@v_line_segment.STStartPoint());
  SET @v_dist_int_pt2lineEnd   = @v_iPoints_StartPoint.STDistance(@v_line_segment.STEndPoint());

  IF ( ROUND(@v_line_length,6) = ROUND(@v_dist_int_pt2LineStart,6) + ROUND(@v_dist_int_pt2LineEnd,6) ) 
  BEGIN
    IF ( @SELF.STGeometryType() = 'CircularString' ) 
      -- @SELF is circular arc
      SET @v_iPoints_EndPoint = @v_iPoints_StartPoint
    ELSE 
      -- @p_segment is Circular Arc
      SET @v_iPoints_midPoint = @v_iPoints_StartPoint;

    IF ( @v_within_arc = 1 ) 
      Return [$(owner)].[STMakeCircularLine](@v_iPoints_StartPoint,@v_iPoints_MidPoint,@v_iPoints_EndPoint,15,15,15);
  END
  ELSE
  BEGIN
    IF ( @v_dist_int_pt2LineStart = case when @v_dist_int_pt2LineStart < @v_dist_int_pt2LineEnd then @v_dist_int_pt2LineStart else @v_dist_int_pt2LineEnd end )
      SET @v_iPoints_midPoint = @SELF.STStartPoint()
    ELSE
     SET @v_iPoints_midPoint = @SELF.STEndPoint();
  END;
    
  IF ( @v_within_arc = 1 ) 
    -- We are finished
    Return [$(owner)].[STMakeCircularLine](@v_iPoints_StartPoint,@v_iPoints_MidPoint,@v_iPoints_EndPoint,15,15,15);
    
  SET @v_dist_int_pt2CurveStart = @v_iPoints_StartPoint.STDistance(@v_circular_arc.STStartPoint());
  SET @v_dist_int_pt2CurveEnd   = @v_iPoints_StartPoint.STDistance(@v_circular_arc.STEndPoint());

  SET @v_vertex = case when @v_dist_int_pt2CurveStart = 
                             case when @v_dist_int_pt2CurveStart< @v_dist_int_pt2CurveEnd 
                                  then @v_dist_int_pt2CurveStart
                                  else @v_dist_int_pt2CurveEnd 
                              end
                       then @v_circular_arc.STStartPoint()
                       else @v_circular_arc.STEndPoint()
                   end;
  -- Assign start/end Point to midPoint
  IF ( @SELF.STGeometryType() = 'CircularString' ) 
    SET @v_iPoints_midPoint = @v_vertex
  ELSE
    SET @v_iPoints_EndPoint = @v_vertex;

  Return [$(owner)].[STMakeCircularLine](@v_iPoints_StartPoint,@v_iPoints_MidPoint,@v_iPoints_EndPoint,15,15,15);
END ;
GO

