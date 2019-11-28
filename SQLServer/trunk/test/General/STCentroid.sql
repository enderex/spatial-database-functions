SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing Centroid Functions...';
GO

-- SQL Server's STCentroid is NULL for MultiPoint
--
with multiPoint as (
  select CAST('XY MultiPoint'   as varchar(15)) as geomText, geometry::STGeomFromText('MULTIPOINT((0 0),(100 0),(100 100),(0 100),(150 110),(150 150),(110 150),(110 110))',0) as geom
  UNION ALL
  select CAST('XYZ MultiPoint'  as varchar(15)) as geomText, geometry::STGeomFromText('MULTIPOINT((0 0 0),(100 0 1),(100 100 2),(0 100 3),(150 110 4),(150 150 5),(110 150 6),(110 110 7))',0) as geom
  UNION ALL
  select CAST('XYZM MultiPoint' as varchar(15)) as geomText, geometry::STGeomFromText('MULTIPOINT((0 0 0 10),(100 0 1 12),(100 100 2 13),(0 100 3 14),(150 110 4 15),(150 150 5 16),(110 150 6 17),(110 110 7 18))',0) as geom
)
select geomText, action, geom
  from (
    select geomText, CAST('Original' as varchar(15)) as action, geom.AsTextZM() as geom from multiPoint as a
    union all
    select geomText, 'SQL .STCentroid()' as action, geom.STCentroid().AsTextZM() as geom from multiPoint
    union all
    select geomText, 'STCentroid_P'      as action, [$(owner)].[STCentroid_P](geom,3,2).AsTextZM() as geom from multiPoint
) as f
order by 1,2;
GO

-- STCentroid_A
--
with poly as (
   select geometry::STGeomFromText('POLYGON((2300 -700, 2800 -300, 2300 700, 2800 1100, 2300 1100, 1800 1100, 2300 400, 2300 200, 2100 100, 2500 100, 2300 -200, 1800 -300, 2300 -500, 2200 -400, 2400 -400, 2300 -700), (2300 1000, 2400  900, 2200 900, 2300 1000))',0) as geom
)
select 'O' as Label, geom.AsTextZM() from poly
union all
select 'A' as Label, $(owner).[STCentroid_A](geom,0,0,NULL,3,2).STAsText() as geom from poly
union all
select 'M' as Label, $(owner).[STCentroid_A](geom,0,1,NULL,3,2).STAsText() as geom from poly
union all
select 'U' as Label, $(owner).[STCentroid_A](geom,0,2,2050,3,2).STAsText() as geom from poly
union all
select 'S' as Label, geom.STCentroid().STAsText() as geom  from poly;
GO

With weightedPoly As (
   select geometry::STGeomFromText('POLYGON((258.72254365233152 770.97400259630615, 268.79365642517564 739.08214548229967, 278.86476919801976 707.1902883682933, 332.57737065318844 693.76213800450114, 366.14774656266889 676.97695004976094, 426.57442319973364 697.11917559544918, 520.57147574627891 737.40362668682576, 631.35371624756431 744.11770186872184, 829.41893411349884 797.83030332389046, 1547.8249785763801 791.11622814199438, 1205.4071442996797 895.18439346138371, 832.77597170444687 1039.5370098721496, 490.3581374277465 1086.5355361454222, 416.50331042688953 1076.464423372578, 381.25441572193506 1059.6792354178378, 346.00552101698065 1042.8940474630976, 320.82773908487036 1019.3947843264614, 295.64995715276001 995.89552118982499, 287.25736317538986 964.00366407581862, 278.86476919801976 932.11180696181225, 282.2218067889678 891.82735587043567, 277.18625040254574 858.25697996095528, 272.15069401612368 824.68660405147489, 258.72254365233152 770.97400259630615))',0) as geom
)
SELECT 'O' as Label,  geom.AsTextZM() from weightedPoly
union all 
SELECT 'A' as Label, $(owner).[STCentroid_A](geom,0,0,NULL,2,2).STAsText() as geom from weightedPoly
union all 
SELECT 'M' as Label, $(owner).[STCentroid_A](geom,0,1,NULL,2,2).STAsText() as geom from weightedPoly
union all 
SELECT 'U' as Label, $(owner).[STCentroid_A](geom,0,2,1200,2,2).STAsText() as geom from weightedPoly
union all
select 'S' as Label, geom.STCentroid().STAsText() as geom from weightedPoly;
GO

-- Multiline options....

with mPoly as (
  select geometry::STGeomFromText('MULTIPOLYGON (((0 0, 100 0, 100 100, 0 100, 0 0)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0) as geom
)
select case when t.IntValue = 0 then 'All' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'Largest' 
            when t.IntValue = 3 then 'Smallest' 
            else '' 
        end as mode,
       [$(owner)].[STCentroid_A]( geom, t.IntValue, 1 /* Weight By MBR not Vertices */, NULL, 3,2).STAsText() as geom --.STBuffer(t.IntValue*2 + 1) as geom 
  from mPoly as a
       cross apply
       $(owner).GENERATE_SERIES(0,3,1) as t
union all
select 'LINESTRING', 
       geom 
  from mPoly;
GO

-- STCentroid_L.......

-- Different distances along the linestring ....

With line As (
  SELECT geometry::STGeomFromText('LINESTRING(258.72254365233152 770.97400259630615, 268.79365642517564 739.08214548229967, 278.86476919801976 707.1902883682933, 332.57737065318844 693.76213800450114, 366.14774656266889 676.97695004976094, 426.57442319973364 697.11917559544918, 520.57147574627891 737.40362668682576, 631.35371624756431 744.11770186872184, 829.41893411349884 797.83030332389046, 1547.8249785763801 791.11622814199438, 1205.4071442996797 895.18439346138371, 832.77597170444687 1039.5370098721496, 490.3581374277465 1086.5355361454222, 416.50331042688953 1076.464423372578, 381.25441572193506 1059.6792354178378, 346.00552101698065 1042.8940474630976, 320.82773908487036 1019.3947843264614, 295.64995715276001 995.89552118982499, 287.25736317538986 964.00366407581862, 278.86476919801976 932.11180696181225, 282.2218067889678 891.82735587043567, 277.18625040254574 858.25697996095528, 272.15069401612368 824.68660405147489, 258.72254365233152 770.97400259630615)',0) as geom
)
SELECT 'O' as label, geom.AsTextZM() from line
union all
SELECT CONCAT(STR(t.intValue),'%') as label, 
       [$(owner)].[STCentroid_L](a.geom,0,CAST(t.IntValue as float)/100.0,3,2).STAsText() as geom -- .STBuffer((t.IntValue/10)+5) as geom
  FROM line as a
       cross apply
       [$(owner)].[generate_series](0,90,10) as t;
GO

-- Various multiline options

With mLine As (
  select CAST('MultiLine' as varchar(15)) as mode,
         geometry::STGeomFromText('MULTILINESTRING((0 0, 100 100),(200 200, 210 210),(500 500,750 750))',0) as geom
)
select mode,a.geom.AsTextZM() from mLine as a
union all
select case when t.IntValue = 0 then 'All' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'Largest' 
            when t.IntValue = 3 then 'Smallest' 
            else '' 
        end as mode,
       [$(owner)].[STCentroid_L](geom,t.IntValue,0.5,3,2).STAsText() as geom --.STBuffer(5+(t.IntValue*5)) as geom
  from mLine as a
       cross apply
       [$(owner)].[generate_series](0,2,1) as t;
GO

With mLine As (
  select CAST('GeometryCollection' as varchar(15)) as mode,
         geometry::STGeomFromText(
'GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), LINESTRING(1 1,2 2),LINESTRING(3 3,19 19) )',0) as geom
--'GEOMETRYCOLLECTION(LINESTRING(0 0,20 0,20 20,0 20,0 0), MULTILINESTRING((1 1,2 2),(3 3,19 19)) )',0) as geom
)
select mode,a.geom from mLine as a
union all
select case when t.IntValue = 0 then 'All' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'Largest' 
            when t.IntValue = 3 then 'Smallest' 
            else '' 
        end as mode,
       [$(owner)].[STCentroid_L](geom,t.IntValue,0.5,3,2).STBuffer(0.2) as geom
  from mLine as a
       cross apply
       [$(owner)].[generate_series](0,2,1) as t;
GO

-- *************************************

-- STCentroid wrapper tests...

select [$(owner)].[STCentroid] (
          /*@p_geometry             */ geometry::STGeomFromText('POINT(5 5)',0),
          /*@p_multi_mode           */ 0,
          /*@p_area_x_start         */ NULL,
          /*@p_area_x_ordinate_seed */ NULL,
          /*@p_line_position_ratio  */ NULL,
          /*@p_round_xy             */ 3,
          /*@p_round_zm             */ 2)
            .STAsText() as geom;
GO

-- MultiPoint ....

with mPoint as (
  select geometry::STGeomFromText('MULTIPOINT((0 0),(100 0),(100 100),(0 100),(150 110),(150 150),(110 150),(110 110))',0) as geom
)
select CAST(geom.STAsText() as varchar(20)) as centroid
  from mPoint
union all
select [$(owner)].[STCentroid] (
          /*@p_geometry             */ geom,
          /*@p_multi_mode           */ 0,
          /*@p_area_x_start         */ NULL,
          /*@p_area_x_ordinate_seed */ NULL,
          /*@p_line_position_ratio  */ NULL,
          /*@p_round_xy             */ 3,
          /*@p_round_zm             */ 2)
          .STAsText() as centroid
  from mPoint;
GO

-- MultiLineString...

with mLine as (
select CAST('MultiLine' as varchar(15)) as mode,
        geometry::STGeomFromText('MULTILINESTRING((0 0, 100 100),(200 200, 210 210),(500 500,750 750))',0) as geom
)
select mode, geom.AsTextZM() from mline as a
union all
select case when t.IntValue = 0 then 'all' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'largest' 
            when t.IntValue = 3 then 'smallest' 
            else '' 
        end as mode,
       [$(owner)].[STCentroid] (
          /*@p_geometry             */ geom,
          /*@p_multi_mode           */ t.IntValue,
          /*@p_area_x_start         */ NULL,
          /*@p_area_x_ordinate_seed */ NULL,
          /*@p_line_position_ratio  */ 0.5,
          /*@p_round_xy             */ 3,
          /*@p_round_zm             */ 2)
            .STAsText() as geom /*.STBuffer(t.IntValue*2 + 1) as geom */
  from mline as a
       cross apply
       [$(owner)].[GENERATE_SERIES](0,3,1) as t;
GO

-- Polygon .....

with mPoly as (
  select CAST('MultiPolygon' as varchar(15)) as mode, 
         geometry::STGeomFromText('MULTIPOLYGON (((0 0, 100 0, 100 100, 0 100, 0 0)), ((110 110, 150 110, 150 150, 110 150, 110 110)))',0) as geom
)
select mode, geom.AsTextZM() from mPoly as m
union all
select case when t.IntValue = 0 then 'All' 
            when t.IntValue = 1 then 'First' 
            when t.IntValue = 2 then 'Largest' 
            when t.IntValue = 3 then 'Smallest' 
            else '' 
       end as mode,
       [$(owner)].[STCentroid] (
          /*@p_geometry             */ geom,
          /*@p_multi_mode           */ t.IntValue,
          /*@p_area_x_start         */ 1,
          /*@p_area_x_ordinate_seed */ NULL,
          /*@p_line_position_ratio  */ NULL,
          /*@p_round_xy             */ 3,
          /*@p_round_zm             */ 2)
            .STAsText() as geom /*.STBuffer(t.IntValue*2 + 1) as geom */
  from mPoly as a
       cross apply
       [$(owner)].[GENERATE_SERIES](0,3,1) as t;
GO

