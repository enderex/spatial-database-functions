SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(Owner)].[STTileGeomByPoint] ...';
GO

-- Top-left position of grid: 55.634269978244582 12.051864414446955
-- Rotation: 5.2 degrees
-- Number of grid rows: 14
-- Number of grid columns: 28
-- Grid cell width: 10 meters
-- Grid cell height: 10 meters

select col,row,geom.STBuffer(0.5) as tile
  from [$(Owner)].[STTileGeomByPoint] ( 
         geometry::Point(55,12,0),
         /*@p_numTileX*/ 4,
         /*@p_numTileY*/ 4,
         /*@p_TileX   */ 10,
         /*@p_TileY   */ 10,
         /*@p_rAngle  */ 5.2,
         /*@p_AsPoint */ 1
        ) as t
union all
select col,row,geom.STBuffer(0.1) as tile
  from [$(Owner)].[STTileGeomByPoint] ( 
         geometry::Point(55,12,0),
         /*@p_numTileX*/ 4,
         /*@p_numTileY*/ 4,
         /*@p_TileX   */ 10,
         /*@p_TileY   */ 10,
         /*@p_rAngle  */ 5.2,
         /*@p_AsPoint */ 0
        ) as t;
GO

