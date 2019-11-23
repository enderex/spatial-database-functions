USE $(usedbname)
GO

SET ANSI_NULLS ON;
SET ARITHABORT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STIsCompound]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STIsCompound];
  PRINT 'Dropped [$(owner)].[STIsCompound] ...';
END;
GO

PRINT 'Creating [$(owner)].[STIsCompound] ...';
GO

CREATE FUNCTION [$(owner)].[STIsCompound]
(
  @p_geometry geometry
)
Returns Bit
As
/****f* EDITOR/STIsCompound (2012)
 *  NAME
 *    STIsCompound -- Tests if supplied geometry has circularString elements.
 *  SYNOPSIS
 *    Function STIsCompound (
 *               @p_geometry geometry 
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].[STIsCompound](geometry::STGeomFromText('
 *     CURVEPOLYGON(
 *       COMPOUNDCURVE(
 *            CIRCULARSTRING(0 5,5 0,10 5,5 10,0 5)
 *       )
 *     )',0)) as isCompound
 *    GO
 *    isCompound 
 *    1
 *  DESCRIPTION
 *    Function that checks if the supplied geometry is described by CircularString elements.
 *  NOTES
 *    While will run in SQL Server 2008 (always 0), is aimed at 2012 onwards.
 *  INPUTS
 *    @p_geometry (geometry) - Any geometry object.
 *  RESULT
 *    true/false  (bit)      - 1 (True) or 0 (False)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2012 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_wkt varchar(max);
  Begin
    SET @v_wkt = @p_geometry.STAsText();
    IF ( CHARINDEX ( 'CIRC',  @v_wkt, 1) > 0 
      OR CHARINDEX ( 'CURVE', @v_wkt, 1) > 0 )
    BEGIN
      Return 1;
    END;
    Return 0;
  End;
End
Go

PRINT 'Testing [$(owner)].[STIsCompound] ...';
GO

SELECT [$(owner)].[STIsCompound](GEOMETRY::STGeomFromText('
  CURVEPOLYGON(
    COMPOUNDCURVE(
         CIRCULARSTRING(0 5,5 0,10 5,5 10,0 5)
    )
  )
',0))
GO


