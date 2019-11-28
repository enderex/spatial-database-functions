SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STMorton]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[STMorton];
  PRINT 'Dropped [$(owner)].[STMorton] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = object_id(N'[$(owner)].[ST_MORTON]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[ST_MORTON];
  PRINT 'Dropped [$(owner)].[ST_MORTON] ...';
END;
GO

PRINT 'Creating [$(owner)].[STMorton] ...';
GO

CREATE FUNCTION [$(owner)].[STMorton] 
(
  @p_col int, 
  @p_row int
)
Returns int
WITH EXECUTE AS CALLER, 
     RETURNS NULL ON NULL INPUT
AS
BEGIN
/****f* SORT/STMorton (2008)
 *  NAME
 *    STMorton -- Function which creates a Morton (Space) Key from the supplied row and column reference.
 *  SYNOPSIS
 *    Function STMorton ( 
 *               @p_col int,
 *               @p_row int  
 *             )
 *     Returns int
 *  USAGE
 *    SELECT STMorton (10, 10) as mKey;
 *     # mKey
 *     828
 *  DESCRIPTION
 *    Function that creates a Morton Key from a row/col (grid) reference. 
 *    The generated value can be used to order/sort geometry objects.
 *  INPUTS
 *    @p_col      (int) - Grid Column Reference.
 *    @p_row      (int) - Grid Row Reference.
 *  RESULT
 *    morton_key  (int) - single integer morton key.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Professor David M. Mark - January  1984 - C;
 *    Simon Greener           - December 2011 - Original Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
  Declare 
    @row       int = abs(@p_row),
    @col       int = abs(@p_col),
    @key       int = 0,
    @level     int = 0,
    @left_bit  int,
    @right_bit int,
    @quadrant  int;
  Begin
    While ((@row>0) Or (@col>0))
    Begin
      /* Split off the row (left_bit) and column (right_bit) bits and then combine them to form a bit-pair representing the quadrant */
      Set @left_bit  = @row % 2;
      Set @right_bit = @col % 2;
      Set @quadrant  = @right_bit + 2*@left_bit;
      Set @key       = @key + round(@quadrant * power(2,2*@level), 0, 1);
      /* row, column, and level are then modified before the loop continues */
      If ( @row = 1 And @col = 1 )
      Begin 
        Set @row = 0; 
        Set @col = 0;
      End
      Else
      Begin
        Set @row = @row / 2;
        Set @col = @col / 2;
        Set @level = @level + 1;
      End;
    End;
  End;
  Return @key;
End;
GO

PRINT 'Creating [$(owner)].[ST_MORTON] ...';
GO

Create Function [$(owner)].[ST_Morton] 
(
  @p_point geography
)
Returns Integer 
As
/****f* SORT/ST_Morton (2008)
 *  NAME
 *    ST_Morton -- Function which creates a Morton (Space) Key from a supplied point object.
 *  SYNOPSIS
 *    Function ST_Morton ( 
 *               @p_point geography
 *             )
 *     Returns int
 *  USAGE
 *    SELECT [$(owner)].[ST_Morton](geography::Point(-34.53561,147.2320392,4326)) as mKey;
 *    mKey
 *    390
 *  DESCRIPTION
 *    Function that creates a Morton Key from a point's XY real world ordinates
 *    Implementation within a specific site is normally a constant based on a standard row/column division
 *    of the MBR of all the data within an organisation.
 *  NOTES
 *    Could be rewritten with geometry @p_point and not geography.
 *  INPUTS
 *    @p_point (geometry) - Real world point whose XY ordinates are converted to Row/Col references.
 *  RESULT
 *    morton_key  (float) - Single integer morton key value.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare @lowerLong float = 138,
          @lowerLat  float = -29.5,
          @colSize   float = 0.5,
          @rowSize   float = 0.602941;
    Return [$(owner)].[STMorton] (
               floor((@p_point.Long-@lowerLong)/@colSize), /* Longitude */
               floor((@p_point.Lat-@lowerLat)  /@rowSize)  /* Latitude */
           );
End;
GO

PRINT 'Testing [$(owner)].[STMorton] ...';
GO

-- Show Morton Grid Cells with Morton Key under Queensland 
SELECT [$(owner)].[ST_MORTON]( f.gridCell.EnvelopeCenter() ) as MortonKey, f.gridCell.STAsText() as gridCell
  FROM (SELECT [$(owner)].[STMBR2GEOGRAPHY](138+(  a.gcol*0.5),-29.5+(  b.grow*0.602941),
                                       138+(1+a.gcol)*0.5,-29.5+(1+b.grow)*0.602941,
                                       4283,10) as gridCell
         FROM (SELECT 0 + g.IntValue as gcol from [$(owner)].[GENERATE_SERIES](0,33,1) as g) as a
               CROSS APPLY
              (SELECT 0 + g.IntValue as grow from [$(owner)].[GENERATE_SERIES](0,33,1) as g) as b
       ) as f;
GO


