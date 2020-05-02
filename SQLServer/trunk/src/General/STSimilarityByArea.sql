SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STSimilarityByArea]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STSimilarityByArea];
  Print 'Dropped [$(owner)].[STSimilarityByArea] ....';
END;
GO

Print 'Creating [$(owner)].[STSimilarityByArea]....';
GO

CREATE FUNCTION [$(owner)].[STSimilarityByArea](
  @p_geometry1 geometry,
  @p_geometry2 geometry
)
returns float
As
Begin 
  Declare 
    @v_areaInt   float,
	@v_areaUnion float;

  IF ( @p_geometry1 is null 
    OR @p_geometry1.STIsValid() = 0
	OR @p_geometry1.STIsEmpty() = 1
	OR @p_geometry1.STGeometryType() not in ('Polygon','MultiPolygon') )
	return NULL;

  IF ( @p_geometry2 is null 
    OR @p_geometry2.STIsValid() = 0
	OR @p_geometry2.STIsEmpty() = 1
	OR @p_geometry2.STGeometryType() not in ('Polygon','MultiPolygon') )
	return NULL;
	
  SET @v_areaInt   = @p_geometry1.STIntersection(@p_geometry2).STArea();
  SET @v_areaUnion = @p_geometry1.STUnion(@p_geometry2).STArea();

  RETURN case when @v_areaUnion = 0.0 then 1.0 else @v_areaInt / @v_areaUnion end;
END;
GO

