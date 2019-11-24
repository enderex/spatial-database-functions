SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STPointAsText]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION  [$(owner)].[STPointAsText];
  PRINT 'Dropped [$(owner)].[STPointAsText] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STPointGeomAsText]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION  [$(owner)].[STPointGeomAsText];
  PRINT 'Dropped [$(owner)].[STPointGeomAsText] ...';
END;
GO

PRINT 'Creating [$(owner)].[STPointAsText] ...';
GO

CREATE FUNCTION [$(owner)].[STPointAsText] 
(
  @p_dimensions varchar(4),  /* XY, XYZ, XYM, XYZM or NULL (XY) */
  @p_X          float,
  @p_Y          float,
  @p_Z          float,
  @p_M          float,
  @p_round_x    int = 3,
  @p_round_y    int = 3,
  @p_round_z    int = 2,
  @p_round_m    int = 2
)
Returns varchar(max)
AS
/****f* TOOLS/STPointAsText (2008)
 *  NAME
 *    STPointAsText -- Function that returns a formatted string representation of a coordinate.
 *  SYNOPSIS
 *    Function STPointAsText (
 *        @p_dimensions varchar(4),  - XY, XYZ, XYM, XYZM or NULL (XY)
 *        @p_X          float,
 *        @p_Y          float,
 *        @p_Z          float,
 *        @p_M          float,
 *        @p_round_x    int = 3,
 *        @p_round_y    int = 3,
 *        @p_round_z    int = 2,
 *        @p_round_m    int = 2
 *     )
 *     Returns varchar(max)
 *  EXAMPLE
 *    With Data As (
 *      select CAST('XY' as varchar(4)) as ords, CAST([dbo].[STPointAsText]('XY',0.1,0.2,0.3,0.41,3,3,2,1) as varchar(40)) as coords
 *      union all
 *      select 'XYZ'                    as ords, [dbo].[STPointAsText]('XYZ',0.1,0.2,0.3,0.41,3,3,2,1) as coords
 *      union all
 *      select 'XYM'                    as ords, [dbo].[STPointAsText]('XYM',0.1,0.2,0.3,0.41,3,3,2,1) as coords
 *      union all
 *      select 'XYZM'                   as ords, [dbo].[STPointAsText]('XYZM',0.1,0.2,0.3,0.41,3,3,2,1) as coords
 *    )
 *    select a.ords,
 *           geometry::STGeomFromText (
 *             'POINT (' + a.coords + ')',0).AsTextZM() as point
 *      from data as a;
 *    GO
 *
 *    ords point
 *    XY   POINT (0.1 0.2)
 *    XYZ  POINT (0.1 0.2 0.3)
 *    XYM  POINT (0.1 0.2 NULL 0.4)
 *    XYZM POINT (0.1 0.2 0.3 0.4)
 *  DESCRIPTION
 *    This function returns a formatted string representation of a coordinate with up to 4 ordinates.
 *    Because ordinates can be NULL, the @p_dimensions instructs the function which ordinates are to be used.
 *    The function is suitable for use in WKT text constructors as shown in the USAGE element of this documentation.
 *    The function correctly rounds each ordinate using the supplied rounding factor.
 *  INPUTS
 *    @p_dimensions (varchar 4) - Ordinates to process. Valid values are XY, XYZ, XYM, XYZM or NULL (XY)
 *    @p_X          (float)     - X Ordinate
 *    @p_Y          (float)     - Y Ordinate
 *    @p_Z          (float)     - Z Ordinate
 *    @p_M          (float)     - M Ordinate
 *    @p_round_x    (int)       - X Ordinate rounding factor.
 *    @p_round_y    (int)       - Y Ordinate rounding factor.
 *    @p_round_z    (int)       - Z Ordinate rounding factor.
 *    @p_round_m    (int)       - M Ordinate rounding factor.
 *  RESULT
 *    formatted string (varchar max) - Formatted string.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
     @v_wkt        varchar(max) = '',
     @v_left_fmt   varchar(25)  = '#######################0.',
     @v_right_fmt  varchar(25)  = '#########################',
     @v_dimensions varchar(4)   = UPPER(ISNULL(@p_dimensions,'XY'));
  Begin
    If ( @p_X IS NULL OR @p_Y IS NULL ) 
       return null;
    IF ( @v_dimensions is null )
       SET @v_dimensions = 'XY';
    SET @v_wkt = FORMAT(@p_X,@v_left_fmt + LEFT(@v_right_fmt,ISNULL(@p_round_x,3)))
                 + 
                 ' ' 
                 +
                 FORMAT(@p_Y,@v_left_fmt + LEFT(@v_right_fmt,ISNULL(@p_round_y,3)))
                 + 
                 case when CHARINDEX('Z',@v_dimensions) > 0
                      then ' ' + 
                           case when @p_z is not null
                                then FORMAT(@p_Z,@v_left_fmt + LEFT(@v_right_fmt,ISNULL(@p_round_z,2)))
                                else 'NULL'
                            end
                      else case when CHARINDEX('M',@v_dimensions) > 0 then ' NULL' else '' end
                  end 
                 + 
                 case when CHARINDEX('M',@v_dimensions) > 0
                      then ' ' + 
                           case when @p_M is not null 
                                then FORMAT(@p_M,@v_left_fmt + LEFT(@v_right_fmt,ISNULL(@p_round_m,2)))
                                else 'NULL'
                             end
                      else '' 
                  end;
    RETURN @v_wkt;
  END;
END
GO

PRINT 'Creating [$(owner)].[STPointGeomAsText] ...';
GO

CREATE FUNCTION [$(owner)].[STPointGeomAsText] 
(
  @p_point    geometry,
  @p_round_xy int = 3,
  @p_round_z  int = 2,
  @p_round_m  int = 2
)
Returns varchar(max)
AS
/****f* CONVERSION/STPointGeomAsText (2008)
 *  NAME
 *    STPointGeomAsText -- Function that returns a formatted string representation of a point's ordinates rounded to supplied tolerances.
 *  SYNOPSIS
 *    Function STPointGeomAsText (
 *        @p_point   geometry,
 *        @p_round_x    int = 3,
 *        @p_round_y    int = 3,
 *        @p_round_z    int = 2,
 *        @p_round_m    int = 2
 *     )
 *     Returns varchar(max)
 *  USAGE
 *    SELECT [$(owner)].[STPointGeomAsText] (
 *             geometry::STPointFromText('POINT (0.1232332 0.21121 0.1213 0.41)',0),
 *             3, 2, 1
 *           ) as point;
 *    GO
 *    point
 *    '0.123 0.211 0.12 0.4'
 *  DESCRIPTION
 *    This function returns a formatted string representation of a point with up to 4 ordinates.
 *    The function is suitable for use in WKT text constructors as shown in the USAGE element of this documentation.
 *    The function correctly rounds each ordinate using the supplied rounding factor.
 *    This function is different from the standard .AsTextZM() as it also rounds the ordinates and does not return the POINT () elements.
 *  NOTES
 *    Wrapper over STPointAsText
 *  INPUTS
 *    @p_point (geometry) - Geometry Point
 *    @p_round_xy   (int) - XY Ordinates rounding factor.
 *    @p_round_z    (int) - Z Ordinate rounding factor.
 *    @p_round_m    (int) - M Ordinate rounding factor.
 *  RESULT
 *    formatted string (varchar max) - Formatted string.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2008 - Original Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
     @v_wkt        varchar(max) = '',
     @v_point      geometry,
     @v_dimensions varchar(4);
  Begin
    If ( @p_point IS NULL ) 
       return null;
    SET @v_point = case when @p_point.STGeometryType() = 'Point' then @p_point else [$(owner)].[STStartPoint] ( @p_point ) end;
    SET @v_dimensions = 'XY' 
                       + case when @v_point.HasZ=1 then 'Z' else '' end +
                       + case when @v_point.HasM=1 then 'M' else '' end;
    RETURN [$(owner)].[STPointAsText] (
              @v_dimensions,
              @v_point.STX,
              @v_point.STY,
              @v_point.Z,
              @v_point.M,
              ISNULL(@p_round_xy,3),
              ISNULL(@p_round_xy,3),
              ISNULL(@p_round_z, 2),
              ISNULL(@p_round_m, 2)
           );
  End;
END
GO

/* ******************** TESTS ******************* */

PRINT 'Testing [$(owner)].[PointAsText] ...';
GO

With Data As (
  select CAST('XY' as varchar(4)) as ords, CAST([$(owner)].[STPointAsText]('XY',0.1,0.2,0.3,0.41,3,3,2,1) as varchar(40)) as coords
  union all
  select 'XYZ'                    as ords, [$(owner)].[STPointAsText]('XYZ',0.1,0.2,0.3,0.41,3,3,2,1) as coords
  union all
  select 'XYM'                    as ords, [$(owner)].[STPointAsText]('XYM',0.1,0.2,0.3,0.41,3,3,2,1) as coords
  union all
  select 'XYZM'                   as ords, [$(owner)].[STPointAsText]('XYZM',0.1,0.2,0.3,0.41,3,3,2,1) as coords
)
select a.ords,
       geometry::STGeomFromText (
         'POINT (' + a.coords + ')',0).AsTextZM() as point
  from data as a;
GO

select case when t.IntValue = 1 then 'XY' 
            when t.IntValue = 2 then 'XYZ'
            when t.IntValue = 3 then 'XYM'
            when t.IntValue = 4 then 'XYZM'
            when t.IntValue = 5 then 'XYZM'
        end as CoordType,
       [$(owner)].[STPointAsText] ( 
          /* @p_dimensions */ case when t.IntValue = 1 then 'XY' 
                                   when t.IntValue = 2 then 'XYZ'
                                   when t.IntValue = 3 then 'XYM'
                                   when t.IntValue = 4 then 'XYZM'
                                   when t.IntValue = 5 then 'XYZM'
                                end,
          /* @p_X          */ 123.45678,
          /* @p_Y          */ 459.298223,
          /* @p_Z          */ case when t.IntValue = 4 then NULL when t.IntValue=5 then 784.903 end,
          /* @p_M          */ 1.345,
          /* @p_round_x    */ 3,
          /* @p_round_y    */ 3,
          /* @p_round_z    */ 2,
          /* @p_round_m    */ 2 )
  from [$(owner)].[GENERATE_SERIES](1,4,1) as t;
GO

SELECT [$(owner)].[STPointGeomAsText] (geometry::STPointFromText('POINT (0.1232332 0.21121 0.1213 0.41)',0),3, 2, 1) as point;
GO

SELECT [$(owner)].[STPointGeomAsText] (geometry::STPointFromText('POINT (0.1232332 0.21121 NULL 0.41)',0),3, 2, 1) as point;
GO


