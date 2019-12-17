SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [lrs].[STFindPointByMeasure] ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'Original Linestring as backdrop for SSMS mapping' as locateType, [lrs].[STFindPointByMeasure](linestring,null,0,3,2).STBuffer(1) as measureSegment from data as a
union all
select 'Null measure (-> NULL)' as locateType, [lrs].[STFindPointByMeasure](linestring,null,0,3,2).STBuffer(1) as measureSegment from data as a
union all
select 'Measure = Before First SM -> NULL)' as locateType, [lrs].[STFindPointByMeasure](linestring,0.1,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = 1st Segment SP -> SM' as locateType, [lrs].[STFindPointByMeasure](linestring,1,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = 1st Segment EP -> EM' as locateType, [lrs].[STFindPointByMeasure](linestring,5.6,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = MidPoint 1st Segment -> NewM' as locateType, [lrs].[STFindPointByMeasure](linestring,2.3,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = 2nd Segment MP -> NewM' as locateType, [lrs].[STFindPointByMeasure](linestring,10.0,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment Mid Point' as locateType, [lrs].[STFindPointByMeasure](linestring,20.0,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment End Point' as locateType, [lrs].[STFindPointByMeasure](linestring,25.4,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = After Last Segment''s End Point Measure' as locateType, [lrs].[STFindPointByMeasure](linestring,47.0,0,3,2).STBuffer(2) as measureSegment from data as a;
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  4, 0  0 0 2)',28355) as rlinestring
)
select 'Measure is middle First With Reversed Measures' as locateType, [lrs].[STFindPointByMeasure](rlinestring,3.0,0,3,2).AsTextZM() as measureSegment from data as a;
GO

-- Now with offset
with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'LineString' as locateType, linestring from data as a
union all
select 'Measure = First Segment Start Point' as locateType, [lrs].[STFindPointByMeasure](linestring,1,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = First Segment End Point' as locateType, [lrs].[STFindPointByMeasure](linestring,5.6,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure is middle First Segment' as locateType, [lrs].[STFindPointByMeasure](linestring,2.3,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Second Segment Mid Point' as locateType, [lrs].[STFindPointByMeasure](linestring,10.0,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment Mid Point' as locateType, [lrs].[STFindPointByMeasure](linestring,20.0,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment End Point' as locateType, [lrs].[STFindPointByMeasure](linestring,25.4,-1.0,3,2).STBuffer(2) as measureSegment from data as a;
GO

-- Measures plus left/right offsets

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [lrs].[STFindPointByMeasure](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.5) as fPoint
  from data as a
       cross apply
       [dbo].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
       cross apply
       [dbo].[generate_series](-1,1,1) as o
union all
select g.intValue as measure,
       o.IntValue as offset,
       [lrs].[STFindPointByMeasure](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).STBuffer(0.5) as fPoint
  from data as a
       cross apply
       [dbo].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
       cross apply
       [dbo].[generate_series](-1,1,1) as o
union all
select null as measure, 
       null as offset,
       linestring.STBuffer(0.2)
  from data as a;
GO

-- Circular Arc / Measured Tests
with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
  union all 
  select [lrs].[STAddMeasure](
           geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
		   0.0,
           geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0).STLength(),
		   4,4) as linestring
)
select 'original' as curve_type,0 as measure,0 as offset,
       linestring as fPoint
  from data union all
select CAST(a.linestring.STGeometryType() as varchar(30)) as curve_type,
       g.intValue as measure,
       o.IntValue as offset,
       [lrs].[STFindPointByMeasure](a.linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.2) as fPoint
  from data as a
       cross apply
       [dbo].[generate_series](a.lineString.STPointN(1).M,
                               round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1),
                               [lrs].[STMeasureRange](a.linestring) / 4.0 ) as g
       cross apply
       [dbo].[generate_series](-1, 1, 1) as o
order by curve_type, measure;
GO

with data as (
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 -1 0, 0 7 -1 3.08, -3 6.3246 -1 6.15),(-3 6.3246 -1 6.15, 0 0 -2.0 10.1, 3 6.3246 -1.0 20.2))',0) as cLine
)
select CAST(measure.IntValue as numeric) as measure,
       CAST(o.IntValue as numeric) / 2.0 as offset,
       [lrs].[STFindPointByMeasure](
          /* @p_linestring*/ a.cLine,
          /* @p_measure   */ CAST(measure.IntValue as numeric),
          /* @p_offset    */ CAST(o.IntValue as numeric),
          /* @p_round_xy  */   3,
          /* @p_round_zm  */   2
       ).STBuffer(0.3) as fPoint
  from data as a
       cross apply [dbo].[Generate_Series](a.cLine.STStartPoint().M,a.cLine.STEndPoint().M,1) as measure
       cross apply [dbo].[generate_series](-1,1,1) as o
union all
select null as ratio,
       null as offset,
       A.cLine.STBuffer(0.1)
  FROM data as a
GO

-- Proof that STFindPointByMeasure doesn't work along a circularlinestring, 
-- only along a linestring when both are part of a compoundcurve:

with data as (
select geometry::STGeomFromText(
'COMPOUNDCURVE ((2173369.79254475 259887.575230554 NULL 2600,2173381.122467 259911.320734575 NULL 2626.3106), 
 CIRCULARSTRING (2173381.122467 259911.320734575 NULL 2626.3106,2173433.84355779 259955.557426129 NULL 0,2173501.82006501 259944.806018785 NULL 2768.24))', 
 2274) as test_line
)
--select test_line as geom from data as a union all
select [lrs].[STFindPointByMeasure]( a.test_line, 2626.3106, 50, 5, 3).AsTextZM()
  from data as a;

-- SGG POINT (2173426.24885 259889.78915 NULL 2626.3)

-- at the edge of the line, returns a point
-- ********************************************************

select [lrs].[STFindPointByMeasure]( 
 geometry::STGeomFromText('COMPOUNDCURVE ((2173369.79254475 259887.575230554 NULL 2600,2173381.122467 259911.320734575 NULL 2626.3106), 
 CIRCULARSTRING (2173381.122467 259911.320734575 NULL 2626.3106,2173433.84355779 259955.557426129 NULL 0,2173501.82006501 259944.806018785 NULL 2768.24))', 2274) 
 , 2626.3107, 50, 5, 4).AsTextZM(); 

-- SGG POINT (2173426.24885 259889.78915 NULL 2626.3106)

--  at the beginning of the curve, returns null 
-- ********************************************************

select [lrs].[STFindPointByMeasure]( 
 geometry::STGeomFromText('CIRCULARSTRING (2173381.122467 259911.320734575 NULL 2626.3106,2173433.84355779 259955.557426129 NULL 0,2173501.82006501 259944.806018785 NULL 2768.24)', 2274) 
 , 2626.3107, 50, 5, 4).AsTextZM(); 

-- SGG POINT (2173426.24885 259889.78915 NULL 2626.3106)

-- returns a point at the correct location, but don't want to have to manually manipulate WKT to get this to work . . . 
-- would of course rather have STSegmentize provide these to the STFindPointByMeasure function automatically . . .
-- ********************************************************

