SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STInsertN] ...';
GO

-- Parameter errors
select [$(owner)].[STInsertN](NULL, geometry::Point(9,9,0),1,3,1).AsTextZM() as geom;
GO

-- Geometry Collection
select [$(owner)].[STInsertN](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5))',0), geometry::Point(9,9,0), 1,3,1).AsTextZM() as geom;
GO

select [$(owner)].[STInsertN](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0), NULL,1,3,1).AsTextZM() as geom;
GO

select [$(owner)].[STInsertN](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0), geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0), 1,3,1).AsTextZM() as geom;
GO

select a.IntValue as insert_position, [$(owner)].[STInsertN](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0), geometry::Point(9,9,0), a.IntValue,1,0).AsTextZM() as geom
  from [$(owner)].[generate_series](-1,4,1) a;
GO

select [$(owner)].[STInsertN](geometry::STGeomFromText('MULTIPOINT(1 2 3)',0), geometry::Point(9.4,9.7,0), 1,3,1).AsTextZM() as geom;
GO

select [$(owner)].[STInsertN](geometry::STGeomFromText('MULTIPOINT(1 2 3)',0), geometry::Point(9.4,9.7,0), -1,3,1).AsTextZM() as geom;
GO

-- Tests
select [$(owner)].[STInsertN](p_point,
                              geometry::Point(1111111.234,-222222222.567,0),
                              p_insert_point,p_precision_xy,1).AsTextZM() as geom
 from (select geometry::Point(16394506.234,-5283738.5676878,3857) as p_point, 0 as p_insert_point, 2 as p_precision_xy
        union all
        select geometry::STGeomFromText('MULTIPOINT(1 2 3)',0) as p_point, 1 as p_insert_point, 0 as p_precision_xy
        union all
        select geometry::STGeomFromText('MULTIPOINT(1 2 3 4)',0) as p_point, 2 as p_insert_point, 0 as p_precision_xy
      ) as f;
GO

-- Point
--
select geometry::STGeomFromText('POINT(0 0 0)',0).STBuffer(0.5) as geom
union all
select [$(owner)].[STInsertN](geometry::STGeomFromText('POINT(0 0 0)',0), geometry::Point(1,1,0), a.IntValue,3,2).AsTextZM() as geom
  from [$(owner)].[generate_series](-1,1,1) as a;
GO

-- Linestring
--
select [$(owner)].[STInsertN](geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0), geometry::Point(5,5,0), a.IntValue,3,2).AsTextZM() as geom
  from [$(owner)].[generate_series](-1,1,1) as a;
GO

-- Move rectangle 10,10 
--
select geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0) as geom
UNION ALL
select [$(owner)].[STInsertN](geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0), geometry::Point(10.0,10.0,0), null,2,1) as geom;
GO 

-- Curved polygon
--
select geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872)))',0).STCurveToLine() as geom
union all
select [$(owner)].[STInsertN](geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872)))',0), geometry::Point(1.1,1.1,0), 5,3,2).AsTextZM() as geom;
GO


