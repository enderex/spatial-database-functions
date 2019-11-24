SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner=$(cogoowner) owner=$(owner)';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STCheckRadii]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STCheckRadii];
  PRINT 'Dropped [$(owner)].[STCheckRadii] ...';
END;
GO

PRINT 'Creating [$(owner)].[STCheckRadii] ...';
GO

CREATE FUNCTION [$(owner)].[STCheckRadii](
 @p_geom       geometry, 
 @p_min_radius Float, 
 @p_round_xy   integer
)
  Returns geometry 
AS
/****f* GEOPROCESSING/STCheckRadii (2008)
 *  NAME
 *    STCheckRadii -- Checks if radius of any three points in a linestring are less than the desired amount.
 *  SYNOPSIS 
 *    Function [$(owner)].[STCheckRadii] (
 *      @p_geom       geometry, 
 *      @p_min_radius Float, 
 *      @p_precision  int
 *    )
 *    Returns geometry
 *  DESCRIPTION
 *    Function that checks vertices in a linestring/multilinestring to see if
 *    the circular arc they describe have radius less than the provided amount.
 *    Each set of three vertices (which could be overlapping) that fail the test
 *    are written to a single MultiPoint object. If no circular arcs in the linestring
 *    describe a circle with radius less than the required amount a NULL geometry is returned.
 *    If another other than a (Multi)linestring is provided it is returned as is. 
 *  NOTES
 *    Supports Linestrings with CircularString elements.
 *    Supplied geometry must not be geographic: function only guaranteed for projected data.
 *    Does not honour dimensions over 2.
 *  INPUTS
 *    @p_linestring (geometry) - Projected Linestring geometry 
 *    @p_min_radius    (Float) - A not null value that describes the minimum radiue of any arc within the linestring.
 *    @p_precision       (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *  RESULT
 *    points        (geometry) - For (m)linestrings the point triplets have a radius less than required; 
 *                               For CircularString itself if radius less than required, otherwise null
 *  EXAMPLE
 *    SELECT [$(owner)].[STCheckRadii](geometry::STGeomFromText('LINESTRING(0.0 0.0,10.0 0.0,10.0 10.0)',0),10.0,3).STAsText() as failingPoints;
 *    
 *    failingPoints
 *    MULTILINESTRING ((0 0, 10 0, 10 10))
 *    
 *    SELECT [$(owner)].[STCheckRadii](geometry::STGeomFromText('MULTILINESTRING((0.0 0.0,10.0 0.0,10.0 10.0),(20.0 0.0,30.0 0.0,30.0 10.0,35 15))',0), 15.0,3).STAsText()  as failingPoints; 
 *    
 *    failingPoints
 *    MULTILINESTRING ((0 0, 10 0, 10 10), (20 0, 30 0, 30 10), (30 0, 30 10, 35 15))
 *    
 *    with data as (
 *      select geometry::STGeomFromText('CIRCULARSTRING(0.0 0.0,10.0 10.0,20.0 0.0)',0) as circulararc
 *    )
 *    select gs.IntValue as requiredMinRadius,
 *           [$(cogoowner)].[STFindCircleFromArc](circularArc).Z as ArcRadius,
 *           [$(owner)].[STCheckRadii](
 *                    circulararc,
 *                    gs.IntValue,
 *                    3).STAsText() as failingArc
 *      from data as a
 *           cross apply
 *           [$(owner)].[generate_series](5,15,5) as gs;
 *    
 *    requiredMinRadius ArcRadius failingArc
 *    5                 10        NULL
 *    10                10        NULL
 *    15                10        CIRCULARSTRING (0 0, 10 10, 20 0)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  Declare
    @v_badRadii      int = 0,
    @v_GeometryType  varchar(100),
    @v_WKT           varchar(max),
    @v_geomn         int,
    @v_first         int,
    @v_second        int,
    @v_third         int,
    @v_srid          int,
    @v_geom          geometry,
    @v_srt_point     geometry,
    @v_mid_point     geometry,
    @v_end_point     geometry,
    @v_circle        geometry,
    @v_cx            float,
    @v_cy            float,
    @v_radius        float,
    @v_round_xy      integer = CASE WHEN @p_round_xy IS NULL THEN 3 ELSE @p_round_xy END,
    @v_format_string varchar(50);
  Begin
    SET @v_format_string = 'FM999999999999.' + REPLICATE('9',@v_round_xy);
    IF ( @p_geom is NULL ) BEGIN
      return NULL;
    END;

    IF ( @p_min_radius is null ) BEGIN
      return @p_geom;
    END;
    
    SET @v_GeometryType = @p_geom.STGeometryType();
    IF ( @v_GeometryType not in ('CircularString','LineString','MultiLineString' ) ) BEGIN
       return NULL;
    END;

    IF ( @p_geom.STNumPoints() < 3 ) BEGIN
      return NULL;
    END;

    SET @v_srid = @p_geom.STSrid;
    IF ( @v_GeometryType = 'CircularString' ) BEGIN
        -- Call FindCircle on CircularString
        SET @v_circle = [$(cogoowner)].[STFindCircleFromArc](@p_geom);
        IF ( @v_circle.Z IS NOT NULL AND @v_circle.Z <> -1 AND @v_circle.Z  < @p_min_radius ) BEGIN
          Return @p_geom;
        END;
        Return Null;
    END;

    SET @v_WKT  = 'MULTILINESTRING(';
    IF ( @v_GeometryType = 'LineString' ) BEGIN
      SET @v_badRadii = 0;
      SET @v_first    = 1;
      SET @v_second   = 2;
      SET @v_third    = 3;
      WHILE ( @v_third <= @p_geom.STNumPoints() ) 
      BEGIN
        SET @v_srt_point = @p_geom.STPointN(@v_first);
        SET @v_first     = @v_first  + 1;
        SET @v_mid_point = @p_geom.STPointN(@v_second);
        SET @v_second    = @v_second + 1;
        SET @v_end_point = @p_geom.STPointN(@v_third);
        SET @v_third     = @v_third  + 1;
        SET @v_radius    = -1;
        -- Call FindCircle
        SET @v_circle = [$(cogoowner)].[STFindCircleByPoint](@v_srt_point,@v_mid_point,@v_end_point);
        SET @v_cx     = @v_circle.STX;
        SET @v_cy     = @v_circle.STY;
        SET @v_radius = @v_circle.Z;
        IF ( @v_radius IS NOT NULL AND @v_radius <> -1 AND @v_radius < @p_min_radius ) BEGIN
          SET @v_badRadii = @v_badRadii + 1;
          IF ( @v_WKT <> 'MULTILINESTRING(' ) BEGIN
             SET @v_WKT = @v_WKT + ',';
          END;
          SET @v_WKT = @v_WKT + 
                          REPLACE([$(owner)].[STMakeCircularLine] (@v_srt_point,@v_mid_point,@v_end_point,
                                                                   @v_round_xy,null,null).STAsText(),
                          'CIRCULARSTRING','');
        END;
      END; -- LOOP 
      SET @v_WKT = @v_WKT + ')';
      IF ( @v_badRadii = 0 ) BEGIN
          Return NULL;
      END ELSE BEGIN
          Return geometry::STGeomFromText(@v_WKT,@v_srid);
      END;
    END;

    IF ( @v_GeometryType = 'MultiLineString' ) BEGIN
      SET @v_geomn = 1;
      WHILE ( @v_geomn <= @p_geom.STNumGeometries() ) 
      BEGIN
        SET @v_badRadii = 0;
        SET @v_geom     = @p_geom.STGeometryN(@v_geomn);
        SET @v_geomn    = @v_geomn + 1;
        SET @v_first    = 1;
        SET @v_second   = 2;
        SET @v_third    = 3;
        IF ( @v_geom.STNumPoints() < 3 ) BEGIN
           -- Skip this geometry
           CONTINUE;
        END;
        WHILE ( @v_third <= @v_geom.STNumPoints() ) 
        BEGIN
           SET @v_srt_point  = @v_geom.STPointN(@v_first);
           SET @v_first      = @v_first  + 1;
           SET @v_mid_point  = @v_geom.STPointN(@v_second);
           SET @v_second     = @v_second + 1;
           SET @v_end_point  = @v_geom.STPointN(@v_third);
           SET @v_third      = @v_third  + 1;
           -- Call FindCircle
           SET @v_circle = [$(cogoowner)].[STFindCircleByPoint](@v_srt_point,@v_mid_point,@v_end_point);
           SET @v_cx     = @v_circle.STX;
           SET @v_cy     = @v_circle.STY;
           SET @v_radius = @v_circle.Z;
           IF ( @v_radius IS NOT NULL AND @v_radius <> -1 AND @v_radius < @p_min_radius ) BEGIN
              SET @v_badRadii = @v_badRadii + 1;
              IF ( @v_WKT <> 'MULTILINESTRING(' ) BEGIN
                 SET @v_WKT = @v_WKT + ',';
              END;
             SET @v_WKT = @v_WKT + 
                             REPLACE([$(owner)].[STMakeCircularLine] (@v_srt_point,@v_mid_point,@v_end_point,
                                                                 @v_round_xy,NULL,NULL).STAsText(),
                                    'CIRCULARSTRING','');
           END;
        END;
      END; 
      SET @v_WKT = @v_WKT + ')' ;
      IF ( @v_badRadii = 0 ) BEGIN
         Return NULL;
      END ELSE BEGIN
         Return geometry::STGeomFromText(@v_WKT,@v_srid);
      END;
    END;
    Return NULL;
  End;
End
GO

SELECT [$(owner)].[STCheckRadii](geometry::STGeomFromText('LINESTRING(0.0 0.0,10.0 0.0,10.0 10.0)',0),10.0,3).STAsText() as failingPoints;

SELECT [$(owner)].[STCheckRadii](geometry::STGeomFromText('MULTILINESTRING((0.0 0.0,10.0 0.0,10.0 10.0),(20.0 0.0,30.0 0.0,30.0 10.0,35 15))',0), 15.0,3).STAsText()  as failingPoints; 

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING(0.0 0.0,10.0 10.0,20.0 0.0)',0) as circulararc
)
select gs.IntValue as requiredMinRadius,
       [$(cogoowner)].[STFindCircleFromArc](circularArc).Z as ArcRadius,
       [$(owner)].[STCheckRadii](
                circulararc,
                gs.IntValue,
                3).STAsText() as failingArc
  from data as a
       cross apply
       [$(owner)].[generate_series](5,15,5) as gs;

