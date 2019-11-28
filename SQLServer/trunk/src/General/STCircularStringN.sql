PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STCircularStringN]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STCircularStringN];
  PRINT 'Dropped [$(owner)].[STCircularStringN] ...';
END;
GO

PRINT 'Creating [$(owner)].[STCircularStringN] ...';
GO

CREATE FUNCTION [$(owner)].[STCircularStringN](
  @p_geometry geometry,
  @p_stringN  integer
)
RETURNS geometry
AS
/****f* INSPECTION/STCircularStringN (2012)
 *  NAME
 *    STCircularStringN-- Extracts CircularString from input CircularString that has more than one CircularArc in it.
 *  SYNOPSIS
 *    Function [$(owner)].[STCircularStringN] (
 *                @p_geometry geometry,
 *                @p_stringN
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    A CircularString can have more than one string encoded within it.
 *    For example if a circularString has 3 points it only has one circularString in it.
 *    If a circularString has 5 points then it has two CircularStrings in it (Point 3 if end of first and start of second).
 *    This function extracts each string but it is checked for validity before being returned.
 *    If the string is invalid (collinear) null is returned by [$(owner)].[STNumCircularStrings]
 *  INPUTS
 *    @p_geometry   (geometry) -- CircularString
 *    @p_stringN     (integer) -- CircularString element within @p_geometry 1..NumCircularStrings
 *  RESULT
 *    circularSting (geometry) -- Circular String described by 3 points.
 *  NOTE
 *    Uses [$(owner)].[STNumCircularStrings]
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) as p_geometry
 *    )
 *    SELECT NumStrings.IntValue as curveN,
 *           [$(owner)].[STCircularStringN](a.p_geometry, NumStrings.IntValue).AsTextZM() as cString
 *      FROM data as a
 *           cross apply
 *           [$(owner)].[generate_series](1,[$(owner)].[STNumCircularStrings](p_geometry),1) as NumStrings;
 *    GO
 * 
 *    CurveN cString
 *    1      CIRCULARSTRING (0 0, 0 4, 3 6.3246)
 *    2      CIRCULARSTRING (3 6.3246, 5 5, 6 3)
 *    3      CIRCULARSTRING (6 3, 5 0, 0 0)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - November 2019 - Ported to SQL Server TSQL from PostgreSQL
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  DECLARE
    @v_point_id   integer,
	@v_numStrings integer,
    @v_cString    geometry;
   SET @v_numStrings = [$(owner)].[STNumCircularStrings](@p_geometry);
   IF ( @p_stringN > @v_numStrings ) 
     RETURN NULL;
   SET @v_cString    = [$(owner)].[STMakeCircularLine] (
                          @p_geometry.STPointN((@p_stringN-1)*2 + 1),
                          @p_geometry.STPointN((@p_stringN-1)*2 + 2),
                          @p_geometry.STPointN((@p_stringN-1)*2 + 3),
						  15,15,15
                        );
  RETURN @v_cString;
END;
GO

PRINT 'Testing [$(owner)].[STCircularStringN] ...';
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) as p_geometry
)
SELECT NumStrings.IntValue as curveN,
       [$(owner)].[STCircularStringN](a.p_geometry, NumStrings.IntValue).AsTextZM() as cString
  FROM data as a
       cross apply
       [$(owner)].[generate_series](1,[$(owner)].[STNumCircularStrings](p_geometry),1) as NumStrings;
GO


