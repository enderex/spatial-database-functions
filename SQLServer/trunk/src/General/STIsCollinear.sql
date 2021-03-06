SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '****************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

PRINT 'Dropping [$(owner)].[STIsCollinear]...';
GO
IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STIsCollinear]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STIsCollinear];
  PRINT 'Dropped [$(owner)].[STIsCollinear] ...';
END;
GO

PRINT 'Creating [$(owner)].[STIsCollinear]...';
GO

CREATE FUNCTION [$(owner)].[STIsCollinear]
(
  @p_linestring          geometry,
  @p_collinear_threshold float = 0.5
)
Returns bit
As
/****f* EDITOR/STIsCollinear (2012)
 *  NAME
 *    STIsCollinear -- Function that checks if a linestring's points all lie on straight line.
 *  SYNOPSIS
 *    Function [$(owner)].[STIsCollinear] (
 *               @p_linestring          geometry,
 *               @p_collinear_threshold float = -1
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].[STIsCollinear] (
 *             geometry::STGeomFromText('LINESTRING(0 0,0.5 0.5,1 1)',0),
 *             0.5
 *           ) as is_collinear;
 *
 *    is_collinear
 *    ---------------------------------------------
 *    1
 *  DESCRIPTION
 *    Function that checks if a line is straight defined by points that are all collinear.
 *    Threshold is applied to deflection angle between a pair of segments. 
 *    If deflection angle < threshold then the two linestring pairs are considered to be 
 *    collinar (ie delfection angle = 0.)
 *  INPUTS
 *    @p_linestring       (geometry) - Supplied Linestring geometry.
 *    @p_collinear_threshold (float) - Deflection tolerance between a pair of segments.
 *  RESULT
 *    boolean                  (bit) - 1 (true) if collinear, 0 otherwise.
 *  NOTES
 *    Uses [location].[STFindDeflectionAngle]
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - October 2019 - Original TSQL Coding
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_geometry_type       varchar(100),
	@v_collinear_threshold float,
    @v_is_collinear        bit;
  Begin
    If ( @p_linestring is null ) 
      Return null;

    -- Only process linear geometries.
    SET @v_geometry_type = @p_linestring.STGeometryType();
    IF ( @v_geometry_type <> 'LineString' )
      Return null;

	SELECT @v_is_collinear = CASE WHEN COUNT(*) = 1 THEN 1 ELSE 0 END
      FROM (SELECT distinct 
                   case when ABS(deflection_angle) < @v_collinear_threshold then 0.0 else f.deflection_angle end as deflection_angle
              FROM (SELECT TOP (100) PERCENT
                           [$(cogoowner)].[STFindDeflectionAngle] (
                                     v.geom,
                                     lead(v.geom, 1) over (order by v.id)
                           ) as deflection_angle
                      FROM [$(owner)].[STSegmentLine](@p_linestring) as v
                     ORDER BY v.segment_id /* Make sure pairs are in correct order */
                   ) as f
             WHERE f.deflection_angle IS not null
	       ) as g;
    RETURN @v_is_collinear;	 
  End;
END;
GO

