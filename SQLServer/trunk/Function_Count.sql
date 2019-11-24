PRINT 'Functions/Procedures Summary by schema...';
GO

select f.category,f.routine_type,
       ISNULL(f.data_type,'TOTAL:') as data_type,
       f.count_by_type
  from (select case when routine_schema = 'lrs' then 'LRS'   else 'GENERAL' end category,
               routine_type, 
               case when data_type = 'TABLE'    then 'TABLE' else 'SCALAR'  end as data_type, 
               count(*) as count_by_type
          from [INFORMATION_SCHEMA].[ROUTINES]
         where routine_schema in ('dbo','lrs','cogo')
           and specific_name not like 'sp%'
           and specific_name not like 'fn%'
        group by ROLLUP(
                   case when routine_schema = 'lrs' then 'LRS' else 'GENERAL' end,
                   routine_type,
                   case when data_type = 'TABLE' then 'TABLE' else 'SCALAR' end
                 ) 
        ) as f
 where f.category is null 
    or (  f.category is not null 
      and f.data_type is not null
    )
order by f.category desc,f.count_by_type;
GO

PRINT 'Total number of functions and procedures by type...'
GO

select case when routine_schema = 'lrs' then 'LRS' else 'GENERAL' end category,
       count(*) as count_by_type
  from [INFORMATION_SCHEMA].[ROUTINES]
 where routine_schema in ('dbo','lrs','cogo')
   and specific_name not like 'sp%'
   and specific_name not like 'fn%'
group by case when routine_schema = 'lrs' then 'LRS' else 'GENERAL' end;
go

