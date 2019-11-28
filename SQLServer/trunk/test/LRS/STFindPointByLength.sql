SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STFindPointByLength] ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'Original Linestring as backdrop for SSMS mapping' as locateType, [$(lrsowner)].[STFindPointByLength](linestring,null,0,3,2).STBuffer(1) as lengthSegment from data as a
union all
select 'Null length (-> NULL)'                            as locateType, [$(lrsowner)].[STFindPointByLength](linestring,null,0,3,2).STBuffer(1) as lengthSegment from data as a
union all
select 'Measure = Before First SM -> NULL)'               as locateType, [$(lrsowner)].[STFindPointByLength](linestring,0.1,0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = 1st Segment SP -> SM'                   as locateType, [$(lrsowner)].[STFindPointByLength](linestring,1,0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = 1st Segment EP -> EM'                   as locateType, [$(lrsowner)].[STFindPointByLength](linestring,5.6,0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = MidPoint 1st Segment -> NewM'           as locateType, [$(lrsowner)].[STFindPointByLength](linestring,2.3,0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = 2nd Segment MP -> NewM'                 as locateType, [$(lrsowner)].[STFindPointByLength](linestring,10.0,0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = Last Segment Mid Point'                 as locateType, [$(lrsowner)].[STFindPointByLength](linestring,20.0,0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = Last Segment End Point'                 as locateType, [$(lrsowner)].[STFindPointByLength](linestring,25.4,0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = After Last Segment''s End Point Measure' as locateType,[$(lrsowner)].[STFindPointByLength](linestring,50.0,0,3,2).STBuffer(2) as lengthSegment from data as a;
GO

-- Now with offset
with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'LineString' as locateType, linestring from data as a
union all
select 'Measure = First Segment Start Point' as locateType,[$(lrsowner)].[STFindPointByLength](linestring,1,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = First Segment End Point' as locateType,  [$(lrsowner)].[STFindPointByLength](linestring,5.6,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure is middle First Segment' as locateType,    [$(lrsowner)].[STFindPointByLength](linestring,2.3,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = Second Segment Mid Point' as locateType, [$(lrsowner)].[STFindPointByLength](linestring,10.0,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = Last Segment Mid Point' as locateType,   [$(lrsowner)].[STFindPointByLength](linestring,20.0,-1.0,3,2).STBuffer(2) as lengthSegment from data as a
union all
select 'Measure = Last Segment End Point' as locateType,   [$(lrsowner)].[STFindPointByLength](linestring,25.4,-1.0,3,2).STBuffer(2) as lengthSegment from data as a;
GO

-- Find by Length plus left/right offsets

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select g.intValue as length,
       o.IntValue as offset,
       [$(lrsowner)].[STFindPointByLength](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.5) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M,
                                    round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1),
                                     2 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select g.intValue as length,
       o.IntValue as offset,
       [$(lrsowner)].[STFindPointByLength](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).STBuffer(0.5) as fPoint
  from data as a
       cross apply
       [$(owner)].generate_series(1,
                                  a.lineString.STNumPoints(),
                                  1 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as length, 
       null as offset,
       linestring.STBuffer(0.2)
  from data as a;
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

-- Measured Linestring with curves...
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

-- Measure Circular Curve test.
select f.ratio,
       CAST(o.IntValue as numeric) / 2.0 as offset,
       [$(lrsowner)].[STFindPointByRatio] (
          /* @p_linestring*/ geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 NULL 0, 0 7 NULL 3.08, -3 6.3246 NULL 6.15),(-3 6.3246 NULL 6.15, 0 0 NULL 10.1, 3 6.3246 NULL 20.2))',0),
          /* @p_ratio     */ f.ratio,
          /* @p_offset    */ CAST(o.IntValue as numeric) / 2.0,
          /* @p_round_xy  */   3,
          /* @p_round_zm  */   2
       ) as fPoint
  from (select /* @p_ratio */ 0.01 * CAST(t.IntValue as numeric) as ratio
          from [$(owner)].[Generate_Series](1,100,10) as t
       ) as f
       cross apply 
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as ratio,
       null as offset,
       geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 NULL 0, 0 7 NULL 3.08, -3 6.3246 NULL 6.15),(-3 6.3246 NULL 6.15, 0 0 NULL 10.1, 3 6.3246 NULL 20.2))',0).STBuffer(0.1);
GO


