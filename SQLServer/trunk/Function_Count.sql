PRINT 'Functions/Procedures Summary By Schema...';
GO

select f.category,f.routine_type, ISNULL(f.data_type,'TOTAL:') as data_type, f.count_by_type
  from (select case when r.routine_schema = 'lrs' then 'LRS'   else 'GENERAL' end category,
               r.routine_type, 
               case when r.data_type = 'TABLE'    then 'TABLE' else 'SCALAR'  end as data_type, 
               count(*) as count_by_type
          from [INFORMATION_SCHEMA].[ROUTINES] as r
         where r.routine_schema in ('dbo','lrs','cogo')
           and r.specific_name not like 'sp%'
           and r.specific_name not like 'fn%'
        group by ROLLUP(
                   case when r.routine_schema = 'lrs' then 'LRS' else 'GENERAL' end,
                   r.routine_type,
                   case when r.data_type = 'TABLE' then 'TABLE' else 'SCALAR' end
                 ) 
        ) as f
 where f.category is null 
    or (  f.category is not null 
      and f.data_type is not null
    )
order by f.category desc,f.count_by_type;
GO

PRINT 'Total number of functions and procedures by type...';
GO

select case when r.routine_schema = 'lrs' then 'LRS' else 'GENERAL' end category, count(*) as count_by_type
  from [INFORMATION_SCHEMA].[ROUTINES] as r
 where r.routine_schema in ('dbo','lrs','cogo')
   and r.specific_name not like 'sp%'
   and r.specific_name not like 'fn%'
group by case when r.routine_schema = 'lrs' then 'LRS' else 'GENERAL' end;
go

