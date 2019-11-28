SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[Generate_Series] ...';
GO

-- Simple increment by 1
SELECT g.IntValue as generate_series FROM [$(owner)].[Generate_Series](2,4,1) g;
GO

-- Increment using Default value (1)
SELECT g.IntValue as generate_series FROM [$(owner)].[Generate_Series](1,5,DEFAULT) g;
GO

-- Increase in steps of 10
SELECT g.IntValue as generate_series FROM [$(owner)].[Generate_Series](100,200,10) g;
GO

-- Negative decrement
SELECT g.IntValue as generate_series FROM [$(owner)].[Generate_Series](5,1,-2) g;
GO

-- Invalid test
SELECT g.IntValue as generate_series FROM [$(owner)].[Generate_Series](4,3,1) g;
GO

-- Increment negative numbers
SELECT g.IntValue as generate_series FROM [$(owner)].[Generate_Series](-4,-1,1) g;
GO

-- generate some dates
SELECT convert(varchar(20),GETDATE() + sa.IntValue,112) as dates FROM [$(owner)].[Generate_Series](0,14,7) sa;
GO

-- Generate some points
SELECT f.id, 
       geometry::Point(f.x,f.y,0 /* SRID */ ).STAsText()  as geom
  FROM ( SELECT sa.IntValue as id,
                ROUND(10000 * RAND(CHECKSUM(NEWID())) +  353880,2) as x,
                ROUND(5000  * RAND(CHECKSUM(NEWID())) + 5404973,2) as y
           FROM [$(owner)].[Generate_Series](1,25,1) sa
        ) f
order by 1 asc;
GO

-- Extract Points from a geometry
SELECT sa.IntValue as pointN,
       a.geom.STPointN(sa.IntValue).STX as x,
       a.geom.STPointN(sa.IntValue).STY as y
  FROM (select geometry::STGeomFromText('LINESTRING(0 0,1 0,1 1,2 1,2 2)',0) as geom) a
       cross apply
       [$(owner)].[Generate_Series](1,a.geom.STNumPoints(),1) sa;
GO

