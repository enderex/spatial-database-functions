USE $(usedbname)
GO

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
  @p_rAngle     float
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
 *               @p_rAngle     float
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
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      col  Int      -- The column reference for a tile
 *      row  Int      -- The row reference for a tile
 *      geom geometry -- The polygon geometry covering the area of the Tile.
 *    )
 *  EXAMPLE
 *    select col,row,geom.STAsText() as tile
 *      from [dbo].[STTileGeomByPoint] ( 
 *             geometry::Point(55,12,0),
 *             /*@p_numTileX*/ 4,
 *             /*@p_numTileY*/ 4,
 *             /*@p_TileX   */ 10,
 *             /*@p_TileY   */ 10,
 *             /*@p_rAngle  */ 5.2
 *            ) as t;
 *    GO
 *    
 *    col row tile
 *    0   0   POLYGON ((55 12, 64.9619469809175 12.8715574274766, 64.0903895534409 22.833504408394, 54.1284425725234 21.9619469809175, 55 12))
 *    0   1   POLYGON ((54.1284425725234 21.9619469809175, 64.0903895534409 22.833504408394, 63.2188321259643 32.7954513893115, 53.2568851450468 31.9238939618349, 54.1284425725234 21.9619469809175))
 *    0   2   POLYGON ((53.2568851450468 31.9238939618349, 63.2188321259643 32.7954513893115, 62.3472746984877 42.7573983702289, 52.3853277175703 41.8858409427524, 53.2568851450468 31.9238939618349))
 *    0   3   POLYGON ((52.3853277175703 41.8858409427524, 62.3472746984877 42.7573983702289, 61.4757172710111 52.7193453511464, 51.5137702900937 51.8477879236698, 52.3853277175703 41.8858409427524))
 *    1   0   POLYGON ((64.9619469809175 12.8715574274766, 74.9238939618349 13.7431148549532, 74.0523365343583 23.7050618358706, 64.0903895534409 22.833504408394, 64.9619469809175 12.8715574274766))
 *    1   1   POLYGON ((64.0903895534409 22.833504408394, 74.0523365343583 23.7050618358706, 73.1807791068817 33.6670088167881, 63.2188321259643 32.7954513893115, 64.0903895534409 22.833504408394))
 *    1   2   POLYGON ((63.2188321259643 32.7954513893115, 73.1807791068817 33.6670088167881, 72.3092216794052 43.6289557977055, 62.3472746984877 42.7573983702289, 63.2188321259643 32.7954513893115))
 *    1   3   POLYGON ((62.3472746984877 42.7573983702289, 72.3092216794052 43.6289557977055, 71.4376642519286 53.590902778623, 61.4757172710111 52.7193453511464, 62.3472746984877 42.7573983702289))
 *    2   0   POLYGON ((74.9238939618349 13.7431148549532, 84.8858409427524 14.6146722824297, 84.0142835152758 24.5766192633472, 74.0523365343583 23.7050618358706, 74.9238939618349 13.7431148549532))
 *    2   1   POLYGON ((74.0523365343583 23.7050618358706, 84.0142835152758 24.5766192633472, 83.1427260877992 34.5385662442647, 73.1807791068817 33.6670088167881, 74.0523365343583 23.7050618358706))
 *    2   2   POLYGON ((73.1807791068817 33.6670088167881, 83.1427260877992 34.5385662442647, 82.2711686603226 44.5005132251821, 72.3092216794052 43.6289557977055, 73.1807791068817 33.6670088167881))
 *    2   3   POLYGON ((72.3092216794052 43.6289557977055, 82.2711686603226 44.5005132251821, 81.399611232846 54.4624602060996, 71.4376642519286 53.590902778623, 72.3092216794052 43.6289557977055))
 *    3   0   POLYGON ((84.8858409427524 14.6146722824297, 94.8477879236698 15.4862297099063, 93.9762304961932 25.4481766908238, 84.0142835152758 24.5766192633472, 84.8858409427524 14.6146722824297))
 *    3   1   POLYGON ((84.0142835152758 24.5766192633472, 93.9762304961932 25.4481766908238, 93.1046730687167 35.4101236717412, 83.1427260877992 34.5385662442647, 84.0142835152758 24.5766192633472))
 *    3   2   POLYGON ((83.1427260877992 34.5385662442647, 93.1046730687167 35.4101236717412, 92.2331156412401 45.3720706526587, 82.2711686603226 44.5005132251821, 83.1427260877992 34.5385662442647))
 *    3   3   POLYGON ((82.2711686603226 44.5005132251821, 92.2331156412401 45.3720706526587, 91.3615582137635 55.3340176335761, 81.399611232846 54.4624602060996, 82.2711686603226 44.5005132251821))
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
            SET @v_tile = [$(owner)].[STRotate]( 
                             @v_tile,
                             @p_point.STX,
                             @p_point.STY,
                             @p_rAngle,
                             15,15
                          );
         INSERT INTO @table VALUES(@v_col,@v_row,@v_tile);
         SET @v_row = @v_row + 1;
       END;
       SET @v_col = @v_col + 1;
     END;
     RETURN;
   END;
End
GO

PRINT 'Testing [$(owner)].[STTileGeomByPoint] ...';
GO

-- Top-left position of grid: 55.634269978244582 12.051864414446955
-- Rotation: 5.2 degrees
-- Number of grid rows: 14
-- Number of grid columns: 28
-- Grid cell width: 10 meters
-- Grid cell height: 10 meters

use DEVDB
go

select col,row,geom.STAsText() as tile
  from [$(owner)].[STTileGeomByPoint] ( 
         geometry::Point(55,12,0),
         /*@p_numTileX*/ 4,
         /*@p_numTileY*/ 4,
         /*@p_TileX   */ 10,
         /*@p_TileY   */ 10,
         /*@p_rAngle  */ 5.2
        ) as t;
GO

QUIT
GO
