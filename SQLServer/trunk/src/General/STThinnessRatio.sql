SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '****************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STThinnessRatio]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STThinnessRatio];
  PRINT 'Dropped [$(owner)].[STThinnessRatio] ...';
END;
GO

/* *************************** FUNCTIONS ************************************* */

Print 'Creating [$(owner)].[STThinnessRatio] ...';
GO

create function [$(Owner)].[STThinnessRatio] (
 @p_polygon geometry
)
Returns float
As
Begin
  Declare
    @v_perimeter float;
  SET @v_perimeter = @p_polygon.STLength();
  RETURN 4.0 * pi() * @p_polygon.STArea() / (@v_perimeter * @v_perimeter );
End;
GO

select [$(Owner)].[STThinnessRatio] (geometry::STGeomFromText('Polygon ((-163875.02999999999883585 -1486692.40999999991618097, -164269.83999999999650754 -1485141.97999999998137355, -164171.01999999998952262 -1485530.06000000005587935, -163875.02999999999883585 -1486692.40999999991618097))',0));

select [$(Owner)].[STThinnessRatio] (geometry::STGeomFromText('POLYGON((
  -165838.38269999996 -1485528.0527999997, 
  -165428.42090000026 -1487072.4876000006, 
  -163875.03449999914 -1486692.4075000007, 
  -164269.84210000001 -1485141.9840999991, 
  -165838.38269999996 -1485528.0527999997))',0));
