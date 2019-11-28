SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

PRINT 'Testing [$(cogoowner)].[STResection] ...';
GO

/*
Location is 0,0;
Remote sites:
1) -10, 0 angle 270.0
2)   0,10 angle 0.0
3)  10, 0 angle 90.0
*/

select 1 id, geometry::Point(  0,10,0).STBuffer(1) as point union all
select 2,    geometry::Point( 10, 0,0).STBuffer(1)          union all
select 3,    geometry::Point(-10, 0,0).STBuffer(1)          union all
Select 0, [$(cogoowner)].[STResection] ( 
            geometry::Point(  0,10,0),120.0,
            geometry::Point( 10, 0,0),120.0,
            geometry::Point(-10, 0,0),120.0,
            'I'
          ).STBuffer(2);
GO


