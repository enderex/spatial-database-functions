SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[Generate_Series]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[Generate_Series];
  PRINT 'Dropped [$(owner)].[Generate_Series] ...';
END;
GO

PRINT 'Creating [$(owner)].[Generate_Series] ...';
GO

CREATE FUNCTION [$(owner)].[Generate_Series] 
( 
  @p_start int,
  @p_end   int, 
  @p_step  int = 1 
)
Returns @Integers TABLE 
( 
  [IntValue] int 
)
AS
/****f* TOOLS/Generate_Series (2008)
 *  NAME
 *    Generate_Series - Creates a series of integers.
 *  SYNOPSIS
 *    Function Generate_Series(
 *       @p_start int,
 *       @p_end   int,
 *       @p_step  int
 *     )
 *     Returns @Integers TABLE 
 *     (
 *       IntValue int
 *     )  
 *  DESCRIPTION
 *    This function creates an array or series of integers starting at @p_start and finishing at @p_end.
 *    The increment between the integer values is supplied by @p_step.
 *    To generate 2, 4, 6, 8, 10 one calls the function as follows Generate_Series(2,10,2).
 *    Negative values are supported.
 *  INPUTS
 *    @p_start (int) - Starting integer.
 *    @p_end   (int) - Finishing integer.
 *    @p_step  (int) - Step or increment.
 *  EXAMPLE
 *    SELECT t.IntValue
 *      FROM [$(owner)].[Generate_Series](2,10,2) as t;
 *    GO
 *    IntValue
 *    --------
 *           2
 *           5
 *           6
 *           8
 *          10
 *  RESULT
 *    Table (Array) of Integers
 *     IntValue (int) - Generates integer value
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Dec 2017 - TSQL SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
    DECLARE 
      @v_i                 INT,
      @v_step              INT,
      @v_terminating_value INT;
    BEGIN
      SET @v_i = CASE WHEN @p_start IS NULL THEN 1 ELSE @p_start END;
      SET @v_step  = CASE WHEN @p_step IS NULL OR @p_step = 0 THEN 1 ELSE @p_step END;
      SET @v_terminating_value =  @p_start + CONVERT(INT,ABS(@p_start-@p_end) / ABS(@v_step) ) * @v_step;
      -- Check for impossible combinations
      IF NOT ( ( @p_start > @p_end AND SIGN(@p_step) = 1 )
               OR
               ( @p_start < @p_end AND SIGN(@p_step) = -1 )) 
      BEGIN
        -- Generate values 
        WHILE ( 1 = 1 )
        BEGIN
           INSERT INTO @Integers ( [IntValue] ) VALUES ( @v_i )
           IF ( @v_i = @v_terminating_value )
              BREAK
           SET @v_i = @v_i + @v_step;
        END;
      END;
    END;
    RETURN
END;
GO


