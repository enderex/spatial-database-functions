USE [$(usedbname)]
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
     WHERE id = object_id(N'[$(owner)].[STMakePoint]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakePoint];
  PRINT 'Dropped [$(owner)].[STMakePoint] ...';
END;
GO

/* *************************** FUNCTIONS ************************************* */

PRINT 'Creating [$(owner)].[STMakePoint] ...';
GO

CREATE FUNCTION [$(owner)].[STMakePoint] 
(
  @p_x    float,
  @p_y    float,
  @p_z    float,
  @p_m    float,
  @p_srid int = 0
)
Returns geometry
As
/****f* CREATE/STMakePoint (2008)
 *  NAME
 *    STMakePoint -- Creates a point from input ordinates.
 *  SYNOPSIS
 *    Function STMakePoint (
 *               @p_x    float,
 *               @p_y    float,
 *               @p_z    float,
 *               @p_m    float,
 *               @p_srid int = 0
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT f.point.AsTextZM() as point, f.point.STSrid as srid
 *      FROM (SELECT [$(owner)].[STMakePoint](1,2,3,4,28355) as point) as f;
 *    point    srid
 *    POINT (1 2 3 4)    28355
 *  DESCRIPTION
 *    Function creates a point from the supplied ordinates.
 *  NOTES
 *    Extends supplied non-OGC static function Point.
 *    Alternative to extended WKT constructor:
 *  INPUTS
 *    @p_x        (float) - Not null X Ordinate.
 *    @p_y        (float) - Not null Y Ordinate.
 *    @p_z        (float) - Not null Z Ordinate.
 *    @p_m        (float) - Not null M Ordinate.
 *  RESULT
 *    Point                      - Geometry point.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *    Creative Commons Attribution-Share Alike 2.5 Australia License.
 *    http://creativecommons.org/licenses/by-sa/2.5/au/
 ******/
Begin
  Declare
    @v_dimensions varchar(4),
    @v_wkt        varchar(max),
    @v_round_xy   int,
    @v_round_zm   int;
  Begin
    SET @v_round_xy = 10;
    SET @v_round_zm = 10;
    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_Z is not null then 'Z' else '' end 
                       + case when @p_M is not null then 'M' else '' end;
    -- Get Coordinate String 
    SET @v_wkt = [$(owner)].[STPointAsText] (
                   @v_dimensions,
                   @p_X,
                   @p_Y,
                   @p_Z,
                   @p_M,
                   @v_round_xy,
                   @v_round_xy,
                   @v_round_zm,
                   @v_round_zm 
                 );
    IF (@v_wkt is null)
      Return NULL;
    Return geometry::STPointFromText('POINT(' + @v_wkt + ')',ISNULL(@p_srid,0));
  End;
END
GO

-- ******************************* Testing ***************************

Print 'Testing STMakePoint...';
GO

SELECT [$(owner)].STMakePoint(10,10,null,null,0);
GO

SELECT f.point.AsTextZM() as point, 
       f.point.STSrid as srid
  FROM (SELECT [$(owner)].[STMakePoint](1,2,3,4,28355) as point) as f;
GO

