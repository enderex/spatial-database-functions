SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

select [dbo].[STSnapPointToGeom](
        geometry::STGeomFromText('POINT (2172251.39758337 257358.817891138)',2274),
        geometry::STGeomFromText('CIRCULARSTRING (2171796.8166267127 257562.7279690057, 2171785.1539784111 257183.20449278614, 2172044.2970194966 256905.68157368898)', 2274),
        NULL,
        3
       ).AsTextZM() as sPoint;
GO

select snap_within.IntValue as snap_within_distance,
       [dbo].[STSnapPointToGeom](
        geometry::STGeomFromText('POINT (2172251.39758337 257358.817891138)',2274),
        geometry::STGeomFromText('CIRCULARSTRING (2171796.8166267127 257562.7279690057, 2171785.1539784111 257183.20449278614, 2172044.2970194966 256905.68157368898)', 2274),
        snap_Within.IntValue,
        3
       ).AsTextZM() as sPoint
  from dbo.Generate_Series(100,600,100) as snap_within;
GO
