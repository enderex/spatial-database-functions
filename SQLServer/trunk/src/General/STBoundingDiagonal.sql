USE $(usedbname)
GO

IF EXISTS (
  SELECT * 
    FROM sysobjects 
   WHERE id = object_id(N'[$(owner)].[STBoundingDiagonal]') 
     AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STBoundingDiagonal];
  PRINT 'Dropped [$(owner)].[STBoundingDiagonal] ...';
END;
GO

/* ================================================== */

CREATE FUNCTION [$(owner)].[STBoundingDiagonal]
(
  @p_geom     geometry,
  @p_round_xy int = 3,
  @p_round_zm int = 2
)
Returns geometry 
AS
/****f* MBR/STBoundingDiagonal (2008)
 *  NAME
 *    STBoundingDiagonal -- Returns the diagonal of the supplied geometry's bounding box as a linestring.
 *  SYNOPSIS
 *    Function [dbo].[STBoundingDiagonal] (
 *                @p_geom     geometry,
 *                @p_round_xy int = 3,
 *                @p_round_zm int = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    This function creates a linestring diagonal for the input geometry.
 *  NOTES
 *    Does not support Points
 *  INPUTS
 *    @p_geom   (geometry) - Must not be a Point geometry.
 *    @p_round_xy    (int) - Rounding factor for XY ordinates.
 *    @p_round_zm    (int) - Rounding factor for ZM ordinates.
 *  RESULT
 *    linstring (geometry) - Result is diagonal of envelope around input geometry.
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('POLYGON ((0 0,100 0,100 10,0 10,0 0))',0) as geom
 *    )
 *    select [$(owner)].[STBoundingDiagonal] (b.geom,3,2).STAsText() as bLine
 *      from data as b;
 *
 *    bLine
 *    LINESTRING (0 0, 100 10)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Oct 2019 - Original coding.
 *  COPYRIGHT
 *    (c) 2012-2019 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *    Creative Commons Attribution-Share Alike 2.5 Australia License.
 *    http://creativecommons.org/licenses/by-sa/2.5/au/
******/
BEGIN
  DECLARE
    @v_GeometryType  varchar(100),
    @v_dimensions    varchar(4),
    @v_round_xy      int,
    @v_round_zm      int,
    @v_bounding_line geometry,
    @v_mbr           geometry;
  Begin
    If ( @p_geom is null )
      Return @p_geom;

    SET @v_GeometryType = @p_geom.STGeometryType();
    -- MultiLineString Supported by alternate processing.
    IF ( @v_GeometryType = 'Point' )
      Return @p_geom;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                       + case when @p_geom.HasZ=1 then 'Z' else '' end 
                       + case when @p_geom.HasM=1 then 'M' else '' end;
           
    SET @v_mbr = @p_geom.STEnvelope();

    SET @v_bounding_line = [$(owner)].[STMakeLine](
                              @v_mbr.STPointN(1),
                              @v_mbr.STPointN(3),
                              @v_round_xy,
                              @v_round_zm
                           );

    Return @v_bounding_line;
  End;
End;
GO

with data as (
  select geometry::STGeomFromText('POLYGON ((0 0,100 0,100 10,0 10,0 0))',0) as geom
)
select [$(owner)].[STBoundingDiagonal] (b.geom,3,2).STAsText() as bLine
  from data as b;
GO

QUIT;
GO
