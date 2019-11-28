SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STSwapOrdinates]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[STSwapOrdinates];
  PRINT 'Dropping [$(owner)].[STSwapOrdinates] ...';
END;
GO

PRINT 'Creating [$(owner)].[STSwapOrdinates] ...';
GO

CREATE FUNCTION [$(owner)].[STSwapOrdinates]
(
  @p_geometry  geometry,
  @p_swap      varchar(2) = 'XY'
)
Returns geometry
As
/****f* EDITOR/STSwapOrdinates (2008)
 *  NAME
 *    STSwapOrdinates -- Allows for swapping ordinate pairs in a geometry.
 *  SYNOPSIS
 *    Function STSwapOrdinates (
 *               @p_geometry geometry,
 *               @p_swap     varchar(2) = 'XY'
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Sometimes the ordinates of a geometry can be swapped such as latitude for X
 *    and Longitude for Y when it should be reversed. This function allows for the
 *    swapping of pairs of ordinates controlled by the @p_swap parameter.
 *    Also supports Z and M ordinate values.
 *  INPUTS
 *    @p_geometry (geometry)  - Supplied geometry.
 *    @p_swap     (varchar 2) - The ordinate pair to swap: XY, XZ, XM, YZ, YM or ZM
 *  RESULT
 *    altered geom (geometry) - Changed Geometry;
 *  EXAMPLE
 *    SELECT [$(owner)].[STSwapOrdinates] (
 *             geometry::STPointFromText('POINT(143.282374 20.293874)',4326),
 *             'XY'
 *           ).AsTextZM() as correctedOrdinates;
 *    correctedOrdinates
 *    POINT (20.293874 143.282374)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2009 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
     @v_coord    int = 0,
     @v_rows     int = 0,
     @v_wkt      varchar(max) = '',
     @v_token    varchar(max),
     @v_delim    varchar(max),
     @v_temp     varchar(100),
     @v_x        varchar(100),
     @v_y        varchar(100),
     @v_z        varchar(100),
     @v_m        varchar(100),
     @v_geometry geometry;
  Begin
    If ( @p_geometry is NULL ) 
      Return null;
    If ( @p_swap NOT IN ('XY','YX', 'XZ', 'XM', 'YZ', 'YM', 'ZM') )
      RETURN CONCAT('POINT(',@p_swap,' must be one of XY, YX, XZ, XM, YZ, YM, ZM only)');
    Set @v_coord = 0;
    Set @v_rows  = 0;
    DECLARE Tokens CURSOR FAST_FORWARD FOR
      SELECT t.token, t.separator
        FROM [$(owner)].[TOKENIZER](@p_geometry.AsTextZM(),' ,()') as t;
    OPEN Tokens;
    FETCH NEXT 
          FROM Tokens
          INTO @v_token, @v_delim;
    WHILE @@FETCH_STATUS = 0
    BEGIN
       IF ( @v_token is null )  -- double delimiter
       BEGIN
          SET @v_wkt = @v_wkt + @v_delim
       END
       ELSE
       BEGIN
          IF ( @v_token not like '[-0-9]%' and @v_token <> 'NULL' ) 
          BEGIN
             SET @v_wkt = @v_wkt + @v_token + LTRIM(@v_delim)
          END
          ELSE -- @v_token LIKE '[0-9]%' or @v_token = 'NULL'
          BEGIN
             IF ( @v_coord = 0 ) BEGIN
               SET @v_x = 'NULL';
               SET @v_y = 'NULL';
               SET @v_z = 'NULL';
               SET @v_m = 'NULL';
             END;
             SET @v_coord = @v_coord + 1;
             IF ( @v_coord = 1 ) SET @v_x = @v_token
             IF ( @v_coord = 2 ) SET @v_y = @v_token
             IF ( @v_coord = 3 ) SET @v_z = @v_token
             IF ( @v_coord = 4 ) SET @v_m = @v_token
             IF ( @v_delim in (',',')') )
             BEGIN
               IF ( @p_swap IN ('XY','YX') ) 
               BEGIN
                 SET @v_temp = @v_y;
                 SET @v_y    = @v_x;
                 SET @v_x    = @v_temp;
               END
               ELSE IF ( @p_swap IN ('XZ','ZX') )
               BEGIN
                 SET @v_temp = @v_z;
                 SET @v_z    = @v_x;
                 SET @v_x    = @v_temp;
               END
               ELSE IF ( @p_swap IN ('XM','MX') )
               BEGIN
                 SET @v_temp = @v_m;
                 SET @v_m    = @v_x;
                 SET @v_x    = @v_temp;
               END
               ELSE IF ( @p_swap IN ('YZ','ZY') )
               BEGIN
                 SET @v_temp = @v_y;
                 SET @v_y    = @v_z;
                 SET @v_z    = @v_temp;
               END
               ELSE IF ( @p_swap IN ('YM','MY') )
               BEGIN
                 SET @v_temp = @v_y;
                 SET @v_y    = @v_m;
                 SET @v_m    = @v_temp;
               END
               ELSE IF ( @p_swap IN ('ZM','MZ') )
               BEGIN
                 SET @v_temp = @v_z;
                 SET @v_z    = @v_m;
                 SET @v_m    = @v_temp;
               END
               SET @v_wkt = CONCAT(@v_wkt,
                                   @v_x,' ',
                                   @v_y,
                                   CASE WHEN @v_z is null 
                                        THEN CASE WHEN @v_m is not null 
                                                  THEN ' NULL'
                                                  ELSE ''
                                              END 
                                        ELSE CONCAT(' ',@v_z) 
                                    END,
                                   CASE WHEN @v_m is null THEN '' ELSE CONCAT(' ',@v_m) END,
                                   @v_delim);
               SET @v_coord = 0;
             END;
           END;
       END;
       FETCH NEXT FROM Tokens INTO @v_token, @v_delim;
    END;
    CLOSE Tokens
    DEALLOCATE Tokens
    SET @v_geometry = geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
    RETURN @v_geometry;
  End
End
GO

