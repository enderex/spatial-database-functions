SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STSnapPointToGeom]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STSnapPointToGeom];
  PRINT 'Dropped [$(owner)].[STSnapPointToGeom] ...';
END;
GO

PRINT '################################';
PRINT 'Creating [$(owner)].[STSnapPointToGeom] ...';
GO

CREATE FUNCTION [$(owner)].[STSnapPointToGeom] (
  @p_point       geometry,
  @p_geom        geometry,
  @p_snap_within float,
  @p_round_xy    int = 3
)
Returns geometry
As
/****f* TOOLS/STSnapPointToGeom (2012)
 *  NAME
 *    STSnapPointToGeom -- Function that snaps @p_point to @p_geom returning result of ShortestLineTo if within supplied distance.
 *  SYNOPSIS
 *    Function [dbo].[STSnapPointToGeom] (
 *        @p_point       geometry,
 *        @p_geom        geometry,
 *        @p_snap_within float,
 *        @p_round_xy    int = 3,
 *     )
 *     Returns varchar(max)
 *  DESCRIPTION
 *    This function is a wrapper over ShortestLineTo.
 *    Given a point and a geometry the function computes the shortest distance from the point to the distance.
 *    If that distance is < a user supplied @p_snap_within distance, the snap point is returned.
 *    If the distance is > the user supplied @p_snap_within distance the original point is returned.
 *    The function rounds each ordinate using the supplied rounding factor.
 *  PARAMETERS
 *    @p_point    (geometry) - The point the caller wants snapped to @p_geom.
 *    @p_geom     (geometry) - A geometry the caller wants @p_point snapped to
 *    @p_snap_within (float) - If the distance from @p_point to the snapped point is less than this value, the snapped point is returned.
 *    @p_round_xy      (int) - X Ordinate rounding factor.
 *  RESULT
 *    Point (geometry) - @p_point is it is not within @p_snap_distance, otherwise the snap point geometry is returned.
 *  EXAMPLE
 *     select [dbo].[STSnapPointToGeom](
 *              geometry::STGeomFromText('POINT (2172251.39758337 257358.817891138)',2274),
 *              geometry::STGeomFromText('CIRCULARSTRING (2171796.8166267127 257562.7279690057, 2171785.1539784111 257183.20449278614, 2172044.2970194966 256905.68157368898)', 2274),
 *              NULL,
 *              3
 *            ).AsTextZM();
 *    sPoint
 *    POINT (2171795.01 257158.984)
 *
 *    select snap_within.IntValue as snap_within_distance,
 *           [dbo].[STSnapPointToGeom](
 *            geometry::STGeomFromText('POINT (2172251.39758337 257358.817891138)',2274),
 *            geometry::STGeomFromText('CIRCULARSTRING (2171796.8166267127 257562.7279690057, 2171785.1539784111 257183.20449278614, 2172044.2970194966 256905.68157368898)', 2274),
 *            snap_Within.IntValue,
 *            3
 *           ).AsTextZM() as sPoint
 *      from [dbo].[Generate_Series](100,600,100) as snap_within;
 *    
 *    snap_within_distance sPoint
 *    100                  POINT (2172251.398 257358.818)
 *    200                  POINT (2172251.398 257358.818)
 *    300                  POINT (2172251.398 257358.818)
 *    400                  POINT (2172251.398 257358.818)
 *    500                  POINT (2171795.01 257158.984)
 *    600                  POINT (2171795.01 257158.984)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2020 - Original Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2020 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_dimensions      varchar(4),
    @v_round_xy        int,
    @v_shortest_length float,
    @v_snap_point      geometry,
    @v_shortest_line   geometry;

  IF ( @p_geom is null or @p_point is null )
    Return @p_point;

  IF ( @p_geom.STIsValid() = 0 )
    Return @p_point;

  SET @v_round_xy = ISNULL(@p_round_xy,3);
  SET @v_dimensions = 'XY'
                      + case when @p_point.HasZ=1 then 'Z' else '' end +
                      + case when @p_point.HasM=1 then 'M' else '' end;

  SET @v_shortest_line = @p_point.ShortestLineTo(@p_geom);

  IF ( @v_shortest_line is null ) 
    return @p_point;

  SET @v_shortest_length = @v_shortest_line.STLength();
  SET @v_snap_point = @p_point;
  IF (  @p_snap_within IS NULL 
        OR 
        ROUND(@v_shortest_length,@v_round_xy) < ROUND(@p_snap_within,@v_round_xy) )
  BEGIN
    SET @v_snap_point = @v_shortest_line.STEndPoint();
  END;

  SET @v_snap_point = geometry::STGeomFromText(
                             'POINT ('
                             +
                             [$(owner)].[STPointAsText] (
                               /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                               /* @p_X          */ @v_snap_point.STX,
                               /* @p_Y          */ @v_snap_point.STY,
                               /* @p_Z          */ case when @p_point.HasZ = 1 then @v_snap_point.Z else null end,
                               /* @p_M          */ case when @p_point.HasM = 1 then @v_snap_point.M else null end,
                               /* @p_round_x    */ @v_round_xy,
                               /* @p_round_y    */ @v_round_xy,
                               /* @p_round_z    */ 15,
                               /* @p_round_m    */ 15
                             )
                             +
                             ')',
                             @p_point.STSrid
                      );
  Return @v_snap_point;
End;
go


