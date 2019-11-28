SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STMakeEnvelope]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakeEnvelope];
  PRINT 'Dropped [$(owner)].[STMakeEnvelope] ...';
END;
GO

PRINT 'Creating [$(owner)].[STMakeEnvelope] ...';
GO

Create Function [$(owner)].[STMakeEnvelope] (
  @p_minx float,
  @p_miny float,
  @p_maxx float,
  @p_maxy float,
  @p_srid integer
)
Returns geometry 
As
/****f* CREATE/STMakeEnvelope (2008)
 *  NAME
 *    STMakeEnvelope -- Function that constructs a 5 point polygon from supplied ordinates.
 *  SYNOPSIS
 *    Function [$(owner)].[STMakeEnvelope] (
 *               @p_mbr_coords in varchar,
 *               @p_srid       in integer default null
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *  NOTES
 *    2D only.
 *  INPUTS
 *    @p_minx   (float) - Lower left x ordinate.
 *    @p_miny   (float) - Lower left y ordinate.
 *    @p_maxx   (float) - Upper left x ordinate.
 *    @p_maxy   (float) - Upper left x ordinate.
 *    @p_srid (integer) - geometry srid
 *  RESULT
 *    geometry (geometry) - Input coordinates converted to 5 point polygon.
 *  EXAMPLE
 *    USE GISDB
 *    GO
 *    SELECT [$(owner)].[STMakeEnvelope](0,0,1,1,null) as mbr;
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2019 - Original TSQL Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
 Declare
  @v_wkt varchar(1000);
 Begin
  IF ( @p_minx is null or
       @p_miny is null or
       @p_maxx is null or
       @p_maxy is null )
    Return NULL;
  SET @v_wkt = 'POLYGON((' + 
                         CAST(@p_minx as varchar(50)) + ' ' + CAST(@p_miny as varchar(50)) + ',' +
                         CAST(@p_maxx as varchar(50)) + ' ' + CAST(@p_miny as varchar(50)) + ',' +
                         CAST(@p_maxx as varchar(50)) + ' ' + CAST(@p_maxy as varchar(50)) + ',' +
                         CAST(@p_minx as varchar(50)) + ' ' + CAST(@p_maxy as varchar(50)) + ',' +
                         CAST(@p_minx as varchar(50)) + ' ' + CAST(@p_miny as varchar(50))
                + '))';
  RETURN geometry::STGeomFromText(@v_wkt,ISNULL(@p_srid,0));
 End;
End
GO

