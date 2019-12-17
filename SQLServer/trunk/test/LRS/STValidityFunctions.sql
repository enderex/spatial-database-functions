SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(lrsowner)].[STValidLrsGeometry] and [$(lrsowner)].[STValidMeasure] ...';
GO

select t.IntValue,
       case when [$(lrsowner)].[STValidMeasure](geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
                                                cast(t.intValue as float) )
                 = 1 
            then 'Yes' 
            else 'No' 
        end as isMeasureWithinLinestring
  from [$(owner)].[GENERATE_SERIES](-1,30,2) as t;
GO

with data as (
  select geometry::STGeomFromText('CIRCULARSTRING ( 2173381.122467   259911.320734575 NULL 2626.3106, 2173433.84355779 259955.557426129 NULL 0, 2173501.82006501 259944.806018785 NULL 2768.24)',0) as p_linestring
)
select [$(lrsowner)].[STIsMeasureIncreasing] (p_linestring) as isIncrease,
       [$(lrsowner)].[STIsMeasureDecreasing] (p_linestring) as isDecrease,
       [$(lrsowner)].[STValidLrsGeometry](p_linestring)     as isValidGeom 
  from data as a;

select [$(lrsowner)].[STValidMeasure](geometry::STGeomFromText('CIRCULARSTRING (2173381.122467 259911.320734575 NULL 2626.3106,2173433.84355779 259955.557426129 NULL 0,2173501.82006501 259944.806018785 NULL 2768.24)',2274),2630) as is_measured
GO

select [$(lrsowner)].[STValidMeasure](geometry::STGeomFromText('COMPOUNDCURVE ((2173369.79254475 259887.575230554 NULL 2600,2173381.122467 259911.320734575 NULL 2626.3106),
 CIRCULARSTRING (2173381.122467 259911.320734575 NULL 2626.3106,2173433.84355779 259955.557426129 NULL 0,2173501.82006501 259944.806018785 NULL 2768.24))',2274),2600) as is_measured
GO
