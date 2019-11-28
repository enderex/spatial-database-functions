SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

Print 'Testing [$(owner)].[STTileByNumGrids] ...';
GO

SELECT row_number() over (order by col, row) as tileId,
       col,row,geom.STBuffer(0.00005) as Tile
  FROM [$(owner)].[STTileByNumGrids](
         geometry::STGeomFromText('LINESTRING(12.160367016481523 55.474850814352628,12.171397605408989 55.478619145167649)',0),
         2, 2,
         geometry::STGeomFromText('POINT(12.160367016481523 55.474850814352628)',0),
         45,
         1
       ) as t
union all
SELECT row_number() over (order by col, row) as tileId,
       col,row,geom as Tile
  FROM [$(owner)].[STTileByNumGrids](
         geometry::STGeomFromText('LINESTRING(12.160367016481523 55.474850814352628,12.171397605408989 55.478619145167649)',0),
         2, 2,
         geometry::STGeomFromText('POINT(12.160367016481523 55.474850814352628)',0),
         45,
         0
        ) as t;
GO

