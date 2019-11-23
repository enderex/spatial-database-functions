USE $(usedbName)
GO

SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STUpdate]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STUpdate];
  PRINT 'Dropped [$(owner)].[STUpdate] ...';
END;
GO

PRINT 'Creating [$(owner)].[STUpdate] ...';
GO

CREATE FUNCTION [$(owner)].[STUpdate]
(
  @p_geometry    geometry,
  @p_original_pt geometry,
  @p_replace_pt  geometry,
  @p_round_xy    int = 3,
  @p_round_zm    int = 2
)
  RETURNS geometry
As
/****f* EDITOR/STUpdate (2012)
 *  NAME
 *    STUpdate -- Function that updates (replaces) all geometry points that are equal to the supplied point with the replacement point.
 *  SYNOPSIS
 *    Function STUpdate (
 *               @p_geometry      geometry,
 *               @p_point         geometry,
 *               @p_replace_point geometry,
 *               @p_round_xy      int = 3,
 *               @p_round_zm      int = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT STUpdate(
 *             STGeomFromText ('POLYGON(0 0,10 0,10 10,0 10,0 0)',0),
 *             STPointFromText('POINT(0 0)',0),
 *             STPointFromText('POINT(1 1)',0),
 *             1 
 *           ).AsTextZM() as updatedGeom;
 *    # updatedGeom
 *    'POLYGON(1 1,10 0,10 10,0 10,1 1)'
 *  DESCRIPTION
 *    Function that updates all coordinates that equal @p_point with the supplied @p_replace_point.
 *    The @p_round_xy value is used when comparing geometry point's XY ordinates to @p_point's.
 *    The updated coordinate's XY ordinates are rounded to @p_round_xy number of decimal digits of precision.
 *    The updated coordinate's ZM ordinates are rounded to @p_round_ZM number of decimal digits of precision.
 *  INPUTS
 *    @p_geometry      (geometry) - supplied geometry of any type.
 *    @p_point         (geometry) - Original coordinate to be replaced.
 *    @p_replace_point (geometry) - Replacement coordinate
 *    @p_round_xy      (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm      (int)      - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    geometry         (geometry) - Input geometry with one or more coordinate replaced.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
     @v_wkt         varchar(max) = '',
     @v_original    varchar(max) = '',
     @v_replacement varchar(max) = '',
     @v_cDim        int = 2,
     @v_round_xy    int = ISNULL(@p_round_xy,3),
     @v_round_zm    int = ISNULL(@p_round_zm,2),
     @v_geometry    geometry
  Begin
    If ( @p_geometry is NULL ) 
    BEGIN
      RETURN NULL;
    END;
    IF (   @p_original_pt is null 
        OR @p_replace_pt is null
        OR @p_original_pt.STGeometryType() <> 'Point' 
        OR  @p_replace_pt.STGeometryType() <> 'Point' )
    BEGIN
      RETURN @p_geometry;
    END;
    SET @v_cDim = [$(owner)].[STCoordDim](@p_geometry);
    -- Format points to tolerance
    SET @v_original = CAST(ROUND(@p_original_pt.STPointN(1).STX,@v_round_xy) as Varchar) + 
                      ' ' + 
                      CAST(ROUND(@p_original_pt.STPointN(1).STY,@v_round_xy) as Varchar) +
                      case when @p_original_pt.STPointN(1).Z is null 
                           then case when @v_cDim > 2 then ' NULL' else '' end
                           else ' ' + CAST(round(@p_original_pt.STPointN(1).Z,@v_round_zm) as varchar)
                       end + 
                      case when @p_original_pt.STPointN(1).M is null 
                           then case when @v_cDim > 3 then ' NULL' else '' end
                           else ' ' + CAST(round(@p_original_pt.STPointN(1).M,@v_round_zm) as varchar)
                       end;
    SET @v_replacement = CAST(ROUND(@p_replace_pt.STPointN(1).STX,@v_round_xy) as Varchar) + 
                         ' ' + 
                         CAST(ROUND(@p_replace_pt.STPointN(1).STY,@v_round_xy) as Varchar) +
                         case when @p_replace_pt.STPointN(1).Z is null 
                              then case when @v_cDim > 2 then ' NULL' else '' end
                              else ' ' + CAST(round(@p_replace_pt.STPointN(1).Z,@v_round_zm) as varchar)
                          end + 
                         case when @p_replace_pt.STPointN(1).M is null 
                              then case when @v_cDim > 3 then ' NULL' else '' end
                              else ' ' + CAST(round(@p_replace_pt.STPointN(1).M,@v_round_zm) as varchar)
                          end;
    SET QUOTED_IDENTIFIER ON;
    -- Process turning tokens that are coordinates into strings to required tolerance.
    WITH COORD_CTE AS (
      select id, 
             Case when @v_original = (CAST(ROUND(Coord.STPointN(1).STX,@v_round_xy) as Varchar) + 
                                      ' ' + 
                                      CAST(ROUND(Coord.STPointN(1).STY,@v_round_xy) as Varchar) +
                                      case when Coord.STPointN(1).Z is null 
                                           then case when @v_cDim > 2 then ' NULL' else '' end
                                           else ' ' + CAST(round(Coord.STPointN(1).Z,@v_round_zm) as varchar)
                                       end + 
                                      case when Coord.STPointN(1).M is null 
                                           then case when @v_cDim > 3 then ' NULL' else '' end
                                           else ' ' + CAST(round(Coord.STPointN(1).M,@v_round_zm) as varchar)
                                       end
                                      )
                  then @v_replacement
                  else token
              end as token, 
             separator
        from (select id, token, separator, 
                     case when token like '%[0-9]%'
                          then geometry::STGeomFromText('POINT('+token+')',0)
                          else null
                      end as Coord
                from (SELECT f.id, LTRIM(RTRIM(ISNULL(f.token,''))) as token, separator
                        FROM [$(owner)].[TOKENIZER](@p_geometry.AsTextZM(),',()') as f
                     ) as f
             ) as g
    )
    SELECT @v_wkt = a.WKT
      FROM (SELECT ((SELECT a.token + a.separator
                       FROM COORD_CTE a
                      ORDER BY a.id
                        FOR XML PATH(''), TYPE, ROOT).value('root[1]','varchar(max)')
                    ) AS WKT
             ) as a;
   SET @v_geometry = geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  END;
  RETURN @v_geometry;
End
GO

PRINT 'Testing [$(owner)].[STUpdate] ...';
GO

select [$(owner)].[STUpdate](geometry::STGeomFromText('POINT(0 0 1 1)',0),
                             geometry::STGeomFromText('POINT(0 0 1 1)',0),
                             geometry::STGeomFromText('POINT(1 1 1 1)',0),2,1).AsTextZM() as WKT
GO
select [$(owner)].[STUpdate](geometry::STGeomFromText('MULTIPOINT((1 1 1 1),(2 2 2 2),(3 3 3 3))',0),
                             geometry::STGeomFromText('POINT(2 2 2 2)',0),
                             geometry::STGeomFromText('POINT(2.1 2.1 2 2)',0),2,1).AsTextZM() as WKT
GO
Select [$(owner)].[STUpdate](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),
                             geometry::STGeomFromText('POINT(3 3)',0), 
                             geometry::STGeomFromText('POINT(2.1 2.5)',0),2,1).AsTextZM() as WKT
GO
select [$(owner)].[STUpdate](geometry::STGeomFromText('MULTILINESTRING((1 1,2 2,3 3),(4 4,5 5,6 6))',0),
                             geometry::STGeomFromText('POINT(3 3)',0),
                             geometry::STGeomFromText('POINT(3.1 3.3)',0),2,1).AsTextZM() as WKT
GO

select [$(owner)].[STUpdate](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872))',0),
                              geometry::STGeomFromText('POINT(9.962 0.872)',0),
                              geometry::STGeomFromText('POINT(9.9 0.9)',0),2,1).AsTextZM() as WKT
GO

-- 'Polygon - First and lat point of ring update.
select [$(owner)].[STUpdate](geometry::STGeomFromText('POLYGON((1 1,10 1,10 10,1 10,1 1),(2 2,9 2,9 9,2 9,2 2))',0),
                             geometry::STGeomFromText('POINT(1 1)',0),
                             geometry::STGeomFromText('POINT(1.1 1.1)',0),2,1).AsTextZM() as WKT
GO
select [$(owner)].[STUpdate](geometry::STGeomFromText('POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0))',28355),
                             geometry::STGeomFromText('POINT(326000.0 5455000.0)',28355),
                             geometry::STGeomFromText('POINT(326100.0 5455100.0)',28355),2,1).AsTextZM() as WKT
GO
select [$(owner)].[STUpdate](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0),
                             geometry::STGeomFromText('POINT(3 4 5)',0),
                             geometry::STGeomFromText('POINT(3.1 4.1 5.1)',0),2,1).AsTextZM() as WKT
GO


