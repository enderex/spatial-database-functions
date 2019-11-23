USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSplitProcedure]') 
    AND xtype IN (N'P')
)
BEGIN
  DROP PROCEDURE [$(lrsowner)].[STSplitProcedure];
  PRINT 'Dropped [$(lrsowner)].[STSplitProcedure] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STSplit]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STSplit];
  PRINT 'Dropped [$(lrsowner)].[STSplit] ...';
END;
GO

-- ***********************************************************

PRINT 'Creating [$(lrsowner)].[STSplitProcedure]...'
GO

CREATE PROCEDURE [$(lrsowner)].[STSplitProcedure] (
  @p_linestring geometry,
  @p_point      geometry,
  @p_line1      geometry OUTPUT,
  @p_line2      geometry OUTPUT,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
AS  
/****m* LRS/STSplitProcedure (2012)
 *  NAME
 *    STSplitProcedure -- Procedure that splits a line into two parts.
 *  SYNOPSIS
 *    Function [$(lrsowner)].[STSplitProcedure] (
 *       @p_linestring geometry,
 *       @p_point      geometry,
 *       @p_line1      geometry OUTPUT,
 *       @p_line2      geometry OUTPUT,
 *       @p_round_xy   int = 3,
 *       @p_round_zm   int = 2
 *     )
 *     Returns geometry 
 *  USAGE
 *    declare @v_linestring geometry = geometry::STGeomFromText('LINESTRING(0 0,10 10,20 20,30 30,40 40,50 50,60 60,70 70,80 80,90 90,100 100)',0),
 *            @v_point      geometry = geometry::STGeomFromText('POINT(50 50)',0),
 *            @v_line1      geometry,
 *            @v_line2      geometry;
 *    exec [$(lrsowner)].[STSplitProcedure] @p_linestring=@v_linestring,
 *                              @p_point=@v_point,
 *                              @p_line1=@v_line1 OUTPUT,
 *                              @p_line2=@v_line2 OUTPUT,
 *                              @p_round_xy=3,
 *                              @p_round_zm=2;
 *    select @v_line1.STAsText() as line1, @v_line2.STAsText() as line2
 *    GO
 *    line1                                               line2
 *    LINESTRING (0 0, 10 10, 20 20, 30 30, 40 40, 50 50)	LINESTRING (50 50, 60 60, 70 70, 80 80, 90 90, 100 100)
 *  DESCRIPTION
 *    Splits @p_linestring at position defined by @p_point.
 *    If @p_point is not on the line it is first snapped to the line.
 *    Supports CircularString and CompoundCurve geometry objects and subelements from 2012 onewards.
 *  INPUTS
 *    @p_linestring (geometry) - Supplied Linestring geometry.
 *    @p_point      (geometry) - Supplied split point.
 *    @p_line1      (geometry) - Is an OUTPUT parameter that holds the first part of split line.
 *    @p_line2      (geometry) - Is an OUTPUT parameter that holds the second part of split line.
 *    @p_round_xy        (int) - Decimal degrees of precision for when formatting XY ordinates in WKT.
 *    @p_round_zm        (int) - Decimal degrees of precision for when formatting Z ordinate in WKT.
 *  RESULT
 *    Two linestrings (geometry) - Two parts of split linestring.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN 
  Declare
	@v_projectedPoint geometry,
	@v_isMeasured     varchar(5);
  IF (@p_linestring is null or @p_point is null)
    Return;
  IF (ISNULL(@p_linestring.STSrid,0) <> ISNULL(@p_point.STSrid,0))
    Return;
  IF ( @p_linestring.STGeometryType() not in ('LineString','CircularString','MultiLineString','CircularCurve') )
    Return;
  IF ( @p_point.STGeometryType() <> 'Point')
    Return;

  SET @v_isMeasured  = [$(lrsowner)].[STIsMeasured](@p_linestring);

  /* Snap point to line and returning point.
     @v_projectedPoint's Z/M set to Z/M values in @p_linestring.
     Except where @p_linestring does not have measures, the length 
	 from the start point of @p_length to @p_point is returnd in M ordinate. */
  SET @v_projectedPoint = [$(lrsowner)].[STProjectPoint] (
           /* @p_linestring*/ @p_Linestring,
           /* @p_point     */ @p_point,
           /* @p_round_xy  */ @p_round_xy,
           /* @p_round_zm  */ case when @v_isMeasured = 'TRUE' then @p_round_zm else 8 end
        );

   /* Now split the linestring using length or measure information */
   IF ( @v_isMeasured = 'TRUE' ) 
   BEGIN
     SET @p_line1 = 
          [$(lrsowner)].[STFindSegmentByMeasureRange] (
            /* @p_linestring    */ @p_Linestring,
            /* @p_start_measure */ 0.0,
            /* @p_end_measure   */ @v_projectedPoint.M,
            /* @p_offset        */ 0,
            /* @p_round_xy      */ @p_round_xy,
            /* @p_round_zm      */ @p_round_zm
          );
     SET @p_line2 = 
	       [$(lrsowner)].[STFindSegmentByMeasureRange] (
             /* @p_linestring    */ @p_Linestring,
             /* @p_start_measure */ @v_projectedPoint.M,
             /* @p_end_measure   */ [$(lrsowner)].[STEndMeasure](@p_Linestring),
             /* @p_offset        */ 0,
             /* @p_round_xy      */ @p_round_xy,
             /* @p_round_zm      */ @p_round_zm
          );
   END
   ELSE
   BEGIN
     SET @p_line1 = 
           [$(lrsowner)].[STFindSegmentByLengthRange] (
             /* @p_linestring   */ @p_Linestring,
             /* @p_start_length */ 0.0,
             /* @p_end_length   */ @v_projectedPoint.M,
             /* @p_offset       */ 0,
             /* @p_round_xy     */ @p_round_xy,
             /* @p_round_zm     */ 8 /* Deliberate as M will hold length */
           );
     SET @p_line2 = 
	       [$(lrsowner)].[STFindSegmentByLengthRange] (
             /* @p_linestring   */ @p_Linestring,
             /* @p_start_length */ @v_projectedPoint.M,
             /* @p_end_length   */ @p_Linestring.STLength(),
             /* @p_offset       */ 0,
             /* @p_round_xy     */ @p_round_xy,
             /* @p_round_zm     */ 8 /* Deliberate as M will hold length */
           );
   END;
   RETURN;
END;
GO

PRINT 'Creating [$(lrsowner)].[STSplit]...'
GO

CREATE FUNCTION [$(lrsowner)].[STSplit] 
(
  @p_linestring geometry,
  @p_point      geometry,
  @p_round_xy   int   = 3,
  @p_round_zm   int   = 2
)
Returns @lines TABLE
(
  line1 geometry,
  line2 geometry
)
AS  
/****m* LRS/STSplit (2012)
 *  NAME
 *    STSplit -- Function that splits a line into two parts.
 *  SYNOPSIS
 *    Function [$(lrsowner)].[STSplit] (
 *       @p_linestring geometry,
 *       @p_point      geometry,
 *       @p_round_xy   int = 3,
 *       @p_round_zm   int = 2
 *     )
 *     Returns @lines TABLE
 *     (
 *       line1 geometry,
 *       line2 geometry
 *     )
 *  DESCRIPTION
 *    Splits @p_linestring at position defined by @p_point.
 *    If @p_point is not on the line it is first snapped to the line.
 *    Supports CircularString and CompoundCurve geometry objects and subelements from 2012 onewards.
 *  INPUTS
 *    @p_linestring (geometry) - Supplied Linestring geometry.
 *    @p_point      (geometry) - Supplied split point.
 *    @p_round_xy        (int) - Decimal degrees of precision for when formatting XY ordinates in WKT.
 *    @p_round_zm        (int) - Decimal degrees of precision for when formatting Z ordinate in WKT.
 *  RESULT
 *    Single record containing one or two linestrings
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('LINESTRING(0 0,10 10,20 20,30 30,40 40,50 50,60 60,70 70,80 80,90 90,100 100)',0) as line,
 *             geometry::STGeomFromText('POINT(50 50)',0) as point
 *    )
 *    select s.line1.AsTextZM() as line1, s.line2.AsTextZM() as line2
 *      from data as a
 *           cross apply 
 *           [$(lrsowner)].[STSplit](
 *                 a.line,
 *                 a.point,
 *                 3,
 *                 2
 *           ) as s;
 *    line1                                               line2
 *    LINESTRING (0 0, 10 10, 20 20, 30 30, 40 40, 50 50) LINESTRING (50 50, 60 60, 70 70, 80 80, 90 90, 100 100)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN 
  Declare
	@v_line1          geometry,
	@v_line2          geometry,
	@v_projectedPoint geometry,
	@v_isMeasured     varchar(5);
  IF (@p_linestring is null or @p_point is null)
    Return;
  IF (ISNULL(@p_linestring.STSrid,0) <> ISNULL(@p_point.STSrid,0))
    Return;
  IF ( @p_linestring.STGeometryType() not in ('LineString','CircularString','MultiLineString','CircularCurve') )
    Return;
  IF ( @p_point.STGeometryType() <> 'Point')
    Return;

  SET @v_isMeasured  = [$(lrsowner)].[STIsMeasured](@p_linestring);

  /* Snap point to line and returning point.
     @v_projectedPoint's Z/M set to Z/M values in @p_linestring.
     Except where @p_linestring does not have measures, the length 
     from the start point of @p_length to @p_point is returnd in M ordinate. */
  SET @v_projectedPoint = [$(lrsowner)].[STProjectPoint] (
           /* @p_linestring*/ @p_Linestring,
           /* @p_point     */ @p_point,
           /* @p_round_xy  */ @p_round_xy,
           /* @p_round_zm  */ case when @v_isMeasured = 'TRUE' then @p_round_zm else 8 end
        );

   /* Now split the linestring using length or measure information */
   IF ( @v_isMeasured = 'TRUE' ) 
   BEGIN
     SET @v_line1 = 
          [$(lrsowner)].[STFindSegmentByMeasureRange] (
            /* @p_linestring    */ @p_Linestring,
            /* @p_start_measure */ 0.0,
            /* @p_end_measure   */ @v_projectedPoint.M,
            /* @p_offset        */ 0,
            /* @p_round_xy      */ @p_round_xy,
            /* @p_round_zm      */ @p_round_zm
          );
     SET @v_line2 = 
	       [$(lrsowner)].[STFindSegmentByMeasureRange] (
             /* @p_linestring    */ @p_Linestring,
             /* @p_start_measure */ @v_projectedPoint.M,
             /* @p_end_measure   */ [$(lrsowner)].[STEndMeasure](@p_Linestring),
             /* @p_offset        */ 0,
             /* @p_round_xy      */ @p_round_xy,
             /* @p_round_zm      */ @p_round_zm
          );
   END
   ELSE
   BEGIN
     SET @v_line1 = 
           [$(lrsowner)].[STFindSegmentByLengthRange] (
             /* @p_linestring   */ @p_Linestring,
             /* @p_start_length */ 0.0,
             /* @p_end_length   */ @v_projectedPoint.M,
             /* @p_offset       */ 0,
             /* @p_round_xy     */ @p_round_xy,
             /* @p_round_zm     */ 8 /* Deliberate as M will hold length */
           );
     SET @v_line2 = 
	       [$(lrsowner)].[STFindSegmentByLengthRange] (
             /* @p_linestring   */ @p_Linestring,
             /* @p_start_length */ @v_projectedPoint.M,
             /* @p_end_length   */ @p_Linestring.STLength(),
             /* @p_offset       */ 0,
             /* @p_round_xy     */ @p_round_xy,
             /* @p_round_zm     */ 8 /* Deliberate as M will hold length */
           );
   END;
   INSERT INTO @lines( [line1],[line2] ) 
        VALUES ( @v_line1, @v_line2 );
   RETURN;
END;
GO

-- ***********************************************************************************************

declare @v_linestring geometry = geometry::STGeomFromText('LINESTRING(0 0,10 10,20 20,30 30,40 40,50 50,60 60,70 70,80 80,90 90,100 100)',0),
        @v_point      geometry = geometry::STGeomFromText('POINT(50 50)',0),
        @v_line1      geometry,
        @v_line2      geometry;
exec [$(lrsowner)].[STSplitProcedure]
                    @p_linestring=@v_linestring,
                    @p_point=@v_point,
					@p_line1=@v_line1 OUTPUT,
					@p_line2=@v_line2 OUTPUT,
					@p_round_xy=3,
					@p_round_zm=8;
select @v_line1.STAsText() as line1, 
	   @v_line2.STAsText() as line2;
go

with data as (
  select geometry::STGeomFromText('LINESTRING(0 0,10 10,20 20,30 30,40 40,50 50,60 60,70 70,80 80,90 90,100 100)',0) as line,
         geometry::STGeomFromText('POINT(50 50)',0) as point
)
select s.line1.AsTextZM() as line1, 
       s.line2.AsTextZM() as line2
  from data as a
       cross apply 
       [$(lrsowner)].[STSplit](
             a.line,
             a.point,
             3,
             2
       ) as s;
GO


