SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STMakeEnvelopeFromText]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STMakeEnvelopeFromText];
  PRINT 'Dropped [$(owner)].[STMakeEnvelopeFromText] ...';
END;
GO

PRINT 'Creating [$(owner)].[STMakeEnvelopeFromText] ...';
GO

Create Function [$(owner)].[STMakeEnvelopeFromText] (
  @p_mbr_coords varchar(max),
  @p_delim      varchar(1) = ' ',
  @p_srid       integer    = 0
)
Returns geometry 
As
/****f* MBR/STMakeEnvelopeFromText (2008)
 *  NAME
 *    STMakeEnvelopeFromText -- Function that constructs a 5 point polygon from supplied string.
 *  SYNOPSIS
 *    Function [$(owner)].[STMakeEnvelopeFromText] (
 *               @p_mbr_coords varchar,
 *               @p_delim      varchar(1) = ' ',
 *               @p_srid       integer    = 0
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *  NOTES
 *    2D only.
 *  INPUTS
 *    @p_mbr_coords (varchar) - 2 coordinates, 4 ordinates
 *    @p_delim      (varchar) - delimiter separating ordinates
 *    @p_srid       (integer) - geometry srid
 *  RESULT
 *    geometry     (geometry) - Input coordinates converted to 5 point polygon.
 *  EXAMPLE
 *    SELECT [dbo].[STMakeEnvelopeFromText]('0,0,1,1',',',0).STAsText() as mbr;
 *    GO
 *    mbr
 *    POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2019 - Original TSQL Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
 Declare
  @v_delim_count integer,
  @v_delim_pos   integer,
  @v_delim_str   varchar(1),
  @v_mbr_coords  varchar(1000),
  @v_ll_x        varchar(100),
  @v_ll_y        varchar(100),
  @v_ur_x        varchar(100),
  @v_ur_y        varchar(100),
  @v_wkt         varchar(100);
 Begin
  IF ( @p_mbr_coords is null ) 
    RETURN NULL;
  SET @v_delim_str  = ISNULL(@p_delim,' ');
  SET @v_delim_pos  = CHARINDEX(@v_delim_str,@p_mbr_coords);
  IF ( @v_delim_pos = 0)
    Return null;
  SET @v_delim_count = LEN(@p_mbr_coords) - LEN(REPLACE(@p_mbr_coords,@v_delim_str,''));
  if ( @v_delim_count <> 3 ) 
    Return null;

  SET @v_delim_pos  = CHARINDEX(@v_delim_str,@p_mbr_coords);
  SET @v_ll_x       = SUBSTRING(@p_mbr_coords,1,@v_delim_pos-1);
  SET @v_mbr_coords = SUBSTRING(@p_mbr_coords,  @v_delim_pos + 1,LEN(@p_mbr_coords));

  SET @v_delim_pos  = CHARINDEX(@v_delim_str,@v_mbr_coords);
  SET @v_ll_y       = SUBSTRING(@v_mbr_coords,1,@v_delim_pos-1);
  SET @v_mbr_coords = SUBSTRING(@v_mbr_coords,@v_delim_pos + 1,LEN(@v_mbr_coords));

  SET @v_delim_pos  = CHARINDEX(@v_delim_str,@v_mbr_coords);
  SET @v_ur_x       = SUBSTRING(@v_mbr_coords,1,@v_delim_pos-1);

  SET @v_ur_y       = SUBSTRING(@v_mbr_coords,@v_delim_pos + 1,LEN(@v_mbr_coords));

  SET @v_wkt = 'POLYGON((' + 
                         @v_ll_x + ' ' + @v_ll_y + ',' +
                         @v_ur_x + ' ' + @v_ll_y + ',' +
                         @v_ur_x + ' ' + @v_ur_y + ',' +
                         @v_ll_x + ' ' + @v_ur_y + ',' +
                         @v_ll_x + ' ' + @v_ll_y +
               '))';
  RETURN geometry::STGeomFromText(@v_wkt,ISNULL(@p_srid,0));
 End;
End;
GO

PRINT 'Testing [$(owner)].[STMakeEnvelopeFromText] ...';
GO

SELECT [$(owner)].[STMakeEnvelopeFromText]('0 0 1 1',DEFAULT,0) as mbr;
GO

SELECT [$(owner)].[STMakeEnvelopeFromText]('0,0,1,1',',',0).STAsText() as mbr;
GO

SELECT [$(owner)].[STMakeEnvelopeFromText]('0@0@1@1','@',0) as mbr;
GO

