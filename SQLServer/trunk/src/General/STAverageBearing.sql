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
  DROP FUNCTION [$(owner)].[STAverageBearing];
  Print 'Dropped [$(owner)].[STAverageBearing] ...';
END;
GO

Print 'Creating [$(owner)].[STAverageBearing] ...';
GO

CREATE FUNCTION [$(owner)].[STAverageBearing] (
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
 *    Function that computes the bearing of each and every segment of a linestring, and then averages the result across all segments.
 *    If @p_linestring contains CircularStrings the bearings will be from the startPoint to the midPoint, and the midPoint to the endPoint.
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
 * 
 *    -- CircularString Test
 *
 *    select [$(owner)].[STAverageBearing] (geometry::STGeomFromText('CIRCULARSTRING(0 0,1 1,2 0)',0)  ) as avgBearing;
 *
 *    avgBearing
 *    90
 *
 *    select [$(owner)].[STAverageBearing] (geometry::STGeomFromText('COMPOUNDCURVE((-2 -2,-1 -1,0 0),CIRCULARSTRING(0 0,1 1,2 0))',0) ) as avgBearing;
 *
 *    avgBearing
 *    67.5
 *  NOTES
 *    Uses [$(owner)].[STFindDeflectionAngle]
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - October 2019 - Original TSQL Coding
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_geometry_type   varchar(100),
    @v_average_bearing float;

  IF ( @p_linestring is null )
    RETURN NULL;

  SET @v_geometry_type= @p_linestring.STGeometryType();
  -- MultiLineString Supported by alternate processing.????
  IF ( @v_geometry_type NOT IN ('LineString','MultiLineString','CompoundCurve','CircularString' ) )
    RETURN NULL;

  SELECT @v_average_bearing = AVG(f.bearing)
    FROM (SELECT case when v.geometry_type = 'LineString'
                      then [$(cogoowner)].[STBearingBetweenPoints] ( 
                              v.segment.STStartPoint(),
                              v.segment.STEndPoint() 
                           )
                      else case when pointN.IntValue = 1 
                                then [$(cogoowner)].[STBearingBetweenPoints] ( 
                                        v.segment.STStartPoint(),
                                        v.segment.STPointN(2) 
                                     )
                                else [$(cogoowner)].[STBearingBetweenPoints] ( 
                                        v.segment.STPointN(2),
                                        v.segment.STEndPoint() 
                                     )
                            end
						end as bearing
            FROM [$(owner)].[STSegmentize] (
                   /* @p_geometry     */ @p_linestring,
                   /* @p_filter       */ 'ALL',
                   /* @p_point        */ NULL,
                   /* @p_filter_value */ NULL,
                   /* @p_start_value  */ NULL,
                   /* @p_end_value    */ NULL,
                   /* @p_round_xy     */ NULL,
                   /* @p_round_z      */ NULL,
                   /* @p_round_m      */ NULL
                 ) as v
				 cross apply
				 dbo.Generate_Series(1,v.segment.STNumPoints()-1,1) as pointN
         ) as f;

  RETURN @v_average_bearing;       
END;
GO
