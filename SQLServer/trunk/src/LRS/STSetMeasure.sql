SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))' ;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSetMeasure]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STSetMeasure];
  PRINT 'Dropped [$(lrsowner)].[STSetMeasure] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSetM]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STSetM];
  PRINT 'Dropped [$(lrsowner)].[STSetM] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STSetMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STSetMeasure] 
(
  @p_point    geometry,
  @p_measure  Float,
  @p_round_xy int = 3,
  @p_round_zm int = 2
)
returns geometry 
as
/****f* LRS/STSetMeasure (2012)
 *  NAME
 *    STSetMeasure -- Function that adds or updates (replaces) M value of supplied geometry point.
 *  SYNOPSIS
 *    Function STSetMeasure (
 *               @p_point    geometry,
 *               @p_measure  float,
 *               @p_round_xy int = 3,
 *               @p_round_zm int = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT STSetMeasure(
 *             STPointFromText('POINT(0 0)',0),
 *             1,
 *             3, 2 
 *           ).AsTextZM() as updatedPoint;
 *    # updatedPoint
 *    'POINT(0 0 NULL 1)'
 *  DESCRIPTION
 *    Function that adds/updates M ordinate of the supplied @p_point.
 *    The updated coordinate's XY ordinates are rounded to @p_round_xy number of decimal digits of precision.
 *    The updated coordinate's ZM ordinates are rounded to @p_round_ZM number of decimal digits of precision.
 *  INPUTS
 *    @p_point     (geometry) - Supplied point geometry.
 *    @p_measure   (float)    - New M value.
 *    @p_round_xy  (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm  (int)      - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point with M (geometry) - Input point with new measure value.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_gtype          varchar(100),
    @v_wkt            varchar(max),
    @v_dimensions     varchar(4),
    @v_round_xy       int,
    @v_round_zm       int,
    @v_measured_point geometry;
  BEGIN
    If ( @p_point is null )
      Return @p_point;

    If ( @p_measure is null )
      Return @p_point;

    SET @v_round_xy   = ISNULL(@p_round_xy,3); 
    SET @v_round_zm   = ISNULL(@p_round_zm,2); 
    SET @v_dimensions = 'XY'
                        + 
                        case when @p_point.HasZ=1 then 'Z' else '' end 
                        +
                        'M';
    SET @v_wkt        = 'POINT(' 
                        + 
                        [$(owner)].[STPointAsText] (
                              /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                              /* @p_X          */ @p_point.STX,
                              /* @p_Y          */ @p_point.STY,
                              /* @p_Z          */ @p_point.Z,
                              /* @p_M          */ @p_measure,
                              /* @p_round_x    */ @v_round_xy,
                              /* @p_round_y    */ @v_round_xy,
                              /* @p_round_z    */ @v_round_zm,
                              /* @p_round_m    */ @v_round_zm
                        )
                        + 
                        ')';
    RETURN geometry::STPointFromText(@v_wkt,@p_point.STSrid);
  END;
END
GO

PRINT 'Creating [$(lrsowner)].[STSetM] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STSetM] 
(
  @p_point    geometry,
  @p_measure  Float,
  @p_round_xy int = 3,
  @p_round_zm int = 2
)
returns geometry 
as
/****f* LRS/STSetM (2012)
 *  NAME
 *    STSetM -- Function that adds or updates (replaces) M value of supplied geometry point.
 *  SYNOPSIS
 *    Function STSetM (
 *               @p_point    geometry,
 *               @p_measure  float,
 *               @p_round_xy int = 3,
 *               @p_round_zm int = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT STSetM(
 *             STPointFromText('POINT(0 0)',0),
 *             1,
 *             3, 2 
 *           ).AsTextZM() as updatedPoint;
 *    # updatedPoint
 *    'POINT(0 0 NULL 1)'
 *  DESCRIPTION
 *    Function that adds/updates M ordinate of the supplied @p_point.
 *    The updated coordinate's XY ordinates are rounded to @p_round_xy number of decimal digits of precision.
 *    The updated coordinate's ZM ordinates are rounded to @p_round_ZM number of decimal digits of precision.
 *  NOTES
 *    Wrapper over STSetMeasure.
 *  INPUTS
 *    @p_point     (geometry) - Supplied point geometry.
 *    @p_measure   (float)    - New M value.
 *    @p_round_xy  (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm  (int)      - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point with M (geometry) - Input point with new measure value.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  Return [$(lrsowner)].[STSetMeasure] (
            @p_point,
            @p_measure,
            @p_round_xy,
            @p_round_zm
         );
END
GO

PRINT 'Testing ...';
GO

With Data As (
  SELECT geometry::Parse('POINT(100.123 100.456 NULL 4.567)') as point
)
SELECT CAST(CONCAT(g.point.AsTextZM(),
       ' ==> ',
       [$(lrsowner)].[STSetMeasure](g.point,99.123,3,1).AsTextZM()) as varchar(500)) as updatedPoint
  FROM data as g;
GO

SELECT [$(lrsowner)].[STSetMeasure](geometry::Point(0,0,28355),10.125,3,2).AsTextZM();
GO


