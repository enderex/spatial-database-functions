USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: Cogo: $(CogoOwner) Owner: $(Owner)';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(Owner)].[STTileGeogByPoint]') 
    AND xtype IN (N'P')
)
BEGIN
  DROP FUNCTION [$(Owner)].[STTileGeogByPoint];
  PRINT 'Dropped [$(Owner)].[STTileGeogByPoint] ...';
END;
GO

PRINT 'Creating [$(Owner)].[STTileGeogByPoint] ...';
GO

CREATE FUNCTION [$(Owner)].[STTileGeogByPoint]
(
  @p_point  geography,
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
  geom geography
)
AS
/****f* TILING/STTileGeogByPoint (2008)
 *  NAME
 *    STTileGeogByPoint -- Creates mesh of tiles anchored to supplied point.
 *  SYNOPSIS
 *    Function STTileGeogByPoint (
 *               @p_point  geography,
 *               @p_numTileX integer,
 *               @p_numTileY integer,
 *               @p_TileX      float,
 *               @p_TileY      float,
 *               @p_rAngle     float
 *             )
 *    Returns @table table (
 *      col  Int,
 *      row  Int,
 *      geom geography
 *    )
 *  DESCRIPTION
 *    This function generates a mesh (grid) of tiles anchored to the supplied origin point.
 *    The mesh of tiles is controlled by three parameters:
 *      1 XY tile size in meters; 
 *      2 The number of tiles in X and Y direction;
 *      3 Optional rotation angle (around origin/anchor point)
 *    The supplied tile sizes are converted to decimal degree equivalents for the 
 *    latitude and longitude SRID supplied with @p_point.
 *  NOTES
 *    The conversion of meters to decimal degrees is accurate for an unrotated grid.
 *    If the grid is rotated the tiles will be slightly incorrect as a distance along a 
 *    parallel of latitude/meridian of longitude will be different for any side not 
 *    aligned to the parallel/meridian.
 *  PARAMETERS 
 *    @p_point (geography) -- Origin/Anchor point of mesh 
 *    @p_numTileX integer) -- Number of tiles in X direction
 *    @p_numTileY integer) -- Number of tiles in Y direction
 *    @p_TileX     (float) -- Size of a Tile's X dimension in real world units.
 *    @p_TileY     (float) -- Size of a Tile's Y dimension in real world units.
 *    @p_rAngle    (float) -- Rotation angle around anchor point.
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      col  Int       -- The column reference for a tile
 *      row  Int       -- The row reference for a tile
 *      geom geography -- The polygon geometry covering the area of the Tile.
 *    )
 *  EXAMPLE
 *    select col,row,geom.STAsText() as geog
 *      from [$(Owner)].[STTileGeogByPoint] ( 
 *             geography::Point(55.634269978244,12.051864414446,4326),
 *             2, 4,
 *             10, 10,
 *             45.0
 *            ) as t;
 *    GO
 *    
 *    col row geog
 *    0   0   POLYGON ((12.05186441 55.63426997, 12.0519279210201 55.6343334810201, 12.0518156474299 55.6344457546103, 12.0517521364098 55.6343822435902, 12.05186441 55.63426997))
 *    0   1   POLYGON ((12.0517521364098 55.6343822435902, 12.0518156474299 55.6344457546103, 12.0517033738396 55.6345580282006, 12.0516398628195 55.6344945171805, 12.0517521364098 55.6343822435902))
 *    0   2   POLYGON ((12.0516398628195 55.6344945171805, 12.0517033738396 55.6345580282006, 12.0515911002494 55.6346703017908, 12.0515275892293 55.6346067907707, 12.0516398628195 55.6344945171805))
 *    0   3   POLYGON ((12.0515275892293 55.6346067907707, 12.0515911002494 55.6346703017908, 12.0514788266585 55.6347825753817, 12.0514153156384 55.6347190643616, 12.0515275892293 55.6346067907707))
 *    1   0   POLYGON ((12.0519279210201 55.6343334810201, 12.0519914320395 55.6343969920395, 12.0518791584493 55.6345092656297, 12.0518156474299 55.6344457546103, 12.0519279210201 55.6343334810201))
 *    1   1   POLYGON ((12.0518156474299 55.6344457546103, 12.0518791584493 55.6345092656297, 12.051766884859 55.63462153922, 12.0517033738396 55.6345580282006, 12.0518156474299 55.6344457546103))
 *    1   2   POLYGON ((12.0517033738396 55.6345580282006, 12.051766884859 55.63462153922, 12.0516546112688 55.6347338128102, 12.0515911002494 55.6346703017908, 12.0517033738396 55.6345580282006))
 *    1   3   POLYGON ((12.0515911002494 55.6346703017908, 12.0516546112688 55.6347338128102, 12.0515423376779 55.6348460864011, 12.0514788266585 55.6347825753817, 12.0515911002494 55.6346703017908))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - October 2019 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
   DECLARE
     @v_srid  Int,
     @v_ll_x  float,
     @v_ll_y  float,
     @v_ur_x  float,
     @v_ur_y  float,
     @v_loCol int,
     @v_hiCol int,
     @v_loRow int,
     @v_hiRow int,
     @v_col   int,
     @v_row   int,
     @v_wkt   nvarchar(max),
     @v_metersX float,
     @v_metersY float,
     @v_geogX   float,
     @v_geogY   float,
     @v_point   geography,
     @v_tile    geography;
   Begin
     If ( @p_point is null )
       Return;
     If ( @p_point.STGeometryType() <> 'Point' )
       Return;
     SET @v_srid = @p_point.STSrid;
     -- Rows is Latitude/Y, Columns is Longitude/X
     -- Convert tileX/TileY meters to decimal degrees
     -- Compute meters for 1 degree
     SET @v_metersX = [$(CogoOwner)].[STGeographicDistance](
                         @p_point,
                         geography::Point(@p_point.Lat+0.1,@p_point.Long+0.1,@p_point.STSrid),
                         'Longitude'
                        );
     SET @v_metersY = [$(CogoOwner)].[STGeographicDistance](
                         @p_point,
                         geography::Point(@p_point.Lat+0.1,@p_point.Long+0.1,@p_point.STSrid),
                         'Latitude'
                        );
     IF ( COALESCE(@p_rAngle,0) = 0 ) 
     BEGIN
       SET @v_geogX = 0.1 / @v_metersX * @p_TileX;
       SET @v_geogY = 0.1 / @v_metersY * @p_TileY;
     END
     ELSE
     BEGIN
       -- Compute point which would be at the opposite end of the tile.
       SET @v_point   = [$(CogoOwner)].[STDirectVincenty]    (@v_point,@p_rAngle,@p_numTileY );
       -- Pretend this point is along the Y/Latitude axis and compute meters
       SET @v_metersY = [$(CogoOwner)].[STGeographicDistance](@p_point,@v_point,'Latitude');
       -- Now compute decimal degree equivalent of the side pretending it is along the axis
       SET @v_geogY   = (@v_point.Lat-@p_point.Lat) / @v_metersY * @p_TileY;
       -- Do same for X/Longitude.
       SET @v_point   = [$(CogoOwner)].[STDirectVincenty]    (@v_point,[$(CogoOwner)].[STNormalizeBearing](@p_rAngle+90.0),@p_numTileX );
       SET @v_metersX = [$(CogoOwner)].[STGeographicDistance](@p_point,@v_point,'Longitude');
       SET @v_geogX  = (@v_point.Long-@p_point.Long) / @v_metersX * @p_TileX;
     END;
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
                 CONVERT(varchar(30),CAST( @p_point.Long + (@v_col * @v_geogX)             as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST( @p_point.Lat  + (@v_row * @v_geogY)             as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST((@p_point.Long + (@v_col * @v_geogX) + @v_geogX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST( @p_point.Lat  + (@v_row * @v_geogY)             as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST((@p_point.Long + (@v_col * @v_geogX) + @v_geogX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST((@p_point.Lat  + (@v_row * @v_geogY) + @v_geogY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST( @p_point.Long + (@v_col * @v_geogX)             as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST((@p_point.Lat  + (@v_row * @v_geogY) + @v_geogY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST( @p_point.Long + (@v_col * @v_geogX)             as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST( @p_point.Lat  + (@v_row * @v_geogY)             as DECIMAL(24,12))) + '))';
         SET @v_tile = geography::STGeomFromText(@v_WKT,@v_srid);
         IF ( COALESCE(@p_rAngle,0) <> 0 ) 
            SET @v_tile = [$(Owner)].[STToGeography] (
                            [$(Owner)].[STRotate]( 
                                   [$(Owner)].[STToGeometry](@v_tile,@p_point.STSrid),
                                   @p_point.Long,
                                   @p_point.Lat,
                                   @p_rAngle,
                                   15,15
                                ),
                                @p_point.STSrid
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

PRINT 'Testing [$(Owner)].[STTileGeogByPoint] ...';
GO
-- Top-left position of grid: 55.634269978244582 12.051864414446955
-- Rotation: 45.0 degrees
-- Number of grid rows: 4
-- Number of grid columns: 4
-- Grid cell width: 10 meters
-- Grid cell height: 10 meters


select col,row,geom.STAsText() as geog
  from [$(Owner)].[STTileGeogByPoint] ( 
         geography::Point(55.634269978244582,12.051864414446955,4326),
         /*@p_numTileX*/ 2,
         /*@p_numTileY*/ 4,
         /*@p_TileX   */ 10,
         /*@p_TileY   */ 10,
         /*@p_rAngle  */ 45.0
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
         /*@p_rAngle  */ 5.2
        ) as t;
GO

QUIT
GO

