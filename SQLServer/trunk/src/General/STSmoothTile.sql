SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STSmoothTile]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STSmoothTile];
  Print 'Dropped [$(owner)].[STSmoothTile] ....';
END;
GO

Print 'Creating [$(owner)].[STSmoothTile]....';
GO

CREATE FUNCTION [$(owner)].[STSmoothTile](
  @p_geometry  geometry,
  @p_precision integer = 3
)
RETURNS geometry
AS
 /****m* EDITING/STSmoothTile
  *  NAME
  *    STSmoothTile -- Smooths polygon created from raster to segment conversion
  *  SYNOPSIS
  *    Function STSmoothTile(
  *               @p_geometry  geometry,
  *               @p_precision integer = 3
  *             )
  *     Returns GEOMETRY
  *  DESCRIPTION
  *    A polygon created from raster to vector conversion, will have many vertices falling
  *    along the same straight line but whose sides will be "stepped".
  *    This function removes coincident points on a side so that a side will be defined by
  *    only a start and end vertex. The stepped sides will be replaced with vertices in the 
  *    midpoint of each step so that any consistent stepped side will be replaced by a single line.
  *  RESULT
  *    geometry (GEOMETRY) -- Grid shaped linestrings replaced by straight lines.
  *  NOTES
  *    Supports LineStrings, MultiLineStrings, Polygons and MultiPolygons.
  *    Uses:
  *      [$(owner)].[STNumDims]
  *      [$(owner)].[generate_series]
  *      [$(owner)].[STNumRings]
  *   EXAMPLE
  *     SELECT [$(owner)].[STSmoothTile](
  *                  geometry::STGeomFromText('LINESTRING(0 0,1 0,1 1,2 1,2 2,3 2,3 3,3 6,0 6,0 2)',0),
  *                  3).AsTextZM() as geom;
  *
  *     geom
  *     LINESTRING (0.5 0, 3 2.5, 3 4.5, 1.5 6, 0 4)
  *
  *     SELECT [$(owner)].[STSmoothTile](geometry::STGeomFromText('POLYGON ((12.5 2.5, 17.5 2.5, 17.5 7.5, 12.5 7.5, 12.5 2.5))',0),3).AsTextZM() as geom;
  *
  *     geom
  *     POLYGON ((15 2.5, 17.5 5, 15 7.5, 12.5 5, 15 2.5))

  *     SELECT [$(owner)].[STSmoothTile](geometry::STGeomFromText('POLYGON ((0 0, 9 0, 9 9, 0 9, 0 0), (2.5 2.5, 2.5 7.5, 7.5 7.5, 7.5 2.5, 2.5 2.5))',0),3).AsTextZM() as geom;
  *
  *     geom
  *     POLYGON ((4.5 0, 9 4.5, 4.5 9, 0 4.5, 4.5 0), (2.5 5, 5 7.5, 7.5 5, 5 2.5, 2.5 5))
  *
  *     select [$(owner)].[STSmoothTile](geometry::STGeomFromText(
  *            'MULTIPOLYGON (((12.5 2.5, 17.5 2.5, 17.5 7.5, 12.5 7.5, 12.5 2.5)), ((10 0, 19 0, 19 9, 10 9, 10 0), (11 1, 11 8, 18 8, 18 1, 11 1)), ((0 0, 9 0, 9 9, 0 9, 0 0), (2.5 2.5, 2.5 7.5, 7.5 7.5, 7.5 2.5, 2.5 2.5)))',0),3);
  *
  *     geom
  *     LINESTRING (0.5 0, 3 2.5, 3 4.5, 1.5 6, 0 4)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 - Original Coding (Oracle)
  *    Simon Greener - April   2020 - Port to SQL Server
  *  COPYRIGHT
  *    (c) 2008-2020 by TheSpatialDBAdvisor/Simon Greener
  ******/
Begin
  Declare
  @v_GeometryType varchar(100),
  @v_wkt_coords   varchar(max),
  @v_wkt          varchar(max),
  @v_end_pt_wkt   varchar(100),
  @v_elemN        int = 0,
  @v_geomN        int = 0,
  @v_nElems       int = 0,
  @v_nGeoms       int = 0,
  @v_geom         geometry,
  @v_precision    int;

  If ( @p_geometry is null ) 
    Return @p_geometry;

  SET @v_GeometryType = @p_geometry.STGeometryType();
  IF ( @v_GeometryType not in ('Polygon','LineString','MultiPolygon','MultiLineString') ) 
    Return @p_geometry;
  
  IF ( [$(owner)].[STNumDims](@p_geometry)<>2 ) 
    Return @p_geometry;

  SET @v_wkt = '';
  SET @v_precision = ISNULL(@p_precision,3);
  
  DECLARE c_elements 
   CURSOR FAST_FORWARD 
      FOR
    WITH geometries as (
    SELECT gs.IntValue as gs, 
           @p_geometry.STNumGeometries() as nGeoms,
           @p_geometry.STGeometryN(gs.IntValue) as geom
      FROM [$(owner)].[generate_series](1,@p_geometry.STNumGeometries(),1) as gs
    )
    SELECT geomN, nGeoms, elemN, nElems, geom 
      FROM (SELECT a.gs as geomN, CAST(null as int) as elemN, CAST(null as int) as nElems, a.nGeoms, a.geom
              FROM geometries as a
             WHERE a.geom.STGeometryType() = 'LineString'
             UNION ALL
            SELECT a.gs as geomN, 1 as elemN, 
                   [$(owner)].[STNumRings](a.geom) as nElems, nGeoms, 
                   a.geom.STExteriorRing() as geom
              FROM geometries as a
             WHERE a.geom.STGeometryType() = 'Polygon'
             UNION ALL
            SELECT a.gs as geomN,
                   gs + 1 as nElem, 
                   [$(owner)].[STNumRings](a.geom) as nElems,nGeoms, 
                   a.geom.STInteriorRingN(gs) as geom
              FROM geometries as a
                   cross apply
                   [$(owner)].[generate_series](1,a.geom.STNumInteriorRing(),1) as gs
             WHERE a.geom.STGeometryType() = 'Polygon'
           )  as f
     ORDER BY 1,2;

    OPEN c_elements;

    FETCH NEXT 
          FROM c_elements
          INTO @v_geomN, @v_nGeoms, @v_elemN, @v_nElems, @v_geom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      -- process coordinates of this element 
      SELECT @v_wkt_coords = string_agg(
               FORMAT(b.mx,'#######################0.' + LEFT('#########################',@v_precision))
               + ' ' + 
               FORMAT(b.my,'#######################0.' + LEFT('#########################',@v_precision)),
               ',' ) within group (order by b.rid)
        FROM (select rid, slope, next_slope, mx, my
               FROM (select rid,
                            slope,
                            lag(slope,1)  over (order by rid) as prev_Slope,
                            lead(slope,1) over (order by rid) as next_Slope,
                            mx,my
                       FROM (select rid,
                                    CASE WHEN (mx - lag(mx,1) over (order by rid)) = 0
                                         THEN 10
                                         ELSE (mY - lag(my,1) over (order by rid)) / (mx - lag(mx,1) over (order by rid))
                                     END as slope,
                                    lag(mx,1) over (order by rid) as lagX,
                                    lag(my,1) over (order by rid) as lagY,
                                    mx, my
                               FROM (select seg.id as rid,
                                            (seg.sx + seg.ex) / 2.0 as mX,
                                            (seg.sy + seg.ey) / 2.0 as mY
                                       FROM [$(owner)].[STSegmentize](
                                              @v_geom,
                                              'ALL',
                                              NULL,NULL,NULL,NULL,
                                              @p_precision,Default,Default) as seg
                                    ) as u
                            ) as v
                    ) as w
             ) as b
       where b.slope is null
          or b.slope <> b.next_slope
          or b.next_slope is null;

      IF ( @v_geometryType = 'LineString' ) 
        /* LineString
           geomN,nGeoms,elemN,nElems
           1,1,null,null
        */
        SET @v_wkt = @v_wkt_coords;

      IF ( @v_geometryType = 'MultiLineString' ) 
      BEGIN
        IF (@v_geomN=1 and @v_elemN is null and @v_nElems is null and @v_nGeoms=1 ) 
        BEGIN
          /* MultiLineString
           geomN,nGeoms,elemN,nElems
           1,2,null,null
           2,2,null,null
          */
          IF ( @v_geomN=1 and @v_nGeoms is not null and @v_elemN is null and @v_nElems is null ) 
            -- raise notice '%','Start MultiLine';
            SET @v_wkt = CONCAT('(',@v_wkt_coords,')');

          IF ( @v_geomN>1 and @v_nGeoms is not null and @v_elemN is null and @v_nElems is null ) 
            -- raise notice '%','End MultiLine';
            SET @v_wkt = CONCAT(@v_wkt,',(',@v_wkt_coords,')');
        END;
      END;

      IF ( @v_geometryType = 'Polygon' ) 
      BEGIN
        /* Polygon
           geomN,nGeoms,elemN,nElems
           1,1,1,3
           1,1,2,3
           1,1,3,3
        */
        -- Get missing end point
        SET @v_end_pt_wkt = SUBSTRING(@v_wkt_coords,1,CHARINDEX(',',@v_wkt_coords)-1);
        IF ( @v_elemN=1 ) 
          SET @v_wkt = CONCAT('(',@v_wkt_coords,',',@v_end_pt_wkt,')')
          -- Raise Notice 'Start Polygon - Exterior Ring';
        ELSE
          SET @v_wkt = CONCAT(@v_wkt,',(',@v_wkt_coords,',',@v_end_pt_wkt,')');
          -- Raise Notice 'Interior Ring';
      END;

      IF ( @v_geometryType = 'MultiPolygon' ) 
      BEGIN
        --raise notice '@v_wkt_coords %',@v_wkt_coords;
        --raise notice 'Start @v_wkt %',@v_wkt;
        /* MultiPolygon
           geomN,nGeoms,elemN,nElems
           1,2,1,2
           1,2,2,2
           2,2,1,3
           2,2,2,3
           2,2,3,3
           GeometryN = 2 with 1 Exterior Ring per poly           
           1,2,1,1
           2,2,1,1
        */
        -- Get missing end point
        SET @v_end_pt_wkt = SUBSTRING(@v_wkt_coords,1,CHARINDEX(',',@v_wkt_coords)-1);
        -- raise notice '% %', 'End Point: ', @v_end_pt_wkt;
        IF ( @v_elemN=1 ) 
        BEGIN -- New Polygon and its Exterior Ring
          -- raise notice '@v_geomN %',@v_geomN;
          IF ( @v_geomN = 1 ) -- First Polygon
            SET @v_wkt = CONCAT('((',
                            @v_wkt_coords,
                            ',',
                            @v_end_pt_wkt,
                            ')'
                           )
          ELSE /* @v_geomN > 1 */ 
            SET @v_wkt = CONCAT(@v_wkt,
                            ',((',
                            @v_wkt_coords,
                            ',',
                            @v_end_pt_wkt,
                            ')'
                            );
          
          -- IF NOTHING ELSE
          -- Interior Rings
          -- raise notice 'Polygon %', @v_wkt;
        END
        ELSE
          -- Interior Ring
          SET @v_wkt = CONCAT(@v_wkt,',(',@v_wkt_coords,',',@v_end_pt_wkt,')');
          -- raise notice 'Inner ring %',@v_wkt;

        IF (@v_elemN=@v_nElems) 
          -- End of Geometry and rings
          SET @v_wkt = CONCAT(@v_wkt,')');

      END; 
      FETCH c_elements 
       INTO @v_geomN, @v_nGeoms, @v_elemN, @v_nElems, @v_geom;
    END; /* WHILE */
  
  CLOSE c_elements;
  SET @v_wkt = CONCAT( UPPER(@v_geometryType),' (',@v_wkt,')');
  SET @v_geom = geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  Return @v_geom;
END;
GO

/*
with data as (
select geometry::STGeomFromText('LINESTRING(0 0,1 0,1 1,2 1,2 2,3 2,3 3,3 6,0 6,0 2)',0) as geom 
--select geometry::STGeomFromText('POLYGON((0 0,1 0,2 0,3 0,4 0,5 0,6 0,7 0,8 0,9 0,10 0,10 1,9 1,8 1,7 1,6 1,5 1,4 1,3 1,2 1,1 1,0 1,0 0))',0) as geom
)
select [$(owner)].[STSmoothTile](a.geom,3) from data as a
select (ST_DumpPoints(dbo.STSmoothTile(a.geom,3))).geom from data as a
union all
select spdba.ST_SmoothTile(a.geom,3) from data as a
union all
select a.geom from data as a;


with data as (
select 1 as id, 'POLYGON((0 0,10 0,10 10,0 10,0 0))'::geometry as p_geom     union all
select 2, 'POLYGON((0 0,10 0,10 10,0 10,0 0),(2.5 2.5,7.5 2.5, 7.5 7.5,2.5 7.5,2.5 2.5))'::geometry as p_geom     union all
select 3, 'POLYGON((0 0,10 0,10 10,0 10,0 0),(2.5 2.5,7.5 2.5, 7.5 7.5,2.5 7.5,2.5 2.5),(0.5 0.5,1.5 0.5,1.5 1.5,0.5 1.5, 0.5 0.5))'::geometry as p_geom    union all
select 4 as id, 'LINESTRING(0 0,1 0,1 1,2 1,2 2,3 2,3 3,3 6,0 6,0 2)'::geometry as p_geom union all
select 9 as id, 'LINESTRING(0 0,1 0,1 1,2 1,2 2,3 2,3 3,4 3)'::geometry as p_geom union all
select 5 as id, 'MULTILINESTRING((0 0,1 0,1 1,2 1,2 2,3 2,3 3,3 6,0 6,0 2),(10 0,11 0,11 1,12 1,12 2,13 2,13 3,13 6,10 6,10 2))'::geometry as p_geom union all
select 6 as id,  'MULTIPOLYGON(((0  0, 9 0, 9  9, 0 9, 0 0),( 2.5 2.5, 7.5 2.5, 7.5 7.5, 2.5 7.5, 2.5 2.5)),
                       ((10 0,19 0,19  9,10 9,10 0),(12.5 2.5,17.5 2.5,17.5 7.5,12.5 7.5,12.5 2.5),(11 1,18 1,18 8,11 8,11 1)))'::geometry as p_geom 
)
select id, p_geom from data as a
union all
select id, spdba.ST_SmoothTile(@p_geom,3) from data as a

with data as (
select 7, 'MULTIPOLYGON(((207540 155340,207520 155340,207520 155359.999999999,207480 155360,207480 155380,207440 155380.000000001,207440 155400,207420 155400,207540 155000,207540 155340)))' as p_geom union all
select 8, 'MULTIPOLYGON(((207540 155340,207520 155340,207520 155359.999999999,207480 155360,207480 155380,207440 155380.000000001,207440 155400,207420 155400,207540 155000,207540 155340)),((200000 155300,200010 155300,200010 155310,200000 155310,200000 155300)))'  as p_geom
)
select id, p_geom from data as a
union all 
select id,spdba.ST_SmoothTile(@p_geom) as sGeom from data as a;

with data as (
select 8 as id, ST_GeoMFromText('MULTIPOLYGON(((207540 155340,207520 155340,207520 155359.999999999,207480 155360,207480 155380,207440 155380.000000001,207440 155400,207420 155400,207540 155000,207540 155340)),((200000 155300,200010 155300,200010 155310,200000 155310,200000 155300)))')  as p_geom
)
,geometries as (
SELECT gs.*, 
     ST_NumGeometries(a.p_geom) as nGeoms,
     ST_GeometryN(a.p_geom,gs.*) as geom
FROM data as a,
     generate_series(1,ST_NumGeometries(a.p_geom)) as gs
 WHERE id = 8
)
select geomN, nGeoms, elemN, nElems
from (
SELECT a.gs as geomN, CAST(null as int) as elemN, CAST(null as int) as nElems, a.nGeoms, a.geom
from geometries as a
 WHERE a.geom.STGeometryType() = 'ST_LineString'
 UNION ALL
SELECT a.gs as geomN, 1 as elemN, 1+ST_NumInteriorRings(a.geom) as nElems, a.nGeoms,ST_ExteriorRing(a.geom) as geom
FROM geometries as a
 WHERE a.geom.STGeometryType() = 'ST_Polygon'
 UNION ALL
SELECT a.gs as geomN,  gs.* + 1 as nElem, 1+ST_NumInteriorRings(a.geom) as nElems, a.nGeoms, ST_InteriorRingN(a.geom,gs.*) as geom
from geometries as a,
   generate_series(1,ST_NumInteriorRings(a.geom)) as gs
 WHERE a.geom.STGeometryType() = 'ST_Polygon'
)  as f
order by 1,2;
*/

select [$(owner)].[STSmoothTile](geometry::STGeomFromText('POLYGON ((12.5 2.5, 17.5 2.5, 17.5 7.5, 12.5 7.5, 12.5 2.5))',0),3).AsTextZM() as geom;
geom
POLYGON ((15 2.5, 17.5 5, 15 7.5, 12.5 5, 15 2.5))

select [$(owner)].[STSmoothTile](geometry::STGeomFromText('POLYGON ((0 0, 9 0, 9 9, 0 9, 0 0), (2.5 2.5, 2.5 7.5, 7.5 7.5, 7.5 2.5, 2.5 2.5))',0),3).AsTextZM() as geom;
geom
POLYGON ((4.5 0, 9 4.5, 4.5 9, 0 4.5, 4.5 0), (2.5 5, 5 7.5, 7.5 5, 5 2.5, 2.5 5))


select [$(owner)].[STSmoothTile](geometry::STGeomFromText(
'MULTIPOLYGON (((12.5 2.5, 17.5 2.5, 17.5 7.5, 12.5 7.5, 12.5 2.5)), ((10 0, 19 0, 19 9, 10 9, 10 0), (11 1, 11 8, 18 8, 18 1, 11 1)), ((0 0, 9 0, 9 9, 0 9, 0 0), (2.5 2.5, 2.5 7.5, 7.5 7.5, 7.5 2.5, 2.5 2.5)))',0),3);


