SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STProjectPoint]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STProjectPoint];
  PRINT 'Dropped [$(lrsowner)].[STProjectPoint] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindMeasureByPoint]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindMeasureByPoint];
  PRINT 'Dropped [$(lrsowner)].[STFindMeasureByPoint] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindMeasure]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindMeasure];
  PRINT 'Dropped [$(lrsowner)].[STFindMeasure] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFindOffset]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFindOffset];
  PRINT 'Dropped [$(lrsowner)].[STFindOffset] ...';
END;
GO

/* *************************** FUNCTIONS ************************************* */

Print 'Creating Master Function [$(lrsowner)].[STProjectPoint] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STProjectPoint]
(
  @p_linestring geometry,
  @p_point      geometry,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
Returns geometry 
as
/****m* LRS/STProjectPoint (2012)
 *  NAME
 *    STProjectPoint --  Return a measured point by snapping provided point to the provided line.
 *  SYNOPSIS
 *    Function STProjectPoint (
 *               @p_linestring geometry,
 *               @p_point      geometry,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    This function snaps supplied point to @p_linestring, returning the snapped point.
 *    
 *    If there is more than one possible solution the first point is retuend.
 *    
 *    Computes Z and M values if exist on @p_linestring.
 *    
 *    If input @p_linestring is 2D, length from start of @p_linestring to point is returned in M ordinate of snapped point.
 *    
 *    Returned points ordinate values are rounded to @p_round_xy/@p_round_zm decimal digits of precision.
 *  NOTES
 *    Supports linestrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Measured linestring with or without Z ordinates.
 *    @p_point      (geometry) - Point near to linestring.
 *    @p_round_xy        (int) - Decimal digits of precision for XY ordinates.
 *    @p_round_zm        (int) - Decimal digits of precision for M ordinate.
 *  RESULT
 *    snapped point (geometry) -- First point found on @p_linestring.
 *  EXAMPLE
 *    select CAST('Actual Measure' as varchar(50)) as test,
 *           [lrs].[STProjectPoint] (
 *              geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *              geometry::Point(8,8,28355),
 *              3,2).AsTextZM() as project_point
 *    union all
 *    select '2D return length in measure' as test,
 *           [lrs].[STProjectPoint] (
 *              geometry::STGeomFromText('LINESTRING(-4 -4, 0 0, 10 0, 10 10)',28355),
 *              geometry::Point(8,8,28355),
 *              3,2).AsTextZM() as project_point
 *    union all
 *    select 'Point has relationship with XYZM circular arc' as test,
 *           [lrs].[STProjectPoint] (
 *              geometry::STGeomFromText('CIRCULARSTRING (3 6.325 -2.1 0, 0 7 -2.1 3.08, -3 6.325 -2.1 6.15)',0),
 *              geometry::Point(2,8,0),
 *              3,2).AsTextZM() as project_point
 *    union all
 *    select 'Point does not have relationship with XYM CircularSring' as test,
 *           [lrs].[STProjectPoint] (
 *              geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),
 *              geometry::Point(8,8,0),
 *              3,2).AsTextZM() as project_point
 *    union all
 *    select 'Point is on centre of the circular arc' as test,
 *           [lrs].[STProjectPoint] (
 *              geometry::STGeomFromText('CIRCULARSTRING (3 6.3246 -1, 0 7 -1, -3 6.3246 -1)',0),
 *              geometry::Point(0,0,0),
 *              3,2).AsTextZM() as project_point
 *    union all
 *    select 'Point projects on to point half way along circular arc' as test,
 *           [lrs].[STProjectPoint] (
 *              geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0),
 *              geometry::Point(0,3.5,0),
 *              3,2).AsTextZM() as project_point
 *    select 'Closest to LineString' as test,
 *           [lrs].[STProjectPoint] (
 *              geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
 *              geometry::Point(-1,1,0),
 *              3,2).AsTextZM() as project_point
 *    Union all
 *    select 'Closest to CircularString' as test,
 *           [lrs].[STProjectPoint] (
 *              geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
 *              geometry::Point(2,8,0),
 *              3,2).AsTextZM() as project_point
 *    go
 *
 *    test                                                    project_point
 *    ------------------------------------------------------- -----------------------------
 *    Actual Measure                                          POINT (10 8 NULL 23.44)
 *    2D return length in measure                             POINT (10 8 NULL 23.66)
 *    Point has relationship with XYZM circular arc           POINT (1.698 6.791 -2.1 1.37)
 *    Point does not have relationship with XYM CircularSring NULL
 *    Point is on centre of the circular arc                  POINT (3 6.3246 -1)
 *    Point projects on to point half way along circular arc  POINT (0 7 NULL 3.1)
 *    Closest to LineString                                   POINT (-0.571 1.204 NULL 5.67)
 *    Closest to CircularString                               POINT (1.698 6.791 NULL 1.39)
 *
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original coding.
 *    Simon Greener - December 2017 - Port to SQL Server (TSQL).
 *    Simon Greener - August   2019 - Added support for CircularArcs and CompoundCurves.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_GeometryType       varchar(100),
    @v_round_xy           int,
    @v_round_zm           int,
    /* LineString variables */
    @v_segment_measure    Float,
    @v_segment_length     Float,
    @v_measure            Float,
    @v_start2point_length Float,
    @v_end2point_length   Float,
    @v_start_length_ratio Float, 
    @v_end_length_ratio   Float, 
    @v_length             Float,
    @v_cum_length         Float,
    @vector               int,
    @first                int,
    @second               int,
    @v_shortest_line      geometry,
    @v_part_shortest_line geometry,
    @v_result_point       geometry,
    @v_start_point        geometry,
    @v_end_point          geometry,
    /* MultiPart Geometry variables */
    @v_geomn              int,
    @v_part_measure       geometry,
    @v_part_geom          geometry;
  BEGIN
    If ( @p_linestring is null )
      Return @p_point;

    If ( @p_point is null )
      Return NULL;
 
    If ( @p_linestring.STSrid <> @p_point.STSrid )
      Return Null;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    SET @v_GeometryType = @p_linestring.STGeometryType();

    IF ( @v_GeometryType NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve' ) )
      Return @p_linestring;

    IF ( @v_GeometryType = 'CircularString' ) BEGIN
      Return [$(lrsowner)].[STPointToCircularArc] (
                      /* @p_circularString */ @p_linestring,
                      /* @p_point          */ @p_point, 
                      /* @p_round_xy       */ @v_round_xy,
                      /* @p_round_zm       */ @v_round_zm 
             );
    END;

    SET  @v_shortest_line = @p_linestring.ShortestLineTo(@p_point);
    IF ( @v_shortest_line is null ) 
      SET @v_result_point = @p_point

    IF ( ROUND(@v_shortest_line.STLength(),@v_round_xy) = 0.0 )
      -- If lengths of shortest line is 0, point on line must be supplied point
      SET @v_result_point = @p_point
    ELSE 
      -- One end is the point, the other must be on the line
      SET @v_result_point = case when    ROUND(@p_point.STX,@v_round_xy) = ROUND(@v_shortest_line.STPointN(1).STX,@v_round_xy)
                                     and ROUND(@p_point.STY,@v_round_xy) = ROUND(@v_shortest_line.STPointN(1).STY,@v_round_xy)
                                 then @v_shortest_line.STPointN(@v_shortest_line.STNumPoints())
                                 else @v_shortest_line.STPointN(1)
                             end;

    -- Now find segment which contains @v_result_point
    SET @v_cum_length = 0.0;
    IF ( @v_GeometryType = 'LineString' )  
    BEGIN
      SET @first  = 1;
      SET @second = 2;
      WHILE ( @second <= @p_linestring.STNumPoints() )
      BEGIN
        SET @v_start_point        = @p_linestring.STPointN(@first);
        SET @v_end_point          = @p_linestring.STPointN(@second);
        SET @v_segment_measure    = @v_end_point.M - @v_start_point.M;
        SET @v_segment_length     = @v_start_point.STDistance(@v_end_point);
        SET @v_start2point_length = @v_start_point.STDistance(@v_result_point);
        SET @v_end2point_length   = @v_end_point.STDistance(@v_result_point);
        -- Does this segment contain the required point?
        -- By ratio
        -- To be done: by bearing and distance
        SET @v_start_length_ratio = @v_start2point_length/@v_segment_length;
        SET @v_end_length_ratio   = @v_end2point_length  /@v_segment_length;
        IF ( ROUND( @v_start_length_ratio + @v_end_length_ratio,@v_round_xy+1) = 1.0 )
        BEGIN
          -- Our point is within segment
          IF ( @p_linestring.HasM = 1 )
          BEGIN
            -- Compute measure 
            SET @v_measure = @v_start_point.M + (@v_segment_measure * @v_start_length_ratio);
            -- Add measure to snapped point
            SET @v_result_point = [$(lrsowner)].[STSetMeasure] (  
                                            /* @p_point    */ @v_result_point, 
                                            /* @p_measure  */ @v_measure,
                                            /* @p_round_xy */ @v_round_xy,
                                            /* @p_round_zm */ @v_round_zm 
                                   );
          END
          ELSE
          BEGIN
            -- Compute length
            SET @v_length = @v_cum_length + @v_start2point_length;
            -- Add length to snapped point
            SET @v_result_point = [$(lrsowner)].[STSetMeasure] (  
                                            /* @p_point    */ @v_result_point, 
                                            /* @p_z        */ @v_length,
                                            /* @p_round_xy */ @v_round_xy,
                                            /* @p_round_zm */ @v_round_zm 
                                   );
          END;
          RETURN @v_result_point;
        END;
        SET @v_cum_length = @v_cum_length + @v_segment_length;
        SET @first        = @first  + 1;
        SET @second       = @second + 1;
      END;  
      RETURN null;
    END;

    IF ( @v_GeometryType = 'MultiLineString' )  
    BEGIN
        -- Get parts of multi-part geometry
        --
        SET @v_part_geom     = null;
        SET @v_geomn         = 1;
        WHILE ( @v_geomn <= @p_linestring.STNumGeometries() )
        BEGIN
            SET @v_part_geom = @p_linestring.STGeometryN(@v_geomn);
            SET @v_geomn     = @v_geomn + 1;
            /* Check if this part includes the required measure */
            IF ( @v_part_geom.ShortestLineTo(@p_point).STLength() = @v_shortest_line.STLength() )
            BEGIN
              /* COmpute point and return */
              SET @v_result_point = [$(lrsowner)].[STProjectPoint] (
                                            /* @p_linestring    */ @v_part_geom,
                                            /* @p_start_measure */ @p_point,
                                            /* @p_round_xy      */ @v_round_xy,
                                            /* @p_round_zm      */ @v_round_zm
                                    );
              BREAK;
            END;
        END;
    END;

    IF ( @v_GeometryType = 'CompoundCurve' )
    BEGIN
      -- Made up of N x CircularCurves and M x LineStrings.
      SET @v_geomn = 1;
      WHILE ( @v_geomn <= @p_linestring.STNumCurves() )
      BEGIN
        SET @v_part_geom = @p_linestring.STCurveN(@v_geomn);
        /* Check if this part includes the required measure */
        IF ( @v_part_geom.ShortestLineTo(@p_point).STLength() = @v_shortest_line.STLength() )
        BEGIN
          SET @v_result_point = [$(lrsowner)].[STProjectPoint] ( 
                                  /* @p_linestring */ @v_part_geom,
                                  /* @p_point      */ @p_point, 
                                  /* @p_round_xy   */ @v_round_xy,
                                  /* @p_round_zm   */ @v_round_zm 
                                );
        END;
        SET @v_geomn  = @v_geomn + 1;
      END; 
    END;
    RETURN @v_result_point;
  END;
End
GO

Print 'Creating Functions that use [$(lrsowner)].[STProjectPoint]: ';
GO

Print '2. [$(lrsowner)].[STFindMeasureByPoint] function ....';
GO

CREATE FUNCTION [$(lrsowner)].[STFindMeasureByPoint] 
(
  @p_linestring geometry,
  @p_point      geometry,
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
Returns float 
as
/****f* LRS/STFindMeasureByPoint  (2012)
 *  NAME
 *    STFindMeasureByPoint -- Returns value of the measure dimension of a point on the provided linesting closest to the provided point.
 *  SYNOPSIS
 *    Function [$(lrsowner)].[STFindMeasureByPoint] (
 *               @p_linestring geometry,
 *               @p_point      geometry,
 *               @p_round_xy   int   = 3,
 *               @p_round_zm   int   = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    Given a point near a the supplied measure @p_linestring, this function returns the measure of the closest point on the measured @p_linestring. 
 *
 *    Returned measure value is rounded to @p_round_zm decimal digits of precision.
 *  NOTES
 *    Srid of @p_linestring and @p_point must be the same.
 *
 *    @p_linestring must be measured.
 *  INPUTS
 *    @p_linestring (geometry) - Measured linestring with or without Z ordinates.
 *    @p_point      (geometry) - Point near to linestring.
 *    @p_round_xy        (int) - Decimal digits of precision for XY ordinates.
 *    @p_round_zm        (int) - Decimal digits of precision for M ordinate.
 *  RESULT
 *    measure value    (float) - Measure of point found on @p_linestring.
 *  EXAMPLE
 *   select [$(lrsowner)].[STFindMeasureByPoint] (
 *              geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *              geometry::Point(8,8,28355),
 *              3,2) as measure
 *    union all
 *    select [$(lrsowner)].[STFindMeasureByPoint] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *             geometry::Point(10,0,28355),
 *             3,2) as measure
 *    GO
 *
 *    measure
 *    23.44
 *    15.61
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original coding.
 *    Simon Greener - December 2017 - Port to SQL Server (TSQL).
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_interpolated_point geometry;
  BEGIN
    If ( @p_linestring is null )
      Return NULL;

    If ( @p_point is null )
      Return NULL;
 
    If ( @p_linestring.STSrid <> @p_point.STSrid )
      Return Null;

    SET @v_interpolated_point = [$(lrsowner)].[STProjectPoint] (
                                        /* @p_linestring    */ @p_linestring,
                                        /* @p_start_measure */ @p_point,
                                        /* @p_round_xy      */ @p_round_xy,
                                        /* @p_round_zm      */ @p_round_zm
                                   );

    IF ( @v_interpolated_point is null ) 
      Return NULL;

    IF ( @v_interpolated_point.HasM = 1 ) 
      Return @v_interpolated_point.M;

    Return NULL;
  END;
END
GO

Print '3. [$(lrsowner)].[STFindMeasure] function ....';
GO

CREATE FUNCTION [$(lrsowner)].[STFindMeasure] 
(
  @p_linestring geometry,
  @p_point      geometry,
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
Returns float 
as
/****f* LRS/STFindMeasure (2012)
 *  NAME
 *    STFindMeasure -- Snaps input point to measured linestring returning measure value
 *  SYNOPSIS
 *     Function STFindMeasure (
 *        @p_linestring geometry,
 *        @p_point      geometry,
 *        @p_round_xy   int = 3,
 *        @p_round_zm   int = 2 
 *      )
 *      Returns float 
 *  DESCRIPTION
 *    Given a point near a the supplied measure @p_linestring, this function returns the measure of the closest point on the measured @p_linestring. 
 *
 *    Measure value returned is rounded to supplied @p_round_zm parameter.
 *  NOTES
 *    Is identical to [lrs].[STFindMeasureByPoint].
 *    Srid of @p_linestring and @p_point must be the same.
 *    @p_linestring must be measured.
 *  INPUTS
 *    @p_linestring (geometry) - Measured (Multi)LineString geometry.
 *    @p_point      (geometry) - Offset Point for which closest linestring point measure is needed.
 *    @p_round_xy        (int) - Decimal digits of precision for XY ordinates.
 *    @p_round_zm        (int) - Decimal digits of precision for M ordinate.
 *  RESULT
 *    measure          (float) - Measure of closest point on line to supplied point.
 *  EXAMPLE
 *    select [lrs].[STFindMeasure] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *             geometry::Point(8,8,28355),
 *             3,2) as measure
 *    union all
 *    select [lrs].[STFindMeasure] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *             geometry::Point(10,0,28355),
 *             3,2) as measure
 *    GO
 *    
 *    measure
 *    23.44
 *    15.61
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - November 2017 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  Return [$(lrsowner)].[STFindMeasureByPoint] (
            /* @p_linestring    */ @p_linestring,
            /* @p_start_measure */ @p_point,
            /* @p_round_xy      */ @p_round_xy,
            /* @p_round_zm      */ @p_round_zm
         );
END
GO

Print '4. [$(lrsowner)].[STFindOffset] function ....';
GO

CREATE FUNCTION [$(lrsowner)].[STFindOffset] 
(
  @p_linestring geometry,
  @p_point      geometry,
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
Returns float 
as
/****f* LRS/STFindOffset (2012)
 *  NAME
 *    STFindOffset -- Compute smallest perpendicular offset from supplied point to the supplied linestring.
 *  SYNOPSIS
 *     Function [$(lrsowner)].[STFindOffset] (
 *         @p_linestring geometry,
 *         @p_point      geometry,
 *         @p_round_xy   int = 3,
 *         @p_round_zm   int = 2 
 *      )
 *      Returns float 
 *  DESCRIPTION
 *    Given a point near @p_linestring, this function returns the perpendicular distance from it to the closest point on @p_linestring. 
 *
 *    Returned measure value is rounded to @p_round_zm decimal digits of precision.
 *  NOTES
 *    Calls [$(lrsowner)].[STProjectPoint].
 *    Srid of @p_linestring and @p_point must be the same.
 *  INPUTS
 *    @p_linestring (geometry) - (Multi)LineString geometry.
 *    @p_point      (geometry) - Offset Point for which closest linestring point measure is needed.
 *    @p_round_xy        (int) - Decimal digits of precision for XY ordinates.
 *    @p_round_zm        (int) - Decimal digits of precision for M ordinate.
 *  RESULT
 *    offset           (float) - Perpendicular offset distance from point to nearest point on line.
 *  EXAMPLE
 *    select [lrs].[STFindOffset] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *             geometry::Point(8,8,28355),
 *             3,2) offset_distance
 *    union all
 *    select [lrs].[STFindOffset] (
 *             geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *             geometry::Point(10,0,28355),
 *             3,2)
 *    go
 *    
 *    offset_distance
 *    2
 *    0
 *  TODO 
 *    Value is negative if on left of line; positive if on right.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - November 2017 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_interpolated_point geometry;
  BEGIN
    IF ( @p_linestring is null or @p_point is null ) 
      Return null;
    IF ( @p_linestring.STSrid <> @p_point.STSrid ) 
      Return null;
    SET @v_interpolated_point = [$(lrsowner)].[STProjectPoint] (
                                        /* @p_linestring    */ @p_linestring,
                                        /* @p_start_measure */ @p_point,
                                        /* @p_round_xy      */ @p_round_xy,
                                        /* @p_round_zm      */ @p_round_zm
                                   );
    IF ( @v_interpolated_point is null ) 
      Return NULL;
    Return @p_point.STDistance(@v_interpolated_point);
  END;
END;
GO


