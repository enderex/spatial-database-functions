SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(cogoowner)].[DMS2DD] ...';
GO

select [$(cogoowner)].[DMS2DD](-44,10,50) as dd
union all
select [$(cogoowner)].[DMS2DD](-32,10,45) as dd
union all
select [$(cogoowner)].[DMS2DD](147,10,0)  as dd;
GO

Print 'Testing [$(cogoowner)].[DMSS2DD] ...';
GO

SELECT a.DD
  FROM (SELECT 1 as id, [$(cogoowner)].[DMSS2DD]('43° 0''   50.00"S') as DD
  UNION SELECT 2 as id, [$(cogoowner)].[DMSS2DD]('43° 30''  45.50"N') as DD
  UNION SELECT 3 as id, [$(cogoowner)].[DMSS2DD]('147° 50'' 30.60"E') as DD
  UNION SELECT 4 as id, [$(cogoowner)].[DMSS2DD]('65° 10''  12.60"W') as DD
 ) a
ORDER BY a.id;
GO

Print 'Testing [$(cogoowner)].[DD2DMS] ...';
GO

select [$(cogoowner)].[DD2DMS](
                        [$(cogoowner)].[DMS2DD](-44,10,50),
                        'd','s','"'
       ) as dd_dms_dd;
GO


