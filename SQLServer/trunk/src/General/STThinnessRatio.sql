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


