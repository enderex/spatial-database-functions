USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STScale]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STScale];
  Print 'Dropped [$(owner)].[STScale] ....';
END;
GO

Print 'Creating [$(owner)].[STScale]....';
GO

CREATE FUNCTION [$(owner)].[STScale]
(
 @p_geometry  geometry,
 @p_xFactor   float,
 @p_yFactor   float,
 @p_zFactor   float,
 @p_mFactor   float,
 @p_round_xy  int = 3,
 @p_round_zm  int = 2

)
Returns geometry
As
/****f* AFFINE/STScale (2008)
  *  NAME
  *    STScale -- TSQL Function that moves a geometry object's ordinates using the supplied delta X, Y, Z and M.
  *  SYNOPSIS
  *    Function STScale (@p_geometry geometry,
  *                      @p_xFactor  float,
  *                      @p_yFactor  float,
  *                      @p_zFactor  float,
  *                      @p_mFactor  float,
  *                      @p_round_xy int = 3,
  *                      @p_round_zm int = 2 
  *                    )
  *     Returns geometry 
  *  USAGE
  *    -- XY
  *    SELECT [dbo].[STScale](
  *                    geometry::STGeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),
  *                    -5.0,
  *                     3.2,
  *                     NULL,
  *                     NULL,
  *                     3,
  *                     2
  *           ).AsTextZM() as scaledGeom;
  *
  *    scaledGeom
  *    LINESTRING (-0.5 0.64, -7 144.64)
  *
  *    -- XYM
  *    SELECT [dbo].[STScale](
  *                    geometry::STGeomFromText('LINESTRING(0.1 0.2 NULL 1.0,1.4 45.2 NULL 45.02)',0),
  *                     NULL,
  *                     NULL,
  *                     NULL,
  *                     1.5,
  *                     3,
  *                     2
  *            ).AsTextZM() as scaledGeom;
  *     
  *     scaledGeom
  *     LINESTRING (0.1 0.2 NULL 1.5, 1.4 45.2 NULL 67.53)
  *
  *    -- XYZM
  *    SELECT [dbo].[STScale](
  *                    geometry::STGeomFromText('LINESTRING(0.1 0.2 0.9 1.0,1.4 45.2 2.1 45.02)',0),
  *                     1.0,
  *                     1.0,
  *                     2.0,
  *                     1.5,
  *                     3,
  *                     2
  *            ).AsTextZM() as scaledGeom;
  *     
  *     scaledGeom
  *     LINESTRING (0.1 0.2 1.8 1.5, 1.4 45.2 4.2 67.53)
  *  DESCRIPTION
  *    Function that scales the supplied geometry's ordinates using the supplied scale factors.
  *    The computed ordinates of the new geometry are rounded to the appropriate decimal digits of precision.
  *  INPUTS
  *    @p_geometry (geometry) - supplied geometry of any type.
  *    @p_xFactor  (double)   - X ordinate scale factor.
  *    @p_yFactor  (double)   - Y ordinate scale factor.
  *    @p_zFactor  (double)   - Z ordinate scale factor.
  *    @p_mFactor  (double)   - M ordinate scale factor.
  *    @p_round_xy (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
  *    @p_round_zm (int)      - Decimal degrees of precision to which calculated XM ordinates are rounded.
  *  RESULT
  *    geometry -- Input geometry scaled by supplied ordinate factor values.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
  *  COPYRIGHT
  *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
Begin
  Declare
     @v_wkt           varchar(max) = '',
     @v_wkt_remainder varchar(max),
     @v_dimensions    varchar(4),
     @v_xFactor       Float = case when @p_xFactor is null then 1.0 else @p_xFactor end,
     @v_yFactor       Float = case when @p_yFactor is null then 1.0 else @p_yFactor end,
     @v_zFactor       Float = case when @p_zFactor is null then 1.0 else @p_zFactor end,
     @v_mFactor       Float = case when @p_mFactor is null then 1.0 else @p_mFactor end,
     @v_round_xy      int,
     @v_round_zm      int,
     @v_pos           int = 0,
     @v_x             Float = 0,
     @v_y             Float = 0,
     @v_z             Float = 0,
     @v_m             Float = 0,
     @v_point         geometry;
  Begin
    If ( @p_geometry is NULL ) 
      Return null;

    -- One of the scale factors must be not null
    If ( @p_xFactor IS NULL AND @p_yFactor IS NULL AND @p_zFactor IS NULL AND @p_mFactor IS NULL ) 
      Return @p_geometry;

    SET @v_round_xy   = ISNULL(@p_round_xy,3);
    SET @v_round_zm   = ISNULL(@p_round_zm,2);

    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                       + case when @p_geometry.HasZ=1 then 'Z' else '' end 
                       + case when @p_geometry.HasM=1 then 'M' else '' end;

    -- Shortcircuit for simplest case
    IF ( @p_geometry.STGeometryType() = 'Point' ) 
    Begin
      SET @v_x = @p_geometry.STX * @v_xFactor;
      SET @v_y = @p_geometry.STY * @v_yFactor;
      SET @v_z = @p_geometry.Z   * @v_zFactor;
      SET @v_m = @p_geometry.M   * @v_mFactor;
      SET @v_wkt = 'POINT(' 
                   +
                   [$(owner)].[STPointAsText] (
                          /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ 
                                              @v_dimensions,
                          /* @p_X          */ @v_x,
                          /* @p_Y          */ @v_Y,
                          /* @p_Z          */ @v_z,
                          /* @p_M          */ @v_M,
                          /* @p_round_x    */ @p_round_xy,
                          /* @p_round_y    */ @p_round_xy,
                          /* @p_round_z    */ @p_round_zm,
                          /* @p_round_m    */ @p_round_zm
                   )
                   + 
                   ')';
      Return geometry::STPointFromText(@v_wkt,@p_geometry.STSrid);
    END;

    SET @v_wkt_remainder = @p_geometry.AsTextZM();
    SET @v_wkt           = SUBSTRING(@v_wkt_remainder,1,CHARINDEX('(',@v_wkt_remainder));
    SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,  CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));

    WHILE ( LEN(@v_wkt_remainder) > 0 )
    BEGIN
       -- Is the start of v_wkt_remainder a coordinate?
       IF ( @v_wkt_remainder like '[-0-9]%' ) 
        BEGIN
         -- We have a coord
         -- Now get position of end of coordinate string
         SET @v_pos = case when CHARINDEX(',',@v_wkt_remainder) = 0
                           then CHARINDEX(')',@v_wkt_remainder)
                           when CHARINDEX(',',@v_wkt_remainder) <> 0 and CHARINDEX(',',@v_wkt_remainder) < CHARINDEX(')',@v_wkt_remainder)
                           then CHARINDEX(',',@v_wkt_remainder)
                           else CHARINDEX(')',@v_wkt_remainder)
                       end;
         -- Create a geometry point from WKT coordinate string
         SET @v_point = geometry::STPointFromText(
                          'POINT(' 
                          + 
                          SUBSTRING(@v_wkt_remainder,1,@v_pos-1)
                          + 
                          ')',
                          @p_geometry.STSrid);
         SET @v_x     = @v_point.STX * @v_xFactor;
         SET @v_y     = @v_point.STY * @v_yFactor;
         SET @v_z     = @v_point.Z   * @v_zFactor;
         SET @v_m     = @v_point.M   * @v_mFactor;
         -- Add to WKT
         SET @v_wkt   = @v_wkt 
                        + 
                        [$(owner)].[STPointAsText] (
                                /* @p_dimensions XY,XYZ,XYM,XYZM or NULL (XY) */ 
                                                    @v_dimensions,
                                /* @p_X          */ @v_x,
                                /* @p_Y          */ @v_y,
                                /* @p_Z          */ @v_Z,
                                /* @p_M          */ @v_M,
                                /* @p_round_x    */ @p_round_xy,
                                /* @p_round_y    */ @p_round_xy,
                                /* @p_round_z    */ @v_round_zm,
                                /* @p_round_m    */ @v_round_zm
                        );
         -- Now remove the old coord from v_wkt_remainder
         SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,@v_pos,LEN(@v_wkt_remainder));
       END
       ELSE
       BEGIN
         -- Move to next character
         SET @v_wkt           = @v_wkt 
                                + 
                                SUBSTRING(@v_wkt_remainder,1,1);
         SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,2,LEN(@v_wkt_remainder));
       END;
    END; -- Loop
    Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  End
End
Go

Print '*********************************';
Print 'Testing STScale .....';
GO

SELECT a.stype, a.geom.AsTextZM() as geomWKT
  FROM (SELECT 'Scaled2D' as stype, [$(owner)].[STScale](geometry::STGeomFromText('LINESTRING (1 2 3, 1 1 1)',0),0.5,0.75,default,default, 2,1) as geom
        UNION ALL
        SELECT 'Original' as stype, geometry::STGeomFromText('LINESTRING (1 2 3, 1 1 1)',0) as geom ) a
GO

SELECT a.stype, a.geom.AsTextZM() as geomWKT
  FROM (SELECT 'Scaled3D' as stype, [$(owner)].[STScale](geometry::STGeomFromText('LINESTRING (1 2 3, 1 1 1)',0), 0.5, 0.75, 0.8,null, 2,1) as geom
        UNION ALL
        SELECT 'Original' as stype, geometry::STGeomFromText('LINESTRING (1 2 3, 1 1 1)',0) as geom ) a
GO
  
SELECT a.stype, a.geom.AsTextZM() as geomWKT
  FROM (SELECT 'Original' as stype, geometry::STGeomFromText('POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))',0) as geom 
        UNION ALL
        SELECT 'Scaled2D' as stype, [$(owner)].[STScale](geometry::STGeomFromText('POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))',0), 2.0, 2.0, null,null, 2,1) as geom
        UNION ALL
        SELECT 'ScaledYOnly' as stype, [$(owner)].[STScale](geometry::STGeomFromText('POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))',0), null, 2.0, null,null, 2,1) as geom ) a
GO


