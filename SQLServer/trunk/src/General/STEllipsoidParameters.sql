USE $(usedbname)
GO

SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(cogoowner)].[STEllipsoidParameters]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STEllipsoidParameters];
  Print 'Dropped [$(cogoowner)].[STEllipsoidParameters] ...';
END;
GO

Print 'Creating [$(cogoowner)].[STEllipsoidParameters] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STEllipsoidParameters] (
  @p_srid integer
)
returns varchar(100)
As
Begin
  Declare
    @a_f varchar(100);
  --select CAST(SUBSTRING(wkt,1,CHARINDEX(',',wkt)-1)   as float) as a,
  --       CAST(SUBSTRING(wkt,CHARINDEX(',',wkt)+1,100) as float) as inverseF
  IF ( @p_srid is null ) 
    return null;
  SELECT @a_f = wkt
    FROM (SELECT SUBSTRING(wkt,1,CHARINDEX(']]',wkt)-1) as wkt
            FROM (SELECT SUBSTRING(wkt,CHARINDEX('", ',wkt)+3,100) as wkt
			        FROM (SELECT SUBSTRING(well_known_text,CHARINDEX('ELLIPSOID[',well_known_text)+10,500) as wkt
					        FROM sys.spatial_reference_systems
                           WHERE spatial_reference_id <> 104001
                             AND spatial_reference_id = @p_srid
						 ) as a
                ) as b
         ) as c;
  Return @a_f;
End;
GO

select spatial_reference_id, [$(cogoowner)].[STEllipsoidParameters](spatial_reference_id) as a_f 
  from sys.spatial_reference_systems
where spatial_reference_id in (4283,4326,4222);
GO

QUIT
