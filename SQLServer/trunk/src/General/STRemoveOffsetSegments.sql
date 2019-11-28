SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '****************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STRemoveOffsetSegments]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STRemoveOffsetSegments];
  PRINT 'Dropped [$(owner)].[STRemoveOffsetSegments] ...';
END;
GO

Print 'Creating [$(owner)].[STRemoveOffsetSegments] ...';
GO

CREATE FUNCTION [$(owner)].[STRemoveOffsetSegments] (
  @p_linestring      geometry,
  @p_offset_distance float,
  @p_round_xy        int,
  @p_round_zm        int
)
Returns geometry
As
/****f* EDITOR/STRemoveOffsetSegments (2008)
 *  NAME
 *    STRemoveOffsetSegments -- Removes any start/end segment in provided linestring that disappear when segments are offset
 *  SYNOPSIS
 *    Function [$(owner)].[STRemoveOffsetSegments] (
 *               @p_linestring      geometry,
 *               @p_offset_distance float,
 *               @p_round_xy        int,
 *               @p_round_zm        int,
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].[STRemoveOffsetSegments] (
 *             geometry::STGeomFromText('LINESTRING(0 0,0.5 0.5,1 1)',0),
 *             0.5,
 *             3,2
 *           ).AsTextZM() as LineWithOffsetSegments;
 *    LineWithOffsetSegments
 *    ---------------------------------------------
 *    LINESTRING (0 0,1 1)
 *  DESCRIPTION
 *    Removes any start/end segment in provided linestring that disappear when segments are offset
 *  INPUTS
 *    @p_linestring   (geometry) - Supplied Linestring geometry.
 *    @p_offset)distance (float) - Line offset distance (-/+)/.
 *    @p_round_xy          (int) - Decimal units of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm          (int) - Decimal units of precision to which any calculated ZM ordinates are rounded.
 *  RESULT
 *    Modified linestring (geometry) - Input linestring with any start/end offset segment removed.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - October 2019 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_linestring  geometry,
    @v_tolerance   float,
    @v_buffer      geometry,
    @v_buffer_ring geometry;

    IF ( @p_linestring.STNumPoints() = 2 ) 
      Return @p_linestring;

    SET @v_tolerance = ABS(ROUND(1.0/POWER(10,@p_round_xy-1),@p_round_xy-1))

    -- Get start and end segments that don't disappear.
    SET @v_buffer      = @p_linestring.STBuffer(ABS(@p_offset_distance));
    SET @v_buffer_ring = @v_buffer.STExteriorRing();

   -- TODO: Need to extend to all pairs within linestring.
    WITH segments as (
      SELECT s.id, s.geom as segment,
             s.geom.STNumPoints() as numPoints
        FROM [$(owner)].[STSegmentLine](@p_linestring) as s
    ), ids as (
     SELECT MIN(id) as minId, MAX(id) as maxId
       FROM (SELECT /* original Line as offset segments */
                    s.[id],
                   ROUND([$(owner)].[STOffsetSegment] (
                                   s.segment,
                                   @p_offset_distance,
                                   @p_round_xy,
                                   @p_round_zm
                          ).ShortestLineTo(@v_buffer_ring)
                     .STLength(),
                          @p_round_xy
                    ) as Dist2Boundary
               FROM segments s
           ) as f
       WHERE f.Dist2Boundary <= @v_tolerance
    )
    SELECT @v_linestring = geometry::CollectionAggregate ( f.line )
      FROM (SELECT TOP (100) PERCENT
                   s.segment as line 
              FROM ids as i
                     INNER JOIN
                       segments as s 
                         ON (s.id between i.minId and i.maxId)
             ORDER BY s.id
          ) as f;
   SET @v_linestring = [$(owner)].[STMakeLineFromGeometryCollection] ( 
                          @v_linestring,
                          @p_round_xy,
                          @p_round_zm 
                       );
   Return @v_linestring;
End;
GO

Print 'Testing [$(owner)].[STRemoveOffsetSegments] ...';
Print '... TOBEDONE.';
GO


