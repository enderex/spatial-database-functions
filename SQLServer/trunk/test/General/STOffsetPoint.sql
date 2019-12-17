select [dbo].[STOffsetPoint](geometry::STGeomFromText('LINESTRING(147.5 -43.132 100, 147.41 -43.387 30000)',4326),0.25,-5).AsTextZM();
-- 'T_Vertex(p_x=>152.19245167,p_y=>-44.85985059,p_z=>7575
      
select [dbo].[STOffsetPoint](geometry::STGeomFromText('LINESTRING(147.5 -43.132 100,147.41 -43.387 30000)',4326),0.25,0).AsTextZM();
--'T_Vertex(p_x=>147.4775,p_y=>-43.19575,p_z=>7575
      
select [dbo].[STOffsetPoint](geometry::STGeomFromText('LINESTRING(147.5 -43.132 100, 147.41 -43.387 30000)',4326),0.25,5).AsTextZM();
--'T_Vertex(p_x=>142.76254833,p_y=>-41.53164941,p_z=>7575
      
select [dbo].[STOffsetPoint](geometry::STGeomFromText('LINESTRING(147.5 -43.132,147.41 -43.387)',4326),0.25,-5).AsTextZM();
--'T_Vertex(p_x=>152.19245167,p_y=>-44.85985059,p_z=>NULL
      
select [dbo].[STOffsetPoint](geometry::STGeomFromText('LINESTRING(147.5 -43.132,147.41 -43.387)',4326),0.25,0).AsTextZM();
--'T_Vertex(p_x=>147.4775,p_y=>-43.19575
      
select [dbo].[STOffsetPoint](geometry::STGeomFromText('LINESTRING(147.5 -43.132,147.41 -43.387)',4326),0.25,5).AsTextZM();
--'T_Vertex(p_x=>142.76254833,p_y=>-41.53164941
      
--*******************
--Circular Arcs...
select [dbo].[STOffsetPoint](geometry::STGeomFromText('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373,252230.478 5527000.0)',28355),0.25,5).AsTextZM();
--'SRID=28355;POINT (252335.098 5526872.307)';
      
select [dbo].[STOffsetPoint](geometry::STGeomFromText('CIRCULARSTRING(252230.478 5526918.373, 252400.08 526918.373,252230.478 5527000.0)',28355),0.25,0).AsTextZM();
--'SRID=28355;POINT (252336.21 5526867.432)';
      
select [dbo].[STOffsetPoint](geometry::STGeomFromText('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373,252230.478 5527000.0)',28355),0.25,-5).AsTextZM();
--'SRID=28355;POINT (252337.322 5526862.557)';
      
select [dbo].[STOffsetPoint](geometry::STGeomFromText('CIRCULARSTRING(252230.478 5526918.373 1.0, 252400.08 5526918.373 1.0, 252230.478 5527000.0 1.0)',28355),0.25,5).AsTextZM();
--'SRID=28355;POINTZ (252335.098 5526872.307 1)';
   