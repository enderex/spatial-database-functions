SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STAverageBearing]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STAvergeBearing];
  Print 'Dropped [$(owner)].[STAverageBearing] ...';
END;
GO

Print 'Creating [$(owner)].[STAverageBearing] ...';
GO

CREATE FUNCTION [$(owner)].[STAvergeBearing] (
  @p_linestring geometry
)
RETURNS Float
AS
/****f* COGO/STAvergeBearing (2012)
 *  NAME
 *    [STAvergeBearing] -- Function that computes average bearing of segments in linestring.
 *  SYNOPSIS
 *    Function [STAvergeBearing] (
 *               @p_linestring geometry
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Function that computes the bearing of each and every segment of a linestring, and then averages the result across all segment.
 *  INPUTS
 *    @p_linestring (geometry) - Supplied Linestring geometry.
 *  RESULT
 *    averge bearing   (float) - Aveage of bearing of all segments in linestring.
 *  EXAMPLE
 *    -- All testing includes reverse.
 *    -- Testing 4 Point Linestring All Points Collinear
 *    select [$(owner)].[STAvergeBearing] (geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,3 0)',0)  ) as avgBearing
 *    union all
 *    select [$(owner)].[STAvergeBearing] ([$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,3 0)',0),DEFAULT,DEFAULT)) as avgBearing
 *    go
 *    
 *    avgBearing
 *    90
 *    270
 * 
 *    --Non Collinear test ...
 *    
 *    select [$(owner)].[STAvergeBearing] ( geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0) ) as avgBearing
 *    union all
 *    select [$(owner)].[STAvergeBearing] ( [$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0),DEFAULT,DEFAULT)) as avgBearing
 *    GO
 *    
 *    avgBearing
 *    136.268038349182
 *    172.268038349182
 *  NOTES
 *    Uses [location].[STFindDeflectionAngle]
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - October 2019 - Original TSQL Coding
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_GeometryType    varchar(100),
    @v_average_bearing float;

  IF ( @p_linestring is null )
    RETURN NULL;

  SET @v_GeometryType = @p_linestring.STGeometryType();
  -- MultiLineString Supported by alternate processing.
  IF ( @v_GeometryType NOT IN ('LineString','MultiLineString') ) -- 'CompoundCurve','CircularString' ) )
    RETURN NULL;

  SELECT @v_average_bearing = AVG(f.bearing)
    FROM (SELECT [$(cogoowner)].[STBearingBetweenPoints] ( v.geom.STStartPoint(), v.geom.STEndPoint() ) as bearing
            FROM [$(owner)].[STVectorize] ( @p_linestring ) as v
         ) as f;

  RETURN @v_average_bearing;       
END
GO

PRINT 'Testing ....'
go

Print '1. Testing Ordinary 2 Point Linestring ...';
GO

select [$(owner)].[STAvergeBearing] (geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0) ) as avgBearing
union all
select [$(owner)].[STAvergeBearing] ([$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0),DEFAULT,DEFAULT)) as avgBearing
GO

Print '2. Testing 4 Point Linestring All Points Collinear - Special Case...';
GO

select [$(owner)].[STAvergeBearing] (geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,3 0)',0)  ) as avgBearing
union all
select [$(owner)].[STAvergeBearing] ([$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,3 0)',0),DEFAULT,DEFAULT)) as avgBearing
go

PRINT '3. Testing More complex Linestring...'
GO 

select [$(owner)].[STAvergeBearing] ( geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0) ) as avgBearing
union all
select [$(owner)].[STAvergeBearing] ( [$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0),DEFAULT,DEFAULT)) as avgBearing
GO

PRINT '4. Testing Nearly Closed Loop Linestring'
GO

select [$(owner)].[STAvergeBearing] ( geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5, 0 -2, 0 -1)',0) ) as avgBearing
union all
select [$(owner)].[STAvergeBearing] ( [$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5, 0 -2, 0 -1)',0),DEFAULT,DEFAULT) ) as avgBearing
go


