SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [dbo].[STOffsetLine] ...';
Print '1. Testing Ordinary 2 Point Linestring ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0) as linestring
)
-- Select f.pGeom.AsTextZM() as pGeom 
Select f.pGeom.STBuffer(0.01) as pGeom 
  from (select d.linestring as pGeom from data as d
        union all
        select [dbo].[STOffsetLine](d.linestring, 0.5,2,1) as pGeom from data as d
        union all
        select [dbo].[STOffsetLine](d.linestring,-0.5,2,1) as pGeom from data as d
       ) as f;
GO

Print '2. Testing 4 Point Linestring All Points Collinear - Special Case...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,3 0)',0) as linestring
)
-- Select f.pGeom.AsTextZM() as pGeom 
Select f.pGeom.STBuffer(0.01) as pGeom 
  from (select d.linestring as pGeom from data as d
        union all
        select [dbo].[STOffsetLine](d.linestring, 0.5,2,1) as pGeom from data as d
        union all
        select [dbo].[STOffsetLine](d.linestring,-0.5,2,1) as pGeom from data as d
       ) as f;
GO

PRINT '3. Testing More complex Linestring...';
GO

use DEVDB
go

DECLARE @p_linestring geometry =geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0);
DECLARE @v_exterior_rings geometry = [dbo].[STOneSidedBuffer](@p_linestring,-0.5,1,4,3).STExteriorRing();
DECLARE @v_linestring_buffer geometry = @p_linestring.STBuffer(0.002);
       SELECT geometry::STGeomFromText(
              'LINESTRING (' + 
		                  STRING_AGG(
                            REPLACE(REPLACE(geometry::Point(g.x,g.y,0).STAsText(),'POINT (',''),')',''),
                            ',' 
                          ) 
				          WITHIN GROUP (ORDER BY g.uid ASC) 
                       +
                       ')',0)
         FROM (/* Process all points removing those inside @v_linestring_buffer */
		       SELECT d1.uid, d1.x, d1.y
                 FROM [dbo].[STVertices](@v_exterior_rings) as d1
               EXCEPT
               SELECT d1.uid, d1.x, d1.y
                 FROM [dbo].[STVertices](@v_exterior_rings) as d1
                WHERE d1.point.STWithin(@v_linestring_buffer) = 1
             ) g;

with data as (
select geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0) as linestring
)
select -1.0 as offset, d.linestring.STStartPoint().STBuffer(0.5) as pGeom from data as d
union all
select 0.0 as offset, d.linestring.STBuffer(0.08) as pGeom from data as d
union all
--select 0.5 as offset, [dbo].[STOffsetLine](d.linestring, 0.5,4,1) as pGeom from data as d
--union all
select -0.5 as offset, [dbo].[STOffsetLine](d.linestring,-0.5,4,1) as pGeom from data as d;
GO

PRINT '4. Testing Nearly Closed Loop Linestring';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5, 0 -2, 0 -1)',0) as linestring
)
Select f.pGeom.STAsText() as pGeom 
  from (select d.linestring as pGeom from data as d
        union all
        select [dbo].[STOffsetLine](d.linestring, 0.5,2,1) as pGeom from data as d
        union all
        select [dbo].[STOffsetLine](d.linestring,-0.5,2,1) as pGeom from data as d
      ) as f;
GO

PRINT 'Testing Closed Loop Linestring +ve case -- FAILS';
GO

with data as (
  select geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5, 0 -2, 0 0)',0) as linestring
)
Select f.pGeom as pGeom 
  from (select 0.0 as offset, d.linestring as pGeom from data as d
        union all
        select 0.5 as offset, [dbo].[STOffsetLine](d.linestring, 0.5,2,1) as pGeom from data as d
        union all
        select -0.5 as offset, [dbo].[STOffsetLine](d.linestring,-0.5,2,1) as pGeom from data as d
      ) as f;
GO

PRINT 'Last Test -- FAILS';
GO

SELECT geometry::STGeomFromText('LINESTRING (63.29 914.361, 73.036 899.855, 80.023 897.179, 79.425 902.707, 91.228 903.305, 79.735 888.304, 98.4 883.584, 115.73 903.305, 102.284 923.026, 99.147 899.271, 110.8 902.707, 90.78 887.02, 96.607 926.911, 95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0)
         .STBuffer(0.2)
          as geom
UNION ALL
SELECT [dbo].[STOffsetLine] (
         geometry::STGeomFromText('LINESTRING (63.29 914.361, 73.036 899.855, 80.023 897.179, 79.425 902.707, 91.228 903.305, 79.735 888.304, 98.4 883.584, 115.73 903.305, 102.284 923.026, 99.147 899.271, 110.8 902.707, 90.78 887.02, 96.607 926.911, 95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0),
         0.5,
         3,
         1
       ).STAsText() as oGeom;
GO

