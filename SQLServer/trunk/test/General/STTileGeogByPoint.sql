SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(Owner)].[STTileGeogByPoint] ...';
GO

-- Top-left position of grid: 55.634269978244582 12.051864414446955
-- Rotation: 45.0 degrees
-- Number of grid rows: 4
-- Number of grid columns: 4
-- Grid cell width: 10 meters
-- Grid cell height: 10 meters

select col,row,geom.STBuffer(0.5) as geog
  from [$(Owner)].[STTileGeogByPoint] ( 
         geography::Point(55.634269978244582,12.051864414446955,4326),
         /*@p_numTileX*/ 2,
         /*@p_numTileY*/ 4,
         /*@p_TileX   */ 10,
         /*@p_TileY   */ 10,
         /*@p_rAngle  */ 45.0,
         /*@p_AsPoint*/   1
        ) as t
union all
select col,row,geom as geog
  from [$(Owner)].[STTileGeogByPoint] ( 
         geography::Point(55.634269978244582,12.051864414446955,4326),
         /*@p_numTileX*/ 2,
         /*@p_numTileY*/ 4,
         /*@p_TileX   */ 10,
         /*@p_TileY   */ 10,
         /*@p_rAngle  */ 45.0,
         /*@p_AsPoint*/   0
        ) as t;
GO

-- Top-left position of grid: 55.634269978244582 12.051864414446955
-- Rotation: 5.2 degrees
-- Number of grid rows: 14
-- Number of grid columns: 28
-- Grid cell width: 10 meters
-- Grid cell height: 10 meters

select col,row,geom
  from [$(Owner)].[STTileGeogByPoint] ( 
         geography::Point(55.634269978244582,12.051864414446955,4326),
         /*@p_numTileX*/ 14,
         /*@p_numTileY*/ 28,
         /*@p_TileX   */ 10,
         /*@p_TileY   */ 10,
         /*@p_rAngle  */ 5.2,
         /*@p_AsPoint*/   0
        ) as t;
GO


