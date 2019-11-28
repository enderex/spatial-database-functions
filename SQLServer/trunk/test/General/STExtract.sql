SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STExtract] ...';
GO

select 'Single Point' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText('POINT(0 0)',0),1) as gElem;
GO

select 'MultiPoint' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom
  from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOINT((0 0),(20 0))',0),1) as gElem;;
GO

select 'Simple Single LineString' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText('LINESTRING(0 0,20 0,20 20,0 20,0 0)',0),1) as gElem ;
GO

select 'Simple MultiLine with 3 LineStrings' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText('MULTILINESTRING((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),1) as gElem ;
GO

select 'Simple MultiPolygon with 3 Exterior Rings and 2 Interior Rings' as test,
       1 as sub_geom,
       d.gid,d.sid,d.geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0), 1) as d;
GO

select 'Single Polygon with 2 Interior Rings' as test,
       1 as sub_geom,
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0), 1) as gElem ;
GO

select 'Simple MultiPolygon with two simple Polygons (ExteriorRings)' as test,
       1 as sub_geom, gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText( 'MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0), 1) as gElem ;
GO

select 'Simple MultiPolygon with three Polygons with 2/0/0 Interior RIngs rings' as test,
        1 as sub_geom,
        gid,sid,geom.STAsText() as geom 
  from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0), 1) as gElem ;
GO

-- *******************
-- Compound Geometries

select 'Single Compound Curve LineString' as test,
       g.IntValue as sub_geom, 
       gid,sid,geom.STAsText() as geom 
  from [$(owner)].[generate_series](0,2,1) g
       cross apply
       [$(owner)].[STExtract](geometry::STGeomFromText( 'COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778))',0), g.[IntValue]) as gElem;
GO

select 'Single Curve Polygon with one exterior (compound) ring' as test,
       g.IntValue as sub_elem, gid,sid,geom.STAsText() as geom 
  from [$(owner)].[generate_series](0,2,1) g
       cross apply
       [$(owner)].[STExtract](
            geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0), 
            g.IntValue) as gElem ;
GO

select 'Curve Polygon (circularString exterior ring) with a single interior CircularString (circle) ring' as test,
       g.IntValue as sub_elem,gid,sid,geom.STAsText() as geom 
  from [$(owner)].[generate_series](0,2,1) g
       cross apply
       [$(owner)].[STExtract] (geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 4, 4 0, 8 4, 4 8, 0 4), CIRCULARSTRING(2 4, 4 2, 6 4, 4 6, 2 4))',0), g.IntValue) as e;

select 'Geometry Collection with Compound elements' as test,
       g.IntValue as sub_geom, gid,sid,geom.STAsText() as geom 
  from [$(owner)].[generate_series](2,2,1) g
       cross apply
       [$(owner)].[STExtract] (
          geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), CURVEPOLYGON( COMPOUNDCURVE((0 -23.43778, 0 23.43778), CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), (-90 23.43778, -90 -23.43778), CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0), 
          g.intValue) as gElem;
GO

