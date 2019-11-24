SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner([$(owner)])';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(cogoowner)].[STResection]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STResection];
  PRINT 'Dropped [$(cogoowner)].[STResection] ...';
END;
GO

drop function [$(cogoowner)].[STResection];
go

create function [$(cogoowner)].[STResection] (
  @p_point1     geometry,
  @p_angle1     float,
  @p_point2     geometry,
  @p_angle2     float,
  @p_point3     geometry,
  @p_angle3     float,
  @p_angle_type varchar(1) = 'I'
)
Returns geometry
As
/****f* COGO/STResection 
 *  NAME
 *    ST_Resection -- Creates a square buffer to left or right of a linestring.
 *  SYNOPSIS
 *    Function [$(cogoowner)].[STResection] (
 *       @p_point1     geometry,
 *       @p_angle1     float,
 *       @p_point2     geometry,
 *       @p_angle2     float,
 *       @p_point3     geometry,
 *       @p_angle3     float,
 *       @p_angle_type varchar(1) = 'I'
 *      )
 *    Returns geometry
 *  NOTES
 *    All three angles must add up to 360.0
 *    Points must be supplied in clockwise order.
 *  TODO
 *    Still under development.
 *  RESULT
 *    point (geometry) - Result of resection
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2019 - Original TSQL coding
 *  COPYRIGHT
 *    (c) 2012-2019 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *    Creative Commons Attribution-Share Alike 2.5 Australia License.
 *    http://creativecommons.org/licenses/by-sa/2.5/au/
******/
Begin
  Declare
    @v_angle_type   varchar(1),
    @v_alpha12      float,
    @v_alpha23      float,
    @v_alpha31      float,
    @v_L12          float,
    @v_L12_2        float,
    @v_L23          float, 
    @v_L23_2        float,
    @v_L13          float,
    @v_L13_2        float,

    @v_cotA123      float,
    @v_A123         float,
    @v_cotA213      float,
    @v_A213         float,
    @v_cotA132      float,
    @v_A132         float,

    @v_cot_alpha12  float,
    @v_cot_alpha23  float,
    @v_cot_alpha31  float,

    @v_F            float,
    @v_f1           float,
    @v_f2           float,
    @v_f3           float,
  
    @v_point_1      geometry,
    @v_point_3      geometry,
    @v_point_12     geometry,
    @v_point_23     geometry,
    @v_point_31     geometry,
    @v_result_point geometry;

  -- Check inputs
  IF ( @p_point1 is null
    or @p_point2 is null
    or @p_point3 is null
    or @p_angle1 is null
    or @p_angle2 is null
    or @p_angle3 is null )
   Return null;
  
  -- Srid Check
  IF ( @p_point1.STSrid <> @p_point2.STSrid
    or @p_point1.STSrid <> @p_point3.STSrid )
    Return Null;

  SET @v_angle_type = UPPER(ISNULL(@p_angle_type,'I'));
  IF ( @v_angle_type not in ('I', /* Internal Angle */
                             'B', /* Bearing from resection point to each external point */
                             'O'  /* Outer angles A->B/C, B->A/C, C->A/B */
                             ) )
    RETURN NULL;

  -- Angle check
  IF ( @v_angle_type = 'I' )
  BEGIN
    IF ( ROUND(( @p_angle1 + @p_angle2 + @p_angle3 ),1) > 360.0 )
      Return NULL;
    SET @v_alpha12 = @p_angle1;
    SET @v_alpha23 = @p_angle2;
    SET @v_alpha31 = @p_angle3;
  END;

  IF ( @v_angle_type = 'B' )
  BEGIN
    -- Bearings from resection point to each point.
    SET @v_alpha12 = @p_angle2 - @p_angle1;
    SET @v_alpha23 = @p_angle3 - @p_angle2;
    SET @v_alpha31 = @p_angle1 - @p_angle3;
    SET @v_alpha31 = CASE WHEN @v_alpha31 < 0 THEN 360.0 + @v_alpha31 ELSE @v_alpha31 END;
  END;

  IF ( @v_angle_type = 'O' )
  BEGIN
    -- Could be three angles between points, 
    SET @v_alpha12 = 180.0 - ( @p_angle1 / 2.0 + @p_angle2 / 2.0 );
    SET @v_alpha23 = 180.0 - ( @p_angle3 / 2.0 - @p_angle2 / 2.0 );
    SET @v_alpha31 = 180.0 - ( @p_angle1 / 2.0 - @p_angle3 / 2.0 );
  END;

  SET @v_L12_2 = POWER(@p_point2.STX-@p_point1.STX,2) + POWER(@p_point2.STY-@p_point1.STY,2);
  SET @v_L23_2 = POWER(@p_point3.STX-@p_point2.STX,2) + POWER(@p_point3.STY-@p_point2.STY,2);
  SET @v_L13_2 = POWER(@p_point3.STX-@p_point1.STX,2) + POWER(@p_point3.STY-@p_point1.STY,2);

  SET @v_L12 = SQRT( @v_L12_2 );
  SET @v_L23 = SQRT( @v_L23_2 );
  SET @v_L13 = SQRT( @v_L13_2 );
    
  SET @v_A123 = ACOS( ( @v_L12_2 + @v_L23_2 - @v_L13_2 ) / ( CAST(2.0 as float) * @v_L12 * @v_L23 ) ) ;
  SET @v_A213 = ACOS( ( @v_L12_2 + @v_L13_2 - @v_L23_2 ) / ( CAST(2.0 as float) * @v_L12 * @v_L13 ) ) ;
  SET @v_A132 = ACOS( ( @v_L13_2 + @v_L23_2 - @v_L12_2 ) / ( CAST(2.0 as float) * @v_L13 * @v_L23 ) ) ;
  
  SET @v_cotA123 = COT( @v_A123 ) ;
  SET @v_cotA213 = COT( @v_A213 ) ;
  SET @v_cotA132 = COT( @v_A132 ) ;
  
  SET @v_cot_alpha12 = COT( @v_alpha12 ) ;
  SET @v_cot_alpha23 = COT( @v_alpha23 ) ;
  SET @v_cot_alpha31 = COT( @v_alpha31 ) ;
  
  SET @v_f1 = CAST(1.0 as float) / ( @v_cotA213 - @v_cot_alpha23 ) ;
  SET @v_f2 = CAST(1.0 as float) / ( @v_cotA123 - @v_cot_alpha31 ) ;
  SET @v_f3 = CAST(1.0 as float) / ( @v_cotA132 - @v_cot_alpha12 ) ;
  SET @v_F  = @v_f1 + @v_f2 + @v_f3 ;
  
  SET @v_result_point =
          geometry::Point(( @v_f1 * @p_point1.STX + @v_f2 * @p_point2.STX + @v_f3 * @p_point3.STX ) / @v_F,
                          ( @v_f1 * @p_point1.STY + @v_f2 * @p_point2.STY + @v_f3 * @p_point3.STY ) / @v_F,
                          @p_point1.STSrid);
  Return @v_result_point;
End
Go

/*
Location is 0,0;
Remote sites:
1) -10, 0 angle 270.0
2)   0,10 angle 0.0
3)  10, 0 angle 90.0
*/

select 1 id, geometry::Point(  0,10,0).STBuffer(1) as point
union all
select 2,    geometry::Point( 10, 0,0).STBuffer(1)
union all
select 3,    geometry::Point(-10, 0,0).STBuffer(1)
union all
Select 0, [$(cogoowner)].[STResection] ( 
            geometry::Point(  0,10,0),120.0,
            geometry::Point( 10, 0,0),120.0,
            geometry::Point(-10, 0,0),120.0,
            'I'
          ).STBuffer(2);


