
SELECT gtype.IntValue,
       a.geom.STAsText()
  FROM [$(owner)].[generate_series](1,3,1) as gtype
       CROSS APPLY
       [$(owner)].[STCollectionExtract](
          geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(0 0),LINESTRING(0 1,1 0),POLYGON((0 0,1 0,1 1,0 1,0 0)),MULTIPOLYGON(((0 0,1 0,1 1,0 1,0 0)),((1 1,2 0,2 2,1 2,1 1))))',0),
          gtype.IntValue
       ) as a;
GO

