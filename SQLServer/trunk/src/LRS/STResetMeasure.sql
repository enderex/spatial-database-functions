SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '****************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(lrsowner)].[STResetMeasure]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STResetMeasure];
  Print 'Dropped [$(lrsowner)].[STResetMeasure]';
END;
GO

Print 'Creating [$(lrsowner)].[STResetMeasure]';
GO

CREATE FUNCTION [$(lrsowner)].[STResetMeasure]
(
  @p_geometry       geometry,
  @p_marker_measure float = -999999999,
  @p_round_xy       int   = 3,
  @p_round_zm       int   = 2
)
Returns geometry
As 
/****f* LRS/STResetMeasure (2012)
 *  NAME
 *    STResetMeasure -- Function that sets all existing assigned measures to NULL.
 *  SYNOPSIS
 *    Function STResetMeasure (
 *       @p_geometry       geometry,
 *       @p_marker_measure float = -999999999,
 *       @p_round_xy       int = 3,
 *       @p_round_zm       int = 2
 *     )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(lrsowner).[STResetMeasure] (
 *             geometry::STGeomFromText('MULTILINESTRING((1 1 NULL 1,2 2 NULL 2),(3 3 NULL 3,4 4 NULL 4))',0),
 *             default,
 *             3,
 *             2).AsTextZM() as ResetMeasureLine
 *    GO
 *    ResetMeasureLine
 *    MULTILINESTRING ((1 1 NULL -999999999, 2 2 NULL -999999999), (3 3 NULL -999999999, 4 4 NULL -999999999))
 *  DESCRIPTION
 *    Sets all measures of a measured linesting to null values leaving dimensionality of geometry alone. 
 *    So, a linestring with XYM remains so, but all measures are set to @c_MarkerMeasure value of -999999999 unless user supplies otherwise.
 *    eg Coord 2 of 10.23,5.75,2.65 => 10.23,5.75,-999999999
 *    Supports CircularString and CompoundCurve geometry objects and subelements from 2012 onewards.
 *  NOTES
 *    This is not the same as STTo2D which removes measures etc and returns a pure 2D geometry.
 *  INPUTS
 *    @p_geometry    (geometry) - Supplied Linestring geometry.
 *    @p_marker_measure (float) - Marker Measure applied to all measure values: Default is -999999999,
 *    @p_round_xy         (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm         (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    M Null Geom (geometry) - Input geometry with all M ordinates set to NULL.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Converted to TSQL for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @c_MarkerMeasure float        = ISNULL(@p_marker_measure,-999999999),
    @v_GeometryType  varchar(100) = '',
    @v_dimensions    varchar(4)   = 'XYM',
    @v_wkt           varchar(max) = '',
    @v_wkt_remainder varchar(max) = '',
    @v_round_xy      int          = 3,
    @v_round_zm      int          = 2,
    @v_pos           int          = 0,
    @v_point         geometry;
  Begin
    If ( @p_geometry is NULL )
      Return @p_geometry;

    -- Only process linear geometries.
    SET @v_GeometryType = @p_geometry.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','CircularString','CompoundCurve','MultiLineString') )
      Return @p_geometry;

    SET @v_dimensions    = 'XY'
                           + case when @p_geometry.HasZ=1 then 'Z' else '' end +
                           + case when @p_geometry.HasM=1 then 'M' else '' end;
    SET @v_round_xy      = ISNULL(@p_round_xy,3);
    SET @v_round_zm      = ISNULL(@p_round_zm,2);
    SET @v_wkt_remainder = @p_geometry.AsTextZM();
    SET @v_wkt           = SUBSTRING(@v_wkt_remainder,1,CHARINDEX('(',@v_wkt_remainder));
    SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,  CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));

    WHILE ( LEN(@v_wkt_remainder) > 0 )
    BEGIN
       -- Is the start of v_wkt_remainder a coordinate?
       IF ( @v_wkt_remainder like '[-0-9]%' )
        BEGIN
         -- We have a coord
         -- Now get position of end of coordinate string
         SET @v_pos = case when CHARINDEX(',',@v_wkt_remainder) = 0
                           then CHARINDEX(')',@v_wkt_remainder)
                           when CHARINDEX(',',@v_wkt_remainder) <> 0 and CHARINDEX(',',@v_wkt_remainder) < CHARINDEX(')',@v_wkt_remainder)
                           then CHARINDEX(',',@v_wkt_remainder)
                           else CHARINDEX(')',@v_wkt_remainder)
                       end;
         -- Create a geometry point from WKT coordinate string
         SET @v_point = geometry::STPointFromText(
                          'POINT('
                          +
                          SUBSTRING(@v_wkt_remainder,1,@v_pos-1)
                          +
                          ')',
                          @p_geometry.STSrid);
         -- Add Point's individual ordinates to WKT
         SET @v_wkt   = @v_wkt
                        +
                        [$(owner)].[STPointAsText] (
                          /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                          /* @p_X       */ @v_point.STX,
                          /* @p_Y       */ @v_point.STY,
                          /* @p_Z       */ @v_point.Z,
                          /* @p_M       */ @c_MarkerMeasure,
                          /* @p_round_x */ @p_round_xy,
                          /* @p_round_y */ @p_round_xy,
                          /* @p_round_z */ @v_round_zm,
                          /* @p_round_m */ 38
                        );
         -- Now remove the old coord from v_wkt_remainder
         SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,@v_pos,LEN(@v_wkt_remainder));
       END
       ELSE
       BEGIN
         -- Move to next character
         SET @v_wkt           = @v_wkt + SUBSTRING(@v_wkt_remainder,1,1);
         SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,2,LEN(@v_wkt_remainder));
       END;
    END; -- Loop
    Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  End;
End
GO

Print 'Testing [$(lrsowner)].[STResetMeasure]';
GO
select [$(lrsowner)].[STResetMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 1,2 2 3 2),(3 3 4 3,4 4 5 4))',0),default,3,2).AsTextZM() as geom
GO

