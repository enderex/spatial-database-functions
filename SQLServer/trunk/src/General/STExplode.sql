USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT *
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STExplode]') 
              AND OBJECTPROPERTY(id, N'IsTableFunction') = 1)
BEGIN
  DROP FUNCTION [$(owner)].[STExplode];
  PRINT 'Dropped [$(owner)].[STExplode] ...';
END;
GO

PRINT 'Creating [$(owner)].[STExplode] ...';
GO

CREATE FUNCTION [$(owner)].[STExplode]
(
  @p_geometry geometry
)
 Returns @geometries TABLE
(
  gid  integer,
  sid  integer,
  geom geometry
)  
AS
/****f* GEOPROCESSING/STExplode (2012)
 *  NAME
 *    STExplode -- STExplode is a wrapper function over STExtract with sub_element parameter set to 1 
 *  SYNOPSIS
 *    Function [$(owner)].[STExplode] (
 *               @p_geometry geometry,
 *             )
 *     Returns @geometries TABLE 
 *     (
 *       gid  integer,
 *       sid  integer,
 *       geom geometry
 *     )  
 *  DESCRIPTION
 *    This function calls STExtract with @p_sub_geom set to 2.
 *    This ensures all possible elements and subelements of a geometry are extracted.
 *  NOTES
 *    This version is for versions of SQL Server from 2012 onwards.
 *  INPUTS
 *    @p_geometry (geometry) - Polygon or Multipolygon geometry object.
 *  EXAMPLE
 *
 *    SELECT t.gid, t.sid, t.geom.STAsText() as geom
 *      FROM [$(owner)].[STExplode] (
 *    GEOMETRY::STGeomFromText (
 *    'CURVEPOLYGON(
 *      COMPOUNDCURVE(
 *       (0 -23.43778, 0 23.43778),
 *       CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), 
 *       (-90 23.43778, -90 -23.43778),
 *       CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)
 *      )
 *    )',0)) as t;
 *    GO
 *    
 *    gid sid geom
 *    --- --- -------------------------------------------
 *      1   1 LINESTRING (0 -23.43778, 0 23.43778)
 *      1   2 CIRCULARSTRING (0 23.43778, -45 23.43778, -90 23.43778)
 *      1   3 LINESTRING (-90 23.43778, -90 -23.43778)
 *      1   4 CIRCULARSTRING (-90 -23.43778, -45 -23.43778, 0 -23.43778)
 *
 *  RESULT
 *    Array of subelements:
 *    gid  - Geometry Identifier (for multigeomemtry objects, the individual high level geometry objects it describes).
 *    sid  - Sub Element Identifier
 *    geom - Geometry representation of subelement.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan 2013 - Original coding.
 *    Simon Greener - Jan 2015 - Port to TSQL SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  If ( @p_geometry is NULL ) 
    return;
  INSERT INTO @geometries ( 
               [gid],
               [sid],
               [geom] ) 
       SELECT e.gid,
              e.sid,
              e.geom
         FROM [$(owner)].[STExtract](@p_geometry,2) as e; 
  RETURN;
END
GO

PRINT 'Testing [$(owner)].[STExplode] ...';
GO

With data as (
  SELECT GEOMETRY::STGeomFromText(
'CURVEPOLYGON(
    COMPOUNDCURVE(
      (0 -23.43778, 0 23.43778),
      CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), 
      (-90 23.43778, -90 -23.43778),
      CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)
    )
  )
',0) as geom
)
select CAST('Original' as varchar(10)) as result, 0, 0, geom.AsTextZM() as geom from data as d
UNION ALL
select 'Explode' as result, t.gid, t.sid, t.geom.AsTextZM() as geom
  From data as d
       cross apply
       [$(owner)].[STExplode](d.geom) as t;
GO


