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
  @p_rAngle     float,
  @p_AsPoint    bit
)
returns @table table
(
  col  Int,
  row  Int,
  geom geography
)
AS
/****m* TILING/STTileGeogByPoint (2008)
 *  NAME
 *    STTileGeogByPoint -- Creates grid of tiles in geographic space.
 *  SYNOPSIS
 *    Function STTileGeogByPoint (
 *      @p_numTileX integer,
 *      @p_numTileY integer,
 *      @p_TileX      float,
 *      @p_TileY      float,
 *      @p_rAngle     float,
 *      @p_AsPoint      bit
 *    )
 *    Returns @table table
 *    (
 *      col  Int,
 *      row  Int,
 *      geom geometry
 *    )
 *  INPUTS
 *    @p_point  (geography) -- Starting Point for grid (Upper Left)
 *    @p_numTileX (integer) -- Number of tiles in X (longitude) direction
 *    @p_numTileY (integer) -- Number of tiles in Y (latitude) direction
 *    @p_TileX      (float) -- Size of a Tile's X dimension in real world units.
 *    @p_TileY      (float) -- Size of a Tile's Y dimension in real world units.
 *    @p_rAngle     (float) -- Optional rotation angle from North.
 *    @p_AsPoint      (bit) -- Return Tile as point or polygon
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      col  Int      -- The column reference for a tile
 *      row  Int      -- The row reference for a tile
 *      geom geometry -- The polygon geometry covering the area of the Tile.
 *    )
 *  EXAMPLE
 *    select col,row, geom.STAsText() as tileGeom
 *      from [$(Owner)].[STTileGeogByPoint] ( 
 *                 geography::Point(55.634269978244,12.051864414446,4326),
 *                 2,2,
 *                 10.0, 15.0,
 *                 22.5
 *            ) as t;
 *     GO
 *
 *    col row tileGeom
 *    0   0   POLYGON ((12.052084452911 55.634218419749, 12.052304491086 55.634166861254, 12.052365253079 55.634249843067, 12.052145214983 55.634301401561, 12.052084452911 55.634218419749))
 *    0   1   POLYGON ((12.052145214983 55.634301401561, 12.052365253624 55.634249843067, 12.052426015745 55.634332824878, 12.052205977184 55.634384383372, 12.052145214983 55.634301401561))
 *    1   0   POLYGON ((12.052304490797 55.63416686086, 12.052524528684 55.634115302364, 12.052585290597 55.634198284177, 12.05236525279 55.634249842672, 12.052304490797 55.63416686086))
 *    1   1   POLYGON ((12.05236525279 55.634249842672, 12.052585291142 55.634198284177, 12.052646053184 55.63428126599, 12.052426014912 55.634332824484, 12.05236525279 55.634249842672))
 *  NOTES
 *    Depends on [$(CogoOwner)].[STDirectVincenty]
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
    @v_rAngle   float,
    @v_wkt     nvarchar(max),
    @v_point1  geography,
    @v_point2  geography,
    @v_point3  geography,
    @v_point4  geography,
    @v_tile    geography;

  If ( @p_point is null )
    Return;
  If ( @p_point.STGeometryType() <> 'Point' )
    Return;
  SET @v_rAngle = COALESCE(@p_rAngle,0.0);
  SET @v_srid   = @p_point.STSrid;
  SET @v_loCol  = 0;
  SET @v_hiCol  = @p_numTileX - 1;
  SET @v_loRow  = 0;
  SET @v_hiRow  = @p_numTileY - 1;
  SET @v_col    = @v_loCol;
  SET @v_point1 = @p_point; -- First/Fifth point in exterior ring (CCW)
  WHILE ( @v_col <= @v_hiCol )
  BEGIN
    SET @v_row = @v_loRow;
    SET @v_point1 = [$(CogoOwner)].[STDirectVincenty](@p_point,@v_rAngle+90.0,@p_TileY*(@v_col+1.0));
    WHILE ( @v_row <= @v_hiRow )
    BEGIN
      -- Generate Polygon Points in CCW order
      SET @v_point2 = [$(CogoOwner)].[STDirectVincenty](@v_point1,@v_rAngle+90.0,@p_TileY);
      -- Second point in exterior ring
      SET @v_point3 = [$(CogoOwner)].[STDirectVincenty](@v_point2,@v_rAngle,@p_TileX);
      -- Second point in exterior ring
      SET @v_point4 = [$(CogoOwner)].[STDirectVincenty](@v_point1,@v_rAngle,@p_TileX);
	  IF ( @p_AsPoint=0 )
        SET @v_wkt = 'POLYGON((' + 
              CONVERT(varchar(30),CAST(@v_point1.Long as DECIMAL(24,12))) + ' ' + 
              CONVERT(varchar(30),CAST(@v_point1.Lat  as DECIMAL(24,12))) + ',' +
              CONVERT(varchar(30),CAST(@v_point2.Long as DECIMAL(24,12))) + ' ' + 
              CONVERT(varchar(30),CAST(@v_point2.Lat  as DECIMAL(24,12))) + ',' +
              CONVERT(varchar(30),CAST(@v_point3.Long as DECIMAL(24,12))) + ' ' + 
              CONVERT(varchar(30),CAST(@v_point3.Lat  as DECIMAL(24,12))) + ',' +
              CONVERT(varchar(30),CAST(@v_point4.Long as DECIMAL(24,12))) + ' ' + 
              CONVERT(varchar(30),CAST(@v_point4.Lat  as DECIMAL(24,12))) + ',' +
              CONVERT(varchar(30),CAST(@v_point1.Long as DECIMAL(24,12))) + ' ' + 
              CONVERT(varchar(30),CAST(@v_point1.Lat  as DECIMAL(24,12))) + '))'
      ELSE
        SET @v_wkt = 'POINT(' + 
              CONVERT(varchar(30),CAST((@v_point1.Long + @v_point3.Long) / 2.0 as DECIMAL(24,12))) + ' ' + 
              CONVERT(varchar(30),CAST((@v_point1.Lat  + @v_point3.Lat)  / 2.0 as DECIMAL(24,12))) + ')';
      SET @v_tile = geography::STGeomFromText(@v_WKT,@v_srid);
      INSERT INTO @table VALUES (
         @v_col,
         @v_row,
         @v_tile 
      );
      -- Move to next First/Fifth point in exterior ring (CCW)
      SET @v_point1 = @v_point4;
      SET @v_row    = @v_row + 1;
    END;
    SET @v_col = @v_col + 1;
  END;
  RETURN;
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


