SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(lrsowner)].[STRemoveMeasure]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STRemoveMeasure];
  Print 'Dropped [$(lrsowner)].[STRemoveMeasure]';
END;
GO

Print 'Creating [$(lrsowner)].[STRemoveMeasure]';
GO

CREATE FUNCTION [$(lrsowner)].[STRemoveMeasure]
(
  @p_linestring geometry,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
Returns geometry
As 
/****f* LRS/STRemoveMeasure (2012)
 *  NAME
 *    STRemoveMeasure -- Function that removes measure values from all points in linestring.
 *  SYNOPSIS
 *    Function STRemoveMeasure (
 *       @p_linestring geometry,
 *       @p_round_xy   int = 3,
 *       @p_round_zm   int = 2
 *     )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(lrsowner).[STRemoveMeasure] (
 *             geometry::STGeomFromText('MULTILINESTRING((1 1 NULL 1,2 2 NULL 2),(3 3 NULL 3,4 4 NULL 4))',0),
 *             3,
 *             2).AsTextZM() as RemoveMeasureLine
 *    GO
 *    RemoveMeasureLine
 *    MULTILINESTRING ((1 1 NULL -999999999, 2 2 NULL -999999999), (3 3 NULL -999999999, 4 4 NULL -999999999))
 *  DESCRIPTION
 *    Removes all measure ordinate values.
 *    Linestring with XYM ordinates is returned with XY ordinates.
 *    Linestring with XYZM ordinates is returned with XYZ ordinates.
 *    Supports CircularString and CompoundCurve geometry objects and subelements from 2012 onewards.
 *  INPUTS
 *    @p_linestring        (geometry) - Supplied Linestring geometry.
 *    @p_round_xy               (int) - Decimal degrees of precision for when formatting XY ordinates in WKT.
 *    @p_round_zm               (int) - Decimal degrees of precision for when formatting Z ordinate in WKT.
 *  RESULT
 *    linestring with no M (geometry) - Input geometry with all M ordinates set to NULL.
 *  EXAMPLE
 *    select [lrs].[STRemoveMeasure] (
 *                 geometry::STGeomFromText('LINESTRING(1 1 NULL 1,2 2 NULL 2)',0),
 *                 3,
 *                 2
 *           ).AsTextZM() as RemoveMeasureLine
 *    union all
 *    select [lrs].[STRemoveMeasure] (
 *                 geometry::STGeomFromText('LINESTRING(1 1 1 1,2 2 2 2)',0),
 *                 3,
 *                 2
 *           ).AsTextZM() as RemoveMeasureLine
 *    union all
 *    select [lrs].[STRemoveMeasure] (
 *                 geometry::STGeomFromText('MULTILINESTRING((1 1 NULL 1,2 2 NULL 2),(3 3 NULL 3,4 4 NULL 4))',0),
 *                 3,
 *                 2
 *           ).AsTextZM() as RemoveMeasureLine
 *    union all
 *    select [lrs].[STRemoveMeasure] (
 *                 geometry::STGeomFromText('MULTILINESTRING((1 1 1 1,2 2 2 2),(3 3 3 3,4 4 4 4))',0),
 *                 3,
 *                 2
 *           ).AsTextZM() as RemoveMeasureLine
 *    GO
 *    
 *    RemoveMeasureLine
 *    LINESTRING (1 1, 2 2)
 *    LINESTRING (1 1 1, 2 2 2)
 *    MULTILINESTRING ((1 1, 2 2), (3 3, 4 4))
 *    MULTILINESTRING ((1 1 1, 2 2 2), (3 3 3, 4 4 4))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType  varchar(100) = '',
    @v_dimensions    varchar(4)   = 'XYM',
    @v_wkt           varchar(max) = '',
    @v_wkt_remainder varchar(max) = '',
    @v_round_xy      int          = 3,
    @v_round_zm      int          = 2,
    @v_pos           int          = 0,
    @v_point         geometry;
  Begin
    If ( @p_linestring is NULL )
      Return @p_linestring;

    -- Only process linear geometries.
    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','CircularString','CompoundCurve','MultiLineString') )
      Return @p_linestring;

    SET @v_dimensions    = 'XY' + case when @p_linestring.HasZ=1 then 'Z' else '' end;
    SET @v_round_xy      = ISNULL(@p_round_xy,3);
    SET @v_round_zm      = ISNULL(@p_round_zm,2);
    SET @v_wkt_remainder = @p_linestring.AsTextZM();
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
                          @p_linestring.STSrid);
         -- Add Point's individual ordinates to WKT
         SET @v_wkt   = @v_wkt
                        +
                        [$(owner)].[STPointAsText] (
                          /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                          /* @p_X       */ @v_point.STX,
                          /* @p_Y       */ @v_point.STY,
                          /* @p_Z       */ @v_point.Z,
                          /* @p_M       */ NULL,
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
    Return geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid);
  End;
End;
GO



