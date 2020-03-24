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
Begin
  Declare
    @v_linestring  geometry,
    @v_tolerance   float,
    @v_buffer      geometry,
    @v_buffer_ring geometry;

    IF ( @p_linestring is null ) 
      Return @p_linestring;

    IF ( ( @p_linestring.STGeometryType() = 'LineString'     and @p_linestring.STNumPoints() = 2 ) 
      OR ( @p_linestring.STGeometryType() = 'CircularString' and @p_linestring.STNumPoints() = 3 ) )
      Return @p_linestring;

    SET @v_tolerance = ABS(ROUND(1.0/POWER(10,@p_round_xy-1),@p_round_xy-1))

    -- Get start and end segments that don't disappear.
    SET @v_buffer      = @p_linestring.STBuffer(ABS(@p_offset_distance));
    SET @v_buffer_ring = @v_buffer.STExteriorRing();

   -- TODO: Need to extend to all pairs within linestring.
    WITH segments as (
      SELECT s.id, s.geom as segment
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
                          ).ShortestLineTo(@v_buffer_ring).STLength(),
                          @p_round_xy
                    ) as Dist2Boundary
               FROM segments s
           ) as f
       WHERE f.Dist2Boundary <= @v_tolerance
    )
    SELECT @v_linestring = [$(owner)].[STMakeLineFromGeometryCollection] ( 
                              [$(owner)].[STRound](geometry::CollectionAggregate ( f.line ),@p_round_xy,@p_round_xy,@p_round_zm,@p_round_zm),
                              @p_round_xy,
                              @p_round_zm 
                           )
      FROM (SELECT TOP (100) PERCENT
                   s.segment as line 
              FROM ids as i
                     INNER JOIN
                       segments as s 
                         ON (s.id between i.minId and i.maxId)
             ORDER BY s.id
          ) as f;
   return @v_linestring;
End;
GO

