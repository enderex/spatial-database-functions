SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(cogoowner)].[STGreatCircleBearing] ...';
GO

select [$(cogoowner)].[STGreatCircleBearing] (
          [$(cogoowner)].[DMS2DD](149,0,0),
          [$(cogoowner)].[DMS2DD](-32,0,0),
          [$(cogoowner)].[DMS2DD](100,0,0),
          [$(cogoowner)].[DMS2DD](10,0,0)
       ) as GCB;
GO

Print 'Testing [$(cogoowner)].[STGreatCircleDistance] ...';
GO

-- Null will force default use of WGS84 flattening and equatorial radius
select [$(cogoowner)].[STGreatCircleDistance] (
         [$(cogoowner)].[DMS2DD]( 90,0,0),0,
         [$(cogoowner)].[DMS2DD](100,0,0),0,
         NULL,NULL) as gcd_wgs84;
GO

-- Hardcoded flattening for WGS84 ...
select [$(cogoowner)].[STGreatCircleDistance] (
          [$(cogoowner)].DMS2DD(90,0,0), 0,
          [$(cogoowner)].DMS2DD(100,0,0),0,
          6378.137, 
          298.257223563 )
       As GCD_90_0_to_100_0;
GO


