use $(usedbname)
go

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '****************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(cogoowner)].[STGeographicDistance]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STGeographicDistance];
  PRINT 'Dropped [$(cogoowner)].[STGeographicDistance] ...';
END;
GO

PRINT 'Creating [$(cogoowner)].[STGeographicDistance] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STGeographicDistance] ( 
  @p_point1 geography, 
  @p_point2 geography,
  @p_method varchar(20) = 'Latitude' -- Or Longitude or Point2Point
)
Returns float
AS
/****f* COGO/STGeographicDistance (2008)
 *  NAME
 *    STGeographicDistance -- Computes distance in meters along parallel latitude/medidian longitude or direct.
 *  SYNOPSIS
 *    Function [$(cogoowner)].[STGeographicDistance] (
 *               @p_point1 geography, 
 *               @p_point2 geography,
 *               @p_method varchar(20) = 'Latitude' -- Or Longitude or Point2Point
 *             )
 *     Returns float
 *  DESCRIPTION
 *    Computes distance between two points either:
 *     1 Along parallel of latitude;
 *     2. Meridian of Longitude
 *     3. Or directly from point to point.
 *  NOTE
 *     Uses geography STDistance function.
 *  INPUTS
 *    @p_point1 (geography) - Geographic point
 *    @p_point2 (geography) - Geographic point
 *    @p_method   (varchar) - Type of distance:  Latitude, Longitude, or Point2Point
 *  RESULT
 *    distance      (float) - Distance in meters.
 *  EXAMPLE
 *    with two_points as (
 *      select geography::Point(55.4748508,12.1603670,4268) as point1,
 *             geography::Point(55.4786191,12.1713976,4268) as point2
 *    )
 *    select srid, method, uom_distance, srs.unit_of_measure,
 *           uom_distance * CAST(srs.unit_conversion_factor as float) as meters
 *      from (select 'Longitude' as method,
 *                   point1.STSrid as srid,
 *                   [cogo].[STGeographicDistance] (point1,point2,'Longitude') as uom_distance
 *              from two_points
 *            union all
 *            select 'Latitude' as method,
 *                   point1.STSrid as srid,
 *                   [cogo].[STGeographicDistance] (point1,point2,'Latitude') as uom_distance
 *              from two_points
 *            union all
 *            select 'Point2Point' as method,
 *                   point1.STSrid as srid,
 *                   [cogo].[STGeographicDistance] (point1,point2,'Point2Point') as uom_distance
 *              from two_points
 *           ) as f
 *           inner join
 *           sys.spatial_reference_systems as srs
 *           on (srs.spatial_reference_id = f.srid)
 *    GO
 *    
 *    srid method      uom_distance     unit_of_measure meters
 *    4268 Longitude   1376.48851124913 US survey foot  419.554537886726
 *    4268 Latitude    2288.65879496564 US survey foot  697.584596787393
 *    4268 Point2Point 2670.61416540797 US survey foot  814.004826690991
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - October 2019 - SQL Server TSQL Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  return case when UPPER(COALESCE(@p_method,'Longitude')) IN ('LONGITUDE','LON','LONG')
              then @p_point1
                     .STDistance(
                        geography::Point(@p_point2.Lat,@p_point1.Long,@p_point1.STSrid)
                   )
              when UPPER(COALESCE(@p_method,'Latitude')) IN ('LATITUDE','LAT')
              then @p_point1
                     .STDistance(
                        geography::Point(@p_point1.Lat,@p_point2.Long,@p_point1.STSrid)
                   )
              else @p_point1.STDistance(@p_point2)
           end;
End;
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
        ) as f
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
       on (srs.spatial_reference_id = f.srid)
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
       on (srs.spatial_reference_id = f.srid)
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
       ) as f
GO

