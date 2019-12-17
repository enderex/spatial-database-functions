SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing:';
Print '  [$(lrsowner)].[STProjectPoint] ...';
GO

select CAST('Actual Measure' as varchar(50)) as test,
       [$(lrsowner)].[STProjectPoint] (
          geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
          geometry::Point(8,8,28355),
          3,2).AsTextZM() as project_point
union all
select '2D return length in measure' as test,
       [$(lrsowner)].[STProjectPoint] (
          geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
          geometry::Point(8,8,28355),
          3,2).AsTextZM() as project_point
union all
select 'Point has relationship with XYZM circular arc' as test,
       [$(lrsowner)].[STProjectPoint] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.325 -2.1 0, 0 7 -2.1 3.08, -3 6.325 -2.1 6.15)',0),
          geometry::Point(2,8,0),
          3,2).AsTextZM() as project_point
union all
select 'Point does not have relationship with XYM CircularSring' as test,
       [$(lrsowner)].[STProjectPoint] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),
          geometry::Point(8,8,0),
          3,2).AsTextZM() as project_point
union all
select 'Point is on centre of the circular arc' as test,
       [$(lrsowner)].[STProjectPoint] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.3246 -1, 0 7 -1, -3 6.3246 -1)',0),
          geometry::Point(0,0,0),
          3,2).AsTextZM() as project_point
union all
select 'Point projects on to point half way along circular arc' as test,
       [$(lrsowner)].[STProjectPoint] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0),
          geometry::Point(0,3.5,0),
          3,2).AsTextZM() as project_point
select 'Closest to LineString' as test,
       [$(lrsowner)].[STProjectPoint] (
          geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
          geometry::Point(-1,1,0),
          3,2).AsTextZM() as project_point
Union all
select 'Closest to CircularString' as test,
       [$(lrsowner)].[STProjectPoint] (
          geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
          geometry::Point(2,8,0),
          3,2).AsTextZM() as project_point;
GO

-- **********************************************************************************

Print '  [$(lrsowner)].[STFindMeasureByPoint] ...';
GO
select [$(lrsowner)].[STFindMeasureByPoint] (
          geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
          geometry::Point(8,8,28355),
          3,2) as measure
union all
select [$(lrsowner)].[STFindMeasureByPoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(10,0,28355),
         3,2) as measure;
GO

-- *******************************************************

Print '  [$(lrsowner)].[STFindMeasure] ...';
GO
select [$(lrsowner)].[STFindMeasure](
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(8,8,28355),
         3,2) as measure
union all
select [$(lrsowner)].[STFindMeasure](
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(10,0,28355),
         3,2) as measure;
GO

Print '  [$(lrsowner)].[STFindOffset] ...';
GO
select [$(lrsowner)].[STFindOffset] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(8,8,28355),
         3,2) offset_distance
union all
select [$(lrsowner)].[STFindOffset] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(10,0,28355),
         3,2);
GO

select [$(owner)].[STRound]( 
          [$(lrsowner)].[STProjectPoint](geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0),
          geometry::Point(1,7.5,0),3,2),3,3,2,2).AsTextZM()

select [$(owner)].[STRound]( 
          [$(lrsowner)].[STProjectPoint] (
		         geometry::STGeomFromText('CircularString (2172207.12090003490447998 256989.8612000048160553 NULL 11200, 2172337.52737651020288467 257437.9648682993138209 NULL 0, 2172663.83167292177677155 257771.62375517189502716 NULL 12142.83130000000528526)',0),
                 geometry::Point(2472207,257137.11,0),
				 3,2),3,3,2,2).AsTextZM()

