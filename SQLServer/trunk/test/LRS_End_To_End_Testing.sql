use SPATIALDB
go

PRINT '-------------------------------------------------';
PRINT '1. Original Linestring ...';
GO
SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring;
GO
Print 'LRS_1.PNG';
GO

PRINT '-------------------------------------------------';
PRINT '2. Add Measure ... ';
GO
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
)
SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ).AsTextZM() as mLinestring
  FROM data as d;
GO
-- mLinestring
-- LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23, 98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)

PRINT '-------------------------------------------------';
PRINT '3. Add Z to Measured Line... ';
GO
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [dbo].[STAddZ](d.mlinestring, 5.34, 8.3837, 3,2 ).AsTextZM() as zmLinestring
  FROM mLine as d;
GO
-- zmLinestring
-- LINESTRING (63.29 914.361 5.34 1, 73.036 899.855 5.54 18.48, 80.023 897.179 5.84 25.96, 79.425 902.707 6.19 31.52, 91.228 903.305 6.69 43.34, 79.735 888.304 7.4 62.23, 98.4 883.584 8.34 81.49, 115.73 903.305 9.59 107.74, 102.284 923.026 11.11 131.61, 99.147 899.271 12.92 155.57, 110.8 902.707 14.86 167.72, 90.78 887.02 17.11 193.15, 96.607 926.911 19.82 233.47, 95.71 926.313 22.55 234.55, 95.412 928.554 25.3 236.81, 101.238 929.002 28.13 242.65, 119.017 922.279 8.38 261.66)

PRINT '-------------------------------------------------';
PRINT '4. Reset Measure (All M ordinates set to -9999)... ';
GO
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
)
SELECT [lrs].[STResetMeasure] (
              [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ),
			  -9999, 3,2 ) .AsTextZM()		   
		    as mLinestring
  FROM data as d;
GO
-- mLinestring
-- LINESTRING (63.29 914.361 NULL -9999, 73.036 899.855 NULL -9999, 80.023 897.179 NULL -9999, 79.425 902.707 NULL -9999, 91.228 903.305 NULL -9999, 79.735 888.304 NULL -9999, 98.4 883.584 NULL -9999, 115.73 903.305 NULL -9999, 102.284 923.026 NULL -9999, 99.147 899.271 NULL -9999, 110.8 902.707 NULL -9999, 90.78 887.02 NULL -9999, 96.607 926.911 NULL -9999, 95.71 926.313 NULL -9999, 95.412 928.554 NULL -9999, 101.238 929.002 NULL -9999, 119.017 922.279 NULL -9999)

PRINT '-------------------------------------------------';
PRINT '5. Remove Measure (Should equal original linestring)... ';
GO
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
)
SELECT d.linestring.STEquals( 
           [lrs].[STRemoveMeasure] (
              [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ),
			  3,2 )
	   ) as equals
  FROM data as d;
GO
-- equals
--      1

PRINT '-------------------------------------------------';
PRINT '6. Inspect Start, End Measures, Measure Range, Ascending or Descending...';
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
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
--            1     261.66       260.66              TRUE             FALSE

PRINT '-------------------------------------------------';
PRINT '7. LRS Validity ...';
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STValidMeasure](e.mLinestring,0.0)                            as ValidMeasure0,
       [lrs].[STValidMeasure](e.mLinestring,e.mLinestring.STStartPoint().M) as ValidStartPoint,
       [lrs].[STValidMeasure](e.mLinestring,10.0)                           as ValidMeasure10,
       [lrs].[STValidLrsPoint](e.mLinestring.STPointN(5))                   as ValidLrsMeasure
  FROM mLine as e;
GO
-- ValidMeasure0 ValidStartPoint ValidMeasure10 ValidLrsMeasure
-- ------------- --------------- -------------- ---------------
--             0               1              1               1

PRINT '-------------------------------------------------';
PRINT '8. Percentages ...';
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT ROUND([lrs].[STMeasureToPercentage](e.mLinestring, e.mLinestring.STLength()/4.0),1) as Percentage,
       ROUND([lrs].[STPercentageToMeasure](e.mLinestring, 25.3),2)                         as Measure
  FROM mLine as e;
GO
-- Percentage Measure
-- ---------- -------
--       24.6   66.95

PRINT '-------------------------------------------------';
PRINT '9. Reverse Measures ...';
GO
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STIsMeasureIncreasing](f.rMeasuredGeom) as MeasureIncreasing,
       [lrs].[STIsMeasureDecreasing](f.rMeasuredGeom)  as MeasureDecreasing,
	   f.rMeasuredGeom.AsTextZM() as geom
  FROM (SELECT [lrs].[STReverseMeasure](e.mLinestring,3,2) as rMeasuredGeom
          FROM mLine as e
	) as f;
GO
-- MeasureIncreasing MeasureDecreasing geom
-- ----------------- ----------------- -------------------------------------------------------
-- FALSE             TRUE              LINESTRING (63.29 914.361 NULL 261.66, 73.036 899.855 NULL 244.18, 80.023 897.179 NULL 236.7, 79.425 902.707 NULL 231.14, 91.228 903.305 NULL 219.32, 79.735 888.304 NULL 200.43, 98.4 883.584 NULL 181.17, 115.73 903.305 NULL 154.92, 102.284 923.026 NULL 131.05, 99.147 899.271 NULL 107.09, 110.8 902.707 NULL 94.94, 90.78 887.02 NULL 69.51, 96.607 926.911 NULL 29.19, 95.71 926.313 NULL 28.11, 95.412 928.554 NULL 25.85, 101.238 929.002 NULL 20.01, 119.017 922.279 NULL 1)

PRINT '-------------------------------------------------';
PRINT '10. Scale Measured Line ...';
GO
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STScaleMeasure](e.mLinestring, 0.0, e.mLinestring.STLength(),0.5,3,2).AsTextZM() as ScaledMeasure
  FROM mLine as e;
GO
-- ScaledMeasure
-- LINESTRING (63.29 914.361 NULL 0.5, 73.036 899.855 NULL 17.98, 80.023 897.179 NULL 25.46, 79.425 902.707 NULL 31.02, 91.228 903.305 NULL 42.84, 79.735 888.304 NULL 61.73, 98.4 883.584 NULL 80.99, 115.73 903.305 NULL 107.24, 102.284 923.026 NULL 131.11, 99.147 899.271 NULL 155.07, 110.8 902.707 NULL 167.22, 90.78 887.02 NULL 192.65, 96.607 926.911 NULL 232.97, 95.71 926.313 NULL 234.05, 95.412 928.554 NULL 236.31, 101.238 929.002 NULL 242.15, 119.017 922.279 NULL 260.66)

PRINT '=================================================';
PRINT '  Linear Referencing / Dynamic Segmentation Tests';
PRINT '=================================================';
GO

PRINT 'Locate Point By .....';
PRINT '-------------------------------------------------';
PRINT '11. Locate Point By Ratio ...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength() + 0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindPointByRatio](e.mLinestring, 0.5, 0.0, 3, 2).AsTextZM() as PointByRatio
  FROM mLine as e;
GO
-- PointByRatio
-- POINT (102.442 922.794 NULL 130.33)

PRINT '-------------------------------------------------';
PRINT '12. Locate Point Using By Length (no offset)...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0,d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindPointByLength](e.mLinestring, 1.0, 0.0, 3, 2).AsTextZM() as Length2PointNoOffset
  FROM mLine as e;
GO
-- Length2PointNoOffset
-- POINT (63.848 913.531 NULL 1.07)

PRINT '-------------------------------------------------';
PRINT '13. Locate Point By Measure (no offset)...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindPointByMeasure](e.mLinestring, 2.0, 0.0, 3, 2).AsTextZM() as Measure2Point10Offset
  FROM mLine as e;
GO
-- Measure2Point10Offset
-- POINT (63.848 913.531 NULL 2)

PRINT 'Given a Point, Compute Measures and Offsets .....';
PRINT '----------------------------------------------------------';
PRINT '14. Find Measure using Point from STFindPointByMeasure ...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999,3,2) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindMeasureByPoint] (
             e.mLinestring, 
             [lrs].[STFindPointByMeasure](e.mLinestring, 50.0, 0.0, 3, 2),
             3, 2) as measure
  FROM mLine as e;
GO
-- measure
-- 50 (Correct)

PRINT '----------------------------------------------------';
PRINT '15. Locate Point By Measure, with 1.1m Offset ...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindPointByMeasure](e.mLinestring, 50.0, 1.1, 3, 2).AsTextZM() as Measure2Point10Offset
  FROM mLine as e;
GO
-- Measure2Point10Offset
-- POINT (86.305 898.687 NULL 50)

PRINT '-----------------------------------------------------------------------';
PRINT '16. Get Offset of Located Measure with 1.1m Offset: should return 1.1 M ...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT round(
         [lrs].[STFindOffset](e.mLinestring, 
                              [lrs].[STFindPointByMeasure](e.mLinestring, 50.0, 1.1, 3, 2),
                              3, 2),
         2) as Offset
  FROM mLine as e;
GO
-- Offset
-- 1.1 (Correct)

PRINT '-----------------------------------------------------------------------------';
PRINT '17. Get Measure of Located Measure (50) with 1.1m Offset: should return 50 ...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT [lrs].[STFindMeasure](e.mLinestring, 
                             [lrs].[STFindPointByMeasure](e.mLinestring, 50.0, 1.1, 3, 2),
						     3, 2) as measure
  FROM mLine as e;
GO
-- measure
-- 50 (Correct)

PRINT '**************************************************';
PRINT 'Extract Linear Segments via Range variables...';
GO

PRINT '-------------------------------------------------';
PRINT '18.1 Locate Segment By Length With/Without offset...';
PRINT 'NO Z and M when linestring with > 1 segments (2 Points) is offset';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,115.73 903.305, 102.284 923.026,99.147 899.271,110.8 902.707,90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
  UNION ALL
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT f.offset, f.linestring.AsTextZM() as tLinestring -- , f.linestring
  FROM (
SELECT 'NONE' as offset, [lrs].[STFindSegmentByLengthRange](e.mLinestring, 5.1, 20.2, 0.0, 3, 2) as linestring FROM mLine as e
union all
SELECT '-1.1', [lrs].[STFindSegmentByLengthRange](e.mLinestring, 5.1, 20.2, -1.1, 3, 2) as Lengths2Segment FROM mLine as e
union all
SELECT '+1.1', [lrs].[STFindSegmentByLengthRange](e.mLinestring, 5.1, 20.2, +1.1, 3, 2) as Lengths2Segment FROM mLine as e
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

PRINT '18.2 Locate CircularString Segment By Length With/Without offset...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0) as linestring
)
SELECT f.offset, f.linestring.AsTextZM() as tLinestring, f.linestring
  FROM (
SELECT 'NONE' as offset, [lrs].[STFindSegmentByLengthRange](e.Linestring, 14.2, 30.1,  0.0, 3, 2) as linestring FROM data as e
union all
SELECT '-1.1',           [lrs].[STFindSegmentByLengthRange](e.linestring, 14.2, 30.1, -1.1, 3, 2) as linestring FROM data as e
union all
SELECT '+1.1',           [lrs].[STFindSegmentByLengthRange](e.linestring, 14.2, 30.1, +1.1, 3, 2) as linestring FROM data as e
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
  UNION ALL
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT f.offset, f.linestring.AsTextZM() as tLinestring -- , f.linestring
  FROM (
SELECT 'NONE' as offset, [lrs].[STFindSegmentByMeasureRange](e.mLinestring, 5.1, 20.2, 0.0, 3, 2) as linestring FROM mLine as e
union all
SELECT '-1.1',           [lrs].[STFindSegmentByMeasureRange](e.mLinestring, 5.1, 20.2, -1.1, 3, 2) as Lengths2Segment FROM mLine as e
union all
SELECT '+1.1',           [lrs].[STFindSegmentByMeasureRange](e.mLinestring, 5.1, 20.2, +1.1, 3, 2) as Lengths2Segment FROM mLine as e
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
  FROM (
SELECT 'NONE' as offset, [lrs].[STFindSegmentByMeasureRange](e.Linestring, 14.2, 30.1,  0.0, 3, 2) as linestring FROM data as e
union all
SELECT '-1.1',           [lrs].[STFindSegmentByMeasureRange](e.linestring, 14.2, 30.1, -1.1, 3, 2) as linestring FROM data as e
union all
SELECT '+1.1',           [lrs].[STFindSegmentByMeasureRange](e.linestring, 14.2, 30.1, +1.1, 3, 2) as linestring FROM data as e
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

select [lrs].[STFindArcPointByLength] (
                /* @p_circular_arc */ geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0),
                /* @p_length       */ 31.0,
                /* @p_offset       */ 0.0,
                /* @p_round_xy     */ 3,
                /* @p_round_zm     */ 2
             ).AsTextZM();
GO
-- POINT (19.986 0.664 NULL 32.43)

PRINT '20.2 Locate Point On CircularString By Measure (no offset)...';
GO

select [lrs].[STFindArcPointByMeasure] (
                           /* @p_circular_arc */ geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0),
                           /* @p_measure      */ 32.0,
                           /* @p_offset       */ 0.0,
                           /* @p_round_xy     */ 3,
                           /* @p_round_zm     */ 2
                       ).AsTextZM();
GO
-- POINT (19.955 1.084 NULL 32)

PRINT '20.3 Split CircularString By Length (no offset)...';
GO

select [lrs].[STSplitCircularStringByLength] (
                /* @p_circular_arc */ geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0),
                /* @p_start_length */ 14.0,
                /* @p_end_length   */ 28.0,
                /* @p_offset       */ 0.0,
                /* @p_round_xy     */ 3,
                /* @p_round_zm     */ 2
             ).AsTextZM();
-- CIRCULARSTRING (
-- 8.178   9.956 NULL 15.19, 
-- 10.123 10.123 NULL 15.32, 
-- 19.38   3.591 NULL 29.39 )
GO

PRINT '20.4 Split CircularString By Measure (no offset)...';
GO

select [lrs].[STSplitCircularStringByMeasure] (
                /* @p_circular_arc  */ geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0),
                /* @p_start_measure */ 15.0,
                /* @p_end_measure   */ 29.0,
                /* @p_offset        */ 0.0,
                /* @p_round_xy      */ 3,
                /* @p_round_zm      */ 2
             ).AsTextZM();
-- CIRCULARSTRING (7.992 9.92 NULL 15, 10.123 10.123 NULL 15.32, 19.242 3.945 NULL 29)
GO

PRINT '20.5 Split LineString By Length (no offset)...';
GO

select [lrs].[STSplitLineSegmentByLength] (
                /* @p_circular_arc */ geometry::STGeomFromText('LINESTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32)',0),
                /* @p_start_length */ 3.0,
                /* @p_end_length   */ 5.0,
                /* @p_offset       */ 0.0,
                /* @p_round_xy     */ 3,
                /* @p_round_zm     */ 2
             ).AsTextZM();
-- LINESTRING (2.121 2.121 NULL 4, 3.536 3.536 NULL 6)
GO

PRINT '20.6 Split LineString By Measure (no offset)...';
GO
select [lrs].[STSplitLineSegmentByMeasure] (
                /* @p_circular_arc  */ geometry::STGeomFromText('LINESTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32)',0),
                /* @p_start_measure */ 4.0,
                /* @p_end_measure   */ 6.0,
                /* @p_offset        */ 0.0,
                /* @p_round_xy      */ 3,
                /* @p_round_zm      */ 2
             ).AsTextZM();
-- LINESTRING (2.828 2.828 NULL 4, 4.243 4.243 NULL 6)
GO

PRINT '20.7 Filter LineString Segments By Length...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT v.id, 
            min(v.id) over (partition by v.multi_tag) as first_id,
            max(v.id) over (partition by v.multi_tag) as last_id,
            v.length,
            v.startLength,
            v.geom.AsTextZM() as geom
       FROM mLine as m 
	         cross apply
	        [lrs].[STFilterLineSegmentByLength] ( 
                m.mLinestring,
                30,
                50,
                3,
                3
            ) as v
      ORDER BY v.id;
GO
/*
id first_id last_id length            startLength      geom
-- -------- ------- ----------------- ---------------- -----------------------------------------------------------------
3  3        5        5.56025071377184 24.9578633024073 LINESTRING (80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52)
4  3        5        11.8181391513216 30.5181140161791 LINESTRING (79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34)
5  3        5        18.8975937621698 42.3362531675007 LINESTRING (91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23)
*/

PRINT '18.7 Filter LineString Segments By Measure...';
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength()+0.999, 3,2 ) as mLinestring
    FROM data as d
)
SELECT v.id, 
            min(v.id) over (partition by v.multi_tag) as first_id,
            max(v.id) over (partition by v.multi_tag) as last_id,
            v.length,
            v.startLength,
            v.geom.AsTextZM() as geom
       FROM mLine as m 
	         cross apply
	        [lrs].[STFilterLineSegmentByMeasure] ( 
                m.mLinestring,
                29,
                49,
                3,
                3
            ) as v
      ORDER BY v.id;
/*
id first_id last_id length           startLength      geom
-- -------- ------- ---------------- ---------------- -----------------------------------------------------------------
3  3        5       5.56025071377184 0                LINESTRING (80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52)
4  3        5       11.8181391513216 5.56025071377184 LINESTRING (79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34)
5  3        5       18.8975937621698 17.3783898650934 LINESTRING (91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23)
*/

