SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Test STNumArray and STArray ...';
GO

Declare @array xml
select 'Empty Array' as test, $(owner).STNumArray(@array);
Set @array = $(owner).STArray(@array,1,'insert',geometry::Point(1,2,0).STAsBinary(),0);
select 'Insert into Empty ' as test, @array;
Set @array = $(owner).STArray(@array,2,'insert',geometry::Point(2,2,0).STAsBinary(),0);
select 'Insert at position 2 (end)' as test, @array;
Set @array = $(owner).STArray(@array,0,'insert',geometry::Point(3,3,0).STAsBinary(),0);
select 'Insert at beginning ' as test, @array;
Set @array = $(owner).STArray(@array,0,'update',geometry::Point(4,4,0).STAsBinary(),0);
select 'Update first geometry' as test, @array;
Set @array = $(owner).STArray(@array,0,'delete',NULL,0);
select 'Delete first geometry' as test, @array;
Set @array = $(owner).STArray(@array,-1,'delete',NULL,0);
select 'Delete last geometry ' as test, @array;
Declare @v_geomXML xml;
Declare @v_vcWKB   varchar(max);
Declare @v_WKB     varbinary(max);
Declare @v_geom    geometry;
Declare @v_srid    int;
Set @v_geomXML = $(owner).STArray(@array,1,'select',NULL,0);
Set @v_vcWKB   = @v_geomXML.value('(/Geometry)[1]','varchar(max)');
Set @v_srid    = @v_geomXML.value('(/Geometry/@srid)[1]','int');
Set @v_geom    = geometry::STGeomFromWKB(CAST(@v_vcWKB AS xml).value('xs:base64Binary(sql:variable("@v_vcWKB"))', 'varbinary(max)'),0);
select 'Select First Geometry ' as test, @v_geomXML, @v_vcWKB, @v_geom.AsTextZM(), @v_geom.STSrid;
select 'Size' as test, $(owner).STNumArray(@array);
GO


