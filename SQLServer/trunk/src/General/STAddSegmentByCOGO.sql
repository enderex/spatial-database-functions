SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '**************************************************************** ';
PRINT 'Database Schema Variables are: COGO $(cogoowner) Owner($(owner)).';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(cogoowner)].[STAddSegmentByCOGO]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STAddSegmentByCOGO];
  PRINT 'Dropped [$(cogoowner)].[STAddSegmentByCOGO] ...';
END;
GO

Print 'Creating [$(cogoowner)].[STAddSegmentByCOGO] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STAddSegmentByCOGO]
(
  @p_linestring geometry,
  @p_bearing    float,
  @p_distance   float,
  @p_end        varchar(5) = 'START',  /* OR END only */
  @p_round_xy   int        = 3,
  @p_round_zm   int        = 2
)
returns geometry
as
/****f* COGO/STAddSegmentByCOGO (2008)
 *  NAME
 *    STAddSegmentByCOGO - Returns a projected point given starting point, a bearing in Degrees, and a distance (geometry SRID units).
 *  SYNOPSIS
 *    Function STAddSegmentByCOGO (
 *               @p_linestring geometry,
 *               @p_dBearing   float,
 *               @p_dDistance  float
 *               @p_round_xy   int = 3,
 *               @p_round_zm   int = 2
 *             )
 *     Returns float 
 *  USAGE
 *    SELECT [$(cogoowner)].[STAddSegmentByCOGO] (geometry::STGeomFromText('LINESTRING(0 0,10 0)',0),90,10,3,2).STAsText() as newSegment;
 *    newSegment
 *    LINESTRING (0 0,10 0,20 0)
 *  DESCRIPTION
 *    Function that adds a new segment (two vertices) to an existing linestring's beginning or end. 
 *    New point is created from a start or end coordinate, using a whole circle bearing (p_dBearing) and a distance (p_dDistance) in SRID Units.
 *    Returned point's XY ordinates are rounded to @p_round_xy decimal digits of precision.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring.
 *    @p_dBearing      (float) - Whole circle bearing between 0 and 360 degrees.
 *    @p_dDistance     (float) - Distance in SRID units from starting point to required point.
 *    @p_round_xy        (int) - XY ordinates decimal digitis of precision.
 *    @p_round_zm        (int) - ZM ordinates decimal digitis of precision.
 *  RESULT
 *    Modified line (geometry) - modified Linestring.
 *  TODO
 *    Z,M extrapolation.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType varchar(100),
    @v_dimensions   varchar(4),
    @v_round_xy     int,
    @v_round_zm     int,
    @v_bearing      float = @p_bearing,
    @v_distance     float = ABS(ISNULL(@p_distance,0.0)),
    @v_end          varchar(5) = UPPER(SUBSTRING(ISNULL(@p_end,'START'),1,5)),
    @v_end_point    geometry,
    @v_start_point  geometry,
    @v_linestring   geometry;
  Begin
    IF ( @p_linestring is NULL )
      Return Null;

    -- Only support simple linestrings
    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','CircularString','CompoundCurve') )
      Return @p_linestring;

    IF ( @v_end NOT IN ('START','END') ) 
      Return @p_linestring;

    IF ( @v_distance = 0.0 ) 
      Return @p_linestring;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);
    -- Set coordinate dimensions flag for STPointAsText function
    SET @v_dimensions = 'XY' 
                        + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                        + case when @p_linestring.HasM=1 then 'M' else '' end;

    IF ( @v_bearing is null ) 
      Return [$(owner)].[STExtend] ( 
                @p_linestring,
                @p_distance,
                @v_end,
                0,
                @v_round_xy,
                @v_round_zm
             );

    -- Set local geometry so that we can update it.
    --
    IF ( @v_end = 'START' )
    BEGIN
      SET @v_start_point = @p_linestring.STStartPoint();
    END;
    ELSE
    BEGIN
      SET @v_start_point = @p_linestring.STEndPoint();
    END;

    -- LineString
    -- To Do: Handle Z and M
    -- To Do: CircularString/CompoundCurve
    --
    SET @v_end_point   = [$(cogoowner)].[STPointFromCOGO] ( 
                            @v_start_point,
                            @p_bearing,
                            @v_distance,
                            @v_round_xy
                         );

    IF ( @p_linestring.HasZ=1 OR @p_linestring.HasM=1 )
	BEGIN
	  SET @v_end_point = geometry::STGeomFromText(
                           'POINT (' 
                           +
                           [$(owner)].[STPointAsText] (
                               /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                               /* @p_X          */ @v_end_point.STX,
                               /* @p_Y          */ @v_end_point.STY,
                               /* @p_Z          */ @v_start_point.Z, /* TODO: Extrapolate by @v_start_point.Z + (distance ratio)? */
                               /* @p_M          */ @v_start_point.M, /* TODO: Extrapolate by @v_start_point.M + (distance ratio)? */
                               /* @p_round_x    */ @v_round_xy,
                               /* @p_round_y    */ @v_round_xy,
                               /* @p_round_z    */ @v_round_zm,
                               /* @p_round_m    */ @v_round_zm
                           )
                           +
                           ')',
                           @p_linestring.STSrid
                         );
    END;

    SET @v_linestring  = [$(owner)].[STInsertN] ( 
                            @p_linestring,
                            @v_end_point,
                            case when @v_end = 'START' then 1 else -1 /* End */ end,
                            @v_round_xy,
                            NULL
                         );
    Return @v_linestring;
  END;
END;
GO

