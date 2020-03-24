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
          /* @p_point      */ b.p_point,
		  /* @p_round      */ 5
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
          /* @p_point      */ b.p_point,
		  /* @p_round      */ 5
       ) as whichSide,
	   B.p_point.STBuffer(0.1) as geom
 from data as a,
      points as b;
GO

select g.IntValue, 
       [$(lrsowner)].[STWhichSide](
          geometry::STGeomFromText('CIRCULARSTRING(0 0,10 10,20 0)',0),
          geometry::Point(10, g.IntValue,0),
          5
       )
  from [$(owner)].[generate_series](-50,50,5) as g;


with data as (
select geometry::STGeomFromText(
'CIRCULARSTRING (
2173742.0037621  259304.411434516 NULL 3498.52,
2173712.74541767 259214.837554961 NULL 3186.7865,
2173742.05001496 259159.972709981 NULL 0)',2274)  as cLine
)
select dbo.STWhichSide(a.cLine,cogo.STFindCircleFromArc(a.cline),3)
 from data as a;
 
select [$(owner)].[STWhichSide](
geometry::STGeomFromText('
CIRCULARSTRING (
2173742.0037621  259304.411434516 NULL 3498.52,
2173712.74541767 259214.837554961 NULL 3186.7865,
2173742.05001496 259159.972709981 NULL 0)',2274),
geometry::Point(2173742.74541767,259214.837554961,2274),
5
);
GO

select [$(owner)].[STWhichSide](
geometry::STGeomFromText('
CIRCULARSTRING (
2173742.05001496 259159.972709981 NULL 0,
2173712.74541767 259214.837554961 NULL 3186.7865,
2173742.0037621  259304.411434516 NULL 3498.52)',2274),
geometry::Point(2173742.74541767,259214.837554961,2274),
5
);
GO

select [$(owner)].[STWhichSide](
geometry::STGeomFromText('
CIRCULARSTRING (
2173742.0037621  259304.411434516 NULL 3498.52,
2173762.74541767 259214.837554961 NULL 3186.7865,
2173742.05001496 259159.972709981 NULL 0)',2274),
geometry::Point(2173742.74541767,259214.837554961,2274),
5
);
GO

select [$(owner)].[STWhichSide](
geometry::STGeomFromText('
CIRCULARSTRING (
2173742.05001496 259159.972709981 NULL 0,
2173762.74541767 259214.837554961 NULL 3186.7865,
2173742.0037621  259304.411434516 NULL 3498.52)',2274),
geometry::Point(2173742.74541767,259214.837554961,2274),
5
);
GO

WITH I124 as (
 select geometry::STGeomFromText('COMPOUNDCURVE (
CIRCULARSTRING (2172207.1209 256989.8612 NULL 11200, 2172337.5274 257437.9649 NULL 0, 2172663.8317 257771.6238 NULL 12142.8313), 
(2172663.8317 257771.6238 NULL 12142.8313, 2173053.9057 258011.324 NULL 12600.6675), 
CIRCULARSTRING (2173053.9057 258011.324 NULL 12600.6675, 2173287.0114 258189.9636 NULL 0, 2173478.7072 258412.4565 NULL 13189.0729), 
CIRCULARSTRING (2173478.7072 258412.4565 NULL 13189.0729, 2173748.7793 258973.8411 NULL 0, 2173828.6565 259591.669 NULL 14440.3391), 
(2173828.6565 259591.669 NULL 14440.3391, 2173758.294 261836.1799 NULL 16685.9526), 
CIRCULARSTRING (2173758.294 261836.1799 NULL 16685.9526, 2173725.784 262165.5463 NULL 0, 2173649.5316 262487.6095 NULL 17348.3827), 
(2173649.5316 262487.6095 NULL 17348.3827, 2173560.7814 262776.4138 NULL 17650.516), 
CIRCULARSTRING (2173560.7814 262776.4138 NULL 17650.516, 2173487.3279 263024.5188 NULL 0, 2173420.5044 263274.4911 NULL 18168.0311), 
(2173420.5044 263274.4911 NULL 18168.0311, 2173069.1373 264662.6827 NULL 19600, 2172750.1517 265922.9399 NULL 20900))',2274) as geom
)
select geom, 'line' as side from I124 union all
select geometry::STGeomFromText('POINT (2172226.110756 258070.570902)', 2274).STBuffer(50), 'Point' as side union all
SELECT a.geom,
       [$(owner)].[STWhichSide](a.geom, geometry::STGeomFromText('POINT (2172226.110756 258070.570902)', 2274), 4) as side 
 FROM I124 as a
