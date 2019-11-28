SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(Owner))';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(Owner)].[STTileGeomByPoint]') 
    AND xtype IN (N'P')
)
BEGIN
  DROP FUNCTION [$(Owner)].[STTileGeomByPoint];
  PRINT 'Dropped [$(Owner)].[STTileGeomByPoint] ...';
END;
GO

PRINT 'Creating [$(Owner)].[STTileGeomByPoint] ...';
GO

CREATE FUNCTION [$(Owner)].[STTileGeomByPoint]
(
  @p_point   geometry,
  @p_numTileX integer,
  @p_numTileY integer,
  @p_TileX      float,
  @p_TileY      float,
  @p_rAngle     float,
  @p_AsPoint      bit
)
returns @table table
(
  col  Int,
  row  Int,
  geom geometry
)
AS
/****f* TILING/STTileGeomByPoint (2008)
 *  NAME
 *    STTileGeomByPoint -- Creates mesh of tiles anchored to supplied point.
 *  SYNOPSIS
 *    Function STTileGeomByPoint (
 *               @p_point   geometry,
 *               @p_numTileX integer,
 *               @p_numTileY integer,
 *               @p_TileX      float,
 *               @p_TileY      float,
 *               @p_rAngle     float,
 *               @p_AsPoint      bit
 *             )
 *     Returns @table table
 *    (
 *      col  Int,
 *      row  Int,
 *      geom geometry
 *    )
 *  DESCRIPTION
 *    This function generates a mesh (grid) of tiles anchored to the supplied origin point.
 *    The mesh of tiles is controlled by three parameters:
 *      1  XY tile size in meters; 
 *      2  The number of tiles in X and Y direction;
 *      3 Optional rotation angle (around origin/achor point)
 *  INPUTS
 *    @p_point  (geometry) -- Origin/Anchor point of mesh 
 *    @p_numTileX integer) -- Number of tiles in X direction
 *    @p_numTileY integer) -- Number of tiles in Y direction
 *    @p_TileX     (float) -- Size of a Tile's X dimension in real world units.
 *    @p_TileY     (float) -- Size of a Tile's Y dimension in real world units.
 *    @p_rAngle    (float) -- Rotation angle around anchor point.
 *    @p_AsPoint     (bit) -- Return tile as point or polygon
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      col  Int      -- The column reference for a tile
 *      row  Int      -- The row reference for a tile
 *      geom geometry -- The polygon geometry covering the area of the Tile.
 *    )
 *  EXAMPLE
 *    select col,row,[$(Owner)].[STRound](geom,3,3,1,1).STAsText() as tile
 *      from [$(Owner)].[STTileGeomByPoint] ( 
 *             geometry::Point(55,12,0),
 *             4,   4,
 *             10, 10,
 *             5.2,0
 *            ) as t;
 *    GO
 *    
 *    col row tile
 *    0   0   POLYGON ((55 12, 64.962 12.872, 64.09 22.834, 54.128 21.962, 55 12))
 *    0   1   POLYGON ((54.128 21.962, 64.09 22.834, 63.219 32.795, 53.257 31.924, 54.128 21.962))
 *    0   2   POLYGON ((53.257 31.924, 63.219 32.795, 62.347 42.757, 52.385 41.886, 53.257 31.924))
 *    0   3   POLYGON ((52.385 41.886, 62.347 42.757, 61.476 52.719, 51.514 51.848, 52.385 41.886))
 *    1   0   POLYGON ((64.962 12.872, 74.924 13.743, 74.052 23.705, 64.09 22.834, 64.962 12.872))
 *    1   1   POLYGON ((64.09 22.834, 74.052 23.705, 73.181 33.667, 63.219 32.795, 64.09 22.834))
 *    1   2   POLYGON ((63.219 32.795, 73.181 33.667, 72.309 43.629, 62.347 42.757, 63.219 32.795))
 *    1   3   POLYGON ((62.347 42.757, 72.309 43.629, 71.438 53.591, 61.476 52.719, 62.347 42.757))
 *    2   0   POLYGON ((74.924 13.743, 84.886 14.615, 84.014 24.577, 74.052 23.705, 74.924 13.743))
 *    2   1   POLYGON ((74.052 23.705, 84.014 24.577, 83.143 34.539, 73.181 33.667, 74.052 23.705))
 *    2   2   POLYGON ((73.181 33.667, 83.143 34.539, 82.271 44.501, 72.309 43.629, 73.181 33.667))
 *    2   3   POLYGON ((72.309 43.629, 82.271 44.501, 81.4 54.462, 71.438 53.591, 72.309 43.629))
 *    3   0   POLYGON ((84.886 14.615, 94.848 15.486, 93.976 25.448, 84.014 24.577, 84.886 14.615))
 *    3   1   POLYGON ((84.014 24.577, 93.976 25.448, 93.105 35.41, 83.143 34.539, 84.014 24.577))
 *    3   2   POLYGON ((83.143 34.539, 93.105 35.41, 92.233 45.372, 82.271 44.501, 83.143 34.539))
 *    3   3   POLYGON ((82.271 44.501, 92.233 45.372, 91.362 55.334, 81.4 54.462, 82.271 44.501)) 
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - October 2019 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
   DECLARE
     @v_srid    Int,
     @v_loCol   int,
     @v_hiCol   int,
     @v_loRow   int,
     @v_hiRow   int,
     @v_col     int,
     @v_row     int,
     @v_wkt     nvarchar(max),
     @v_tile    geometry;
   Begin
     If ( @p_point is null )
       Return;
     If ( @p_point.STGeometryType() <> 'Point' )
       Return;
     SET @v_srid = @p_point.STSrid;
     SET @v_loCol = 0;
     SET @v_hiCol = @p_numTileX - 1;
     SET @v_loRow = 0;
     SET @v_hiRow = @p_numTileY - 1;
     SET @v_col = @v_loCol;
     WHILE ( @v_col <= @v_hiCol )
     BEGIN
       SET @v_row = @v_loRow;
       WHILE ( @v_row <= @v_hiRow )
       BEGIN
         SET @v_wkt = 'POLYGON((' + 
                 CONVERT(varchar(30),CAST( @p_point.STX + (@v_col * @p_tileX)             as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST( @p_point.STY + (@v_row * @p_tileY)             as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST((@p_point.STX + (@v_col * @p_tileX) + @p_tileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST( @p_point.STY + (@v_row * @p_tileY)             as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST((@p_point.STX + (@v_col * @p_tileX) + @p_tileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST((@p_point.STY + (@v_row * @p_tileY) + @p_tileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST( @p_point.STX + (@v_col * @p_tileX)             as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST((@p_point.STY + (@v_row * @p_tileY) + @p_tileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST( @p_point.STX + (@v_col * @p_tileX)             as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST( @p_point.STY + (@v_row * @p_tileY)             as DECIMAL(24,12))) + '))';
         SET @v_tile = geometry::STGeomFromText(@v_WKT,@v_srid);
         IF ( COALESCE(@p_rAngle,0) <> 0 ) 
            SET @v_tile = [$(Owner)].[STRotate]( 
                             @v_tile,
                             @p_point.STX,
                             @p_point.STY,
                             @p_rAngle,
                             15,15
                          );
         INSERT INTO @table VALUES(@v_col,@v_row,case when @p_AsPoint=1 then @v_tile.STCentroid() else @v_tile end);
         SET @v_row = @v_row + 1;
       END;
       SET @v_col = @v_col + 1;
     END;
     RETURN;
   END;
End;
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

