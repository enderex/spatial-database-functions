SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '*************************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) COGO Owner([$(cogoowner)])';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STIntersect2CircularArcs]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STIntersect2CircularArcs];
  PRINT 'Dropped [$(owner)].[STIntersect2CircularArcs] ...';
END;
GO

PRINT 'Creating [$(owner)].[STIntersect2CircularArcs] ...';
GO

Create Function [$(owner)].[STIntersect2CircularArcs] (
  @SELF      geometry,
  @p_segment geometry
)
Returns geometry -- Segment 
As
Begin
  Declare
    @v_round_xy int = 15,
    @v_iPoints  geometry,
    @v_circle_1 geometry,
    @v_circle_2 geometry,
    @v_P0       geometry,
    @v_P1       geometry,
    @v_P2       geometry,
    @v_d        Float,
    @v_a        Float,
    @v_h        Float;

    IF ( @SELF.STGeometryType() != 'CircularString' AND @p_segment.STGeometryType() <> 'CircularString' ) 
      -- One is a CircularArc: Call STIntersect'
      RETURN @SELF.STIntersection(@p_segment)
    ELSE
      IF ( NOT (@SELF.STGeometryType() = 'CircularString' AND @p_segment.STGeometryType() = 'CircularString' ) ) 
        -- Two CircularArcs: Call STIntersect2CircularArcs
        RETURN [$(owner)].[STIntersect2CircularArcs](@SELF,@p_segment);


    SET @v_circle_1 = [$(cogoowner)].[STFindCircleFromArc](@SELF);
    SET @v_circle_2 = [$(cogoowner)].[STFindCircleFromArc](@p_segment);
    IF ( ( @v_circle_1.STStartPoint().STX = -1 and @v_circle_1.STStartPoint().STY = -1 and @v_circle_1.STStartPoint().Z = -1 )
      OR ( @v_circle_2.STStartPoint().STX = -1 and @v_circle_2.STStartPoint().STY = -1 and @v_circle_2.STStartPoint().Z = -1 ) )
      Return @SELF.STIntersection(@p_segment);

    SET @v_P0 = geometry::Point(@v_circle_1.STX,@v_circle_1.STY,@SELF.STSrid);
    SET @v_P1 = geometry::Point(@v_circle_2.STX,@v_circle_2.STY,@SELF.STSrid);
    SET @v_d  = @v_P0.STDistance(@v_P1);
    SET @v_a  = ((@v_circle_1.Z*@v_circle_1.Z) - (@v_circle_2.Z*@v_circle_2.Z) + (@v_d*@v_d)) / (CAST(2.0 as float)*@v_d);
    SET @v_h  = SQRT(@v_circle_1.Z*@v_circle_1.Z - @v_a*@v_a);

    SET @v_P2 = [$(owner)].[STPointSubtract](@v_P1,@v_P0);
    SET @v_P2 = [$(owner)].[STPointScale](@v_P2,@v_a/@v_d);
    SET @v_P2 = [$(owner)].[STPointAdd](@v_P2,@v_P0);
    SET @v_iPoints = [$(owner)].[STMakeLineXY] (
                        /* p_start_x   */ @v_P2.STX + @v_h * (@v_P1.STY - @v_P0.STY) / @v_d,
                        /* p_start_y   */ @v_P2.STY - @v_h * (@v_P1.STX - @v_P0.STX) / @v_d,
                        /* p_end_x     */ @v_P2.STX - @v_h * (@v_P1.STY - @v_P0.STY) / @v_d,
                        /* p_end_y     */ @v_P2.STY + @v_h * (@v_P1.STX - @v_P0.STX) / @v_d,
                        /* p_srid      */ @SELF.STSrid,
                        /* @p_round_xy */ @v_round_xy
                     );
    Return @v_iPoints;
END;
GO
