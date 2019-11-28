SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(lrsowner)].[STReverseMeasure] ...';
GO

With roads as (
select geometry::STGeomFromText('LINESTRING(6012823.67 2115982.17 NULL 0.0, 
                                            6012802.73 2116135.36 NULL 154.62, 
                                            6012808.02 2116172.29 NULL 191.92, 
                                            6012759.63 2116512.49 NULL 535.55, 
                                            6012710.22 2116859.9  NULL 886.46, 
                                            6012685.05 2117036.86 NULL 1065.2, 
                                            6012662.15 2117197.81 NULL 1227.77, 
                                            6012639.24 2117358.89 NULL 1390.47, 
                                            6012616.49 2117518.83 NULL 1552.02, 
                                            6012595.63 2117677.81 NULL 1712.36, 
                                            6012577.74 2117833.5  NULL 1869.08, 
                                            6012527.85 2118162.97 NULL 2202.3, 
                                            6012481.8  2118483.41 NULL 2526.04, 
                                            6012434.31 2118821.59 NULL 2867.54, 
                                            6012386.77 2119169.05 NULL 3218.24, 
                                            6012339.32 2119507.67 NULL 3560.16, 
                                            6012316.04 2119675.92 NULL 3730.02, 
                                            6012292.06 2119844.61 NULL 3900.4, 
                                            6012247.47 2120184.04 NULL 4242.75, 
                                            6012200.32 2120523.34 NULL 4585.31, 
                                            6012165.96 2120757.08 NULL 4821.56, 
                                            6012208.57 2120826.43 NULL 4902.96)',2872) as geom 
)
Select d.*
  From roads r
       CROSS APPLY 
       [$(owner)].[STDumpPoints] ( 
         [$(lrsowner)].[STReverseMeasure] ( r.geom, 3, 2 )
       ) as d;
GO

with data as (
select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.4 16.3, 3 6.3 1.6 20.2))',0) as Geom
)
select 'Before' as text, d.geom.AsTextZM() as rGeom from data as d
union all
select 'After' as text, [$(lrsowner)].[STReverseMeasure](d.geom,3,2).AsTextZM() as rGeom from data as d;
GO

