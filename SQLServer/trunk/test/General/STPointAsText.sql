SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[PointAsText] ...';
GO

With Data As (
  select CAST('XY' as varchar(4)) as ords, CAST([$(owner)].[STPointAsText]('XY',0.1,0.2,0.3,0.41,3,3,2,1) as varchar(40)) as coords
  union all
  select 'XYZ'                    as ords, [$(owner)].[STPointAsText]('XYZ',0.1,0.2,0.3,0.41,3,3,2,1) as coords
  union all
  select 'XYM'                    as ords, [$(owner)].[STPointAsText]('XYM',0.1,0.2,0.3,0.41,3,3,2,1) as coords
  union all
  select 'XYZM'                   as ords, [$(owner)].[STPointAsText]('XYZM',0.1,0.2,0.3,0.41,3,3,2,1) as coords
)
select a.ords,
       geometry::STGeomFromText (
         'POINT (' + a.coords + ')',0).AsTextZM() as point
  from data as a;
GO

select case when t.IntValue = 1 then 'XY' 
            when t.IntValue = 2 then 'XYZ'
            when t.IntValue = 3 then 'XYM'
            when t.IntValue = 4 then 'XYZM'
            when t.IntValue = 5 then 'XYZM'
        end as CoordType,
       [$(owner)].[STPointAsText] ( 
          /* @p_dimensions */ case when t.IntValue = 1 then 'XY' 
                                   when t.IntValue = 2 then 'XYZ'
                                   when t.IntValue = 3 then 'XYM'
                                   when t.IntValue = 4 then 'XYZM'
                                   when t.IntValue = 5 then 'XYZM'
                                end,
          /* @p_X          */ 123.45678,
          /* @p_Y          */ 459.298223,
          /* @p_Z          */ case when t.IntValue = 4 then NULL when t.IntValue=5 then 784.903 end,
          /* @p_M          */ 1.345,
          /* @p_round_x    */ 3,
          /* @p_round_y    */ 3,
          /* @p_round_z    */ 2,
          /* @p_round_m    */ 2 )
  from [$(owner)].[GENERATE_SERIES](1,4,1) as t;
GO

SELECT [$(owner)].[STPointGeomAsText] (geometry::STPointFromText('POINT (0.1232332 0.21121 0.1213 0.41)',0),3, 2, 1) as point;
GO

SELECT [$(owner)].[STPointGeomAsText] (geometry::STPointFromText('POINT (0.1232332 0.21121 NULL 0.41)',0),3, 2, 1) as point;
GO


