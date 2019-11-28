SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STCoordDim]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STCoordDim];
  Print 'Dropped [$(owner)].[STCoordDim] ...';
END;
GO

Print 'Creating [$(owner)].[STCoordDim] ...';
GO

CREATE FUNCTION [$(owner)].[STCoordDim]
(
  @p_point geometry
)
Returns int
As
/****f* INSPECT/STCoordDim (2012)
 *  NAME
 *    STCoordDim -- Function that returns the coordinate dimension of a  geometry point.
 *  SYNOPSIS
 *    Function STCoordDim (
 *               @p_point geometry,
 *             )
 *     Returns int 
 *  USAGE
 *    SELECT STCoordDim (
 *             STPointFromText('POINT(0 0)',0)
 *           ) as coordDim;
 *    # coordDim
 *    2
 *  DESCRIPTION
 *    This function returns the coordinate dimension of a geometry point.
 *    If only XY ordinates, 2 is returned.
 *    If only XYZ or XYM ordinates, 3 is returned.
 *    If XYZM ordinates, 4 is returned.
 *  NOTES
 *    Uses HasZ and HasM extended methods to determine whether an ordinate exists.
 *  INPUTS
 *    @p_point (geometry) - Supplied point geometry.
 *  RESULT
 *    dimensionality (int) - 2,3 or 4.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_cDim integer;
  Begin
    IF (@p_point is null) 
    Begin
      Return null;
    End;
    SET @v_cDim  = 2;
    IF ( @p_point.HasZ = 1 )
    Begin
      SET @v_cDim = @v_cDim + 1;
    End;
    IF ( @p_point.HasM = 1 )
    Begin
      SET @v_cDim = 4;
    End;
    Return @v_cDim;
  End;
End;
GO

