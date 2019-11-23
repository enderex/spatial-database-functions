USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS(lrs) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STIsMeasured]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STIsMeasured];
  PRINT 'Dropped [$(lrsowner)].[STIsMeasured] ... ';
END;
GO

PRINT 'Creating STIsMeasured...';
GO

CREATE FUNCTION [$(lrsowner)].[STIsMeasured] 
(
  @p_geometry geometry
)
Returns varchar(5)
As
/****m* LRS/STIsMeasured (2012)
 *  NAME
 *    STIsMeasured -- Function checks if supplied linestring has measures.
 *  SYNOPSIS
 *    Function [$(lrsowner)].[STIsMeasured] (
 *       @@p_geometry geometry
 *     )
 *     Returns varchar(5)
 *  USAGE
 *    WITH data AS (
 *     select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.4 16.3, 3 6.3 1.6 20.2))',0) as Geom
 *     union all
 *     select geometry::STGeomFromText('LINESTRING(0 0, 100 100)',0) 
 *     union all
 *     select geometry::STGeomFromText('LINESTRING(0 0 0.1, 100 100 99.8)',0) 
 *     union all
 *     select geometry::STGeomFromText('LINESTRING(0 0 0 0.1, 100 100 0 99.8)',0) 
 *     union all
 *     select geometry::STPointFromText('POINT(0 0)',0) 
 *     union all
 *     select geometry::STPointFromText('POINT(0 0 1.1)',0) 
 *     union all
 *     select geometry::STPointFromText('POINT(0 0 1.1 2.2)',0) 
 *    )
 *    SELECT d.geom.STGeometryType() as gType, 
 *           dbo.STCoordDim(d.geom) as cDim,
 *           [lrs].[STIsMeasured]( d.geom ) as isMeasured
 *      FROM data as d;
 *    GO
 *    
 *    gType         cDim isMeasured
 *    CompoundCurve 4          TRUE
 *    LineString    2         FALSE
 *    LineString    3         FALSE
 *    LineString    4          TRUE
 *    Point         2         FALSE
 *    Point         3         FALSE
 *    Point         4          TRUE
 *  DESCRIPTION
 *    Returns TRUE if @p_linestring has measures, FALSE otherwise.
 *    Supports CircularString and CompoundCurve geometry objects and subelements from 2012 onewards.
 *  INPUTS
 *    @p_geometry (geometry) - Supplied geometry.
 *  RESULT
 *    BOOLEAN (varchar5) - True if @p_geometry has measures otherwise False.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2017 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  If ( @p_geometry is null ) 
    Return 'FALSE';
  /* Nothing to do if not measured */
  IF ( @p_geometry.HasM=0 )
      Return 'FALSE';
  Return 'TRUE';
END
GO

-- *************************************************************
-- Tests

WITH data AS (
 select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.4 16.3, 3 6.3 1.6 20.2))',0) as Geom
 union all
 select geometry::STGeomFromText('LINESTRING(0 0, 100 100)',0) 
 union all
 select geometry::STGeomFromText('LINESTRING(0 0 0.1, 100 100 99.8)',0) 
 union all
 select geometry::STGeomFromText('LINESTRING(0 0 0 0.1, 100 100 0 99.8)',0) 
 union all
 select geometry::STPointFromText('POINT(0 0)',0) 
 union all
 select geometry::STPointFromText('POINT(0 0 1.1)',0) 
 union all
 select geometry::STPointFromText('POINT(0 0 1.1 2.2)',0) 
)
SELECT d.geom.STGeometryType() as gType, 
       dbo.STCoordDim(d.geom) as cDim,
       [$(lrsowner)].[STIsMeasured]( d.geom ) as isMeasured
  FROM data as d;
GO

