USE DEVDB
GO

SELECT SCHEMA_NAME(schema_id) AS 'Schema',
	   name AS 'Function Name',
       TYPE,
       type_desc AS 'Function Type', 
       create_date AS 'Created Date',
	   so.modify_date as 'Modify Date'
  FROM sys.objects as so
 WHERE SCHEMA_NAME(schema_id) in ('dbo','lrs','cogo')
   and type in ('FN', 'IF', 'FN', 'AF', 'FS', 'FT', 'P')
 ORDER BY so.modify_date desc;

