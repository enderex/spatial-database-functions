
select [$(owner)].[STAverage](geometry::STGeomFromText('POINT(-1 -1)',0),geometry::STGeomFromText('POINT(1 1)',0)).AsTextZM() as aPoint;

select [$(owner)].[STAverage](geometry::STGeomFromText('POINT(-1 -1 1.1)',0),geometry::STGeomFromText('POINT(1 1 3)',0)).AsTextZM() as aPoint;

select [$(owner)].[STAverage](geometry::STGeomFromText('POINT(-1 -1 NULL 2.1)',0),geometry::STGeomFromText('POINT(1 1 NULL 3)',0)).AsTextZM() as aPoint;

select [$(owner)].[STAverage](geometry::STGeomFromText('POINT(-1 -1 1.1 2.1)',0),geometry::STGeomFromText('POINT(1 1 2.1 3)',0)).AsTextZM() as aPoint;

select [$(owner)].[STAverage](geometry::STGeomFromText('POINT(-1 -1 1.1 2.1)',0),geometry::STGeomFromText('POINT(1 1 NULL 3)',0)).AsTextZM() as aPoint;
