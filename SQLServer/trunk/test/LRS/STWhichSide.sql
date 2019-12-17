with data as (
  select geometry::STGeomFromText('LINESTRING(0 0,1 1)',0) as v_segment
), points as (
  select geometry::STGeomFromText('POINT(0.5 1)',0) as p_point
  union all
  select geometry::STGeomFromText('POINT(0.5 0.5)',0) as p_point
  union all
  select geometry::STGeomFromText('POINT(0.5 0)',0) as p_point         
)
select '_' as which, v_segment from data as a
union all
select [$(lrsowner)].[STWhichSide] (
          /* @p_linestring */ v_segment,
          /* @p_point      */ b.p_point 
       ),
	   b.p_point.STBuffer(0.1) as point
 from data as a,
      points as b;
GO

with data as (
  select '1' as whichSide, geometry::STGeomFromText('CIRCULARSTRING(0 0,1 1,2 0)',0) as v_segment
  union all
  select '2' as whichSide, geometry::STGeomFromText('CIRCULARSTRING(2 0,1 1,0 0)',0) as v_segment

), points as (
  select geometry::STGeomFromText('POINT(1 2)',0) as p_point
  union all
  select geometry::STGeomFromText('POINT(1 1)',0) as p_point
  union all
  select geometry::STGeomFromText('POINT(1 0)',0) as p_point         
)
select whichSide, v_segment as geom from data as a
union all
select [$(lrsowner)].[STWhichSide] (
          /* @p_linestring */ v_segment,
          /* @p_point      */ b.p_point 
       ) as whichSide,
	   B.p_point.STBuffer(0.1) as geom
 from data as a,
      points as b;
GO
