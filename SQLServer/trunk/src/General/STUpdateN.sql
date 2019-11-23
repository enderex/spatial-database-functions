USE $(usedbname)
GO

SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT *
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STUpdateN]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STUpdateN];
  Print 'Dropped [$(owner)].[STUpdateN] ...';
END;
GO

Print 'Creating [$(owner)].[STUpdateN] ...';
GO

CREATE FUNCTION [$(owner)].[STUpdateN] 
(
  @p_geometry   geometry,
  @p_replace_pt geometry,
  @p_position   int,
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
returns geometry
as
/****f* EDITOR/STUpdateN (2012)
 *  NAME
 *    STUpdateN -- Function which updates the coordinate at position @p_position in the supplied geometry.
 *  SYNOPSIS
 *    Function STUpdateN (
 *               @p_geometry   geometry,
 *               @p_replace_pt float,
 *               @p_position   int,
 *               @p_round_xy   int = 3,
 *               @p_round_zm   int = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT STUpdateN(
 *             STGeomFromText ('LINESTRING(0 0,2 2)',0),
 *             STPointFromText('POINT(1 1)',0),
 *             2,
 *             2, 1 ).STAsText() as updatedGeom;
 *    # updatedGeom
 *    'LINESTRING(0 0,1 1)'
 *  DESCRIPTION
 *    Function that updates coordinate identified by @p_position with the new point (@p_replace_point) in the supplied geometry.
 *    @p_position Values:
 *      1. null -> defaults to 1;
 *      2. -1   -> maximum number of points ie STNumPoints(p_geometry) 
 *      3. Greater than STNumPoints(p_geometry) -> maximum number of points ie STNumPoints(p_geometry)
 *    The updated coordinate's ordinates are rounded to @p_round_xy number of decimal digits of precision.
 *  INPUTS
 *    @p_geometry      (geometry) - supplied geometry of any type.
 *    @p_replace_point (geoemtry) - Replacement coordinate
 *    @p_position      (int)      - Coordinate position in @p_geometry: between 1 and STNumPoints.
 *    @p_round_xy      (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm      (int)      - Decimal degrees of precision to which calculated zm ordinates are rounded.
 *  RESULT
 *    updated geom     (geometry) - Input geometry with coordinate replaced.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType   varchar(100),
    @v_wkt            varchar(max) = '',
    @v_replace_pt_wkt varchar(max) = '',
    @v_dimensions     varchar(4),
    @v_round_xy       int,
    @v_round_zm       int,
    @v_position       int,
    @v_geometry       geometry;
  Begin
    If ( @p_geometry is NULL ) 
      RETURN NULL;

    IF ( @p_Position is null )
      Return @p_geometry;

    IF (   @p_replace_pt is null
        OR @p_replace_pt.STGeometryType() <> 'Point' )
      RETURN @p_geometry;

    SET @v_position = CASE WHEN @p_position = -1 
                             OR @p_position > @p_geometry.STNumPoints() 
                           THEN @p_geometry.STNumPoints() 
                           WHEN @p_position = 0  
                           THEN 1
                           ELSE @p_position
                       END;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    -- Set flag for STPointFromText
    -- @p_dimensions => XY, XYZ, XYM, XYZM or NULL (XY) 
    SET @v_dimensions = 'XY' 
                       + case when @p_geometry.HasZ=1 then 'Z' else '' end 
                       + case when @p_geometry.HasM=1 then 'M' else '' end;

    -- Format replacement point to tolerance
    SET @v_replace_pt_wkt = [$(owner)].[STPointAsText] (
                            /* @p_dimensions */ @v_dimensions,
                            /* @p_X          */ @p_replace_pt.STX,
                            /* @p_Y          */ @p_replace_pt.STY,
                            /* @p_Z          */ @p_replace_pt.Z,
                            /* @p_M          */ @p_replace_pt.M,
                            /* @p_round_x    */ @v_round_xy,
                            /* @p_round_y    */ @v_round_xy,
                            /* @p_round_z    */ @v_round_zm,
                            /* @p_round_m    */ @v_round_zm
                          )

    SET QUOTED_IDENTIFIER ON;
    -- Process turning tokens that are coordinates into strings to required tolerance.
    WITH COORD_CTE AS (
      select g.id, 
             case when g.TokType = 'COORD' and g.CoordId = @v_position
                  then @v_replace_pt_wkt
                  else token
              end as token,
             g.separator
        from (select f.id, f.token, f.separator, 
                     (case when f.token like '%[0-9]%' then 'COORD' else 'TOKEN' end) as tokType,
                     rank() over (partition by (case when f.token like '%[0-9]%' then 'COORD' else 'TOKEN' end) order by f.id) as coordid
               from (SELECT f.id, LTRIM(RTRIM(ISNULL(f.token,''))) as token, f.separator
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

Print 'Testing [$(owner)].[STUpdateN] ...';
GO

select [$(owner)].[STUpdateN](geometry::STGeomFromText('POINT(0 0 1 1)',0),
                              geometry::STGeomFromText('POINT(1 1 1 1)',0),
                              1,
                              0,1).AsTextZM() as WKT
GO
select [$(owner)].[STUpdateN](geometry::STGeomFromText('MULTIPOINT((1 1 1 1),(2 2 2 2),(3 3 3 3))',0),
                              geometry::STGeomFromText('POINT(2.1 2.1 2 2)',0),
                              2,
                              1,1).AsTextZM() as WKT
GO
Select [$(owner)].[STUpdateN](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),
                              geometry::STGeomFromText('POINT(2.1 2.5)',0),
                              3, 
                              1,1).AsTextZM() as WKT
GO
select [$(owner)].[STUpdateN](geometry::STGeomFromText('MULTILINESTRING((1 1,2 2,3 3),(4 4,5 5,6 6))',0),
                              geometry::STGeomFromText('POINT(3.1 3.3)',0),
                              3,
                              1,1).AsTextZM() as WKT
GO
select [$(owner)].[STUpdateN](geometry::STGeomFromText('POLYGON((1 1,10 1,10 10,1 10,1 1),(2 2,9 2,9 9,2 9,2 2))',0),
                              geometry::STGeomFromText('POINT(9.1 2.1)',0),
                              7,
                              1,1).AsTextZM() as WKT
GO
select [$(owner)].[STUpdateN](geometry::STGeomFromText('POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0))',28355),
                              geometry::STGeomFromText('POINT(326100.0 5455100.0)',28355),
                              2,
                              1,1).AsTextZM() as WKT
GO
select [$(owner)].[STUpdateN](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0),
                              geometry::STGeomFromText('POINT(3.1 4.1 5.1)',0),
                              3,
                              1,1).AsTextZM() as WKT
GO


