SELECT CONCAT('Connected to ',QUOTENAME(DB_NAME())) as db_name;

select count(*) as functions_before_drop
  from [INFORMATION_SCHEMA].[ROUTINES]
 where routine_schema in ('dbo','lrs','cogo')
   and specific_name not like 'sp%'
   and specific_name not like 'fn%';
GO


Declare @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + N' DROP FUNCTION ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
FROM sys.objects
WHERE type_desc LIKE '%FUNCTION%';
Exec sp_executesql @sql;
SET @sql = '';
SELECT @sql = @sql + N' DROP PROCEDURE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
FROM sys.objects
WHERE type_desc LIKE '%PROCEDURE%';
Exec sp_executesql @sql;
GO

select count(*) as functions_after_drop
  from [INFORMATION_SCHEMA].[ROUTINES]
 where routine_schema in ('dbo','lrs','cogo')
   and specific_name not like 'sp%'
   and specific_name not like 'fn%';
GO

