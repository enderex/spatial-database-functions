USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STTiler]') 
    AND xtype IN (N'P')
)
BEGIN
  DROP PROCEDURE [$(owner)].[STTiler];
  PRINT 'Dropped [$(owner)].[STTiler] ...';
END;
GO

PRINT 'Creating [$(owner)].[STTiler] ...';
GO

CREATE PROCEDURE [$(owner)].[STTiler]
(
  @p_ll_x      float,
  @p_ll_y      float,
  @p_ur_x      float,
  @p_ur_y      float,
  @p_TileX     float,
  @p_TileY     float,
  @p_rx        float,
  @p_ry        float,
  @p_rangle    float
  @p_Srid      Int,
  @p_out_table nvarchar(128),
  @p_geography Int = 1
)
AS
/****f* TILING/STTiler (2012)
 *  NAME
 *    STTiler -- Covers supplied envelope (LL/UR) with a mesh of tiles of size TileX and TileY,
 *               and writes them to a new table created with the supplied name.
 *  SYNOPSIS
 *    Procedure STTiler (
 *               @p_ll_x      float,
 *               @p_ll_y      float,
 *               @p_ur_x      float,
 *               @p_ur_y      float,
 *               @p_TileX     float,
 *               @p_TileY     float,
 *               @p_rx        float,
 *               @p_ry        float,
 *               @p_rangle    float
 *               @p_srid      int,
 *               @p_out_table nvarchar(128),
 *               @p_geography Int = 1
 *             )
 *  USAGE
 *    EXEC [$(owner)].[STTiler] 0, 0, 1000, 1000, 250, 250, 0, 0, 0, 0, '[$(owner)].GridLL', 0;
 *    GO
 *    SELECT COUNT(*) as tableCount FROM [$(owner)].[GridLL];
 *    GO
 *
 *    tableCount
 *    ----------
 *    16
 *    
 *  DESCRIPTION
 *    Procedure that takes a spatial extent (LL/UR), computes the number of tiles that cover it and
 *    The number of columns and rows that cover this area is calculated using @p_TileX/@p_TileY which
 *    are in @p_SRID units.
 *    All rows and columns are visited, with polygons being created that represent each tile.
 *    If @p_rx/@p_ry/@p_rangle are supplied, the resultant grid is rotated around @p_rx and @p_ry angle @p_angle.
 *  INPUTS
 *    @p_ll_x         (float) - Spatial Extent's lower left X/Longitude ordinate.
 *    @p_ll_y         (float) - Spatial Extent's lower left Y/Latitude  ordinate.
 *    @p_ur_x         (float) - Spatial Extent's upper right X/Longitude ordinate.
 *    @p_ur_y         (float) - Spatial Extent's upper right Y/Latitude  ordinate.
 *    @p_TileX        (float) - Size of a Tile's X dimension in decimal degrees.
 *    @p_TileY        (float) - Size of a Tile's Y dimension in decimal degrees.
 *    @p_rX           (float) - X ordinate of rotation point.
 *    @p_rY           (float) - Y ordinate of rotation point.
 *    @p_angle        (float) - Rotation angle expressed in decimal degrees between 0 and 360.
 *    @p_srid           (int) - Geographic SRID (default is 4326)
 *    @p_out_table (nvarchar) - Name of table to hold tiles. Can be expressed as DB.OWNER.OBJECT.
 *    @p_geography      (int) - If 1 (True) column in table will be geography; if 0, geometry.
 *  RESULT
 *    A Table with the name @p_out_table is created with this structure:
 *    Create Table + @p_out_table + 
 *    ( 
 *      gid  Int Identity(1,1) not null, 
 *      geom geometry   -- If @p_geography = 0
 *      geog geography  -- If @p_geography = 1
 *    );
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *    Simon Greener - October  2019 - Added rotation capability
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
begin
   DECLARE
     @v_srid       Int,
     @v_obj_type   varchar(20),
     @v_sql        nvarchar(MAX),
     @v_db         nvarchar(128),
     @v_owner      nvarchar(128),
     @v_object     nvarchar(128),
     @v_geo        nvarchar(128),
     @v_geo_type   nvarchar(128),
     @v_start_time datetime,
     @v_count      BigInt = 0,
     @v_loCol      int,
     @v_hiCol      int,
     @v_loRow      int,
     @v_hiRow      int,
     @v_col        int,
     @v_row        int,
     @v_wkt        nvarchar(max),
     @v_tile       geometry;
   Begin
     SET @v_srid     = ISNULL(@p_srid,4326);
     SET @v_geo      = 'geom';
     SET @v_geo_type = 'geometry';
     If ( ISNULL(@p_geography,1) = 1 )
     BEGIN
       SET @v_geo_type = 'geography';
       SET @v_geo      = 'geog';
     END;
    
     -- If @p_out_table name is fully qualified... we need to split it
     --
     SET @v_object = PARSENAME(@p_out_table,1);
     SET @v_owner  = CASE WHEN PARSENAME(@p_out_table,2) IS NULL THEN 'dbo'     ELSE PARSENAME(@p_out_table,2) END;
     SET @v_db     = CASE WHEN PARSENAME(@p_out_table,3) IS NULL THEN DB_NAME() ELSE PARSENAME(@p_out_table,3) END;
    
     -- Check if object exists with a geography/geometry
     -- NOTE: If table_catalog of table is different from current DB_NAME we need to query
     -- The [INFORMATION_SCHEMA] of that database via dynamic SQL
     --
     SET @v_sql = N'SELECT @object_type = a.[TABLE_TYPE]
                      FROM ' + @v_db + N'.[INFORMATION_SCHEMA].[TABLES] a
                     WHERE a.[TABLE_CATALOG] = @db_in
                       AND a.[TABLE_SCHEMA]  = @owner_in
                       AND a.[TABLE_NAME]    = @object_in';
     BEGIN TRY
       EXEC sp_executesql @query = @v_sql, 
                          @params = N'@object_type nvarchar(128) OUTPUT, @db_in nvarchar(128), @owner_in nvarchar(128), @object_in nvarchar(128)', 
                          @object_type = @v_obj_type OUTPUT, 
                          @db_in       = @v_db, 
                          @owner_in    = @v_owner, 
                          @object_in   = @v_object;
     END TRY
     BEGIN CATCH
       Print 'Could not verify that @p_out_table does not exist. Reason = ' + ERROR_MESSAGE();
       Return;
     END CATCH

     If ( @v_obj_type is not null )
     Begin
       Print 'Table/View with name ' + @p_out_table + ' must not exist.';
       Return;
     End;
    
     -- Create Table
     --
     SET @v_sql = N'Create Table ' + @p_out_table + 
                  N' ( gid Int Identity(1,1) not null, ' +
                  N' ' + @v_geo +N' ' + @v_geo_type +
                  N' )';
     BEGIN TRY
       EXEC sp_executesql @query = @v_sql;
     END TRY
     BEGIN CATCH
       Print 'Could not create output grid table ' + @p_out_table + '. Reason = ' + ERROR_MESSAGE();
       Return;
     END CATCH
    
     SET @v_start_time = getdate();
     SET @v_loCol = FLOOR(   @p_LL_X / @p_TileX );
     SET @v_hiCol = CEILING( @p_UR_X / @p_TileX ) - 1;
     SET @v_loRow = FLOOR(   @p_LL_Y / @p_TileY );
     SET @v_hiRow = CEILING( @p_UR_Y / @p_TileY ) - 1;
     SET @v_col = @v_loCol;
     WHILE ( @v_col <= @v_hiCol )
     BEGIN
       BEGIN TRANSACTION thisColumn;
       SET @v_row = @v_loRow;
       WHILE ( @v_row <= @v_hiRow )
       BEGIN
         SET @v_count = @v_count + 1;
         SET @v_wkt = 'POLYGON((' + 
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(((@v_col * @p_TileX) + @p_TileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(((@v_col * @p_TileX) + @p_TileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(((@v_row * @p_TileY) + @p_TileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(((@v_row * @p_TileY) + @p_TileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + '))';
         SET @v_tile = geometry::STGeomFromText(@v_WKT,@v_srid);
         IF ( @p_rx is not null and @p_ry is not null and COALESCE(@p_angle,0) <> 0 ) 
            SET @v_tile = [$(owner)].[STRotate]( @v_tile, @p_rx, @p_ry, @p_angle, 15, 15 );
         SET @v_wkt = @v_tile.STAsText();
         SET @v_sql = N'INSERT INTO ' + @p_out_table + N' (' + @v_geo + N') ' +
                      N'VALUES(' + @v_geo_type + N'::STPolyFromText(@IN_WKT,@IN_Srid))';
         BEGIN TRY
           EXEC sp_executesql @query   = @v_sql, 
                              @params  = N'@in_WKT nvarchar(max), @IN_SRID Int', 
                              @IN_WKT  = @v_wkt,
                              @IN_SRID = @v_SRID;
         END TRY
         BEGIN CATCH
           Print 'Could not insert grid record into ' + @p_out_table + '. Reason = ' + ERROR_MESSAGE();
           Return;
         END CATCH
         SET @v_row = @v_row + 1;
       END;
       COMMIT TRANSACTION thisColumn;
       SET @v_col = @v_col + 1;
     END;
     PRINT 'Created ' + CAST(@v_count as varchar(10)) + ' grids in: ' + RTRIM(CAST(DATEDIFF(ss,@v_start_time,GETDATE()) as char(10))) + ' seconds!';
     RETURN;
   END;
End
Go

Print 'Testing [$(owner)].[STTiler] ...';
GO

DROP TABLE IF EXISTS [$(owner)].[GridLL]
exec [$(owner)].[STTiler] 0, 0, 1000, 1000, 250, 250, 0,0,0, 0, '[$(owner)].GridLL', 0
SELECT COUNT(*) as tableCount FROM [$(owner)].[GridLL]
SELECT gid, geom.STAsText() FROM [$(owner)].[GridLL]
GO

DROP TABLE IF EXISTS [$(owner)].[GridLL]
exec [$(owner)].[STTiler] 0, 0, 1000, 1000, 250, 250, 0,0,45, 0, '[$(owner)].GridLL', 0
SELECT COUNT(*) as tableCount FROM [$(owner)].[GridLL]
SELECT gid, geom.STAsText() FROM [$(owner)].[GridLL]
GO

QUIT
GO

