USE [$(usedbname)]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) Cogo($(cogoowner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(cogoowner)].[STFindLineIntersection]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindLineIntersection];
  Print 'Dropped STFindLineIntersection ....';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(cogoowner)].[STFindLineIntersectionBySegment]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindLineIntersectionBySegment];
  Print 'Dropped [$(cogoowner)].[STFindLineIntersectionBySegment] ....';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(cogoowner)].[STFindLineIntersectionDetails]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindLineIntersectionDetails];
  Print 'Dropped [$(cogoowner)].[STFindLineIntersectionDetails] ....';
END;
GO

Print 'Creating [$(cogoowner)].[STFindLineIntersection] ....';
GO

CREATE FUNCTION [$(cogoowner)].[STFindLineIntersection]
(
 @x11 float, @y11 float,
 @x12 float, @y12 float,
 @x21 float, @y21 float,
 @x22 float, @y22 float 
)
Returns geometry
As
/****f* COGO/STFindLineIntersection (2008)
 *  NAME
 *    STFindLineIntersection -- Finds intersection point between two simple, two ordinate, line segments. 
 *  SYNOPSIS
 *    Function STFindLineIntersection (
 *               @x11     float, @y11     float,
 *               @x12     float, @y12     float,
 *               @x21     float, @y21     float,
 *               @x22     float, @y22     float 
 *             )
 *     Returns geometry
 *  USAGE
 *    Print 'Crossed Lines ...';
 *    GO
 *    SELECT f.intersections.AsTextZM() as intersection,
 *           f.intersections.STGeometryN(1).AsTextZM() as iPoint,
 *           f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
 *           f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
 *      FROM (SELECT [cogo].[STFindLineIntersection](0,0,10,10,0,10,10,0) as intersections ) as f;
 *     GO
 *     intersection                     iPoint      iPointOnSegment1 iPointOnSegment1
 *     -------------------------------- ----------- ---------------- ----------------
 *     MULTIPOINT ((5 5), (5 5), (5 5)) POINT (5 5) POINT (5 5)      POINT (5 5)
 *
 *     Print 'Extended Intersection ...';
 *     GO
 *    SELECT f.intersections.AsTextZM() as intersection,
 *           f.intersections.STGeometryN(1).AsTextZM() as iPoint,
 *           f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
 *           f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
 *      FROM (SELECT [cogo].[STFindLineIntersection](0,0,10,10,0,10,10,0) as intersections ) as f;
 *     GO
 *     intersection                     iPoint      iPointOnSegment1 iPointOnSegment1
 *     -------------------------------- ----------- ---------------- ----------------
 *     MULTIPOINT ((5 5), (5 5), (4 6)) POINT (5 5) POINT (5 5)      POINT (4 6)
 *
 *     Print 'Parallel Lines (meet at single point)....';
 *     GO
 *     SELECT f.intersections.AsTextZM() as intersection,
 *            f.intersections.STGeometryN(1).AsTextZM() as iPoint,
 *            f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
 *            f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
 *       FROM (SELECT [$(cogoowner)].[STFindLineIntersection] (0,0,10,0, 0,20,10,0) as intersections ) as f;
 *     GO
 *     intersection                        iPoint       iPointOnSegment1 iPointOnSegment1
 *     ----------------------------------- ------------ ---------------- ----------------
 *     MULTIPOINT ((10 0), (10 0), (10 0)) POINT (10 0) POINT (10 0)     POINT (10 0)
 * 
 *     Print 'Parallel Lines that do not meet at single point....';
 *     GO
 *     SELECT f.intersections.AsTextZM() as intersection,
 *            f.intersections.STGeometryN(1).AsTextZM() as iPoint,
 *            f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
 *            f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
 *       FROM (SELECT [$(cogoowner)].[STFindLineIntersection] (0,0,10,0, 0,1,10,1) as intersections ) as f;
 *     GO
 *     intersection                        iPoint       iPointOnSegment1 iPointOnSegment1
 *     ----------------------------------- ------------ ---------------- ----------------
 *     MULTIPOINT ((10 0), (10 0), (10 0)) POINT (10 0) POINT (10 0)     POINT (10 0)
 *  DESCRIPTION
 *    Finds intersection point between two lines: 
 *      1. If first and second segments have a common point, it is returned for all three points.
 *      2. Point(1) is the point where the lines defined by the segments intersect.
 *      3. Point(2) is the point on segment 1 that is closest to segment 2 (can be Point(1) or Start/End point )
 *      4. Point(3) is the point on segment 2 that is closest to segment 1 (can be Point(1) or Start/End point )
 *      5. If the lines are parallel, all returned ordinates are set to @c_MaxFloat of -1.79E+308 
 *      6. If the point of intersection is not on both segments, then this is almost certainly not the
 *         point where the two segments are closest.
 *
 *     If the lines are parallel, all returned 
 *     -------
 *     Method:
 *     Treat the lines as parametric where line 1 is:
 *       X = x11 + dx1 * t1
 *       Y = y11 + dy1 * t1
 *     and line 2 is:
 *       X = x21 + dx2 * t2
 *       Y = y21 + dy2 * t2
 *     Setting these equal gives:
 *       x11 + dx1 * t1 = x21 + dx2 * t2
 *       y11 + dy1 * t1 = y21 + dy2 * t2
 *     Rearranging:
 *       x11 - x21 + dx1 * t1 = dx2 * t2
 *       y11 - y21 + dy1 * t1 = dy2 * t2
 *       (x11 - x21 + dx1 * t1) *   dy2  = dx2 * t2 *   dy2
 *       (y11 - y21 + dy1 * t1) * (-dx2) = dy2 * t2 * (-dx2)
 *     Adding the equations gives:
 *       (x11 - x21) * dy2 + ( dx1 * dy2) * t1 +
 *       (y21 - y11) * dx2 + (-dy1 * dx2) * t1 = 0
 *     Solving for t1 gives:
 *       t1 * (dy1 * dx2 - dx1 * dy2) =
 *       (x11 - x21) * dy2 + (y21 - y11) * dx2
 *       t1 = ((x11 - x21) * dy2 + (y21 - y11) * dx2) /
 *            (dy1 * dx2 - dx1 * dy2)
 *     Now solve for t2.
 *     ----------
 *     @Note       : If 0 <= t1 <= 1, then the point lies on segment 1.
 *                 : If 0 <= t2 <= 1, then the point lies on segment 1.
 *                 : If dy1 * dx2 - dx1 * dy2 = 0 then the lines are parallel.
 *                 : If the point of intersection is not on both
 *                 : segments, then this is almost certainly not the
 *                 : point where the two segments are closest.
 *
 *  INPUTS
 *    @x11 (float) - X Ordinate of the start point for the first vector
 *    @y11 (float) - Y Ordinate of the start point for the first vector
 *    @x12 (float) - X Ordinate of the end point for the first vector
 *    @y12 (float) - Y Ordinate of the end point for the first vector
 *    @x21 (float) - X Ordinate of the start point for the second vector
 *    @y21 (float) - Y Ordinate of the start point for the second vector
 *    @x22 (float) - X Ordinate of the end point for the second vector
 *    @y22 (float) - Y Ordinate of the end point for the second vector
 *  RESULT
 *    MultiPoint (geometry) - (iPoint)  Intersection point, 
 *                            (iPoint1) Intersection point on linestring 1.
 *                            (iPoint2) Intersection point on linestring 2.
 *  NOTES
 *    Assumes planar projection eg UTM.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - May 2008 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @c_MaxFloat  float = -1.79E+308,
    @v_wkt       varchar(max),
    @inter_x     float, @inter_y  float,
    @inter_x1    float, @inter_y1 float,
    @inter_x2    float, @inter_y2 float,
    @dX1         Float,
    @dY1         Float,
    @dx2         Float,
    @dy2         Float,
    @t1          Float,
    @t2          Float,
    @denominator Float;
  BEGIN
    SET @v_wkt = 'MULTIPOINT (';
    -- Short Circuit: Check for common point
    IF ( @x11 = @x21 and @y11 = @y21 )
    BEGIN
      SET @inter_x = @x11;
      SET @inter_y = @y11;
    END;
    IF ( @x11 = @x22 and @y11 = @y22 )
    BEGIN
      SET @inter_x = @x11;
      SET @inter_y = @y11;
    END;
    IF ( @x12 = @x21 and @y12 = @y21 )
    BEGIN
      SET @inter_x = @x12;
      SET @inter_y = @y12;
    END;
    IF ( @x12 = @x22 and @y12 = @y22 )
    BEGIN
      SET @inter_x = @x12;
      SET @inter_y = @y12;
    END;
    -- We have an intersection.
    IF ( @inter_x <> @c_MaxFloat )
    BEGIN
      SET @v_WKT = @v_wkt 
                 + '(' + [$(owner)].[STPointAsText] ('XY',@inter_x,@inter_y,NULL,NULL,15,15,8,8) + '),'
                 + '(' + [$(owner)].[STPointAsText] ('XY',@inter_x,@inter_y,NULL,NULL,15,15,8,8) + '),'
                 + '(' + [$(owner)].[STPointAsText] ('XY',@inter_x,@inter_y,NULL,NULL,15,15,8,8) + '))';
      Return geometry::STGeomFromText(@v_wkt,0);
    END;

    -- Get the segments' parameters.
    SET @dX1 = @x12 - @x11;
    SET @dY1 = @y12 - @y11;
    SET @dx2 = @x22 - @x21;
    SET @dy2 = @y22 - @y21;

    -- Solve for t1 and t2.
    SET @denominator = (@dY1 * @dx2 - @dX1 * @dy2);
    IF ( @denominator = 0 ) 
    BEGIN
      -- The lines are parallel.
      SET @v_WKT = @v_wkt 
                 + REPLACE(geometry::Point (@c_MaxFloat,@c_MaxFloat,0).STAsText(),'POINT','') + ','
                 + REPLACE(geometry::Point (@c_MaxFloat,@c_MaxFloat,0).STAsText(),'POINT','') + ','
                 + REPLACE(geometry::Point (@c_MaxFloat,@c_MaxFloat,0).STAsText(),'POINT','') + ')';
      Return geometry::STGeomFromText(@v_wkt,0);
    END;

    SET @t1 = ((@x11 - @x21) * @dy2 + (@y21 - @y11) * @dx2) /  @denominator;
    SET @t2 = ((@x21 - @x11) * @dY1 + (@y11 - @y21) * @dX1) / -@denominator;

    -- Find the point of intersection.
    SET @inter_x = @x11 + @dX1 * @t1;
    SET @inter_y = @y11 + @dY1 * @t1;

    -- Find the closest points on the segments.
    If @t1 < 0 
    BEGIN
      SET @t1 = 0;
    END
    ELSE
    BEGIN
      IF @t1 > 1 
      BEGIN
        SET @t1 = 1;
      END;
    END;

    IF @t2 < 0 
    BEGIN
      SET @t2 = 0;
    END 
    ELSE
    BEGIN
      If @t2 > 1 
      BEGIN
        SET @t2 = 1;
      END;
    END;

    SET @inter_x1 = @x11 + @dX1  * @t1;
    SET @inter_y1 = @y11 + @dY1  * @t1;
    SET @inter_x2 = @x21 + @dx2 * @t2;
    SET @inter_y2 = @y21 + @dy2 * @t2;

    SET @v_WKT = @v_wkt 
                 + '(' + [$(owner)].[STPointAsText] ('XY',@inter_x, @inter_y, NULL,NULL,15,15,8,8) + '),'
                 + '(' + [$(owner)].[STPointAsText] ('XY',@inter_x1,@inter_y1,NULL,NULL,15,15,8,8) + '),'
                 + '(' + [$(owner)].[STPointAsText] ('XY',@inter_x2,@inter_y2,NULL,NULL,15,15,8,8) + '))';
    Return geometry::STGeomFromText(@v_wkt,0);
  END;
END;
GO

Print 'Creating [$(cogoowner)].[STFindLineIntersectionBySegment] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindLineIntersectionBySegment]
(
  @p_line_segment_1 geometry,
  @p_line_segment_2 geometry
)
returns geometry
As
/****f* COGO/STFindLineIntersectionBySegment (2008)
 *  NAME
 *    STFindLineIntersectionBySegment -- Finds intersection point between two simple, two ordinate, line segments. 
 *  SYNOPSIS
 *    Function STFindLineIntersectionBySegment (
 *       @p_line_segment_1 geometry,
 *       @p_line_segment_2 geometry
 *    )
 *     Returns geometry;
 *  USAGE
 *    SELECT [$(cogoowner)].[STFindLineIntersectionBySegment] (
 *                geometry::STLineFromText('LINESTRING(0 0,10 10)',0),
 *                geometry::STLineFromText('LINESTRING(0 10,10 0)',0)
 *           ).AsTextZM() as Intersection
 *    GO
 *    Intersection
 *    MULTIPOINT ((5 5), (5 5), (5 5))
 *
 *  DESCRIPTION
 *    Finds intersection point between two lines: 
 *    Calls STFindLineIntersection so see its documentation.
 *  INPUTS
 *    @p_line_segment_1 (geometry) - 2 Point LineString.
 *    @p_line_segment_2 (geometry) - 2 Point LineString.
 *  RESULT
 *    MultiPoint (geometry) - (iPoint)  Intersection point, 
 *                            (iPoint1) Intersection point on linestring 1.
 *                            (iPoint2) Intersection point on linestring 2.
 *  NOTES
 *    Only Supports 2 Point LineStrings.
 *    Assumes planar projection eg UTM.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - May 2008 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_MultiPoint geometry;
  Begin
    IF (@p_line_segment_1 is null
     or @p_line_segment_2 is null ) 
      Return NULL; 

    IF ( (@p_line_segment_1 is not null and @p_line_segment_1.STGeometryType() <> 'LineString' )
     OR  (@p_line_segment_2 is NOT null and @p_line_segment_2.STGeometryType() <> 'LineString' ) ) 
     Return NULL;

    IF ( @p_line_segment_1.STNumPoints() <> 2 OR  @p_line_segment_2.STNumPoints() <> 2 )
      Return NULL;

    SET @v_MultiPoint = 
            [$(cogoowner)].[STFindLineIntersection] ( 
                  @p_line_segment_1.STStartPoint().STX,
                  @p_line_segment_1.STStartPoint().STY,
                  @p_line_segment_1.STPointN(2).STX,
                  @p_line_segment_1.STPointN(2).STY,
                  @p_line_segment_2.STStartPoint().STX,
                  @p_line_segment_2.STStartPoint().STY,
                  @p_line_segment_2.STPointN(2).STX,
                  @p_line_segment_2.STPointN(2).STY
           );

    Return geometry::STGeomFromText(@v_multiPoint.AsTextZM(),
                                    @p_line_segment_1.STSrid);
  End;
End;
GO

Print 'Creating [$(cogoowner)].[STFindLineIntersectionDetails] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindLineIntersectionDetails]
(
  @p_line_segment_1 geometry,
  @p_line_segment_2 geometry
)
Returns varchar(max)
/****f* COGO/STFindLineIntersectionDetails (2008)
 *  NAME
 *    STFindLineIntersectionDetails -- Interprets intersection that results from a call to STFindLineIntersectionBySegment with same parameter values.
 *  SYNOPSIS
 *    Create Function STFindLineIntersectionDetails 
 *       @p_line_segment_1 geometry,
 *       @p_line_segment_2 geometry
 *    )
 *     Returns varchar(max);
 *  USAGE
 *    with data as (
 *    select c.IntValue as offset, 
 *           geometry::STGeomFromText('LINESTRING (0.0 0.0, 20.0 0.0, 20.0 10.0)',0) as line
 *      from [$(owner)].[Generate_Series] (0,-25,-5) as c
 *    )
 *    select f.offset,
 *           [$(owner)].[STRound]([$(cogoowner)].[STFindLineIntersectionBySegment] (first_segment,second_segment),3,3,1,1).STAsText() as geom,
 *           [$(cogoowner)].[STFindLineIntersectionDetails](first_segment,second_segment) as reason
 *      from (select b.offset,
 *                   [$(owner)].[STOffsetSegment](                                                   a.geom,b.offset,8,8) as first_segment,
 *                   [$(owner)].[STOffsetSegment](lead(a.geom,1) over (partition by b.offset order by a.id),b.offset,8,8) as second_segment 
 *              from data as b
 *                   cross apply 
 *                   [$(owner)].[STSegmentLine] (b.line) as a
 *           ) as f
 *     where second_segment is not null
 *    order by offset;
 *    GO
 *    offset geom                                   reason
 *    -25    MULTIPOINT ((-5 25), (0 25), (-5 10))  Virtual Intersection Near Start 1 and End 2
 *    -20    MULTIPOINT ((0 20), (0 20), (0 10))    Virtual Intersection Within 1 and Near End 2
 *    -15    MULTIPOINT ((5 15), (5 15), (5 10))    Virtual Intersection Within 1 and Near End 2
 *    -10    MULTIPOINT ((10 10), (10 10), (10 10)) Intersection within both segments
 *     -5    MULTIPOINT ((15 5), (15 5), (15 5))    Intersection within both segments
 *      0    MULTIPOINT ((20 0), (20 0), (20 0))    Intersection at End 1 Start 2 
 *  DESCRIPTION
 *    Describes intersection point between two lines: 
 *    Internal code is same as STFindLineIntersection with parameters from STFindLineIntersectionBySegment so see their documentation.
 *    Processes code that determines intersections as per STFindLineIntersection but determines nature of intersection ie whether physical, virtual, nearest point on segment etc.
 *  INPUTS
 *    @p_line_segment_1 (geometry) - 2 Point LineString.
 *    @p_line_segment_2 (geometry) - 2 Point LineString.
 *  RESULT
 *    Interpretation (varchar) - One of:
 *      Intersection at End 1 End 2
 *      Intersection at End 1 Start 2
 *      Intersection at Start 1 End 2
 *      Intersection at Start 1 Start 2
 *      Intersection within both segments
 *      Parallel
 *      Unknown
 *      Virtual Intersection Near End 1 and End 2
 *      Virtual Intersection Near End 1 and Start 2
 *      Virtual Intersection Near Start 1 and End 2
 *      Virtual Intersection Near Start 1 and Start 2
 *      Virtual Intersection Within 1 and Near End 2
 *      Virtual Intersection Within 1 and Near Start 2
 *      Virtual Intersection Within 2 and Near End 1
 *      Virtual Intersection Within 2 and Near Start 1
 *  NOTES
 *    Only Supports 2 Point LineStrings.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - March 2018 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
As
Begin
  Declare
    @c_MaxFloat              float = -1.79E+308,
    @v_description           varchar(200),
    @v_segment_1_description varchar(100),
    @v_segment_2_description varchar(100),
    @v_intersection_points   geometry,
    @v_intersection_point    geometry,
    @v_intersection_point_1  geometry,
    @v_intersection_point_2  geometry;
  BEGIN
    IF (@p_line_segment_1 is null
     or @p_line_segment_2 is null ) 
    BEGIN
      Return NULL; 
    END;

    IF ( (@p_line_segment_1 is not null and @p_line_segment_1.STGeometryType() <> 'LineString' )
     OR  (@p_line_segment_2 is NOT null and @p_line_segment_2.STGeometryType() <> 'LineString' ) ) 
    BEGIN
     Return NULL;
    END;

    IF ( @p_line_segment_1.STNumPoints() <> 2 OR  @p_line_segment_2.STNumPoints() <> 2 )
    BEGIN
      Return 'Only 2 point linestrings are supported.';
    END;

    -- Short Circuit: Check for common point at either end
    --
    IF ( @p_line_segment_1.STStartPoint().STEquals(@p_line_segment_2.STStartPoint()) = 1 )
    BEGIN
      RETURN 'Intersection at Start Point 1 and Start Point 2';
    END;
    IF ( @p_line_segment_1.STStartPoint().STEquals(@p_line_segment_2.STEndPoint()) = 1 )
    BEGIN
      RETURN 'Intersection at Start Point 1 and End Point 2';
    END;
    IF ( @p_line_segment_1.STEndPoint().STEquals(@p_line_segment_2.STStartPoint()) = 1 )
    BEGIN
      RETURN 'Intersection at End Point 1 and Start Point 2';
    END;
    IF ( @p_line_segment_1.STEndPoint().STEquals(@p_line_segment_2.STEndPoint()) = 1 )
    BEGIN
      RETURN 'Intersection at End Point 1 End Point 2';
    END;

    -- Intersection not at one of ends.
    -- Compute intersection.
    --
    SET @v_intersection_points
          = [$(cogoowner)].[STFindLineIntersectionBySegment] (
                @p_line_segment_1,
                @p_line_segment_2
            );

    -- Easy case: parallel
    --
    IF ( @v_intersection_points.STPointN(1).STX = @c_MaxFloat )
    BEGIN
      -- The lines are parallel.
      RETURN 'Parallel';
    END;

    SET @v_intersection_point   = @v_intersection_points.STPointN(1);
    SET @v_intersection_point_1 = @v_intersection_points.STPointN(2);
    SET @v_intersection_point_2 = @v_intersection_points.STPointN(3);

    SET @v_segment_1_description =
                      CASE WHEN @v_intersection_point.STEquals(@p_line_segment_1.STStartPoint()) = 1
                           THEN 'at Start Point 1'
                           WHEN @v_intersection_point.STEquals(@p_line_segment_1.STEndPoint()) = 1
                           THEN 'at End Point 1'
                           ELSE 'Within 1'
                       END;

    SET @v_segment_2_description =
                       +
                       CASE WHEN @v_intersection_point.STEquals(@p_line_segment_2.STStartPoint()) = 1
                            THEN 'at Start Point 2'
                            WHEN @v_intersection_point.STEquals(@p_line_segment_2.STEndPoint()) = 1
                            THEN 'at End Point 2'
                            ELSE 'Within 2'
                        END;

    SET @v_description = 
            CASE WHEN @v_intersection_point.STEquals(@v_intersection_point_1) = 1
                  AND @v_intersection_point.STEquals(@v_intersection_point_2) = 1
                      /* All three intersection points are the same */
                 THEN 'Intersection ' 
                      +
                      @v_segment_1_description
                      +
                      ' and '
                      +
                      @v_segment_2_description

                 WHEN @v_intersection_point.STEquals(@v_intersection_point_1) = 1
                  and @v_intersection_point.STEquals(@v_intersection_point_2) = 0
                      /* Intersection point is within first segment but not second */
                 THEN 'Intersection ' 
                      +
                      @v_segment_1_description
                      +
                      ' and Virtual Intersection '
                      +
                      CASE WHEN @v_intersection_point_2.STEquals(@p_line_segment_2.STStartPoint()) = 1
                           THEN 'Near Start Point 2'
                           WHEN @v_intersection_point_2.STEquals(@p_line_segment_2.STEndPoint()) = 1
                           THEN 'Near End Point 2'
                           ELSE 'Outside 2'
                        END

                 WHEN @v_intersection_point.STEquals(@v_intersection_point_2) = 1
                  and @v_intersection_point.STEquals(@v_intersection_point_1) = 0
                      /* Intersection point is within second segment but not first */
                 THEN 'Virtual Intersection Near '
                      + 
                      CASE WHEN @v_intersection_point_1.STEquals(@p_line_segment_1.STStartPoint()) = 1
                           THEN 'Start Point 1'
                           WHEN @v_intersection_point_1.STEquals(@p_line_segment_1.STEndPoint()) = 1
                           THEN 'End Point 1'
                       END
                      +
                      ' and '
                      +
                      @v_segment_2_description

                 WHEN @v_intersection_point.STEquals(@v_intersection_point_1) = 0
                  and @v_intersection_point.STEquals(@v_intersection_point_2) = 0
                 THEN 'Virtual Intersection Near ' 
                      + 
                      CASE WHEN @v_intersection_point_1.STEquals(@p_line_segment_1.STStartPoint())=1
                            AND @v_intersection_point_2.STEquals(@p_line_segment_2.STStartPoint())=1
                           THEN 'Start 1 and Start 2'
                           WHEN @v_intersection_point_1.STEquals(@p_line_segment_1.STEndPoint())=1
                            AND @v_intersection_point_2.STEquals(@p_line_segment_2.STEndPoint())=1
                           THEN 'End 1 and End 2'
                           WHEN @v_intersection_point_1.STEquals(@p_line_segment_1.STStartPoint())=1
                            AND @v_intersection_point_2.STEquals(@p_line_segment_2.STEndPoint())=1
                           THEN 'Start 1 and End 2'
                           WHEN @v_intersection_point_1.STEquals(@p_line_segment_1.STEndPoint())=1
                            AND @v_intersection_point_2.STEquals(@p_line_segment_2.STStartPoint())=1
                           THEN 'End 1 and Start 2'
                           ELSE 'Unknown'
                       END
                 ELSE 'Unknown'
             END;
    Return @v_description;
  END;
END;
GO

Print '------------------------------------------------------';
Print 'Testing [$(cogoowner)].[STFindLineIntersection] ...';
GO

Print 'Crossed Lines ...';
GO

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersection](0,0,10,10,0,10,10,0) as intersections ) as f;
GO

Print 'Extended Intersection ...';
GO

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersection](0,0,10,10,0,10,4,6) as intersections ) as f;
GO

Print 'Parallel Lines (meet at single point)....';
GO

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersection] (0,0,10,0, 0,20,10,0) as intersections ) as f;
GO

Print 'Parallel Lines that do not meet at single point....';
GO

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersection] (0,0,10,0, 0,1,10,1) as intersections ) as f;
GO

Print '----------------------------------------------------';
Print 'Testing [$(cogoowner)].[STFindLineIntersectionBySegment]: ';
GO

SELECT [$(cogoowner)].[STFindLineIntersectionBySegment] (
          geometry::STLineFromText('LINESTRING(0 0,10 10)',0),
          geometry::STLineFromText('LINESTRING(0 10,10 0)',0)
       ).AsTextZM() as intersection;
GO

Print '----------------------------------------------------';
Print 'Testing [$(cogoowner)].[STFindLineIntersectionDetails]: ';
GO

with data as (
select -20 as offset, geometry::STGeomFromText('LINESTRING (0 20, 20 20)',0) as first_segment, geometry::STGeomFromText('LINESTRING (0 0, 0 10)',0) as second_segment
union all
select -10 as offset, geometry::STGeomFromText('LINESTRING (0 10, 20 10)',0) as first_segment, geometry::STGeomFromText('LINESTRING (10 0, 10 10)',0) as second_segment
union all
select  -5 as offset, geometry::STGeomFromText('LINESTRING (0 5, 20 5)',0) as first_segment, geometry::STGeomFromText('LINESTRING (15 0, 15 10)',0) as second_segment
union all
select   0 as offset, geometry::STGeomFromText('LINESTRING (0 0, 20 0)',0) as first_segment, geometry::STGeomFromText('LINESTRING (20 0, 20 10)',0) as second_segment
union all
select -15 as offset, geometry::STGeomFromText('LINESTRING (0 15, 20 15)',0) as first_segment, geometry::STGeomFromText('LINESTRING (5 0, 5 10)',0) as second_segment
union all
select -25 as offset, geometry::STGeomFromText('LINESTRING (0 25, 20 25)',0) as first_segment, geometry::STGeomFromText('LINESTRING (-5 0, -5 10)',0) as second_segment
)
select f.offset,
       [$(owner)].[STRound]([$(cogoowner)].[STFindLineIntersectionBySegment](first_segment,second_segment),3,3,1,1).STAsText() as geom,
                            [$(cogoowner)].[STFindLineIntersectionDetails]  (first_segment,second_segment) as reason
  from data as f
order by offset;
GO

PRINT '******************************************************************';
GO

QUIT
GO

select geometry::STGeomFromText('CIRCULARSTRING (0 0, 10 10, 20 0)',0) as circular
union all
select geometry::STGeomFromText('LINESTRING (-2 -2, 25 -2)',0) as circular;

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersectionBySegment] (
  geometry::STGeomFromText('LINESTRING (-2 -2, 25 -2)',0),
  geometry::STGeomFromText('CIRCULARSTRING (30 0, 40 10, 50 0)',0) 
  ) as intersections ) as f;
GO

select geometry::STGeomFromText('CIRCULARSTRING (0 0, 10 10, 20 0)',0) as circular
union all
select geometry::STGeomFromText('CIRCULARSTRING (30 0, 40 10, 50 0)',0) as circular;

SELECT f.intersections.AsTextZM() as intersection,
       f.intersections.STGeometryN(1).AsTextZM() as iPoint,
       f.intersections.STGeometryN(2).AsTextZM() as iPointOnSegment1,
       f.intersections.STGeometryN(3).AsTextZM() as iPointOnSegment1
  FROM (SELECT [$(cogoowner)].[STFindLineIntersectionBySegment] (
  geometry::STGeomFromText('CIRCULARSTRING (0 0, 10 10, 20 0)',0),
  geometry::STGeomFromText('CIRCULARSTRING (30 0, 40 10, 50 0)',0) 
  ) as intersections ) as f;
GO

