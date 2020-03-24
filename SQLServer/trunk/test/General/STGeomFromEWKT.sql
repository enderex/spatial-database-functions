SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STGeomFromEWKT] ...';
GO

select [$(owner)].[STGeomFromEWKT]('POINT EMPTY').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('MULTIPOINT EMPTY').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('LINESTRING EMPTY').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('CIRCULARSTRING EMPTY').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('MULTILINESTRING EMPTY').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('POLYGON EMPTY').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('MULTIPOLYGON EMPTY').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('COMPOUNDCURVE EMPTY').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('GEOMETRYCOLLECTION EMPTY').AsTextZM() as geom;
GO

select [$(owner)].[STGeomFromEWKT]('POINT(1 2)').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('POINTZ(1 2 3)').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('POINTM(1 2 3)').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('POINTZM(1 2 3 4)').AsTextZM() as geom;
GO

select [$(owner)].[STGeomFromEWKT]('LineString (1 2,4 5,3 4,4 6,5 7,6 7)').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('SRID=2274;LINESTRING (1 2,4 5,3 4,4 6,5 7,6 7)').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('SRID=2274;LINESTRINGZ (1 2 3,3 4 5,4 6 6,5 7 7,6 7 8)').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('SRID=2274;LINESTRINGM (1 2 3,3 4 5,4 6 6,5 7 7,6 7 8)').AsTextZM() as geom;
GO

select [$(owner)].[STGeomFromEWKT]('MULTILINESTRING ((1 2 3,4 5 6,3 4 5),(4 5 6,5 6 7, 5 6 7))').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('MULTILINESTRING Z ((1 2 3,4 5 6,3 4 5),(4 5 6,5 6 7, 5 6 7))').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('MULTILINESTRING M ((1 2 3,4 5 6,3 4 5),(4 5 6,5 6 7, 5 6 7))').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('SRID=2287;MULTILINESTRING ZM ((1 2 3,4 5 6,3 4 5),(4 5 6,5 6 7, 5 6 7))').AsTextZM() as geom;
GO

select [$(owner)].[STGeomFromEWKT]('POLYGON((0 0 1,10 0 1,10 10 1,0 10 1,0 0 1))').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('POLYGONZ((0 0 1,10 0 1,10 10 1,0 10 1,0 0 1))').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('POLYGONM((0 0 1,10 0 1,10 10 1,0 10 1,0 0 1))').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('POLYGONZM((0 0 NULL 1, 10 0 NULL 1, 10 10 NULL 1, 0 10 NULL 1, 0 0 NULL 1))').AsTextZM() as geom;
GO

select [$(owner)].[STGeomFromEWKT]('GEOMETRYCOLLECTION (POINT(0 0 1), LINESTRING(10 0 1, 10 10 1, 0 10 1))').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('GEOMETRYCOLLECTION Z(POINT(0 0 1), LINESTRING(10 0 1, 10 10 1, 0 10 1))').AsTextZM() as geom;
GO
select [$(owner)].[STGeomFromEWKT]('GEOMETRYCOLLECTION M(POINT(0 0 1), LINESTRING(10 0 1, 10 10 1, 0 10 1))').AsTextZM() as geom;
GO

select [$(owner)].[STGeomFromEWKT]('COMPOUNDCURVE M((2173369.79254475 259887.575230554 2600,2173381.122467 259911.320734575 2626.3106),CIRCULARSTRING (2173381.122467 259911.320734575 2626.3106,2173433.84355779 259955.557426129 0,2173501.82006501 259944.806018785 2768.24))').AsTextZM() as geom;
GO
