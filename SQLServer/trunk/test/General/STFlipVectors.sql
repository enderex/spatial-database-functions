SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STFlipVectors] ...';
GO

select [$(owner)].STFlipVectors(geometry::STGeomFromText('GEOMETRYCOLLECTION (LINESTRING (722335.611 6173822.536, 722335.47 6173823.346, 722334.613 6173828.385, 722329.368 6173841.482, 722311.17 6173842.292, 722307.014 6173845.442, 722305.324 6173849.181, 722305.06 6173851.71, 722306.148 6173876.505, 722305.744 6173881.404), LINESTRING (722305.744 6173881.404, 722296.674 6173915.147), LINESTRING (722273.849 6173733.574, 722259.114 6173732.475, 722251.948 6173734.944, 722247.083 6173740.803), LINESTRING (722285.426 6173751.941, 722272.843 6173751.121), LINESTRING (722272.843 6173751.121, 722267.574 6173750.871), LINESTRING (722273.297 6173742.573, 722272.843 6173751.121), LINESTRING (722267.574 6173750.871, 722249.384 6173749.921, 722247.133 6173747.322, 722247.083 6173740.803), LINESTRING (722407.481 6173757.919, 722396.819 6173757.4), LINESTRING (722396.819 6173757.4, 722368.643 6173756.09), LINESTRING (722368.643 6173756.09, 722338.909 6173754.91), LINESTRING (722338.909 6173754.91, 722312.737 6173753.17), LINESTRING (722312.737 6173753.17, 722285.426 6173751.941), LINESTRING (722315.26 6173735.884, 722273.849 6173733.574), LINESTRING (722396.819 6173757.4, 722395.376 6173779.455), LINESTRING (722338.909 6173754.91, 722335.611 6173822.536), LINESTRING (722407.003 6173741.103, 722367.588 6173738.873), LINESTRING (722367.588 6173738.873, 722315.26 6173735.884), LINESTRING (722474.949 6173744.272, 722407.003 6173741.103), LINESTRING (722540.594 6173764.348, 722424.303 6173758.729), LINESTRING (722424.303 6173758.729, 722407.481 6173757.919), LINESTRING (722540.594 6173764.348, 722540.924 6173756.18), LINESTRING (722407.481 6173757.919, 722407.234 6173749.061), LINESTRING (722541.262 6173748.481, 722474.949 6173744.272), LINESTRING (722621.04 6173751.181, 722614.403 6173751.311), LINESTRING (722614.403 6173751.311, 722601.646 6173751.561, 722541.262 6173748.481), LINESTRING (722618.864 6173768.387, 722612.341 6173768.607, 722540.594 6173764.348), LINESTRING (722625.938 6173768.147, 722618.864 6173768.387), LINESTRING (722633.846 6173765.228, 722625.938 6173768.147), LINESTRING (722630.028 6173751.351, 722621.04 6173751.181))',0));
GO

Print '1. Two polygons with single shared boundary ....';
PRINT '... Point added to show that it is ignored.';
Print '... Result is 8 vectors with shared boundary duplicated...';
GO

With gc As (
select geometry::STGeomFromText('GEOMETRYCOLLECTION( POLYGON((10 0,20 0,20 20,10 20,10 0)), POLYGON((20 0,30 0,30 20,20 20,20 0)), POINT(0 0))',0) as geom
)
select v.sx,v.sy,v.ex,v.ey,count(*)
  from gc as a
       cross apply
       [$(owner)].[STVectorize](a.geom) as v
GROUP By v.sx,v.sy,v.ex,v.ey;
GO

Print '2. Two polygons with single shared boundary ....';
PRINT '... Point added to show that it is ignored.';
Print '... Result is 7 vectors as shared is now same and is removed by group by...';
GO

With gc As (
select geometry::STGeomFromText( 'GEOMETRYCOLLECTION( POLYGON((10 0,20 0,20 20,10 20,10 0)), POLYGON((20 0,30 0,30 20,20 20,20 0)), POINT(0 0))',0) as geom
)
select v.sx,v.sy,v.ex,v.ey,count(*)
  from gc as a
       cross apply
       [$(owner)].[STVectorize](
          [$(owner)].[STFlipVectors](a.geom)
       ) as v
group by v.sx,v.sy,v.ex,v.ey;
go

-- Could use this to remove the boundary and create a new polygon from both (dissolve)
-- Yes, could just use STUnion in first place but this is just an example of what can be done once vectors are flipped.
With gc As (
select geometry::STGeomFromText('GEOMETRYCOLLECTION( POLYGON((10 0,20 0,20 20,10 20,10 0)), POLYGON((20 0,30 0,30 20,20 20,20 0)), POINT(0 0))',0) as geom
)
select geometry::STGeomFromText(
         REPLACE(
            geometry::UnionAggregate(vector).STAsText(),
            'LINESTRING (' COLLATE DATABASE_DEFAULT,
            'POLYGON (('   COLLATE DATABASE_DEFAULT
         ) 
         + ')' COLLATE DATABASE_DEFAULT,
         0).STAsText() as polygon
  from (select [$(owner)].[STMakeLine] (
                  geometry::Point(v.sx,v.sy,0),
                  geometry::Point(v.ex,v.ey,0),
                  3,2
               ) as vector
          from gc as a
               cross apply
               [$(owner)].[STVectorize] (
                 [$(owner)].[STFlipVectors] ( a.geom )
               ) as v
         group by v.sx,v.sy,v.ex,v.ey
        having count(*) = 1  /* Get rid of duplicate lines */
       ) as f;
go

