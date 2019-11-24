SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '**********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))' ;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(lrsowner)].[STFilterLineSegmentByMeasure]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFilterLineSegmentByMeasure];
  PRINT 'Dropped [$(lrsowner)].[STFilterLineSegmentByMeasure] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STFilterLineSegmentByMeasure] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFilterLineSegmentByMeasure] 
(
  @p_linestring    geometry,
  @p_start_measure Float = 0.5,
  @p_end_measure   Float = 0.5,
  @p_round_xy      int = 3,
  @p_round_zm      int = 2
)
RETURNS @Segments TABLE
(
  id             int,
  multi_tag      varchar(30),
  element_id     int,
  element_tag    varchar(30),
  subelement_id  int,
  subelement_tag varchar(30),
  segment_id     int,
  sx             float,  /* Start Point */
  sy             float,
  sz             float,
  sm             float,
  mx             float,  /* Mid Point */
  my             float,
  mz             float,
  mm             float,
  ex             float,  /* End Point */
  ey             float,
  ez             float,
  em             float,
  length         float,
  startLength    float,
  measureRange   float,
  geom           geometry  /* Useful if vector is a circular arc */
)
AS
/****f* LRS/STFilterLineSegmentByMeasure (2012)
 *  NAME
 *    STFilterLineSegmentByMeasure -- This function detects and returns all segments (2 point linestring, 3 point circularString) that fall within the defined by the range @p_start_measure .. @p_end_measure .
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFilterLineSegmentByMeasure] (
 *               @p_linestring    geometry,
 *               @p_start_measure Float,
 *               @p_end_measure   Float = null,
 *               @p_round_xy      int   = 3,
 *               @p_round_zm      int   = 2
 *             )
 *     Returns @Segments TABLE 
 *     (
 *       id             int,
 *       multi_tag      varchar(100),
 *       element_id     int,
 *       element_tag    varchar(100),
 *       subelement_id  int,
 *       subelement_tag varchar(100),
 *       segment_id     int,
 *       sx             float,  
 *       sy             float,
 *       sz             float,
 *       sm             float,
 *       mx             float,  
 *       my             float,
 *       mz             float,
 *       mm             float,
 *       ex             float, 
 *       ey             float,
 *       ez             float,
 *       em             float,
 *       length         float,
 *       startLength    float,
 *       measureRange   float,
 *       geom           geometry
 *     )  
 *  DESCRIPTION
 *    Given a start and end length, this function breaks the input @p_linestring into its fundamental 2 Point LineString or 3 Point CircularStrings.
 *    If then analyses each segment to see if it falls within the range defined by @p_start_measure .. @p_end_measure.
 *    If the segment falls within the range, it is returned.
 *    If a segment's end point = @p_start_measure then it is not returned but the next segment, whose StartPoint = @p_start_measure is returned.
 *  NOTES
 *    Supports linestrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry.
 *    @p_start_measure (float) - Measure defining start point of located geometry.
 *    @p_end_measure   (float) - Measure defining end point of located geometry.
 *    @p_round_xy        (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm        (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    Table (Array) of Indivitual Line Segments:
 *     id             (int)        - Unique identifier starting at segment 1.
 *     multi_tag      (varchar100) - WKT Tag if Multi geometry eg MULTILINESTRING/MULTICURVE/MULTIPOLYGON.
 *     element_id     (int)        - Top level element identifier eg 1 for first polygon in multiPolygon.
 *     element_tag    (varchar100) - WKT Tag for first element eg POLYGON if part of MULTIPOlYGON.
 *     subelement_id  (int)        - SubElement identifier of subelement of element with parts eg OuterRing of Polygon
 *     subelement_tag (varchar100) - WKT Tag for first subelement of element with parts eg OuterRing of Polygon
 *     segment_id     (int)        - Unique identifier starting at segment 1 for each element.
 *     sx             (float)      - Start Point X Ordinate 
 *     sy             (float)      - Start Point Y Ordinate 
 *     sz             (float)      - Start Point Z Ordinate 
 *     sm             (float)      - Start Point M Ordinate
 *     mx             (float)      - Mid Point X Ordinate (Only if CircularString)
 *     my             (float)      - Mid Point Y Ordinate (Only if CircularString)
 *     mz             (float)      - Mid Point Z Ordinate (Only if CircularString)
 *     mm             (float)      - Mid Point M Ordinate (Only if CircularString)
 *     ex             (float)      - End Point X Ordinate 
 *     ey             (float)      - End Point Y Ordinate 
 *     ez             (float)      - End Point Z Ordinate 
 *     em             (float)      - End Point M Ordinate 
 *     length         (float)      - Length of this segment in SRID units
 *     startLength    (float)      - Cumulative Length (from start of geometry) at the start of this segment in SRID units
 *     measureRange   (float)      - Measure Range ie EndM - StartM
 *     geom           (geometry)   - Geometry representation of segment.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_MainGeomType     varchar(30),
    @v_GeomType         varchar(30),
    @v_LastGeomType     varchar(30),
    @v_round_xy         int,
    @v_round_zm         int,
    -- Iteration Variables
    @v_id               int = 1,
    @v_geomn            int = 0,
    @v_CurveN           int = 0,
    @v_SubElement       int = 0,
    @v_segment_id       int = 0,
    @v_NumGeoms         int = 0,
    @v_NumElements      int = 0,
    @v_first_pointN     int = 0,
    @v_second_pointN    int = 0,

    -- Segment Variables
    @v_start_point      geometry,
    @v_end_point        geometry,
    @v_segment_geom     geometry,
    @v_start_measure    float,
    @v_end_measure      float,
    @v_greatest_measure float,
    @v_greatest         float,
    @v_least            float,
    -- Segment length variables
    @v_segment_length   float = 0.0,
    @v_total_length     float = 0.0,
    -- Extracted Element/SUbElement Geometries
    @v_curve            geometry,
    @v_geom             geometry;
  Begin
    If ( @p_linestring is NULL )
      Return;

    IF ( @p_linestring.HasM=0 )
      Return;

    SET @v_MainGeomType = @p_linestring.STGeometryType();
    IF ( @v_MainGeomType NOT IN ('MultiLineString','LineString','CircularString','CompoundCurve' ) )
      Return;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    -- Set up measure filtering variables...
    SET @v_start_measure    = case when @p_start_measure is null          then @p_linestring.STPointN(1).M                           else @p_start_measure end;
    SET @v_end_measure      = case when @p_end_measure   is null          then @p_linestring.STPointN(@p_linestring.STNumPoints()).M else @p_end_measure   end;
    SET @v_greatest_measure = case when @v_start_measure > @v_end_measure then @v_start_measure                                      else @v_end_measure   end;

    -- CompoundCurve objects are made up of N x CircularCurves and/or M x LineStrings.
    -- All accessed via STCurveN (even LineString)

    SET @v_id           = 1;
    SET @v_LastGeomType = 'NULL';
    SET @v_geomn        = 1;
    SET @v_segment_id   = 0;
    SET @v_NumGeoms     = case when @v_MainGeomType in ('CompoundCurve')
                               then @p_linestring.STNumCurves()
                               else @p_linestring.STNumGeometries()
                           end;

    -- Loop over all geometries or curves ....
    WHILE ( @v_geomn <= @v_NumGeoms )
    BEGIN

      -- Extract appropriate subelement
      SET @v_geom = case when @v_MainGeomType = 'CompoundCurve'
                         then @p_linestring.STCurveN(   @v_geomn)
                         else @p_linestring.STGeometryN(@v_geomn)
                     end;

      -- STCurveN extracts subelements as elements if CircularString with more than one curve.
      SET @v_NumElements = case when @v_MainGeomType = 'CompoundCurve'
                                then 1
                                else @v_NumElements + 1
                            end;

      -- Processing depends on sub-element type
      SET @v_GeomType  = @v_geom.STGeometryType();

      -- Even if CompoundCurve has LINESTRING with more than one vector,
      -- STCurveN() API call extracts as many 2 point linestrings as exist in the original LINESTRING subelement.
      -- And as many 3 point CircularStrings as there are in the CircularString subelement.
      --
      IF ( @v_MainGeomType = 'CompoundCurve' )
      BEGIN
        -- Increase SubElement Count only when processing CircularString for first time
        IF ( @v_LastGeomType != @v_GeomType )
          SET @v_SubElement = @v_SubElement + 1;
      END;

      IF ( @v_GeomType = 'LineString' )
      BEGIN

        SET @v_first_pointN      = 1;
        SET @v_second_pointN     = 2;

        WHILE ( @v_second_pointN <= @v_geom.STNumPoints() )
        BEGIN

          SET @v_segment_id     = @v_segment_id + 1;
          SET @v_start_point    = @v_geom.STPointN(@v_first_pointN);
          SET @v_end_point      = @v_geom.STPointN(@v_second_pointN);
          SET @v_segment_geom   = [$(owner)].[STMakeLine](
                                       @v_start_point, 
                                       @v_end_point,
                                       @v_round_xy,
                                       @v_round_zm
                                  );
          SET @v_segment_length = @v_segment_geom.STLength();

          -- Compute and Apply Filter
          SET @v_greatest = case when @v_start_point.M > @v_start_measure then @v_start_point.M else @v_start_measure end;
          SET @v_least    = case when @v_end_point.M   < @v_end_measure   then @v_end_point.M   else @v_end_measure   end;

          -- Now save segment if Measure range overlaps user input range...
          IF ( @v_Greatest <= @v_Least )
          BEGIN
            INSERT INTO @Segments (
                       [id],
                       [multi_tag],
                       [element_id],
                       [element_tag],
                       [subelement_id],
                       [subelement_tag],
                       [segment_id],
                       [sx],[sy],[sz],[sm],
                       [ex],[ey],[ez],[em],
                       [length],
                       [startLength],
                       [measureRange],
                       [geom]
            ) VALUES ( @v_id,
                       case when @v_MainGeomType in ('CompoundCurve','MultiLineString' ) then UPPER(@v_MainGeomType) else null end,
                       @v_NumElements,
                       UPPER(@v_geomType),
                       @v_SubElement,
                       null,
                       @v_segment_id,
                       @v_start_point.STX,@v_start_point.STY, @v_start_point.Z,@v_start_point.M,
                         @v_end_point.STX,  @v_end_point.STY,   @v_end_point.Z,  @v_end_point.M,
                       @v_segment_length, 
                       @v_total_length,
                      (@v_end_point.M - @v_start_point.M),
                       @v_segment_geom
            );
            SET @v_total_length = @v_total_length + @v_segment_length;
            IF ( @v_greatest_measure <=  @v_end_point.M )
              RETURN;
          END;
          SET @v_id            = @v_id            + 1;
          SET @v_first_pointN  = @v_first_pointN  + 1;
          SET @v_second_pointN = @v_second_pointN + 1;
        END;
      END; -- IF ( @v_GeomType = 'LineString' )
 
      IF ( @v_GeomType = 'CircularString' )
      BEGIN

        SET @v_CurveN   = 1;
        WHILE ( @v_CurveN <= @v_geom.STNumCurves() )
        BEGIN
          SET @v_segment_id     = @v_segment_id + 1;
          SET @v_curve          = @v_geom.STCurveN(@v_CurveN);
          SET @v_segment_length = @v_curve.STLength();

          -- Check Filter
          SET @v_greatest = case when @v_start_point.M > @v_start_measure then @v_start_point.M else @v_start_measure end;
          SET @v_least    = case when @v_end_point.M   < @v_end_measure   then @v_end_point.M   else @v_end_measure   end;

          -- Now save if Measure range overlaps user input range...
          IF ( @v_Greatest <= @v_Least )
          BEGIN
            INSERT INTO @Segments (
                       [id],
                       [multi_tag],
                       [element_id],
                       [element_tag],
                       [subelement_id],
                       [subelement_tag],
                       [segment_id],
                       [sx],[sy],[sz],[sm],
                       [mx],[my],[mz],[mm],
                       [ex],[ey],[ez],[em],
                       [length],
                       [startLength],
                       [measureRange],
                       [geom]
            ) VALUES ( @v_id         /*            id */,
                       case when @v_MainGeomType in ('CompoundCurve','MultiLineString' ) then UPPER(@v_MainGeomType) else null end,
                       @v_NumElements /*    element_id */,
                       UPPER(@v_geomType),
                       case when @v_MainGeomType = 'CompoundCurve'
                            then @v_SubElement
                            else @v_CurveN
                        end                   /*  subelement_id */,
                       NULL                   /* subelement_tag */,
                       @v_segment_id         /*      segment_id */,
                       @v_curve.STPointN(1).STX,@v_curve.STPointN(1).STY,@v_curve.STPointN(1).Z,@v_curve.STPointN(1).M,
                       @v_curve.STPointN(2).STX,@v_curve.STPointN(2).STY,@v_curve.STPointN(2).Z,@v_curve.STPointN(2).M,
                       @v_curve.STPointN(3).STX,@v_curve.STPointN(3).STY,@v_curve.STPointN(3).Z,@v_curve.STPointN(3).M,
                       @v_segment_length,
                       @v_total_length,
                       @v_curve.STPointN(3).M - @v_curve.STPointN(1).M,
                       @v_curve
            );
            SET @v_total_length = @v_total_length + @v_segment_length;
            IF ( @v_greatest_measure <=  @v_end_point.M )
              RETURN;
          END;
          SET @v_id     = @v_id     + 1;
          SET @v_CurveN = @v_CurveN + 1;
        END;
      END; -- IF ( @v_GeomType = 'CircularString' )

      SET @v_LastGeomType = @v_GeomType;
      SET @v_geomn        = @v_geomn  + 1;

    END; -- WHILE ( @v_geomn <= @v_NumGeoms )
    RETURN;
END;
END
GO

PRINT 'Testing [$(lrsowner)].[STFilterLineSegmentByMeasure] ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 1 as id, 'SM NULL (set to 1)/ EM NULL (return all segments)' as locateType,[$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,null,null,3,2) as s
union all
select 2 as id, 'SM NULL (set to 1) / EM = 1 (returns first segment)' as locateType,[$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,null,1,3,2) as s
union all
select 3 as id, 'SM/EM Same Mid First Segment (Returns First Segment)' as locateType, [$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,2,2,3,2) as s
union all
select 5 as id, 'SM 5 (First Segment)/EM 10 (last Segment)' as locateType, [$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,5,10,3,2) as s
union all
select 6 as id, 'SM 6 / EM 10 (Last Segment)' as locateType,  [$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,6,10,3,2) as s
union all
select 9 as id, 'SM before First and EM after last point' as locateType, [$(lrsowner)].[STMeasureRange](d.linestring) as mRange,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,0.1,30.0,3,2) as s;

-- MULTILINESTRING 

with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6), (10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))',28355) as linestring
)
select 1 as id, 'Start = First Point Second Segment' as locateType,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,15.61,null,3,2) as s
union all
select 2 as id, 'Start = First Point / End Second Point Second Segment' as locateType,
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,15.61,25.4,3,2) as s
union all
select 3 as id, 'Cross first and second segments',
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,2,6,3,2) as s
union all
select 4 as id, 'Cross first and second segments',
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,2,25,3,2) as s
union all
select 4 as id, 'Cross all segments',
       s.* from data as d cross apply [$(lrsowner)].[STFilterLineSegmentByMeasure](linestring,2,26,3,2) as s;

with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6), (10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))',28355) as linestring
)
select g.intValue        as start_measure,
       g.IntValue + 2.25 as end_measure,
       s.* 
  from data as d 
       cross apply
       [$(owner)].[generate_series](d.lineString.STStartPoint().M, 
                                    round(d.lineString.STEndPoint().M,0,1), 
                                    2) as g
       cross apply 
       [$(lrsowner)].[STFilterLineSegmentByMeasure](d.linestring,g.IntValue,g.IntValue + 2.25,3,2) as s;
GO

with data as (
select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.4 16.3, 3 6.3 1.6 20.2))',0) as linestring
)
select CAST(d.LineString.STGeometryType() as varchar(30)) as gType, 
       d.lineString.STStartPoint().M as start_measure, 
       d.linestring.STEndPoint().M as end_measure, 
       d.linestring 
  from data as d
union all 
select TOP 1 
       s.multi_tag    as gType, 
       g.intValue     as start_measure, 
       g.IntValue+2.5 as end_measure, 
       s.geom.STBuffer(1) as fSegment
  from data as d
       cross apply
       [$(owner)].[generate_series](      d.lineString.STStartPoint().M, 
                                    round(d.lineString.STEndPoint().M,0,1), 
                                    2) as g
       cross apply 
       [$(lrsowner)].[STFilterLineSegmentByMeasure](d.linestring,g.IntValue,g.IntValue + 2.25,3,2) as s;
GO


