SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: owner($(owner))';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STLineMerge]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STLineMerge];
  PRINT 'Dropped [$(owner)].[STLineMerge] ...';
END;
GO

PRINT 'Creating [$(owner)].[STLineMerge] ...';
GO

CREATE FUNCTION [$(owner)].[STLineMerge]
(
  @p_geometry geometry,
  @p_mode     varchar(1) = 'L' -- 'X'
)
RETURNS geometry
AS
-- =============================================
-- Author:      Simon Greener
-- Create date: 28 July 2018
-- Description: Simple Line Merge routine using recusive processing to generate longest line from group of linestrings.
-- =============================================
BEGIN
  DECLARE 
    @v_mode      varchar(1), 
    @v_leftMostX float,
    @v_geometry  geometry;

  IF ( @p_geometry is null ) 
    return @p_geometry;

  IF (@p_geometry.STGeometryType() NOT IN ('MultiLineString','LineString')) 
    return @p_geometry;

  SET @v_mode = UPPER(ISNULL(@p_mode,'L'));
  IF ( @v_mode not in ('L','X') )
    Return @p_geometry;

  SET @v_leftMostX = @p_geometry.STEnvelope().STStartPoint().STX;

  With base_lines as (
    /* Pull individual LineStrings out of any MultiLineString group */
    select v.[gid]      as gid, 
           v.[geom]     as segment,
           @v_leftMostX as leftMostX,
           v.[geom].STEnvelope().STStartPoint().STX as lineLeftX,
           ROUND(    v.[geom].STLength(),3)         as segment_length,
           ROUND(MAX(v.[geom].STLength()) over (partition by v.sid),3) as max_length,
           count(*)                       over (partition by v.sid)    as num_segments
      from [$(owner)].[STExtract] ( @p_geometry, 0 ) as v
  )
  , /* Now stitch linestrings together to find longest */
  walk_network(level,
               original_id, 
               child_id, 
               path, 
               segment) 
  AS ( 
    /* Root is longest linestring from multilinestring */
    select TOP 1 
           0             as level, 
           sl.[gid]      as original_id,
           sl.[gid]      as child_id,
           CAST(sl.[gid] as varchar(max)) + '/' as path, 
           sl.[segment]  as segment
      from base_lines as sl
     where ( @v_mode = 'L' and sl.[segment_Length] = sl.[max_length] ) -- Longest predicate
        or ( @v_mode = 'X' and sl.[lineLeftX]      = sl.[leftMostX]  ) -- Left most line
    UNION ALL
    /* Find next connected linestring and merge via recursive CTE */
    select w.[level] + 1       as level,
           w.[original_id]     as original_id,
           s.[gid]        as child_id, 
           CAST(CONCAT(w.[path],
                       '/',
                       CAST(s.[gid] as varchar(38)),
                       '/') as varchar(max)
               ) as path,
           /* Add new segment on to correct end */
           /* STUnion adds segment on to correct end regardless as to orientation */
           w.[segment].STUnion(s.[segment]) as geom
      from walk_network w
           inner join 
           base_lines s
           ON (     /* Any segment that touches is a candidate .... */ 
                    s.[segment].STTouches(w.[segment]) = 1
                and /* ... but only if it touches only at the end and not within */
                 (  s.[segment].STStartPoint().STEquals(w.[segment].STStartPoint()) = 1
                 or s.[segment].STStartPoint().STEquals(w.[segment].STEndPoint(  )) = 1
                 or s.[segment].STEndPoint(  ).STEquals(w.[segment].STEndPoint(  )) = 1
                 or s.[segment].STEndPoint(  ).STEquals(w.[segment].STStartPoint()) = 1
                 )
                 and /* ... and only if it has already not been processed */
                 CHARINDEX(CAST(s.[gid] as varchar(20))+'/',w.[path]) = 0
              )
     where /* Stop recursing this branch if built network has looped back so that start point = end point*/ 
           w.[segment].STEndPoint().STEquals(w.[segment].STStartPoint()) <> 1 
  )
  select TOP 1 
         @v_geometry = f.[segment]
    from (select a.[segment], 
                 a.[segment].STLength() as segment_length,
                 max(a.[segment].STLength()) over (order by a.[segment].STLength() desc) as max_segment_length
            from walk_network as a
           where a.[segment] is not null
         ) as f
   where f.[segment_length] = f.[max_segment_length]
   order by f.[segment_length] desc;
  RETURN @v_geometry;
END;
GO

PRINT 'Testing [$(owner)].[STLineMerge] ...';
GO

With tGeometry As (
  select cast('1' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (10 0,30 0,20 10)',0) as geom
   union all
  select cast('2' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (20 10,10 10)',0) as geom
   union all
  select cast('3' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (10 10,10 0)',0) as geom
   union all
  select cast('4' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (0 0,10 0)',0) as geom
   union all
  select cast('5' as varchar(2)) as id, geometry::STGeomFromText('LINESTRING (20 20, 20 10)',0) as geom
)
select 'O' + f.id as text, f.geom.STBuffer(0.2) as geom, ROUND(f.geom.STLength(),3) as gLen from tGeometry as f
union all
select 'MinX' as text,     f.geom.STBuffer(2)   as geom, ROUND(f.geom.STLength(),3) as gLen from (select [$(owner)].[STLineMerge](geometry::CollectionAggregate(a.geom),'X') as geom from tGeometry as a) as f
union all
select 'Long' as text,     f.geom.STBuffer(1)   as geom, ROUND(f.geom.STLength(),3) as gLen from (select [$(owner)].[STLineMerge](geometry::CollectionAggregate(a.geom),'L') as geom from tGeometry as a) as f;
GO

