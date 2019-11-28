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

