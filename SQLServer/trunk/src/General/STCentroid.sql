USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STCentroid_P]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STCentroid_P];
  Print 'Dropped [$(owner)].[STCentroid_P] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STCentroid_L]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STCentroid_L];
  PRINT 'Dropped [$(owner)].[STCentroid_L] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STCentroid_A]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STCentroid_A];
  PRINT 'Dropped [$(owner)].[STCentroid_A] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STCentroid]') 
      AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STCentroid];
  PRINT 'Dropped [$(owner)].[STCentroid] ...';
END;
GO

-- Deprecated function....
IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id(N'[$(owner)].[STMultiCentroid]') 
              AND xtype IN (N'FN', N'IF', N'TF'))
BEGIN
  DROP FUNCTION [$(owner)].[STMultiCentroid];
  PRINT 'Dropped [$(owner)].[STMultiCentroid] ...';
END;
GO

PRINT 'Creating [$(owner)].[STCentroid_P] ...';
GO

CREATE FUNCTION [$(owner)].[STCentroid_P] 
(
  @p_geometry geometry,
  @p_round_xy int   = 3,
  @p_round_zm int   = 2
)
Returns geometry 
AS
/****f* GEOPROCESSING/STCentroid_P (2008)
 *  NAME
 *    STCentroid_P - Generates centroid for a point (itself) or multipoint.
 *  SYNOPSIS
 *    Function STCentroid_P (
 *       @p_geometry geometry,
 *       @p_round_xy int = 3,
 *       @p_round_zm int = 2
 *    )
 *     Returns geometry
 *  DESCRIPTION
 *    This function creates centroid of multipoint via averaging of ordinates.
 *  INPUTS
 *    @p_geometry (geometry) - Point or Multipoint geometry object.
 *    @p_round_xy (int)      - Ordinate rounding precision for XY ordinates.
 *    @p_round_zm (int)      - Ordinate rounding precision for ZM ordinates.
 *  RETURN
 *    centroid (geometry) - The centroid.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - July 2008 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  DECLARE
    @v_gtype      varchar(100),
    @v_wkt        varchar(max),
    @v_dimensions varchar(4), 
    @v_round_xy   int = ISNULL(@p_round_xy,3),
    @v_round_zm   int = ISNULL(@p_round_zm,2),
    @v_x          Float = 0.0,
    @v_y          Float = 0.0,
    @v_z          Float = 0.0,
    @v_m          Float = 0.0,
    @v_geomn      int,
    @v_part_geom  geometry,
    @v_geometry   geometry;
  BEGIN
      If ( @p_geometry is null )
       Return @p_geometry;

      SET @v_gtype = @p_geometry.STGeometryType();

      IF ( @v_gtype = 'Point' ) 
        RETURN @p_geometry;

      IF ( @v_gtype = 'MultiPoint' ) 
      BEGIN
        -- Set flag for STPointFromText
        -- @p_dimensions => XY, XYZ, XYM, XYZM or NULL (XY) 
        SET @v_dimensions = 'XY' 
                       + case when @p_geometry.HasZ=1 then 'Z' else '' end 
                       + case when @p_geometry.HasM=1 then 'M' else '' end;

        -- Get parts of multi-point geometry
        --
        SET @v_geomn   = 1;
        WHILE ( @v_geomn <= @p_geometry.STNumGeometries() )
        BEGIN
          SET @v_part_geom = @p_geometry.STGeometryN(@v_geomn);
          SET @v_x     = @v_x + @v_part_geom.STX;
          SET @v_y     = @v_y + @v_part_geom.STY;
          IF ( @v_part_geom.HasZ = 1 ) 
            SET @v_z   = @v_z + @v_part_geom.Z;
          IF ( @v_part_geom.HasM = 1 ) 
            SET @v_m   = @v_m + @v_part_geom.M;
          SET @v_geomn = @v_geomn + 1;
        END; 
        SET @v_wkt = 'POINT('
                     +
                     [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ (@v_x/@p_geometry.STNumGeometries()),
                            /* @p_Y          */ (@v_y/@p_geometry.STNumGeometries()),
                            /* @p_Z          */ (@v_z/@p_geometry.STNumGeometries()),
                            /* @p_M          */ (@v_m/@p_geometry.STNumGeometries()),
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                     )
                     + 
                    ')';
        SET @v_geometry = geometry::STPointFromText(@v_wkt,@p_geometry.STSrid);
        RETURN @v_geometry;
      END;
      RETURN NULL;
    END;
END
GO

PRINT 'Creating [$(owner)].[STCentroid_L] ...';
GO

CREATE FUNCTION [$(owner)].[STCentroid_L] 
(
  @p_geometry            geometry,
  @p_multiLineStringMode int   = 2,    /* 0 = all, 1 = First, 2 = largest, 3 = smallest */
  @p_position_as_ratio   Float = 0.5,
  @p_round_xy            int   = 3,
  @p_round_zm            int   = 2
)
returns geometry 
AS
/****f* GEOPROCESSING/STCentroid_L (2008)
 *  NAME
 *    STCentroid_L - Generates centroid for a Linestring or multiLinestring geometry object.
 *  SYNOPSIS
 *    Function STCentroid_L (
 *       @p_geometry            geometry,
 *       @p_multiLineStringMode int   = 2,    
 *       @p_position_as_ratio   Float = 0.5,
 *       @p_round_xy            int = 3,
 *       @p_round_zm            int = 2
 *    )
 *     Returns geometry
 *  DESCRIPTION
 *    This function creates a centroid for a Linestring or MultiLineString geometry object.
 *    IF @p_geometry is MultiLineString four modes are available that control the creation of the centroid(s).
 *      0 = All      (A multiPoint object is created one for each part)
 *      1 = First    (First linestring @p_geometry.STGeometryN(1) is used).
 *      2 = largest  (Longest linestring part of MultiLineString is used).
 *      3 = smallest (Shortest linestring part of MultiLineString is used).
 *    The position of the centroid for a single linestring is computed at exactly 1/2 way along its length (0.5).
 *    The position can be varied by supplying a @p_position_as_ratio value other than 0.5.
 *  INPUTS
 *    @p_geometry       (geometry) - LineString or MultiLineString geometry object.
 *    @p_multiLineStringMode (int) - Mode controlling centroid(s) generation when @p_geometry is MultiLineString/GeometryCollection.
 *    @p_position_as_ratio (float) - Position along linestring where centroid location is computed.
 *    @p_round_xy            (int) - Ordinate rounding precision for XY ordinates.
 *    @p_round_zm            (int) - Ordinate rounding precision for ZM ordinates.
 *  RETURN
 *    centroid(s)       (geometry) - One or more centroid depending on input.
 *  TOBEDONE
 *    Support for MultiLineStrings within GeometryCollections.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - July 2008   - Original coding.
 *    Simon Greener - August 2018 - Support for GeometryCollection
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/

begin
  DECLARE
    @v_gtype               varchar(100),
    @v_round_xy            int = ISNULL(@p_round_xy,3),
    @v_round_zm            int = ISNULL(@p_round_zm,2),
    @v_isGeography         bit,
    /* LineString variables */
    @v_total_length        Float,
    @v_ratio_as_length     Float,
    @v_segment_length      Float,
    @v_cumulative_length   Float,
    @v_bearing_from_start  Float,
    @v_distance_from_start Float,
    @vector                int,
    @first                 int,
    @second                int,
    @v_centroid            geometry,
    @v_start_point         geometry,
    @v_end_point           geometry,
    /* MultiLineString variables */
    @v_geomn               int,
    @v_length              Float,
    @v_test_length         Float = 0.0,
    @v_part_centroid       geometry,
    @v_part_geom           geometry,
    @v_temp_geom           geometry,
    @v_geometry            geometry; /* Local p_geometry */
  BEGIN
    If ( @p_geometry is null )
      Return @v_geometry.STGeometryType();

    SET @v_gtype = @p_geometry.STGeometryType();

    If ( @p_multiLineStringMode is null 
      or @p_multiLineStringMode not in (0,1,2,3) ) 
      Return @p_geometry.STCentroid();

    SET @v_gtype       = @p_geometry.STGeometryType();
    SET @v_isGeography = [$(owner)].[STIsGeographicSrid](@p_geometry.STSrid);
	SET @v_geometry    = @p_geometry;

	-- Convert GeometryCollection to appropriate linestring
    IF ( @v_gtype = 'GeometryCollection' ) 
    BEGIN
      SET @v_geometry = [$(owner)].[STConvertToLineString]( @p_geometry );
	  IF ( @v_geometry.STNumPoints() = 0 ) -- LINESTRING EMPTY
	    Return geometry::STGeomFromText('POINT EMPTY',@p_geometry.STSrid); 
	  SET @v_gtype    = @v_geometry.STGeometryType();
    END;

    IF ( @v_gtype = 'LineString' )  
    BEGIN
      SET @first  = 1;
      SET @second = 2;
      SET @v_cumulative_length = 0;
      SET @v_total_length      = case when @v_isGeography=1
                                      then geography::STGeomFromText(@p_geometry.AsTextZM(),@p_geometry.STSrid).STLength()
                                      else @p_geometry.STLength()
                                  end;
      SET @v_ratio_as_length   = @p_position_as_ratio * @v_total_length;
      WHILE ( @second <= @p_geometry.STNumPoints() )
      BEGIN
        SET @v_start_point    = @p_geometry.STPointN(@first);
        SET @v_end_point      = @p_geometry.STPointN(@second);
        SET @v_segment_length = @v_start_point.STDistance(@v_end_point);
        -- Does this segment contain the required point?
        IF ( @v_ratio_as_length <= ( @v_cumulative_length + 
                                     @v_segment_length )  )
        BEGIN
          -- This segment has our centroid
          SET @v_distance_from_start = ( @v_ratio_as_length - @v_cumulative_length )
          SET @v_bearing_from_start  = [$(cogoowner)].[STBearingBetweenPoints] (
                                         @v_start_point,
                                         @v_end_point
                                       );
          SET @v_centroid = [$(cogoowner)].[STPointFromCOGO] (
                              @v_start_point,
                              @v_bearing_from_start,
                              @v_distance_from_start,
                              @v_round_xy
                            );
          RETURN @v_centroid;
        END;
        SET @v_cumulative_length = @v_cumulative_length + @v_segment_length;
        SET @first  = @first  + 1;
        SET @second = @second + 1;
      END;  
    END

    IF ( @v_gtype IN ('MultiLineString') )
    BEGIN
      -- Set test length values depending on mode
      --
      IF ( @p_multiLineStringMode = 2 ) /* 2 = largest */
        SET @v_test_length = -9999999999.9999999;
      IF ( @p_multiLineStringMode = 3 ) /* 3 = smallest */
        SET @v_test_length = 9999999999.9999999;

      -- Get parts of multi-part linestring
      --
      SET @v_part_geom = null;
      SET @v_centroid  = null;
      SET @v_geomn     = 1;
      WHILE ( @v_geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        SET @v_part_geom = @p_geometry.STGeometryN(@v_geomn);
        SET @v_geomn     = @v_geomn + 1;
        /* Process all parts */
        IF ( @p_multiLineStringMode = 0 )  /* 0 = all */
        BEGIN
          SET @v_part_centroid = [$(owner)].[STCentroid_L] (
                                      @v_part_geom,
                                      0,
                                      @p_position_as_ratio,
                                      @v_round_xy,
                                      @v_round_zm
                                   );
          SET @v_centroid = CASE WHEN @v_centroid is null 
                                 THEN @v_part_centroid 
                                 ELSE @v_centroid.STUnion(@v_part_centroid) 
                             END;
          CONTINUE;
        END;

        /* Stop if first part */
        IF ( @p_multiLineStringMode = 1 )  /* 1 = first part */
        BEGIN
          SET @v_centroid = [$(owner)].[STCentroid_L] ( 
                               @v_part_geom,
                               @p_multiLineStringMode,
                               @p_position_as_ratio,
                               @v_round_xy,
                               @v_round_zm
                            );
          BREAK;
        END;
		/* Get Test length metric and centroid for current part 
           Check if we should save this part
        */
        SET @v_length = case when @v_isGeography=1
                             then geography::STGeomFromText(@v_part_geom.AsTextZM(),@v_part_geom.STSrid).STLength()
                             else @v_part_geom.STLength()
                         end;

        IF ( @p_multiLineStringMode = 2 and @v_length >= @v_test_length )     /* 2 = Largest */
        BEGIN
          SET @v_test_length = @v_length;
          SET @v_temp_geom   = @v_part_geom;
          CONTINUE;
        END;
        IF ( @p_multiLineStringMode = 3 AND @v_length <= @v_test_length ) /* 3 = Smallest */
        BEGIN
          SET @v_test_length = @v_length;
          SET @v_temp_geom   = @v_part_geom;
          CONTINUE;
        END;
      END; 
    END;
    IF (  @p_multiLineStringMode IN (2,3) 
      and @v_temp_geom is not null )
    BEGIN
      SET @v_centroid = [$(owner)].[STCentroid_L] (
                             @v_temp_geom,
                             @p_multiLineStringMode,
                             @p_position_as_ratio,
                             @v_round_xy,
                             @v_round_zm
                          );
    END;
    RETURN ISNULL(@v_centroid,geometry::STGeomFromText('POINT EMPTY',@p_geometry.STSrid));
  END;
  RETURN geometry::STGeomFromText('POINT EMPTY',@p_geometry.STSrid);
End
GO

PRINT 'Creating [$(owner)].[STCentroid_A] ...';
GO

CREATE FUNCTION [$(owner)].[STCentroid_A] 
(
  @p_geometry         geometry,
  @p_multiPolygonMode int   = 2,  /* 0 = all, 1 = First, 2 = largest, 3 = smallest */
  @p_area_x_start     int   = 0,  /* 0 = use average of all Area's vertices for starting X centroid calculation 
                                     1 = centre X of MBR 
                                     2 = User supplied starting seed X */
  @p_seed_x           Float = NULL,
  @p_round_xy         int   = 3,
  @p_round_zm         int   = 2
)
returns geometry 
as
/****f* GEOPROCESSING/STCentroid_A (2008)
 *  NAME
 *    STCentroid_A - Generates centroid for a polygon or multiPolygon geometry object.
 *  SYNOPSIS
 *    Function STCentroid_A (
 *       @p_geometry          geometry,
 *       @p_multiPolygonMode  int   = 2,    
 *       @p_area_x_start      int   = 0,
 *       @p_seed_x            Float = NULL,
 *       @p_round_xy          int   = 3,
 *       @p_round_zm          int   = 2
 *    )
 *     Returns geometry
 *  DESCRIPTION
 *    This function creates a centroid for a Polygon or MultiPolygon geometry object.
 *    The standard geometry.STCentroid() function does not guarantee that the centroid it generates falls inside a polygon.
  *   This function ensures that the centroid of any arbitrary polygon falls within the polygon.
 *    IF @p_geometry is MultiPolygon four modes are available that control the creation of the centroid(s).
 *      0 = All      (A multiPoint object is created one for each part)
 *      1 = First    (First Polygon @p_geometry.STGeometryN(1) is used).
 *      2 = largest  (Largest Polygon part of MultiPolygon is used).
 *      3 = smallest (Smallest Polygon part of MultiPolygon is used).
 *    The function works by computing a X ordinate for which a Y ordinate will be found that falls within the polygon.
 *    The X ordinate position can be controlled by the @p_area_x_start parameter as follows:
 *      0 = Average (Use average of X ordinates of Area's vertices for starting X centroid calculation).
 *      1 = MBR     (Compute and use the Centre X ordinate of the MBR of the geometry object).
 *      2 = User    (Use the user supplied starting @p_seed_X).
 *  INPUTS
 *    @p_geometry    (geometry) - Point or Multipoint geometry object.
 *    @p_multiPolygonMode (int) - Mode controlling centroid(s) generation when @p_geometry is MultiLineString.
 *    @p_area_x_start     (int) - How to determine the starting X ordinate.
 *    @p_seed_x         (Float) - If @p_area_x_start = 2 then user must supply a value.
 *    @p_round_xy         (int) - Ordinate rounding precision for XY ordinates.
 *    @p_round_zm         (int) - Ordinate rounding precision for ZM ordinates.
 *  RETURN
 *    centroid(s)    (geometry) - One or more centroid depending on input.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - July 2008 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_gtype         varchar(100),
    @v_round_xy      int = ISNULL(@p_round_xy,3),
    @v_round_zm      int = ISNULL(@p_round_zm,2),
    @v_cx            float,
    @v_cy            float,
    @v_seed          geometry,
     /* MultiPolygon variables */
    @v_geomn         int,
    @v_area          Float,
    @v_test_area     Float = 0.0,
    @v_part_centroid geometry,
    @v_centroid      geometry,
    @v_part_geom     geometry;
  BEGIN
    If ( @p_geometry is null )
       Return @p_geometry;
    If ( @p_multiPolygonMode is null 
      or @p_multiPolygonMode not in (0,1,2,3) ) 
      Return @p_geometry;
    IF ( @p_area_x_start NOT IN (0,1,2) )
       Return cast('Starting position must be 0, 1 or 2.' as varchar(max)); -- geometry);
    If ( @p_area_x_start = 2 AND @p_seed_x IS NULL )
       Return cast('Seed X value not provided.' as varchar(max)); -- geometry);

    SET @v_gtype = @p_geometry.STGeometryType();

    IF ( @v_gtype = 'Polygon' ) 
    BEGIN
      -- Create starting seed point geometry
      --
      SET @v_seed = CASE @p_area_x_start 
                         WHEN 0 THEN @p_geometry
                         WHEN 1 THEN geometry::Point(@p_geometry.STEnvelope().STPointN(1).STX,
                                                     @p_geometry.STEnvelope().STPointN(1).STY,
                                                     @p_geometry.STSrid).STUnion(
                                     geometry::Point(@p_geometry.STEnvelope().STPointN(3).STX,
                                                     @p_geometry.STEnvelope().STPointN(3).STY,
                                                     @p_geometry.STSrid))
                         WHEN 2 THEN geometry::Point(@p_seed_x,0,@p_geometry.STSrid)
                         ELSE @p_geometry
                    END;
  
      -- Check user seed X between MBR of object
      --
      IF ( @p_area_x_start = 2 AND 
         ( @p_seed_x <= @p_geometry.STEnvelope().STPointN(1).STX OR @p_seed_x >= @p_geometry.STEnvelope().STPointN(3).STX ) )
         Return cast('Seed X value not between provided geometry''s MBR.' as varchar(max)); -- geometry);
  
      SELECT TOP 1 
             @v_cx = cx, 
             @v_cy = cy
        FROM (SELECT z.x                 as cx,
                     z.y + ( ydiff / 2 ) as cy,
                     ydiff
                FROM (SELECT w.id,
                             w.x,
                             w.y,
                             case when w.ydiff is null then 0 else w.ydiff end as ydiff,
                             case when w.id = 1
                                  then case when w.inout = 1
                                            then 'INSIDE'
                                            else 'OUTSIDE'
                                        end
                                  when SUM(w.inout) OVER (ORDER BY w.id) % 2 = 1
                                  /* Need to look at previous result as inside/outside is a binary switch */
                                  then 'INSIDE'
                                  else 'OUTSIDE'
                              end as inout
                        FROM (SELECT row_number() over (order by u.y asc) as id,
                                     u.x,
                                     u.y,
                                     case when u.touchCross in (0)         /* Cross */ then 1
                                          when u.touchCross in (-1,-2,1,2) /* Touch */ then 0
                                          else 0
                                      end as inout,
                                     ABS(LEAD(u.y,1) OVER(ORDER BY u.y) - u.y) As YDiff
                                FROM (SELECT s.x,
                                             s.y,
                                             /* In cases where polygons have boundaries/holes that touch at a point we need to count them more than once */
                                             case when count(*) > 2 then 1 else sum(s.touchcross) end as touchcross
                                        FROM (SELECT t.x,
                                                     t.y,
                                                     t.touchcross
                                                FROM (SELECT r.x,
                                                             case when (r.endx = r.startx)
                                                                  then (r.starty + r.endy ) / 2
                                                                  else round(r.starty + ( (r.endy-r.starty)/(r.endx-r.startx) ) * (r.x-r.startx),@v_round_xy)
                                                              end as y,
                                                             case when ( r.x = r.startx and r.x = r.endx )
                                                                  then 99  /* Line is Vertical */
                                                                  when ( ( r.x = r.startx and r.x > r.endx )
                                                                      or ( r.x = r.endX   and r.x > r.startX ) )
                                                                  then -1 /* Left Touch */
                                                                  when ( ( r.x = r.endX   and r.x < r.startX  )
                                                                      or ( r.x = r.startX and r.x < r.endX ) )
                                                                  then 1 /* Right Touch */
                                                                  else 0 /* cross */
                                                              end as TouchCross
                                                         FROM (SELECT c.x,
                                                                      round(v.sx,@v_round_xy) as startX,
                                                                      round(v.sy,@v_round_xy) as startY,
                                                                      round(v.ex,@v_round_xy) as endX,
                                                                      round(v.ey,@v_round_xy) as endY
                                                                 FROM (SELECT round(avg(p.x),@v_round_xy) as x
                                                                         FROM [$(owner)].[STDumpPoints](@v_seed) p 
                                                                      ) c
                                                                      cross apply
                                                                      [$(owner)].[STVectorize](@p_geometry) v
                                                              ) r
                                                        WHERE r.x BETWEEN r.StartX AND r.endx
                                                           OR r.x BETWEEN r.endx   AND r.startx 
                                                     ) t
                                             ) s
                                       GROUP BY s.x,s.y
                                     ) u
                             ) w
                     ) z
               WHERE z.inout = 'INSIDE'
             ) f
          ORDER BY f.ydiff DESC;
      RETURN geometry::Point(@v_cx, @v_cy, @p_geometry.STSrid);  
    END;

    IF ( @v_gtype = 'MultiPolygon' ) 
      BEGIN
          -- Set test length values depending on mode
        --
        IF ( @p_multiPolygonMode = 2 ) /* 2 = largest */
           SET @v_test_area = -9999999999.9999999;
        IF ( @p_multiPolygonMode = 3 ) /* 3 = smallest */
           SET @v_test_area =  9999999999.9999999;

        -- Get parts of multi-part geometry
        --
        SET @v_part_geom = null;
        SET @v_centroid  = null;
        SET @v_geomn     = 1;
        WHILE ( @v_geomn <= @p_geometry.STNumGeometries() )
        BEGIN
          SET @v_part_geom = @p_geometry.STGeometryN(@v_geomn);
          SET @v_geomn     = @v_geomn + 1;

          /* Process all parts */
          IF ( @p_multiPolygonMode = 0 )  /* 0 = all */
          BEGIN
            SET @v_part_centroid = [$(owner)].[STCentroid_A] (
                                      @v_part_geom,
                                      @p_multiPolygonMode,
                                      @p_area_x_start,
                                      @p_seed_x,
                                      @v_round_xy,
                                      @v_round_zm
                                   );
            SET @v_centroid = CASE WHEN @v_centroid is null 
                                   THEN @v_part_centroid 
                                   ELSE @v_centroid.STUnion(@v_part_centroid) 
                               END;
            CONTINUE;
          END;

          /* Get Test length metric and centroid for current part */
          SET @v_area          = @v_part_geom.STArea();
          SET @v_part_centroid = [$(owner)].[STCentroid_A] ( 
                                    @v_part_geom,
                                    @p_multiPolygonMode,
                                    @p_area_x_start,
                                    @p_seed_x,
                                    @v_round_xy,
                                    @v_round_zm
                                 );

          /* Stop if first part */
          IF ( @p_multiPolygonMode = 1 )  /* 1 = first part */
          BEGIN
            SET @v_centroid  = @v_part_centroid;
            BREAK;
          END;

          -- Check if we should save this centroid
          /* 2 = Largest */
          IF ( @p_multiPolygonMode = 2 and @v_area >= @v_test_area )
          BEGIN
            SET @v_test_area = @v_area;
            SET @v_centroid  = @v_part_centroid;
            CONTINUE;
          END;

          /* 3 = Smallest */
          IF ( @p_multiPolygonMode = 3 AND @v_area <= @v_test_area )
          BEGIN
            SET @v_test_area = @v_area;
            SET @v_centroid  = @v_part_centroid;
            CONTINUE;
          END;
        END; 
        RETURN @v_centroid;
      END;
    RETURN NULL;
  END;
End
GO

PRINT 'Creating [$(owner)].[STCentroid] ...';
GO

-- Wrapper over above....
--
-- TODO Handle GeometryCollection...
--
CREATE FUNCTION [$(owner)].[STCentroid] 
(
  @p_geometry             geometry,
  @p_multi_mode           int   = 2,   /* 0 = all, 1 = First, 2 = largest, 3 = smallest */
  @p_area_x_start         int   = 0,   /* 0 = use average of all Area's vertices for starting X centroid calculation 
                                          1 = centre X of MBR 
                                          2 = User supplied starting seed X */  
  @p_area_x_ordinate_seed float = 0,   /* When @p_area_x_start this provides actual X ordinate value */
  @p_line_position_ratio  float = 0.5, /* Only for linestrings */
  @p_round_xy             int   = 3,
  @p_round_zm             int   = 2
)
returns geometry 
as
/****f* GEOPROCESSING/STCentroid
 *  NAME
 *    STCentroid -- Wrapper that creates centroid geometry for any multipoint, (multi)line or (multi)Polygon object. 
 *  SYNOPSIS
 *    Function ST_Centroid (
 *       @p_geometry             geometry,
 *       @p_multi_Mode           int   = 2,    
 *       @p_area_x_start         int   = 0,
 *       @p_area_x_ordinate_seed Float = 0,
 *       @p_line_position_ratio  Float = 0.5,
 *       @p_round_xy             int   = 3,
 *       @p_round_zm             int   = 2
 *    )
 *   Returns geometry
 *  DESCRIPTION
 *    This function creates a single centroid by calling the Centroid_P, Centroid_L or Centroid_A functions
 *    according to @p_geometry.STGeometryType().
 *  INPUTS
 *    @p_geometry          (geometry) - Geometry object.
 *    @p_multi_mode             (int) - Maps to STCentroid_L/@p_multiLineStringMode or STCentroid_P/@p_multiPolygonMode.
 *    @p_area_x_start           (int) - Maps to STCentroid_A/@p_area_x_start.
 *    @p_area_x_ordinate_seed (Float) - Maps to STCentroid_A/@p_seed_x.
 *    @p_line_position_ratio  (Float) - Maps to STCentroid_L/@p_position_as_ratio.
 *    @p_round_xy               (int) - Ordinate rounding precision for XY ordinates.
 *    @p_round_zm               (int) - Ordinate rounding precision for ZM ordinates.
 *  RESULT
 *    centroid(s) (geometry) - Centroid of input object.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan 2013 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_gtype      varchar(100),
    @v_round_xy   int = ISNULL(@p_round_xy,3),
    @v_round_zm   int = ISNULL(@p_round_zm,2),
    @v_multi_mode int = ISNULL(@p_multi_mode,1),
    @v_geomn      int,
    @v_centroid   geometry,
    @v_part_geom  geometry,
    @v_geometry   geometry;
  BEGIN
    If ( @p_geometry is null )
      Return @p_geometry;

    If ( @v_multi_mode is not null 
     and @v_multi_mode not in (0,1,2,3) ) 
      Return @p_geometry;

    SET @v_gtype = @p_geometry.STGeometryType();

    -- Now get centroid by calling relelvant function
    --
    IF ( @v_gtype = 'Point' )
      RETURN @p_geometry;
    IF ( @v_gtype = 'MultiPoint' ) 
      RETURN [$(owner)].[STCentroid_P] ( 
                @p_geometry,
                @v_round_xy,
                @v_round_zm 
             );
    IF ( @v_gtype IN ('LineString','MultiLineString') ) 
      RETURN [$(owner)].[STCentroid_L] (
                @p_geometry,
                @p_multi_mode,
                @p_line_position_ratio,
                @v_round_xy,
                @v_round_zm
             );
    IF ( @v_gtype IN ('Polygon','MultiPolygon') )
      RETURN [$(owner)].[STCentroid_A] ( 
                @p_geometry,
                @p_multi_mode,
                @p_area_x_start,
                @p_area_x_ordinate_seed,
                @v_round_xy,
                @v_round_zm
             );
    IF ( @v_gtype = 'GeometryCollection') 
    BEGIN
      -- Break apart and call function with parts ...
      SET @v_geomn  = 1;
      WHILE ( @v_geomn <= @p_geometry.STNumGeometries() )
      BEGIN
        SET @v_part_geom = @p_geometry.STGeometryN(@v_geomn);
        -- Get Centroid of part
        SET @v_geometry = [$(owner)].[STCentroid] (
                             @v_part_geom,
                             @p_multi_mode,
                             @p_area_x_start,
                             @p_area_x_ordinate_seed,
                             @p_line_position_ratio,
                             @v_round_xy,
                             @v_round_zm
                          );
        IF ( @p_multi_mode = 1 /* 1 = First */ )
          RETURN @v_geometry;
        SET @v_centroid = case when @v_centroid is null 
                               then @v_geometry 
                               else @v_centroid.STUnion(@v_geometry) 
                           end;
        SET @v_geomn = @v_geomn + 1;
      END; 
      RETURN @v_centroid;
    END;
    RETURN NULL;
  END;
end
go

PRINT 'Testing Centroid Functions...';
GO

-- SQL Server's STCentroid is NULL for MultiPoint
--
with multiPoint as (
  select CAST('XY MultiPoint'   as varchar(15)) as geomText, geometry::STGeomFromText('MULTIPOINT((0 0),(100 0),(100 100),(0 100),(150 110),(150 150),(110 150),(110 110))',0) as geom
  UNION ALL
  select CAST('XYZ MultiPoint'  as varchar(15)) as geomText, geometry::STGeomFromText('MULTIPOINT((0 0 0),(100 0 1),(100 100 2),(0 100 3),(150 110 4),(150 150 5),(110 150 6),(110 110 7))',0) as geom
  UNION ALL
  select CAST('XYZM MultiPoint' as varchar(15)) as geomText, geometry::STGeomFromText('MULTIPOINT((0 0 0 10),(100 0 1 12),(100 100 2 13),(0 100 3 14),(150 110 4 15),(150 150 5 16),(110 150 6 17),(110 110 7 18))',0) as geom
)
select geomText, action, geom
  from (
    select geomText, CAST('Original' as varchar(15)) as action, geom.AsTextZM() as geom from multiPoint as a
    union all
    select geomText, 'SQL .STCentroid()' as action, geom.STCentroid().AsTextZM() as geom from multiPoint
    union all
    select geomText, 'STCentroid_P'      as action, [$(owner)].[STCentroid_P](geom,3,2).AsTextZM() as geom from multiPoint
) as f
order by 1,2;
GO

-- STCentroid_A
--
with poly as (
   select geometry::STGeomFromText('POLYGON((2300 -700, 2800 -300, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400, 2300 200, 2100 100, 2500 100, 2300 -200, 1800 -300, 2300 -500, 2200 -400, 2400 -400, 2300 -700), (2300 1000, 2400  900, 2200 900, 2300 1000))',0) as geom
)
select 'O' as Label, geom.AsTextZM() from poly
union all
select 'A' as Label, $(owner).[STCentroid_A](geom,0,0,NULL,3,2).STAsText() as geom from poly
union all
select 'M' as Label, $(owner).[STCentroid_A](geom,0,1,NULL,3,2).STAsText() as geom from poly
union all
select 'U' as Label, $(owner).[STCentroid_A](geom,0,2,2050,3,2).STAsText() as geom from poly
union all
select 'S' as Label, geom.STCentroid().STAsText() as geom  from poly
GO

With weightedPoly As (
   select geometry::STGeomFromText('POLYGON((258.72254365233152 770.97400259630615, 268.79365642517564 739.08214548229967, 278.86476919801976 707.1902883682933, 332.57737065318844 693.76213800450114, 366.14774656266889 676.97695004976094, 426.57442319973364 697.11917559544918, 520.57147574627891 737.40362668682576, 631.35371624756431 744.11770186872184, 829.41893411349884 797.83030332389046, 1547.8249785763801 791.11622814199438, 1205.4071442996797 895.18439346138371, 832.77597170444687 1039.5370098721496, 490.3581374277465 1086.5355361454222, 416.50331042688953 1076.464423372578, 381.25441572193506 1059.6792354178378, 346.00552101698065 1042.8940474630976, 320.82773908487036 1019.3947843264614, 295.64995715276001 995.89552118982499, 287.25736317538986 964.00366407581862, 278.86476919801976 932.11180696181225, 282.2218067889678 891.82735587043567, 277.18625040254574 858.25697996095528, 272.15069401612368 824.68660405147489, 258.72254365233152 770.97400259630615))',0) as geom
)
SELECT 'O' as Label,  geom.AsTextZM() from weightedPoly
union all 
SELECT 'A' as Label, $(owner).[STCentroid_A](geom,0,0,NULL,2,2).STAsText() as geom from weightedPoly
union all 
SELECT 'M' as Label, $(owner).[STCentroid_A](geom,0,1,NULL,2,2).STAsText() as geom from weightedPoly
union all 
SELECT 'U' as Label, $(owner).[STCentroid_A](geom,0,2,1200,2,2).STAsText() as geom from weightedPoly
union all
select 'S' as Label, geom.STCentroid().STAsText() as geom from weightedPoly
GO

-- Multiline options....

with mPoly as (
  select geometry::STGeomFromText('MULTIPOLYGON (((0 0, 100 0, 100 100, 0 100, 0 0)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0) as geom
)
select case when t.IntValue = 0 then 'All' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'Largest' 
            when t.IntValue = 3 then 'Smallest' 
            else '' 
        end as mode,
       [$(owner)].[STCentroid_A]( geom, t.IntValue, 1 /* Weight By MBR not Vertices */, NULL, 3,2).STAsText() as geom --.STBuffer(t.IntValue*2 + 1) as geom 
  from mPoly as a
       cross apply
       $(owner).GENERATE_SERIES(0,3,1) as t
union all
select 'LINESTRING', 
       geom 
  from mPoly;
GO

-- STCentroid_L.......

-- Different distances along the linestring ....

With line As (
  SELECT geometry::STGeomFromText('LINESTRING(258.72254365233152 770.97400259630615, 268.79365642517564 739.08214548229967, 278.86476919801976 707.1902883682933, 332.57737065318844 693.76213800450114, 366.14774656266889 676.97695004976094, 426.57442319973364 697.11917559544918, 520.57147574627891 737.40362668682576, 631.35371624756431 744.11770186872184, 829.41893411349884 797.83030332389046, 1547.8249785763801 791.11622814199438, 1205.4071442996797 895.18439346138371, 832.77597170444687 1039.5370098721496, 490.3581374277465 1086.5355361454222, 416.50331042688953 1076.464423372578, 381.25441572193506 1059.6792354178378, 346.00552101698065 1042.8940474630976, 320.82773908487036 1019.3947843264614, 295.64995715276001 995.89552118982499, 287.25736317538986 964.00366407581862, 278.86476919801976 932.11180696181225, 282.2218067889678 891.82735587043567, 277.18625040254574 858.25697996095528, 272.15069401612368 824.68660405147489, 258.72254365233152 770.97400259630615)',0) as geom
)
SELECT 'O' as label, geom.AsTextZM() from line
union all
SELECT CONCAT(STR(t.intValue),'%') as label, 
       [$(owner)].[STCentroid_L](a.geom,0,CAST(t.IntValue as float)/100.0,3,2).STAsText() as geom -- .STBuffer((t.IntValue/10)+5) as geom
  FROM line as a
       cross apply
       [$(owner)].[generate_series](0,90,10) as t
GO

-- Various multiline options

With mLine As (
  select CAST('MultiLine' as varchar(15)) as mode,
         geometry::STGeomFromText('MULTILINESTRING((0 0, 100 100),(200 200, 210 210),(500 500,750 750))',0) as geom
)
select mode,a.geom.AsTextZM() from mLine as a
union all
select case when t.IntValue = 0 then 'All' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'Largest' 
            when t.IntValue = 3 then 'Smallest' 
            else '' 
        end as mode,
       [$(owner)].[STCentroid_L](geom,t.IntValue,0.5,3,2).STAsText() as geom --.STBuffer(5+(t.IntValue*5)) as geom
  from mLine as a
       cross apply
       [$(owner)].[generate_series](0,2,1) as t

use Geokodning
go

With mLine As (
  select CAST('GeometryCollection' as varchar(15)) as mode,
         geometry::STGeomFromText(
'GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), LINESTRING(1 1,2 2),LINESTRING(3 3,19 19) )',0) as geom
--'GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), MULTILINESTRING((1 1,2 2),(3 3,19 19)) )',0) as geom
)
select mode,a.geom from mLine as a
union all
select case when t.IntValue = 0 then 'All' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'Largest' 
            when t.IntValue = 3 then 'Smallest' 
            else '' 
        end as mode,
       [$(owner)].[STCentroid_L](geom,t.IntValue,0.5,3,2).STBuffer(0.2) as geom
  from mLine as a
       cross apply
       [$(owner)].[generate_series](0,2,1) as t
go

-- *************************************

-- STCentroid wrapper tests...

select [$(owner)].[STCentroid] (
          /*@p_geometry             */ geometry::STGeomFromText('POINT(5 5)',0),
          /*@p_multi_mode           */ 0,
          /*@p_area_x_start         */ NULL,
          /*@p_area_x_ordinate_seed */ NULL,
          /*@p_line_position_ratio  */ NULL,
          /*@p_round_xy             */ 3,
          /*@p_round_zm             */ 2)
            .STAsText() as geom;

-- MultiPoint ....

with mPoint as (
  select geometry::STGeomFromText('MULTIPOINT((0 0),(100 0),(100 100),(0 100),(150 110),(150 150),(110 150),(110 110))',0) as geom
)
select CAST(geom.STAsText() as varchar(20)) as centroid
  from mPoint
union all
select [$(owner)].[STCentroid] (
          /*@p_geometry             */ geom,
          /*@p_multi_mode           */ 0,
          /*@p_area_x_start         */ NULL,
          /*@p_area_x_ordinate_seed */ NULL,
          /*@p_line_position_ratio  */ NULL,
          /*@p_round_xy             */ 3,
          /*@p_round_zm             */ 2)
          .STAsText() as centroid
  from mPoint
GO

-- MultiLineString...

with mLine as (
select CAST('MultiLine' as varchar(15)) as mode,
        geometry::STGeomFromText('MULTILINESTRING((0 0, 100 100),(200 200, 210 210),(500 500,750 750))',0) as geom
)
select mode, geom.AsTextZM() from mline as a
union all
select case when t.IntValue = 0 then 'all' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'largest' 
            when t.IntValue = 3 then 'smallest' 
            else '' 
        end as mode,
       [$(owner)].[STCentroid] (
          /*@p_geometry             */ geom,
          /*@p_multi_mode           */ t.IntValue,
          /*@p_area_x_start         */ NULL,
          /*@p_area_x_ordinate_seed */ NULL,
          /*@p_line_position_ratio  */ 0.5,
          /*@p_round_xy             */ 3,
          /*@p_round_zm             */ 2)
            .STAsText() as geom /*.STBuffer(t.IntValue*2 + 1) as geom */
  from mline as a
       cross apply
       [$(owner)].[GENERATE_SERIES](0,3,1) as t
GO

-- Polygon .....

with mPoly as (
  select CAST('MultiPolygon' as varchar(15)) as mode, 
         geometry::STGeomFromText('MULTIPOLYGON (((0 0, 100 0, 100 100, 0 100, 0 0)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0) as geom
)
select mode, geom.AsTextZM() from mPoly as m
union all
select case when t.IntValue = 0 then 'All' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'Largest' 
            when t.IntValue = 3 then 'Smallest' 
            else '' 
       end as mode,
       [$(owner)].[STCentroid] (
          /*@p_geometry             */ geom,
          /*@p_multi_mode           */ t.IntValue,
          /*@p_area_x_start         */ 1,
          /*@p_area_x_ordinate_seed */ NULL,
          /*@p_line_position_ratio  */ NULL,
          /*@p_round_xy             */ 3,
          /*@p_round_zm             */ 2)
            .STAsText() as geom /*.STBuffer(t.IntValue*2 + 1) as geom */
  from mPoly as a
       cross apply
       [$(owner)].[GENERATE_SERIES](0,3,1) as t
GO

QUIT
GO

