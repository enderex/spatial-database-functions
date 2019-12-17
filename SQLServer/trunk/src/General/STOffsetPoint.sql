DROP Function [$(owner)].[STOffsetPoint];
GO

CREATE Function [$(owner)].[STOffsetPoint](
  @p_linestring geometry,
  @p_ratio      Float,
  @p_offset     float
)
Returns geometry
AS
BEGIN
  DECLARE
    @v_geometry_type    varchar(100),
    @v_dims             integer,
    @v_az               float,
    @v_angle            float,
    @v_vertex           geometry,
    @v_centre           geometry,
    @v_bearing          float,
    @v_distance         float,
    @v_ratio            float,
    @v_delta_x          float,
    @v_dir              Integer,
    @v_delta            geometry,
    @v_point            geometry,
    @v_deflection_angle float,
    @v_arc_rotation     integer;

  -- STIsEmpty captures LINESTRING EMPTY
  IF (@p_linestring is null or @p_linestring.STIsEmpty()=1)
    Return NULL;

  SET @v_ratio = COALESCE(@p_ratio,-1);
  IF (@v_ratio NOT BETWEEN 0 AND 1) 
    Return NULL;

  SET @v_geometry_type = @p_linestring.STGeometryType();

  IF ( @v_geometry_type NOT IN ('LineString','CircularString') )
    Return @p_linestring;

  SET @v_dims = [$(owner)].[STCoordDim](@p_linestring.STStartPoint());
  IF ( @v_geometry_type = 'CircularString' )  -- CircularStringN?
  BEGIN
    -- DEBUG dbms_output.put_line('  STisCircularArc = 1');

    -- *** Short circuit if start/end coord.
    SET @v_vertex = case when @v_ratio = 0.0
                         Then @p_linestring.STStartPoint()
                         when @v_ratio = 1.0
                         then @p_linestring.STEndPoint()
                         else NULL
                     end;

    -- Short circuit vertex 
    IF ( @p_offset = 0.0 and @v_vertex is not null ) 
      return @v_vertex;

    -- *** End Short Circuit 

    -- Compute common centre and radius
    --
    SET @v_centre = [$(cogoowner)].[STFindCircleFromArc](@p_linestring);

    -- Defines circle?
    IF (  @v_centre.STX = -1 
      and @v_centre.STY = -1 
      and @v_centre.Z   = -1 )
      Return null;

    -- Retrieve radius and remove from centre point
    SET @v_distance = @v_centre.Z + (@p_offset * -1);
    SET @v_centre   = [$(owner)].[STMakePoint](
                         @v_centre.STX,
                         @v_centre.STY,
                         @p_linestring.STStartPoint().Z,
                         NULL,
                         @p_linestring.STSrid
                      );

    -- Get subtended angle ie angle of circular arc
    -- ** Short Circuit
    If ( @p_offset != 0.0 and @v_vertex is not null ) 
    BEGIN
      SET @v_bearing = [$(cogoowner)].[STBearingBetweenPoints](
                           @v_centre,
                           @v_vertex
                        );
    END
    ELSE
    BEGIN
      SET @v_angle = [$(cogoowner)].[STDegrees](
                        [$(cogoowner)].[STSubtendedAngleByPoint](
                           @p_linestring.STStartPoint(),
                           @v_centre,
                           @p_linestring.STEndPoint()
                        )
                      );

      SET @v_deflection_angle = [$(cogoowner)].[STFindDeflectionAngle]( @p_linestring, NULL );

      SET @v_arc_rotation     = SIGN(@v_deflection_angle);

      -- now get angle subtended by this measure ratio

      SET @v_angle = @v_ratio * @v_angle;

      -- Turn subtended angle of ratio into a bearing
      SET @v_bearing = [$(cogoowner)].[STBearingBetweenPoints](
                           @v_centre,
                           @p_linestring.STStartPoint()
                        );

      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing]( @v_bearing + (@v_arc_rotation * @v_angle) );
    END;

    -- Offset point is bearing+@v_radius from centre
    --
    SET @v_vertex = [$(cogoowner)].[STPointFromCOGO](
                        @v_centre,
                        @v_bearing,
                        @v_distance,
                        8
                     );

    IF ( @v_dims > 2 ) 
    BEGIN
      -- upscale @v_vertex to pretend Measure
      -- Compute M for 2D circular arc point
      SET @v_vertex = [$(owner)].[STMakePoint](
                         @v_vertex.STX,
                         @v_vertex.STY,
                         @p_linestring.STStartPoint().Z + @v_ratio * (@p_linestring.STEndPoint().Z - @p_linestring.STStartPoint().Z),
                         @p_linestring.STStartPoint().M + @v_ratio * (@p_linestring.STEndPoint().M - @p_linestring.STStartPoint().M), 
                         @p_linestring.STSrid
                    );
    END;

    -- DEBUG vertex on segment 
  END
  ELSE
  BEGIN
    -- DEBUG dbms_output.put_line('  LineString: Compute base offset');
    SET @v_az    = RADIANS(
                       [$(cogoowner)].[STBearingBetweenPoints] (
                         @p_linestring.STStartPoint(),
                         @p_linestring.STEndPoint()
                       )
                   );

    SET @v_dir   = CASE WHEN @v_az < PI() THEN -1 ELSE 1 END;

    SET @v_delta = geometry::Point(
                      ABS(COS(@v_az)) * COALESCE(@p_offset,0) * @v_dir,
                      ABS(SIN(@v_az)) * COALESCE(@p_offset,0) * @v_dir,
                      @p_linestring.STSrid
                    );

    SET @v_delta_x = @v_delta.STX;
    IF NOT ( @v_az > PI()/2
         AND @v_az < PI()
          OR @v_az > 3 * PI()/2 ) 
      SET @v_delta_x  = -1 * @v_delta.STX;

    -- @v_delta holds offset delta line
    -- Need to compute point for that offset
    SET @v_vertex = [$(owner)].[STMakePoint](
                       @v_delta_x   + @p_linestring.STStartPoint().STX + @v_ratio*(@p_linestring.STEndPoint().STX-@p_linestring.STStartPoint().STX),
                       @v_delta.STY + @p_linestring.STStartPoint().STY + @v_ratio*(@p_linestring.STEndPoint().STY-@p_linestring.STStartPoint().STY),
                       @p_linestring.STStartPoint().Z   + @v_ratio*(@p_linestring.STEndPoint().Z  -@p_linestring.STStartPoint().Z),
                       @p_linestring.STStartPoint().M   + @v_ratio*(@p_linestring.STEndPoint().M  -@p_linestring.STStartPoint().M),
                       @p_linestring.STSrid
                    );

  END;
  RETURN @v_vertex;
END;
GO

