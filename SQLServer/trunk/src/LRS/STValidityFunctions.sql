USE [$(usedbname)]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(lrsowner)].[STValidMeasure]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STValidMeasure];
  PRINT 'Dropped [$(lrsowner)].[STValidMeasure] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(lrsowner)].[STValidLrsPoint]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STValidLrsPoint];
  PRINT 'Dropped [$(lrsowner)].[STValidLrsPoint] ...';
END;
GO

IF EXISTS (SELECT * 
            FROM sysobjects 
            WHERE id = object_id (N'[$(lrsowner)].[STValidLrsGeometry]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STValidLrsGeometry];
  PRINT 'Dropped [$(lrsowner)].[STValidLrsGeometry] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STValidLrsGeometry] ...';
GO

Create Function [$(lrsowner)].[STValidMeasure]
(
  @p_linestring geometry,
  @p_measure    float 
)
Returns bit
As
/****f* LRS/STValidMeasure (2012)
 *  NAME
 *    STValidMeasure -- Checks if supplied measure falls within the linestring's measure range.
 *  SYNOPSIS
 *    Function STValidMeasure (
 *       @p_linestring geometry,
 *       @p_measure    float
 *    )
 *    Returns bit
 *  DESCRIPTION
 *    Function returns 1 (true) if measure falls within the underlying linestring's measure range 
 *    or the 0 (false) string if the supplied measure does not fall within the measure range.
 *    Support All Linestring geometry types
 *  INPUTS
 *    @p_linestring (geometry) - Measured linestring.
 *    @p_measure       (float) - Actual Measure value.
 *  RESULT
 *    1/0                (bit) - 1 (true) if measure within range, 0 (false) otherwise.
 *  EXAMPLE
 *    select t.IntValue,
 *           case when [lrs].[STValidMeasure](geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
 *                                                    cast(t.intValue as float) )
 *                     = 1 
 *                then 'Yes' 
 *                else 'No' 
 *            end 
 *             as isMeasureWithinLinestring
 *      from [dbo].[Generate_Series] (-1,30,4) as t;
 *    GO
 *    
 *    IntValue	isMeasureWithinLinestring
 *    -1	No
 *    3	Yes
 *    7	Yes
 *    11	Yes
 *    15	Yes
 *    19	Yes
 *    23	Yes
 *    27	No
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2017 - Original coding.
 *    Simon Greener - December 2017 - Port to SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin 
  IF ( @p_linestring is null )
    Return 0;
  IF ( @p_linestring.STDimension() <> 1 )
    Return 0;
  Return Case When @p_linestring.STPointN(1).HasM = 1 
               and @p_measure BETWEEN @p_linestring.STPointN(1).M 
                                  AND @p_linestring.STPointN(@p_linestring.STNumPoints()).M
              Then 1
              Else 0
          End;
END
GO

Create Function [$(lrsowner)].[STValidLrsPoint]
(
  @p_point geometry
)
Returns bit 
As
/****f* LRS/STValidLrsPoint (2012)
 *  NAME
 *    STValidLrsPoint -- Checks if supplied @p_point is a valid LRS point.
 *  SYNOPSIS
 *    Function STValidLrsPoint (
 *       @p_point geometry
 *    )
 *    Returns bit
 *  DESCRIPTION
 *    Function returns 1 (true) if point is measured, and 0 (false) if point is not measured.
 *    A valid LRS point has measure information. 
 *    The function checks for the Point geometry type and has a measured ordinate.
 *  INPUTS
 *    @p_point (geometry) - Measured Point.
 *  RESULT
 *    1/0           (bit) - 1 (true) if measured point, 0 (false) otherwise.
 *  EXAMPLE
 *    select [lrs].[STValidLrsPoint](geometry::STGeomFromText('POINT(0 0)',0)) as is_measured_point
 *    GO
 *    
 *    is_measured_point
 *    0
 *    
 *    select [lrs].[STValidLrsPoint](geometry::STGeomFromText('POINT(0 0 NULL 1)',0)) as is_measured_point
 *    GO
 *    
 *    is_measured_point
 *    1
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2017 - Original coding.
 *    Simon Greener - December 2017 - Port to SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  IF ( @p_point is null ) 
    RETURN 0;
  IF ( @p_point.STGeometryType() NOT IN ('MultiPoint','Point') )
    RETURN 0;
  RETURN CASE WHEN @p_point.HasM = 1 AND @p_point.M IS NOT NULL THEN 1 ELSE 0 END;
End;
GO

PRINT 'Creating [$(lrsowner)].[STValidLrsGeometry] ...';
GO

Create Function [$(lrsowner)].[STValidLrsGeometry]
(
  @p_linestring geometry
)
Returns bit 
As
/****f* LRS/STValidLrsGeometry (2012)
 *  NAME
 *    STValidLrsGeometry -- Checks if supplied @p_linestring is a valid measured linestring. 
 *  SYNOPSIS
 *    Function STValidLrsGeometry (
 *       @p_linestring geometry
 *    )
 *    Returns bit
 *  DESCRIPTION
 *    This function checks for geometry type and number of dimensions of the geometric segment.
 *    Function returns 1 (true) if provided geometry is a linestring with valid measured, and 0 (false) otherwise.
 *    Linestring must have either increasing or decreasing measures.
 *    The function supports all Linestring geometry types.
 *  INPUTS
 *    @p_linestring (geometry) - Measured Linestring.
 *  RESULT
 *    1/0                (bit) - 1 (true) if measured linestring, 0 (false) otherwise.
 *  EXAMPLE
 *    select [lrs].[STValidLrsGeometry](geometry::STGeomFromText('LINESTRING(0 0,50 50,100 100)',0)) as is_measured
 *    GO
 *  
 *    is_measured
 *    0
 *  
 *    select [lrs].[STValidLrsGeometry](geometry::STGeomFromText('LINESTRING(0 0 NULL 1,50 50 NULL 14.1,100 100 NULL 141.1)',0)) as is_measured
 *    GO
 *  
 *    is_measured
 *    1
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January  2017 - Original coding.
 *    Simon Greener - December 2017 - Port to SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  IF ( @p_linestring is null ) 
    RETURN 0;
  IF ( @p_linestring.STGeometryType() NOT IN ('MultiLineString','LineString') )
    RETURN 0;
  Return CASE WHEN /* Geometry is Measured  */ @p_linestring.HasM = 1
               AND /* Start Measure Defined */ @p_linestring.STPointN(1).M                         IS NOT NULL
               AND /*   End Measure Defined */ @p_linestring.STPointN(@p_linestring.STNumPoints()).M IS NOT NULL
               AND /* IsMeasureIncreasing */   (  [$(lrsowner)].[STIsMeasureIncreasing] (@p_linestring) = 'TRUE'
                   /* IsMeasureDecreasing */   OR [$(lrsowner)].[STIsMeasureDecreasing] (@p_linestring) = 'TRUE' )
              THEN 1
              ELSE 0
         END;
End;
GO

PRINT '***********************************************';
PRINT 'Testing [$(lrsowner)].[STValidLrsGeometry] and [$(lrsowner)].[STValidMeasure] ...';
GO

select t.IntValue,
       case when [$(lrsowner)].[STValidMeasure](geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
                                                cast(t.intValue as float) )
                 = 1 
            then 'Yes' 
            else 'No' 
        end 
         as isMeasureWithinLinestring
  from GENERATE_SERIES(-1,30,2) as t;
GO


