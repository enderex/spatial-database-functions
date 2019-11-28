SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STTileByNumGrids]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STTileByNumGrids];
  Print 'Dropped [$(owner)].[STTileByNumGrids] ...';
END;
GO

Print 'Creating [$(owner)].[STTileByNumGrids] ...';
GO

CREATE FUNCTION [$(owner)].[STTileByNumGrids] (
  @p_geometry  geometry,
  @p_NumGridsX integer,
  @p_NumGridsY integer, 
  @p_rPoint    geometry, -- Point(rx,ry)
  @p_rAngle    float,
  @p_AsPoint   bit
)
Returns @table table
(
  col  Int,
  row  Int,
  geom geometry 
)
as
/****f* TILING/STTileByNumGrids (2008)
 *  NAME
 *    STTileByNumGrids -- Covers supplied geometry object with a mesh of a specific number of times in X and Y.
 *  SYNOPSIS
 *    Function [$(owner)].[STTileByNumGrids] (
 *      @p_geometry  geometry,
 *      @p_NumGridsX integer,
 *      @p_NumGridsY integer, 
 *      @p_rPoint    geometry, -- Point(rx,ry)
 *      @p_rAngle    float,
 *      @p_AsPoint   bit
 *    )
 *    Returns @table table
 *    (
 *      col  Int,
 *      row  Int,
 *      geom geometry
 *    )
 *  DESCRIPTION
 *    Computes Envelope/MBR of supplied geometry object. Then computes size of individual tile
 *    by dividing the XY extents of the computed MBR by the supplied number of tiles in X (columns) and Y (rows).
 *    All rows and columns are visited, with polygons being created that represent each tile using
 *    the compute size in X and Y.
 *    If @p_rPoint (Geometry Point only) and @p_rAngle (whole circle bearing) are supplied, the resultant grid is rotated around the @p_rPoint and @p_rAngle angle.
 *  INPUTS
 *    @p_geometry (geometry) - Any geometry type (except Point) over which a grid of tiles is produced.
 *    @p_NumGridsX (integer) - The number of grids in the X direction (columns)
 *    @p_NumGridsY (integer) - The number of grids in the Y direction (rows)
 *    @p_rPoint   (geometry) - Rotation Point.
 *    @p_rAngle      (float) - Rotation angle expressed in decimal degrees between 0 and 360.
 *    @p_AsPoint       (bit) - Return tile as point or polygon
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      col  Int      -- The column reference for a tile
 *      row  Int      -- The row reference for a tile
 *      geom geometry -- The polygon geometry covering the area of the Tile.
 *    )
 *  EXAMPLE
 *    SELECT row_number() over (order by col, row) as tileId,
 *           col,
 *           row,
 *           geom.STAsText() as Tile
 *      FROM [$(owner)].[STTileByNumGrids](
 *              geometry::STGeomFromText('LINESTRING(12.160367016481 55.474850814352,12.171397605408 55.478619145167)',0),
 *                2, 2,
 *              geometry::STGeomFromText('POINT(12.160367016481 55.474850814352)',0),
 *              45,0
 *           ) as t;
 *    GO
 *
 *    tileId col  row   Tile
 *    1      2204 29442 POLYGON ((12.1557 55.4736, 12.1612 55.4736, 12.1612 55.4755, 12.1557 55.4755, 12.1557 55.4736))
 *    2      2204 29443 POLYGON ((12.1557 55.4755, 12.1612 55.4755, 12.1612 55.4774, 12.1557 55.4774, 12.1557 55.4755))
 *    3      2205 29442 POLYGON ((12.1612 55.4736, 12.1667 55.4736, 12.1667 55.4755, 12.1612 55.4755, 12.1612 55.4736))
 *    4      2205 29443 POLYGON ((12.1612 55.4755, 12.1667 55.4755, 12.1667 55.4774, 12.1612 55.4774, 12.1612 55.4755))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - October 2011 - Ported from Oracle to TSQL.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
   DECLARE
     @v_wkt       nvarchar(max),
     @v_NumGridsX float,
     @v_NumGridsY float,
     @v_col       int,
     @v_row       int,
     @v_rPoint    geometry,
     @v_tile      geometry,
     @v_llx       float,
     @v_lly       float,
     @v_urx       float,
     @v_ury       float,
     @v_width     float,
     @v_height    float,
     @v_loCol     integer,
     @v_hiCol     integer,
     @v_loRow     integer,
     @v_hiRow     integer;
Begin
     IF ( @p_geometry is null ) 
       Return;

     IF ( COALESCE(@p_NumGridsX,0) = 0 OR COALESCE(@p_NumGridsY,0) = 0 )
       Return;

     SET @v_NumGridsX = CAST(@v_NumGridsX as float);
     SET @v_NumGridsY = CAST(@v_NumGridsY as float);

     IF ( @p_rPoint is not null and @p_rPoint.STGeometryType() <> 'Point') 
       SET @v_rPoint = @p_rPoint.STPointN(1);

     SELECT TOP 1
            @v_llx = minx,
            @v_lly = miny,
            @v_urx = maxx,
            @v_ury = maxy
       FROM [$(owner)].[STGeometry2MBR] ( @p_geometry );

     SET @v_width  = (@v_urx - @v_llx) / @p_NumGridsX;
     SET @v_height = (@v_ury - @v_lly) / @p_NumGridsY;
     SET @v_loCol  = ROUND(   @v_llx / @v_width,0,1 );
     SET @v_hiCol  = CEILING( @v_urx / @v_width  ) - 1;
     SET @v_loRow  = ROUND(   @v_lly / @v_height,0,1 );
     SET @v_hiRow  = CEILING( @v_ury / @v_height ) - 1;
     SET @v_col    = @v_loCol;
     WHILE ( @v_col < @v_hiCol )
     BEGIN
       SET @v_row = @v_loRow;
       WHILE ( @v_row < @v_hiRow )
       BEGIN
         SET @v_wkt = 'POLYGON((' + 
                 CONVERT(varchar(100), ROUND(@v_col * @v_width,6))                + ' ' + 
                 CONVERT(varchar(100), ROUND(@v_row * @v_height,6))                + ',' +
                 CONVERT(varchar(100), ROUND(((@v_col * @v_width) + @v_width),6)) + ' ' + 
                 CONVERT(varchar(100), ROUND(@v_row * @v_height,6))                + ',' +
                 CONVERT(varchar(100), ROUND(((@v_col * @v_width) + @v_width),6)) + ' ' + 
                 CONVERT(varchar(100), ROUND(((@v_row * @v_height) + @v_height),6)) + ',' +
                 CONVERT(varchar(100), ROUND(@v_col * @v_width,6))                + ' ' + 
                 CONVERT(varchar(100), ROUND(((@v_row * @v_height) + @v_height),6)) + ',' +
                 CONVERT(varchar(100), ROUND(@v_col * @v_width,6))                + ' ' + 
                 CONVERT(varchar(100), ROUND(@v_row * @v_height,6))                + '))';
         SET @v_tile = geometry::STGeomFromText(@v_WKT,@p_geometry.STSrid);
         IF ( @v_rPoint is not null and @p_rAngle <> 0 ) 
            SET @v_tile = [$(owner)].[STRotate]( 
                                   @v_tile,
                                   @p_rPoint.STX,
                                   @p_rPoint.STX,
                                   @p_rangle,
                                   15,
                                   15
                                );

         INSERT INTO @table (   col,   row,geom)
                     VALUES (@v_col,@v_row,
                             case when @p_AsPoint=1 then @v_tile.STCentroid() else @v_tile end);
         SET @v_row = @v_row + 1;
       END;
       SET @v_col = @v_col + 1;
     END;
     RETURN;
   END;
End
GO

