SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STTo2D]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STTo2D];
  Print 'Dropped [$(owner)].[STTo2D] ...';
END;
GO

Print 'Creating [$(owner)].[STTo2D] ...';
GO

CREATE FUNCTION [$(owner)].[STTo2D]
(
  @p_geometry geometry
)
  RETURNS geometry
As
/****m* EDITOR/STTo2D (2012)
 *  NAME
 *    STTo2D -- Function that removes any Z or M ordinates from the @p_geometry
 *  SYNOPSIS
 *    Function [$(owner)].[STTo2D] (
 *               @p_geometry geometry
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].[STTo2D](
 *             STGeomFromText ('POLYGON(0 0,10 0,10 10,0 10,0 0)',0)
 *           ).AsTextZM() as 2DGeom;
 *    # 2DGeom
 *    'POLYGON(1 1,10 0,10 10,0 10,1 1)'
 *  DESCRIPTION
 *    Function that removes all Z and M ordinates from the input @p_geometry.
 *  INPUTS
 *    @p_geometry (geometry) - supplied geometry of any type.
 *  RESULT
 *    geometry    (geometry) - 2D version of input geometry
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2019 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2012-2019 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *    Creative Commons Attribution-Share Alike 2.5 Australia License.
 *    http://creativecommons.org/licenses/by-sa/2.5/au/
******/
Begin
  Declare
     @v_wkt      varchar(max) = '',
     @v_geometry geometry
  Begin
    If ( @p_geometry is NULL ) 
    BEGIN
      RETURN NULL;
    END;

    IF ( [$(owner)].[STCoordDim](@p_geometry) = 2 )
      RETURN @p_geometry;

    IF ( @p_geometry.STGeometryType() = 'Point' )
     RETURN geometry::Point(@p_geometry.STX,@p_geometry.STY,@p_geometry.STSrid);

    SET QUOTED_IDENTIFIER ON;
    -- Process turning tokens that are coordinates into strings 
    WITH tokens AS (
      select f.id, 
             LTRIM(RTRIM(ISNULL(f.token,''))) as token, 
             f.separator
        from [$(owner)].[TOKENIZER](@p_geometry.AsTextZM(),',()') as f
    )
    select @v_wkt = 
           STRING_AGG ( 
              case when f.token like '%[0-9]%'
                   then substring( f.token,1,charindex(' ', f.token,charindex(' ', f.token)+1)-1)
                   else f.token
               end 
              + 
              f.separator, '' 
           ) WITHIN GROUP (ORDER BY f.id ASC)
      from tokens as f;

   SET @v_geometry = geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  END;
  RETURN @v_geometry;
End;
GO

