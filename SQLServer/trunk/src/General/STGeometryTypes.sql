SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STGeometryTypes]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STGeometryTypes];
  Print 'Dropped [$(owner)].[STGeometryTypes] ...';
END;
GO

Print 'Creating [$(owner)].[STGeometryTypes] ...';
GO

CREATE FUNCTION [$(owner)].[STGeometryTypes](
  @p_geometry geometry 
)
 Returns varchar(MAX)
As
/****f* INSPECT/STGeometryTypes (2012)
  *  NAME
  *    STGeometryTypes -- Extracts all geometry type keywords from a geometry (and its sub-elements)
  *  SYNOPSIS
  *    Function [$(owner)].[STGeometryTypes](
  *               @p_geometry geometry
  *             )
  *      Returns geometry
  *  DESCRIPTION
  *    Returns list of geometry types (from OGC STGeometryType function)
  *    that describe the contents of the passed in geometry.
  *    All complex geometries are "exploded" to extract sub element geometry types
  *    Geography objects can be processed by converting to geometry using
  *    dbo.STToGeometry() function. 
  *  ARGUMENTS
  *    @p_geometry (geometry) - Any valid geomtery
  *  RESULT
  *    string -- list of geometry types are appear (in order) in geometry.
  *  EXAMPLE
  *    -- Simple geometry
  *    select dbo.[STGeometryTypes](geometry::STGeomFromText('POINT(0 1 2)',0)) as gtypes;
  *    go
  *    gtypes
  *    POINT
  *
  *    -- Single CurvePolygon with one interior ring
  *    select [$(owner)].[STGeometryTypes](geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 5, 5 0, 0 -5, -5 0, 0 5), (-2 2, 2 2, 2 -2, -2 -2, -2 2))',0)) as gtypes;
  *    GO
  *    gtypes
  *    CURVEPOLYGON,CIRCULARSTRING
  *
  *    -- GeometryCollection
  *    select  [$(owner)].[STGeometryTypes](
  *    geometry::STGeomFromText(
  *             'GEOMETRYCOLLECTION(
  *                      LINESTRING(0 0,20 0,20 20,0 20,0 0), 
  *                      CURVEPOLYGON(
  *                           COMPOUNDCURVE(
  *                                   (0 -23.43778, 0 23.43778),
  *                                   CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),
  *                                   (-90 23.43778, -90 -23.43778),
  *                                   CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), 
  *                      COMPOUNDCURVE(
  *                              CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), 
  *                              (0 -23.43778, 0 23.43778)))',0)) as gTypes;
  *    GO
  *    gTypes
  *    GEOMETRYCOLLECTION,LINESTRING,CURVEPOLYGON,COMPOUNDCURVE,CIRCULARSTRING,CIRCULARSTRING,COMPOUNDCURVE,CIRCULARSTRING
  *    
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - April 2019 - SQL Server Spatial
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_return varchar(MAX);
  Begin
    If ( @p_geometry is NULL ) 
      return NULL;

    SELECT @v_return = SUBSTRING(a.token,2,LEN(a.token))
      FROM (SELECT (STUFF((SELECT ',' + a.token
                             FROM (select t.token
                                     from [$(owner)].[Tokenizer](@p_geometry.AsTextZM(),' ,)(') as t
                                   ) as a
                            WHERE a.token is not null
                              AND a.token not like '%[0-9]%'
                           FOR XML PATH(''), TYPE, ROOT
                          ).value('root[1]','nvarchar(max)'),1,1,'''')
                    ) AS token
            ) as a;

    RETURN @v_return;
   End;
End
GO

-- Simple geometry
select dbo.[STGeometryTypes](geometry::STGeomFromText('POINT(0 1 2)',0)) as gtypes;
go

-- Single CurvePolygon with one interior ring
select [$(owner)].[STGeometryTypes](geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 5, 5 0, 0 -5, -5 0, 0 5), (-2 2, 2 2, 2 -2, -2 -2, -2 2))',0)) as gtypes;
GO

-- GeometryCollection
select  [$(owner)].[STGeometryTypes](
geometry::STGeomFromText(
         'GEOMETRYCOLLECTION(
                  LINESTRING(0 0,20 0,20 20,0 20,0 0), 
                  CURVEPOLYGON(
                       COMPOUNDCURVE(
                               (0 -23.43778, 0 23.43778),
                               CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),
                               (-90 23.43778, -90 -23.43778),
                               CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))), 
                  COMPOUNDCURVE(
                          CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778), 
                          (0 -23.43778, 0 23.43778)))',0)) as gTypes;
GO

