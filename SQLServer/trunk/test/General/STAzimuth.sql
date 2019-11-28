
select case when [$(cogoowner)].[STDegrees]([$(cogoowner)].[STAzimuth] (10,0.123,0,0)) = [$(cogoowner)].[STBearing](10,0.123,0,0) then 'Equals' else 'Not Equal' end as az;
GO

