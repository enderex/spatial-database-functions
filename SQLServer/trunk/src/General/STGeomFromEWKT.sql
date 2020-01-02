SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STGeomFromEWKT]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[STGeomFromEWKT];
  PRINT 'Dropped [$(owner)].[STGeomFromEWKT] ...';
END;
GO

PRINT 'Creating [$(owner)].[STGeomFromEWKT]...';
GO

CREATE FUNCTION [$(owner)].[STGeomFromEWKT](
  @p_ewkt varchar(max)
)
Returns geometry
As
/****m* INTERCHANGE/STGeomFromEWKT (2008)
 *  NAME
 *    STGeomFromEWKT -- Implements an import method for Extended Well Known Text including EWKT with SRID, Z and M ordinates..
 *  SYNOPSIS
 *    Function [dbo].[STGeomFromEWKT] (
 *      @p_ewkt varchar(max)
 *    )
 *    Returns geometry
 *  DESCRIPTION
 *    Implements an import method for Extended Well Known Text including EWKT with SRID=, Z and M ordinates..
 *    Returns valid geometry object if input is valid.
 *    Imports any WKT or PostGIS-style EWKT.
 *    Supports EWKT like "POINT EMPTY".
 *  NOTES
 *    A description of the EWKT structure is available in the PostGIS documentation.
 *  RESULT
 *    geometry (geometry) -- geometry containing a valid geometry with SRID, 2, 3 or 4 dimensions.
 *  EXAMPLE
 *    select [dbo].[STGeomFromEWKT]('POINT EMPTY').AsTextZM() as geom;
 *    geom
 *    -----------
 *    POINT EMPTY
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('MULTIPOINT EMPTY').AsTextZM() as geom;
 *    geom
 *    ----------------
 *    MULTIPOINT EMPTY
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('LINESTRING EMPTY').AsTextZM() as geom;
 *    geom
 *    ----------------
 *    LINESTRING EMPTY
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('CIRCULARSTRING EMPTY').AsTextZM() as geom;
 *    geom
 *    --------------------
 *    CIRCULARSTRING EMPTY
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('MULTILINESTRING EMPTY').AsTextZM() as geom;
 *    geom
 *    ---------------------
 *    MULTILINESTRING EMPTY
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('POLYGON EMPTY').AsTextZM() as geom;
 *    geom
 *    -------------
 *    POLYGON EMPTY
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('MULTIPOLYGON EMPTY').AsTextZM() as geom;
 *    geom
 *    ------------------
 *    MULTIPOLYGON EMPTY
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('COMPOUNDCURVE EMPTY').AsTextZM() as geom;
 *    geom
 *    -------------------
 *    COMPOUNDCURVE EMPTY
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('GEOMETRYCOLLECTION EMPTY').AsTextZM() as geom;
 *    geom
 *    ------------------------
 *    GEOMETRYCOLLECTION EMPTY
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('POINT(1 2)').AsTextZM() as geom;
 *    geom
 *    -----------
 *    POINT (1 2)
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('POINTZ(1 2 3)').AsTextZM() as geom;
 *    geom
 *    -------------
 *    POINT (1 2 3)
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('POINTM(1 2 3)').AsTextZM() as geom;
 *    geom
 *    ------------------
 *    POINT (1 2 NULL 3)
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('POINTZM(1 2 3 4)').AsTextZM() as geom;
 *    geom
 *    ---------------
 *    POINT (1 2 3 4)
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('LineString (1 2,4 5,3 4,4 6,5 7,6 7)').AsTextZM() as geom;
 *    geom
 *    -----------------------------------------
 *    LINESTRING (1 2, 4 5, 3 4, 4 6, 5 7, 6 7)
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('SRID=2274;LINESTRING (1 2,4 5,3 4,4 6,5 7,6 7)').AsTextZM() as geom;
 *    geom
 *    -----------------------------------------
 *    LINESTRING (1 2, 4 5, 3 4, 4 6, 5 7, 6 7)
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('SRID=2274;LINESTRINGZ (1 2 3,3 4 5,4 6 6,5 7 7,6 7 8)').AsTextZM() as geom;
 *    geom
 *    ----------------------------------------------
 *    LINESTRING (1 2 3, 3 4 5, 4 6 6, 5 7 7, 6 7 8)
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('SRID=2274;LINESTRINGM (1 2 3,3 4 5,4 6 6,5 7 7,6 7 8)').AsTextZM() as geom;
 *    geom
 *    -----------------------------------------------------------------------
 *    LINESTRING (1 2 NULL 3, 3 4 NULL 5, 4 6 NULL 6, 5 7 NULL 7, 6 7 NULL 8)
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('MULTILINESTRING ((1 2 3,4 5 6,3 4 5),(4 5 6,5 6 7, 5 6 7))').AsTextZM() as geom;
 *    geom
 *    --------------------------------------------------------------
 *    MULTILINESTRING ((1 2 3, 4 5 6, 3 4 5), (4 5 6, 5 6 7, 5 6 7))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('MULTILINESTRING Z ((1 2 3,4 5 6,3 4 5),(4 5 6,5 6 7, 5 6 7))').AsTextZM() as geom;
 *    geom
 *    --------------------------------------------------------------
 *    MULTILINESTRING ((1 2 3, 4 5 6, 3 4 5), (4 5 6, 5 6 7, 5 6 7))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('MULTILINESTRING M ((1 2 3,4 5 6,3 4 5),(4 5 6,5 6 7, 5 6 7))').AsTextZM() as geom;
 *    geom
 *    --------------------------------------------------------------------------------------------
 *    MULTILINESTRING ((1 2 NULL 3, 4 5 NULL 6, 3 4 NULL 5), (4 5 NULL 6, 5 6 NULL 7, 5 6 NULL 7))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('SRID=2287;MULTILINESTRING ZM ((1 2 3,4 5 6,3 4 5),(4 5 6,5 6 7, 5 6 7))').AsTextZM() as geom;
 *    geom
 *    --------------------------------------------------------------------------------------------
 *    MULTILINESTRING ((1 2 NULL 3, 4 5 NULL 6, 3 4 NULL 5), (4 5 NULL 6, 5 6 NULL 7, 5 6 NULL 7))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('POLYGON((0 0 1,10 0 1,10 10 1,0 10 1,0 0 1))').AsTextZM() as geom;
 *    geom
 *    -------------------------------------------------
 *    POLYGON ((0 0 1, 10 0 1, 10 10 1, 0 10 1, 0 0 1))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('POLYGONZ((0 0 1,10 0 1,10 10 1,0 10 1,0 0 1))').AsTextZM() as geom;
 *    geom
 *    -------------------------------------------------
 *    POLYGON ((0 0 1, 10 0 1, 10 10 1, 0 10 1, 0 0 1))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('POLYGONM((0 0 1,10 0 1,10 10 1,0 10 1,0 0 1))').AsTextZM() as geom;
 *    geom
 *    --------------------------------------------------------------------------
 *    POLYGON ((0 0 NULL 1, 10 0 NULL 1, 10 10 NULL 1, 0 10 NULL 1, 0 0 NULL 1))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('POLYGONZM((0 0 NULL 1, 10 0 NULL 1, 10 10 NULL 1, 0 10 NULL 1, 0 0 NULL 1))').AsTextZM() as geom;
 *    geom
 *    --------------------------------------------------------------------------
 *    POLYGON ((0 0 NULL 1, 10 0 NULL 1, 10 10 NULL 1, 0 10 NULL 1, 0 0 NULL 1))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('GEOMETRYCOLLECTION (POINT(0 0 1), LINESTRING(10 0 1, 10 10 1, 0 10 1))').AsTextZM() as geom;
 *    geom
 *    ------------------------------------------------------------------------
 *    GEOMETRYCOLLECTION (POINT (0 0 1), LINESTRING (10 0 1, 10 10 1, 0 10 1))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('GEOMETRYCOLLECTION Z(POINT(0 0 1), LINESTRING(10 0 1, 10 10 1, 0 10 1))').AsTextZM() as geom;
 *    geom
 *    ------------------------------------------------------------------------
 *    GEOMETRYCOLLECTION (POINT (0 0 1), LINESTRING (10 0 1, 10 10 1, 0 10 1))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('GEOMETRYCOLLECTION M(POINT(0 0 1), LINESTRING(10 0 1, 10 10 1, 0 10 1))').AsTextZM() as geom;
 *    geom
 *    --------------------------------------------------------------------------------------------
 *    GEOMETRYCOLLECTION (POINT (0 0 NULL 1), LINESTRING (10 0 NULL 1, 10 10 NULL 1, 0 10 NULL 1))
 *    
 *    (1 row affected)
 *    
 *    select [dbo].[STGeomFromEWKT]('COMPOUNDCURVE M((2173369.79254475 259887.575230554 2600,2173381.122467 259911.320734575 2626.3106),CIRCULARSTRING (2173381.122467 259911.320734575 2626.3106,2173433.84355779 259955.557426129 0,2173501.82006501 259944.806018785 2768.24))').AsTextZM() as geom
 *    geom
 *    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *    COMPOUNDCURVE ((2173369.79254475 259887.575230554 NULL 2600, 2173381.122467 259911.320734575 NULL 2626.3106), CIRCULARSTRING (2173381.122467 259911.320734575 NULL 2626.3106, 2173433.84355779 259955.557426129 NULL 0, 2173501.82006501 259944.806018785 NULL 2768.24))
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
    @v_ewkt                 varchar(max),
    @v_hasZ                 bit,
    @v_hasM                 bit,
    @v_num_ords             integer = 0,
    @v_num_coords           integer = 0,
    @v_srid_i               integer = 0,
    @v_position             integer = 0,
    @v_srid_s               varchar(100),
    @v_coord_string         varchar(100),
    @v_originalGeometryType varchar(100),
    @v_geometryType         varchar(100),
    @v_ordinates            varchar(2),
    @v_geometry             geometry;

  IF ( @p_ewkt is null ) 
  BEGIN
    RETURN geometry::STGeomFromText('GEOMETRY EMPTY',0);
  END;

  IF ( @p_ewkt LIKE '%EMPTY' ) 
    Return geometry::STGeomFromText(@p_ewkt,0);

  SET @v_srid_i = 0;
  SET @v_position = CHARINDEX(';',@p_ewkt,1);
  IF ( @v_position > 0 )
  BEGIN
    -- Has 'SRID=nnn;' prefix.
    -- Find SRID if at start
    -- SRID=2345; POINT(23283.l2929 2929290l.2020)
    SET @v_srid_s = SUBSTRING(@p_ewkt,1,@v_position-1);
    -- SRID=2345
    IF ( @v_srid_s is not null ) 
    Begin
      SET @v_srid_s = SUBSTRING(@v_srid_s,CHARINDEX('=',@v_srid_s,1)+1,LEN(@v_srid_s));
      -- 2345
      IF (@v_srid_s is not null) 
        SET @v_srid_i = CAST(@v_srid_s as integer);
      -- Remove SRID={VALUE}; from original WKT
      SET @v_ewkt = TRIM(SUBSTRING(@p_ewkt,CHARINDEX(';',@p_ewkt)+1,LEN(@p_ewkt)));
    END;
  END
  ELSE
    SET @v_ewkt = @p_ewkt;

  --Extract Geometry Type
  SET @v_originalGeometryType = SUBSTRING(@v_ewkt,1,CHARINDEX('(',@v_ewkt,1)-1);
  SET @v_hasZ = 0;
  SET @v_hasM = 0;
  SET @v_ordinates = SUBSTRING(@v_originalGeometryType,LEN(@v_originalGeometryType)-1,2);
  IF ( @v_ordinates = 'ZM' OR @v_ordinates = 'MZ' ) 
  BEGIN
    SET @v_hasZ = 1;  
    SET @v_hasM = 1;
    SET @v_GeometryType = SUBSTRING(@v_originalGeometryType,1,LEN(@v_originalGeometryType)-2);
  END
  ELSE
  BEGIN
    IF ( @v_originalGeometryType like '%Z' )
      SET @v_hasZ = 1;
    IF ( @v_originalGeometryType like '%M' )
      SET @v_hasM = 1;
    SET @v_GeometryType = case when @v_hasZ = 0 AND @v_hasM = 0
                               then @v_originalGeometryType
                               else SUBSTRING(@v_originalGeometryType,1,LEN(@v_originalGeometryType)-1)
                            end;
  END;

  IF ( @v_geometryType <> @v_originalGeometryType )
    SET @v_ewkt = REPLACE(@v_ewkt,@v_originalGeometryType,UPPER(@v_GeometryType));

  -- Find out how many ordinates
  SET @v_coord_string  = SUBSTRING(@v_ewkt,
                                   CHARINDEX('(',@v_ewkt,1)+1,
                                   PATINDEX('%[,)]%',@v_ewkt)-CHARINDEX('(',@v_ewkt,1)-1
                         );
  IF ( SUBSTRING(@v_coord_string,1,1) = '(' )
    SET @v_coord_string  = SUBSTRING(@v_coord_string,2,LEN(@v_coord_string));
  SET @v_num_ords      = LEN(@v_coord_string) - LEN(REPLACE(@v_coord_string, ' ', '')) + 1;
  SET @v_num_coords    = LEN(@v_ewkt)         - LEN(REPLACE(@v_ewkt,         ',', '')) + 1;

  -- If WKT is single Point then use T_VERTEX Constructor to parse the coordinate string.
  IF ( @v_num_ords = 2) 
  BEGIN
    SET @v_geometry = geometry::STGeomFromText(@v_ewkt,@v_srid_i);
    RETURN @v_geometry;
  END;

  IF ( @v_num_ords = 4 )
  BEGIN
    SET @v_geometry = geometry::STGeomFromText(@v_ewkt,@v_srid_i);
    RETURN @v_geometry;
  END;

  IF ( @v_num_ords = 3 AND @v_hasM = 0) 
  BEGIN
    SET @v_geometry = geometry::STGeomFromText(@v_ewkt,@v_srid_i);
    RETURN @v_geometry;
  END;

  -- Last case is ( @v_num_ords = 3 and @v_hasM = 1 ) 
  -- Need to add in NULL to Z ordinate position
  With tokens As (
    select a.id,
           case when a.token like '%Z'
                then REPLACE(a.token,'Z','')
                when a.token like '%M'
                then SUBSTRING(a.token,1,LEN(a.token-1))
                when a.is_coordinate <> 0 -- Coordinate has three values XYM when it should have 4 XY(NULL)M
                then SUBSTRING(a.token,1,(LEN(a.token) - CHARINDEX(' ',REVERSE(a.token))) ) + 
                     ' NULL' 
                     + 
                     SUBSTRING(a.token, (LEN(a.token) - CHARINDEX(' ',REVERSE(a.token)))+1,100) 
                else a.token
            end as token,
           a.separator
      from (select t.id,
                   ISNULL(t.token,'') as token,
                   PATINDEX('%[0-9]%',TRIM(t.token)) as is_coordinate,
                   ISNULL(t.separator,'') as separator
              from [$(owner)].[Tokenizer](@v_ewkt,';(,)') t
            ) a
  )
  select @v_geometry = geometry::STGeomFromText(STRING_AGG ( f.token + f.separator, '' ) WITHIN GROUP ( ORDER BY f.id ASC),0) 
    from tokens as f;
  Return @v_geometry;
End;
GO


