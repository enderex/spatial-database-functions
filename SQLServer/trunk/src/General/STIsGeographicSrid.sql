SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STIsGeographicSrid]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STIsGeographicSrid];
  PRINT 'Dropped [$(owner)].[STIsGeographicSrid] ...';
END;
GO

PRINT 'Creating [$(owner)].[STIsGeographicSrid] ...';
GO

CREATE FUNCTION [$(owner)].[STIsGeographicSrid] 
( 
  @p_srid int 
)
Returns bit
/****f* TOOLS/STIsGeographicSrid (2012)
 *  NAME
 *    STIsGeographicSrid -- Checks @p_srid to see if exists in sys.spatial_reference_systems table (which holds geodetic SRIDS)
 *  SYNOPSIS
 *    Function STIsGeographicSrid (
 *               @p_srid int 
 *             )
 *     Returns bit 
 *  USAGE
 *    SELECT [$(owner)].[STIsGeographicSrid](4283) as isGeographicSrid
 *    GO
 *    isGeographicSrid
 *    ----------------
 *    1
 *  DESCRIPTION
 *    All geographic/geodetic SRIDs are stored in the sys.spatial_reference_systems table.
 *    This function checks to see if the supplied SRID is in that table. 
 *    If it is, 1 is returned otherwise 0.
 *  INPUTS
 *    @p_srid (int) - Srid value.
 *  RESULT
 *    Y/N     (bit) - 1 if True; 0 if False
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - June 2018 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
As
Begin
  Declare @v_is_geographic_srid int;
  If ( @p_srid is null )
    Return 0;
  select @v_is_geographic_srid = count(*) from [sys].[spatial_reference_systems] where spatial_reference_id = @p_srid;
  Return case when @v_is_geographic_srid = 0 then 0 else 1 end;
End;
GO

