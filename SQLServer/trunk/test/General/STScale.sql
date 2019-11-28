SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STScale]....';
GO

SELECT a.stype, a.geom.AsTextZM() as geomWKT
  FROM (SELECT 'Scaled2D' as stype, [$(owner)].[STScale](geometry::STGeomFromText('LINESTRING (1 2 3, 1 1 1)',0),0.5,0.75,default,default, 2,1) as geom
        UNION ALL
        SELECT 'Original' as stype, geometry::STGeomFromText('LINESTRING (1 2 3, 1 1 1)',0) as geom ) a;
GO

SELECT a.stype, a.geom.AsTextZM() as geomWKT
  FROM (SELECT 'Scaled3D' as stype, [$(owner)].[STScale](geometry::STGeomFromText('LINESTRING (1 2 3, 1 1 1)',0), 0.5, 0.75, 0.8,null, 2,1) as geom
        UNION ALL
        SELECT 'Original' as stype, geometry::STGeomFromText('LINESTRING (1 2 3, 1 1 1)',0) as geom ) a;
GO
  
SELECT a.stype, a.geom.AsTextZM() as geomWKT
  FROM (SELECT 'Original' as stype, geometry::STGeomFromText('POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))',0) as geom 
        UNION ALL
        SELECT 'Scaled2D' as stype, [$(owner)].[STScale](geometry::STGeomFromText('POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))',0), 2.0, 2.0, null,null, 2,1) as geom
        UNION ALL
        SELECT 'ScaledYOnly' as stype, [$(owner)].[STScale](geometry::STGeomFromText('POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))',0), null, 2.0, null,null, 2,1) as geom ) a;
GO


