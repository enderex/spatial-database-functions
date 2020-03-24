SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id (N'[$(owner)].[STPointAdd]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(owner)].[STPointAdd];
  PRINT 'Dropped [$(owner)].[STPointAdd] ...';
END;
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id (N'[$(owner)].[STPointNormal]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(owner)].[STPointNormal];
  PRINT 'Dropped [$(owner)].[STPointNormal] ...';
END;
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id (N'[$(owner)].[STPointSubtract]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(owner)].[STPointSubtract];
  PRINT 'Dropped [$(owner)].[STPointSubtract] ...';
END;
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id (N'[$(owner)].[STPointScale]') AND xtype IN (N'FN', N'IF', N'TF') )
BEGIN
  DROP FUNCTION [$(owner)].[STPointScale];
  PRINT 'Dropped [$(owner)].[STPointScale] ...';
END;
GO

PRINT '################################';
PRINT 'Creating [$(owner)].[STPointAdd] ...';
GO

Create Function [$(owner)].[STPointAdd]( 
  @SELF    geometry,
  @p_point geometry 
)
Returns geometry
As
Begin
  Return geometry::Point(
           @SELF.STX + @p_point.STX,
           @SELF.STY + @p_point.STY,
           @SELF.STSrid
         );
End;
GO

PRINT '################################';
PRINT 'Creating [$(owner)].[STPointNormal] ...';
GO

Create Function [$(owner)].[STPointNormal]( 
   @SELF    geometry,
     @p_point geometry 
)
Returns geometry
As
Begin
  Declare
    @v_length float;

  SET @v_length = SQRT(@SELF.STX*@SELF.STX + @SELF.STY*@SELF.STY);
  Return geometry::Point(
           @SELF.STX / @v_length,
           @SELF.STY / @v_length,
           @SELF.STSrid
         );
End;
GO

PRINT '################################';
PRINT 'Creating [$(owner)].[STPointSubtract] ...';
GO

Create Function [$(owner)].[STPointSubtract] (
  @SELF    geometry,
  @p_point geometry 
)
Returns geometry
As
Begin
  Return geometry::Point( 
           @SELF.STX - @p_point.STX,
           @SELF.STY - @p_point.STY,
           @SELF.STSrid
         );
End;
GO

PRINT '################################';
PRINT 'Creating [$(owner)].[STPointScale] ...';
GO

Create Function [$(owner)].[STPointScale] (
  @SELF    geometry,
  @p_scale float = 1.0
)
Returns geometry
As
Begin
  Return geometry::Point( 
           @SELF.STX * ISNULL(@p_scale,1.0),
           @SELF.STY * ISNULL(@p_scale,1.0),
           @SELF.STSrid
         );
End;
GO

