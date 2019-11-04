USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STGeometry2MBR]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STGeometry2MBR];
  PRINT 'Dropped [$(owner)].[STGeometry2MBR] ...';
END;
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STGeography2MBR]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STGeography2MBR];
  PRINT 'Dropped [$(owner)].[STGeography2MBR] ...';
END;
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STMBR2Geometry]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STMBR2Geometry];
  PRINT 'Dropped [$(owner)].[STMBR2Geometry] ...';
END;
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STMBR2Geography]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STMBR2Geography];
  PRINT 'Dropped [$(owner)].[STMBR2Geography] ...';
END;
GO

IF EXISTS (
  SELECT * 
    FROM sysobjects 
   WHERE id = object_id(N'[$(owner)].[STMBRLongestSide]') 
     AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STMBRLongestSide];
  PRINT 'Dropped [$(owner)].[STMBRLongestSide] ...';
END;
GO

IF EXISTS (
  SELECT * 
    FROM sysobjects 
   WHERE id = object_id(N'[$(owner)].[STMBRShortestSide]') 
     AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STMBRShortestSide];
  PRINT 'Dropped [$(owner)].[STMBRShortestSide] ...';
END;
GO

/* ****************************************************************************** */

Print 'Creating [$(owner)].[STGeometry2MBR] ....';
GO

CREATE FUNCTION [$(owner)].[STGeometry2MBR]
(
  @p_geometry geometry
)
returns @table table
(
  minx Float,
  miny Float,
  maxx Float,
  maxy Float
)
as
/****f* MBR/STGeometry2MBR (2008)
 *  NAME
 *    STGeometry2MBR - Returns lower left and upper right coordinates of supplied geoemtry's Envelope.
 *  SYNOPSIS
 *    Function STGeometry2MBR (
 *       @p_geometry geometry
 *     )
 *     Returns @table TABLE 
 *     (
 *        minx Float,
 *        miny Float,
 *        maxx Float,
 *        maxy Float
 *     ) 
 *  EXAMPLE
 *
 *    SELECT t.minx, t.miny, t.maxx, t.maxy
 *      FROM [$(owner)].[STGeometry2MBR](geometry::STGeomFromText('LINESTRING(0 0,0.1 0.1,0.5 0.5,0.8 0.8,1 1)',0)) as t
 *    GO
 *    minx miny maxx maxy
 *    ---- ---- ---- ----
 *       0    0    1    1
 *
 *  DESCRIPTION
 *    Supplied with a non-NULL geometry, this function returns the ordinates of the lower left and upper right corners of the geometries STEnvelope/MBR. 
 *  INPUTS
 *    @p_geometry (geometry) - Any geometry object type.
 *  RESULT
 *    Table (Array) of Floats
 *      minx (float) - X Ordinate of Lower Left Corner of Geometry MBR.
 *      miny (float) - Y Ordinate of Lower Left Corner of Geometry MBR.
 *      maxx (float) - X Ordinate of Upper Right Corner of Geometry MBR.
 *      maxy (float) - Y Ordinate of Upper Right Corner of Geometry MBR.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Aug 2008 - Converted to SQL Server 2008
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
   If ( @p_geometry is null )
     Return;
   INSERT INTO @table ( minx, miny, maxx, maxy ) 
   VALUES(@p_geometry.STEnvelope().STPointN(1).STX,
          @p_geometry.STEnvelope().STPointN(1).STY,
          @p_geometry.STEnvelope().STPointN(3).STX,
          @p_geometry.STEnvelope().STPointN(3).STY);
   Return;
End;
Go

Print 'Creating [$(owner)].[STGeography2MBR] ....';
GO

CREATE FUNCTION [$(owner)].[STGeography2MBR]
(
  @p_geography geography
)
Returns @table table 
(
  minx  Float,
  miny  Float,
  maxx  Float,
  maxy  Float
)
As
/****f* MBR/STGeography2MBR (2008)
 *  NAME
 *    STGeography2MBR - Returns lower left and upper right coordinates of supplied geography's Envelope.
 *  SYNOPSIS
 *    Function STGeography2MBR (
 *       @p_geography geography
 *     )
 *     Returns @table TABLE 
 *     (
 *        minx Float,
 *        miny Float,
 *        maxx Float,
 *        maxy Float
 *     ) 
 *  EXAMPLE
 *
 *    SELECT t.minx, t.miny, t.maxx, t.maxy
 *      FROM [$(owner)].[STGeography2MBR](geography::STGeogFromText('LINESTRING(0 0,0.1 0.1,0.5 0.5,0.8 0.8,1 1)',4326)) as t
 *    GO
 *    minx miny maxx maxy
 *    ---- ---- ---- ----
 *       0    0    1    1
 *
 *  DESCRIPTION
 *    Supplied with a non-NULL geometry, this function returns the ordinates of the lower left and upper right corners of the geography's STEnvelope/MBR. 
 *  INPUTS
 *    @p_geography (ge-graphy) - Any geography object type.
 *  RESULT
 *    Table (Array) of Floats
 *      minx (float) - X Ordinate of Lower Left Corner of Geography's MBR.
 *      miny (float) - Y Ordinate of Lower Left Corner of Geography's MBR.
 *      maxx (float) - X Ordinate of Upper Right Corner of Geography's MBR.
 *      maxy (float) - Y Ordinate of Upper Right Corner of Geography's MBR.
 *  NOTES
 *    Uses [$(owner)].[STToGeometry]
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Aug 2008 - Converted to SQL Server 2008
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
   Declare
     @v_geometry geometry;
   If ( @p_geography is null )
     Return;
   SET @v_geometry = [$(owner)].[STToGeometry](@p_geography,@p_geography.STSrid);
   IF ( @v_geometry.STIsValid() = 0 ) 
     SET @v_geometry = @v_geometry.MakeValid();
   INSERT INTO @table ( minx, miny, maxx, maxy ) 
   VALUES(@v_geometry.STEnvelope().STPointN(1).STX,
          @v_geometry.STEnvelope().STPointN(1).STY,
          @v_geometry.STEnvelope().STPointN(3).STX,
          @v_geometry.STEnvelope().STPointN(3).STY);
   Return;
End;
Go

Print 'Creating [$(owner)].[STMBR2Geometry] ...';
GO

CREATE FUNCTION [$(owner)].[STMBR2Geometry] 
(
  @p_minx     float,
  @p_miny     float,
  @p_maxx     float,
  @p_maxy     float,
  @p_srid     Int,
  @p_round_xy int = 3 
)
Returns geometry
As
/****f* MBR/STMBR2Geometry (2008)
 *  NAME
 *    STMBR2Geometry - Given lower left and upper right coordinates of geometry's envelope/mbr this function returns a 5 point polygon geometry.
 *  SYNOPSIS
 *    Function STMBR2Geometry (
 *       @p_minx    Float,
 *       @p_miny    Float,
 *       @p_maxx    Float,
 *       @p_maxy    Float
 *       @p_srid     Int,
 *       @p_round_xy int = 3 
 *     )
 *     Returns geometry
 *  EXAMPLE
 *
 *    SELECT [$(owner)].[STMBR2Geometry](0,0,1,1,0,3)',0)).STAsText() as polygon
 *    GO
 *    polygon
 *    POLYGON((0 0,1 0,1 1,0 1,0 0))
 *
 *  DESCRIPTION
 *    Given lower left and upper right coordinates of geometry's envelope/mbr this function returns a 5 point polygon geometry.
 *    The resultant polygons XY ordinates are rounded to the supplied value. 
 *    The SRID should be a valid projected SRID.
 *  INPUTS
 *    @p_minx   (float) - X Ordinate of Lower Left Corner of Geometry MBR.
 *    @p_miny   (float) - Y Ordinate of Lower Left Corner of Geometry MBR.
 *    @p_maxx   (float) - X Ordinate of Upper Right Corner of Geometry MBR.
 *    @p_maxy   (float) - Y Ordinate of Upper Right Corner of Geometry MBR.
 *    @p_srid     (int) - Valid projected SRID.
 *    @p_round_xy (int) - Value used to round XY ordinates to fixed decimal digits of precision.
 *  RESULT
 *    @p_geometry (geometry) - Polygon geometry with single exterior ring.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Aug 2008 - Converted to SQL Server 2008
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare 
    @v_round_xy int = ISNULL(@p_round_xy,3);
  Return geometry::STGeomFromText(
         'POLYGON((' + 
                 STR(@p_minx,38,@v_round_xy) + ' ' + STR(@p_miny,38,@v_round_xy) + ',' +
                 STR(@p_maxx,38,@v_round_xy) + ' ' + STR(@p_miny,38,@v_round_xy) + ',' +
                 STR(@p_maxx,38,@v_round_xy) + ' ' + STR(@p_maxy,38,@v_round_xy) + ',' +
                 STR(@p_minx,38,@v_round_xy) + ' ' + STR(@p_maxy,38,@v_round_xy) + ',' +
                 STR(@p_minx,38,@v_round_xy) + ' ' + STR(@p_miny,38,@v_round_xy) + '))',
                 @p_srid);
End;
Go

Print 'Creating [$(owner)].[STMBR2Geography] ...';
GO

CREATE FUNCTION [$(owner)].[STMBR2Geography]
(
  @p_minx     float,
  @p_miny     float,
  @p_maxx     float,
  @p_maxy     float,
  @p_srid     Int,
  @p_round_ll int = 8 
)
Returns geography
As
/****f* MBR/STMBR2Geography (2008)
 *  NAME
 *    STMBR2Geography - Given lower left and upper right coordinates of geometry's envelope/mbr this function returns a 5 point polygon geometry.
 *  SYNOPSIS
 *    Function STMBR2Geography (
 *       @p_minx     Float,
 *       @p_miny     Float,
 *       @p_maxx     Float,
 *       @p_maxy     Float
 *       @p_srid     Int,
 *       @p_round_ll int = 3 
 *     )
 *     Returns geometry
 *  EXAMPLE
 *
 *    SELECT [$(owner)].[STMBR2Geography](0,0,1,1,0,3)',0)).STAsText() as polygon
 *    GO
 *    polygon
 *    POLYGON((0 0,1 0,1 1,0 1,0 0))
 *
 *  DESCRIPTION
 *    Given lower left and upper right coordinates of geometry's envelope/mbr this function returns a 5 point polygon geometry.
 *    The resultant polygons XY ordinates are rounded to the supplied value. 
 *    The SRID should be a valid projected SRID.
 *  INPUTS
 *    @p_minx   (float) - X Ordinate of Lower Left Corner of Geography MBR.
 *    @p_miny   (float) - Y Ordinate of Lower Left Corner of Geography MBR.
 *    @p_maxx   (float) - X Ordinate of Upper Right Corner of Geography MBR.
 *    @p_maxy   (float) - Y Ordinate of Upper Right Corner of Geography MBR.
 *    @p_srid     (int) - Valid projected SRID.
 *    @p_round_ll (int) - Value used to round Latitude/Longitude ordinates to fixed decimal digits of precision.
 *  RESULT
 *    @p_geometry (geometry) - Polygon geometry with single exterior ring.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Aug 2008 - Converted to SQL Server 2008
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare 
    @v_round_ll int = ISNULL(@p_round_ll,8);
  Return geography::STGeomFromText(
         'POLYGON((' + 
                 STR(@p_minx,38,@v_round_ll) + ' ' + STR(@p_miny,38,@v_round_ll) + ',' +
                 STR(@p_maxx,38,@v_round_ll) + ' ' + STR(@p_miny,38,@v_round_ll) + ',' +
                 STR(@p_maxx,38,@v_round_ll) + ' ' + STR(@p_maxy,38,@v_round_ll) + ',' +
                 STR(@p_minx,38,@v_round_ll) + ' ' + STR(@p_maxy,38,@v_round_ll) + ',' +
                 STR(@p_minx,38,@v_round_ll) + ' ' + STR(@p_miny,38,@v_round_ll) + '))',
                 @p_srid);
End;
Go

PRINT 'Creating Function [$(owner)].[STMBRShortestSide]...';
GO

CREATE FUNCTION [$(owner)].[STMBRShortestSide]
(
  @p_geometry geometry
)
returns float
as
/****f* MBR/STMBRShortestSide (2008)
 *  NAME
 *    STMBRShortestSide - Returns length of shortest side of Envelope/MBR of supplied geometry.
 *  SYNOPSIS
 *    Function [$(owner)].[STMBRShortestSide] (
 *       @p_geometry geometry
 *     )
 *     Returns Float
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('POLYGON ((0 0,100 0,100 10,0 10,0 0))',0) as geom
 *    )
 *    SELECT [$(owner)].[STMBRShortestSide] (a.geom) as length
 *      FROM data as a;
 *    GO
 *
 *    length 
 *    ------
 *     100.0
 *
 *  DESCRIPTION
 *    Supplied with a non-NULL geometry, this function returns the length of the shortest side of its Envelope.
 *  INPUTS
 *    @p_geometry (geometry) - Any geometry object type.
 *  RESULT
 *    length (float) - length of shortest side of envelope
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Oct 2019 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  Declare
   @v_mbr        geometry,
   @v_length        float,
   @v_length_side_1 float,
   @v_length_side_2 float;
  Begin
    If ( @p_geometry is null )
      Return NULL;
    If ( @p_geometry.STGeometryType() = 'Point' )
      Return 0.0;
    set @v_mbr = @p_geometry.STEnvelope();
    set @v_length_side_1 = @v_mbr.STPointN(1).STDistance(@v_mbr.STPointN(2));
    set @v_length_side_2 = @v_mbr.STPointN(2).STDistance(@v_mbr.STPointN(3));
    set @v_length        = case when @v_length_side_1 < @v_length_side_2
                                then @v_length_side_1
                                else @v_length_side_2
                            end;
    Return @v_length;
  End;
End;
Go

PRINT 'Creating Function [$(owner)].[STMBRLongestSide]...';
GO

CREATE FUNCTION [$(owner)].[STMBRLongestSide]
(
  @p_geometry geometry
)
returns float
as
/****f* MBR/STMBRLongestSide (2008)
 *  NAME
 *    STMBRLongestSide - Returns length of shortest side of Envelope/MBR of supplied geometry.
 *  SYNOPSIS
 *    Function [$(owner)].[STMBRLongestSide] (
 *       @p_geometry geometry
 *     )
 *     Returns Float
 *  EXAMPLE
 *    with data as (
 *      select geometry::STGeomFromText('POLYGON ((0 0,100 0,100 10,0 10,0 0))',0) as geom
 *    )
 *    SELECT [$(owner)].[STMBRLongestSide] (a.geom) as length
 *      FROM data as a;
 *    GO
  *
 *    length 
 *    ------
 *      10.0
 *
 *  DESCRIPTION
 *    Supplied with a non-NULL geometry, this function returns the length of the longest side of its Envelope.
 *  INPUTS
 *    @p_geometry (geometry) - Any geometry object type.
 *  RESULT
 *    length (float) - length of shortest side of envelope
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Oct 2019 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
begin
  Declare
   @v_mbr        geometry,
   @v_length        float,
   @v_length_side_1 float,
   @v_length_side_2 float;
  Begin
    If ( @p_geometry is null )
      Return NULL;
    If ( @p_geometry.STGeometryType() = 'Point' )
      Return 0.0;
    set @v_mbr = @p_geometry.STEnvelope();
    set @v_length_side_1 = @v_mbr.STPointN(1).STDistance(@v_mbr.STPointN(2));
    set @v_length_side_2 = @v_mbr.STPointN(2).STDistance(@v_mbr.STPointN(3));
    set @v_length        = case when @v_length_side_1 > @v_length_side_2
                                then @v_length_side_1
                                else @v_length_side_2
                           end;
   Return @v_length;
  End;
End;
Go

PRINT '============';
PRINT 'Testing ....';
GO

select f.*
  from [$(owner)].[STGeometry2MBR](geometry::STGeomFromText('POLYGON((0 0,10 0,10 20,0 20,0 0))',0)) as f;

-- First, let's create a simple polygon geometry
--
select [$(owner)].[STMBR2Geometry](0,0,100,100,28355,0).STAsText() as geomWKT
GO

-- Or a polyon geography
select [$(owner)].[STMBR2Geography](147.8347938734,-32.34937894309,148.239230982,-31.93337,4283,8).STAsText() as geomWKT
GO

-- Now, let's create a polygon with a hole
--
select [$(owner)].[STMBR2Geometry] (0,0,100,100,28355,0)
                 .STDifference([$(owner)].[STMBR2Geometry] (40,40,60,60,28355,0))
                 .STAsText() as geomWKT
GO

-- Now let's create a multipolygon with a hole
--
select [$(owner)].[STMBR2Geometry] (0,0,100,100,28355,0)
                 .STDifference([$(owner)].[STMBR2Geometry] (40,40,60,60,28355,0))
                 .STUnion     ([$(owner)].[STMBR2Geometry] (200,200,400,400,28355,0))
                 .STAsText() as geomWKT
GO

-- Finally, let's create a polygon with a hole using the mbr2geography function
--
select [$(owner)].[STMBR2Geography] (147,-44,148,-43,4326,0)
                 .STDifference([$(owner)].[STMBR2Geography] (147.4,-43.6,147.6,-43.2,4326,2))
                 .STAsText() as geogWKT
GO

with data as (
  select geometry::STGeomFromText('POLYGON ((0 0,100 0,100 10,0 10,0 0))',0) as geom
)
SELECT [$(owner)].[STMBRLongestSide] (a.geom) as length
  FROM data as a
GO

with data as (
  select geometry::STGeomFromText('POLYGON ((0 0,100 0,100 10,0 10,0 0))',0) as geom
)
SELECT [$(owner)].[STMBRShortestSide] (a.geom) as length
  FROM data as a
GO

QUIT
GO

