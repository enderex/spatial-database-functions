SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS(lrs) Owner($(owner))';
GO

/* TOBEDONE
ST_LineInterpolatePoints   — Returns one or more points interpolated along a line.
*/

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STLineInterpolatePoint]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STLineInterpolatePoint];
  PRINT 'Dropped [$(lrsowner)].[STLineInterpolatePoint] ... ';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STLineLocatePoint]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STLineLocatePoint];
  PRINT 'Dropped [$(lrsowner)].[STLineLocatePoint] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STLocateAlong]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STLocateAlong];
  PRINT 'Dropped [$(lrsowner)].[STLocateAlong] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STLocateBetween]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STLocateBetween];
  PRINT 'Dropped [$(lrsowner)].[STLocateBetween]';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STLineSubstring]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STLineSubstring];
  PRINT 'Dropped [$(lrsowner)].[STLineSubstring]';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STInterpolatePoint]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STInterpolatePoint];
  PRINT 'Dropped [$(lrsowner)].[STInterpolatePoint] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STLocateBetweenElevations]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STLocateBetweenElevations];
  PRINT 'Dropped [$(lrsowner)].[STLocateBetweenElevations] ... ';
END;
GO

-- ***************************************************************************************

Print 'Creating [$(lrsowner)].[STLineInterpolatePoint] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STLineInterpolatePoint] 
(
  @p_linestring geometry,
  @p_fraction   Float,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
Returns geometry 
AS
/****f* LRS/STLineInterpolatePoint (2012)
 *  NAME
 *    STLineInterpolatePoint -- Returns point geometry at supplied fraction along linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STLineInterpolatePoint] (
 *               @p_linestring geometry,
 *               @p_fraction   Float
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a fraction between 0 and 1.0, this function returns a geometry point at the position described by that ratio.
 *
 *    Ratio is combined with length, so @p_ratio of 1.0 is equivalent to @p_linestring.STLength() ie @p_linestring.STEndPoint().
 *    For example, @p_ratio value of 0.5 returns point at exact midpoint of linestring (ct centroid).
 *
 *    Supports measured and unmeasured linestrings.
 *
 *    Supports LineStrings with CircularString elements.
 *  NOTES
 *    Wrapper over lrs.STFindPointByRatio
 *
 *    Implements PostGIS ST_LineInterpolatePoint function.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring (including CircularString) geometry.
 *    @p_ratio         (float) - Length ratio between 0.0 and 1.0. If Null, @p_linestring is returned.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point         (geometry) - Point at provided measure/length fraction from start.
 *  EXAMPLE
 *    -- Linestring
 *    select f.fraction,
 *           [$(lrsowner)].[STLineInterpolatePoint] (
 *              @p_linestring geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0),
 *              @p_fraction   f.fraction,
 *              @p_round_xy   4,
 *              @p_round_zm   3
 *           ).AsTextZM() as fPoint
 *      from (select 0.01 * CAST(t.IntValue as numeric) as fraction
 *              from [dbo].[Generate_Series](1,100,10) as t
 *           ) as f
 *      order by f.fraction
 *    GO
 *    
 *    fraction fPoint
 *    0.01     POINT (-3.8186 -3.8186 0 1.046)
 *    0.11     POINT (-2.0044 -2.0044 0 1.506)
 *    0.21     POINT (-0.1902 -0.1902 0 1.966)
 *    0.31     POINT (2.2968 0 0 6.496)
 *    0.41     POINT (4.8625 0 0 7.497)
 *    0.51     POINT (7.4281 0 0 8.498)
 *    0.61     POINT (9.9938 0 0 9.499)
 *    0.71     POINT (10 2.5595 0 16.587)
 *    0.81     POINT (10 5.1252 0 17.566)
 *    0.91     POINT (10 7.6909 0 18.545)
 * 
 *    -- Unmeasured 2D Compound curve test.
 *    select f.fraction,
 *           [$(lrsowner)].[STLineInterpolatePoint] (
 *              geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
 *              f.fraction,
 *              4,
 *              3
 *           ).AsTextZM() as fPoint
 *      from (select 0.01 * CAST(t.IntValue as numeric) as fraction
 *              from [dbo].[Generate_Series](1,100,10) as t
 *           ) as f
 *      order by f.fraction
 *    GO
 *
 *    fraction fPoint
 *    0.01     POINT (2.8163 6.4085)
 *    0.11     POINT (0.876 6.945)
 *    0.21     POINT (-1.1367 6.9071)
 *    0.31     POINT (-2.9736 6.269)
 *    0.41     POINT (-2.1079 4.4439)
 *    0.51     POINT (-1.2421 2.6187)
 *    0.61     POINT (-0.3764 0.7935)
 *    0.71     POINT (0.4893 1.0316)
 *    0.81     POINT (1.3551 2.8568)
 *    0.91     POINT (2.2208 4.682)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - July 2019 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  RETURN [$(lrsowner)].[STFindPointByRatio] (
            /* p_linestring */ @p_linestring,
            /* @p_ratio     */ @p_fraction,
            /* @p_offset    */ 0.0,
            /* @p_round_xy  */ @p_round_xy,
            /* @p_round_zm  */ @p_round_zm
         );
END
GO

-- ************************************************************************************************************************

Print 'Creating [$(lrsowner)].[STLineLocatePoint] ....';
GO

CREATE FUNCTION [$(lrsowner)].[STLineLocatePoint] 
(
  @p_linestring geometry,
  @p_point      geometry,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
Returns float 
as
/****f* LRS/STLineLocatePoint  (2012)
 *  NAME
 *    STLineLocatePoint -- Returns a float between 0 and 1 representing the location of the closest point on LineString to the given Point
 *  SYNOPSIS
 *    Function [$(lrsowner)].[STLineLocatePoint] (
 *               @p_linestring geometry,
 *               @p_point      geometry,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    Given a point near a the supplied measure @p_linestring, this function returns the measure/length ratio of the found positions. 
 *  NOTES
 *    Is identical to PostGIS's ST_LineLocatePoint.
 *
 *    Srid of @p_linestring and @p_point must be the same.
 *
 *    If @p_linestring is measured ratio returned is measure of located point / MeasureRange of linestring.
 *
 *    If @p_linestring is not measured the ratio returned is position of located point from start / STLenth of linestring.
 *  INPUTS
 *    @p_linestring (geometry) - Measured linestring with or without Z ordinates.
 *    @p_point      (geometry) - Point near to linestring.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    ratio value      (float) - Ratio of  point found on @p_linestring.
 *  EXAMPLE
 *   select [$(lrsowner)].[STLineLocatePoint] (
 *              geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *              geometry::Point(8,8,28355),
 *              default,
 *              default
 *          ) as ratio
 *    union all
 *    select [lrs].[STLineLocatePoint] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4,0 0,10 0,10 10)',28355),
 *             geometry::Point(10,0,28355),
 *             4,
 *             8
 *          ) as ratio
 *    GO
 *
 *    ratio
 *    23.44
 *    15.61
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - July 2019 
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  Return [$(lrsowner)].[STFindMeasureByPoint] ( @p_linestring, @p_point, @p_round_xy, @p_round_zm )
         /
         [$(lrsowner)].[STMeasureRange] ( @p_linestring );
END
GO

-- *************************************************************************************************

PRINT 'Creating [$(lrsowner)].[STLocateAlong] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STLocateAlong] 
(
  @p_linestring geometry,
  @p_measure    Float,
  @p_offset     Float = 0.0,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
returns geometry 
as
/****f* LRS/STLocateAlong (2012)
 *  NAME
 *    STLocateAlong -- Returns (possibly offset) point geometry at supplied measure along linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STLocateAlong] (
 *               @p_linestring geometry,
 *               @p_measure    Float,
 *               @p_offset     Float = 0.0,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    This function is identical to STFindPointByName and so is a synonym for it.
 *
 *    Given a measure, this function returns a geometry point at that measure.
 *
 *    Only the measure's first point is returned as measures are assume to be organised in ascending or descending order and so are unique.
 *
 *    If a non-zero/null value is suppied for @p_offset, the found point is offset (perpendicular to line) to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *
 *    Computed point's ordinate values are rounded to @p_round_xy/@p_round_zm decimal digits of precision.
 *  NOTES
 *    Implements PostGIS's ST_LocateAlong(geometry ageom_with_measure, float8 a_measure, float8 offset) except that because
 *    measures are assumed to be organised in ascending or descending order and so are unique, only one point can be returned
 *    and not multiple as in the PostGIS example.
 *
 *    Supports LineStrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry with measures.
 *    @p_measure       (float) - Measure defining position of point to be located.
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in STSrid units.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    point         (geometry) - Point at provided measure optionally offset to left or right.
 *  EXAMPLE
 *    -- Linestring.
 *    with data as (
 *      select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
 *    )
 *    select g.intValue as measure,
 *           o.IntValue as offset,
 *           [$(lrsowner)].[STLocateAlong](linestring,g.IntValue,o.IntValue,3,2).AsTextZM() as fPoint
 *      from data as a
 *           cross apply
 *           [dbo].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
 *           cross apply
 *           [dbo].[generate_series](-1,1,1) as o
 *    union all
 *    select g.intValue as measure,
 *           o.IntValue as offset,
 *           [$(lrsowner)].[STLocateAlong](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).AsTextZM() as fPoint
 *      from data as a
 *           cross apply
 *           [dbo].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
 *           cross apply
 *           [dbo].[generate_series](-1,1,1) as o
 *    GO
 *    
 *    measure offset fPoint
 *          1     -1 POINT (-0.707 0.707 NULL 1)
 *          1      0 POINT (-4 -4 0 1)
 *          1      1 POINT (0.707 -0.707 NULL 1)
 *          3     -1 POINT (-3.293 -1.879 NULL 3)
 *          3      0 POINT (-2.586 -2.586 NULL 3)
 *          3      1 POINT (-1.879 -3.293 NULL 3)
 *          5     -1 POINT (-1.879 -0.465 NULL 5)
 *          5      0 POINT (-1.172 -1.172 NULL 5)
 *          5      1 POINT (-0.465 -1.879 NULL 5)
 *          7     -1 POINT (1.4 1 NULL 7)
 *          7      0 POINT (1.4 0 NULL 7)
 *          7      1 POINT (1.4 -1 NULL 7)
 *          9     -1 POINT (3.4 1 NULL 9)
 *          9      0 POINT (3.4 0 NULL 9)
 *          9      1 POINT (3.4 -1 NULL 9)
 *         11     -1 POINT (5.4 1 NULL 11)
 *         11      0 POINT (5.4 0 NULL 11)
 *         11      1 POINT (5.4 -1 NULL 11)
 *         13     -1 POINT (7.4 1 NULL 13)
 *         13      0 POINT (7.4 0 NULL 13)
 *         13      1 POINT (7.4 -1 NULL 13)
 *         15     -1 POINT (9.4 1 NULL 15)
 *         15      0 POINT (9.4 0 NULL 15)
 *         15      1 POINT (9.4 -1 NULL 15)
 *         17     -1 POINT (9 1.39 NULL 17)
 *         17      0 POINT (10 1.39 NULL 17)
 *         17      1 POINT (11 1.39 NULL 17)
 *         19     -1 POINT (9 3.39 NULL 19)
 *         19      0 POINT (10 3.39 NULL 19)
 *         19      1 POINT (11 3.39 NULL 19)
 *         21     -1 POINT (9 5.39 NULL 21)
 *         21      0 POINT (10 5.39 NULL 21)
 *         21      1 POINT (11 5.39 NULL 21)
 *         23     -1 POINT (9 7.39 NULL 23)
 *         23      0 POINT (10 7.39 NULL 23)
 *         23      1 POINT (11 7.39 NULL 23)
 *         25     -1 POINT (9 9.39 NULL 25)
 *         25      0 POINT (10 9.39 NULL 25)
 *         25      1 POINT (11 9.39 NULL 25)
 *          1     -1 POINT (-0.707 0.707 NULL 1)
 *          1      0 POINT (-4 -4 0 1)
 *          1      1 POINT (0.707 -0.707 NULL 1)
 *          2     -1 POINT (-0.707 0.707 NULL 5.6)
 *          2      0 POINT (0 0 0 5.6)
 *          2      1 POINT (0.707 -0.707 NULL 5.6)
 *          3     -1 POINT (10 1 NULL 15.61)
 *          3      0 POINT (10 0 0 15.61)
 *          3      1 POINT (10 -1 NULL 15.61)
 *          4     -1 POINT (9 10 NULL 25.4)
 *          4      0 POINT (10 10 0 25.4)
 *          4      1 POINT (11 10 NULL 25.4)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  Return [$(lrsowner)].[STFindPointByMeasure] (
           /* @p_linestring */ @p_linestring,
           /* @p_measure    */ @p_measure,
           /* @p_offset     */ @p_offset, 
           /* @p_round_xy   */ @p_round_xy,
           /* @p_round_zm   */ @p_round_zm
         );
END
go

-- ****************************************************************************************************************************

Print 'Creating [$(lrsowner)].[STLocateBetween] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STLocateBetween] 
(
  @p_linestring    geometry,
  @p_start_measure Float,
  @p_end_measure   Float = null,
  @p_offset        Float = 0.0,
  @p_round_xy      int   = 3,
  @p_round_zm      int   = 2
)
returns geometry 
as
/****f* LRS/STLocateBetween (2012)
 *  NAME
 *    STLocateBetween -- Extracts, and possibly offet, linestring using supplied start and end measures and @p_offset value.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STLocateBetween] (
 *               @p_linestring    geometry,
 *               @p_start_measure Float,
 *               @p_end_measure   Float = null,
 *               @p_offset        Float = 0,
 *               @p_round_xy      int   = 3,
 *               @p_round_zm      int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a start and end measure, this function extracts the line segment defined between them (a point if start=end).
 *
 *    If a non-zero value is suppied for @p_offset, the extracted line is then offset to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *  NOTES
 *    Supports linestrings with CircularString elements.
 *
 *    Supports measured and unmeasured linestrings.
 *
 *    Is wrapper over STFindSegmentByMeasureRange.
 *
 *    Provides implementation of PostGIS's ST_LocateBetween(geometry geomA, float8 measure_start, float8 measure_end, float8 offset);
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry with measures.
 *    @p_start_measure (float) - Measure defining start point of located geometry.
 *    @p_end_measure   (float) - Measure defining end point of located geometry.
 *    @p_offset        (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    line          (geometry) - Line between start/end measure with offset.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_interpolated_line geometry;
  BEGIN
    SET @v_interpolated_line = [$(lrsowner)].[STFindSegmentByMeasureRange] (
                                 /* @p_linestring    */ @p_linestring,
                                 /* @p_start_measure */ @p_start_measure,
                                 /* @p_end_measure   */ @p_end_measure,
                                 /* @p_offset        */ @p_offset, 
                                 /* @p_round_xy      */ @p_round_xy,
                                 /* @p_round_zm      */ @p_round_zm
                               );
    RETURN @v_interpolated_line;
  END;
END
go

-- ****************************************************************************************************************************

Print 'Creating [$(lrsowner)].[STLineSubstring] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STLineSubstring] 
(
  @p_linestring     geometry,
  @p_start_fraction Float,
  @p_end_fraction   Float = null,
  @p_offset         Float = 0.0,
  @p_round_xy       int   = 3,
  @p_round_zm       int   = 2
)
returns geometry 
as
/****f* LRS/STLineSubstring (2012)
 *  NAME
 *  STLineSubstring -- Returns a substring of the providec linestring starting and ending at the given fractions (between 0 and 1) of total 2d length or measure range.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STLineSubstring] (
 *               @p_linestring     geometry,
 *               @p_start_fraction Float,
 *               @p_end_fraction   Float = null,
 *               @p_offset         Float = 0,
 *               @p_round_xy       int   = 3,
 *               @p_round_zm       int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given a start and end measure, this function extracts the line segment defined between them (a point if start=end).
 *
 *    If a non-zero value is suppied for @p_offset, the extracted line is then offset to the left (if @p_offset < 0) or to the right (if @p_offset > 0).
 *  NOTES
 *    Supports linestrings with CircularString elements.
 *
 *    Supports measured and unmeasured linestrings.
 *
 *    Is wrapper over STFindSegmentByMeasureRange.
 *
 *    Provides implementation of PostGIS's ST_LocateBetween(geometry geomA, float8 measure_start, float8 measure_end, float8 offset);
 *  INPUTS
 *    @p_linestring  (geometry) - Linestring geometry with measures.
 *    @p_start_fraction (float) - Value defining start point of located geometry.
 *    @p_end_fraction   (float) - Value defining end point of located geometry.
 *    @p_offset         (float) - Offset (distance) value left (negative) or right (positive) in SRID units.
 *    @p_round_xy         (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm         (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    line          (geometry) - Line between start/end measure with offset.
 *  EXAMPLE
 *    -- Measured Linestring
 *    Print '....Line SubString';
 *    select [lrs].[STLineSubstring] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *             0.0,1.0,0.0,3,2).AsTextZM() as line
 *    union all
 *    select [lrs].[STLineSubstring] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *             0.0,0.5,0.0,3,2).AsTextZM() as line
 *    GO
 *    
 *    line
 *    LINESTRING (-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)
 *    LINESTRING (-4 -4 0 1, 0 0 0 5.6, 13.2 0 0 13.2)
 *    
 *     -- UnMeasured LineStrings';
 *    select [lrs].[STLineSubstring] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
 *             0.0,1.0,0.0,3,2).AsTextZM() as line
 *    union all
 *    select [lrs].[STLineSubstring] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
 *             0.0,0.5,0.0,3,2).AsTextZM() as line
 *    GO
 *    
 *    line
 *    LINESTRING (-4 -4, 0 0, 10 0, 10 10)
 *    LINESTRING (-4 -4, 0 0, 7.172 0)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - July 2019 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_interpolated_line geometry;
  BEGIN
    SET @v_interpolated_line = 
           case when @p_linestring.HasM = 1
                then [$(lrsowner)].[STFindSegmentByMeasureRange] (
                                      /* @p_linestring    */ @p_linestring,
                                      /* @p_start_measure */ [$(lrsowner)].[STPercentageToMeasure](@p_linestring,@p_start_fraction * 100.0),
                                      /* @p_end_measure   */ [$(lrsowner)].[STPercentageToMeasure](@p_linestring,@p_end_fraction   * 100.0),
                                      /* @p_offset        */ @p_offset, 
                                      /* @p_round_xy      */ @p_round_xy,
                                      /* @p_round_zm      */ @p_round_zm
                                    )
                else [$(lrsowner)].[STFindSegmentByLengthRange] (
                                      /* @p_linestring    */ @p_linestring,
                                      /* @p_start_measure */ [$(lrsowner)].[STPercentageToMeasure](@p_linestring,@p_start_fraction * 100.0),
                                      /* @p_end_measure   */ [$(lrsowner)].[STPercentageToMeasure](@p_linestring,@p_end_fraction   * 100.0),
                                      /* @p_offset        */ @p_offset, 
                                      /* @p_round_xy      */ @p_round_xy,
                                      /* @p_round_zm      */ @p_round_zm
                                    )
           end;
    RETURN @v_interpolated_line;
  END;
END
GO

-- ****************************************************************************************************************************

Print 'Creating [$(lrsowner)].[STInterpolatePoint] ....';
GO

CREATE FUNCTION [$(lrsowner)].[STInterpolatePoint] 
(
  @p_linestring geometry,
  @p_point      geometry,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
Returns float 
as
/****f* LRS/STInterpolatePoint (2012)
 *  NAME
 *    STInterpolatePoint -- Returns value of the measure dimension or length of a point on the provided linesting closest to the provided point.
 *  SYNOPSIS
 *    Function [$(lrsowner)].[STInterpolatePoint] (
 *               @p_linestring geometry,
 *               @p_point      geometry,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns float
 *  DESCRIPTION
 *    This function snaps supplied point to @p_linestring, computes and returns the measure value of the snapped point, or length to the snapped point.
 *
 *    @p_linestring can be measured or unmeasured.
 *
 *    Returned value is rounded to @p_round_zm decimal digits of precision.
 *  NOTES
 *    IS a wrapper over STFindMeasureByPoint that returns Measure or length.
 *
 *    Is implementation of PostGIS ST_InterpolatePoint
 *
 *    Supports linestrings with CircularString elements.
 *
 *    Srid of @p_linestring and @p_point must be the same.
 *  INPUTS
 *    @p_linestring (geometry) - Measured linestring with or without Z ordinates.
 *    @p_point      (geometry) - Point near to linestring.
 *    @p_round_xy        (int) - Decimal digits of precision for XY ordinates.
 *    @p_round_zm        (int) - Decimal digits of precision for M ordinate.
 *  RESULT
 *    measure value    (float) - Measure of point found on @p_linestring.
 *  EXAMPLE
 *    Print '  [$(lrsowner)].[STInterpolatePoint] ...';
 *    GO
 *    Print '....Measured LineStrings';
 *    select [lrs].[STInterpolatePoint] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *             geometry::Point(8,8,28355),
 *             3,2) as measure
 *    union all
 *    select [lrs].[STInterpolatePoint] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *             geometry::Point(10,0,28355),
 *             3,2) as measure
 *    GO
 *    
 *    measure
 *    23.44
 *    15.61
 *    
 *    Print '....UnMeasured LineStrings';
 *    select [lrs].[STInterpolatePoint] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
 *             geometry::Point(8,8,28355),
 *             3,3) as measure
 *    union all
 *    select [lrs].[STInterpolatePoint] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
 *             geometry::Point(10,0,28355),
 *             3,3) as measure
 *    GO
 *    
 *    measure
 *    23.657
 *    15.657
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original coding.
 *    Simon Greener - December 2017 - Port to SQL Server (TSQL).
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  Return [$(lrsowner)].[STFindMeasureByPoint] (
            /* @p_linestring    */ @p_linestring,
            /* @p_start_measure */ @p_point,
            /* @p_round_xy      */ @p_round_xy,
            /* @p_round_zm      */ @p_round_zm
         );
END
GO

-- *********************************************************************************************

Print 'Creating [$(lrsowner)].[STLocateBetweenElevations] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STLocateBetweenElevations]
(
  @p_linestring geometry,
  @p_start_z    Float,
  @p_end_z      Float = null,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
returns geometry 
as
/****f* LRS/STLocateBetweenElevations (2008)
 *  NAME
 *    STLocateBetweenElevations -- Computes and returns elements that intersect the specified Z range.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STLocateBetweenElevations] (
 *               @p_linestring geometry,
 *               @p_start_z    Float,
 *               @p_end_z      Float = null,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Is implementation of PostGIS:
 *
 *       geometry ST_LocateBetweenElevations(geometry geom_mline, 
 *                                           float8 elevation_start,
 *                                           float8 elevation_end);
 *
 *    Processes the supplied (3D, 3DM) (multi)linestring returning the elements that intersect the specified range of elevations inclusively.
 *
 *    May return Points and/or linestrings in the appropriate geometry type.
 *
 *    Where a new xy position is to be computed, the value is rounded using @p_round_xm.
 *
 *    Computes M values if exist on @p_linestring and rounds the values based on @p_round_zm..
 *  NOTES
 *    Does not currently support Linestrings with CircularString elements (2012+).
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry with Z ordinates (could have M ordinates).
 *    @p_start_z       (float) - Start Elevation.
 *    @p_end_z         (float) - End Elevation.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    geometry      (geometry) - Geometry of the appropriate type.
 *  EXAMPLE
 *    -- PostGIS 1
 *    select [$(lrsowner)].[STLocateBetweenElevations](
 *             geometry::STGeomFromText('LINESTRING(1 2 3, 4 5 6)',0),
 *             2,4, 
 *             3,2).AsTextZM() as geomZ;
 *    
 *    geomz
 *    LINESTRING (1 2 3, 2 3 4)
 *    
 *    -- PostGIS 2
 *    select [$(lrsowner)].[STLocateBetweenElevations](
 *             geometry::STGeomFromText('LINESTRING(1 2 6, 4 5 -1, 7 8 9)',0),
 *             6,9, 
 *             3,2).AsTextZM() as geomZ;
 * 
 *    geomz
 *    GEOMETRYCOLLECTION (POINT (1 2 6), LINESTRING (6.1 7.1 6, 7 8 9))
 *
 *    -- PostGIS 3
 *    SELECT d.geom.AsTextZM() as geomWKT
 *      FROM (SELECT [$(lrsowner)].[STLocateBetweenElevations](
 *                     geometry::STGeomFromText('LINESTRING(1 2 6, 4 5 -1, 7 8 9)',0),
 *                     6,9,
 *                     3,2
 *                   ) As the_geom
 *           ) As foo
 *           cross apply
 *           [$(owner)].[STExtract](foo.the_geom,default) as d;
 *    
 *    geomWKT
 *    POINT (1 2 6)
 *    LINESTRING (6.1 7.1 6, 7 8 9)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - July 2019 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_GeometryType        varchar(100),
    @v_Dimensions          varchar(4),
    @v_round_xy            int,
    @v_round_zm            int,
    /* Processing Variables */
    @v_i                   int,
    @v_wkt                 varchar(max),
    @v_points              geometry,
    @v_linestrings         geometry,
    @v_return_geom         geometry,
    /* Filtered Segment Variables */
    @v_id                  int,
    @v_geom                geometry;

  BEGIN
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( @p_linestring.HasZ <> 1 )
      Return @p_linestring;

    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString',
                             'MultiLineString' ) )
      Return @p_linestring;

    SET @v_round_xy      = ISNULL(@p_round_xy,3);
    SET @v_round_zm      = ISNULL(@p_round_zm,2);

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end +
                       + case when @p_linestring.HasM=1 then 'M' else '' end;

    -- process measures against FilteredSegments ...
    --
    DECLARE cFilteredSegments 
     CURSOR FAST_FORWARD 
        FOR
     With segments as (
       SELECT f.id, 
              case when end_z IS null
                   then [$(owner)].[STMakePoint](f.sx,f.sy,start_z,f.em,@p_linestring.STSrid) -- compute xy
                   when start_z IS null
                   then [$(owner)].[STMakePoint](f.ex,f.ey,end_z,f.em,@p_linestring.STSrid) -- compute xy
                   else [$(owner)].[STMakeLine] (
                                    [$(owner)].[STMakePoint](f.sx + (f.ex-f.sx)*(start_z-f.sz)/(f.ez-f.sz),
                                                        f.sy + (f.ey-f.sy)*(start_z-f.sz)/(f.ez-f.sz),
                                                        start_z,
                                                        f.sm + (f.em-f.sm)*(start_z-f.sz)/(f.ez-f.sz),
                                                        @p_linestring.STSrid),
                                       [$(owner)].[STMakePoint](f.sx + (f.ex-f.sx)*(end_z-f.sz)/(f.ez-f.sz),
                                                        f.sy + (f.ey-f.sy)*(end_z-f.sz)/(f.ez-f.sz),
                                                        end_z,
                                                        f.sm + (f.em-f.sm)*(end_z-f.sz)/(f.ez-f.sz),
                                                        @p_linestring.STSrid),
                                    3,2
                                  )
               end as geom
         FROM (SELECT v.id, 
                      v.sx, v.sy, v.sz, v.sm,
                      v.ex, v.ey, v.ez, v.em,
                      max(v.id) over (order by v.id desc) as last_id,
                      case when @p_start_z = v.sz or @p_start_z = v.ez 
                           then @p_start_z 
                           when @p_start_z between case when v.sz <= v.ez then v.sz else v.ez end
                                               and case when v.sz <= v.ez then v.ez else v.sz end
                           then @p_start_z
                           when v.id = 1 and @p_start_z < v.sz
                           then v.sz
                           else v.sz 
                       end AS start_z,
                      case when   @p_end_z = v.sz or @p_end_z = v.ez 
                           then   @p_end_z
                           when   @p_end_z between case when v.sz <= v.ez then v.sz else v.ez end
                                            and case when v.sz <= v.ez then v.ez else v.sz end
                           then @p_end_z
                           when v.id = max(v.id) over (order by v.id desc) and @p_end_z > v.ez
                           then v.ez
                           else null
                       end AS end_z,
                      v.geom.AsTextZM() as geom
                    FROM [$(owner)].[STVectorize] ( @p_linestring ) as v
                  ) as f
            where NOT (f.start_z is null and f.end_z is null)
    )
    select * 
      from segments as f
     order by f.id;

    OPEN cFilteredSegments;

    FETCH NEXT 
     FROM cFilteredSegments 
     INTO @v_id,
          @v_geom;
           
    -- Check if any filtered segments were returned.
    -- 
    IF ( @@FETCH_STATUS <> 0 ) 
    BEGIN
      -- Nothing to do.
      CLOSE      cFilteredSegments;
      DEALLOCATE cFilteredSegments;
      RETURN NULL; 
    END;

    WHILE ( @@FETCH_STATUS = 0 )
    BEGIN
      if ( @v_geom.STGeometryType() = 'Point' ) 
      begin
        if ( @v_return_geom is null ) 
          set @v_points = @v_geom
        else
          set @v_points = [$(owner)].[STInsertN](@v_points,@v_geom,-1,@v_round_xy,@v_round_zm);
      End 
      else /* LineString */ 
      begin
        if ( @v_return_geom is null )
          set @v_linestrings = @v_geom
        else
          set @v_linestrings = [$(owner)].[STAppend](@v_linestrings,@v_geom,@v_round_xy,@v_round_zm);
      end;
      FETCH NEXT 
       FROM cFilteredSegments 
       INTO @v_id,
            @v_geom;
    END;
    IF (@v_points is     null and @v_linestrings is     null ) 
      return NULL;   
    IF (@v_points is not null and @v_linestrings is     null ) 
      return @v_points;
    IF (@v_points is     null and @v_linestrings is not null ) 
      return @v_linestrings;
    -- Both not null
    -- Need to extend STAppend to provide standard way to handle append other than just linestrings.
    set @v_wkt = 'GEOMETRYCOLLECTION(';
    set @v_i  = 1;
    while @v_i <= @v_points.STNumGeometries() 
    Begin
      set @v_wkt = CONCAT(@v_wkt,
                          @v_points.STGeometryN(@v_i).AsTextZM(),
                          ',');
      set @v_i = @v_i + 1;
    End;
    set @v_i  = 1;
    while @v_i <= @v_linestrings.STNumGeometries() 
    Begin
      set @v_wkt = CONCAT(@v_wkt,
                          @v_linestrings.STGeometryN(@v_i).AsTextZM(),
                          case when @v_i <> @v_linestrings.STNumGeometries() then ',' else '' end);
      set @v_i = @v_i + 1;
    End;
    set @v_wkt = CONCAT(@v_wkt,')');
    return geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid);
  End;
End
GO

-- ****************************************************************************************************************************
--
-- TESTING
--
-- ****************************************************************************************************************************

Print 'Testing [$(lrsowner)].[STLineInterpolatePoint] ...';
GO

-- Linestring
select f.fraction,
       [$(lrsowner)].[STLineInterpolatePoint] (
          /* @p_linestring*/ geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0),
          /* @p_fraction  */ f.fraction,
          /* @p_round_xy  */ 4,
          /* @p_round_zm  */ 3
       ).AsTextZM() as fPoint
  from (select 0.01 * CAST(t.IntValue as numeric) as fraction
          from [$(owner)].[Generate_Series](1,100,10) as t
       ) as f
  order by f.fraction
GO

-- Unmeasured Compound curve test.
select f.fraction,
       [$(lrsowner)].[STLineInterpolatePoint] (
          /* @p_linestring*/ geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
          /* @p_fraction  */ f.fraction,
          /* @p_round_xy  */ 4,
          /* @p_round_zm  */ 3
       ).AsTextZM() as fPoint
  from (select 0.01 * CAST(t.IntValue as numeric) as fraction
          from [$(owner)].[Generate_Series](1,100,10) as t
       ) as f
  order by f.fraction
GO

-- ***************************************************************

Print 'Testing  [$(lrsowner)].[STLineLocatePoint] ...';
GO

select [$(lrsowner)].[STLineLocatePoint] (
           geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
           geometry::Point(8,8,28355),
           default,
           default
       ) as ratio
union all
select [$(lrsowner)].[STLineLocatePoint] (
          geometry::STGeomFromText('LINESTRING(-4 -4,0 0,10 0,10 10)',28355),
          geometry::Point(10,0,28355),
          4,
          8
       ) as ratio
Go

-- ***************************************************************

Print 'Testing  [$(lrsowner)].[STLocateAlong] ...';
GO

-- Measured Linestring.
with data as (
  select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring,g.IntValue,o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
GO

-- UnMeasured 2D Linestring.
with data as (
  select geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring,g.IntValue,o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
GO

-- UnMeasured 2D Circular string and Compound curve.
with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
  union all 
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring,g.IntValue,o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STLocateAlong](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).AsTextZM() as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
GO

-- ********************************************************************

PRINT 'STLocateBetween -> LineString ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',0) as linestring
)
Select locateType, 
       sm,em,
       case when f.measureSegment is not null 
            then f.measureSegment.AsTextZM() 
            else null 
        end as measureSegment 
  from (
select 'SM 1.0/EM 1.0 => Start Point' as locateType,1.0 as sm,1.0 as em,  [$(lrsowner)].[STLocateBetween](linestring,1.0,1.0,0,3,2) as measureSegment from data as a
union all
select 'SM 1.0/EM NULL => Whole Linestring',1.0,null,                     [$(lrsowner)].[STLocateBetween](linestring,1.0,null,0,3,2) as measureSegment from data as a
union all
select 'SM NULL/EM 1 => Start Point',null,1.0,                            [$(lrsowner)].[STLocateBetween](linestring,null,1.0,0,3,2) as measureSegment from data as a
union all
select 'SM NULL/EM 5.6 => Return 1s Segment',null,5.6,                    [$(lrsowner)].[STLocateBetween](linestring,null,5.6,0.0,3,2) as measureSegment from data as a
union all
select 'SM 5.6/EM 5.6 => 1st Segment EP or 2nd SP',5.6,5.6,               [$(lrsowner)].[STLocateBetween](linestring,5.6,5.6,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 5.0 Within First Segment => New Segment',2.0,5.0,       [$(lrsowner)].[STLocateBetween](linestring,2.0,5.0,0,3,2) as measureSegment from data as a
union all
select 'SM 2.0/EM 6.0 => Two New Segments',2.0,6.0,                       [$(lrsowner)].[STLocateBetween](linestring,2,6,0,3,2) as measureSegment from data as a
union all
select 'SM 1.1/EM 25.4 => New 1st Segment, 2nd, New 3rd Segment',1.1,25.1,[$(lrsowner)].[STLocateBetween](linestring,1.1,25.1,0,3,2) as measureSegment from data as a
union all
select 'SM 0.1/EM 30.0 => whole linestring',0.1,30.0,                     [$(lrsowner)].[STLocateBetween](linestring,0.1,30.0,0,3,2) as measureSegment from data as a
) as f;
GO

-- *******************************************************************

Print '  [$(lrsowner)].[STInterpolatePoint] ...';
GO
Print '....Measured LineStrings';
select [$(lrsowner)].[STInterpolatePoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(8,8,28355),
         3,2) as measure
union all
select [$(lrsowner)].[STInterpolatePoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(10,0,28355),
         3,2) as measure
GO

Print '....UnMeasured LineStrings';
select [$(lrsowner)].[STInterpolatePoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
         geometry::Point(8,8,28355),
         3,3) as measure
union all
select [$(lrsowner)].[STInterpolatePoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
         geometry::Point(10,0,28355),
         3,3) as measure
GO

-- *****************************************************************************************

Print '  [$(lrsowner)].[STLineSubstring] ...';
GO
Print '....Line SubString';
select [$(lrsowner)].[STLineSubstring] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         0.0,1.0,0.0,3,2).AsTextZM() as line
union all
select [$(lrsowner)].[STLineSubstring] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         0.0,0.5,0.0,3,2).AsTextZM() as line
GO

-- line
-- LINESTRING (-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)
-- LINESTRING (-4 -4 0 1, 0 0 0 5.6, 13.2 0 0 13.2)

Print '....UnMeasured LineStrings';
select [$(lrsowner)].[STLineSubstring] (
         geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
         0.0,1.0,0.0,3,2).AsTextZM() as line
union all
select [$(lrsowner)].[STLineSubstring] (
         geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
         0.0,0.5,0.0,3,2).AsTextZM() as line
GO

-- line
-- LINESTRING (-4 -4, 0 0, 10 0, 10 10)
-- LINESTRING (-4 -4, 0 0, 7.172 0)

-- ******************************************************************************************

PRINT 'Testing [$(lrsowner)].[STLocateBetweenElevations] ...';
GO

-- PostGIS 1
select [$(lrsowner)].[STLocateBetweenElevations](
         geometry::STGeomFromText('LINESTRING(1 2 3, 4 5 6)',0),
         2,4, 
         3,2).AsTextZM() as geomZ;
GO

--geomz
--LINESTRING (1 2 3, 2 3 4)

-- PostGIS 2
select [$(lrsowner)].[STLocateBetweenElevations](
         geometry::STGeomFromText('LINESTRING(1 2 6, 4 5 -1, 7 8 9)',0),
         6,9, 
         3,2).AsTextZM() as geomZ;
GO

--geomz
--GEOMETRYCOLLECTION (POINT (1 2 6), LINESTRING (6.1 7.1 6, 7 8 9))

-- PostGIS 3
SELECT d.geom.AsTextZM() as geomWKT
  FROM (SELECT [$(lrsowner)].[STLocateBetweenElevations](
                 geometry::STGeomFromText('LINESTRING(1 2 6, 4 5 -1, 7 8 9)',0),
                 6,9,
                 3,2
               ) As the_geom
       ) As foo
       cross apply
       [$(owner)].[STExtract](foo.the_geom,default) as d;
GO

--geomWKT
--POINT (1 2 6)
--LINESTRING (6.1 7.1 6, 7 8 9)



