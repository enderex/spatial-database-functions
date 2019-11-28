SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STToGeography]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
  DROP FUNCTION [$(owner)].[STToGeography];
  PRINT 'Dropped STToGeography...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STToGeometry]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
  DROP FUNCTION [$(owner)].[STToGeometry]
  Print 'Dropped STToGeometry...';
END;
GO

Print 'Creating [$(owner)].[STToGeography] ...';
GO

CREATE FUNCTION [$(owner)].[STToGeography] 
(
  @p_geom geometry,
  @p_srid Int = null
)
Returns geography
As
/****f* CONVERSION/STToGeography (2008)
 *  NAME
 *    STToGeography - Given a geometry object returns a geography object.
 *  SYNOPSIS
 *    Function STToGeography (
 *       @p_geom geometry,
 *       @p_srid Int = NULL
 *     )
 *     Returns geography
 *  EXAMPLE
 *
 *    SELECT [$(owner)].[STToGeography] (
 *             geometry::STGeomFromText('LINESTRING(147.234 -43.2345, 148.234 -43.2345)',0),
 *             4326
 *           ).STAsText() 
 *     as geog
 *    GO
 *    geog
 *    LINESTRING(147.234 -43.2345, 148.234 -43.2345)
 *
 *  DESCRIPTION
 *    Given valid geometry object this function converts it to a geography object, assigns @p_srid value and returns. 
 *    The @p_srid value should be a valid geography SRID.
 *    Mainly useful for converting 2008 geometry objects with geographic data to 2012+ geography objects.  *  INPUTS
 *    @p_geom (geometry) - A valid geometry object.
 *    @p_srid      (int) - Valid geographic SRID. If null, uses SRID associated with supplied geometry.
 *  RESULT
 *    geography (geography) - Geography object.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Aug 20012 - Initial SQL Server 20012 implementation
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Return geography::STGeomFromText( @p_geom.AsTextZM(), ISNULL(@p_srid,@p_geom.STSrid) );
End;
GO

Print 'Creating [$(owner)].[STToGeometry] ...';
GO

CREATE FUNCTION [$(owner)].[STToGeometry] 
(
  @p_geog geography,
  @p_srid Int = null
)
Returns geometry
As
/****f* CONVERSION/STToGeometry (2012)
 *  NAME
 *    STToGeometry - Given a geography object returns a geometry object.
 *  SYNOPSIS
 *    Function STToGeometry (
 *       @p_geog geography,
 *       @p_srid Int = NULL
 *     )
 *     Returns geometry
 *  EXAMPLE
 *
 *    SELECT [$(owner)].[STToGeometry] (
 *             geography::STGeomFromText('LINESTRING(147.234 -43.2345, 148.234 -43.2345)',4326),
 *             NULL
 *           ).STAsText() as geom;
 *    GO
 *    geom
 *    LINESTRING (147.234 -43.2345, 148.234 -43.2345)
 *
 *  DESCRIPTION
 *    Given valid geography object this function converts it to a geometry object, assigns @p_srid value and returns. 
 *    The @p_srid value should be a valid projected SRID.
 *    Mainly useful for converting 2012 geography objects to geometry equalivalent to be able to use functions only available for geometry. 
 *  INPUTS
 *    @p_geog (geography) - A valid geographic object.
 *    @p_srid       (int) - Valid projected SRID. If null, uses SRID associated with supplied geography
 *  RESULT
 *    geometry (geometry) - Geometry object.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Aug 20012 - Initial SQL Server 20012 implementation
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Return geometry::STGeomFromText( @p_geog.AsTextZM(), ISNULL(@p_srid,@p_geog.STSrid) );
End;
GO

