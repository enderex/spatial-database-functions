SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

DROP FUNCTION IF EXISTS [$(owner)].[STAverage]
GO

CREATE FUNCTION [$(owner)].[STAverage](
  @p_first_point  geometry,
  @p_second_point geometry
)
RETURNS geometry
AS
  /****f* GEOPROCESSING/ST_Average
  *  NAME
  *    ST_Average -- Averages ordinates of 2 Points 
  *  SYNOPSIS
  *    CREATE FUNCTION dbo.ST_Average(
  *        @p_first_point  geometry,
  *        @p_second_point geometry
  *    )
  *    RETURNS boolean 
  *  ARGUMENTS
  *    @p_first_point  (geometry) -- point 
  *    @p_second_point (geometry) -- point
  *  RESULT
  *    point (geometry - Average of two points
  *  DESCRIPTION
  *    This function takes two points and averages the ordinates.
  *    If points have different ordinate dimensions, 2D point is returned.
  *  EXAMPLE
  *     select ST_AsText(spdba.ST_Average('POINT(-1 -1)'::geometry,'POINT(1 1)'::geometry)) as aPoint;
  *     aPoint
  *     POINT(0 0)
  *     select ST_AsText(spdba.ST_Average('POINTZ(-1 -1 1)'::geometry,'POINTZ(1 1 2)'::geometry)) as aPoint;
  *     aPoint
  *     POINT(0 0 1.5)
  *     select ST_AsText(spdba.ST_Average('POINTM(-1 -1 1)'::geometry,'POINTM(1 1 2)'::geometry)) as aPoint;
  *     aPoint
  *     POINT(0 0 1.5)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - April 2019, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
Begin
  Declare 
    @v_avg_point       geometry,
    @v_first_dim_flag  varchar(4),
    @v_second_dim_flag varchar(4);

  If ( @p_first_point is NULL or @p_second_point is null) 
    Return case when @p_first_point is NULL then @p_second_point else @p_first_point end;

  IF ( @p_first_point.STGeometryType() <> 'Point' 
    OR @p_second_point.STGeometryType() <> 'Point' ) 
    Return case when @p_first_point.STGeometryType()  = 'Point' then @p_first_point 
                when @p_second_point.STGeometryType() = 'Point' then @p_second_point 
                else NULL
           end;

  -- Values are: 0=2d, 1=3dm, 2=3dz, 3=4d.
  SET @v_first_dim_flag = 'XY' 
                         + case when @p_first_point.HasZ=1 then 'Z' else '' end 
                         + case when @p_first_point.HasM=1 then 'M' else '' end;

  SET @v_second_dim_flag = 'XY' 
                         + case when @p_second_point.HasZ=1 then 'Z' else '' end 
                         + case when @p_second_point.HasM=1 then 'M' else '' end;

  IF ( @v_first_dim_flag = 'XY' AND @v_first_dim_flag = @v_second_dim_flag) 
    RETURN geometry::Point ( 
                        (@p_first_point.STX + @p_second_point.STX)/2.0, 
                        (@p_first_point.STY + @p_second_point.STY)/2.0,
                         @p_first_point.STSrid
                       );

  IF ( @v_first_dim_flag = 'XYM' AND @v_first_dim_flag = @v_second_dim_flag) 
    RETURN [$(owner)].[STMakePoint](
                    (@p_first_point.STX + @p_second_point.STX)/2.0, 
                    (@p_first_point.STY + @p_second_point.STY)/2.0,
					NULL,
                    (@p_first_point.M   + @p_second_point.M)/2.0,
					@p_first_point.STSrid
           );
		    
  IF ( @v_first_dim_flag = 'XYZ' AND @v_first_dim_flag = @v_second_dim_flag) 
    RETURN [$(owner)].[STMakePoint](
                    (@p_first_point.STX + @p_second_point.STX)/2.0, 
                    (@p_first_point.STY + @p_second_point.STY)/2.0,
                    (@p_first_point.Z   + @p_second_point.Z)  /2.0,
					NULL,
					@p_first_point.STSrid
           );

  IF ( @v_first_dim_flag = 'XYZM' AND @v_first_dim_flag = @v_second_dim_flag) 
    RETURN [$(owner)].[STMakePoint](
                    (@p_first_point.STX + @p_second_point.STX)/2.0, 
                    (@p_first_point.STY + @p_second_point.STY)/2.0,
                    (@p_first_point.Z + @p_second_point.Z)/2.0,
                    (@p_first_point.M + @p_second_point.M)/2.0,
					@p_first_point.STSrid
           );

  RETURN [$(owner)].[STMakePoint](
                    (@p_first_point.STX + @p_second_point.STX)/2.0, 
                    (@p_first_point.STY + @p_second_point.STY)/2.0,
					case when  @v_first_dim_flag LIKE '%Z%' AND @v_second_dim_flag like '%Z%'
					     then (@p_first_point.Z + @p_second_point.Z)/2.0
						 when  @v_first_dim_flag like '%Z%'
						 then  @p_first_point.Z
						 when  @v_second_dim_flag LIKE '%Z%'
						 then  @p_second_point.Z
						 else NULL
					 end,
					case when  @v_first_dim_flag LIKE '%M%' AND @v_second_dim_flag like '%M%'
					     then (@p_first_point.M + @p_second_point.M)/2.0
						 when  @v_first_dim_flag like '%M%'
						 then  @p_first_point.M
						 when  @v_second_dim_flag LIKE '%M%'
						 then  @p_second_point.M
						 else NULL
					 end,
					@p_first_point.STSrid
           );

END;
GO
