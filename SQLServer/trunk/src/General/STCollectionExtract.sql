USE [DEVDB]
GO

/****** Object:  UserDefinedFunction [dbo].[STCollectionExtract]    Script Date: 20/04/2020 6:00:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create function [dbo].[STCollectionExtract] (
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
              FROM [dbo].[Generate_Series](1,@p_collection.STNumGeometries(),1) as geomN
                   cross apply
                   [dbo].[Generate_Series](1,@p_collection.STGeometryN(geomN.[IntValue]).STNumGeometries(),1) as partN
           ) as f
     WHERE (@p_type = 1 and f.geom.STGeometryType() = 'Point')
	    OR (@p_type = 2 and f.geom.STGeometryType() = 'LineString')
	    OR (@p_type = 3 and f.geom.STGeometryType() = 'Polygon');
  END;
  RETURN;
End;
GO

