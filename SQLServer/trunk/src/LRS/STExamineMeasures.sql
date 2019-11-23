USE [$(usedbname)]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(lrsowner)].[STStartMeasure]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(lrsowner)].[STStartMeasure];
  PRINT 'Dropped [$(lrsowner)].[STStartMeasure] ...';
END;
GO
IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(lrsowner)].[STEndMeasure]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(lrsowner)].[STEndMeasure];
  PRINT 'Dropped [$(lrsowner)].[STEndMeasure] ...';
END;
GO
IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(lrsowner)].[STIsMeasureDecreasing]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(lrsowner)].[STIsMeasureDecreasing];
  PRINT 'Dropped [$(lrsowner)].[STIsMeasureDecreasing] ...';
END;
GO
IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(lrsowner)].[STIsMeasureIncreasing]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(lrsowner)].[STIsMeasureIncreasing];
  PRINT 'Dropped [$(lrsowner)].[STIsMeasureIncreasing] ...';
END;
GO
IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(lrsowner)].[STMeasureRange]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(lrsowner)].[STMeasureRange];
  PRINT 'Dropped [$(lrsowner)].[STMeasureRange] ...';
END;
GO
IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(lrsowner)].[STMeasureToPercentage]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(lrsowner)].[STMeasureToPercentage];
  PRINT 'Dropped [$(lrsowner)].[STMeasureToPercentage] ...';
END;
GO
IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(lrsowner)].[STPercentageToMeasure]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(lrsowner)].[STPercentageToMeasure];
  PRINT 'Dropped [$(lrsowner)].[STPercentageToMeasure] ...';
END;
GO

Print 'Creating [$(lrsowner)].[STStartMeasure]...';
GO

CREATE FUNCTION [$(lrsowner)].[STStartMeasure]
(
  @p_linestring geometry
)
Returns Float
As
/****f* LRS/STStartMeasure (2012)
 *  NAME
 *    STStartMeasure -- Returns M value of first point in measured geometry.
 *  SYNOPSIS
 *    Function STStartMeasure (
 *       @p_linestring geometry
 *    )
 *    Returns geometry 
 *  DESCRIPTION
 *    Returns start measure associated with first point in a measured line-string.
 *    Supports Linestrings with CircularString elements (2012).
 *  INPUTS
 *    @p_linestring (geometry) - Supplied Linestring geometry.
 *  RESULT
 *    measure (float) -- Measure value of first point in a measured line-string.
 *  NOTES 
 *    If the line-string is not measured it returns 0.
 *  EXAMPLE
 *    select [$(lrsowner)].[STStartMeasure](geometry::STGeomFromText('LINESTRING(1 1 2 3, 2 2 3 4)', 0)) as start_measure
 *    union all
 *    select [$(lrsowner)].[STStartMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))', 0))
 *    union all
 *    select [$(lrsowner)].[STStartMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0))
 *    GO
 *
 *   start_measure
 *   3
 *   3
 *   0 
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Port to SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType varchar(1000) = '',
    @v_pointm       integer,
    @v_m            Float;
  Begin
    IF (@p_linestring is null)
      Return NULL;
    /* Only linear objects */
    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return null;
    /* Return 0.0 if not measured */
    IF ( @p_linestring.HasM=0 )
      Return 0.0;
    SET @v_m       = null;
    SET @v_pointm  = @p_linestring.STNumPoints();
    IF ( @v_pointm > 0 )
      SET @v_m = @p_linestring.STPointN(1).M;
    Return @v_m;
  END;
END;
GO

Print '********************* ';

Print 'Creating [$(lrsowner)].[STEndMeasure]...';
GO

CREATE FUNCTION [$(lrsowner)].[STEndMeasure]
(
  @p_linestring geometry
)
Returns Float
As
/****f* LRS/STEndMeasure (2012)
 *  NAME
 *    STEndMeasure -- Returns M value of last point in a measured geometry.
 *  SYNOPSIS
 *    Function STEndMeasure (
 *       @p_linestring geometry
 *    )
 *    Returns geometry 
 *  DESCRIPTION
 *    Returns the measure associated with the last point in a measured line-string.
 *    Supports Linestrings with CircularString elements (2012).
 *  INPUTS
 *    @p_linestring (geometry) - Supplied Linestring geometry.
 *  RESULT
 *    measure (float) -- Measure value of the last point in a measured line-string.
 *  NOTES
 *    If the line-string is not measured it returns the length of @p_linestring.
 *  EXAMPLE
 *    select [lrs].[STEndMeasure](geometry::STGeomFromText('LINESTRING(1 1 2 3, 2 2 3 4)', 0)) as end_measure
 *    union all
 *    select [lrs].[STEndMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))', 0))
 *    union all
 *    select [lrs].[STEndMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0))
 *    GO
 *    
 *    end_measure
 *    4
 *    6
 *    6.15
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Port to SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType varchar(1000) = '',
    @v_pointm       integer,
    @v_m            Float;
  Begin
    IF (@p_linestring is null)
      Return NULL;
    /* Only linear objects */
    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return null;
    /* If not measured return STLength of @p_linestring to do if not measured */
    IF ( @p_linestring.HasM=0 )
      Return @p_linestring.STLength();
    SET @v_m       = null;
    SET @v_pointm  = @p_linestring.STNumPoints();
    IF ( @v_pointm > 0 )
      SET @v_m = @p_linestring.STPointN(@v_pointm).M;
    Return @v_m;
  END;
END;
GO

Print 'Creating [$(lrsowner)].[STMeasureRange]...';
GO

CREATE FUNCTION [$(lrsowner)].[STMeasureRange]
(
  @p_linestring geometry
)
Returns Float
As
/****f* LRS/STMeasureRange (2012)
 *  NAME
 *    STMeasureRange -- Returns (Last Point M Value) - (First Point M Value) or length if not measured.
 *  SYNOPSIS
 *    Function STMeasureRange (
 *      @p_linestring geometry
 *    )
 *   Returns varchar(5)
 *  DESCRIPTION
 *    If @p_linestring is measured, the function returns end point measure value - start point measure value.
 *
 *    If line-string not measured, returns length of line.
 *  INPUTS
 *    @p_linestring (geometry) - Supplied Linestring geometry.
 *  RESULT
 *    measure range  (float) - Measure range for measured line-string; returns NULL if not measured.
 *  NOTES
 *    If @p_linestring is not measured, the function will return STLength.
 *  EXAMPLE
 *    select [lrs].[STMeasureRange](geometry::STGeomFromText('LINESTRING(1 1, 2 2)', 0)) as range
 *    union all
 *    select [lrs].[STMeasureRange](geometry::STGeomFromText('LINESTRING(1 1 2 3, 2 2 3 4)', 0)) as range
 *    union all
 *    select [lrs].[STMeasureRange](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))', 0))
 *    union all
 *    select [lrs].[STMeasureRange](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0))
 *    GO
 *    
 *    range
 *    NULL
 *    1
 *    3
 *    6.15
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Port to SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Return [$(lrsowner)].[STEndMeasure]  (@p_linestring) - 
         [$(lrsowner)].[STStartMeasure](@p_linestring);
End;
GO

Print 'Creating [$(lrsowner)].[STMeasureToPercentage]...';
GO

CREATE FUNCTION [$(lrsowner)].[STMeasureToPercentage]
(
  @p_linestring geometry,
  @p_measure    Float
)
Returns Float
As
/****f* LRS/STMeasureToPercentage (2012)
 *  NAME
 *    STMeasureToPercentage --Converts supplied measure value to a percentage.
 *  SYNOPSIS
 *    Function STMeasureToPercentage (
 *      @p_linestring geometry,
 *      @p_measure  Float
 *    )
 *   Returns varchar(5)
 *  DESCRIPTION
 *    The end measure minus the start measure of a measured line-string defines
 *    the range of the measures (see ST_Measure_Range). The supplied measure is
 *    divided by this range and multiplied by 100 to return the measure as a percentage.
 *    For non measured line-strings all values are computed using lengths.
 *  INPUTS
 *    @p_linestring (geometry) - Supplied Linestring geometry.
 *    @p_measure     (float) - Measure somewhere within linestring.
 *  RESULT
 *    Percentage     (float) - Returns measure within measure range of linestring as percentage (0..100) 
 *  EXAMPLE
 *    select [lrs].[STMeasureToPercentage](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),4) as percentage
 *    union all
 *    select [lrs].[STMeasureToPercentage](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),5)
 *    union all
 *    select [lrs].[STMeasureToPercentage](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),6.15)
 *    GO
 *    
 *    percentage
 *    33.3333333333333
 *    66.6666666666667
 *    100
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Port to SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType varchar(1000) = '',
    @v_min_measure  Float,
    @v_max_measure  Float,
    @v_m_range      Float,
    @v_s_point      geometry,
    @v_e_point      geometry;
  Begin
    IF ( @p_linestring is null or @p_measure is null ) 
      Return NULL;
    /* Only linear objects */
    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return null;
    /* Nothing to do if not measured */
    IF ( @p_linestring.HasM=0 )
      Return null;
    SET @v_s_point = @p_linestring.STPointN(1);
    SET @v_e_point = @p_linestring.STPointN(@p_linestring.STNumPoints());
    SET @v_min_measure = case when @v_e_point.M > @v_s_point.M
                              then @v_s_point.M
                              else @v_e_point.M
                          end;
    SET @v_max_measure = case when @v_e_point.M > @v_s_point.M
                              then @v_e_point.M
                              else @v_s_point.M
                          end;
    SET @v_m_range = @v_max_measure - @v_min_measure;
    return ( ( @p_measure - @v_min_measure ) / @v_m_range ) * 100.0;
  End;
End;
GO

Print 'Creating [$(lrsowner)].[STPercentageToMeasure]...';
GO

CREATE FUNCTION [$(lrsowner)].[STPercentageToMeasure] 
(
  @p_linestring geometry,
  @p_percentage Float 
)
Returns Float
As
/****f* LRS/STPercentageToMeasure (2012)
 *  NAME
 *    STPercentageToMeasure -- Converts supplied Percentage value to a Measure.
 *  SYNOPSIS
 *    Function STPercentageToMeasure (
 *      @p_linestring geometry,
 *      @p_percentage Float
 *    )
 *   Returns varchar(5)
 *  DESCRIPTION
 *    The supplied percentage value (between 0 and 100) is multipled by
 *    the measure range (see STMeasureRange) to return a measure value between
 *    the start and end measures. For non measured line-strings all values are
 *    computed using lengths.
 *  INPUTS
 *    @p_linestring (geometry) - Supplied Linestring geometry.
 *    @p_percentage    (float) - Percentage within linestring: from 0 to 100.
 *  RESULT
 *    Measure value    (float) - Measure at the provided percentage along the linestring.
 *  EXAMPLE
 *    select 50.0 as percentage,
 *           [lrs].[STStartMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0)) as start_measure,
 *           [lrs].[STEndMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0)) as end_measure,
 *           [lrs].[STPercentageToMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),50) as measure
 *    union all
 *    select 80.0 as percentage,
 *           [lrs].[STStartMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0)) as start_measure,
 *           [lrs].[STEndMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0)) as end_measure,
 *           [lrs].[STPercentageToMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),80)
 *    union all
 *    select 10.0 as percentage,
 *           [lrs].[STStartMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0)) as start_measure,
 *           [lrs].[STEndMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0)) as end_measure,
 *           [lrs].[STPercentageToMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),10)
 *    GO
 *    
 *    percentage start_measure end_measure measure
 *          50.0             3           6 4.5
 *          80.0             3           6 5.4
 *          10.0             0        6.15 0.615
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Port to SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Return [$(lrsowner)].[STStartMeasure] ( @p_linestring ) 
         + 
         ( 
           (@p_percentage / 100.0) 
           * 
           [$(lrsowner)].[STMeasureRange] ( @p_linestring)
         ); 
End;
GO

Print 'Creating [$(lrsowner)].[STIsMeasureIncreasing]...';
GO

CREATE FUNCTION [$(lrsowner)].[STIsMeasureIncreasing] 
(
  @p_linestring geometry
)
Returns varchar(5)
As
/****f* LRS/STIsMeasureIncreasing (2012)
 *  NAME
 *    STIsMeasureIncreasing -- Checks if M values increase in value over the whole linestring.
 *  SYNOPSIS
 *    Function STIsMeasureIncreasing (
 *      @p_linestring geometry
 *    )
 *   Returns varchar(5)
 *  DESCRIPTION
 *    Checks all measures of all vertices in a linestring from start to end.
 *    Computes difference between each pair of measures. 
 *    If all measure differences increase then TRUE is returned, otherwise FALSE. 
 *    For non-measured line-strings the value is always TRUE.
 *    Supports Linestrings with CircularString elements (2012).
 *  RESULT
 *    boolean (varchar 5) - TRUE if measures are increasing, FALSE otherwise.
 *  EXAMPLE
 *    select [lrs].[STIsMeasureIncreasing](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0)) as is_increasing
 *    union all
 *    select [lrs].[STIsMeasureIncreasing]([dbo].[STReverse](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),1,1)) as is_increasing
 *    union all
 *    select [lrs].[STIsMeasureIncreasing](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0)) as is_increasing
 *    GO
 *    
 *    is_increasing
 *    TRUE
 *    FALSE
 *    TRUE
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Port to SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType varchar(1000) = '',
    @v_i            Integer,
    @v_prev_measure Float,
    @v_measure      Float;
  Begin
    IF ( @p_linestring is null ) 
      Return NULL;
    /* Only linear objects */
    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return null;
    /* Nothing to do if not measured */
    IF ( @p_linestring.HasM=0 )
      Return null;
    SET @v_prev_measure = @p_linestring.STPointN(1).M;
    SET @v_i = 2;
    WHILE ( @v_i <= @p_linestring.STNumPoints() )
    BEGIN
       SET @v_measure = @p_linestring.STPointN(@v_i).M;
       IF ( @v_measure < @v_prev_measure )
       BEGIN
          return 'FALSE';
       END;
       SET @v_prev_measure = @v_measure;
       SET @v_i = @v_i + 1;    
    END;
  End;
  RETURN 'TRUE';
End;
GO

Print 'Creating [$(lrsowner)].[STIsMeasureDecreasing]...';
GO

CREATE FUNCTION [$(lrsowner)].[STIsMeasureDecreasing]
(
  @p_linestring geometry
)
Returns varchar(5)
As
/****f* LRS/STIsMeasureDecreasing (2012)
 *  NAME
 *    STIsMeasureDecreasing -- Checks if M values decrease in value over the whole linestring.
 *  SYNOPSIS
 *    Function STIsMeasureDecreasing (
 *      @p_linestring geometry
 *    )
 *   Returns varchar(5)
 *  DESCRIPTION
 *    Checks all measures of all vertices in a linestring from start to end.
 *    Computes difference between each pair of measures. 
 *    If all measure differences decrease then TRUE is returned, otherwise FALSE. 
 *    For non-measured line-strings the value is always TRUE.
 *    Supports Linestrings with CircularString elements (2012).
 *  RESULT
 *    boolean (varchar 5) - TRUE if measures are decreasing, FALSE otherwise.
 *  EXAMPLE
 *    select [lrs].[STIsMeasureDecreasing](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3,2 2 3 4),(3 3 4 5,4 4 5 6))',0)) as is_decreasing
 *    union all
 *    select [lrs].[STIsMeasureDecreasing](geometry::STGeomFromText('MULTILINESTRING((4 4 5 6,3 3 4 5),(2 2 3 4,1 1 2 3))',0)) as is_decreasing
 *    union all
 *    select [lrs].[STIsMeasureDecreasing](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0)) as is_decreasing
 *    GO
 * 
 *    is_decreasing
 *    FALSE
 *    TRUE
 *    FALSE
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2013 - Original Coding.
 *    Simon Greener - December 2017 - Port to SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_GeometryType varchar(1000) = '',
    @v_i            Integer,
    @v_prev_measure Float,
    @v_measure      Float;
  Begin
    IF ( @p_linestring is null ) 
      Return NULL;
    /* Only linear objects */
    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','MultiLineString','CircularString','CompoundCurve') )
      Return null;
    /* Nothing to do if not measured */
    IF ( @p_linestring.HasM=0 )
      Return null;
    SET @v_prev_measure = @p_linestring.STPointN(1).M;
    SET @v_i = 2;
    WHILE ( @v_i <= @p_linestring.STNumPoints() )
    BEGIN
       SET @v_measure = @p_linestring.STPointN(@v_i).M;
       IF ( @v_measure > @v_prev_measure )
       BEGIN
          return 'FALSE';
       END;
       SET @v_prev_measure = @v_measure;
       SET @v_i = @v_i + 1;    
    END;
  End;
  RETURN 'TRUE';
End;
GO

Print 'Testing .... ';
PRINT '1. STStartMeasure'
GO
select [$(lrsowner)].[STStartMeasure](geometry::STGeomFromText('LINESTRING(1 1 2 3, 2 2 3 4)', 0))
GO
select [$(lrsowner)].[STStartMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))', 0))
GO
select [$(lrsowner)].[STStartMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0))
GO

PRINT '2. STEndMeasure'
GO
select [$(lrsowner)].[STEndMeasure](geometry::STGeomFromText('LINESTRING(1 1 2 3, 2 2 3 4)', 0))
GO
select [$(lrsowner)].[STEndMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))', 0))
GO
select [$(lrsowner)].[STEndMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0))
GO

PRINT '3. STMeasureRange'
GO
select [$(lrsowner)].[STMeasureRange](geometry::STGeomFromText('LINESTRING(1 1 2 3, 2 2 3 4)', 0))
GO
select [$(lrsowner)].[STMeasureRange](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))', 0))
GO
select [$(lrsowner)].[STMeasureRange](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0))
GO

PRINT '4. STPercentageToMeasure'
GO
select [$(lrsowner)].[STPercentageToMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),50)
GO
select [$(lrsowner)].[STPercentageToMeasure](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),80)
GO
select [$(lrsowner)].[STPercentageToMeasure](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),10)
GO

PRINT '5. STMeasureToPercentage'
GO
select [$(lrsowner)].[STMeasureToPercentage](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),4)
GO
select [$(lrsowner)].[STMeasureToPercentage](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),5)
GO
select [$(lrsowner)].[STMeasureToPercentage](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0),6.15)
GO

PRINT '6. STIsMeasureIncreasing'
GO
select [$(lrsowner)].[STIsMeasureIncreasing](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0))
GO
select [$(lrsowner)].[STIsMeasureIncreasing]([$(owner)].[STReverse](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3, 2 2 3 4),(3 3 4 5,4 4 5 6))',0),1,1))
GO
select [$(lrsowner)].[STIsMeasureIncreasing](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0))
GO

PRINT '7. STIsMeasureDecreasing'
GO
select [$(lrsowner)].[STIsMeasureDecreasing](geometry::STGeomFromText('MULTILINESTRING((1 1 2 3,2 2 3 4),(3 3 4 5,4 4 5 6))',0))
GO
select [$(lrsowner)].[STIsMeasureDecreasing](geometry::STGeomFromText('MULTILINESTRING((4 4 5 6,3 3 4 5),(2 2 3 4,1 1 2 3))',0))
GO
select [$(lrsowner)].[STIsMeasureDecreasing](geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0))
GO

