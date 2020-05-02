SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STCollectionExtract]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STCollectionExtract];
  Print 'Dropped [$(owner)].[STCollectionExtract] ....';
END;
GO

Print 'Creating [$(owner)].[STCollectionExtract]....';
GO

CREATE FUNCTION [$owner)].[STCollectionExtract] (
  @p_collection geometry,
  @p_type       integer
)
Returns @geometries TABLE (
  id    integer,
  geom geometry
)
As
Begin
  IF ( @p_collection.STGeometryType() IN ('GeometryCollection') )
  BEGIN
    INSERT INTO @geometries (id,geom)
    SELECT row_number() over (order by (select 1)) as id,
	       f.geom
      FROM (SELECT @p_collection
                     .STGeometryN(geomN.[IntValue])
                     .STGeometryN(partN.[IntValue]) as geom
              FROM [$owner)].[Generate_Series](1,@p_collection.STNumGeometries(),1) as geomN
                   cross apply
                   [$owner)].[Generate_Series](1,@p_collection.STGeometryN(geomN.[IntValue]).STNumGeometries(),1) as partN
           ) as f
     WHERE (@p_type = 1 and f.geom.STGeometryType() = 'Point')
	    OR (@p_type = 2 and f.geom.STGeometryType() = 'LineString')
	    OR (@p_type = 3 and f.geom.STGeometryType() = 'Polygon');
  END;
  RETURN;
End;
GO

