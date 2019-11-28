PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STRemoveCollinearPoints]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[STRemoveCollinearPoints];
  PRINT 'Dropped [$(owner)].[STRemoveCollinearPoints] ...';
END;
GO

PRINT 'Creating [$(owner)].[STRemoveCollinearPoints] ...';
GO

Create Function [$(owner)].[STRemoveCollinearPoints]
(
  @p_linestring          geometry,
  @p_collinear_threshold float = 0.5,
  @p_round_xy            int   = 3,
  @p_round_z             int   = 2,
  @p_round_m             int   = 2
)
Returns varchar(max) -- geometry
As
/****f* EDITOR/STRemoveCollinearPoints (2012)
 *  NAME
 *    STRemoveCollinearPoints -- Function that removes unnecessary points that lie on straight line between adjacent points.
 *  SYNOPSIS
 *    Function [$(owner)].[STRemoveCollinearPoints] (
 *               @p_linestring          geometry,
 *               @p_collinear_threshold float = -1,
 *               @p_round_xy            int = 3,
 *               @p_round_z             int = 2,
 *               @p_round_m             int = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].[STRemoveCollinearPoints] (
 *             geometry::STGeomFromText('LINESTRING(0 0,0.5 0.5,1 1)',0),
 *             0.5,
 *             3,
 *             2,2
 *           ).AsTextZM() as LineWithCollinearPointsRemoved;
 *    LineWithCollinearPointsRemoved
 *    ---------------------------------------------
 *    LINESTRING (0 0,1 1)
 *  DESCRIPTION
 *    Function that checks each triple of adjacent points and removes middle one if collinear with start and end point.
 *    Collinearity is determined by computing the deflection angle (degrees) at the mid point and comparing it to the @p_collinear_threshold parameter value (degrees).
 *    If the collinear threshold value is < the deflection angle, the mid point is removed.
 *    The updated coordinate's XY ordinates are rounded to p_round_xy number of decimal digits of precision.
 *    The updated coordinate's Z ordinate is rounded to @p_round_Z number of decimal digits of precision.
 *    The updated coordinate's M ordinate is rounded to @p_round_M number of decimal digits of precision.
 *  INPUTS
 *    @p_linestring       (geometry) - Supplied Linestring geometry.
 *    @p_round_xy              (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_z               (int) - Decimal degrees of precision to which any calculated Z ordinates is rounded.
 *    @p_round_m               (int) - Decimal degrees of precision to which any calculated M ordinates is rounded.
 *  RESULT
 *    Modified linestring (geometry) - Input linestring with any collinear points removed.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2018 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_geometry_type       varchar(100),
    @v_wkt                 varchar(max),
    @v_dimensions          varchar(4),
    @v_round_xy            int,
    @v_round_z             int,
    @v_round_m             int,
    @v_subtended_angle     float,
    @v_collinear_threshold float,

    /* STSegmentLine Variables*/
    @v_id                  int,
    @v_max_id              int,
    @v_multi_tag           varchar(100),
    @v_element_id          int,
    @v_prev_element_id     int,
    @v_element_tag         varchar(100),
    @v_prev_element_tag    varchar(100),
    @v_length              float,
    @v_nextLength          float,
    @v_segment_geom        geometry,
    @v_next_segment_geom   geometry;
  Begin
    If ( @p_linestring is null ) 
      Return @p_linestring.AsTextZM();

    -- Only process linear geometries.
    SET @v_geometry_type = @p_linestring.STGeometryType();
    IF ( @v_geometry_type NOT IN ('LineString',
                                  'MultiLineString') )
      Return @p_linestring.AsTextZM();

    SET @v_dimensions          = 'XY'
                                 + case when @p_linestring.HasZ=1 then 'Z' else '' end +
                                 + case when @p_linestring.HasM=1 then 'M' else '' end;
    SET @v_round_xy            = ISNULL(@p_round_xy,3);
    SET @v_round_z             = ISNULL(@p_round_z,2);
    SET @v_round_m             = ISNULL(@p_round_m,2);
    SET @v_collinear_threshold = case when ISNULL(@p_collinear_threshold,-1) < 0 then -1 else @p_collinear_threshold end;

    -- Walk over all the segments of the linear geometry
    DECLARE cSegments 
     CURSOR FAST_FORWARD 
        FOR
     SELECT max(v.id) over (partition by v.multi_tag) as max_id,
            v.id,            v.multi_tag,
            v.element_id,    v.element_tag,
            v.length,        lead(v.length,1) over (order by v.id) as next_length,
            v.geom,          lead(v.geom,  1) over (order by v.id) as next_segment_geom
       FROM [$(owner)].[STSegmentLine](@p_linestring) as v
      ORDER by v.element_id, 
               v.subelement_id, 
               v.segment_id

   OPEN cSegments;

   FETCH NEXT 
    FROM cSegments 
    INTO @v_max_id,        @v_id, 
         @v_multi_tag,     @v_element_id,    @v_element_tag, 
         @v_length,        @v_nextLength,
         @v_segment_geom,  @v_next_segment_geom;

   SET @v_prev_element_tag = UPPER(@v_element_tag);
   SET @v_prev_element_id  = @v_element_id;
   SET @v_wkt              = UPPER(case when @v_multi_tag is not null then @v_multi_tag else @v_element_tag end) 
                             + 
                             case when @v_multi_tag = 'MultiLineString' then ' ((' else ' (' end
                             + 
                             [$(owner)].[STPointGeomAsText] (
                               /* @p_point    */ @v_segment_geom.STStartPoint(),
                               /* @p_round_xy */ @v_round_xy,
                               /* @p_round_z  */ @v_round_z,
                               /* @p_round_m  */ @v_round_m
                             )
                             + 
                             ',';
   WHILE @@FETCH_STATUS = 0
   BEGIN

     IF ( @v_element_tag <> @v_prev_element_tag 
       or @v_element_id  <> @v_prev_element_id )
     BEGIN
       SET @v_wkt = @v_wkt + '), ' ;
       -- First Coord of new element segment.
       --
       SET @v_wkt = @v_wkt 
                    + 
                    [$(owner)].[STPointGeomAsText] (
                      /* @p_point    */ @v_segment_geom.STStartPoint(),
                      /* @p_round_xy */ @v_round_xy,
                      /* @p_round_z  */ @v_round_z,
                      /* @p_round_m  */ @v_round_m
                    )
                    + 
                    ',';
     END  
     ELSE
     BEGIN
       -- Add comma unless already there...
       IF ( CHARINDEX(',',@v_wkt,LEN(@v_wkt)-1) <> LEN(@v_wkt) ) 
         SET @v_wkt = @v_wkt + ',';
     END;

     IF ( @v_id < @v_max_id )
     BEGIN
       -- Check angle between two segments
       SET @v_subtended_angle = ABS(
                                  [$(cogoowner)].[STDegrees] ( 
                                    [$(cogoowner)].[STSubtendedAngle] (
                                      @v_segment_geom.STStartPoint().STX,
                                      @v_segment_geom.STStartPoint().STY,
                                      @v_segment_geom.STEndPoint().STX,
                                      @v_segment_geom.STEndPoint().STY,
                                      @v_next_segment_geom.STEndPoint().STX,
                                      @v_next_segment_geom.STEndPoint().STY
                                    )
                                  )
                              );
     END;

     IF ( -- Last segment no angle check, just add last point
          @v_id = @v_max_id
          OR
          -- We Do Not Have a Collinar Point 
          ABS(@v_subtended_angle - 180) > @v_collinear_threshold 
        ) 
     BEGIN
       SET @v_wkt = @v_wkt 
                    + 
                    [$(owner)].[STPointGeomAsText] (
                      /* @p_point    */ @v_segment_geom.STEndPoint(),
                      /* @p_round_xy */ @v_round_xy,
                      /* @p_round_z  */ @v_round_z,
                      /* @p_round_m  */ @v_round_m
                     );
     END;

     SET @v_prev_element_tag = @v_element_tag;
     SET @v_prev_element_id  = @v_element_id;

     FETCH NEXT 
      FROM cSegments 
    INTO @v_max_id,        @v_id, 
         @v_multi_tag,     @v_element_id,    @v_element_tag, 
         @v_length,        @v_nextLength,
         @v_segment_geom,  @v_next_segment_geom;

   END;
   CLOSE cSegments
   DEALLOCATE cSegments
   SET @v_wkt = @v_wkt + ')';
   IF ( @v_multi_tag is not null ) 
     SET @v_wkt = @v_wkt + ')';
   Return @v_wkt; -- geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid);
  End;
END;
GO

PRINT 'Testing [$(owner)].[STRemoveCollinearPoints] ...';
GO

select [$(owner)].[STRemoveCollinearPoints]( geometry::STGeomFromText('LINESTRING(0 0,1 1,2 2)',0),1.0,3,2,1) as angle;
GO

select [$(owner)].[STRemoveCollinearPoints] (geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,2.1 0,2.2 0.0,2.3 0,3 0)',0),1.0,3,2,1) as cleanedLine ;
GO

