SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STAsEWKT]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[STAsEWKT];
  PRINT 'Dropped [$(owner)].[STAsEWKT] ...';
END;
GO

PRINT 'Creating [$(owner)].[STAsEWKT]...';
GO

CREATE Function [$(owner)].[STAsEWKT] (
  @p_geometry geometry
)
Returns varchar(max)
As
/****m* INTERCHANGE/STAsEWKT (2008)
 *  NAME
 *    STAsEWKT -- Implements an method to create Extended Well Known Text (EWKT) strings from the input @p_geometry.
 *  SYNOPSIS
 *    Function [$(owner)].[STAsEWKT] (
 *      @p_geometry geometry
 *    )
 *    Returns varchar(max)
 *  DESCRIPTION
 *    Implements an export method that writes Extended Well Known Text (EWKT) from @p_geometry.
 *    Writes SRID=nnn; prefix and ZM suffixes to geometry type..
 *    Export WKT or PostGIS-style EWKT.
 *  NOTES
 *    A description of the EWKT structure is available in the PostGIS documentation.
 *  RESULT
 *    EWKT (varchar(max) -- EWKT string describing @p_geometry.
 *  EXAMPLE
 *    select [$(owner)].[STAsEWKT](geometry::STGeomFromText('POINT (1 2)',0));
 *    GO
 *    
 *    ----------
 *    POINT(1 2)
 *    
 *    (1 row affected)
 *    
 *    select [$(owner)].[STAsEWKT](geometry::STGeomFromText('POINT (1 2)',2274));
 *    GO
 *    
 *    --------------------
 *    SRID=2274;POINT(1 2)
 *    
 *    (1 row affected)
 *    
 *    select [$(owner)].[STAsEWKT](geometry::STGeomFromText('POINT (1 2 3)',0));
 *    GO
 *    
 *    -------------
 *    POINTZ(1 2 3)
 *    
 *    (1 row affected)
 *    
 *    select [$(owner)].[STAsEWKT](geometry::STGeomFromText('POINT (1 2 3)',2274));
 *    GO
 *    
 *    -----------------------
 *    SRID=2274;POINTZ(1 2 3)
 *    
 *    (1 row affected)
 *    
 *    select [$(owner)].[STAsEWKT](geometry::STGeomFromText('POINT (1 2 NULL 3)',2274));
 *    GO
 *    
 *    ----------------------------
 *    SRID=2274;POINTM(1 2 NULL 3)
 *    
 *    (1 row affected)
 *    
 *    select [$(owner)].[STAsEWKT](geometry::STGeomFromText('POINT (1 2 1.2 3)',2274));
 *    GO
 *    
 *    ----------------------------
 *    SRID=2274;POINTZM(1 2 1.2 3)
 *    
 *    (1 row affected)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2020 - Original coding.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
Begin
  Declare
    @v_dimensions  varchar(4),
    @v_ewkt        varchar(max),
    @v_textZM      varchar(max),
    @v_srid_prefix varchar(100),
    @v_empty_s     varchar(100);

  IF ( @p_geometry is null )
    Return NULL;

  SET @v_srid_prefix = case when @p_geometry.STSrid <> 0
                            then 'SRID='+CAST(@p_geometry.STSrid as varchar(100)) + ';' 
                            else '' 
                        end;

  -- Special case where SQL Server generates WKT but not EWKT for EMPTY geometries.
  IF ( @p_geometry.STIsEmpty() = 1 ) 
  BEGIN
    SET @v_ewkt = @v_srid_prefix + @p_geometry.AsTextZM();
    Return @v_ewkt;
  END;

  SET @v_dimensions = case when @p_geometry.HasZ=1 then 'Z' else '' end +
                      case when @p_geometry.HasM=1 then 'M' else '' end;

  -- Handle POINT differently
  IF ( @p_geometry.STGeometryType() = 'Point' ) 
  BEGIN
    SET @v_ewkt = @v_srid_prefix + 'POINT' + @v_dimensions + '(';
    SET @v_ewkt = @v_ewkt +
                  + 
                  [$(owner)].[STPointAsText] (
                     /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ 'XY' + @v_dimensions,
                     /* @p_X          */ @p_geometry.STX,
                     /* @p_Y          */ @p_geometry.STY,
                     /* @p_Z          */ case when @v_dimensions in ('Z','ZM') then @p_geometry.Z else @p_geometry.M end,
                     /* @p_M          */ case when @v_dimensions in ('ZM','M') then @p_geometry.M else null end,
                     /* @p_round_x    */ 12,
                     /* @p_round_y    */ 12,
                     /* @p_round_z    */ 12,
                     /* @p_round_m    */ 12
                  )
                  + 
                  ')';
    Return @v_ewkt;
  END; 

  -- ZM can mean NULL M.
  -- If so we downgrade ZM to M
  --
  SET @v_textZM = @p_geometry.AsTextZM();
  IF ( @v_textZM like '% NULL %' )
   SET @v_dimensions = REPLACE(@v_dimensions,'Z','');

  -- For all others we use generic SQL
  -- Build EWKT String...
  With data as (
    select a.id,
           case when a.id = 1
                then @v_srid_prefix +
                     TRIM(a.token) +
                     @v_dimensions +
                     ' '
                when a.coord_id <> 0
                then REPLACE(a.token,' NULL','')
                else a.token
            end as token,
           a.separator,
           case when a.coord_id <> 0 and a.token like '%NULL%'
                then 1 else 0 end as noM
      from (select t.id,
                   t.token as token,
                   case when t.token is  null
                        then 0
                        when PATINDEX('%[0-9]%',TRIM(t.token)) = 1
                        then 1
                        else 0
                    end as coord_id,
                  separator
             from [$(owner)].[Tokenizer](@v_textZM,'(,)') t
           ) a
  ) 
  select @v_ewkt = STRING_AGG ( f.token + f.separator, '' ) WITHIN GROUP ( ORDER BY f.id ASC )
    from data as f

  Return @v_ewkt;
End;
GO

