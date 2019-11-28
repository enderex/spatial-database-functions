SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: Cogo: $(CogoOwner) Owner: $(Owner)';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(Owner)].[STTileGeogByPoint]') 
       AND xtype IN (N'TF')
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
  @p_point    geography,
  @p_origin   varchar(2),
  @p_numTileX integer,
  @p_numTileY integer,
  @p_TileX    float,
  @p_TileY    float,
  @p_rAngle   float,
  @p_AsPoint  bit
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
 *      @p_point    geography,
 *      @p_origin   varchar(2),
 *      @p_numTileX integer,
 *      @p_numTileY integer,
 *      @p_TileX    float,
 *      @p_TileX    float,
 *      @p_rAngle   float,
 *      @p_AsPoint  bit
 *    )
 *    Returns @table table
 *    (
 *      col  Int,
 *      row  Int,
 *      geom geometry
 *    )
 *  INPUTS
 *    @p_point  (geography) -- Starting Point for grid (Upper Left)
 *    @p_origin   (varchar) -- Position of point wrt grid: LL,UL,LR,UR
 *    @p_numTileX (integer) -- Number of tiles in X (longitude) direction
 *    @p_numTileY (integer) -- Number of tiles in Y (latitude) direction
 *    @v_TileX      (float) -- Size of a Tile's X dimension in real world units along parallel of Latitude (ie X distance)
 *    @v_TileY      (float) -- Size of a Tile's Y dimension in real world units along meridian of Longitude (ie Y distance)
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
 *    select col,row, geom.STAsText() as tileGeog
 *      from [$(Owner)].[STTileGeogByPoint] ( 
 *                 geography::Point(55.634269978244,12.051864414446,4326),
 *                 'LL',
 *                 2,2,
 *                 10.0, 15.0,
 *                 22.5
 *            ) as t;
 *     GO
 *
 *    col row tileGeog
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
    @v_origin  varchar(2),
    @v_srid    Int,
    @v_loCol   int,
    @v_hiCol   int,
    @v_loRow   int,
    @v_hiRow   int,
    @v_col     int,
    @v_row     int,
    @v_rAngle  float,
    @v_TileMetersAlongLong float,
    @v_TileMetersAlongLat  float,
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
  SET @v_origin = SUBSTRING(UPPER(COALESCE(@p_origin,'LL')),1,2);
  IF ( @v_origin not in ('LL','LR','UL','UR')) 
    return;
  SET @v_rAngle = COALESCE(@p_rAngle,0.0);
  SET @v_TileMetersAlongLat  = @p_TileX;
  SET @v_TileMetersAlongLong = @p_TileY;
  SET @v_srid   = @p_point.STSrid;
  SET @v_loCol  = 0;
  SET @v_hiCol  = @p_numTileX - 1;
  SET @v_loRow  = 0;
  SET @v_hiRow  = @p_numTileY - 1;
  SET @v_col    = @v_loCol;
  WHILE ( @v_col <= @v_hiCol )
  BEGIN
    SET @v_row = @v_loRow;
	-- Generate polygon points in CCW order
	-- 1st point in tile exterior ring
    SET @v_point1 = case @v_origin 
                    when 'LL' then [$(cogoowner)].[STDirectVincenty](@p_point,@v_rAngle+90.0, @v_TileMetersAlongLat*@v_col)
                    when 'UL' then [$(cogoowner)].[STDirectVincenty](@p_point,@v_rAngle+90.0, @v_TileMetersAlongLat*@v_col)
                    when 'LR' then [$(cogoowner)].[STDirectVincenty](@p_point,@v_rAngle+270.0,@v_TileMetersAlongLat*@v_col)
                    when 'UR' then [$(cogoowner)].[STDirectVincenty](@p_point,@v_rAngle+270.0,@v_TileMetersAlongLat*@v_col)
                    end;
    WHILE ( @v_row <= @v_hiRow )
    BEGIN
      -- 2nd Point in tile exterior ring
      SET @v_point2 = case @v_origin 
                      when 'LL' then [$(cogoowner)].[STDirectVincenty](@v_point1,@v_rAngle+ 90.0,@v_TileMetersAlongLat)
                      when 'UL' then [$(cogoowner)].[STDirectVincenty](@v_point1,@v_rAngle+180.0,@v_TileMetersAlongLong)
                      when 'LR' then [$(cogoowner)].[STDirectVincenty](@v_point1,@v_rAngle,      @v_TileMetersAlongLong)
                      when 'UR' then [$(cogoowner)].[STDirectVincenty](@v_point1,@v_rAngle+270.0,@v_TileMetersAlongLat)
                      end;
      -- 3rd point in tile exterior ring
      SET @v_point3 = case @v_origin 
                      when 'LL' then [$(cogoowner)].[STDirectVincenty](@v_point2,@v_rAngle,      @v_TileMetersAlongLong)
                      when 'UL' then [$(cogoowner)].[STDirectVincenty](@v_point2,@v_rAngle+90.0, @v_TileMetersAlongLat)
                      when 'LR' then [$(cogoowner)].[STDirectVincenty](@v_point2,@v_rAngle+270.0,@v_TileMetersAlongLat)
                      when 'UR' then [$(cogoowner)].[STDirectVincenty](@v_point2,@v_rAngle+180.0,@v_TileMetersAlongLong)
                      end;
      -- 4th point in exterior ring
      SET @v_point4 = case @v_origin 
                      when 'LL' then [$(cogoowner)].[STDirectVincenty](@v_point1,@v_rAngle,      @v_TileMetersAlongLong)
                      when 'UL' then [$(cogoowner)].[STDirectVincenty](@v_point1,@v_rAngle+90.0, @v_TileMetersAlongLat)
                      when 'LR' then [$(cogoowner)].[STDirectVincenty](@v_point1,@v_rAngle+270.0,@v_TileMetersAlongLat)
                      when 'UR' then [$(cogoowner)].[STDirectVincenty](@v_point1,@v_rAngle+180.0,@v_TileMetersAlongLong)
                      end;
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
      SET @v_point1 = case when @v_origin in ('LL','UR') then @v_point4 else @v_point2 end;
      SET @v_row    = @v_row + 1;
    END;
    SET @v_col = @v_col + 1;
  END;
  RETURN;
End;
GO
