SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(cogoowner)].[STGeographicDistance] ...';
GO

with two_points as (
  select geography::Point(55.4748508,12.1603670,4326) as point1,
         geography::Point(55.4786191,12.1713976,4326) as point2
)
select method, /* 4326's UOM is meters */ meters
  from (select 'Longitude' as method,
               [$(cogoowner)].[STGeographicDistance] (point1,point2,'Longitude') as meters
          from two_points
        union all
        select 'Latitude' as method,
               [$(cogoowner)].[STGeographicDistance] (point1,point2,'Latitude') as meters
          from two_points
        union all
        select 'Direct' as method,
               [$(cogoowner)].[STGeographicDistance] (point1,point2,'Direct') as meters
          from two_points
        ) as f;
GO

-- 4268 is US survey foot

with two_points as (
  select geography::Point(55.4748508,12.1603670,4268) as point1,
         geography::Point(55.4786191,12.1713976,4268) as point2
)
select srid, method, uom_distance, srs.unit_of_measure,
       uom_distance * CAST(srs.unit_conversion_factor as float) as meters
  from (select 'Longitude' as method,
               point1.STSrid as srid,
               [$(cogoowner)].[STGeographicDistance] (point1,point2,'Longitude') as uom_distance
          from two_points
        union all
        select 'Latitude' as method,
               point1.STSrid as srid,
               [$(cogoowner)].[STGeographicDistance] (point1,point2,'Latitude') as uom_distance
          from two_points
        union all
        select 'Point2Point' as method,
               point1.STSrid as srid,
               [$(cogoowner)].[STGeographicDistance] (point1,point2,'Point2Point') as uom_distance
          from two_points
       ) as f
       inner join
       sys.spatial_reference_systems as srs
       on (srs.spatial_reference_id = f.srid);
GO

with two_points as (
  select geography::Point(55.4748508,12.1603670,4268) as point1,
         geography::Point(55.4786191,12.1713976,4268) as point2
)
select srid, method, uom_distance, srs.unit_of_measure,
       uom_distance * CAST(srs.unit_conversion_factor as float) as meters
  from (select 'Point2Point' as method,
               point1.STSrid as srid,
               [$(cogoowner)].[STGeographicDistance] (point1,point2,'Point2Point') as uom_distance
          from two_points
       ) as f
       inner join
       sys.spatial_reference_systems as srs
       on (srs.spatial_reference_id = f.srid);
GO

with two_points as (
  select geography::Point(55.4748508,12.1603670,4326) as point1,
         geography::Point(55.4786191,12.1713976,4326) as point2
)
select parallel, parallel_meters, meridian, meridian_meters,
       parallel_meters / 50.0 as numTilesY,
       meridian_meters / 50.0 as numTilesX
  from (select 'Distance Along Constant Longitude' as parallel,
               [$(cogoowner)].[STGeographicDistance] (point1,point2,'Longitude') as parallel_meters
          from two_points
       ) as a,
       (select 'Distance Along Constant Latitude' as meridian,
               [$(cogoowner)].[STGeographicDistance] (point1,point2,'Latitude') as meridian_meters
          from two_points
       ) as f;
GO

