DROP TABLE [$(owner)].[geometry_columns];
GO

CREATE TABLE [$(owner)].[geometry_columns] (
   F_TABLE_SCHEMA    VARCHAR(30) NOT NULL,
   F_TABLE_NAME      VARCHAR(30) NOT NULL,
   F_GEOMETRY_COLUMN VARCHAR(30) NOT NULL,
   COORD_DIMENSION   INTEGER DEFAULT 2,
   SRID              INTEGER,
   TYPE              VARCHAR(30),
   UNIQUE(F_TABLE_SCHEMA, F_TABLE_NAME, F_GEOMETRY_COLUMN),
   CHECK(TYPE IN ('POINT','LINE', 'POLYGON', 'COLLECTION', 'MULTIPOINT', 'MULTILINE', 'MULTIPOLYGON', 'GEOMETRY','CIRCULARSTRING','COMPOUNDCURVE','CURVEPOLYGON') )
);
GO

INSERT INTO [$(owner)].[geometry_columns] ( F_TABLE_SCHEMA, F_TABLE_NAME, F_GEOMETRY_COLUMN)
SELECT s.name as f_table_schema,
       t.name as f_table_name,
       c.name as f_Column_Name
FROM sys.schemas            as s
     INNER JOIN sys.tables  as t ON s.schema_id = t.schema_id
     INNER JOIN sys.columns as c on t.object_id = c.object_id
WHERE system_type_id = 240;
GO

select * from [$(owner)].[geometry_columns] ;

DROP PROCEDURE [$(owner)].[AddGeometryColumn];
GO

CREATE PROCEDURE [$(owner)].[AddGeometryColumn] (
  @p_schema_name nvarchar(128),
  @p_table_name  nvarchar(128),
  @p_column_name nvarchar(128)
) 
AS
BEGIN
  DECLARE
    @v_geometry_type   varchar(100),
    @v_coordinate_dimension integer,
    @v_srid                 integer,
    @v_parameters      nvarchar(500),
    @v_sql             nvarchar(2000);

  SET @v_sql = 
N'SELECT TOP 1 ' + 
       ' @coord_dimsOUT = [$(owner)].[STCoordDim](a.' + @p_column_name + ') as coordinate_dimension,' +
       ' @geom_typeOUT = UPPER(a.' + @p_column_name + N'.STGeometryType() ) as geometry_type, ' +
       ' @geom_sridOUT = a.' + @p_column_name + N'.STSrid as geometry_srid ' +
' FROM [' + @p_schema_name + N'].[' + @p_table_name + '] as a';

  SET @v_parameters = N'@p_schema_name nvarchar(128),@p_table_name nvarchar(128),@p_column_name nvarchar(128),' +
                      N'@coord_dimsOUT integer OUTPUT,@geom_typeOUT varchar(100) OUTPUT,@geom_sridOUT integer OUTPUT';

  EXEC sp_executesql @query         = @v_sql, 
                     @params        = @v_parameters,
                     @coord_dimsOUT = @v_coordinate_dimension OUTPUT, 
                     @geom_typeOUT  = @v_geometry_type OUTPUT,
                     @geom_sridOUT  = @v_srid OUTPUT;

  UPDATE [$(owner)].[geometry_columns] 
     SET TYPE            = @v_geometry_type,
         coord_dimension = @v_coordinate_dimension,
         srid            = @v_srid
   WHERE f_table_schema    = @p_schema_name
     and f_table_name      = @p_table_name
     and F_GEOMETRY_COLUMN = @p_column_name;
  RETURN;
END;
GO

EXEC [$(owner)].[AddGeometryColumn] N'dbo',N'GridLL',N'geom';
GO

select * from [$(owner)].[geometry_columns];
SELECT TOP 1
       [$(owner)].[STCoordDim](a.geom) as coordinate_dimension,
       UPPER(a.geom.STGeometryType() ) as geometry_type,
       a.geom.STSrid as geometry_srid
  from [$(owner)].[GridLL] as a;
GO


