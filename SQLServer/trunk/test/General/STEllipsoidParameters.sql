SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(cogoowner)].[STEllipsoidParameters] ...';
GO

select spatial_reference_id, 
       [$(cogoowner)].[STEllipsoidParameters](
           spatial_reference_id
       ) as a_f 
  from sys.spatial_reference_systems
 where spatial_reference_id in (4283,4326,4222);
GO

