USE [DEVDB]
GO

/****** Object:  UserDefinedFunction [dbo].[STSimilarityByArea]    Script Date: 20/04/2020 6:01:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE function [dbo].[STSimilarityByArea](
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

