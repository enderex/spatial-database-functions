USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS(lrs) Owner($(owner))';
GO

PRINT 'Deleting [$(lrsowner)].[STPointToCircularArc] ...'
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STPointToCircularArc]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STPointToCircularArc];
  PRINT 'Dropped [$(lrsowner)].[STPointToCircularArc] ... ';
END;
GO

PRINT 'Creating [$(lrsowner)].[STPointToCircularArc] ...'
GO

CREATE FUNCTION [$(lrsowner)].[STPointToCircularArc] (
   @p_circularString geometry,
   @p_vertex         geometry,
   @p_round_xy       int   = 3,
   @p_round_zm       int   = 2
)
Returns geometry
As
/****m* LRS/STPointToCircularArc (2012)
 *  NAME
 *    STPointToCircularArc -- Return a measured point by snapping provided point to the provided circularstring
 *  SYNOPSIS
 *    Function [$(lrsowner)].[STPointToCircularArc] (
 *               @p_circularString geometry,
 *               @p_point          geometry,
 *               @p_round_xy       int   = 3,
 *               @p_round_zm       int   = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    This function snaps supplied point to @p_circularString, returning the snapped point.
 *    
 *    Computes Z and M values if exist on @p_circularString.
 *    
 *    If input @p_circularString is 2D, length from start of @p_circularString to point is returned in M ordinate of snapped point.
 *    
 *    Returned points ordinate values are rounded to @p_round_xy/@p_round_zm decimal digits of precision.
 *  NOTES
 *    Supports CircularString geometries only.
 *  INPUTS
 *    @p_circularString (geometry) - (Measured) CircularString with or without Z ordinates.
 *    @p_point          (geometry) - Point near to linestring.
 *    @p_round_xy            (int) - Decimal digits of precision for XY ordinates.
 *    @p_round_zm            (int) - Decimal digits of precision for M ordinate.
 *  RESULT
 *    snapped point (geometry) -- First point found on @p_circularString.
 *  EXAMPLE
 *    select 'Point has relationship with XYZM circular arc' as test,
 *           [lrs].[STPointToCircularArc] (
 *              geometry::STGeomFromText('CIRCULARSTRING (3 6.325 -2.1 0, 0 7 -2.1 3.08, -3 6.325 -2.1 6.15)',0),
 *              geometry::Point(2,8,0),
 *              3,2).AsTextZM() as project_point
 *    union all
 *    select 'Point does not have relationship with XYM CircularSring' as test,
 *           [lrs].[STPointToCircularArc] (
 *              geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),
 *              geometry::Point(8,8,0),
 *              3,2).AsTextZM() as project_point
 *    union all
 *    select 'Point is on centre of the circular arc' as test,
 *           [lrs].[STPointToCircularArc] (
 *              geometry::STGeomFromText('CIRCULARSTRING (3 6.3246 -1, 0 7 -1, -3 6.3246 -1)',0),
 *              geometry::Point(0,0,0),
 *              3,2).AsTextZM() as project_point
 *    union all
 *    select 'Point projects on to point half way along circular arc' as test,
 *           [lrs].[STPointToCircularArc] (
 *              geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0),
 *              geometry::Point(0,3.5,0),
 *              3,2).AsTextZM() as project_point
 *    go
 *    
 *    test                                                    project_point
 *    ------------------------------------------------------- -----------------------------
 *    Point has relationship with XYZM circular arc           POINT (1.698 6.791 -2.1 1.37)
 *    Point does not have relationship with XYM CircularSring NULL
 *    Point is on centre of the circular arc                  POINT (3 6.3246 -1)
 *    Point projects on to point half way along circular arc  POINT (0 7 NULL 3.1)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2019 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_round_xy           int   = 3,
    @v_round_zm           int   = 2,
    @v_gtype              varchar(max),
    @v_dimensions         varchar(100),
    @v_wkt                varchar(max),
    @v_isGeographic       bit,
    @vX                   Float,
    @vY                   Float,
    @magV                 Float,
    @v_geog_vertex        geography,
    @v_geog_centre        geography,
    @v_vertex             geometry,
    @v_centre             geometry,
    @v_intersection_point geometry,
    @v_segment            geometry,
    @v_radius             Float,
    @v_intersection_angle Float,
    @v_circular_arc_angle Float,
    @v_bearing            Float,
    @v_length             Float,
    @v_m                  Float,
    @v_ratio              Float;

    IF ( @p_vertex is null OR @p_circularString is null) BEGIN
      Return null;
    End;

    if ( @p_vertex.STSrid <> @p_circularString.STSrid ) Begin
      Return NULL;
    END;

    IF ( @p_vertex.STGeometryType() <> 'Point' ) BEGIN
      Return @p_vertex;
    END;

    IF ( @p_circularString.STGeometryType() <> 'CircularString' ) BEGIN
    -- IF ( @v_gtype NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve' ) ) BEGIN
      Return @p_circularString;
    END;

    SET @v_round_xy  = ISNULL(@p_round_xy,3);
    SET @v_round_zm  = ISNULL(@p_round_zm,2);

    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                       + case when @p_circularString.HasZ=1 then 'Z' else '' end 
                       + case when @p_circularString.HasM=1 then 'M' else '' end;

    -- Find centre of circle
    SET @v_centre = [$(cogoowner)].[STFindCircleFromArc](@p_circularString); -- z holds radius

    -- Does the CircularArc Define and actual circle?
    IF (  @v_centre.STX = -1 
      and @v_centre.STY = -1 
      and @v_centre.Z   = -1 ) Begin
      -- SGG: Need new function STIsCollinear()
      Return null;
    End;

    -- Note: For geodetic, Z/Radius is in decimal degrees.
    SET @v_radius = @v_centre.Z;

    -- SGG: Align input coodinate dimensions
    SET @v_vertex = @p_vertex;
    IF ( [$(owner)].[STCoordDim](@p_vertex)=2 and [$(owner)].[STCoordDim](@p_circularString)=3 ) Begin
      -- Increase coordinate dimensions to 3
      SET @v_vertex = [$(owner)].[STMakePoint](
                             @p_vertex.STX,
                             @p_vertex.STY,
                             @p_circularString.STPointN(1).Z,
                             NULL,
                             @p_vertex.STSrid
                      );
      SET @v_centre = [$(owner)].[STMakePoint] (
                             @v_centre.STX,
                             @v_centre.STY,
                             @p_circularString.STPointN(1).Z,
                             NULL,
                             @p_circularString.STSrid
                      );

    END ELSE IF ( [$(owner)].[STCoordDim](@p_vertex)=3 and [$(owner)].[STCoordDim](@p_circularString)=3 ) Begin
      -- If Z are not the same they can't intersect
      If ( @p_vertex.Z <> @p_circularString.STPointN(1).Z ) Begin
        return null;
      End;
    END ELSE IF ( [$(owner)].[STCoordDim](@p_vertex) IN (2,3) and [$(owner)].[STCoordDim](@p_circularString)=2 ) Begin
      -- Decrease coordinate dimensions of v_vertex to 2
      SET @v_dimensions = 'XY';
      SET @v_vertex = geometry::Point(
                             @p_vertex.STX,
                             @p_vertex.STY,
                             @p_vertex.STSrid
                     );
      -- SGG: Apply CircularArc's Z (all three the same) to centre
      SET @v_centre = geometry::Point(
                         @v_centre.STX,
                         @v_centre.STY,
                         @p_circularString.STSrid
                      );
    End;

    -- Short circuit if centre = @p_vertex
    -- SGG: Precision Model??
    IF (   [$(owner)].[STRound](@v_centre,@v_round_xy,@v_round_xy,@v_round_zm,@v_round_zm)
         .STEquals(
           [$(owner)].[STRound](@v_vertex,@v_round_xy,@v_round_xy,@v_round_zm,@v_round_zm)
         )=1 ) Begin
      Return @p_circularString.STPointN(1);
    End;

    -- Now compute intersection point with circular arc using math 
    -- SGG Planar Math is inaccurate for Geodetic data???
    SET @vX   = @v_vertex.STX - @v_centre.STX;
    SET @vY   = @v_vertex.STY - @v_centre.STY;
    SET @magV = SQRT(@vX*@vX + @vY*@vY);
    SET @v_intersection_point = geometry::Point(
                                   @v_centre.STX + @vX / @magV * @v_radius,
                                   @v_centre.STY + @vY / @magV * @v_radius,
                                   @p_circularString.STSrid
                                );

    -- Check to see if computed point is actually on circular arc and not virtual circle perimiter
    -- 
    SET @v_length = @v_centre.STDistance(@v_vertex);

    SET @v_isGeographic = [$(owner)].[STisGeographicSrid](@p_vertex.STSrid);
    IF ( @v_isGeographic = 1 ) BEGIN
      SET @v_geog_vertex = [$(owner)].[STToGeography](@p_vertex,        @p_vertex.STSrid);
      SET @v_geog_centre = [$(owner)].[STToGeography](@v_centre,        @p_vertex.STSrid);
      SET @v_length      = @v_geog_centre.STDistance(@v_geog_vertex);  -- SGG: @v_radius is decimal degrees
    END;

    If ( @v_intersection_point is null ) Begin
      If ( @v_length < @v_radius ) Begin
        -- Bearing and distance from centre to circular arc 
        -- Check for Correct Calculation for Geographic/Geodetic data
        SET @v_length  = @v_radius;
        SET @v_bearing = [$(cogoowner)].[STNormalizeBearing](
                              [$(cogoowner)].[STBearingBetweenPoints](
                                        @v_centre,
                                        @v_vertex
                              )
                         );
        SET @v_intersection_point = [$(cogoowner)].[STPointFromCOGO](
                                            @v_centre,
                                            @v_bearing,
                                            @v_length,
                                            @v_round_xy
                                          );
      End;
    End;

    -- *********************************************************
    -- Check if intersection point falls on Circular Arc or not.
    --

    -- Circular arc angle
    SET @v_circular_arc_angle = [$(cogoowner)].[STSubtendedAngleByPoint](
                                        @p_circularString.STPointN(1),
                                        @p_circularString.STPointN(2),
                                        @p_circularString.STPointN(3)
                                );

    -- Now compute again with midCoord replaced by computed point
    SET @v_intersection_angle = [$(cogoowner)].[STSubtendedAngleByPoint](
                                        @p_circularString.STPointN(1),
                                        @v_intersection_point,
                                        @p_circularString.STPointN(3)
                                );

    If ( SIGN(@v_circular_arc_angle) <> SIGN(@v_intersection_angle) ) Begin
      Return NULL;
    End;

    -- Construct point to be returned
    --

    -- 1. Compute subtended angle at centre
    --

    -- 1.1 Circular arc angle
    SET @v_circular_arc_angle = [$(cogoowner)].[STSubtendedAngleByPoint](
                                        @p_circularString.STPointN(1),
                                        @v_centre,
                                        @p_circularString.STPointN(3)
                                );

    -- 1.2 Compute start/centre/intersection 
    SET @v_intersection_angle = [$(cogoowner)].[STSubtendedAngleByPoint](
                                        @p_circularString.STPointN(1),
                                        @v_centre,
                                        @v_intersection_point
                                );

    -- Z is as for any point on circular arc
    -- M is computed as a ratio from start coord.
    --
    SET @v_ratio = @v_intersection_angle / @v_circular_arc_angle;
    If ( @p_CircularString.HasM = 0 ) Begin
      SET @v_m = @p_circularString.STLength() * @v_ratio;
      SET @v_dimensions = CONCAT(@v_dimensions,'M');
    End Else Begin
      SET @v_m = @p_circularString.STPointN(1).M + 
                (@p_circularString.STPointN(3).M - @p_circularString.STPointN(1).M) * 
                 @v_ratio; 
    END;

    SET @v_intersection_point = geometry::STPointFromText(
                               'POINT('
                                +
                                [$(owner)].[STPointAsText] (
                                         /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                                         /* @p_X          */ @v_intersection_point.STX,
                                         /* @p_Y          */ @v_intersection_point.STY,
                                         /* @p_Z          */ @p_circularString.STPointN(1).Z,
                                         /* @p_M          */ @v_m,
                                         /* @p_round_x    */ @v_round_xy,
                                         /* @p_round_y    */ @v_round_xy,
                                         /* @p_round_z    */ @v_round_zm,
                                         /* @p_round_m    */ @v_round_zm
                                 )
                                 +
                                 ')',
                                 @p_circularString.STSrid);

    Return @v_intersection_point;
  End;
Go

-- ************************************************************************************

PRINT 'Testing [$(lrsowner)].[STPointToCircularArc] ...'
GO

-- Falls on circular arc with M no Z
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),
          geometry::Point(2,8,0),
          3,2).AsTextZM() as project_point
go

-- Falls on circular arc with Z
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.325 -2.1 0, 0 7 -2.1 3.08, -3 6.325 -2.1 6.15)',0),
          geometry::Point(2,8,0),
          3,2).AsTextZM() as project_point
go

-- Does not fall on circular arc
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),
          geometry::Point(8,8,0),
          3,2).AsTextZM() as project_point
go

-- 2D Circular Arc - Supplied point is also the centre of the circular arc
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0),
          geometry::Point(0,0,0),
          3,2).AsTextZM() as project_point
go

-- 2D Circular Arc - Supplied point half way between centre of the circular arc and the circular arc
select geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0).STLength() as len,
       [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',0),
          geometry::Point(0,3.5,0),
          3,2).AsTextZM() as project_point
go

-- Unsuported geometries 
select [$(lrsowner)].[STPointToCircularArc] (
          geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
          geometry::Point(8,8,0),
          3,2).AsTextZM() as project_point
go


