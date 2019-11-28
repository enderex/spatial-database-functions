SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

Print 'Testing [$(owner)].[STOneSidedBuffer] ...';
GO

with data as (
select 'Ordinary 2 Point Linestring' as test, geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0) as linestring
union all
select 'Self Joining Linestring'     as test, geometry::STGeomFromText('LINESTRING(0 0,1 0,2 3,4 5,2 10,-1 5,0 0)',0) as linestring
union all
select 'Ends within buffer distance' as test, geometry::STGeomFromText('LINESTRING(0 0,1 0,2 3,4 5,2 10,-1 5,0 0.3)',0) as linestring
)
select d.linestring.STAsText() as sqBuff from data as d
union all
select [$(owner)].[STOneSidedBuffer](d.linestring,/*BuffDist*/0.5,/*@p_square*/1,2,1).STAsText() as sqBuff from data as d;
GO

select geometry::STGeomFromText('LINESTRING(0 0, 10 0, 10 10, 0 10,0 0)',0) as geom
union all
select [$(owner)].[STOneSidedBuffer](geometry::STGeomFromText('LINESTRING (0 0, 10 0, 10 10, 0 10,0 0)',0),-1.0,1,3,2)
union all
select [$(owner)].[STOneSidedBuffer](geometry::STGeomFromText('LINESTRING (0 0, 10 0, 10 10, 0 10,0 0)',0),1.0,0,3,2);
GO

-- Nearly closed
select geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0).STBuffer(0.01) as rGeom
union all
select [$(owner)].[STOneSidedBuffer] (geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0),-0.5,1,3,1).STAsText() as pGeom;
GO


