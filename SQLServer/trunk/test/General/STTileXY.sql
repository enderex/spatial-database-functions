SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STTileXY] ...';
GO

SELECT row_number() over (order by t.col, t.row) as rid, 
       t.col, t.row, t.geom.STAsText() as geom
  FROM [$(owner)].[STTileXY](0,0,1000,1000,250,250,0,0,0,0) as t;
GO

SELECT row_number() over (order by t.col, t.row) as rid, 
       t.col, t.row, t.geom.STAsText() as geom
  FROM [$(owner)].[STTileXY](0,0,1000,1000,250,250,0,0,45,0) as t;
GO


