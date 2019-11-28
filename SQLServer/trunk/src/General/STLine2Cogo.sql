SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) Cogo($(cogoowner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(cogoowner)].[STLine2Cogo]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STLine2Cogo];
  Print 'Dropped [STLine2Cogo] ....';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(cogoowner)].[STLine2CogoAsTable]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STLine2CogoAsTable];
  Print 'Dropped [STLine2CogoAsTable] ....';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(cogoowner)].[STCogo2Line]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STCogo2Line];
  Print 'Dropped [STCogo2Line] ....';
END;
GO

PRINT '******************************************************************';
Print 'Creating [STLine2CogoAsTable] ....';
GO

CREATE FUNCTION [$(cogoowner)].[STLine2CogoAsTable]
( 
  @p_linestring  geometry,
  @pDegreeSymbol NVarChar(1),
  @pMinuteSymbol NVarChar(1),
  @pSecondSymbol NVarChar(1) 
)
Returns @segments TABLE
(
  segment_id int,          /* Unique integer */
  element_id int,          /* If Linestring, 1, else part of MULTILINESTRING */
  dms        varchar(100), /* Bearing expressed as DMS */
  bearing    float,        /* Bearing expressed as DD */
  distance   float,        /* Length of segment */
  deltaZ     float         /* delta Z along segment */
)
AS
/****f* COGO/STLine2CogoAsTable (2008)
 *  NAME
 *   STLine2CogoAsTable - Dumps all segment of supplied linestring geometry object to bearing and distance tuples.
 *  SYNOPSIS
 *   Function STLine2CogoAsTable (
 *       @p_linestring  geometry,
 *       @pDegreeSymbol NVarChar(1),
 *       @pMinuteSymbol NVarChar(1),
 *       @pSecondSymbol NVarChar(1) 
 *    )
 *    Returns @segments Table (
 *        segment_id int,          -- Unique integer 
 *        element_id int,          -- If Linestring, 1, else part of MULTILINESTRING 
 *        dms        varchar(100), -- Bearing expressed as DMS string
 *        bearing    float,        -- Bearing expressed as DD
 *        distance   float,        -- Length of segment
 *        deltaZ     float         -- delta Z along segment
 *    )  
 *  EXAMPLE
 *    SELECT t.*
 *      FROM [$(cogoowner)].[STLine2CogoAsTable](geometry::STGeomFromText('MULTILINESTRING((0 0,1 1,2 2),(100 100,110 110,130 130))',0),
 *                                               NULL,NULL,NULL) as t
 *     ORDER BY t.segment_id;
 *    GO
 *    segment_id element_id    dms          bearing distance         deltaZ
 *    1          1          45° 0'0.000" 45      1.4142135623731  NULL
 *    2          1          45° 0'0.000" 45      1.4142135623731  NULL
 *    3          2          45° 0'0.000" 45      14.142135623731  NULL
 *    4          2          45° 0'0.000" 45      28.2842712474619 NULL
 *  DESCRIPTION
 *    This function converts each segment of a (multi)linestring into a COGO bearing and distance.
 *    The COGO references are returning in the order they appear in the geometry object.
 *  INPUTS
 *    @p_linestring  (geometry)    - A LINESTRING or MULTILINESTRING object.
 *    @pDegreeSymbol (NVarChar(1)) - Degrees symbol eg ^
 *    @pMinuteSymbol (NVarChar(1)) - Seconds symbol eg '
 *    @pSecondSymbol (NVarChar(1)) - Seconds symbol eg "
 *  RESULT
 *    Table (Array) of Points :
 *     segment_id  (int) - Unique segment id starting at first and ending at last regardless as to whether multilinestring.
 *     element_id  (int) - Identifier unique to each element eg MultiLineString first LINESTRING is 1, second is 2 etc.
 *     dms     (varchar) - DMS eg 149^10'11.1" 
 *     bearing   (float) - DD eg 149.1334343
 *     distance  (float) - length of segment (if geodetic SRID will be in meters).
 *     deltaZ    (float) - end z ordinate minus start z ordinate for each segment.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - June 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2017 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_id           int,
    @v_element_id   int,
    @v_length       float,
    @v_bearing      float,
    @v_deltaZ       float,
    @v_dms          varchar(100),
    @v_segment_geom geometry;

  IF ( @p_linestring is null ) 
    Return;

  IF ( @p_linestring.STGeometryType() NOT IN ('LineString','MultiLineString') )
    Return;

  -- Walk over all the segments of the linear geometry
  DECLARE cSegments 
  CURSOR FAST_FORWARD 
     FOR
  SELECT v.id,
         v.element_id,
         v.ez - v.sz,
         v.length,
         v.geom
    FROM [$(owner)].[STSegmentLine](@p_linestring) as v
   ORDER BY v.id DESC;

   OPEN cSegments;

   FETCH NEXT 
    FROM cSegments 
    INTO @v_id,
         @v_element_id,
         @v_deltaZ,
         @v_length,
         @v_segment_geom;

   WHILE @@FETCH_STATUS = 0
   BEGIN
     
     SET @v_bearing = [$(cogoowner)].[STBearingBetweenPoints] ( 
                        /* @p_start_point */ @v_segment_geom.STStartPoint(),
                        /* @p_end_point   */ @v_segment_geom.STEndPoint()
                      );

     SET @v_dms     = [$(cogoowner)].[DD2DMS] (
                        /* @dDecDeg       */ @v_bearing,
                        /* @pDegreeSymbol */ ISNULL(@pDegreeSymbol,CHAR(176)),
                        /* @pMinuteSymbol */ ISNULL(@pMinuteSymbol,CHAR(39)),
                        /* @pSecondSymbol */ ISNULL(@pSecondSymbol,'"')
                      );
     INSERT INTO @segments ( segment_id,    element_id,    dms,    bearing,  distance,    deltaZ )
     VALUES (                     @v_id, @v_element_id, @v_dms, @v_bearing, @v_length, @v_deltaZ);

     FETCH NEXT 
      FROM cSegments 
      INTO @v_id,
           @v_element_id,
           @v_deltaZ,
           @v_length,
           @v_segment_geom;

   END; /* While */
   CLOSE      cSegments
   DEALLOCATE cSegments
   RETURN;
END;
GO

PRINT '****************************************************************************************************'
GO

Print 'Creating [STLine2Cogo] ....';
GO

CREATE FUNCTION [$(cogoowner)].[STLine2Cogo]
( 
  @p_linestring  geometry,
  @pDegreeSymbol NVarChar(1),
  @pMinuteSymbol NVarChar(1),
  @pSecondSymbol NVarChar(1) 
)
Returns XML
AS
/****f* COGO/STLine2Cogo (2008)
 *  NAME
 *   STLine2Cogo - Converts LineString into COGO XML structure for use in STCogo2Line.
 *  SYNOPSIS
 *   Function STLine2Cogo (
 *       @p_linestring  geometry,
 *       @pDegreeSymbol NVarChar(1),
 *       @pMinuteSymbol NVarChar(1),
 *       @pSecondSymbol NVarChar(1) 
 *    )
 *    Returns XML
 *  EXAMPLE
 *    -- Write 2D with DMS string bearings
 *    SELECT [$(cogoowner)].[STLine2Cogo] (
 *              geometry::STGeomFromText('LINESTRING (10 10, 8.163 17.034, 158.755 35.432, 157.565 25.108)',0),
 *              CHAR(176),CHAR(39),'"')
 *    GO
 *    <Cogo srid="0">
 *      <Segments>
 *        <Segment>
 *          <MoveTo>POINT (10 10)</MoveTo>
 *          <DegMinSec> 345°21'48.75"</DegMinSec>
 *          <Distance>345.364</Distance>
 *        </Segment>
 *        <Segment>
 *          <DegMinSec>  83° 2'4.652"</DegMinSec>
 *          <Distance>83.0346</Distance>
 *        </Segment>
 *        <Segment>
 *          <DegMinSec> 186°34'30.73"</DegMinSec>
 *          <Distance>186.575</Distance>
 *        </Segment>
 *      </Segments>
 *    </Cogo>
 *  DESCRIPTION
 *    This function converts each segment of a (multi)linestring into a COGO bearing and distance XML Segment.
 *    The COGO references are returning in the order they appear in the geometry object.
 *    The first point of the start of a LineString element is returned as a <MoveTo> element.
 *    If all three symbol parameters are NULL, <Bearing> elements are created holding decimal degrees, else <DegMinSec> elements are written.
 *  NOTE
 *    Measured lines are unsupported.
 *  INPUTS
 *    @p_linestring  (geometry)    - A LINESTRING or MULTILINESTRING object.
 *    @pDegreeSymbol (NVarChar(1)) - Degrees symbol eg ^
 *    @pMinuteSymbol (NVarChar(1)) - Seconds symbol eg '
 *    @pSecondSymbol (NVarChar(1)) - Seconds symbol eg "
 *  RESULT
 *    COGO Object    (XML);
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - June 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2017 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_CogoXML         xml,
    @v_segment_xml     xml,
    @v_segment_node    varchar(max),
    @v_dimensions      varchar(4),
    @v_dd              bit,
    @v_DegreeSymbol    NVarChar(1),
    @v_MinuteSymbol    NVarChar(1),
    @v_SecondSymbol    NVarChar(1),
    @v_id              int,
    @v_element_id      int,
    @v_prev_element_id int,
    @v_z               float,
    @v_prev_z          float,
    @v_length          float,
    @v_bearing         float,
    @v_dms             varchar(100),
    @v_segment_geom    geometry;

  IF ( @p_linestring is null ) 
    Return NULL;

  IF ( @p_linestring.STGeometryType() NOT IN ('LineString','MultiLineString') )
    Return NULL;

  IF ( @p_linestring.STPointN(1).HasM = 1 )
    Return NULL;
       
  SET @v_dd = case when (@pDegreeSymbol is null and 
                         @pMinuteSymbol is null and
                         @pSecondSymbol is null )
                   then 1
                   else 0
                end;
  IF (@v_dd = 0) 
  BEGIN
    SET @v_DegreeSymbol = ISNULL(@pDegreeSymbol,CHAR(176));
    SET @v_MinuteSymbol = ISNULL(@pMinuteSymbol,CHAR(39));
    SET @v_SecondSymbol = ISNULL(@pSecondSymbol,'"');
  END;

  SET @v_dimensions  = 'XY' + case when @p_linestring.STPointN(1).HasZ=1 then 'Z' else '' end;

  -- Create base COGO XML document..
  SET @v_CogoXML = '<Cogo srid="' + CAST(@p_linestring.STPointN(1).STSrid as varchar(10)) + '"><Segments></Segments></Cogo>';

  -- Walk over all the segments of the linear geometry
  DECLARE cSegments 
  CURSOR FAST_FORWARD 
     FOR
  SELECT v.id,
         v.element_id,
         v.sz,
         v.ez,
         v.length,
         v.geom
    FROM [$(owner)].[STSegmentLine](@p_linestring) as v
   ORDER BY v.id DESC;

  OPEN cSegments;

  FETCH NEXT 
   FROM cSegments 
   INTO @v_id,
        @v_element_id,
        @v_prev_z,
        @v_z,
        @v_length,
        @v_segment_geom;

  SET @v_prev_element_id = @v_element_id;

  WHILE @@FETCH_STATUS = 0
  BEGIN
     -- Add Segment Tag
     SET @v_segment_node = '<Segment id="' + CAST(@v_id as varchar(15)) + '">';

     -- Add start point as moveTo
     -- TODO: Fix if has Measures
     IF ( @v_id = 1 or @v_element_id <> @v_prev_element_id )
     BEGIN
       SET @v_segment_node = @v_segment_node + '<MoveTo>' + @v_segment_geom.STStartPoint().AsTextZM() + + '</MoveTo>';
     END;

     -- Create tags to describe segment's COGO
     SET @v_bearing = [$(cogoowner)].[STBearingBetweenPoints] ( 
                        /* @p_start_point */ @v_segment_geom.STStartPoint(),
                        /* @p_end_point   */ @v_segment_geom.STEndPoint()
                      );

     IF ( @v_dd = 1 ) 
     BEGIN
       SET @v_segment_node = @v_segment_node + '<Bearing>' + CAST(@v_bearing as varchar(50)) + '</Bearing>';
     END
     ELSE
     BEGIN
       SET @v_dms = [$(cogoowner)].[DD2DMS] (
                      /* @dDecDeg       */ @v_bearing,
                      /* @pDegreeSymbol */ @v_DegreeSymbol,
                      /* @pMinuteSymbol */ @v_MinuteSymbol,
                      /* @pSecondSymbol */ @v_SecondSymbol
                    );
       SET @v_segment_node = @v_segment_node + '<DegMinSec>' + @v_dms + '</DegMinSec>';
     END;

     -- Add Distance ....
     SET @v_segment_node = @v_segment_node + '<Distance>' + CAST(@v_length as varchar(50)) + '</Distance>';
     IF ( @v_dimensions = 'XYZ' ) 
     BEGIN
       SET @v_segment_node = @v_segment_node + '<DeltaZ>' + CAST((@v_z - @v_prev_z) as varchar(50)) + '</DeltaZ>';
     END;

     SET @v_segment_node = @v_segment_node + '</Segment>';

     -- Now add segment to Cogo XML document
     SET @v_segment_xml = @v_segment_node;
     SET @v_CogoXML.modify('insert sql:variable("@v_segment_xml") as first into (/Cogo/Segments)[1]') ;  

     SET @v_prev_element_id = @v_element_id;

     FETCH NEXT 
      FROM cSegments 
      INTO @v_id,
           @v_element_id,
           @v_prev_z,
           @v_z,
           @v_length,
           @v_segment_geom;

  END; /* While */
  CLOSE      cSegments
  DEALLOCATE cSegments

  RETURN @v_CogoXML;
END;
GO

PRINT '***********************************************************************************';
Print 'Creating [STCogo2Line] ....';
GO

CREATE FUNCTION [$(cogoowner)].[STCogo2Line]
( 
  @p_cogo     xml,
  @p_round_xy int = 3,
  @p_round_z  int = 2
)
Returns geometry
AS
/****f* COGO/STCogo2Line (2008)
 *  NAME
 *   STCogo2Line - Creates linestring from move, bearing and distance instructions supplied in the XML parameter.
 *  SYNOPSIS
 *   Function [$(cogoowner)].[STCogo2Line] (
 *       @p_cogo     xml,
 *       @p_round_xy int = 3,
 *       @p_round_z  int = 2
 *    )
 *    Returns Geometry
 *  EXAMPLE
 *    Print 'Generate XYZ linestring using ordinate string moveTo.';
 *    Declare @v_cogo xml;
 *    SET @v_cogo = 
 *    '<Cogo srid="28356">
 *    <Segments>
 *    <Segment id="1"><MoveTo>10 10 -1</MoveTo><DegMinSec> 345°21''48.75"</DegMinSec><Distance>7.26992</Distance><DeltaZ>1</DeltaZ></Segment>
 *    <Segment id="2"><DegMinSec>  83° 2''4.652"</DegMinSec><Distance>151.712</Distance><DeltaZ>2</DeltaZ></Segment>
 *    <Segment id="3"><DegMinSec> 186°34''30.73"</DegMinSec><Distance>10.3924</Distance><DeltaZ>3</DeltaZ></Segment>
 *    </Segments>
 *    </Cogo>';
 *    select [cogo].[STCogo2Line] (@v_cogo, 3, 2).AsTextZM() as cogoLine
 *    GO
 *    LINESTRING(10 10 -1,8.163 17.034 0,158.755 35.432 2,157.565 25.108 5)
 *  DESCRIPTION
 *    This function takes a set of bearings and distances supplied in XML format, and creates a linestring from it.
 *    The COGO bearings can be supplied as decimal degrees or as a text string sutable for use with DMSS2DD.
 *    If @p_start_point is supplied then its XY ordinates, and SRID, are used for the starting point of the line, otherwise 0,0 and 0 SRID.
 *    The final geometry will have its XY ordinates rounded to @p_round_xy of precision, similarly for Z.
 *    COGO XML Format:
 *      <Cogo srid={int}>
 *       <Segments>
 *         <Segment id="?">
 *           <MoveTo></MoveTo>
 *           <DegMinSec></DegMinSec>
 *           <Bearing></Bearing>
 *           <Distance></Distance>
 *           <DeltaZ></DeltaZ>
 *         <Segment id="?">
 *         <Segment>
 *           ....
 *         <Segment>
 *       </Segments>
 *      </Cogo>
 *    <moveTo> allows for a point object to be provided for the start point, or can denote a break between linestrings.
 *    <moveTo> should contain either a POINT() WKT object or the coordinate string part of a POINT() WKT object eg
 *       POINT(1 2 -1) -- XYZ
 *       1 2 -1
 *    <moveTo> associated with first <Segment> determines if linestring 2D or 3D. 
 *    If <moveTo> missing for first <Segment>, linestring is 2D regardless as to whether any other <moveTo>s exist in any other <Segment>
 *    If linestring is XYZ then <DeltaZ> elements are expected.
 *    <DegMinSec> does not have to exist if <Bearing> (decimal degrees) exists.
 *    <DeltaZ> is optional, if not, a 3D <MoveTo> is expected for the first <Segment>
 *  INPUTS
 *    @p_cogo     (xml) - MoveTos, Bearings, Distances and DeltaZ instructions
 *    @p_round_xy (int) - Rounding factor for XY ordinates.
 *    @p_round_z  (int) - Rounding factor for Z ordinate.
 *  RESULT
 *    linestring geometry - New linestring geometry object.
 *  NOTE 
 *    Measures not supported: see LRS functions.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - June 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2017 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_dimensions  varchar(4),
    @v_bearing     float,
    @v_distance    float,
    @v_deltaZ      float,
    @v_z           float,
    @v_i           int,
    @v_moveToCount int,
    @v_numCogo     int,
    @v_srid        int,
    @v_round_xy    int,
    @v_round_z     int,
    @v_DMS         varchar(100),
    @v_wkt         varchar(max),
    @v_move_coords varchar(100),
    @v_start_point geometry,
    @v_next_point  geometry,
    @v_linestring  geometry;

  IF ( @p_cogo is null ) 
    Return null;

  SET @v_round_xy = ISNULL(@p_round_xy,3);
  SET @v_round_z  = ISNULL(@p_round_z, 2);

  -- How many geometries in array?
  SET @v_numCogo = @p_cogo.value('count(/Cogo/Segments/*)', 'int');
  If ( @v_numCogo = 0 )
    Return NULL;

  -- Get SRID.
  SET @v_srid = COALESCE(@p_cogo.value('(/Cogo/@srid)[1]','int'),0);

  -- If more than one MoveTo, or MoveTo is not in first segment, we have a MULTILINESTRING
  SET @v_moveToCount = @p_cogo.value('count(/Cogo/Segments/Segment/MoveTo)','int') 
  SET @v_move_coords = @p_cogo.value('(/Cogo/Segments/Segment[1]/MoveTo)[1]','varchar(100)');
  SET @v_wkt         = case when @v_moveToCount > 1
                              or ( @v_moveToCount = 1 and @v_move_coords is null ) 
                            then 'MULTILINESTRING((' 
                            else 'LINESTRING(' 
                        end;

  -- Determine XYZ or ZY
  IF ( @v_move_coords is null )
  BEGIN
    -- Assume 2D linestring will start at 0,0
    SET @v_dimensions  = 'XY';
    SET @v_start_point = geometry::Point(0,0,@v_srid);
    SET @v_move_coords = NULL;
    SET @v_z           = NULL;
  END
  ELSE
  BEGIN
    SET @v_move_coords = case when CHARINDEX('POINT',@v_move_coords,1)>0 
                              then @v_move_coords 
                              else 'POINT(' + @v_move_coords + ')' 
                          end;
    SET @v_start_point = geometry::STGeomFromText(@v_move_coords,@v_srid);
    SET @v_dimensions  = 'XY' + case when @v_start_point.HasZ=1 then 'Z' else '' end;
    SET @v_z           = case when @v_dimensions = 'XYZ' then @v_start_point.Z else NULL end;
  END;

  -- Now process all COGO instructions
  SET @v_i = 0;
  WHILE @v_i < @v_numCogo
  BEGIN
     SET @v_i = @v_i + 1;

     -- Do we have a MoveTo at our current position in the XML?
     IF ( @v_moveToCount > 0 )
     BEGIN
       SET @v_move_coords = @p_cogo.value('(/Cogo/Segments/Segment[sql:variable("@v_i")]/MoveTo)[1]','varchar(100)');
       IF ( @v_move_coords is not null ) 
       BEGIN
         SET @v_move_coords = case when CHARINDEX('POINT',@v_move_coords,1)>0 
                                   then @v_move_coords 
                                   else 'POINT(' + @v_move_coords + ')' 
                               end;
         SET @v_start_point = geometry::STGeomFromText(@v_move_coords,@v_srid);
         SET @v_z           = case when @v_dimensions = 'XYZ' then @v_start_point.Z else NULL end;
       END
     END;

     -- Add start point to WKT only for first point in a linestring element
     IF ( @v_i = 1 ) or ( @v_i > 1 and @v_move_coords is not null ) 
     BEGIN
       SET @v_wkt = @v_wkt 
                  + 
                  case when ( @v_i > 1 and @v_move_coords is not null ) 
                       then '),(' 
                       else ''
                   end
                  +
                  [$(owner)].[STPointAsText] (
                     @v_dimensions,
                     @v_start_point.STX,
                     @v_start_point.STY,
                     @v_z,
                     NULL,
                     @v_round_xy,
                     @v_round_xy,
                     @v_round_z,
                     NULL
                  );
     END;
     SET @v_wkt = @v_wkt + ',';

     -- Retrieve COGO instructions from XML for this segment to generate end point
     SET @v_DMS = @p_cogo.value('(/Cogo/Segments/Segment[sql:variable("@v_i")]/DegMinSec)[1]','varchar(100)');
     IF ( @v_DMS is not null )
     BEGIN
       SET @v_bearing = [$(cogoowner)].DMSS2DD( @v_DMS );
     END
     ELSE
     BEGIN
       SET @v_bearing = @p_cogo.value('(/Cogo/Segments/Segment[sql:variable("@v_i")]/Bearing)[1]','float');
     END;

     IF ( @v_bearing is null )
       Continue;
  
     -- Get distance
     SET @v_distance = @p_cogo.value('(/Cogo/Segments/Segment[sql:variable("@v_i")]/Distance)[1]','float');
     IF ( @v_distance is null )
       Continue;

     IF ( @v_dimensions = 'XYZ' )
     BEGIN
       SET @v_deltaZ = @p_cogo.value('(/Cogo/Segments/Segment[sql:variable("@v_i")]/DeltaZ)[1]','float');
       SET @v_z      = @v_z + ISNULL(@v_deltaZ,0.0);
     END;

     -- Now create next point
     SET @v_next_point = [$(cogoowner)].[STPointFromCOGO] ( 
                           /* @p_start_point */ @v_start_point,
                           /* @p_dBearing    */ @v_bearing,
                           /* @p_dDistance   */ @v_distance,
                           /* @p_round_xy    */ @v_round_xy
                         );

     -- Create string version of point (X Y Z M) and add to WKT
     SET @v_wkt = @v_wkt 
                  + 
                  [$(owner)].[STPointAsText] (
                          @v_dimensions,
                          @v_next_point.STX,
                          @v_next_point.STY,
                          @v_z,
                          NULL,
                          @v_round_xy,
                          @v_round_xy,
                          @v_round_z,
                          NULL
                  );
     SET @v_move_coords = NULL;
     SET @v_start_point = @v_next_Point;
   END; /* While */

   SET @v_wkt = @v_wkt 
                + 
                case when CHARINDEX('MULTI',@v_wkt) > 0 then '))' else ')' end;
   RETURN geometry::STGeomFromText(@v_wkt,@v_srid);

END;
GO

Print 'Testing [$(cogoowner)].[STLine2CogoAsTable] ....';
GO

SELECT *
  FROM [$(cogoowner)].[STLine2CogoAsTable](geometry::STGeomFromText('MULTILINESTRING((0 0,1 1,2 2),(100 100,110 110,130 130))',0), NULL,NULL,NULL) as t
 ORDER BY t.segment_id;
GO
/*
segment_id    element_id    dms    bearing    distance    deltaZ
1    1      45° 0'0.000"    45    1.4142135623731    NULL
2    1      45° 0'0.000"    45    1.4142135623731    NULL
3    2      45° 0'0.000"    45    14.142135623731    NULL
4    2      45° 0'0.000"    45    28.2842712474619    NULL
*/

Print 'Testing [$(cogoowner)].[STLine2Cogo] ....';
GO

SELECT [$(cogoowner)].[STLine2COGO](geometry::STGeomFromText('LINESTRING (382.875 -422.76, 381.038 -415.726, 531.63 -397.328, 530.44 -407.652, 543.796 -406.729, 542.673 -415.759, 603.73 -415.063, 603.693 -403.377, 614.665 -404.601, 612.239 -376.561, 617.793 -375.878)',28356),NULL,NULL,NULL) as t
GO

select [$(cogoowner)].[STLine2Cogo] (geometry::STGeomFromText(' MULTILINESTRING ( (10 10, 8.163 17.034, 158.755 35.432, 157.565 25.108, 170.921 26.031), (100 100, 98.877 90.97, 159.934 91.666, 159.897 103.352), (200 200, 210.972 198.776, 208.546 226.816, 214.1 227.499))',0),null,null,null) as cogoObj;
GO

Print 'Testing [STCogo2Line] ....';
GO

Declare @v_xml XML;
SET @v_xml = 
'<Cogo><Segments>
<Segment id="1"><DegMinSec>45° 0''0.000"</DegMinSec><Distance>1.41421</Distance><DeltaZ>1</DeltaZ></Segment>
<Segment id="2"><DegMinSec>45° 0''0.000"</DegMinSec><Distance>1.41421</Distance><DeltaZ>2</DeltaZ></Segment>
<Segment id="3"><DegMinSec>45° 0''0.000"</DegMinSec><Distance>14.1421</Distance><DeltaZ>3</DeltaZ></Segment>
<Segment id="4"><DegMinSec>45° 0''0.000"</DegMinSec><Distance>28.2843</Distance><DeltaZ>4</DeltaZ></Segment>
</Segments></Cogo>';
select cogoLine.AsTextZM() as cogoLineWKT
  from (select [$(cogoowner)].[STCogo2Line] (@v_xml, 3, 2) as cogoLine) as f;
GO

Declare @v_cogo xml;
SET @v_cogo = 
'<Cogo><Segments>
<Segment id="1"><DegMinSec> 345°21''48.75"</DegMinSec><Distance>7.26992</Distance><DeltaZ>1</DeltaZ></Segment>
<Segment id="2"><DegMinSec>  83° 2''4.652"</DegMinSec><Distance>151.712</Distance><DeltaZ>2</DeltaZ></Segment>
<Segment id="3"><DegMinSec> 186°34''30.73"</DegMinSec><Distance>10.3924</Distance><DeltaZ>3</DeltaZ></Segment>
<Segment id="4"><DegMinSec>  86° 2''48.18"</DegMinSec><Distance>13.3879</Distance><DeltaZ>4</DeltaZ></Segment>
<Segment id="5"><DegMinSec> 187° 5''20.73"</DegMinSec><Distance>9.09956</Distance><DeltaZ>5</DeltaZ></Segment>
<Segment id="6"><DegMinSec>  89°20''48.85"</DegMinSec><Distance>61.061</Distance><DeltaZ>6</DeltaZ></Segment>
<Segment id="7"><DegMinSec> 359°49''6.930"</DegMinSec><Distance>11.6861</Distance><DeltaZ>7</DeltaZ></Segment>
<Segment id="8"><DegMinSec>  96°21''55.47"</DegMinSec><Distance>11.0401</Distance><DeltaZ>8</DeltaZ></Segment>
<Segment id="9"><DegMinSec> 355° 3''18.45"</DegMinSec><Distance>28.1448</Distance><DeltaZ>9</DeltaZ></Segment>
<Segment id="10"><DegMinSec>  82°59''21.42"</DegMinSec><Distance>5.59584</Distance><DeltaZ>10</DeltaZ></Segment>
</Segments></Cogo>';
select cogoLine, cogoLine.AsTextZM() as cogoLineWKT
  from (select [$(cogoowner)].[STCogo2Line] (@v_cogo, 3, 2) as cogoLine) as f;
GO

SELECT [$(cogoowner)].[STCogo2Line] ( f.cogoXML, 3,2) as linestring
  FROM (SELECT [$(cogoowner)].[STLine2Cogo] (
                 geometry::STGeomFromText('MULTILINESTRING((0 0,1 1,2 2),(100 100,110 110,130 130))',0),
                 CHAR(176),
                 CHAR(39),
                 '"'
               ) as cogoXML 
        ) as f;
GO

Declare @v_cogo xml;
SET @v_cogo = 
'<Cogo srid="28356"><Segments>
<Segment id="1"><MoveTo>10 10 -10</MoveTo><DegMinSec> 345°21''48.75"</DegMinSec><Distance>7.26992</Distance><DeltaZ>1</DeltaZ></Segment>
<Segment id="2"><DegMinSec>  83° 2''4.652"</DegMinSec><Distance>151.712</Distance><DeltaZ>2</DeltaZ></Segment>
<Segment id="3"><DegMinSec> 186°34''30.73"</DegMinSec><Distance>10.3924</Distance><DeltaZ>3</DeltaZ></Segment>
<Segment id="4"><DegMinSec>  86° 2''48.18"</DegMinSec><Distance>13.3879</Distance><DeltaZ>4</DeltaZ></Segment>
<Segment id="5"><DegMinSec> 187° 5''20.73"</DegMinSec><Distance>9.09956</Distance><DeltaZ>5</DeltaZ></Segment>
<Segment id="6"><DegMinSec>  89°20''48.85"</DegMinSec><Distance>61.061</Distance><DeltaZ>6</DeltaZ></Segment>
<Segment id="7"><DegMinSec> 359°49''6.930"</DegMinSec><Distance>11.6861</Distance><DeltaZ>7</DeltaZ></Segment>
<Segment id="8"><MoveTo>100 100 -15</MoveTo><DegMinSec>  96°21''55.47"</DegMinSec><Distance>11.0401</Distance><DeltaZ>8</DeltaZ></Segment>
<Segment id="9"><DegMinSec> 355° 3''18.45"</DegMinSec><Distance>28.1448</Distance><DeltaZ>9</DeltaZ></Segment>
<Segment id="10"><DegMinSec>  82°59''21.42"</DegMinSec><Distance>5.59584</Distance><DeltaZ>10</DeltaZ></Segment>
</Segments></Cogo>';
--select [$(cogoowner)].[STCogo2Line] (@v_cogo, 3, 2) as cogoLine
select cogoLine, cogoLine.AsTextZM() as cogoLineWKT from (select [$(cogoowner)].[STCogo2Line] (@v_cogo, 3, 2) as cogoLine) as f;
GO


