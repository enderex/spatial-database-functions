use DEVDB
go

Drop Function If Exists [dbo].[STPolygonize];
GO

Create Function [dbo].[STPolygonize] (
  @p_polygon_collection geometry,
  @p_similarity         float = 1.0,
  @p_round_xy           integer = 3,
  @p_loops              integer = 5
)
 Returns @polygons TABLE(
   id      integer,
   polygon geometry
)
As
Begin
  Declare 
    @v_srid               integer,
    @v_i                  integer,
    @v_geom_i             geometry,
    @v_num_geoms          integer,
    @v_round_xy           integer,
    @v_loop               integer,
    @v_count              integer,

    @v_similarity         float,
    @v_relationship       varchar(1000),
    @v_keep_processing    integer,
    @v_geometry_type      varchar(100),
    @v_polygon_collection geometry,
    @v_collection         geometry;
  
  IF (@p_polygon_collection is null 
   OR @p_polygon_collection.STGeometryType() <> 'GeometryCollection' 
   OR @p_polygon_collection.STIsValid() = 0 
   OR @p_polygon_collection.STIsEmpty() = 1 )
   RETURN;

  SET @v_srid       = @p_polygon_collection.STSrid;
  SET @v_round_xy   = ISNULL(@p_round_xy,3);   
  SET @v_similarity = ISNULL(@p_similarity,1.0);

  -- The GeometryCollection should contain non-duplicate polygons only.
  -- Calling function can ensure this by using ....
  --
  --SELECT @v_polygon_collection = geometry::CollectionAggregate(f.geom)
  --  FROM [dbo].[STCollectionDeduplicate] ( @p_polygon_collection, 3 /* POLYGON */, @v_similarity ) as f
  -- ORDER BY f.geom.STArea() DESC;

  SET @v_polygon_collection = @p_polygon_collection;

  SET @v_collection      = NULL;
  SET @v_keep_processing = 1;
  SET @v_loop            = 1;
  WHILE ( @v_loop <= ISNULL(@p_loops,10) and @v_keep_processing <> 0 )
  BEGIN
    -- Load first into empty collection
    SET @v_collection = [dbo].[STCollectionAppend] (
                               @v_collection,
                               @v_polygon_collection.STGeometryN(1),
                               0
                            );

    SET @v_collection = @v_collection.MakeValid();

    SET @v_i = 2;
    WHILE ( @v_i <= @v_polygon_collection.STNumGeometries() )
    BEGIN
      SET @v_geom_i = @v_polygon_collection.STGeometryN(@v_i);

      -- Handle geometries that have no relationship with any object in the collection
      -- In collection mode, STDetermine returns a comma separated list eg 'DISJOINT,EQUALS,CONTAINS',
      -- Or, if the collection has one geometry, a single word eg EQUALS
      SET @v_relationship = [dbo].[STDetermine](@v_collection,@v_geom_i,@v_similarity);

      -- If only have single token in @v_relationship then it means we can add the geometry directly
      IF (@v_relationship IN ('DISJOINT','TOUCHES'))
      BEGIN
        -- Not in collection so add it
        SET @v_collection = [dbo].[STCollectionAppend] (@v_collection,@v_geom_i,1);
        SET @v_i += 1;
        CONTINUE;
      END;

      IF (@v_relationship = 'EQUALS')
      BEGIN
        -- Nothing to do
        SET @v_i += 1;
        CONTINUE;
      END;
      
      -- @v_geom_i has possibly multiple relationships with one or more geometry in the collection.
      -- Process @g_geom_i against all intersecting polygons
      --
      WITH processed AS (
      SELECT geometry::CollectionAggregate(f.geom) as cGeom
        FROM (
        SELECT CASE 
               WHEN a.relationship = 'OVERLAPS'
               THEN CASE i.[IntValue]
                    WHEN 1 THEN a.geom.STIntersection (@v_geom_i)
                    WHEN 2 THEN a.geom.STDifference   (@v_geom_i)
                    WHEN 3 THEN @v_geom_i.STDifference(a.geom)
                     END
               WHEN a.relationship = 'CONTAINS'
               THEN CASE i.[IntValue]
                    WHEN 1 THEN a.geom.STDifference(@v_geom_i)
                    WHEN 2 THEN @v_geom_i
                     END 
               WHEN a.relationship = 'WITHIN'
               THEN CASE i.[IntValue]
                    WHEN 1 THEN @v_geom_i
                    WHEN 2 THEN @v_geom_i.STDifference(a.geom)
                     END
               ELSE a.geom 
                END as geom
         FROM (SELECT @v_collection.STGeometryN(geomN.[IntValue]) as geom,
                      /* Get specific 1:1 relationship */
                      [dbo].[STDetermine](@v_collection.STGeometryN(geomN.[IntValue]),
                                          @v_geom_i,
                                          @v_similarity
                      ) as relationship
                 FROM [dbo].[Generate_Series](1,@v_collection.STNumGeometries(),1) as geomN
              ) as a
              CROSS APPLY
              [dbo].[generate_series](
                    1,
                    CASE 
                    WHEN a.relationship = 'OVERLAPS' 
                    THEN 3
                    WHEN a.relationship IN ('CONTAINS','WITHIN') 
                    THEN 2
                    ELSE 1 /* DISTINCT,EQUALS,TOUCHES */
                    END,
                    1
              ) as i
           ) as f
        WHERE f.geom.STIsValid() = 1
          -- AND [dbo].[STThinnessRatio](a.geom) > 0.00002
      )
      SELECT @v_collection = [dbo].[STRound] (geometry::CollectionAggregate(r.geom),@v_round_xy,@v_round_xy,@v_round_xy,@v_round_xy)
        FROM processed as a
             cross apply
             [dbo].[STCollectionDeduplicate] (a.cGeom,3/*Polygon*/,@v_similarity) as r;

      SET @v_collection = @v_collection.MakeValid();

      SET @v_i += 1;
    END;

    -- *************************
    -- Do we need to loop again?
    --
    IF ( @v_collection is null OR @v_collection.STIsEmpty() = 1 ) 
    BEGIN
      -- Return current @v_polygon_collection
      SET @v_collection = @v_polygon_collection;
      BREAK;
    END;
  
    -- Remove duplicates from current collection of polygons
    -- Filter out points and linestrings, only returning polygons
    --
    SELECT @v_collection = geometry::CollectionAggregate(f.geom)
      FROM [dbo].[STCollectionDeduplicate] ( @v_collection, 3 /* Polygon */, @v_similarity ) as f;

    SET @v_collection = @v_collection.MakeValid();

    -- ********************************************************
    -- We need to continue to process the new set of polygons
    -- if we still have any polygon that overlaps another etc.
    --
    SET @v_i               = 1;
    SET @v_keep_processing = 0;
    SET @v_num_geoms       = @v_collection.STNumGeometries();
    WHILE ( @v_i <= @v_num_geoms )
    BEGIN
      SET @v_relationship = dbo.STDetermine(
                                @v_collection,
                                @v_collection.STGeometryN(@v_i),
                                @v_similarity
                            );
      IF ( CHARINDEX('OVERLAPS',@v_relationship) > 0
        OR CHARINDEX('CONTAINS',@v_relationship) > 0
        OR CHARINDEX('WITHIN',  @v_relationship) > 0 )
      BEGIN
        SET @v_keep_processing = 1;
        BREAK;
      END;
      SET @v_i += 1;
    END; -- WHILE

    IF ( @v_keep_processing > 0 ) 
      SET @v_polygon_collection = @v_collection;

    -- End of loop test
    SET @v_loop += 1;
  END; -- Loops

  -- Return polygons 
  -- All duplicates have already been removed.
  --
  INSERT INTO @polygons (id,polygon)
  SELECT geomN.IntValue as id,
         @v_collection.STGeometryN(geomN.IntValue) as polygon
    FROM [dbo].[generate_series](1,@v_collection.STNumGeometries(),1) as geomN;
  RETURN;
END;
GO

-- ***********************************************************************************

select p.id, p.polygon.STAsText() as polygon
  from [dbo].[STPolygonize](
geometry::STGeomFromText(
'GEOMETRYCOLLECTION(
POLYGON((1 1,9 1,9 9,1 9,1 1)),
POLYGON((3 3,8 3,8 8,3 8,3 3)),
POLYGON((1 1,3 1,3 3,1 3,1 1)),
POLYGON((2 2,4 2,4 4,2 4,2 2)),
POLYGON((9 9,10 9,10 10,9 10,9 9)),
POLYGON((2 6,3 6,3 8,2 8,2 6)),
POLYGON((5 6,6 6,6 7,5 7,5 6)),
POLYGON((3.5 1.5,4.5 1.5,4.5 3.5,3.5 3.5,3.5 1.5)))',0)
,0.99999,3,5) as p;

-- *****************************************************

select p.polygon.STAsText() as rGeom
       --p.polygon.STArea() as area,
       --p.polygon.STLength() as perimeter,
       --CAST([dbo].[STThinnessRatio](p.polygon) as decimal(12,10)) as thinR
  from [dbo].[STPolygonize](
geometry::STGeomFromText('
GEOMETRYCOLLECTION (
Polygon ((-164269.8421000000089407 -1485141.98409999907016754, -164171.02209999971091747 -1485530.05790000036358833, -163373.06230000033974648 -1485340.88959999941289425, -163470.6119999997317791 -1484944.89310000091791153, -164269.8421000000089407 -1485141.98409999907016754)),
Polygon ((-165633.91220000013709068 -1486298.35319999977946281, -165428.4209000002592802 -1487072.48760000057518482, -164647.92300000041723251 -1486881.51879999972879887, -164844.56289999932050705 -1486103.06799999997019768, -165633.91220000013709068 -1486298.35319999977946281)),
Polygon ((-165838.38269999995827675 -1485528.05279999971389771, -165633.91220000013709068 -1486298.35319999977946281, -164844.56289999932050705 -1486103.06799999997019768, -164647.92300000041723251 -1486881.51879999972879887, -163875.03449999913573265 -1486692.40750000067055225, -164171.02209999971091747 -1485530.05790000036358833, -164269.8421000000089407 -1485141.98409999907016754, -165838.38269999995827675 -1485528.05279999971389771)),
Polygon ((-165838.38269999995827675 -1485528.05279999971389771, -165428.4209000002592802 -1487072.48760000057518482, -163875.03449999913573265 -1486692.40750000067055225, -164171.02209999971091747 -1485530.05790000036358833, -164269.8421000000089407 -1485141.98409999907016754, -165838.38269999995827675 -1485528.05279999971389771)))',0)
,0.99999,1,5) as p;

-- *********************************************

With MNUnit as (
 /* MN */
          select geometry::STGeomFromText(
'POLYGON((-164269.84210000001 -1485141.9840999991, -164171.02209999971 -1485530.0579000004, -163373.06230000034 -1485340.8895999994, -163470.61199999973 -1484944.8931000009, -164269.84210000001 -1485141.9840999991))',0) as geom
/* Unit */
union all select geometry::STGeomFromText(
'POLYGON((-165633.91220000014 -1486298.3531999998, -165428.42090000026 -1487072.4876000006, -164647.92300000042 -1486881.5187999997, -164844.56289999932 -1486103.068, -165633.91220000014 -1486298.3531999998))',0)
union all select geometry::STGeomFromText(
'POLYGON((-165838.38269999996 -1485528.0527999997, -165633.91220000014 -1486298.3531999998, -164844.56289999932 -1486103.068, -164647.92300000042 -1486881.5187999997, -163875.03449999914 -1486692.4075000007, -164269.84210000001 -1485141.9840999991, -165838.38269999996 -1485528.0527999997))',0)
union all select geometry::STGeomFromText(
'POLYGON((-165838.38269999996 -1485528.0527999997, -165428.42090000026 -1487072.4876000006, -163875.03449999914 -1486692.4075000007, -164269.84210000001 -1485141.9840999991, -165838.38269999996 -1485528.0527999997))',0) as geom
)
, collection as (
select geometry::CollectionAggregate(b.geom) as geomC
  from (select TOP 100 PERCENT
               b.geom
          from (select geometry::CollectionAggregate(f.geom) as geomC
                  from MNUnit as f
               ) as a
               cross apply
               [DEVDB].[dbo].[STCollectionDeDuplicate](
                             dbo.STRound(a.geomC,2,2,1,1),
                             3,0.9999) as b
         ORDER BY b.geom.STArea() desc
       ) as b
)
select p.id, 
       p.polygon.STAsText() as geom
  from collection as a
       cross apply
       [dbo].[STPolygonize](a.geomC,0.99999,2,3) as p;

/*
select round([devdb].[dbo].[STSimilarityByArea](b.geom,c.geom),5) as similarity,
             [devdb].[dbo].[STDetermine](b.geom,c.geom,0.9999) as determine
  from geometryCollection as a
       cross apply
       dbo.STCollectionExtract(a.geom,3) as b
       cross apply
       dbo.STCollectionDeDuplicate(a.geom,3,0.99999) as c

select p.id, 
       p.polygon.STArea() as area,
       p.polygon.STLength() as perimeter,
       [dbo].[STThinnessRatio](p.polygon) as thinR,
       p.polygon.STAsText() as geom
  from geometrycollection as a
       cross apply
       [dbo].[STPolygonize](a.geom,0.99999,2,5) as p;
*/

with polygons as (
select geometry::STGeomFromText('POLYGON ((-164647.92 -1486881.52, -163875.03 -1486692.41, -164171.02 -1485530.06, -164171.02 -1485530.06, -164269.84 -1485141.98, -165838.38 -1485528.05, -165633.91 -1486298.35, -164844.56 -1486103.07, -164647.92 -1486881.52))',0) as polygon1,
       geometry::STGeomFromText('POLYGON ((-164647.92 -1486881.52, -163875.03 -1486692.41, -164269.84 -1485141.98, -165838.38 -1485528.05, -165633.91 -1486298.35, -165633.91 -1486298.35, -165633.91 -1486298.35, -164844.56 -1486103.07, -164647.92 -1486881.52))',0) as polygon2
)
select [dbo].[STDetermine](a.polygon1,a.polygon2,0.99999) as determine,
       [dbo].[STSimilarityByArea](a.polygon1,a.polygon2) as similarity
  from polygons as a;
