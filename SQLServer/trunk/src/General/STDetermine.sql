SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STDetermine]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP  FUNCTION [$(owner)].[STDetermine];
  Print 'Dropped [$(owner)].[STDetermine] ...';
END;
GO

Print 'Creating [$(owner)].[STDetermine] ...';
GO

CREATE FUNCTION [$(owner)].[STDetermine]
(
  @p_geometry1 geometry,
  @p_geometry2 geometry
)
Returns varchar(500)
AS
/****f* INSPECT/STDetermine (2008)
 *  NAME
 *   STDetermine - Determines all possible spatial relations between two geometry instances.
 *  SYNOPSIS
 *    Function [$(owner)].[STDetermine]
 *             (
 *               @p_geometry1 geometry,
 *               @p_geometry2 geometry
 *             )
 *      Return varchar(500)
 *  DESCRIPTION
 *    Compares the first geometry against the second using all the instance comparison methods, 
 *    returning a comma separated string containing tokens representing each method: STContains -> CONTAINS.
 *    Methods and returned Strings are:
 *     STDisjoint   -> DISJOINT
 *     STEquals     -> EQUALS
 *     STContains   -> CONTAINS
 *     STCrosses    -> CROSSES
 *     STOverlaps   -> OVERLAPS
 *     STTouches    -> TOUCHES
 *     STIntersects -> INTERSECTS
 *    So if two polygons overlap each othre, a string containing "OVERLAPS" will be returned (see Example).
 *    Or is a point lies inside a polygon the "CONTAINS" relationship would be returned (see Example); 
 *    Two lines that meet at a start/end point will return "TOUCHES".
 *    Note that in all the cases above, "INTERSECTS" is always returned as a catch-all relationship: it always appears at the end of the returned string. 
 *    If two geometry objects are equal or disjoint a string containing only "EQUALS" or "DISJOINT" is returned.
 *  INPUTS
 *    @p_geometry1 (geometry) - Non-null geometry instance.
 *    @p_geometry2 (geometry) - Non-null geometry instance.
 *  RESULT
 *    relations found (varchar) - Comma separated string containing tokens representing each method: STContains -> CONTAINS.
 *  EXAMPLE
 *    Select [$(owner)].[STDetermine] ( 
 *             geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0),
 *             geometry::STGeomFromText('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',0)
 *           ) as relations;
 *    go
 *    relations
 *    -------------------
 *    OVERLAPS,INTERSECTS
 *
 *    Select [$(owner)].[STDetermine] ( 
 *             geometry::STGeomFromText('LINESTRING (100.0 0.0, 400.0 0.0)',0),
 *             geometry::STGeomFromText('LINESTRING (90.0 0.0, 100.0 0.0)',0)
 *     ) as relations;
 *    go
 *    relations
 *    -------------------
 *    TOUCHES,INTERSECTS
 *
 *    Select [$(owner)].[STDetermine] ( 
 *             geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0) ,
 *             geometry::STPointFromText('POINT (250 150)',0)
 *           ) as relations;
 *    go
 *    relations
 *    -------------------
 *    CONTAINS,INTERSECTS
 *
 *    Select [$(owner)].[STDetermine] ( 
 *             geometry::STPointFromText('POINT (250 150)',0),
 *             geometry::STPointFromText('POINT (250 150)',0)
 *           ) as relations;
 *    go
 *    relations
 *    -------------------
 *    EQUALS
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_relations varchar(500) = '';
  BEGIN
    IF ( @p_geometry1 is null OR @p_geometry2 is null ) Return NULL;
    SET @v_relations =                case when @p_geometry1.STDisjoint   (@p_geometry2) = 1 then 'DISJOINT'    else '' end;
    IF ( @v_relations <> '' ) Return @v_relations;
    SET @v_relations = @v_relations + case when @p_geometry1.STEquals     (@p_geometry2) = 1 then 'EQUALS'      else '' end;
    IF ( @v_relations <> '' ) Return @v_relations;
    SET @v_relations = @v_relations + case when @p_geometry1.STContains   (@p_geometry2) = 1 then ',CONTAINS'   else '' end;
    SET @v_relations = @v_relations + case when @p_geometry1.STCrosses    (@p_geometry2) = 1 then ',CROSSES'    else '' end;
    SET @v_relations = @v_relations + case when @p_geometry1.STOverlaps   (@p_geometry2) = 1 then ',OVERLAPS'   else '' end;
    SET @v_relations = @v_relations + case when @p_geometry1.STTouches    (@p_geometry2) = 1 then ',TOUCHES'    else '' end;
    SET @v_relations = @v_relations + case when @p_geometry1.STIntersects (@p_geometry2) = 1 then ',INTERSECTS' else '' end;
    Return case when CHARINDEX(',',@v_relations)=1 then SUBSTRING(@v_relations,2,LEN(@v_relations)) else @v_relations end;
  END;
END;
GO

Print 'Testing [$(owner)].[STDetermine] ...';
GO

Select [$(owner)].[STDetermine] ( 
         geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0),
         geometry::STGeomFromText('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',0)
       ) as relations;
go

Select [$(owner)].[STDetermine] ( 
         geometry::STGeomFromText('LINESTRING (100.0 0.0, 400.0 0.0)',0),
         geometry::STGeomFromText('LINESTRING (90.0 0.0, 100.0 0.0)',0)
       ) as relations;
GO

select [$(owner)].[STDetermine] ( 
         geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0) ,
         geometry::STPointFromText('POINT (250 150)',0)
     ) as relations;
GO

select [$(owner)].[STDetermine] ( 
       geometry::STPointFromText('POINT (250 150)',0),
       geometry::STPointFromText('POINT (250 150)',0)
     ) as relations;
GO

