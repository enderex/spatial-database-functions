SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
 
PRINT 'Testing [$(owner)].[STIsPseudoMultiCurve]....';
GO

-- Produces 2D pseudo MultiCurve
select         geometry::STGeomFromText('MULTILINESTRING((-5 0 0 1,-2.5 -2.5 0 1.5,-0.5 -0.5 0 5.6), (0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6))',0)
      .STUnion(geometry::STGeomFromText('CIRCULARSTRING(-0.5 -0.5 0 5.6,-0.2 -0.4 0 5.5, -0.1 -0.1 0 5.65)',0)).AsTextZM() as MultiCurve;
GO

select f.MultiCurve.STGeometryType() as gType,
       [$(owner)].[STIsPseudoMultiCurve] ( f.MultiCurve ) as isPseudoMultiCurve
  from (select geometry::Point(0,0,0) as MultiCurve
        union all
        select geometry::STGeomFromText('LINESTRING(-5 0 0 1,-2.5 -2.5 0 1.5,-0.5 -0.5 0 5.6)',0) as MultiCurve
        union all
        select geometry::STGeomFromText('MULTILINESTRING((-5 0 0 1,-2.5 -2.5 0 1.5,-0.5 -0.5 0 5.6), (0 0 0 5.6, 5 5 0 6.3,5 10 0 9.6))',0) as MultiCurve
        union all
        select geometry::STGeomFromText('GEOMETRYCOLLECTION (LINESTRING (5 10, 5 5, 0 0), COMPOUNDCURVE ((-5 0, -2.5 -2.5, -0.5 -0.5), CIRCULARSTRING (-0.5 -0.5, -0.2 -0.4, -0.1 -0.1)))',0) as MultiCurve
        union all
        select geometry::STGeomFromText('GEOMETRYCOLLECTION (LINESTRING (5 10 0 0, 5 5, 0 0 0 5), COMPOUNDCURVE ((-5 0 0 10, -2.5 -2.5 0 11.2, -0.5 -0.5 0 12.1), CIRCULARSTRING (-0.5 -0.5 0 12.1, -0.2 -0.4 0 13.4, -0.1 -0.1 0 14.2)))',0) as MultiCurve
       ) as f;
GO


