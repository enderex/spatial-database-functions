SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STFindPointByLength] ...';
GO

select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61)',0) as geom union all
select [$(cogoowner)].[STFindPointBisector](
geometry::STGeomFromText('LINESTRING(-4 -4 0 1,0 0 0 5.6)',0),
geometry::STGeomFromText('LINESTRING(0 0 0 5.6,10 0 0 15.61)',0),
3,3,3,2).STBuffer(0.1);


select geometry::STGeomFromText('LINESTRING(0  0,10  0)',28355) as geom union all
select geometry::STGeomFromText('LINESTRING(10  0,10 10)',28355) as geom union all
select [$(cogoowner)].[STFindPointBisector](
geometry::STGeomFromText('LINESTRING(0  0,10  0)',28355),
geometry::STGeomFromText('LINESTRING(10  0,10 10)',28355),
10,3,3,3).STBuffer(0.1);

-- Long line
select geometry::STGeomFromText('LINESTRING(0 0,10 0,10 10)',28355) as lengthSegment union all
select [$(lrsowner)].[STFindPointByLength](
           geometry::STGeomFromText('LINESTRING(0 0,10 0,10 10)',28355),10.0,5,3,2).STBuffer(0.1) as lengthSegment;

-- Iterate over LineString with offsets
with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'Original Linestring as backdrop for SSMS mapping' as locateType, '0' as offset,
        linestring.STBuffer(0.5) as lengthSegment from data as a
union all
select 'Null length (-> NULL)' as locateType, '0' as offset,
       [$(lrsowner)].[STFindPointByLength](linestring,null,0,3,2).STBuffer(0.1) as lengthSegment from data as a
union all
select 'On intersection between seg 1 and 2' as locType,
       'Offset ' + CAST(offset.IntValue as varchar(100)),
      [$(lrsowner)].[STFindPointByLength](linestring,5.65685424949238,offset.IntValue,3,2).STBuffer(0.2) as lengthSegment
  from data as a
       cross apply
	   dbo.generate_series(-5,5,5) as offset
union all
select 'Length ' + CAST(cumLength.IntValue as varchar(100)), 
       'Offset ' + CAST(offset.IntValue     as varchar(100)),
       [$(lrsowner)].[STFindPointByLength](linestring,cumLength.IntValue,offset.IntValue,3,2).STBuffer(0.2) as lengthSegment
  from data as a
       cross apply
	   dbo.Generate_Series(-1,CEILING(a.linestring.STLength()),1) as cumLength
	   cross apply
	   dbo.Generate_Series(-2,2,1) as offset
GO

-- Now with offset
with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'LineString' as locateType, linestring from data as a
union all
select 'Length = First Segment Start Point' as locateType,[$(lrsowner)].[STFindPointByLength](linestring,1,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Length = First Segment End Point' as locateType,  [$(lrsowner)].[STFindPointByLength](linestring,5.6,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Length is middle First Segment' as locateType,    [$(lrsowner)].[STFindPointByLength](linestring,2.3,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Length = Second Segment Mid Point' as locateType, [$(lrsowner)].[STFindPointByLength](linestring,10.0,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Length = Last Segment Mid Point' as locateType,   [$(lrsowner)].[STFindPointByLength](linestring,20.0,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Length = Last Segment End Point' as locateType,   [$(lrsowner)].[STFindPointByLength](linestring,25.4,-1.0,3,2).STBuffer(2) as lengthSegment from data as a;
GO

-- 2D Linestring with curves...
with data as (
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
)
select g.intValue as length,
       CAST(o.IntValue as numeric) / 2.0 as offset,
       [$(lrsowner)].[STFindPointByLength](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.2) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](0,a.lineString.STLength(),a.lineString.STLength()/4.0) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as length, 
       null as offset,
       linestring.STBuffer(0.1)
  from data as a;
GO

-- Length Linestring with curves...
with data as (
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 NULL 0, 0 7 NULL 3.08, -3 6.3246 NULL 6.15),(-3 6.3246 NULL 6.15, 0 0 NULL 10.1, 3 6.3246 NULL 20.2))',0) as linestring
)
select g.intValue as length,
       CAST(o.IntValue as numeric) / 2.0 as offset,
       [$(lrsowner)].[STFindPointByLength](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.2) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](0,a.lineString.STLength(),a.lineString.STLength()/4.0) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as length, 
       null as offset,
       linestring.STBuffer(0.1)
  from data as a;
GO

-- ******************************************************************************************

Print 'Testing [$(lrsowner)].[STFindPointByRatio] ...';
GO

-- Linestring test.
with data as (
  select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
)
select f.ratio,
       o.IntValue as offset,
       [$(lrsowner)].[STFindPointByRatio] (
          /* @p_linestring*/ a.linestring,
          /* @p_ratio     */ f.ratio,
          /* @p_offset    */ o.IntValue,
          /* @p_round_xy  */ 3,
          /* @p_round_zm  */ 2
       ).AsTextZM() as fPoint
  from data as a,
       (select /* @p_ratio */ 0.01 * CAST(t.IntValue as numeric) as ratio
          from [$(owner)].[Generate_Series](1,100,10) as t
       ) as f
       cross apply 
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as length, 
       null as offset,
       linestring.AsTextZM()
  from data as a;
GO

-- 2D Circular Curve test.
select f.ratio,
       CAST(o.IntValue as numeric) / 2.0 as offset,
       [$(lrsowner)].[STFindPointByRatio] (
          /* @p_linestring*/ geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
          /* @p_ratio     */ f.ratio,
          /* @p_offset    */ CAST(o.IntValue as numeric) / 2.0,
          /* @p_round_xy  */   3,
          /* @p_round_zm  */   2
       ).AsTextZM() as fPoint
  from (select /* @p_ratio */ 0.01 * CAST(t.IntValue as numeric) as ratio
          from [$(owner)].[Generate_Series](1,100,10) as t
       ) as f
       cross apply 
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as ratio,
       null as offset,
       geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0).AsTextZM();
GO

-- Length Circular Curve test.
-- Measure ordinate exists.
with data as (
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 NULL 0, 0 7 NULL 3.08, -3 6.3246 NULL 6.15),(-3 6.3246 NULL 6.15, 0 0 NULL 10.1, 3 6.3246 NULL 20.2))',0) as cLine
)
select f.ratio,
       CAST(o.IntValue as numeric) / 2.0 as offset,
       [$(lrsowner)].[STFindPointByRatio] (
          /* @p_linestring*/ a.cLine,
          /* @p_ratio     */ f.ratio,
          /* @p_offset    */ CAST(o.IntValue as numeric) / 2.0,
          /* @p_round_xy  */   3,
          /* @p_round_zm  */   2
       ).AsTextZM() as fPoint -- STBuffer(0.3) as fPoint
  from data as a
       cross apply
	   (select /* @p_ratio */ 0.01 * CAST(t.IntValue as numeric) as ratio
          from [$(owner)].[Generate_Series](1,100,10) as t
       ) as f
       cross apply 
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as ratio,
       null as offset,
       A.cLine.AsTextZM() -- .STBuffer(0.1)
  FROM data as a
GO

-- Z and M
with data as (
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 -1 0, 0 7 -1 3.08, -3 6.3246 -1 6.15),(-3 6.3246 -1 6.15, 0 0 -2.0 10.1, 3 6.3246 -1.0 20.2))',0) as cLine
)
select f.ratio,
       CAST(o.IntValue as numeric) / 2.0 as offset,
       [$(lrsowner)].[STFindPointByRatio] (
          /* @p_linestring*/ a.cLine,
          /* @p_ratio     */ f.ratio,
          /* @p_offset    */ CAST(o.IntValue as numeric) / 2.0,
          /* @p_round_xy  */   3,
          /* @p_round_zm  */   2
       ).AsTextZM() as fPoint -- STBuffer(0.3) as fPoint
  from data as a
       cross apply
	   (select /* @p_ratio */ 0.01 * CAST(t.IntValue as numeric) as ratio
          from [$(owner)].[Generate_Series](1,100,10) as t
       ) as f
       cross apply 
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as ratio,
       null as offset,
       A.cLine.AsTextZM() -- STBuffer(0.1)
  FROM data as a
GO
