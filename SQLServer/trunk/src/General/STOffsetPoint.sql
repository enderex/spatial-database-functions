SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: COGO=$(cogoowner) owner=$(owner)';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STOffsetPoint]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP Function [$(owner)].[STOffsetPoint];
  PRINT 'Dropped [$(owner)].[STOffsetPoint] ...';
END;
GO

PRINT 'Creating [$(owner)].[STOffsetPoint] ...';
GO

CREATE Function [$(owner)].[STOffsetPoint] (
  @p_linestring geometry,
  @p_ratio      Float,
  @p_offset     float,
  @p_round_xy   integer = 3,
  @p_round_z    integer = 2,
  @p_round_m    integer = 3
)
Returns geometry
AS
BEGIN
  DECLARE
    @v_geometry_type    varchar(100),
    @v_dimensions       varchar(4),
    @v_round_xy         integer,
    @v_round_z          integer,
    @v_round_m          integer,

    @v_sign             integer,
    @v_az               float,
    @v_angle            float,
    @v_vertex           geometry,
    @v_centre           geometry,
    @v_arc_point        geometry,
    @v_which            varchar(1),
    @v_arc_length       float,
    @v_radius           float,
    @v_circumference    float,
    @v_deflection_angle float,
    @v_arc_rotation     integer,
    @v_bearing          float,
    @v_offset           float,
    @v_ratio            float,
    @v_delta_x          float,
    @v_dir              Integer,
    @v_delta            geometry,
    @v_point            geometry,
    @v_linestring       geometry;

  -- STIsEmpty captures LINESTRING EMPTY
  IF (@p_linestring is null or @p_linestring.STIsEmpty()=1)
    Return NULL;

  SET @v_ratio = ISNULL(@p_ratio,0.0);
  IF (@v_ratio NOT BETWEEN 0 AND 1) 
    Return @p_linestring;

  SET @v_geometry_type = @p_linestring.STGeometryType();

  IF ( @v_geometry_type NOT IN ('LineString','CircularString') )
    Return @p_linestring;

  SET @v_linestring = @p_linestring;

  -- Need to be consistent with linestring.
  IF ( @v_linestring.STGeometryType() = 'CircularString')
  BEGIN
    IF ( @v_linestring.STNumPoints() > 3 ) 
      SET @v_linestring= [$(owner)].[STCircularStringN](@v_linestring,1);
  END;

  SET @v_round_xy   = ISNULL(@p_round_xy,3);
  SET @v_round_z    = ISNULL(@p_round_z,2);
  SET @v_round_m    = ISNULL(@p_round_m,3);
  SET @v_offset     = ISNULL(@p_offset,0.0);
  SET @v_dimensions = 'XY' 
                      + case when @v_linestring.HasZ=1 then 'Z' else '' end +
                      + case when @v_linestring.HasM=1 then 'M' else '' end ;

  -- Short circuit if start/end coord.
  IF ( @v_offset = 0.0 and (ROUND(@v_ratio,8) = 0.0 or ROUND(@v_ratio,8) = 1.0) )
  BEGIN
    Return case when @v_ratio = 0.0
                Then @v_linestring.STStartPoint()
                when @v_ratio = 1.0
                then @v_linestring.STEndPoint()
                else NULL
            end;
  END;

  -- ###########################################################################
  -- ############################## CircularString #############################
  -- ###########################################################################

  IF ( @v_geometry_type = 'CircularString' ) 
  BEGIN
    -- Compute centre of circle defining CircularString
    --
    SET @v_centre = [$(cogoowner)].[STFindCircleFromArc] (@v_linestring);
  
    -- Defines circle?
    IF (  @v_centre.STX = -1 and @v_centre.STY = -1 and @v_centre.Z   = -1 ) 
      Return null;

    -- Make circle a 2D point (throw away radius)
    SET @v_radius = @v_centre.Z;
    SET @v_centre = geometry::Point(@v_centre.STX,@v_centre.STY,@v_linestring.STSrid);
  
    -- Compute circumference of circle
    SET @v_circumference = 2.0 * PI() * @v_radius;

    -- Compute arcLength to our measure point
    SET @v_arc_length    = @v_linestring.STLength() * @v_ratio;
  
    -- Compute the angle subtended by the arc at the centre of the circle
    SET @v_angle          = (@v_arc_length / @v_circumference) * CAST(360.0 as float);
    
    -- Compute bearing from centre to first point of circular arc
    SET @v_bearing       = [$(cogoowner)].[STBearingBetweenPoints](
                               @v_centre,
                               @v_linestring.STStartPoint()
                           );

    -- Which side of circularString is its centre beginning at starting point ?
    -- 
    SET @v_sign   = SIGN(@v_offset);
    SET @v_which  = [$(owner)].[STWhichSide](@v_linestring,@v_centre,@v_round_xy);

    -- Calculate bearing from circle centre to measure point using computed angle and side
    -- 
    SET @v_bearing += CASE WHEN @v_which = 'L'
                           THEN -1 * @v_angle
                           ELSE @v_angle
                       END;

    -- Normalise bearing
    SET @v_bearing = [$(cogoowner)].[STNormalizeBearing](@v_bearing);

    -- Create point on CircularArc
    --
    SET @v_arc_point = [$(cogoowner)].[STPointFromCOGO](
                          @v_centre,
                          @v_bearing,
                          @v_radius,
                          @v_round_xy
                       );

    -- If point is offset, generate point from this point on circularString
    IF ( ABS(@v_offset) = 0.0 )
    BEGIN
      SET @v_point = @v_arc_point;
    END
    ELSE -- IF ( ABS(@v_offset) <> 0.0 )
    BEGIN
      -- Bearing is from centre of circularString to point on circularArc
      -- Compute bearing from point on circularArc to actual offset point
      --
      SET @v_bearing = case when @v_which = 'L' and @v_offset < 0
                            then @v_bearing + 180.0
                            when @v_which = 'L' and @v_offset > 0
                            then @v_bearing
                            when @v_which = 'R' and @v_offset < 0
                            then @v_bearing
                            when @v_which = 'R' and @v_offset > 0
                            then @v_bearing + 180.0
                        end;

      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing](@v_bearing);
  
      -- Compute point 
      SET @v_point = [$(cogoowner)].[STPointFromCOGO](
                         @v_arc_point,
                         @v_bearing,
                         ABS(@v_offset),
                         @v_round_xy
                     );

    END;

    -- MAYBE: If new point between STPointN(1) and STPointN(2) not just 1-3 then M may need to be computed differently 
    -- However, a circularstring is a homogeneous object and M is a measure like a length....
    -- In SQL Server a CircularString's Z ordinates have to all be the same.
    --
    SET @v_vertex = geometry::STPointFromText(
                    'POINT(' 
                    + 
                    [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @v_point.STX,
                            /* @p_Y          */ @v_point.STY,
                            /* @p_Z          */ @v_linestring.STStartPoint().Z,
                            /* @p_Z          */ @v_linestring.STStartPoint().M + @v_ratio*(@v_linestring.STEndPoint().M - @v_linestring.STStartPoint().M),
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_z,
                            /* @p_round_m    */ @v_round_m
                    )
                    + 
                    ')',
                    @v_linestring.STSrid
                  );

    Return @v_vertex;
  END
  ELSE
  BEGIN

    -- ###########################################################################
    -- ############################## LineString #################################
    -- ###########################################################################

    -- LineString: Compute base offset
    SET @v_az    = RADIANS(
                       [$(cogoowner)].[STBearingBetweenPoints] (
                         @v_linestring.STStartPoint(),
                         @v_linestring.STEndPoint()
                       )
                   );

    SET @v_dir   = CASE WHEN @v_az < PI() THEN -1 ELSE 1 END;

    SET @v_delta = geometry::Point(
                      ABS(COS(@v_az)) * @v_offset * @v_dir,
                      ABS(SIN(@v_az)) * @v_offset * @v_dir,
                      @v_linestring.STSrid
                    );

    SET @v_delta_x = @v_delta.STX;
    IF NOT ( @v_az > PI()/2
         AND @v_az < PI()
          OR @v_az > 3 * PI()/2 ) 
      SET @v_delta_x  = -1 * @v_delta.STX;

    -- @v_delta holds offset delta line
    -- Need to compute point for that offset
    SET @v_vertex = [$(owner)].[STMakePoint](
                       @v_delta_x   + @v_linestring.STStartPoint().STX + @v_ratio*(@v_linestring.STEndPoint().STX-@v_linestring.STStartPoint().STX),
                       @v_delta.STY + @v_linestring.STStartPoint().STY + @v_ratio*(@v_linestring.STEndPoint().STY-@v_linestring.STStartPoint().STY),
                       @v_linestring.STStartPoint().Z                  + @v_ratio*(@v_linestring.STEndPoint().Z  -@v_linestring.STStartPoint().Z),
                       @v_linestring.STStartPoint().M                  + @v_ratio*(@v_linestring.STEndPoint().M  -@v_linestring.STStartPoint().M),
                       @v_linestring.STSrid
                    );

  END;
  RETURN @v_vertex;
END;
GO

