USE [DEVDB]
GO

/****** Object:  UserDefinedFunction [dbo].[STDetermine]    Script Date: 20/04/2020 6:01:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[STDetermine]
(
  @p_geometry1                 geometry,
  @p_geometry2                 geometry,
  @p_equals_similarity_measure float = 1
)
Returns varchar(500)
AS
/****m* PROCESSING/STDetermine (2012)
 *  NAME
 *   STDetermine - Determines all possible spatial relations between two geometry instances.
 *  SYNOPSIS
 *    Function STDetermine
 *               @p_geometry1                 geometry,
 *               @p_geometry2                 geometry,
 *               @p_equals_similarity_measure float = 1
 *             )
 *      Return varchar(500)
 *  DESCRIPTION
 *    Compares the first geometry against the second using all the instance comparison methods:
 *    Returns comma separated string containing tokens representing each method: STContains -> CONTAINS.
 *    If p_equals_similarity_measure is <> 1 then its value determines the amount of difference allowed
 *    before two polygons are considered to be equal.
 *  INPUTS
 *    @p_geometry1                 (geometry) - Non-null geometry instance.
 *    @p_geometry2                 (geometry) - Non-null geometry instance.
 *    @p_equals_similarity_measure (float)    - Area Similarity measure = 1
 *  RESULT
 *    Relation  found (varchar) - If two simple geometries, a single string is returned with a textual description of the relationship.
 *    Relations found (varchar) - If first is GeometryCollection, all geometries in the collection are compared to second geometry: a comma separated string containing tokens representing each relationship is returned.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - March 2020 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2020 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_i             integer,
	@v_similarity    float = ISNULL(@p_equals_similarity_measure,1.0),
    @v_intersections varchar(max),
    @v_geom_i        geometry;

  IF ( @p_geometry1 is null OR @p_geometry2 is null ) RETURN NULL;

  --- Not yet
  IF ( @p_geometry2.STGeometryType() = 'GeometryCollection' ) RETURN NULL;

  IF ( @p_geometry1.STGeometryType() <> 'GeometryCollection' )
  BEGIN
    IF ( @p_geometry1.STDisjoint  (@p_geometry2) = 1 ) RETURN 'DISJOINT';
    IF ( @p_geometry1.STEquals    (@p_geometry2) = 1 
         OR
         (@p_geometry1.STGeometryType() = 'Polygon' 
          AND 
          @p_geometry2.STGeometryType() = 'Polygon'
          AND 
          [dbo].[STSimilarityByArea](@p_geometry1,@p_geometry2) >= @v_similarity 
         ) 
       ) 
      RETURN 'EQUALS';
    IF ( @p_geometry1.STTouches   (@p_geometry2) = 1 ) RETURN 'TOUCHES';
    IF ( @p_geometry1.STContains  (@p_geometry2) = 1 ) RETURN 'CONTAINS';
    IF ( @p_geometry1.STWithin    (@p_geometry2) = 1 ) RETURN 'WITHIN';
    IF ( @p_geometry1.STOverlaps  (@p_geometry2) = 1 ) RETURN 'OVERLAPS';
    IF ( @p_geometry1.STCrosses   (@p_geometry2) = 1 ) RETURN 'CROSSES';
  END;

  IF ( @p_geometry1.STGeometryType() = 'GeometryCollection' )
  BEGIN
    SET @v_intersections = '';
    SET @v_i = 1;
    WHILE ( @v_i <= @p_geometry1.STNumGeometries() )
    BEGIN
      SET @v_geom_i = @p_geometry1.STGeometryN(@v_i);
      IF ( @v_geom_i.STDisjoint  (@p_geometry2) = 1 ) 
        SET @v_intersections = case when CHARINDEX('DISJOINT',@v_intersections) <> 0 then @v_intersections else @v_intersections + ',DISJOINT' end;
      IF ( @v_geom_i.STEquals    (@p_geometry2) = 1 
           OR
           (@v_geom_i.STGeometryType() = 'Polygon' 
            AND 
            @v_geom_i.STGeometryType() = 'Polygon'
            AND 
            [dbo].[STSimilarityByArea](@v_geom_i,@p_geometry2) >= @v_similarity 
           ) 
         )
        SET @v_intersections = case when CHARINDEX('EQUALS',@v_intersections) <> 0 then @v_intersections else @v_intersections + ',EQUALS' end;
      IF ( @v_geom_i.STTouches   (@p_geometry2) = 1 ) 
        SET @v_intersections = case when CHARINDEX('TOUCHES',@v_intersections) <> 0 then @v_intersections else @v_intersections + ',TOUCHES' end;
      IF ( @v_geom_i.STContains  (@p_geometry2) = 1 ) 
        SET @v_intersections = case when CHARINDEX('CONTAINS',@v_intersections) <> 0 then @v_intersections else @v_intersections + ',CONTAINS' end;
      IF ( @v_geom_i.STWithin    (@p_geometry2) = 1 ) 
        SET @v_intersections = case when CHARINDEX('WITHIN',@v_intersections) <> 0 then @v_intersections else @v_intersections + ',WITHIN' end;
      IF ( @v_geom_i.STOverlaps  (@p_geometry2) = 1 ) 
        SET @v_intersections = case when CHARINDEX('OVERLAPS',@v_intersections) <> 0 then @v_intersections else @v_intersections + ',OVERLAPS' end;
      IF ( @v_geom_i.STCrosses   (@p_geometry2) = 1 ) 
        SET @v_intersections = case when CHARINDEX('CROSSES',@v_intersections) <> 0 then @v_intersections else @v_intersections + ',CROSSES' end;
      SET @v_i += 1;
    END;
    SET @v_intersections = SUBSTRING(@v_intersections,2,LEN(@v_intersections));
    RETURN @v_intersections;
  END;
  RETURN case when @p_geometry1.STIntersects(@p_geometry2) = 1 then 'INTERSECTS' else 'UNKNOWN' end;
END
GO

