SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '***********************************************************************************';
PRINT 'Database Schema Variables are: Cogo($(cogoowner)), LRS($(lrsowner)) Owner($(owner))';
GO

IF EXISTS (
    SELECT *
      FROM sysobjects
     WHERE id = object_id(N'[$(lrsowner)].[STFilterLineSegmentByLength]')
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(lrsowner)].[STFilterLineSegmentByLength];
  PRINT 'Dropped [$(lrsowner)].[STFilterLineSegmentByLength] ...';
END;
GO

PRINT 'Creating [$(lrsowner)].[STFilterLineSegmentByLength] ...';
GO

CREATE FUNCTION [$(lrsowner)].[STFilterLineSegmentByLength]
(
  @p_linestring   geometry,
  @p_start_length Float,
  @p_end_length   Float = 0.5,
  @p_round_xy     int = 3,
  @p_round_zm     int = 2
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
/****f* LRS/STFilterLineSegmentByLength (2012)
 *  NAME
 *    STFilterLineSegmentByLength -- This function detects and returns all segments (2 point linestring, 3 point circularString) that fall within the defined by the range @p_start_length .. @p_end_length .
 *  SYNOPSIS 
 *    Function [$(lrsowner)].[STFilterLineSegmentByLength] (
 *               @p_linestring   geometry,
 *               @p_start_length Float,
 *               @p_end_length   Float = null,
 *               @p_round_xy     int   = 3,
 *               @p_round_zm     int   = 2
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
 *    If then analyses each segment to see if it falls within the range defined by @p_start_length .. @p_end_length.
 *    If the segment falls within the range, it is returned.
 *    If a segment's end point = @p_start_length then it is not returned but the next segment, whose StartPoint = @p_start_length is returned.
 *  NOTES
 *    Supports linestrings with CircularString elements.
 *  INPUTS
 *    @p_linestring (geometry) - Linestring geometry.
 *    @p_start_length  (float) - Length defining start point of located geometry.
 *    @p_end_length    (float) - Length defining end point of located geometry.
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
    -- Parameters
    @v_start_length      float,
    @v_end_length        float,
    @v_MainGeomType      varchar(30),
    @v_round_xy          int,
    @v_round_zm          int,
    -- Iteration Variables
    @v_GeomType          varchar(30),
    @v_LastGeomType      varchar(30),
    @v_id                int = 1,
    @v_segment_id        int = 0,
    @v_subelement_id     int = 0,
    @v_geomn             int = 0,
    @v_CurveN            int = 0,
    @v_NumGeoms          int = 0,
    @v_NumElements       int = 0,
    @v_first_pointN      int = 0,
    @v_second_pointN     int = 0,
    -- Segment Variables
    @v_start_point       geometry,
    @v_end_point         geometry,
    @v_segment_geom      geometry,
    @v_segment_length    float,
    @v_cumulative_length float,
    @v_temp_length       float,
    -- Extracted Element/SUbElement Geometries
    @v_curve             geometry,
    @v_geom              geometry;
  Begin
    If ( @p_linestring is NULL )
      Return;

    SET @v_MainGeomType = @p_linestring.STGeometryType();
    IF ( @v_MainGeomType NOT IN ('MultiLineString','LineString','CircularString','CompoundCurve') )
      Return;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    -- Set up length filtering variables...
    SET @v_cumulative_length = 0.0;
    SET @v_start_length      = case when @p_start_length is null then                      0.0 else ABS(@p_start_length) end;
    SET @v_end_length        = case when @p_end_length   is null then @p_linestring.STLength() else ABS(@p_end_length)   end;
    -- Flip lengths if required
    IF ( @v_start_length > @v_end_length )
    BEGIN
      SET @v_temp_length  = @v_start_length;
      SET @v_start_length = @v_end_length;
      SET @v_end_length   = @v_temp_length;
    END;

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
          SET @v_SubElement_id = @v_SubElement_id + 1;
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
          SET @v_segment_geom   = [$(owner)].[STMakeLine]( @v_start_point, @v_end_point,@v_round_xy,@v_round_zm );
          SET @v_segment_length = @v_segment_geom.STLength();

          -- Now save if Length range overlaps user input range...
          --
          IF ( (@v_start_length     <  (@v_cumulative_length + @v_segment_length) ) 
           OR (@v_cumulative_length >=  @v_end_length) )
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
            ) VALUES ( @v_id                   /*            id */,
                       case when @v_MainGeomType in ('CompoundCurve','MultiLineString' ) 
                            then UPPER(@v_MainGeomType) 
                            else null 
                        end                        /* multi_tag */,
                       @v_NumElements          /*    element_id */,
                       UPPER(@v_geomType)        /* element_tag */, 
                       @v_SubElement_id        /* subelement_id */,
                       null                   /* subelement_tag */,
                       @v_segment_id         /*      segment_id */,
                       @v_start_point.STX,@v_start_point.STY, @v_start_point.Z,@v_start_point.M,
                         @v_end_point.STX,  @v_end_point.STY,   @v_end_point.Z,  @v_end_point.M,
                       @v_segment_length,
                       @v_cumulative_length,
                       case when @p_linestring.HasM=1 then ( @v_end_point.M - @v_start_point.M ) else null end,
                       @v_segment_geom
            );
          END;
          SET @v_cumulative_length = @v_cumulative_length + @v_segment_length;
          IF ( @v_end_length <= @v_cumulative_length )
            RETURN;

          SET @v_id            = @v_id            + 1;
          SET @v_first_pointN  = @v_first_pointN  + 1;
          SET @v_second_pointN = @v_second_pointN + 1;
        END; -- WHILE ( @v_second_pointN <= @v_geom.STNumPoints() )
      END;   --    IF ( @v_GeomType = 'LineString' )
 
      IF ( @v_GeomType = 'CircularString' )
      BEGIN

        SET @v_CurveN   = 1;
        WHILE ( @v_CurveN <= @v_geom.STNumCurves() )
        BEGIN

          SET @v_segment_id     = @v_segment_id + 1;
          SET @v_curve          = @v_geom.STCurveN(@v_CurveN);
          SET @v_segment_length = @v_curve.STLength();
          -- Now save if Length range overlaps user input range...
          -- 
          IF ( (@v_start_length      < (@v_cumulative_length + @v_segment_length) ) 
           OR (@v_cumulative_length >= @v_end_length) )
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
            ) VALUES ( @v_id                   /*            id */,
                       case when @v_MainGeomType in ('CompoundCurve','MultiLineString' ) 
                            then UPPER(@v_MainGeomType) 
                            else null 
                        end                        /* multi_tag */,
                       @v_NumElements          /*    element_id */,
                       UPPER(@v_geomType)        /* element_tag */, 
                       case when @v_MainGeomType = 'CompoundCurve'
                            then @v_SubElement_id
                            else @v_CurveN
                        end                   /*  subelement_id */,
                       NULL                   /* subelement_tag */,
                       @v_segment_id         /*      segment_id */,
                       @v_curve.STPointN(1).STX,@v_curve.STPointN(1).STY,@v_curve.STPointN(1).Z,@v_curve.STPointN(1).M,
                       @v_curve.STPointN(2).STX,@v_curve.STPointN(2).STY,@v_curve.STPointN(2).Z,@v_curve.STPointN(2).M,
                       @v_curve.STPointN(3).STX,@v_curve.STPointN(3).STY,@v_curve.STPointN(3).Z,@v_curve.STPointN(3).M,
                       @v_segment_length,
                       @v_cumulative_length,
                       case when @p_linestring.HasM=1 then ( @v_curve.STPointN(3).M - @v_curve.STPointN(1).M ) else null end,
                       @v_curve
            );
          END;
          SET @v_cumulative_length = @v_cumulative_length + @v_segment_length;
          IF ( @v_end_length <= @v_cumulative_length )
            RETURN;

          SET @v_id     = @v_id     + 1;
          SET @v_CurveN = @v_CurveN + 1;
        END; -- WHILE ( @v_CurveN <= @v_geom.STNumCurves() )
      END;   -- IF ( @v_GeomType = 'CircularString' )

      SET @v_LastGeomType = @v_GeomType;
      SET @v_geomn        = @v_geomn  + 1;

    END; -- WHILE ( @v_geomn <= @v_NumGeoms )
    RETURN;
  END;
END;
GO


