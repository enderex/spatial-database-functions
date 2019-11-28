SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STInsertN] ...';
GO

-- Null p_geometry Parameter returns p_point
select 1 as testid, [$(owner)].[STInsertN](NULL, geometry::Point(9,9,0) /* 2D */, 1,3,null).AsTextZM() as geom;
GO

-- Null p_geometry Parameter returns p_point
select 2 as testid, [$(owner)].[STInsertN](NULL, geometry::STPointFromText('POINT(9 9 0)',0) /* 3D */, 1,3,2).AsTextZM() as geom;
GO

-- No point to add so return geometry
select 3 as testid, [$(owner)].[STInsertN](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0), NULL, 1,3,2).AsTextZM() as geom;
GO

-- Geometry Collections not supported, so is returned.
select 4 as testid, [$(owner)].[STInsertN](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5))',0), geometry::Point(9,9,0), 1,3,2).AsTextZM() as geom;
GO

-- p_point must be point, so geometry is returned.
select 5 as testid, [$(owner)].[STInsertN](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0), geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0), 1,3,2).AsTextZM() as geom;
GO

-- Insert from begining to end
select 6 as testid, a.IntValue as insert_position,
       [$(owner)].[STInsertN](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0), geometry::Point(9,9,0), a.IntValue, 0, 2).AsTextZM() as geom
  from [$(owner)].[GENERATE_SERIES](-1,4,1) a;
GO

select 7 as testid, [$(owner)].[STInsertN](geometry::STGeomFromText('MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))',0), geometry::Point(0.5,0.5,0), 2, 3,2).AsTextZM() as geom;
GO

-- Add point to start of multipoint
select 8 as testid, [$(owner)].[STInsertN](geometry::STGeomFromText('MULTIPOINT(1 2 3)',0), /* 3D */ geometry::Point(9.4,9.7,0), /* 2D */ 1, 3, 2).AsTextZM() as geom;
GO

-- Add point to end of multipoint
select 9 as testid, [$(owner)].[STInsertN](geometry::STGeomFromText('MULTIPOINT(1 2 3)',0), geometry::Point(9.4,9.7,0), -1, 3, 2).AsTextZM() as geom;
GO

-- Add XYZM point to an XYZ point
select 10 as testid, t.intValue as Position,
       [$(owner)].[STInsertN](geometry::STGeomFromText('POINT(0 0 0)',  0), geometry::STGeomFromText('POINT(3 3 2 2)',0), t.IntValue, 1,2).AsTextZM() as geom
  from $(owner).Generate_Series(-1,1,1) as t
 where t.IntValue <> 0;
GO

With geoms As (
          select 1 as id, geometry::Point(16394506.234,-5283738.5676878,3857)  as p_point, 
                 0 as p_insert_point, 2 as p_precision
union all select 2 as id, geometry::STGeomFromText('MULTIPOINT(1 2 3)',3857)   as p_point,
                 1 as p_insert_point, 0 as p_precision
union all select 3 as id, geometry::STGeomFromText('MULTIPOINT(1 2 3 4)',3857) as p_point, 
                 2 as p_insert_point, 0 as p_precision
)
select 11 as testid, 
       [$(owner)].[STInsertN](a.p_point, geometry::Point(1111111.234,-222222222.567,3857), a.p_insert_point, a.p_precision, 2).AsTextZM() as geom
 from geoms a;
GO

-- Insert Point with NULL Z ordinates
select 12 as testid, 
       a.IntValue as InsertPosn,
       [$(owner)].[STInsertN](geometry::STGeomFromText('LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23, 98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)',0),
                         geometry::STGeomFromText('POINT (80.5823 901.3054 NULL 30)',0),
                         a.IntValue,
                         1,2).AsTextZM() as geom
  from [$(owner)].[generate_series](-1,4,1) a;
GO




