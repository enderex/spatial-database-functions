SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

Print 'Testing [$(owner)].[STRemoveSpikesByWKT] ...';
GO

select 'SQL Server Documentation'                                       as comment,[$(owner)].[STRemoveSpikesByWKT] ('LINESTRING(1 4, 3 4, 2 4, 2 0)',4283,10.0,8,2,2)
union all
select 'SQL Server Documentation Adjusted (Calls STRemoveSpikes)'       as comment,[$(owner)].[STRemoveSpikesByWKT] ('LINESTRING(1 4, 3 4.01, 2 4, 2 0)',4283,10.0,8,2,2)
union all
select 'Duplicate first/last, spike in middle, return first two points' as comment, [$(owner)].[STRemoveSpikesByWKT] ('LINESTRING(148.13719 -35.2973 5 0, 148.13737 -35.29527 10 10, 148.13719 -35.2973 6 16)',4283,10.0,8,2,2)
Union all
select 'Spike in middle'                                                as comment, [$(owner)].[STRemoveSpikesByWKT] ('LINESTRING(148.60735 -35.157845 356 0, 148.60724 -35.157917 87 87, 148.60733 -35.157997 9 96, 148.60724 -35.157917 5 101)',4283,10.0,8,2,2);
GO

select 'O' as id,     geometry::STGeomFromText('LINESTRING(148.60735 -35.157845 356 0, 148.60724 -35.157917 87 87, 148.60733 -35.157997 9 96, 148.60724 -35.157917 5 101)',4283) as line
union all
select 'L' as id, [$(owner)].[STRemoveSpikes] ('LINESTRING(148.60735 -35.157845 356 0, 148.60724 -35.157917 87 87, 148.60733 -35.157997 9 96, 148.60724 -35.157917 5 101)',10.0,8,2,2);
GO


