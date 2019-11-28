SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STVertices] ...';
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m], e.[point].AsTextZM() as point
  from [$(owner)].[STVertices](geometry::STGeomFromText('POINT(0 1 2 3)',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m], e.[point]
  from [$(owner)].[STVertices](geometry::STGeomFromText('LINESTRING(2 3 4,3 4 5)',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STVertices](geometry::STGeomFromText('POLYGON ((0 0, 100 0, 100 100, 0 100, 0 0))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STVertices] (
       geometry::STGeomFromText('MULTIPOLYGON( ((200 200, 400 200, 400 400, 200 400, 200 200)), ((0 0, 100 0, 100 100, 0 100, 0 0),(40 40,60 40,60 60,40 60,40 40)))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STVertices](geometry::STGeomFromText('POLYGON((2300 -700, 2800 -300, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400, 2300 200, 2100 100, 2500 100, 2300 -200, 1800 -300, 2300 -500, 2200 -400, 2400 -400, 2300 -700), (2300 1000, 2400  900, 2200 900, 2300 1000))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STVertices](geometry::STGeomFromText('MULTILINESTRING((2 3 4,3 4 5),(1 1,2 2))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STVertices](geometry::STGeomFromText('MULTIPOINT((1 1),(2 2),(3 3))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STVertices](geometry::STGeomFromText('MULTIPOLYGON (((200 200, 400 200, 400 400, 200 400, 200 200)), ((0 0, 100 0, 100 100, 0 100, 0 0)), ((2300 -700, 2800 -300, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400, 2300 200, 2100 100, 2500 100, 2300 -200, 1800 -300, 2300 -500, 2200 -400, 2400 -400, 2300 -700), (2300 1000, 2400  900, 2200 900, 2300 1000)))',0)) as e;
GO

select e.[uid], e.[pid], e.[mid], e.[rid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STVertices](geometry::STGeomFromText( 'GEOMETRYCOLLECTION( POINT(2 3 4), POINT(4 5), MULTIPOINT((1 1),(2 2),(3 3)), LINESTRING(2 3 4,3 4 5), MULTILINESTRING((2 3 4,3 4 5),(1 1,2 2)), POLYGON((0 0 0, 100 0 1, 100 100 2, 0 100 3, 0 0 4)), POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)), MULTIPOLYGON(((200 200, 400 200, 400 400, 200 400, 200 200)), ((0 0, 100 0, 100 100, 0 100, 0 0), (40 40,60 40,60 60,40 60,40 40))))',0)) as e;
GO

select e.[uid], e.[mid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [$(owner)].[STVertices](
          [$(owner)].[STToGeometry](geography::STGeomFromText('POLYGON((148.0 -44.0, 148.0 -43.0, 147.0 -43.0, 147.0 -44.0, 148.0 -44.0), (147.4 -43.6, 147.2 -43.6, 147.2 -43.2, 147.4 -43.2, 147.4 -43.6))',4326),0)
       ) as e;
GO

select t.*
  from [$(owner)].[STVertices](geometry::STGeomFromText('COMPOUNDCURVE ((-4 -4 NULL 0, 0 0 NULL 5.657, 10 0 NULL 15.657), CIRCULARSTRING (10 0 NULL 15.657, 10 5 NULL 20.657, 20 10 NULL 38.162), (20 10 NULL 38.162, 21 11 NULL 39.577, 22 12 NULL 35.991))',0)) as t;
GO

