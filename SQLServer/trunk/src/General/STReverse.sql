SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT *
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STReverse]') 
              AND OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
Begin
  DROP FUNCTION [$(owner)].[STReverse];
  Print 'Dropped [$(owner)].[STReverse]';
End
GO

Print 'Creating [$(owner)].[STReverse] ....'
GO

CREATE FUNCTION [$(owner)].[STReverse]
(
  @p_geometry geometry,
  @p_round_xy int = 3,
  @p_round_zm int = 2
)
Returns geometry
As
/****f* EDITOR/STReverse (2012)
 *  NAME
 *    STReverse -- Function which reverses the vertices of a linestring and parts/vertices of multilinestring.
 *  SYNOPSIS
 *    Function STReverse (
 *               @p_geometry geometry,
 *               @p_round_xy int = 3,
 *               @p_round_zm int = 2
 *             )
 *     Returns geometry 
 *  SYNOPSIS
 *    select id, action, geom 
 *      from (select 'Before' as action, id, geom.STAsText() as geom
 *              from (select 1 as id, geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0) as geom
 *                    union all
 *                    select 2 as id, geometry::STGeomFromText('MULTILINESTRING((1 1,2 2), (3 3, 4 4))',0) as geom
 *                    union all
 *                    select 3 as id, geometry::STGeomFromText('MULTIPOINT((1 1),(2 2),(3 3),(4 4))',0) as geom
 *                    ) as data
 *           union all
 *           select 'After' as action, id, STReverse(geom).STAsText() as geom
 *             from (select 1 as id, geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0) as geom
 *                   union all
 *                   select 2 as id, geometry::STGeomFromText('MULTILINESTRING((1 1,2 2), (3 3, 4 4))',0) as geom
 *                   union all
 *                   select 3 as id, geometry::STGeomFromText('MULTIPOINT((1 1),(2 2),(3 3),(4 4))',0) as geom
 *                  ) as data
 *           ) as f
 *    order by id, action desc;
 *
 *    id action geom
 *  ---- ------ --------------------------------------
 *     1 Before LINESTRING(0 0,10 0)
 *     1 After  LINESTRING(10 0,0 0)
 *     2 Before MULTILINESTRING((1 1,2 2),(3 3,4 4))
 *     2 After  MULTILINESTRING((4 4,3 3),(2 2,1 1))
 *     3 Before MULTIPOINT((1 1),(2 2),(3 3),(4 4))
 *     3 After  MULTIPOINT((4 4),(3 3),(2 2),(1 1))
 * 
 *  DESCRIPTION
 *    Function that reverses the coordinates of the following:
 *      1. MultiPoint 
 *      2. LineString
 *      3. CircularString (2012)
 *      4. CompoundCurve  (2012)
 *      5. MultiLineString 
 *    If the geometry is a MultiLineString, the parts, and then their vertices are reversed.
 *  INPUTS
 *    @p_geometry   (geometry) - Supplied geometry of supported type.
 *    @p_round_xy   (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm   (int)      - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    reversed geom (geometry) - Input geometry with parts and vertices reversed.
 *  NOTES
 *    Function STGeomFromText if reversal processing invalidates the geometry.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_geometryType     varchar(100),
    @v_wkt              varchar(max),
    @v_dimensions       varchar(4),
    @v_round_xy         int,
    @v_round_zm         int,
    /* MultiPoint */
    @v_geomn            int,
    @v_point            geometry,
    /* STSegmentLine Variables*/
    @v_id               int,
    @v_max_id           int, /* The last will be first and the first last */
    @v_multi_tag        varchar(100),
    @v_element_id       int,
    @v_prev_element_id  int,
    @v_element_tag      varchar(100),
    @v_prev_element_tag varchar(100),
    @v_subelement_id    int,
    @v_subelement_tag   varchar(100),
    @v_segment_id       int, 
    @v_sx               float,  /* Start Point */
    @v_sy               float,
    @v_sz               float,
    @v_sm               float,
    @v_mx               float,  /* Mid Point */
    @v_my               float,
    @v_mz               float,
    @v_mm               float,
    @v_ex               float,  /* End Point */
    @v_ey               float,
    @v_ez               float,
    @v_em               float,
    @v_length           float,
    @v_startLength      float,
    @v_measureRange     float,
    @v_segment_geom     geometry;
  Begin
    If ( @p_geometry is null ) 
      Return @p_geometry;

    -- Only process linear geometries.
    SET @v_GeometryType = @p_geometry.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','CircularString','CompoundCurve','MultiLineString','MultiPoint') )
      Return @p_geometry;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    SET @v_dimensions        = 'XY' + 
                                case when @p_geometry.HasZ=1 then 'Z' else '' end 
                                + 
                                case when @p_geometry.HasM=1 then 'M' else '' end;

    IF (@v_geometryType = 'MultiPoint' )
    BEGIN
      SET @v_geomn = @p_geometry.STNumGeometries();
      SET @v_wkt   = 'MULTIPOINT (';
      WHILE ( @v_geomn > 0 ) 
      BEGIN
        SET @v_point = @p_geometry.STGeometryN(@v_geomn);
        SET @v_wkt   = @v_wkt 
                       +
                       '('
                       +
                       [$(owner)].[STPointAsText] (
                                  /* @p_dimensions 
                       XY,XYZ,XYM,XYZM or NULL(XY) */ @v_dimensions,
                                  /* @p_X          */ @v_point.STX,
                                  /* @p_Y          */ @v_point.STX,
                                  /* @p_Z          */ @v_point.Z,
                                  /* @p_M          */ @v_point.M,
                                  /* @p_round_x    */ @v_round_xy,
                                  /* @p_round_y    */ @v_round_xy,
                                  /* @p_round_z    */ @v_round_zm,
                                  /* @p_round_m    */ @v_round_zm
                             )
                       +
                       ')';
        SET @v_geomn = @v_geomn - 1;
        IF ( @v_GeomN > 0 ) 
          SET @v_wkt = @v_wkt + ',';
      END;  -- While All geometries...
      -- Terminate whole geometry
      SET @v_wkt = @v_wkt + ')';
      RETURN geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
    END;

    -- Walk over all the segments of the linear geometry
    DECLARE cSegments 
     CURSOR FAST_FORWARD 
        FOR
     SELECT max(v.id) over (partition by v.multi_tag) as max_id,
            v.id,            v.multi_tag,
            v.element_id,    v.element_tag,
            v.subelement_id, v.subelement_tag,
            v.segment_id, 
            v.sx, v.sy, v.sz, v.sm,
            v.mx, v.my, v.mz, v.mm,
            v.ex, v.ey, v.ez, v.em,
            v.length,
            v.startLength,
            v.measureRange,
            v.geom
       FROM [$(owner)].[STSegmentLine](@p_geometry) as v
      ORDER by v.id desc;

   OPEN cSegments;

   FETCH NEXT 
    FROM cSegments 
    INTO @v_max_id,
         @v_id,            @v_multi_tag,
         @v_element_id,    @v_element_tag, 
         @v_subelement_id, @v_subelement_tag, 
         @v_segment_id, 
         @v_sx, @v_sy, @v_sz, @v_sm, 
         @v_mx, @v_my, @v_mz, @v_mm,
         @v_ex, @v_ey, @v_ez, @v_em,
         @v_length,
         @v_startLength,
         @v_measureRange,
         @v_segment_geom;

   SET @v_prev_element_tag = UPPER(@v_element_tag);
   SET @v_prev_element_id  = @v_element_id;
   SET @v_wkt              = UPPER(case when @v_multi_tag is not null then @v_multi_tag else @v_element_tag end) 
                             + 
                             case when @v_multi_tag = 'MultiLineString' then ' ((' else ' (' end
                             + 
                             case when @v_multi_tag = 'CompoundCurve' 
                                  then case when @v_element_tag = 'LineString' then '(' else @v_element_tag + ' (' end 
                                  else '' 
                              end
                             +
                             [$(owner)].[STPointAsText] (
                                  /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                                  /* @p_X          */ @v_ex,
                                  /* @p_Y          */ @v_ey,
                                  /* @p_Z          */ @v_ez,
                                  /* @p_M          */ @v_em,
                                  /* @p_round_x    */ @v_round_xy,
                                  /* @p_round_y    */ @v_round_xy,
                                  /* @p_round_z    */ @v_round_zm,
                                  /* @p_round_m    */ @v_round_zm
                             )
                             + 
                             ',';

   WHILE @@FETCH_STATUS = 0
   BEGIN

     IF ( @v_element_tag <> @v_prev_element_tag 
       or @v_element_id  <> @v_prev_element_id )
     BEGIN
       SET @v_wkt = @v_wkt + '), ' + case when @v_element_tag = 'CircularString' then 'CIRCULARSTRING(' else '(' end;
       -- First Coord of new element segment.
       --
       SET @v_wkt = @v_wkt + 
                    [$(owner)].[STPointAsText] (
                            /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                            /* @p_X          */ @v_ex,
                            /* @p_Y          */ @v_ey,
                            /* @p_Z          */ @v_ez,
                            /* @p_M          */ @v_em,
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                    )
                    + 
                    ', ';
     END
     ELSE
     BEGIN
       IF ( @v_id < @v_max_id ) 
         SET @v_wkt = @v_wkt + ', ';
     END;

     -- Is this a circularArc?
     IF ( @v_segment_geom.STGeometryType() = 'CircularString' and @v_mx is not null) 
     BEGIN
       SET @v_wkt = @v_wkt + 
                    [$(owner)].[STPointAsText] (
                          /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                          /* @p_X          */ @v_mx,
                          /* @p_Y          */ @v_my,
                          /* @p_Z          */ @v_mz,
                          /* @p_M          */ @v_mm,
                          /* @p_round_x    */ @v_round_xy,
                          /* @p_round_y    */ @v_round_xy,
                          /* @p_round_z    */ @v_round_zm,
                          /* @p_round_m    */ @v_round_zm
                    )
                    +
                    ', ';
     END;

     -- Print out new point
     SET @v_wkt = @v_wkt + 
                  [$(owner)].[STPointAsText] (
                          /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                          /* @p_X          */ @v_sx,
                          /* @p_Y          */ @v_sy,
                          /* @p_Z          */ @v_sz,
                          /* @p_M          */ @v_sm,
                          /* @p_round_x    */ @v_round_xy,
                          /* @p_round_y    */ @v_round_xy,
                          /* @p_round_z    */ @v_round_zm,
                          /* @p_round_m    */ @v_round_zm
                   );

     SET @v_prev_element_tag = @v_element_tag;
     SET @v_prev_element_id  = @v_element_id;

     FETCH NEXT 
      FROM cSegments 
      INTO @v_max_id,
           @v_id,            @v_multi_tag,
           @v_element_id,    @v_element_tag, 
           @v_subelement_id, @v_subelement_tag, 
           @v_segment_id, 
           @v_sx, @v_sy, @v_sz, @v_sm, 
           @v_mx, @v_my, @v_mz, @v_mm,
           @v_ex, @v_ey, @v_ez, @v_em,
           @v_length,
           @v_startLength,
           @v_measureRange,
           @v_segment_geom;
   END;
   CLOSE cSegments
   DEALLOCATE cSegments
   SET @v_wkt = @v_wkt + ')';
   IF ( @v_multi_tag is not null ) 
     SET @v_wkt = @v_wkt + ')';
   Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  End;
END
GO

