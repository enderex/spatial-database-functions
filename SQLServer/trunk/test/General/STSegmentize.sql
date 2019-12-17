SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Testing [$(owner)].[STSegmentize] ...';
GO

select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326454.7 5455793.7 1,326621.3 5455813.7 2,326455.4 5455796.6 3,326454.7 5455793.7 4)))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('LINESTRING(0 0, 1 1, 2 2, 3 3)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('LINESTRING(0 1 2 2.1, 2 3 2.1 3.4, 4 5 2.3 5.4, 6 7 2.2 6.7)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('POLYGON((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7))',28356) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('MULTIPOLYGON(((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7)),((326771.6 5455831.6,326924.1 5455849.9,326901.9 5455874.2,326900.7 5455875.8,326888.9 5455867.3,326866 5455853.1,326862 5455851.2,326847.4 5455845.8,326827.7 5455841.2,326771.6 5455831.6)))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('MULTIPOLYGON(((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7)),((326771.6 5455831.6,326924.1 5455849.9,326901.9 5455874.2,326900.7 5455875.8,326888.9 5455867.3,326866 5455853.1,326862 5455851.2,326847.4 5455845.8,326827.7 5455841.2,326771.6 5455831.6)))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('MULTIPOLYGON (((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((80 80, 100 80, 100 100, 80 100, 80 80)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('CIRCULARSTRING (0 0, 0 4,3 6.3246, 5 5, 6 3, 5 0,0 0)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 15 -5, 10 -10,15 -15)',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 2, 2 0, 4 2), CIRCULARSTRING(4 2, 2 4, 0 2))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('COMPOUNDCURVE((3 5, 3 3), CIRCULARSTRING(3 3, 5 1, 7 3), (7 3, 7 5), CIRCULARSTRING(7 5, 5 7, 3 5))',0) ) as v;
GO
select v.* FROM [$(owner)].[STSegmentize] ( geometry::STGeomFromText('COMPOUNDCURVE ((4 4, 3 3, 2 2, 0 0),CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0))',0) ) as v;
GO

SELECT v.*
FROM [$(owner)].[STSegmentize](geometry::STGeomFromText(
'GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), 
                    POLYGON((100 10, 200 10,200 20,100 20,100 10)),
					CIRCULARSTRING(10 0, 15 5, 15 -5, 10 -10,15 -15),
                    POLYGON((100 0, 200 0,200 20,100 20,100 0),(110 5,190 5,190 15,110 15,110 5)),
                    CURVEPOLYGON( 
                         COMPOUNDCURVE(
						      (0 -23.43778, 0 23.43778), 
						      CIRCULARSTRING(0 23.43778, -45 30.43778, -90 23.43778), 
							  (-90 23.43778, -90 -23.43778), 
							  CIRCULARSTRING(-90 -23.43778, -45 -13.43778, 0 -23.43778) 
                          )
                    ), 
                    COMPOUNDCURVE(
					          CIRCULARSTRING(-80 -23.778, -35 13.78, -10 -23.78), 
						      (-10 -23.78, -11 -23.438) ) )'
,0)) as v;

use DEVDB
go

    SELECT v.id,
           v.min_id,
           v.max_id,
           v.geometry_type,
		   v.hierarchy,
           ROUND(v.sz,4) as sZ,
           ROUND(v.sm,4) as sm,
           11.0 as measure,
           ROUND(v.em,4) as em,
           ROUND(v.measure_range,3)     as m_range,
           ROUND(v.segment_length,4)    as segment_length,
           ROUND(v.start_length,4)      as length_to_start,
           ROUND(v.cumulative_length,4) as cumulative_length,
           v.cumulative_measure,
           v.prev_segment,
           v.segment,
           v.next_segment
      FROM [$(owner)].[STSegmentize] (
             /* @p_geometry     */ 
			 geometry::STGeomFromText('COMPOUNDCURVE ((2173369.79254475 259887.575230554 NULL 2600,2173381.122467 259911.320734575    NULL 2626.3106), CIRCULARSTRING (2173381.122467 259911.320734575   NULL 2626.3106,2173433.84355779 259955.557426129 NULL 2683.1,2173501.82006501 259944.806018785 NULL 2768.24))', 2274),
             -- [dbo].[STReverse](geometry::STGeomFromText('COMPOUNDCURVE ((2173369.79254475 259887.575230554 NULL 2600,2173381.122467 259911.320734575    NULL 2626.3106), CIRCULARSTRING (2173381.122467 259911.320734575   NULL 2626.3106,2173433.84355779 259955.557426129 NULL 2683.1,2173501.82006501 259944.806018785 NULL 2768.24))', 2274),3,3),
             -- [lrs].[STAddMeasure](geometry::STGeomFromText('MULTILINESTRING((0 0,1 1),(2 2,3 3),(4 4,5 5))',0),null,null,3,2),
             /* @p_filter       */ 'ALL', --'ALL', -- 'MEASURE_RANGE', -- 'LENGTH_RANGE', -- 'MEASURE',
             /* @p_point        */ NULL,
             /* @p_filter_value */ NULL,
             /* @p_start_value  */ 2704.1, -- 1.1,
             /* @p_end_value    */ 2604.1, -- 2.2
             4,3,3
           ) as v;


