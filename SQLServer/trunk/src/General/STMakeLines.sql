USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '*************************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) COGO Owner([$(cogoowner)])';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STMakeLineXY]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakeLineXY];
  PRINT 'Dropped [$(owner)].[STMakeLineXY] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STMakeLine]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakeLine];
  PRINT 'Dropped [$(owner)].[STMakeLine] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STMakeLineFromMultiPoint]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakeLineFromMultiPoint];
  PRINT 'Dropped [$(owner)].[STMakeLineFromMultiPoint] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STMakeCircularLine]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakeCircularLine];
  PRINT 'Dropped [$(owner)].[STMakeCircularLine] ...';
END;
GO

/* *************************** FUNCTIONS ************************************* */

PRINT 'Creating [$(owner)].[STMakeLineXY] ...';
GO

CREATE FUNCTION [$(owner)].[STMakeLineXY] 
(
  @p_start_x  float,
  @p_start_y  float,
  @p_end_x    float,
  @p_end_y    float,
  @p_srid     int = 0,
  @p_round_xy int = 10
)
Returns geometry
AS
/****f* CREATE/STMakeLineXY (2008)
 *  NAME
 *    STMakeLineXY -- Creates a two point 2D XY linestring.
 *  SYNOPSIS
 *    Function STMakeLine (
 *               @p_start_x  float,
 *               @p_start_y  float,
 *               @p_end_x    float,
 *               @p_end_y    float,
 *               @p_srid     int = 0,
 *               @p_round_xy int = 10
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].STMakeLineXY(0,0,10,10,28355).STAsText() as line;
 *    LINE
 *    LINESTRING (0 0,10 10)
 *  DESCRIPTION
 *    Function creates a two point 2D linestring from supplied start and end XY values.
 *    The output linestring's XY ordinates are rounded to the supplied @p_round_xy value.
 *  NOTES
 *    If any of @p_start_x/y or @p_end_x/y are null, a null result is returned.
 *  INPUTS
 *    @p_start_x  (float) - Start X ordinate
 *    @p_start_y  (float) - Start Y ordinate
 *    @p_end_x    (float) - End X ordinate
 *    @p_end_y    (float) - End Y ordinate
 *    @p_srid       (int) - Srid 
 *    @p_round_xy   (int) - rounding value for ordinates.
 *  RESULT
 *    linestring (geometry) - LineString from start point to end point.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
    @v_wkt        varchar(max),
    @v_Dimensions varchar(4),
    @v_round_xy   int,
    @v_srid       int;

 IF (@p_start_x is null 
  or @p_start_y is null 
  or @p_end_x   is null
  or @p_end_y   is null)
   return null;

  SET @v_dimensions = 'XY'; 
  SET @v_round_xy   = ISNULL(@p_round_xy,10);
  SET @v_srid       = ISNULL(@p_srid,0);
  SET @v_wkt = 'LINESTRING (' 
               +
               [$(owner)].[STPointAsText] (
                        @v_dimensions,
                        @p_start_X,
                        @p_start_Y,
                        NULL,
                        NULL,
                        @v_round_xy,
                        @v_round_xy,
                        15,
                        15
               )
               +
               ', '
               +
               [$(owner)].[STPointAsText] (
                        @v_dimensions,
                        @p_end_X,
                        @p_end_Y,
                        Null,
                        Null,
                        @v_round_xy,
                        @v_round_xy,
                        15,
                        15
               )
               +
               ')';

  Return geometry::STLineFromText( @v_wkt, @v_srid );
END
GO

PRINT 'Creating [$(owner)].[STMakeLine] ...';
GO

CREATE FUNCTION [$(owner)].[STMakeLine] 
(
  @p_start_point geometry,
  @p_end_point   geometry,
  @p_round_xy    int = 10,
  @p_round_zm    int = 10
)
Returns geometry
AS
/****f* CREATE/STMakeLine (2008)
 *  NAME
 *    STMakeLine -- Creates a two point linestring.
 *  SYNOPSIS
 *    Function STMakeLine (
 *               @p_start_point geometry,
 *               @p_end_point   geometry,
 *               @p_round_xy    int = 10,
 *               @p_round_zm    int = 10
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].[STMakeLine](geometry::Point(0,0,0),geometry::Point(10,10,28355)) as line;
 *    LINE
 *    45
 *  DESCRIPTION
 *    Function creates a two point linestring from supplied start and end points.
 *    The output linestring's XY ordinates are rounded to the supplied @p_round_xy value.
 *    The output linestring's ZM ordinates are rounded to the supplied @p_round_zm value.
 *  NOTES
 *    If @p_start_point or @p_end_point are null, a null result is returned.
 *    If @p_start_point or @p_end_point have different SRIDS, a null result is returned.
 *  INPUTS
 *    @p_start_point  (geometry) - Not null start point.
 *    @p_end_point    (geometry) - Not null end point.
 *    @p_round_xy     (int)      - XY ordinate precision.
 *    @p_round_zm     (int)      - ZM ordinate precision.
 *  RESULT
 *    linestring      (geometry) - LineString from start point to end point.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
    @v_wkt        varchar(max),
    @v_Dimensions varchar(4),
    @v_round_xy   int,
    @v_round_zm   int;
  Begin
    IF (@p_start_point is null or @p_end_point is null)
      return null;
    IF (@p_start_point.STGeometryType() <> 'Point' 
     or @p_end_point.STGeometryType()   <> 'Point' )
      return null;
    IF (ISNULL(@p_start_point.STSrid,0) <> ISNULL(@p_end_point.STSrid,0) )
      return null;
    SET @v_dimensions = 'XY' 
                       + case when @p_start_point.HasZ=1 then 'Z' else '' end 
                       + case when @p_start_point.HasM=1 then 'M' else '' end;
    SET @v_round_xy   = ISNULL(@p_round_xy,10);
    SET @v_round_zm   = ISNULL(@p_round_zm,10);
    SET @v_wkt = 'LINESTRING (' 
                 +
                 [$(owner)].[STPointAsText] (
                          @v_dimensions,
                          @p_start_point.STX,
                          @p_start_point.STY,
                          @p_start_point.Z,
                          @p_start_point.M,
                          @v_round_xy,
                          @v_round_xy,
                          @v_round_zm,
                          @v_round_zm
                 )
                 +
                 ', '
                 +
                 [$(owner)].[STPointAsText] (
                          @v_dimensions,
                          @p_end_point.STX,
                          @p_end_point.STY,
                          @p_end_point.Z,
                          @p_end_point.M,
                          @v_round_xy,
                          @v_round_xy,
                          @v_round_zm,
                          @v_round_zm
                 )
                 +
                 ')';
    Return geometry::STLineFromText(
                       @v_wkt,
                       @p_end_point.STSrid
                     );
  End;
END
GO

PRINT 'Creating [$(owner)].[STMakeLineFromMultiPoint] ...';
GO

CREATE FUNCTION [$(owner)].[STMakeLineFromMultiPoint] 
(
  @p_points geometry
)
Returns geometry
AS
/****f* CREATE/STMakeLineFromMultiPoint (2008)
 *  NAME
 *    STMakeLineFromMultiPoint -- Creates a linestring from supplied MULTIPOINT geometry.
 *  SYNOPSIS
 *    Function STMakeLineFromMultiPoint (
 *               @p_points geometry
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].STMakeLineFromMultiPoint(geometry::STGeomFromText('MULTIPOINT(((0,0),(10,10))',28355) as line;
 *    LINE
 *    LINESTRING(0 0,10 10)
 *  DESCRIPTION
 *    Function creates linestring from supplied points in @p_points (MultiPoint).
 *  NOTES
 *    Only MultiPoint input geometry supported.
 *  INPUTS
 *    @p_points (geometry) - Not null MultiPoint geometry.
 *  RESULT
 *    linestring -- LineString from provided multipoint geometry.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *      Creative Commons Attribution-Share Alike 2.5 Australia License.
 *      http://creativecommons.org/licenses/by-sa/2.5/au/
 ******/
BEGIN
  DECLARE
    @v_wkt varchar(max);
  BEGIN
    IF (@p_points is null)
      return null;
    IF (@p_points.STGeometryType() <> 'MultiPoint' )
      return null;
    SET @v_wkt = REPLACE(REPLACE(REPLACE(@p_points.AsTextZM(),'MULTIPOINT (','LINESTRING '),'), (',','),'))',')');
    Return geometry::STGeomFromText(@v_wkt,@p_points.STSrid);
  END;
END
GO

PRINT '********************************************';
PRINT 'Creating [$(owner)].[STMakeCircularLine] ...';
GO

CREATE FUNCTION [$(owner)].[STMakeCircularLine] 
(
  @p_start_point geometry,
  @p_mid_point   geometry,
  @p_end_point   geometry,
  @p_round_xy    int = 8,
  @p_round_z     int = 8,
  @p_round_m     int = 8
)
Returns geometry
AS
/****f* CREATE/STMakeCircularLine (2008)
 *  NAME
 *    STMakeCircularLine -- Creates a three point Circular linestring.
 *  SYNOPSIS
 *    Function STMakeCircularLine (
 *               @p_start_point geometry,
 *               @p_mid_point   geometry,
 *               @p_end_point   geometry,
 *               @p_round_xy    int = 8,
 *               @p_round_z     int = 8,
 *               @p_round_m     int = 8
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT $(owner).STMakeCircularLine(
 *              geometry::Point(0,0,28355),
 *              geometry::Point(5,5,28355),
 *              geometry::Point(10,10,28355),
 *              1,1,null
 *           ) as cline;
 *    LINE
 *    45
 *  DESCRIPTION
 *    Function creates a three point Circular linestring from supplied start, mid and end points.
 *    The output linestring's XY ordinates are rounded to the supplied p_round_xy value.
 *    The output linestring's Z ordinates are rounded to the supplied p_round_z value.
 *    The output linestring's M ordinates are rounded to the supplied p_round_m value.
 *  NOTES
 *    If @p_start_point, or @p_mid_point, or @p_end_point are null, a null result is returned.
 *    If @p_start_point, or @p_mid_point, or @p_end_point have different SRIDS, a null result is returned.
 *    If points are collinear (XY only), null is returned.
 *    Z is returned if ALL points have Z ordinates and all values are equal.
 *    M is returned if ALL points have M ordinates.
 *  INPUTS
 *    @p_start_point (geometry) - Not null start point.
 *    @p_mid_point   (geometry) - Not null start point.
 *    @p_end_point   (geometry) - Not null end point.
 *    @p_round_xy         (int) - XY ordinate precision.
 *    @p_round_z          (int) - Z ordinate precision.
 *    @p_round_m          (int) - M ordinate precision.
 *  RESULT
 *    circular linestring (geometry) - Circular LineString from start point, through mid point, to end point.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - March 2018 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
    @v_wkt          varchar(max),
    @v_Dimensions   varchar(4),
    @v_angle3points float,
    @v_round_xy     int,
    @v_round_z      int,
    @v_round_m      int;
  Begin
    IF (@p_start_point is null 
     or @p_mid_point   is null
     or @p_end_point   is null)
      return null;

    IF (@p_start_point.STGeometryType() <> 'Point' 
     or @p_mid_point.STGeometryType()   <> 'Point' 
     or @p_end_point.STGeometryType()   <> 'Point' )
      return null;

    IF (ISNULL(@p_start_point.STSrid,0) <> ISNULL(@p_mid_point.STSrid,0) 
     or ISNULL(@p_start_point.STSrid,0) <> ISNULL(@p_end_point.STSrid,0) )
      return null;

    -- Check collinearity
    SET @v_angle3points = [$(cogoowner)].[STSubtendedAngle] (
                             @p_start_point.STX, @p_start_point.STY, 
                             @p_mid_point.STX,   @p_mid_point.STY, 
                             @p_end_point.STX,   @p_end_point.STY 
                          );
    IF (ABS(@v_angle3points) = PI() or @v_angle3points = 0.0 )
      return null;

    SET @v_dimensions = 'XY' 
                       + case when   @p_start_point.HasZ=1 
                                   and @p_mid_point.HasZ=1
                                   and @p_end_point.HasZ=1
                                   and @p_start_point.Z = @p_mid_point.Z
                                   and @p_mid_point.Z   = @p_end_point.Z
                              then 'Z' 
                              else '' 
                          end 
                       + case when   @p_start_point.HasM=1 
                                   and @p_mid_point.HasM=1
                                   and @p_end_point.HasM=1
                              then 'M' 
                              else '' 
                          end;
    SET @v_round_xy   = ISNULL(@p_round_xy,8);
    SET @v_round_z    = ISNULL(@p_round_z, 8);
    SET @v_round_m    = ISNULL(@p_round_m, 8);
    SET @v_wkt = 'CIRCULARSTRING (' 
                 +
                 [$(owner)].[STPointAsText] (
                          @v_dimensions,
                          @p_start_point.STX,
                          @p_start_point.STY,
                          @p_start_point.Z,
                          @p_start_point.M,
                          @v_round_xy,
                          @v_round_xy,
                          @v_round_z,
                          @v_round_m
                 )
                 +
                 ', '
                 +
                 [$(owner)].[STPointAsText] (
                          @v_dimensions,
                          @p_mid_point.STX,
                          @p_mid_point.STY,
                          @p_mid_point.Z,
                          @p_mid_point.M,
                          @v_round_xy,
                          @v_round_xy,
                          @v_round_z,
                          @v_round_m
                 )
                 +
                 ', '
                 +
                 [$(owner)].[STPointAsText] (
                          @v_dimensions,
                          @p_end_point.STX,
                          @p_end_point.STY,
                          @p_end_point.Z,
                          @p_end_point.M,
                          @v_round_xy,
                          @v_round_xy,
                          @v_round_z,
                          @v_round_m
                 )
                 +
                 ')';
    Return geometry::STGeomFromText( @v_wkt, @p_end_point.STSrid );
  End;
END
go

-- ******************************* Testing ***************************

Print 'Testing STMakeLineXY...';
GO

SELECT [$(owner)].[STMakeLineXY](null,null,null,null,null,null);
GO
SELECT [$(owner)].[STMakeLineXY](0,0,10,10,0,3).STAsText();
GO

Print 'Testing STMakeLine...';
GO

SELECT [$(owner)].[STMakeLine](null,null,null,null);
GO
SELECT [$(owner)].[STMakeLine](geometry::Point(0,0,0),null,null,null);
GO
SELECT [$(owner)].[STMakeLine](null,geometry::Point(10,10,0),null,null);
GO
SELECT [$(owner)].[STMakeLine](geometry::Point(0,0,0),geometry::Point(10,10,28355),3,2);
GO
SELECT [$(owner)].[STMakeLine](geometry::Point(0,0,0),geometry::Point(10,10,0),3,2).STAsText();
GO

Print 'Testing STMakeLineFromMultiPoint ...';
GO

select [$(owner)].[STMakeLineFromMultiPoint](geometry::STGeomFromText('MULTIPOINT((0 0),(1 1),(2 2),(3 3))',0)).AsTextZM();
GO

Print 'Testing STMakeCircularLine...';
Print 'Parameter Test.'
GO
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), null,geometry::Point(10,0,0),10,3,3);
Print 'SRID Test.'
GO
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(5,0,0),geometry::Point(10,0,100),10,3,3);
Print 'Collinear Test 1.'
GO
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(5,0,0),geometry::Point(10,0,0),10,3,3);
Print 'Collinear Test 2.'
GO
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(5,5,0),geometry::Point(10,10,0),10,3,3);
Print 'Duplicate Point Test.'
GO
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(0,0,0),geometry::Point(10,10,0),10,3,3);
Print 'Real Circular Arc Test.'
select [$(owner)].[STMakeCircularLine] (geometry::Point(0,0,0), geometry::Point(5,5,0),geometry::Point(10,0,0),10,3,3);
GO

