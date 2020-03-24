PRINT '-------------------------------------------------';
PRINT '1. Original Linestring ...';
GO
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring;
GO
Print 'LRS_1.PNG';
GO

PRINT '-------------------------------------------------';
PRINT '2. Add Measure ... ';
GO
WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING 
(2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING 
(2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
)
SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ).AsTextZM() as mLinestring
  FROM data as d;
GO
-- mLinestring
-- COMPOUNDCURVE ((2172150.685 258351.613 NULL 7400, 2171796.817 257562.728 NULL 8264.62), CIRCULARSTRING (2171796.817 257562.728 NULL 8264.62, 2171785.154 257183.204 NULL 8654.17, 2172044.297 256905.682 NULL 9043.72), (2172044.297 256905.682 NULL 9043.72, 2172405.655 256740.527 NULL 9441.03), CIRCULARSTRING (2172405.655 256740.527 NULL 9441.03, 2172647.647 256579.203 NULL 9733.1, 2172826.928 256350.196 NULL 10025.17), (2172826.928 256350.196 NULL 10025.17, 2172922.015 256178.153 NULL 10321.74))

PRINT '-------------------------------------------------';
PRINT '3. Add Z to Measured Line... ';
GO
WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [$(owner)].[STAddZ](d.mlinestring, 5.34, 8.3837, 3,2 ).AsTextZM() as zmLinestring
  FROM mLine as d;
GO
-- zmLinestring
-- COMPOUNDCURVE ((2172150.685 258351.613 5.34 7400, 2171796.817 257562.728 6.27 8264.62), CIRCULARSTRING (2171796.817 257562.728 6.27 8264.62, 2171785.154 257183.204 6.27 8654.17, 2172044.297 256905.682 6.27 9043.72), (2172044.297 256905.682 6.27 9043.72, 2172405.655 256740.527 8.47 9441.03), CIRCULARSTRING (2172405.655 256740.527 8.47 9441.03, 2172647.647 256579.203 8.47 9733.1, 2172826.928 256350.196 8.47 10025.17), (2172826.928 256350.196 8.47 10025.17, 2172922.015 256178.153 8.38 10321.74))

PRINT '-------------------------------------------------';
PRINT '4. Reset Measure (All M ordinates set to -9999)... ';
GO
WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
)
SELECT [lrs].[STResetMeasure] (
              [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ),
			  -9999, 3, 2).AsTextZM()		   
		    as mLinestring
  FROM data as d;
GO
-- mLinestring
-- COMPOUNDCURVE ((2172150.685 258351.613 NULL -9999, 2171796.817 257562.728 NULL -9999), CIRCULARSTRING (2171796.817 257562.728 NULL -9999, 2171785.154 257183.204 NULL -9999, 2172044.297 256905.682 NULL -9999), (2172044.297 256905.682 NULL -9999, 2172405.655 256740.527 NULL -9999), CIRCULARSTRING (2172405.655 256740.527 NULL -9999, 2172647.647 256579.203 NULL -9999, 2172826.928 256350.196 NULL -9999), (2172826.928 256350.196 NULL -9999, 2172922.015 256178.153 NULL -9999))

PRINT '-------------------------------------------------';
PRINT '5. Remove Measure (Should equal original linestring)... ';
GO
WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
)
SELECT d.linestring.STEquals( 
           [lrs].[STRemoveMeasure] (
              [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ),
			  3,2 )
	   ) as equals
  FROM data as d;
GO
-- equals
--      1

PRINT '-------------------------------------------------';
PRINT '6. Inspect Start, End Measures, Measure Range, Ascending or Descending...';
WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STStartMeasure](e.mLinestring)        as StartMeasure,
       [lrs].[STEndMeasure](e.mLinestring)          as EndMeasure,
       [lrs].[STMeasureRange](e.mLinestring)        as MeasureRange,
       [lrs].[STIsMeasureIncreasing](e.mLinestring) as MeasureIncreasing,
       [lrs].[STIsMeasureDecreasing](e.mLinestring) as MeasureDecreasing
  FROM mLine as e;
GO
-- StartMeasure EndMeasure MeasureRange	MeasureIncreasing MeasureDecreasing
-- ------------ ---------- ------------ ----------------- -----------------
--         7400   10321.74      2921.74              TRUE             FALSE

PRINT '-------------------------------------------------';
PRINT '7. LRS Validity ...';
WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STValidMeasure](e.mLinestring,7000.0)                         as ValidMeasureBefore,
       [lrs].[STValidMeasure](e.mLinestring,e.mLinestring.STStartPoint().M) as ValidStartPoint,
       [lrs].[STValidMeasure](e.mLinestring,8860.87)                        as ValidMeasureMiddle,
       [lrs].[STValidLrsPoint](e.mLinestring.STPointN(5))                   as ValidLrsMeasure
  FROM mLine as e;
GO
-- ValidMeasureBefore ValidStartPoint ValidMeasureMiddle ValidLrsMeasure
-- ------------------ --------------- ------------------ ---------------
--                  0               1                  1               1

PRINT '-------------------------------------------------';
PRINT '8. Percentages ...';
WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT ROUND([lrs].[STMeasureToPercentage](e.mLinestring, 
                                           e.mLinestring.STStartPoint().M + [lrs].[STMeasureRange](e.mLinestring)/4.0),1) as Percentage,
       ROUND([lrs].[STPercentageToMeasure](e.mLinestring, 25.3),2)                       as Measure
  FROM mLine as e;
GO
-- Percentage Measure
-- ---------- -------
--         25  8139.2

PRINT '-------------------------------------------------';
PRINT '9. Reverse Measures ...';
GO
WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STIsMeasureIncreasing](f.oMeasuredLine) as oMeasureIncreasing,
       [lrs].[STIsMeasureDecreasing](f.rMeasuredLine) as rMeasureIncreasing,
	   f.rMeasuredLine.AsTextZM() as geom
  FROM (SELECT e.mLinestring as oMeasuredLine,
               [lrs].[STReverseMeasure](e.mLinestring,3,2) as rMeasuredLine
          FROM mLine as e
	) as f;
GO

-- oMeasureIncreasing rMeasureDecreasing geom
-- ------------------ ------------------ -------------------------------------------------------
-- TRUE               TRUE               COMPOUNDCURVE ((2172150.685 258351.613 NULL 10321.74, 2171796.817 257562.728 NULL 9457.12), CIRCULARSTRING (2171796.817 257562.728 NULL 9457.12, 2171785.154 257183.204 NULL 9067.57, 2172044.297 256905.682 NULL 8678.02), (2172044.297 256905.682 NULL 8678.02, 2172405.655 256740.527 NULL 8280.71), CIRCULARSTRING (2172405.655 256740.527 NULL 8280.71, 2172647.647 256579.203 NULL 7988.64, 2172826.928 256350.196 NULL 7696.57), (2172826.928 256350.196 NULL 7696.57, 2172922.015 256178.153 NULL 7400))


PRINT '-------------------------------------------------';
PRINT '10. Scale Measured Line ...';
GO
WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STScaleMeasure](e.mLinestring, 0.0, (10321.74-7400.0),0.5,3,2).AsTextZM() as ScaledMeasure
  FROM mLine as e;
GO
-- ScaledMeasure
-- COMPOUNDCURVE ((2172150.685 258351.613 NULL 0.5, 2171796.817 257562.728 NULL 865.12), CIRCULARSTRING (2171796.817 257562.728 NULL 865.12, 2171785.154 257183.204 NULL 1254.67, 2172044.297 256905.682 NULL 1644.22), (2172044.297 256905.682 NULL 1644.22, 2172405.655 256740.527 NULL 2041.53), CIRCULARSTRING (2172405.655 256740.527 NULL 2041.53, 2172647.647 256579.203 NULL 2333.6, 2172826.928 256350.196 NULL 2625.67), (2172826.928 256350.196 NULL 2625.67, 2172922.015 256178.153 NULL 2921.74))

PRINT '=================================================';
PRINT '  Linear Referencing / Dynamic Segmentation Tests';
PRINT '=================================================';
GO

PRINT 'Locate Point By .....';
PRINT '-------------------------------------------------';
PRINT '11. Locate Point By Ratio ...';
GO

WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindPointByRatio](
          e.mLinestring, 
		  0.5/*ratio*/, 
		  0.0 /*Offset*/, 
		  0 /* RadiusCheck*/, 
		  3, 2).AsTextZM() as PointByRatio
  FROM mLine as e;
GO

-- PointByRatio
-- POINT (2171862.355 257047.58 NULL 8810.87)

PRINT '-------------------------------------------------';
PRINT '12. Locate Point Using By Length (no offset)...';
GO

WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindPointByLength](
         e.mLinestring, 
		 e.mLineString.STLength()/2.0, /*Length*/
		 0.0,  /*Offset*/ 
		   0,  /*RadiusCheck*/
		 3,2).AsTextZM() as Length2PointNoOffset
  FROM mLine as e;
GO

-- Length2PointNoOffset
-- POINT (2171862.355 257047.58 NULL 8810.87)

PRINT '-------------------------------------------------';
PRINT '13. Locate Point By Measure (no offset)...';
GO

WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindPointByMeasure](
         e.mLinestring, 
		 e.mLinestring.STStartPoint().M + (e.mLineString.STEndPoint().M - e.mLinestring.STStartPoint().M)/2.0, /*Measure*/ 
		 0.0, /*Offset*/
		   0, /* RadiusCheck*/
           3, 2).AsTextZM() as Measure2Point10Offset
  FROM mLine as e;
GO

-- Measure2Point10Offset
-- POINT (2171895.493 257010.17 NULL 8860.87)

PRINT 'Given a Point, Compute Measures and Offsets .....';
PRINT '----------------------------------------------------------';
PRINT '14. Find Measure using Point from STFindPointByMeasure ...';
GO

WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindMeasureByPoint] (
             e.mLinestring, 
             [lrs].[STFindPointByMeasure](e.mLinestring, 9043.72, 0.0, 0, 3, 2),
             3, 2) as measure
  FROM mLine as e;
GO

-- measure (Should return starting measure)
-- 9043.72 (Correct)

PRINT '----------------------------------------------------';
PRINT '15. Locate Point By Measure, with 1.1m Offset ...';
GO

WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindPointByMeasure](e.mLinestring, 9043.72, 1.1, 1, 3, 2).AsTextZM() as Measure2Point10Offset
  FROM mLine as e;
GO

-- Measure2Point10Offset
-- POINT (2172043.84 256904.682 NULL 9043.7)

PRINT '-----------------------------------------------------------------------';
PRINT '16. Get Offset of Located Measure with 1.1m Offset: should return 1.1 M ...';
GO

WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring
    FROM data as d
)
SELECT ROUND(
         [lrs].[STFindOffset](
           e.mLinestring, 
           [lrs].[STFindPointByMeasure](e.mLinestring, 9043.72, 1.1, 1, 3, 2),
           3, 2),
         2) as Offset
  FROM mLine as e;
GO

-- Offset (Should be same as original STFindPointByMeasure)
-- 1.1    (Correct)

PRINT '-----------------------------------------------------------------------------';
PRINT '17. Get Measure of Located Measure (50) with 1.1m Offset: should return 50 ...';
GO

WITH data as (
select geometry::STGeomFromText('COMPOUNDCURVE (
(2172150.685 258351.613, 2171796.817 257562.728), 
CIRCULARSTRING (2171796.817 257562.728, 2171785.154 257183.204, 2172044.297 256905.682), 
(2172044.297 256905.682, 2172405.655 256740.527), 
CIRCULARSTRING (2172405.655 256740.527, 2172647.647 256579.203, 2172826.928 256350.196), 
(2172826.928 256350.196, 2172922.015 256178.153))',2274) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 7400.0, 10321.74, 3,2 ) as mLinestring FROM data as d
), pm as (
select mLinestring, [lrs].[STFindPointByMeasure](e.mLinestring, 9043.72, 1.1, 1, 3, 2) as point from mLine as e
)
SELECT [lrs].[STFindMeasure](e.mLinestring, e.point, 3, 2) as measure
  FROM pm as e;
GO

-- measure (Should be same as input)
-- 9043.72 (Correct)

PRINT '**************************************************';
PRINT 'Extract Linear Segments via Range variables...';
GO

PRINT '-------------------------------------------------';
PRINT '18.1 Locate Segment By Length With/Without offset...';
PRINT 'NO Z and M when linestring with > 1 segments (2 Points) is offset';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,115.73 903.305, 102.284 923.026,99.147 899.271,110.8 902.707,90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
)
 SELECT f.offset, f.linestring --.AsTextZM() as tLinestring -- , f.linestring
  FROM (SELECT 'O' as offset, e.linestring from data as e
        union all
        SELECT '0.0' as offset, [lrs].[STFindSegmentByLengthRange](
               /* @p_linestring   */ e.Linestring,
               /* @p_start_length */ 5.1,
               /* @p_end_length   */ 20.2,
               /* @p_offset       */ 0.0,
               /* @p_radius_check */ 0,
               /* @p_round_xy     */ 3,
               /* @p_round_zm     */ 2) as linestring FROM data as e
        union all
        SELECT '-1.1' as offset, [lrs].[STFindSegmentByLengthRange](e.Linestring, 5.1, 20.2, -1.1, 0, 3, 2) as Lengths2Segment FROM data as e
        union all
        SELECT '+1.1' as offset, [lrs].[STFindSegmentByLengthRange](e.Linestring, 5.1, 20.2, +1.1, 0, 3, 2) as Lengths2Segment FROM data as e
      ) as f;
GO

-- offset tLinestring
-- ------ ---------------------------------------------------------------------------------------------------------
--   NONE LINESTRING (66.134 910.128 NULL 6.1, 73.036 899.855 NULL 18.48, 75.58 898.881 NULL 21.2)
--   NONE LINESTRING (66.134 910.128 NULL 6.1, 73.036 899.855 NULL 18.47)
--   -1.1 LINESTRING (75.973 899.908, 73.755 900.758, 67.047 910.741)
--   -1.1 LINESTRING (67.047 910.741 NULL 6.1, 73.949 900.468 NULL 18.47)
--   +1.1 LINESTRING (65.221 909.515, 72.123 899.242, 72.173 899.173, 72.227 899.109, 72.287 899.049, 72.351 898.994, 72.419 898.944, 72.49 898.9, 72.565 898.861, 72.643 898.828, 75.187 897.854)
--   +1.1 LINESTRING (65.221 909.515 NULL 6.1, 72.123 899.242 NULL 18.47)

PRINT '-------------------------------------------------';
PRINT '18.2 Locate CircularString Segment By Length With/Without offset...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0) as linestring
)
SELECT f.offset, f.linestring.AsTextZM() as tLinestring, f.linestring
  FROM (SELECT 'NONE' as offset, [lrs].[STFindSegmentByLengthRange](e.Linestring, 14.2, 30.1, 0.0, 1, 3, 2) as linestring FROM data as e
        union all
        SELECT '-1.1',           [lrs].[STFindSegmentByLengthRange](e.linestring, 14.2, 30.1, -1.1, 1, 3, 2) as linestring FROM data as e
        union all
        SELECT '+1.1',           [lrs].[STFindSegmentByLengthRange](e.linestring, 14.2, 30.1, +1.1, 1, 3, 2) as linestring FROM data as e
       ) as f;
GO

-- LengthsOfCircularStringNoOffset
-- CIRCULARSTRING (
-- 8.375 9.991 NULL 15.4, 
-- 10.123 10.123 NULL 15.32, 
-- 19.897 1.559 NULL 31.51)

PRINT '-----------------------------------------------------------------';
PRINT '19.1 Locate Segment By Measures With/Without offset...';
PRINT 'NO Z and M when linestring with > 1 segments (2 Points) is offset';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,115.73 903.305, 102.284 923.026,99.147 899.271,110.8 902.707,90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
--  UNION ALL
--  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT f.offset, f.linestring -- .AsTextZM() as tLinestring -- , f.linestring
  FROM (SELECT 'NONE' as offset, [lrs].[STFindSegmentByMeasureRange](e.mLinestring, 5.1, 20.2, 0.0, 1, 3, 2) as linestring FROM mLine as e
        union all
        SELECT '-1.1',           [lrs].[STFindSegmentByMeasureRange](e.mLinestring, 5.1, 20.2, -1.1, 1, 3, 2) as Lengths2Segment FROM mLine as e
        union all
        SELECT '+1.1',           [lrs].[STFindSegmentByMeasureRange](e.mLinestring, 5.1, 20.2, +1.1, 1, 3, 2) as Lengths2Segment FROM mLine as e
       ) as f;
GO

-- offset tLinestring
-- ------ ----------------------------------------------------------------------------------------------------------------------------
--   NONE LINESTRING (66.134 910.128 NULL 5.1, 73.036 899.855 NULL 18.48, 91.9 892.63 NULL 20.2)
--   NONE LINESTRING (66.134 910.128 NULL 5.1, 73.036 899.855 NULL 18.47)
--   -1.1 LINESTRING (92.293 893.657, 73.755 900.758, 67.047 910.741)
--   -1.1 LINESTRING (67.047 910.741 NULL 5.1, 73.949 900.468 NULL 18.47)
--   +1.1 LINESTRING (65.221 909.515, 72.123 899.242, 72.173 899.173, 72.227 899.109, 72.287 899.05, 72.351 898.994, 72.419 898.945, 72.49 898.9, 72.565 898.861, 72.643 898.828, 91.507 891.603)
--   +1.1 LINESTRING (65.221 909.515 NULL 5.1, 72.123 899.242 NULL 18.47)

PRINT '-------------------------------------------------------------------';
PRINT '19.2 Locate CircularString Segment By Measure With/Without offset...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0) as linestring
)
SELECT f.offset, f.linestring.AsTextZM() as tLinestring, f.linestring
  FROM (SELECT 'NONE' as offset, [lrs].[STFindSegmentByMeasureRange](e.Linestring, 14.2, 30.1,  0.0, 1, 3, 2) as linestring FROM data as e
        union all
        SELECT '-1.1',           [lrs].[STFindSegmentByMeasureRange](e.linestring, 14.2, 30.1, -1.1, 1, 3, 2) as linestring FROM data as e
        union all
        SELECT '+1.1',           [lrs].[STFindSegmentByMeasureRange](e.linestring, 14.2, 30.1, +1.1, 1, 3, 2) as linestring FROM data as e
       ) as f;
GO

-- offset tLinestring
-- ------ ----------------------------------------------------------------------------------------
-- NONE   CIRCULARSTRING (7.226 9.731 NULL 14.2, 10.123 10.123 NULL 15.32, 19.601 2.921 NULL 30.1)
-- -1.1   CIRCULARSTRING (6.921 10.788 NULL 14.2, 10.136 11.223 NULL 15.32, 20.657 3.229 NULL 30.1)
-- +1.1   CIRCULARSTRING (7.531 8.674 NULL 14.2, 10.11 9.023 NULL 15.32, 18.545 2.613 NULL 30.1)

PRINT '**************************************************';

PRINT '-------------------------------------------------';
PRINT '20. Test Length/Measure Support Functions ....';
PRINT '20.1 Locate Point On CircularString By Length (no offset)...';
GO

select [lrs].[STFindPointByLength] (
                /* @p_circular_arc */ geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0),
                /* @p_length       */ 31.0,
                /* @p_offset       */ 0.0,
                /* @p_radius_check */ 1,
                /* @p_round_xy     */ 3,
                /* @p_round_zm     */ 2
             ).AsTextZM();
GO
-- POINT (19.986 0.664 NULL 32.43)

PRINT '---------------------------------------------';
PRINT '20.2 Locate Point On CircularString By Measure (no offset)...';
GO

select [lrs].[STFindPointByMeasure] (
                /* @p_circular_arc */ geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0),
                /* @p_measure      */ 32.0,
                /* @p_offset       */ 0.0,
                /* @p_radius_check */ 1,
                /* @p_round_xy     */ 3,
                /* @p_round_zm     */ 2
            ).AsTextZM();
GO
-- POINT (19.955 1.084 NULL 32)

PRINT '---------------------------------------------';
PRINT '20.3 Split CircularString By Length (no offset)...';
GO

select [lrs].[STSplitSegmentByLength] (
                /* @p_circular_arc */ geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0),
                /* @p_start_length */ 14.0,
                /* @p_end_length   */ 28.0,
                /* @p_offset       */ 0.0,
                /* @p_radius_check */ 1,
                /* @p_round_xy     */ 3,
                /* @p_round_zm     */ 2
             ).AsTextZM();
-- CIRCULARSTRING (
-- 8.178   9.956 NULL 15.19, 
-- 10.123 10.123 NULL 15.32, 
-- 19.38   3.591 NULL 29.39 )
GO

PRINT '---------------------------------------------';
PRINT '20.4 Split CircularString By Measure (no offset)...';
GO

select [lrs].[STSplitSegmentByMeasure] (
                /* @p_circular_arc  */ geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0),
                /* @p_start_measure */ 15.0,
                /* @p_end_measure   */ 29.0,
                /* @p_offset        */ 0.0,
                /* @p_radius_check  */ 1,
                /* @p_round_xy      */ 3,
                /* @p_round_zm      */ 2
             ).AsTextZM();
-- CIRCULARSTRING (7.992 9.92 NULL 15, 10.123 10.123 NULL 15.32, 19.242 3.945 NULL 29)
GO

PRINT '---------------------------------------------';
PRINT '20.5 Split LineString By Length (no offset)...';
GO

select [lrs].[STSplitSegmentByLength] (
                /* @p_circular_arc */ geometry::STGeomFromText('LINESTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32)',0),
                /* @p_start_length */ 3.0,
                /* @p_end_length   */ 5.0,
                /* @p_offset       */ 0.0,
                /* @p_radius_check */ 1,
                /* @p_round_xy     */ 3,
                /* @p_round_zm     */ 2
             ).AsTextZM();
-- LINESTRING (2.121 2.121 NULL 4, 3.536 3.536 NULL 6)
GO

PRINT '---------------------------------------------';
PRINT '20.6 Split LineString By Measure (no offset)...';
GO

select [lrs].[STSplitSegmentByMeasure] (
                /* @p_circular_arc  */ geometry::STGeomFromText('LINESTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32)',0),
                /* @p_start_measure */ 4.0,
                /* @p_end_measure   */ 6.0,
                /* @p_offset        */ 0.0,
                /* @p_radius_check */ 1,
                /* @p_round_xy      */ 3,
                /* @p_round_zm      */ 2
             ).AsTextZM();
-- LINESTRING (2.828 2.828 NULL 4, 4.243 4.243 NULL 6)
GO

PRINT '---------------------------------------------';
PRINT '20.7 Filter LineString Segments By Length...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT v.id, 
        v.min_id,
        v.max_id,
        v.segment_length,
        v.start_length,
        v.geometry_type,
        v.segment.AsTextZM() as geom
    FROM mLine as m 
	        cross apply
	    [$(owner)].[STSegmentize]( 
            m.mLinestring,
			'LENGTH_RANGE',
			NULL,
			NULL,
            30,
            50,
            3,
            3,3
        ) as v
    ORDER BY v.id;
GO

/*
id min_id max_id length           startLength      geom
-- ------ ------ ---------------- ---------------- -----------------------------------------------------------------
3  3      5      5.56025071377184 24.9578633024073 LINESTRING (80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52)
4  3      5      11.8181391513216 30.5181140161791 LINESTRING (79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34)
5  3      5      18.8975937621698 42.3362531675007 LINESTRING (91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23)
*/

PRINT '---------------------------------------------';
PRINT '18.7 Filter LineString Segments By Measure...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT v.id, 
        v.min_id,
        v.max_id,
        v.segment_length,
        v.start_length,
        v.geometry_type,
        v.segment.AsTextZM() as geom
    FROM mLine as m 
	        cross apply
	    [$(owner)].[STSegmentize]( 
            m.mLinestring,
			'MEASURE_RANGE',
			NULL,
			NULL,
            29,
            49,
            3,
            3,3
        ) as v
    ORDER BY v.id;
GO

/*
id min_id max_id length           startLength      geom
-- ------ ------ ---------------- ---------------- -----------------------------------------------------------------
3  3      5      5.56025071377184 0                LINESTRING (80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52)
4  3      5      11.8181391513216 5.56025071377184 LINESTRING (79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34)
5  3      5      18.8975937621698 17.3783898650934 LINESTRING (91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23)
*/

