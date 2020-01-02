SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STAppend]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STAppend];
  PRINT 'Dropped [$(owner)].[STAppend]';
END;
GO

Print 'Creating [$(owner)].[STAppend] ...';
GO

CREATE FUNCTION [$(owner)].[STAppend]
(
  @p_linestring1 geometry,
  @p_linestring2 geometry,
  @p_round_xy    int   = 3,
  @p_round_zm    int   = 2
)
returns geometry 
as
/****m* EDITOR/STAppend (2012)
 *  NAME
 *    STAppend -- Appends second linestring to end of first linestring.
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STAppend] (
 *               @p_linestring1 geometry,
 *               @p_linestring2 geometry,
 *               @p_round_xy    int   = 3,
 *               @p_round_zm    int   = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Given two linestrings, this function appends the second to the first, though their direction could change (eg Start/Start Point relationship).
 *    While one can use STUnion() for this, STUnion does not handle geometries with Z and M.
 *    This function specifically supports Z and M for LRS type operations.
 *    The input geometry objects must conform to the following:
 *      1. Normally, both linestrings should be either a CircularString or a Linestring.
 *      2. A CompoundCurve is supported only when it is supplied as @p_linestring1.
 *      3. A MultiLineString can only be supplied via @p_linestring1.
 *      4. A LineString can only be supplied via @p_linestring2 when @p_linestring1 is a MultiLineString.
 *      5. Two supplied MultiLineString geometries are not currently supported.
 *      6. Both linestring parameters must have the same SRID
 *      7. Both linestring parameters must have the same Coordinate Dimension ie XYZ=XYZ, XYM=XYM or XYZM=XYZM. 
 *      8. Both linestring parameters geometries must be valid.
 *    It is up to the caller to ensure these conditions are met.
 *    For optimal performance one should append a smaller second geometry (@p_linestring2) to a larger @p_linestring1.
 *  NOTES
 *    Supports Linestrings with CircularString elements.
 *  INPUTS
 *    @p_linestring1 (geometry) - Linestring geometry possibly with elevation (Z) and measures (M).
 *    @p_linestring2 (geometry) - Linestring geometry possibly with elevation (Z) and measures (M).
 *    @p_round_xy         (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm         (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    appended line  (geometry) - New line with second appended to first
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  DECLARE
    @v_GeometryType1       varchar(100),
    @v_GeometryType2       varchar(100),
    @v_wkt                 varchar(max),
    @v_wkt_remainder       varchar(max),
    @v_last_wkt_point      varchar(500),
    @v_wkt_point           varchar(500),
    @v_Dimensions          varchar(4),
    @v_Dimensions2         varchar(4),
    @v_round_xy            int,
    @v_round_zm            int,
    @v_geomn               int,
    @v_NumGeoms            int,
    @v_appended            bit,
    @v_linestring1         geometry,
    @v_linestring2         geometry,
    @v_geometry            geometry,
    @v_reversed_line       geometry;
  BEGIN
    If ( @p_linestring1 is null and @p_linestring2 is null )
      Return NULL;
    If ( @p_linestring1 is not null and @p_linestring2 is null )
      Return @p_linestring1;
    If ( @p_linestring1 is null and @p_linestring2 is not null )
      Return @p_linestring2;
    If ( @p_linestring1.STSrid<>@p_linestring2.STSrid )
      Return @p_linestring1;
    If ( @p_linestring1.STIsValid()=0 OR @p_linestring2.STIsValid()=0 )
      Return @p_linestring1;

    SET @v_GeometryType1 = @p_linestring1.STGeometryType();
    IF (@v_GeometryType1 NOT IN ('MultiLineString',
                                 'LineString',
                                 'CircularString',
                                 'CompoundCurve' ) )
      Return @p_linestring2;

    SET @v_GeometryType2 = @p_linestring2.STGeometryType();
    IF ( @v_GeometryType2 = 'CompoundCurve' AND 
         @v_GeometryType1 <> 'CompoundCurve' )
    BEGIN
      -- Put compoundCurve first
      SET @v_linestring1   = geometry::STGeomFromText(@p_linestring2.AsTextZM(),@p_linestring2.STSrid);
      SET @v_linestring2   = geometry::STGeomFromText(@p_linestring1.AsTextZM(),@p_linestring2.STSrid);
      SET @v_GeometryType1 = @p_linestring2.STGeometryType();
      SET @v_GeometryType2 = @p_linestring1.STGeometryType();
    END
    ELSE
    BEGIN
     SET @v_linestring1  = @p_linestring1;
     SET @v_linestring2  = @p_linestring2;
    END;

    -- second cannot be a MultiLineString or CompoundCurve
    IF (@v_GeometryType2 NOT IN ('LineString',
                                 'CircularString' ) ) 
      Return @p_linestring1;

    IF ( @v_GeometryType1 = 'MultiLineString' and @v_GeometryType2 <> 'LineString' )
      Return @p_linestring1;

    -- Check dimensions
    SET @v_dimensions = 'XY' 
                        + case when @p_linestring1.HasZ=1 then 'Z' else '' end +
                        + case when @p_linestring1.HasM=1 then 'M' else '' end ;
    SET @v_dimensions2 = 'XY' 
                         + case when @p_linestring2.HasZ=1 then 'Z' else '' end +
                         + case when @p_linestring2.HasM=1 then 'M' else '' end ;
    IF ( @v_dimensions <> @v_Dimensions2 )
      Return @p_linestring1;

    SET @v_round_xy      = ISNULL(@p_round_xy,3);
    SET @v_round_zm      = ISNULL(@p_round_zm,2);

    -- ******************************************************************************
    -- Process 
    --
    --IF ( @v_dimensions = 'XY' )
    --  Return @p_linestring1.STUnion(@p_linestring2);

    SET @v_wkt          = '';

    IF ( @v_geometryType1 = 'MultiLineString' ) 
    BEGIN
      -- Find Element of MultiLineString that has first Equals relationship
      SET @v_geomn      = 1;
      SET @v_NumGeoms   = @v_linestring1.STNumGeometries();
      SET @v_wkt        = 'MULTILINESTRING (';
      SET @v_appended   = 0;
      -- Loop over all geometries or curves ....
      WHILE ( @v_geomn <= @v_NumGeoms )
      BEGIN
        -- Extract appropriate subelement
        SET @v_linestring1 = @p_linestring1.STGeometryN(@v_geomn);
        IF ( [$(owner)].[STEquals](@v_linestring1.STEndPoint(),  @v_linestring2.STStartPoint(),@v_round_xy,@v_round_zm,@v_round_zm) = 1 
          OR [$(owner)].[STEquals](@v_linestring1.STStartPoint(),@v_linestring2.STEndPoint(),  @v_round_xy,@v_round_zm,@v_round_zm) = 1 
          OR [$(owner)].[STEquals](@v_linestring1.STStartPoint(),@v_linestring2.STStartPoint(),@v_round_xy,@v_round_zm,@v_round_zm) = 1 
          OR [$(owner)].[STEquals](@v_linestring1.STEndPoint(),  @v_linestring2.STEndPoint(),  @v_round_xy,@v_round_zm,@v_round_zm) = 1 )
        BEGIN
          -- Test relationship and add to current linestring
          SET @v_geometry = [$(owner)].[STAppend] ( @v_linestring1, @v_linestring2, @v_round_xy, @v_round_zm );
          IF ( @v_geometry is not null ) 
          BEGIN
            SET @v_appended      = 1;
            SET @v_wkt_remainder = @v_geometry.AsTextZM();
            -- Get rid of LINESTRING token
            SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX('(',@v_wkt_remainder),LEN(@v_wkt_remainder));
            -- Add to current WKT for all parts
            SET @v_wkt           = @v_wkt + case when @v_geomn > 1 then ',' else '' end + @v_wkt_remainder;
          END;
        END
        ELSE
        BEGIN
          SET @v_wkt_remainder = @v_linestring1.AsTextZM();
          -- Get rid of LINESTRING token
          SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX('(',@v_wkt_remainder),LEN(@v_wkt_remainder));
          -- Add to current WKT for all parts
          SET @v_wkt           = @v_wkt + case when @v_geomn > 1 then ',' else '' end + @v_wkt_remainder;
        END;
        SET @v_geomn = @v_geomn + 1;
      END;
      -- Return geometry
      IF ( @v_appended = 0 )
      BEGIN
        SET @v_wkt_remainder = @v_linestring2.AsTextZM();
        -- Get rid of LINESTRING token
        SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX('(',@v_wkt_remainder),LEN(@v_wkt_remainder));
        -- Add to current WKT for all parts
        SET @v_wkt           = @v_wkt + ',' + @v_wkt_remainder;
      END;
      Return geometry::STGeomFromText(@v_wkt 
                                      + 
                                      ')',
                                      @v_linestring1.STSrid);
    END;

    IF ( @v_GeometryType1 = @v_GeometryType2 )
    BEGIN
      -- 1. Share start/end point?
      -- Must Round to ensure match
      IF ( [$(owner)].[STEquals](@v_linestring1.STEndPoint(),
                            @v_linestring2.STStartPoint(),
                            @v_round_xy,
                            @v_round_zm,
                            @v_round_zm) = 1 )
      BEGIN
        -- Add Second to End of First  ....
        SET @v_wkt_remainder = @v_linestring2.AsTextZM();
        SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX(',',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));
        SET @v_wkt           = REPLACE(@v_linestring1.AsTextZM(),')',',') + @v_wkt_remainder;
        -- Return geometry
        Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
      END;

      -- 2. Start / End
      IF ( [$(owner)].[STEquals](@v_linestring1.STStartPoint(),
                            @v_linestring2.STEndPoint(),
                            @v_round_xy,
                            @v_round_zm,
                            @v_round_zm) = 1 )
      BEGIN
        -- Add first to End of second....
        SET @v_wkt_remainder = @v_linestring1.AsTextZM();
        SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX(',',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));
        SET @v_wkt           = REPLACE(@v_linestring2.AsTextZM(),')',',') + @v_wkt_remainder;
        -- Return geometry
        Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
      END;

      -- 3. Start / Start
      IF ( [$(owner)].[STEquals](@v_linestring1.STStartPoint(),
                            @v_linestring2.STStartPoint(),
                            @v_round_xy,
                            @v_round_zm,
                            @v_round_zm) = 1 )
      BEGIN
        -- Add Second to Reverse of First....
        SET @v_reversed_line = [$(owner)].[STReverse] (@v_linestring1,@v_round_xy,@v_round_zm);
        SET @v_wkt_remainder = @v_linestring2.AsTextZM();
        SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX(',',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));
        SET @v_wkt           = REPLACE(@v_reversed_line.AsTextZM(),')',',') + @v_wkt_remainder;
        -- Return geometry
        Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
      END;

      -- 4. End / End
      IF ( [$(owner)].[STEquals](@v_linestring1.STEndPoint(),
                            @v_linestring2.STEndPoint(),
                            @v_round_xy,
                            @v_round_zm,
                            @v_round_zm) = 1 )
      BEGIN
        -- Add reverse of Second to end of First ....
        SET @v_reversed_line = [$(owner)].[STReverse] (@v_linestring2,@v_round_xy,@v_round_zm);
        SET @v_wkt_remainder = @v_reversed_line.AsTextZM();
        SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX(',',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));
        SET @v_wkt_remainder = REPLACE(REPLACE(@v_wkt_remainder,'((','('),'))',')');
        SET @v_wkt           = REPLACE(@v_linestring1.AsTextZM(),')',',') + @v_wkt_remainder;
        -- Return geometry
        Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
      END;

      IF ( @v_GeometryType1 = 'CircularString' and @v_GeometryType2 = 'CircularString' )
        -- CircularString combinations result in a GeometryCollection (why not MultiCurve?)
        SET @v_wkt = 'GEOMETRYCOLLECTION ('
                     +
                     @v_linestring1.AsTextZM()
                     +
                     ','
                     +
                     @v_linestring2.AsTextZM()
                     +
                     ')'
      -- Return geometry
      ELSE
        -- Combinations result in a multilinestring
        SET @v_wkt = 'MULTILINESTRING ('
                     +
                     REPLACE(@v_linestring1.AsTextZM(),'LINESTRING','')
                     +
                     ','
                     +
                     REPLACE(@v_linestring2.AsTextZM(),'LINESTRING','')
                     +
                     ')';
      Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
    END;

    -- We have processed situations where both are LINESTRING or CIRCULARSTRING
    -- What is left is a LINESTRING and a CIRCULARSTRING ...

    --
    -- When combined these create COMPOUNDCURVE geometries.
    -- SQL Server's STUnion creates COMPOUNDCURVE(CIRCULARSTRING(),()) when points match even if CIRCULARSTRING second
    -- Except when DISJOINT then GEOMETRYCOLLECTION
    --
    -- 1. Share start/end point?
    -- Must Round to ensure match
    IF ( [$(owner)].[STEquals](@v_linestring1.STEndPoint(),
                          @v_linestring2.STStartPoint(),
                          @v_round_xy,
                          @v_round_zm,
                          @v_round_zm) = 1 )
    BEGIN
      -- Add Second to End of First  ....
      SET @v_wkt_remainder = @v_linestring2.AsTextZM();
      IF ( @v_linestring2.STGeometryType() = 'LineString' ) 
      BEGIN
        -- Get rid of LINESTRING WKT prefix
        SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX('(',@v_wkt_remainder),LEN(@v_wkt_remainder)); 
        SET @v_wkt_remainder = REPLACE(REPLACE(@v_wkt_remainder,'((','('),'))',')');
      END;
      SET @v_wkt = @v_linestring1.AsTextZM();
      IF ( @v_linestring1.STGeometryType() = 'CompoundCurve' ) 
      BEGIN
        -- Remove CompundCurve Tag
        SET @v_wkt = SUBSTRING(@v_wkt,CHARINDEX('(',@v_wkt)+1,LEN(@v_wkt));
        SET @v_wkt = REPLACE(REPLACE(@v_wkt,'))',')'),'((','(');
      END;
      SET @v_wkt   = 'COMPOUNDCURVE (' + REPLACE(@v_wkt + ',' + @v_wkt_remainder,'LINESTRING','') + ')';
      -- Return geometry
      Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
    END;

    -- 2. Start / Start
    IF ( [$(owner)].[STEquals](@v_linestring1.STStartPoint(),
                          @v_linestring2.STStartPoint(),
                          @v_round_xy,
                          @v_round_zm,
                          @v_round_zm) = 1 )
    BEGIN
      -- Reverse first and add second to its end ...
      SET @v_reversed_line = [$(owner)].[STReverse] (@v_linestring1,@v_round_xy,@v_round_zm);

      SET @v_wkt = @v_reversed_line.AsTextZM();
      IF ( @v_reversed_line.STGeometryType() = 'CompoundCurve' ) 
      BEGIN
        -- Get rid of COMPOUNDCURVE WKT Wrap
        SET @v_wkt = SUBSTRING(@v_wkt,CHARINDEX('(',@v_wkt)+1,LEN(@v_wkt));
        SET @v_wkt = REPLACE(REPLACE(@v_wkt,'))',')'),'((','(');
      END;

      SET @v_wkt_remainder           = @v_linestring2.AsTextZM();
      IF ( @v_linestring2.STGeometryType() = 'CompoundCurve' ) 
      BEGIN
        SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));
        SET @v_wkt_remainder = REPLACE(REPLACE(@v_wkt_remainder,'))',')'),'((','(');
      END;
      SET @v_wkt   = 'COMPOUNDCURVE (' + REPLACE(@v_wkt + ',' + @v_wkt_remainder ,'LINESTRING','')  + ')';
      -- Return geometry
      Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
    END;

    -- 3. Start / End
    IF ( [$(owner)].[STEquals](@v_linestring1.STStartPoint(),
                          @v_linestring2.STEndPoint(),
                          @v_round_xy,
                          @v_round_zm,
                          @v_round_zm) = 1 )
    BEGIN
      -- Add Reverse of Second to Reverse of First....
      SET @v_reversed_line = [$(owner)].[STReverse](@v_linestring1,@v_round_xy,@v_round_zm);
      SET @v_wkt = @v_reversed_line.AsTextZM();
      IF ( @v_reversed_line.STGeometryType() = 'CompoundCurve' ) 
      BEGIN
        -- Get rid of COMPOUNDCURVE WKT Wrap
        SET @v_wkt = SUBSTRING(@v_wkt,CHARINDEX('(',@v_wkt)+1,LEN(@v_wkt));
        SET @v_wkt = REPLACE(REPLACE(@v_wkt,'))',')'),'((','(');
      END;

      SET @v_reversed_line = [$(owner)].[STReverse](@v_linestring2,@v_round_xy,@v_round_zm);
      SET @v_wkt_remainder = @v_reversed_line.AsTextZM();
      IF ( @v_reversed_line.STGeometryType() = 'CompoundCurve' ) 
      BEGIN
        -- Remove COMPOUNDCURVE WKT Prefix
        SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));
        SET @v_wkt_remainder = REPLACE(REPLACE(@v_wkt_remainder,'))',')'),'((','(');
      END;
      SET @v_wkt   = 'COMPOUNDCURVE (' + REPLACE(@v_wkt + ',' + @v_wkt_remainder ,'LINESTRING','')  + ')';
      -- Return geometry
      Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
    END;

    -- 4. End / End
    IF ( [$(owner)].[STEquals](@v_linestring1.STEndPoint(),
                          @v_linestring2.STEndPoint(),
                          @v_round_xy,
                          @v_round_zm,
                          @v_round_zm) = 1 )
    BEGIN
      -- Add Reverse of Second to End of First ....
      -- First
      SET @v_wkt = @v_linestring1.AsTextZM();
      IF ( @v_linestring1.STGeometryType() = 'CompoundCurve' ) 
      BEGIN
        SET @v_wkt = SUBSTRING(@v_wkt,CHARINDEX('(',@v_wkt)+1,LEN(@v_wkt));
        SET @v_wkt = REPLACE(REPLACE(@v_wkt,'))',')'),'((','(');
      END;
      -- Second
      SET @v_reversed_line = [$(owner)].[STReverse] (@v_linestring2,@v_round_xy,@v_round_zm);
      SET @v_wkt_remainder = @v_reversed_line.AsTextZM();
      IF ( @v_linestring1.STGeometryType() = 'CompoundCurve' ) 
      BEGIN
        SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));
        SET @v_wkt_remainder = REPLACE(REPLACE(@v_wkt_remainder,'))',')'),'((','(');
      END;
      SET @v_wkt   = 'COMPOUNDCURVE (' + REPLACE(@v_wkt + ',' + @v_wkt_remainder ,'LINESTRING','')  + ')';
      -- Return geometry
      Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
    END;

    -- CircularString combinations result in a GeometryCollection (why not MultiCurve?)
    SET @v_wkt = 'GEOMETRYCOLLECTION ('
                 +
                 @v_linestring1.AsTextZM()
                 +
                 ','
                 +
                 @v_linestring2.AsTextZM()
                 +
                 ')';
    -- Return geometry
    Return geometry::STGeomFromText(@v_wkt,@v_linestring1.STSrid);
  End;
End;
GO

