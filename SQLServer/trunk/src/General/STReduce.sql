SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STReduce]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STReduce];
  Print 'Dropped [$(owner)].[STReduce] ....';
END;
GO

Print 'Creating [$(owner)].[STReduce]....';
GO

CREATE FUNCTION [$(owner)].[STReduce]
(
  @p_linestring       geometry,
  @p_reduction_length float,
  @p_end              varchar(5) = 'START',
  @p_round_xy         int        = 3,
  @p_round_zm         int        = 2
)
returns geometry
as
/****m* EDITOR/STReduce (2008)
 *  NAME
 *    STReduce -- Function which extends the first or last vertex connected segment of a linestring.
 *  SYNOPSIS
 *    Function STReduce (
 *               @p_linestring       geometry,
 *               @p_reduction_length float,
 *               @p_end              varchar(5),
 *               @p_round_xy         int = 3,
 *               @p_round_zm         int = 2
 *             )
 *     Returns geometry
 *  USAGE
 *    SELECT [$(owner)].[STReduce](geometry::ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),5.0,'START',2,1).AsTextZM() as reducedGeom;
 *    # reducedGeom
 *    'LINESTRING(-4.9 30.2,-3.6 31.5)'
 *  DESCRIPTION
 *    Function that shortens the supplied linestring at either its start or end (p_end) the required length.
 *    The function can apply the reduction at either ends (or both).
 *    The function will remove existing vertices as the linestring is shortened. 
 *    If the linestring reduces to nothing, an error will be thrown by STGeomFromText.
 *    Any computed ordinates of the new geometry are rounded to @p_round_xy/@p_round_zm number of decimal digits of precision.
 *  NOTES
 *    MultiLinestrings and CircularString linestrings are not supported.
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    @p_linestring        (geometry) - Supplied geometry of type LINESTRING only.
 *    @p_reduction_length  (float)    - Length to reduce linestring by in SRID units.
 *    @p_end               (varchar5) - START means reduce line at its start; END means extend at its end and BOTH means extend at both START and END of line.
 *    @p_round_xy          (int)      - Round XY ordinates to supplied decimal digits of precision.
 *    @p_round_zm          (int)      - Round ZM ordinates to supplied decimal digits of precision.
 *  RESULT
 *    linestring           (geometry) - Input geometry extended as instructed.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *    Simon Greener - February 2020 - Fixed bug with reduction ratio.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *    Creative Commons Attribution-Share Alike 2.5 Australia License.
 *    http://creativecommons.org/licenses/by-sa/2.5/au/
 ******/
Begin
  Declare
    @v_GeometryType      varchar(100),
    @v_isGeography       bit,
    @v_reduction_length  float = ABS(@p_reduction_length),
    @v_round_xy          int,
    @v_round_zm          int,
    @v_geom_length       float = 0,
    @v_end               varchar(5) = UPPER(SUBSTRING(ISNULL(@p_end,'START'),1,5)),
    @v_deltaX            float,
    @v_deltaY            float,
    @v_end_pt            geometry,
    @v_internal_pt       geometry,
    @v_segment_length    float,
    @v_new_point         geometry,
    @v_pt_id             int = 0,
    @v_linestring        geometry;
  Begin
    IF ( @p_linestring is NULL )
      Return Null;

    -- Only support simple linestrings
    SET @v_GeometryType = @p_linestring.STGeometryType();
    IF ( @v_GeometryType <> 'LineString' )
      Return @p_linestring;

    IF ( @v_end NOT IN ('START','BOTH','END') ) 
      Return @p_linestring;

    IF ( @p_reduction_length is NULL OR @p_reduction_length = 0 ) 
      Return @p_linestring;

    SET @v_isGeography = [$(owner)].[STIsGeographicSrid](@p_linestring.STSrid);
    SET @v_round_xy    = ISNULL(@p_round_xy,3);
    SET @v_round_zm    = ISNULL(@p_round_zm,2);

    -- Set local geometry so that we can update it.
    --
    SET @v_linestring = @p_linestring;

    -- Is reduction distance (when BOTH) greater than actual length of string?
    --
    SET @v_geom_length = ROUND(case when @v_isGeography = 1 
                                    then geography::STGeomFromText(@p_linestring.AsTextZM(),@p_linestring.STSrid).STLength()
                                    else @p_linestring.STLength()
                                end,@v_round_xy);
    IF ( @v_reduction_length >= (@v_geom_length / CASE @v_end WHEN 'BOTH' THEN 2.0 ELSE 1 END) )
      Return @p_linestring;

    IF ( @v_end IN ('START','BOTH') )
    BEGIN
      -- Reduce
      SET @v_pt_id = 0; 
      WHILE (1=1)
      BEGIN
        SET @v_pt_id          = @v_pt_id + 1;
        SET @v_end_pt         = @v_linestring.STPointN(@v_pt_id);
        SET @v_internal_pt    = @v_linestring.STPointN(@v_pt_id + 1);
        SET @v_deltaX         = @v_internal_pt.STX - @v_end_pt.STX;
        SET @v_deltaY         = @v_internal_pt.STY - @v_end_pt.STY;
        SET @v_segment_length = ROUND(case when @v_isGeography = 1
                                          then [$(owner)].[STToGeography] (@v_end_pt,     @p_linestring.STSrid).STDistance( 
                                               [$(owner)].[STToGeography] (@v_internal_pt,@p_linestring.STSrid) )
                                          else @v_end_pt.STDistance(@v_internal_pt)
                                      End,@v_round_xy);
        IF (ROUND(@v_reduction_length, @v_round_xy + 1)
         >= ROUND(@v_segment_length,   @v_round_xy + 1))
        BEGIN
          SET @v_linestring   = [$(owner)].[STDeleteN] ( 
                                   @v_linestring, 
                                   @v_pt_id, 
                                   @v_round_xy, 
                                   @v_round_zm 
                                );
          SET @v_reduction_length = @v_reduction_length - @v_segment_length;
          SET @v_pt_id            = @v_pt_id - 1;
        END
        ELSE
        BEGIN
          -- To Do: Handle Z and M
          SET @v_new_point  = geometry::Point(
                                  round(@v_end_pt.STX + @v_deltaX * (@v_reduction_length / @v_segment_length), @v_round_xy),
                                  round(@v_end_pt.STY + @v_deltaY * (@v_reduction_length / @v_segment_length), @v_round_xy),
                                  @p_linestring.STSrid
                              );
          SET @v_linestring = [$(owner)].[STUpdateN] (
                                 @v_linestring,
                                 @v_new_point,
                                 @v_pt_id,
                                 @v_round_xy, 
                                 @v_round_zm 
                              );
          BREAK;
        END;
      END; -- While 
    END;   -- IF ( @v_end IN ('START','BOTH') )

    IF ( @v_end IN ('BOTH','END') )
    BEGIN
      -- Reduce
      SET @v_reduction_length = ABS(@p_reduction_length); -- Reset as could be modified in START/BOTH handler.
      SET @v_pt_id            = @v_linestring.STNumPoints() + 1;
      WHILE (1=1)
      BEGIN
        SET @v_pt_id          = @v_pt_id - 1;
        SET @v_end_pt         = @v_linestring.STPointN(@v_pt_id);
        SET @v_internal_pt    = @v_linestring.STPointN(@v_pt_id - 1);
        SET @v_deltaX         = @v_internal_pt.STX - @v_end_pt.STX;
        SET @v_deltaY         = @v_internal_pt.STY - @v_end_pt.STY;
        SET @v_segment_length = ROUND(case when @v_isGeography = 1
                                          then [$(owner)].[STToGeography] (@v_end_pt,     @p_linestring.STSrid).STDistance( 
                                               [$(owner)].[STToGeography] (@v_internal_pt,@p_linestring.STSrid) )
                                          else @v_end_pt.STDistance(@v_internal_pt)
                                      End,@v_round_xy);
        IF ( ROUND(@v_reduction_length,@v_round_xy + 1) 
          >= ROUND(@v_segment_length,  @v_round_xy + 1) )
        BEGIN
          SET @v_linestring   = [$(owner)].[STDeleteN] ( 
                                   @v_linestring, 
                                   @v_pt_id, 
                                   @v_round_xy, 
                                   @v_round_zm
                                );
          SET @v_reduction_length = @v_reduction_length - @v_segment_length;
        END
        ELSE
        BEGIN
          -- To Do: Handle Z and M
          SET @v_new_point  = geometry::Point(
                                 round(@v_end_pt.STX + @v_deltaX * (@v_reduction_length / @v_segment_length), @v_round_xy),
                                 round(@v_end_pt.STY + @v_deltaY * (@v_reduction_length / @v_segment_length), @v_round_xy),
                                 @p_linestring.STSrid
                              );
          SET @v_linestring = [$(owner)].[STUpdateN] (
                                 @v_linestring,
                                 @v_new_point,
                                 @v_linestring.STNumPoints(),
                                 @v_round_xy, 
                                 @v_round_zm 
                              );
          BREAK;
        END;
      END; -- LOOP
    END;   -- IF ( @v_end IN ('BOTH','END') )

    Return @v_linestring;

  END;
END
GO


