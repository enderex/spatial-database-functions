BEGIN
  IF OBJECT_ID(DB_NAME()+'.$(owner).geometry_columns') IS NULL
   BEGIN
    PRINT 'GEOMETRY_COLUMMS Table does not exist, creating it now';
    CREATE TABLE [$(owner)].[geometry_columns] (
       [f_table_catalog]    [varchar](128) NOT NULL
      ,[f_table_schema]    [varchar](128) NOT NULL
      ,[f_table_name]      [varchar](256) NOT NULL
      ,[f_geometry_column] [varchar](256) NOT NULL
      ,[coord_dimension]   [int]          NOT NULL
      ,[srid]              [int]          NOT NULL
      ,[geometry_type]     [varchar](30)  NOT NULL
     CONSTRAINT [geometry_columns_pk] PRIMARY KEY CLUSTERED (
         [f_table_catalog] ASC
         ,[f_table_schema] ASC
         ,[f_table_name] ASC
         ,[f_geometry_column] ASC
     ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY]
  END
  PRINT  'GEOMETRY_COLUMNS Table already exists, no further action necessary';
END;
GO

DROP PROCEDURE [$(owner)].[Populate_Geometry_Columns];
GO

CREATE PROCEDURE [$(owner)].[Populate_Geometry_Columns] 
  @schema VARCHAR(MAX) = '', 
  @table VARCHAR(MAX) = ''
AS
/* =============================================
* Author:      Chris Tippett
* Create date: 2014-08-12
* Description: Detect columns with geometry datatypes and add them to [$(owner)].[geometry_columns]
* Author       Simon Greener
* Modify Date: 2019-12-4
* Description: Minor formatting, installer aware, added coord_dim calculation for 2012+.
* =============================================
*/
BEGIN
  SET NOCOUNT ON;
   
  DECLARE
     @db_name        VARCHAR(MAX)
    ,@tbl_schema     VARCHAR(MAX)
    ,@tbl_name       VARCHAR(MAX)
    ,@tbl_oldname    VARCHAR(MAX)
    ,@clm_name       VARCHAR(MAX)
    ,@geom_srid      INT
    ,@geom_coord_dim INT
    ,@geom_type      VARCHAR(MAX)
    ,@v_sql          VARCHAR(MAX)
    ,@msg            VARCHAR(MAX);
  
  SET @msg = '--------------------------------------------------'+CHAR(10)
  SET @msg += 'FINDING GEOMETRY DATATYPES'
  RAISERROR(@msg,0,1) WITH NOWAIT
         
  SET @schema = NULLIF(@schema,'$(owner)')
  IF ( @table IS NULL )
    RETURN;
   
  -- setup temporary table to contain the SRID and type of geometry
  IF OBJECT_ID(DB_NAME()+'.$(owner).#geom_info') IS NULL
  BEGIN
    CREATE TABLE [$(owner)].[#geom_info] (GEOM_SRID INT, GEOM_TYPE VARCHAR(50), GEOM_COORD_DIM INT, Count_Type INT);
  END;
   
  DECLARE column_cursor 
   CURSOR 
      FOR
   SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
     FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE DATA_TYPE     IN ('geometry','geography')
      AND TABLE_CATALOG = DB_NAME()
      AND TABLE_SCHEMA  LIKE COALESCE(@schema,'%')
      AND TABLE_NAME    LIKE COALESCE(@table,'%')
    ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
       
  OPEN column_cursor
  FETCH NEXT FROM column_cursor INTO @db_name, @tbl_schema, @tbl_name, @clm_name;
   
  SET @msg = ' > Searching  ['+@db_name+'].['+@tbl_schema+'].['+@tbl_name+'] for geometry columns'
  RAISERROR(@msg,0,1) WITH NOWAIT
   
  IF @@FETCH_STATUS < 0
   BEGIN
    SET @msg = '    - No columns with geometry datatype found'
    RAISERROR(@msg,0,1) WITH NOWAIT
   END

  BEGIN TRY  
 
  WHILE @@FETCH_STATUS = 0
   BEGIN
      
    -- check whether column exists already in [geometry_columns]
    IF EXISTS (
     SELECT 1
       FROM [$(owner)].[geometry_columns]
       WHERE [f_table_catalog]   = @db_name 
         AND [f_table_schema]    = @tbl_schema 
         AND [f_table_name]      = @tbl_name 
         AND [f_geometry_column] = @clm_name
    )
     BEGIN
      SET @msg = '    - Geometry column "'+@clm_name+'" found and already exists in geometry_columns table'
      RAISERROR(@msg,0,1) WITH NOWAIT
     END
   
    ELSE
     BEGIN
       -- use dynamic sql to get srid and geometry type
	  SET @v_sql =
      'SELECT '+@clm_name+'.STSrid AS GEOM_SRID' +
            ','+@clm_name+'.MakeValid().STGeometryType() AS GEOM_TYPE' +
            ',(2 + a.'+@clm_name+'.HasZ + a.'+@clm_name+'.HasM) as GEOM_COORD_DIM' +
            ',COUNT(*) AS Count_Type ' +
           ' FROM '+@db_name+'.'+@tbl_schema+'.'+@tbl_name+' as a' +
          ' WHERE '+@clm_name+'.STIsValid() = 1' +
          ' GROUP BY '+@clm_name+'.STSrid' +
           ',(2 + a.'+@clm_name+'.HasZ + a.'+@clm_name+'.HasM)'+
                  ','+@clm_name+'.MakeValid().STGeometryType()';
      RAISERROR(@v_sql,0,1) WITH NOWAIT

      INSERT INTO [$(owner)].[#geom_info] EXEC(@v_sql);
     
      IF @@ROWCOUNT > 1
       BEGIN
        SET @msg = '    - WARNING: More than 1 geometry type detected in column. Taking most frequent type for column definition'
        RAISERROR(@msg,0,1) WITH NOWAIT
       END
  
      -- assign srid and geometry type to variables
      SELECT TOP 1
             @geom_srid      = a.GEOM_SRID
            ,@geom_type      = UPPER(a.GEOM_TYPE)
            ,@geom_coord_dim = a.GEOM_COORD_DIM
        FROM [$(owner)].[#geom_info] as a
       ORDER BY Count_Type DESC;
   
      -- reset @geom_info contents
      DELETE FROM [$(owner)].[#geom_info];
  
      -- insert into [geometry_columns] if the column doesn't already exist
      SET @msg  = '    - Adding column "'+@clm_name+'" to geometry_columns table'+CHAR(10)
      SET @msg += '       + geometry type: '+@geom_type+CHAR(10)
      SET @msg += '       + srid: '+CAST(@geom_srid AS VARCHAR(10))
      RAISERROR(@msg,0,1)
   
      INSERT INTO $(owner).geometry_columns (
        [f_table_catalog]
       ,[f_table_schema]
       ,[f_table_name]
       ,[f_geometry_column]
       ,[coord_dimension]
       ,[srid]
       ,[geometry_type]
      ) VALUES (
       @db_name, 
       @tbl_schema, 
       @tbl_name, 
       @clm_name, 
       @geom_coord_dim, 
       @geom_srid, 
       @geom_type); 
     END;

    -- iterate cursor
    FETCH NEXT FROM column_cursor INTO @db_name, @tbl_schema, @tbl_name, @clm_name;
   
    -- check whether the cursor is looping through another column of the previous table (purely for messaging purposes)
    IF @tbl_name <> @tbl_oldname
     BEGIN
      SET @msg = ' > Searching  ['+@db_name+'].['+@tbl_schema+'].['+@tbl_name+'] for geometry columns';
      RAISERROR(@msg,0,1) WITH NOWAIT;
     END
    SET @tbl_oldname = @tbl_name;
   END;
   
   CLOSE column_cursor;
   DEALLOCATE column_cursor;
   DROP TABLE [$(owner)].[#geom_info];

  END TRY  
  BEGIN CATCH  
   CLOSE column_cursor;
   DEALLOCATE column_cursor;
   RAISERROR('Error Caught',0,1) WITH NOWAIT
  END CATCH;

  SET @msg = '--------------------------------------------------'+CHAR(10)
  SET @msg += 'Done!'+CHAR(10)
  SET @msg += '--------------------------------------------------'
  RAISERROR(@msg,0,1) WITH NOWAIT
END;
GO

exec [$(owner)].[Populate_Geometry_Columns] '$(owner)', 'GridLL'
exec [$(owner)].[Populate_Geometry_Columns] '$(owner)', 'locality'
exec [$(owner)].[Populate_Geometry_Columns] '$(owner)', 'EDS_POINT_NOV'
exec [$(owner)].[Populate_Geometry_Columns] '$(owner)', 'gps_observations'
GO

select * from [$(owner)].[geometry_columns];

select geog.STSrid from $(owner).locality;
