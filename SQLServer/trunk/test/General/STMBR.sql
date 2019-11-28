SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing ....';
GO

select f.* from [$(owner)].[STGeometry2MBR](geometry::STGeomFromText('POLYGON((0 0,10 0,10 20,0 20,0 0))',0)) as f;

-- First, let's create a simple polygon geometry
--
select [$(owner)].[STMBR2Geometry](0,0,100,100,28355,0).STAsText() as geomWKT;
GO

-- Or a polyon geography
select [$(owner)].[STMBR2Geography](147.8347938734,-32.34937894309,148.239230982,-31.93337,4283,8).STAsText() as geomWKT;
GO

-- Now, let's create a polygon with a hole
--
select [$(owner)].[STMBR2Geometry] (0,0,100,100,28355,0)
                 .STDifference([$(owner)].[STMBR2Geometry] (40,40,60,60,28355,0))
                 .STAsText() as geomWKT;
GO

-- Now let's create a multipolygon with a hole
--
select [$(owner)].[STMBR2Geometry] (0,0,100,100,28355,0)
                 .STDifference([$(owner)].[STMBR2Geometry] (40,40,60,60,28355,0))
                 .STUnion     ([$(owner)].[STMBR2Geometry] (200,200,400,400,28355,0))
                 .STAsText() as geomWKT;
GO

-- Finally, let's create a polygon with a hole using the mbr2geography function
--
select [$(owner)].[STMBR2Geography] (147,-44,148,-43,4326,0)
                 .STDifference([$(owner)].[STMBR2Geography] (147.4,-43.6,147.6,-43.2,4326,2))
                 .STAsText() as geogWKT;
GO

with data as (
  select geometry::STGeomFromText('POLYGON ((0 0,100 0,100 10,0 10,0 0))',0) as geom
)
SELECT [$(owner)].[STMBRLongestSide] (a.geom) as length
  FROM data as a;
GO

with data as (
  select geometry::STGeomFromText('POLYGON ((0 0,100 0,100 10,0 10,0 0))',0) as geom
)
SELECT [$(owner)].[STMBRShortestSide] (a.geom) as length
  FROM data as a;
GO


