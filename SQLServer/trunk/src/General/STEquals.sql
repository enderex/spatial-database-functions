SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STEquals]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STEquals];
  PRINT 'Dropped [$(owner)].[STEquals]';
END;
GO

Print 'Creating [$(owner)].[STEquals] ...';
GO

CREATE FUNCTION [$(owner)].[STEquals]
(
  @p_point1   geometry,
  @p_point2   geometry,
  @p_round_xy int   = 3,
  @p_round_z  int   = 2,
  @p_round_m  int   = 2
)
returns bit
as
/****f* INSPECT/STEquals (2012)
 *  NAME
 *    STEquals -- Checks if all XYZM ordinates of two points are equal.
 *  SYNOPSIS 
 *    Function [$(owner)].[STEquals] (
 *               @p_point1   geometry,
 *               @p_point2   geometry,
 *               @p_round_xy int   = 3,
 *               @p_round_z  int   = 2,
 *               @p_round_m  int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Standqard STIsEquals() function only processes XY ordinates of a point.
 *    This function checks XY but also Z and M.
 *    Decimal digits of precision are used in the comparison.
 *    The input geometry objects must conform to the following:
 *      1. Both must be of geometry type point
 *      2. Both must have the same SRID
 *      3. Both must have the same Coordinate Dimension ie XYZ=XYZ, XYM=XYM or XYZM=XYZM. 
 *    It is up to the caller to ensure these conditions are met.
 *  ARGUMENTS
 *    @p_point1   (geometry) - Point geometry possibly with elevation (Z) and measures (M).
 *    @p_point2   (geometry) - Point geometry possibly with elevation (Z) and measures (M).
 *    @p_round_xy      (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_z       (int) - Decimal degrees of precision to which Z ordinates are compared.
 *    @p_round_m       (int) - Decimal degrees of precision to which M ordinates are compared.
 *  RESULT
 *    1/0              (bit) - True is 1 and False is 0
 *  NOTES
 *    Supports Linestrings with CircularString elements.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_round_xy int = ISNULL(@p_round_xy,3),
    @v_round_z  int = ISNULL(@p_round_z,2),
    @v_round_m  int = ISNULL(@p_round_m,2);
  BEGIN
    IF ( @p_point1 is     null and @p_point2 is     null )
      Return 1;
    IF ( @p_point1 is not null and @p_point2 is     null )
      Return 0;
    IF ( @p_point1 is     null and @p_point2 is not null )
      Return 0;
    IF ( @p_point1.STSrid <> @p_point2.STSrid )
      Return 0;
    IF ( ( @p_point1.HasZ <> @p_point2.HasZ ) 
      or ( @p_point1.HasM <> @p_point2.HasM ) )
       Return 0;
    IF (                       ROUND(@p_point1.STX,@v_round_xy) = ROUND(@p_point2.STX,@v_round_xy)
     AND                       ROUND(@p_point1.STY,@v_round_xy) = ROUND(@p_point2.STY,@v_round_xy)
     AND (@p_point1.HasZ=0 OR (ROUND(@p_point1.Z,  @v_round_Z)  = ROUND(@p_point2.Z,  @v_round_z)))
     AND (@p_point1.HasM=0 OR (ROUND(@p_point1.M,  @v_round_m)  = ROUND(@p_point2.M,  @v_round_m))) )
       Return 1;
    Return 0;
  END;
End;
GO

select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 0 1)',0),
                        geometry::STGeomFromText('POINT(-4 -4 0 1)',1),
                        3,2,2);
GO
select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 0 1)',0),
                        geometry::STGeomFromText('POINT(-4 -4 0 1)',0),
                        3,2,2);
GO
select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 NULL 1)',0),
                        geometry::STGeomFromText('POINT(-4 -4 NULL 1)',0),
                        3,2,2);
GO
select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 NULL 1.1236)',0),
                        geometry::STGeomFromText('POINT(-4 -4 NULL 1.124)',0),
                        3,2,2);
GO
select [$(owner)].[STEquals](geometry::STGeomFromText('POINT(-4 -4 NULL 1.126)',0),
                        geometry::STGeomFromText('POINT(-4 -4 NULL 1.124)',0),
                        3,2,2);
GO

