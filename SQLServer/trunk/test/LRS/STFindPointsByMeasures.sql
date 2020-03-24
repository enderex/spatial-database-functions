select 0 as delta, geometry::STGeomFromText('LINESTRING (0 0 NULL 0, 1 1 NULL 1.41, 2 2 NULL 2.83, 3 3 NULL 4.24, 4 4 NULL 5.66, 5 5 NULL 7.07, 6 6 NULL 8.49, 10 6 NULL 12.49)',0)
union all
select 12.49 / 20.0 as delta, 
       [$(lrsowner)].[STFindPointsByMeasures] (
          geometry::STGeomFromText('LINESTRING (0 0 NULL 0, 1 1 NULL 1.41, 2 2 NULL 2.83, 3 3 NULL 4.24, 4 4 NULL 5.66, 5 5 NULL 7.07, 6 6 NULL 8.49, 10 6 NULL 12.49)',0),
         12.49 / 20.0,  
		 '-2,0.0,2', 
          3,3).STBuffer(0.2)
union all
select 0 as delta, geometry::Point(pts.x,pts.y,0).STBuffer(0.1) as pnt
  from [$(owner)].[STDumpPoints](geometry::STGeomFromText('LINESTRING (0 0 NULL 0, 1 1 NULL 1.41, 2 2 NULL 2.83, 3 3 NULL 4.24, 4 4 NULL 5.66, 5 5 NULL 7.07, 6 6 NULL 8.49, 10 6 NULL 12.49)',0)) as pts;
