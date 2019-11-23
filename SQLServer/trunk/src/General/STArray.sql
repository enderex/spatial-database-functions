USE [$(usedbname)]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[_STArray]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[_STArray];
  PRINT 'Dropped [$(owner)].[_STArray]';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STNumArray]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STNumArray];
  PRINT 'Dropped [$(owner)].[STNumArray]';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STGeogArrayN]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STGeogArrayN];
  PRINT 'Dropped [$(owner)].[STGeogArrayN]';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STGeomArrayN]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STGeomArrayN];
  PRINT 'Dropped [$(owner)].[STGeomArrayN]';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STGeogArray]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STGeogArray];
  PRINT 'Dropped [$(owner)].[STGeogArray]';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STGeomArray]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STGeomArray];
  PRINT 'Dropped [$(owner)].[STGeomArray]';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[iArray]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[iArray];
  PRINT 'Dropped [$(owner)].[iArray]';
END;
GO

PRINT '******************************************************************';
Print 'Creating [$(owner)].[_STArray] ...';
GO

CREATE FUNCTION [$(owner)].[_STArray]
( 
  @p_array  xml,
  @p_i      int            = 1,
  @p_action varchar(10)    = 'select',
  @p_wkb    varbinary(max) = null, -- Ensures can save geometry and geography
  @p_srid   int            = 0
)
Returns xml
/****f* TOOLS/_STArray (2008)
 *  NAME
 *    _STArray -- Base function for implementing arrays of geometry and geography.
 *  SYNOPSIS
 *    Function _STArray 
 *    (
 *       @p_array  xml,
 *       @p_i      int            = 1,
 *       @p_action varchar(10)    = 'select',
 *       @p_wkb    varbinary(max) = null, -- Ensures can save geometry and geography
 *       @p_srid   int            = 0
 *    )
 *    Returns xml 
 *  USAGE
 *    SELECT [$(owner)].[_STArray] (........) as result;
 *    Result
 *    <Depends on @p_action>
 *  DESCRIPTION
 *    This function implements all the basic operations of an array of geometry/geography objects.
 *    XML is used for the implementation.
 *    The function is "hidden" due to the various methods returning different results eg count -> integer; array[i] -> srid,wkb.
 *    The @p_action methods are:
 *      insert : inserts geometry/geography into provided position @p_i in array.If @p_i exists, the position is updated.
 *      update : updates geometry/geography at @p_i position in array.
 *      delete : deleted geometry/geography at @p_i position in array.
 *      select : returns geometry/geography WKB and SRID at @p_i position in array.
 *  INPUTS
 *    @p_array  (xml)           : Array itself
 *    @p_i      (int)           : 1,
 *    @p_action (varchar 10)    : select, update, delete, insert
 *    @p_wkb    (varbinary max) : geometry/geography as WKB so can hold both object types.
 *    @p_srid   (int)           : SRID of @p_wkb. It is possible for the array to hold heterogeneous SRIDed geom/geog objects.
 *  RESULT
 *    Depends on @p_action. 
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - May 2018 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
As
Begin
  Declare
    @v_GeomArray  xml,
    @v_GeomXML    xml,
    @v_wkb        varbinary(max),
    @v_wkbBase64  nvarchar(max),
    @v_action     varchar(10),
    @v_i          int,
    @v_numGeoms   int,
    @v_srid       int;
  Begin
    SET @v_i      = ISNULL(@p_i,1);
    SET @v_i      = CASE WHEN @v_i = 0 THEN 1 ELSE @v_i END;
    SET @v_action = ISNULL(LOWER(@p_action),'select');
    If ( @v_action not in ('insert','update','delete','select') )
    Begin
      Return @p_array;
    End;
    SET @v_GeomArray = @p_array;
    SET @v_srid      = ISNULL(@p_i,0);

    -- How many geometries in array?
    SET @v_numGeoms = @v_GeomArray.value('count(/ArrayOf/Geometries/*)', 'int');
    If ( @v_i = -1 )
    Begin
      SET @v_i = @v_numGeoms;
    End;

    -- Insert into empty array (special case) ...
    If (@p_array is null)
    Begin
      If (@p_wkb is null or @v_action <> 'insert' )
      Begin
        Return @p_array;
      End;
      SET @v_wkb        = @p_wkb;
      SET @v_wkbBase64  = CAST(N'' AS xml).value('xs:base64Binary(xs:hexBinary(sql:variable("@v_wkb")))', 'varchar(max)');
      SET @v_GeomArray = '<ArrayOf><Geometries><Geometry srid="' + CAST(@v_srid as varchar(10)) + 
                                                        '" wkb="' + @v_wkbBase64 + '"/></Geometries></ArrayOf>';
      Return @v_GeomArray;
    End;

    If ( @v_action = 'select' )
    Begin
      If ( @v_numGeoms = 0 )
       Begin
         Return NULL;
      End;
       IF ( @v_i > @v_numGeoms )
      Begin
        SET @v_i = @v_numGeoms;
      End;
      SET @v_srid      = @v_GeomArray.value('(/ArrayOf/Geometries/Geometry[sql:variable("@v_i")]/@srid)[1]','int');
      SET @v_wkbBase64 = @v_GeomArray.value('(/ArrayOf/Geometries/Geometry[sql:variable("@v_i")]/@wkb)[1]','nvarchar(max)');
      SET @v_GeomXML   = N'<Geometry srid="' + CAST(@v_srid as varchar(10)) + '">' + @v_wkbBase64 + '</Geometry>';
      Return @v_geomXML;
    END;

    If ( @v_action = 'insert' )
    Begin 
      -- Turn varbinary into Base64 String.
      SET @v_wkbBase64 = CAST(N'' AS xml).value('xs:base64Binary(xs:hexBinary(sql:variable("@p_wkb")))', 'varchar(max)');
      If ( @v_i = 1 )
      Begin
        SET @v_GeomXML = '<Geometry srid="' + CAST(@v_srid as varchar(10)) + '" wkb="' + @v_wkbBase64 + '"/>';
        SET @v_GeomArray.modify('insert sql:variable("@v_GeomXML") as first into (/ArrayOf/Geometries)[1]');
      End
      Else 
      Begin
        If ( @v_i > @v_numGeoms )
        Begin
          SET @v_i       = @v_numGeoms + 1;
          SET @v_GeomXML = '<Geometry srid="' + CAST(@v_srid as varchar(10)) + '" wkb="' + @v_wkbBase64 + '"/>';
          SET @v_GeomArray.modify('insert sql:variable("@v_GeomXML") as last into (/ArrayOf/Geometries)[1]') ;  
        End
        Else
        Begin
          SET @v_GeomXML = '<Geometry srid="' + CAST(@v_srid as varchar(10)) + '" wkb="' + @v_wkbBase64 + '"/>';
          SET @v_GeomArray.modify('insert sql:variable("@v_GeomXML") into (/ArrayOf/Geometries/Geometry[sql:variable("@v_i")])[1]') ;  
        End;
      End;
      Return @v_GeomArray;
    End;
  
    IF ( @v_action = 'update' )
    Begin
      If ( @v_i > @v_numGeoms )
      Begin
         SET @v_i = @v_numGeoms + 1;
      End;
      -- varbinary to base64
      SET @v_wkbBase64 = CAST(N'' AS xml).value('xs:base64Binary(xs:hexBinary(sql:variable("@p_wkb")))', 'varchar(max)');
      SET @v_GeomArray.modify('replace value of (/ArrayOf/Geometries/Geometry[sql:variable("@v_i")]/@wkb)[1] with sql:variable("@v_wkbBase64")');
      SET @v_GeomArray.modify('replace value of (/ArrayOf/Geometries/Geometry[sql:variable("@v_i")]/@srid)[1] with sql:variable("@v_srid")');
      Return @v_GeomArray;
    End;

    If ( @v_action = 'delete' )
    Begin
      If ( @v_i >= @v_numGeoms )
      Begin
        SET @v_GeomArray.modify('delete /ArrayOf/Geometries/Geometry[last()]');
      End
      Else
      Begin
        SET @v_GeomArray.modify('delete /ArrayOf/Geometries/Geometry[sql:variable("@v_i")]');
      End;
      Return @v_GeomArray;
    End;
    Return @v_GeomArray;
  End;
End;
Go

PRINT '******************************************************************';
Print 'Creating [$(owner)].[STNumArray] ...';
GO

CREATE FUNCTION [$(owner)].[STNumArray]
( 
  @p_array xml
)
Returns int
/****f* TOOLS/STNumArray (2008)
 *  NAME
 *    STNumArray -- Return number of elements in the array (size).
 *  SYNOPSIS
 *    Function STNumArray 
 *    (
 *       @p_array xml
 *    )
 *    Returns int 
 *  USAGE
 *    SELECT [$(owner)].[STNumArray](@p_array) as count;
 *    Count
 *    45
 *  DESCRIPTION
 *    This function returns the number of element in the supplied array (count)
 *    Returns 0 is @p_array is NULL
 *  INPUTS
 *    @p_array  (xml) : Array itself
 *  RESULT
 *    Size/Count (int)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - May 2018 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
As
Begin
  -- Handle Empty Array  ...
  If (@p_array is null)
  Begin
    Return 0;
  End;
  Return @p_array.value('count(/ArrayOf/Geometries/*)', 'int');
End;
Go

PRINT '******************************************************************';
Print 'Creating [$(owner)].[STGeogArray] ...';
GO

CREATE FUNCTION [$(owner)].[STGeogArray]
( 
  @p_array  xml,
  @p_i      int         = 1,
  @p_action varchar(10) = 'insert',
  @p_geog   geography 
)
Returns xml
As
Begin
  Declare
    @v_array xml;

  -- Select is supported in a separate function STGeogArrayN  
  If ( ISNULL(@p_action,'insert') = 'select' )
    Return @p_array;

  -- Call base function
  SET @v_array = [$(owner)].[_STArray] (
                   /* @p_array */ @p_array,
                   /* @p_i     */ @p_i,
                   /* @p_action*/ @p_action,
                   /* @p_wkb   */ @p_geog.AsBinaryZM(),
                   /* @p_srid  */ @p_geog.STSrid
                 );

  Return @v_array;
End;
Go

PRINT '******************************************************************';
Print 'Creating [$(owner)].[STGeogArrayN] ...';
GO

CREATE FUNCTION [$(owner)].[STGeogArrayN]
( 
  @p_array xml,
  @p_i     int = 1
)
Returns geography
As
Begin
  Declare 
    @v_geog      geography,
     @v_selectXML xml,
    @v_vcWKB     varchar(max),
     @v_srid      int;

  -- Call base function
  SET @v_selectXML = [$(owner)].[_STArray] (
                       /* @p_array */ @p_array,
                       /* @p_i     */ @p_i,
                       /* @p_action*/ 'select',
                       /* @p_wkb   */ NULL,
                       /* @p_srid  */ NULL
                     );
  If ( @v_selectXML is null )
    Return NULL;

  -- Extract Geography and Srid from return XML
  Set @v_srid  = @v_selectXML.value('(/Geometry/@srid)[1]','int');
  Set @v_vcWKB = @v_selectXML.value('(/Geometry)[1]','varchar(max)');
  Set @v_geog  = geography::STGeomFromWKB(CAST(@v_vcWKB AS xml).value('xs:base64Binary(sql:variable("@v_vcWKB"))','varbinary(max)'),
                                           @v_srid);
  Return @v_geog;
End;
go

PRINT '******************************************************************';
Print 'Creating [$(owner)].[STGeomArray] ...';
GO

CREATE FUNCTION [$(owner)].[STGeomArray]
( 
  @p_array  xml,
  @p_i      int         = 1,
  @p_action varchar(10) = 'insert',
  @p_geom   geometry
)
Returns xml
As
Begin
  Declare
    @v_array xml;

  -- Select is supported in a separate function STGeogArrayN  
  If ( ISNULL(@p_action,'insert') = 'select' )
    Return @p_array;

  -- Call base function
  SET @v_array = [$(owner)].[_STArray] (
                   /* @p_array */ @p_array,
                   /* @p_i     */ @p_i,
                   /* @p_action*/ @p_action,
                   /* @p_wkb   */ @p_geom.AsBinaryZM(),
                   /* @p_srid  */ @p_geom.STSrid
                 );

  Return @v_array;
End;
Go

PRINT '******************************************************************';
Print 'Creating [$(owner)].[STGeogArrayN] ...';
GO

CREATE FUNCTION [$(owner)].[STGeomArrayN]
( 
  @p_array xml,
  @p_i     int = 1
)
Returns geometry
As
Begin
  Declare 
    @v_geom      geometry,
     @v_selectXML xml,
    @v_vcWKB     varchar(max),
     @v_srid      int;

  -- Call base function
  SET @v_selectXML = [$(owner)].[_STArray] (
                       /* @p_array */ @p_array,
                       /* @p_i     */ @p_i,
                       /* @p_action*/ 'select',
                       /* @p_wkb   */ NULL,
                       /* @p_srid  */ NULL
                     );
  If ( @v_selectXML is null )
    Return NULL;

  -- Extract Geometry and Srid from return XML
  Set @v_srid  = @v_selectXML.value('(/Geometry/@srid)[1]','int');
  Set @v_vcWKB = @v_selectXML.value('(/Geometry)[1]','varchar(max)');
  Set @v_geom  = geometry::STGeomFromWKB(CAST(@v_vcWKB AS xml).value('xs:base64Binary(sql:variable("@v_vcWKB"))','varbinary(max)'),
                                          @v_srid);
  Return @v_geom;
End;
go

PRINT '******************************************************************';
PRINT 'Creating [$(owner)].[iArray] ...';
GO

CREATE FUNCTION [$(owner)].[iArray] (
  @p_iArray xml, 
  @p_action varchar(20) = 'select',
  @p_i      int = 0,
  @p_value  int = NULL
)
returns @array Table ( 
  array xml,
  value int
)
as
Begin
  Declare 
    @v_iArray    XML,
    @v_valueXML  XML,
    @v_numValues int,
    @v_i         int,
    @v_sValue    varchar(20),
    @v_value     int,
    @v_action    varchar(20);

  SET @v_i      = ISNULL(@p_i,1);
  SET @v_i      = CASE WHEN @v_i = 0 THEN 1 ELSE @v_i END;
  SET @v_action = ISNULL(LOWER(@p_action),'select');
  IF ( @v_action not in ('insert','update','delete','select','count','size') )
  BEGIN
    INSERT INTO @array (array,value) VALUES (@p_iArray,@p_value);
    RETURN;
  END;

  -- Insert into empty array (special case) ...
  If (@p_iArray is null)
  Begin
    If (@p_value is null or @v_action <> 'insert' )
    Begin
      INSERT INTO @array (array,value) VALUES (@p_iArray,@p_value);
      RETURN;
    End;
    INSERT INTO @array (array,value) VALUES ('<i>' + CONVERT(varchar,@p_value) + '</i>',@p_value);
    RETURN;
  End;

  -- How many geometries in array?
  SET @v_numValues = @p_iArray.value('count(/*)', 'int');
  IF ( @v_action in ('count','size') ) 
  Begin
    INSERT INTO @array (array,value) VALUES (@v_iArray,@v_numValues);
    RETURN;
  End;

  If ( @v_i = -1 )
  Begin
    SET @v_i = @v_numValues;
  End;

  SET @v_iArray  = CAST(@p_iArray as XML);
  IF ( @v_action = 'select' )
  Begin
    If ( @v_numValues = 0 )
    Begin
      Return;
    End;
    SET @v_value = @v_iArray.value('(/i[sql:variable("@v_i")]/text())[1]','int');
    INSERT INTO @array (array,value) VALUES (@v_iArray,@v_value);
    RETURN;
  END;

  IF ( @v_action = 'insert' )
  Begin 
    IF ( @p_value is null ) 
    BEGIN
      RETURN;
    END;
    SET @v_valueXML = CAST('<i>' + CONVERT(varchar,@p_value) + '</i>' AS XML);
    IF ( @v_i = 1 )
    Begin
      SET @v_iArray.modify('insert sql:variable("@v_valueXML") as first into (/)[1]');
    End
    Else 
    Begin
      If ( @v_i >= @v_numValues )
      Begin
        SET @v_i = @v_numValues + 1;
        SET @v_iArray.modify('insert sql:variable("@v_valueXML") as last into (/)[1]') ;  
      End
      Else
      Begin
        SET @v_iArray.modify('insert sql:variable("@v_valueXML") into (/i[sql:variable("@v_i")])[1]') ;  
      End;
    End;
    INSERT INTO @array (array,value) VALUES (@v_iArray,@p_value);
    RETURN;
  End;
  
  IF ( @v_action = 'update' )
  Begin
    SET @v_value = CONVERT(varchar,@p_value);
    SET @v_iArray.modify('replace value of (/i[sql:variable("@v_i")]/text())[1] with sql:variable("@v_value")');
    INSERT INTO @array (array,value) VALUES (@v_iArray,@v_value);
    RETURN;
  End;

  If ( @v_action = 'delete' )
  Begin
    If ( @v_i >= @v_numValues )
    Begin
      SET @v_iArray.modify('delete /i[last()]');
    End
    Else
    Begin
      SET @v_iArray.modify('delete /i[sql:variable("@v_i")]');
    End;
    INSERT INTO @array (array,value) VALUES (@v_iArray,@v_i);
    RETURN;
  End;
  Return;
End;

PRINT '******************************************************************';
PRINT 'Test STNumArray and STArray ...';
GO

Declare @array xml
select 'Empty Array' as test, $(owner).STNumArray(@array);

Set @array = $(owner).STArray(@array,1,'insert',geometry::Point(1,2,0).STAsBinary(),0);
select 'Insert into Empty ' as test, @array;

Set @array = $(owner).STArray(@array,2,'insert',geometry::Point(2,2,0).STAsBinary(),0);
select 'Insert at position 2 (end)' as test, @array;

Set @array = $(owner).STArray(@array,0,'insert',geometry::Point(3,3,0).STAsBinary(),0);
select 'Insert at beginning ' as test, @array;

Set @array = $(owner).STArray(@array,0,'update',geometry::Point(4,4,0).STAsBinary(),0);
select 'Update first geometry' as test, @array;

Set @array = $(owner).STArray(@array,0,'delete',NULL,0);
select 'Delete first geometry' as test, @array;

Set @array = $(owner).STArray(@array,-1,'delete',NULL,0);
select 'Delete last geometry ' as test, @array;

Declare @v_geomXML xml;
Declare @v_vcWKB   varchar(max);
Declare @v_WKB     varbinary(max);
Declare @v_geom    geometry;
Declare @v_srid    int;
Set @v_geomXML = $(owner).STArray(@array,1,'select',NULL,0);
Set @v_vcWKB   = @v_geomXML.value('(/Geometry)[1]','varchar(max)');
Set @v_srid    = @v_geomXML.value('(/Geometry/@srid)[1]','int');
Set @v_geom    = geometry::STGeomFromWKB(CAST(@v_vcWKB AS xml).value('xs:base64Binary(sql:variable("@v_vcWKB"))', 'varbinary(max)'),0);
select 'Select First Geometry ' as test, @v_geomXML, @v_vcWKB, @v_geom.AsTextZM(), @v_geom.STSrid;

select 'Size' as test, $(owner).STNumArray(@array);
GO


