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
    @v_geometry_type      varchar(100),
    @v_deflection_angle   float,
    @v_closest_distance   float,
    @v_distance_to_centre float,
    @v_radius             float,
    @v_distance           float,
    @v_circle             geometry,
    @v_segment            geometry;

  IF (@p_linestring is null or @p_point is null)
    return NULL;

  -- get segment that is closest to the supplied point
  SELECT @v_segment          = s.[segment],
         @v_geometry_type    = s.[geometry_type],
         @v_closest_distance = s.[closest_distance]
    FROM [$(owner)].[STSegmentize] (
                 /* @p_geometry     */ @p_linestring,
                 /* @p_filter       */ 'CLOSEST',
                 /* @p_point        */ @p_point,
                 /* @p_filter_value */ NULL,
                 /* @p_start_value  */ NULL,
                 /* @p_end_value    */ NULL,
                 ISNULL(@p_round,3),8,8
         ) as s;

  IF (@v_closest_distance is null)
    RETURN NULL; -- Error?

  IF (@v_closest_distance = 0.0) 
    RETURN 'O';

  IF ( @v_geometry_type = 'LineString' ) 
  BEGIN
    -- Compute offset direction 
    SET @v_deflection_angle = [$(cogoowner)].[STSubtendedAngleByPoint] (
                                 /* @p_start */  @v_segment.STStartPoint(),
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
                                  /*@p_from_line*/ @p_linestring,
                                  /*@p_to_line  */ NULL
                               );
    -- Find centre of circular arc
    SET @v_circle = [$(cogoowner)].[STFindCircleFromArc]( @p_linestring );
    SET @v_radius = ROUND(@v_circle.Z,ISNULL(@p_round,3));
    -- Remove radius
    SET @v_circle = geometry::Point(
                         @v_circle.STStartPoint().STX,
                         @v_circle.STStartPoint().STY,
                         @p_linestring.STSrid
                      );
    SET @v_distance_to_centre = @p_point.STDistance(@v_circle);
    SET @v_distance           = ROUND(@v_distance_to_centre + @v_closest_distance,ISNULL(@p_round,3));
    IF ( @v_distance = @v_radius) 
      RETURN case when @v_deflection_angle < 0 then 'L' else 'R' end;

    IF ( @v_distance > @v_radius) 
      RETURN case when @v_deflection_angle < 0 then 'R' else 'L' end;

    RETURN case when @v_deflection_angle = 0 then 'O' when @v_deflection_angle > 0 then 'L' else 'R' end;
  END;
  RETURN NULL;
End;
GO


