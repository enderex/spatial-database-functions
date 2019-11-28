SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STExtract] ....';
GO

select 'POINT' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('POINT(0 0)',0),1) as gElem union all
select 'MPONT' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOINT((0 0),(20 0))',0),1) as gElem union all
select 'LINES' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('LINESTRING(0 0,20 0,20 20,0 20,0 0)',0),1) as gElem union all
select 'MLINE' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('MULTILINESTRING((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),1) as gElem union all
select 'POLYI' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0),1) as gElem union all
select 'MPLYO' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOLYGON (((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0),1) as gElem union all
select 'MPLYI' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0),1) as gElem union all
select 'CPLY0' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0),0) as gElem union all
select 'CPLY1' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)))',0),1) as gElem union all
select 'GEOC0' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0),0) as gElem union all
select 'GEOC1' as gtype, gid,sid,geom.STAsText() as geom from [$(owner)].[STExtract](geometry::STGeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), CURVEPOLYGON(COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), COMPOUNDCURVE(CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), (0 -23.43778, 0 23.43778)))',0),1) as gElem;
GO

