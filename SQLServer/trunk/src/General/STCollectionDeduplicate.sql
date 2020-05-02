SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STCollectionDeDuplicate]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STCollectionDeDuplicate];
  Print 'Dropped [$(owner)].[STCollectionDeDuplicate] ....';
END;
GO

Print 'Creating [$(owner)].[STCollectionDeDuplicate]....';
GO

CREATE FUNCTION [$(owner)].[STCollectionDeduplicate] (
  @p_collection geometry, -- GeometryCollection
  @p_geom_type  integer = 0, /* 0:All, 1:Point, 2:Line, 3:geom */
  @p_similarity float = 1.0
)
RETURNS @geoms TABLE (
   Id   integer,
   geom geometry
)
AS 
/****m* PROCESSING/STCollectionDeduplicate (2012)
 *  NAME
 *   STCollectionDeduplicate - Determines all possible spatial relations between two geometry instances.
 *  SYNOPSIS
 *    Function STCollectionDeduplicate
 *               @p_collection geometry,    -- GeometryCollection
 *               @p_geom_type  integer = 0, -- 0:All, 1:Point, 2:Line, 3:geom 
 *               @p_similarity float = 1.0  -- See $(owner).STSimilarityByArea
 *             )
 *     RETURNS @geoms TABLE (
 *       Id   integer,
 *       geom geometry
 *     )
 *  DESCRIPTION
 *    The input to this function is a GeometryCollection containing any type of geometry.
 *    The GeometryCollection is processed for equality, with only one geometry being kept.
 *    @p_geom_type allows the user to instruct the function to filter any geometry type 
 *    that is not the desired type:
 *      0 - All types are processed.
 *      1 - Only points are compared and returned.
 *      2 - Only LineStrings are compared and returned.
 *      3 - Only Polygons are compared and returned.
 *    If p_similarity is <> 1 then its value determines the amount of difference allowed
 *    before two polygons are considered to be equal.
 *  INPUTS
 *    @p_collection (geometry) - Non-null GeometryCollection instance.
 *    @p_geom_type  (Integer)  - Geometry Types to be processed and returned.
 *    @p_similarity (float)    - Area Similarity measure 0..1
 *  RESULT
 *    Table of Geometries - In which all duplicates have been removed.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - March 2020 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2020 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_collection geometry,
    @v_similarity float,
    @v_srid       integer,
    @v_geom_type  integer;

  IF ( @p_collection is null )
    RETURN;

  IF ( @p_collection.STGeometryType() <> 'GeometryCollection' ) 
  BEGIN
    INSERT INTO @geoms (id,geom) VALUES(1,@p_collection);
    RETURN;
  END;

  IF ( @p_collection.STIsValid() = 0 ) 
    SET @v_collection = @p_collection.MakeValid()
  ELSE
    SET @v_collection = @p_collection;

  SET @v_similarity = ISNULL(@v_similarity,1.0);
  SET @v_srid       = @v_collection.STSrid;
  SET @v_geom_type  = ISNULL(@p_geom_type,0);

  WITH geomSet as (
    SELECT row_number() over (order by (select 1)) as id,
           f.Geom as geom
      FROM (SELECT @v_collection
                      .STGeometryN(geomN.[IntValue])
                      .STGeometryN(partN.[IntValue]) as Geom
              FROM [$(owner)].[Generate_Series](1,@v_collection.STNumGeometries(),1) as geomN
                   cross apply
                   [$(owner)].[Generate_Series](1,@v_collection.STGeometryN(geomN.[IntValue]).STNumGeometries(),1) as partN
            ) as f
      WHERE  @v_geom_type = 0
         OR (@v_geom_type = 1 and f.Geom.STGeometryType() = 'Point')
         OR (@v_geom_type = 2 and f.Geom.STGeometryType() = 'LineString')
         OR (@v_geom_type = 3 and f.Geom.STGeometryType() = 'Polygon')
     )
     , equals as (
     SELECT DISTINCT a.id2 as id_equals /* id2 is the equals one to be thrown away */
       FROM (SELECT DISTINCT 
                    case when a.id < b.id then a.id else b.id end as id1,
                    case when a.id < b.id then b.id else a.id end as id2
               FROM geomSet as a,
                    geomSet as b
              WHERE a.id <> b.id
              ) as a
              INNER JOIN geomSet as ps  ON (ps.id  = a.id1)
              INNER JOIN geomSet as ps2 ON (ps2.id = a.id2)
        WHERE [$(owner)].[STDetermine](ps.geom,ps2.geom,@v_similarity) = 'EQUALS'
      )
      --select * from equals; -- 2 3 8 12
      INSERT INTO @geoms (id,geom)
      SELECT gs.id, gs.geom as geom
       FROM (SELECT ps.id
               FROM geomSet as ps
             EXCEPT
             SELECT ps.id
               FROM geomSet as ps
              WHERE EXISTS (SELECT 1 FROM equals as e WHERE e.id_equals = ps.id)
            ) as b
            inner join 
            geomSet as gS on (gs.id = b.id);

   RETURN;
END;
GO

