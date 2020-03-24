SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***************************************************************';
PRINT 'Database Schema Variables are: LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STWhichSide]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STWhichSide];
  PRINT 'Dropped [$(owner)].[STWhichSide] ...';
END
ELSE
  PRINT '[$(owner)].[STWhichSide] does not exist...';
GO

PRINT 'Creating  [$(owner)].[STWhichSide]...';
GO

CREATE FUNCTION [$(owner)].[STWhichSide] (
  @p_linestring geometry,
  @p_point      geometry,
  @p_round      int = 3
)
Returns varchar(1)
As
Begin
  DECLARE
    @v_geometry_type       varchar(100),
    @v_round               int,
    @v_deflection_angle    float,
    @v_distance_to_segment float,
    @v_distance_to_centre  float,
    @v_radius              float,
    @v_sum_distance        float,
    @v_circle              geometry,
    @v_point               geometry,
    @v_segment             geometry;

  IF (@p_linestring is null or @p_point is null)
    return NULL;

  SET @v_round = ISNULL(@p_round,3);

  -- get segment that is closest to the supplied point
  SELECT @v_segment             = s.[segment],
         @v_geometry_type       = s.[geometry_type],
         @v_distance_to_segment = s.[closest_distance]
    FROM [$(owner)].[STSegmentize] (
                 /* @p_geometry     */ @p_linestring,
                 /* @p_filter       */ 'CLOSEST',
                 /* @p_point        */ @p_point,
                 /* @p_filter_value */ NULL,
                 /* @p_start_value  */ NULL,
                 /* @p_end_value    */ NULL,
                 @v_round,12,12
         ) as s;

  IF (@v_distance_to_segment is null)
    RETURN NULL; -- Error?

  IF (@v_distance_to_segment = 0.0) 
    RETURN 'O';

  IF ( @v_geometry_type = 'LineString' ) 
  BEGIN
    -- Compute offset direction 
    SET @v_deflection_angle = [$(cogoowner)].[STSubtendedAngleByPoint] (
                                 /* @p_start  */ @v_segment.STStartPoint(),
                                 /* @p_centre */ @v_segment.STEndPoint(),
                                 /* @p_end    */ @p_point 
                              );
    RETURN case when SIGN(@v_deflection_angle) = -1 
                then 'L' 
                else 'R' 
            end;
  END 
  ELSE
  BEGIN
    SET @v_deflection_angle = [$(cogoowner)].[STFindDeflectionAngle] (
                                  /*@p_from_line*/ @v_segment,
                                  /*@p_to_line  */ NULL
                               );
    -- Find centre of circular arc
    SET @v_circle = [$(cogoowner)].[STFindCircleFromArc]( @v_segment );
    SET @v_radius = ROUND(@v_circle.Z,@p_round);
    -- Remove radius
    SET @v_circle = geometry::Point(
                      @v_circle.STStartPoint().STX,
                      @v_circle.STStartPoint().STY,
                      @p_linestring.STSrid
                    );
    SET @v_distance_to_centre = ROUND(@p_point.STDistance(@v_circle),@p_round);
    IF ( @v_distance_to_centre = 0.0 ) 
      RETURN case when @v_deflection_angle < 0 then 'L' else 'R' end;
     
    SET @v_sum_distance = ROUND(@v_distance_to_centre + @v_distance_to_segment,@v_round);
    IF ( @v_sum_distance > @v_radius) 
      RETURN case when @v_deflection_angle < 0 then 'R' else 'L' end;

    RETURN case when @v_deflection_angle = 0 then 'O' when @v_deflection_angle > 0 then 'L' else 'R' end;
  END;
  RETURN NULL;
End;
GO


