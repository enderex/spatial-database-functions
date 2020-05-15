DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

/****t* OBJECT TYPE/T_GEOMETRY_ROW
*  NAME
*    T_GEOMETRY_ROW - Object Type used when returning sdo_geometry objects in a pipelined function.
*  DESCRIPTION
*    An object type that allows for a SDO_GEOMETRY geometry object to be represented as a single object.
*    Mainly for use in PIPELINED Functions.
*    If one PIPES a single sdo_geometry object, it appears at the end of the pipeline as the individual 5 attributes of an sdo_geometry object and not a single sdo_geometry attribute object.
*  NOTES
*    No methods are declared on this type.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2005 - Original coding.
*    Simon Greener - Jan 2013 - Port from GEOM Package for &&INSTALL_SCHEMA..
*  COPYRIGHT
*    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_GEOMETRY_ROW
AUTHID DEFINER
AS Object (

  /****v* T_GEOMETRY_ROW/ATTRIBUTES(T_GEOMETRY_ROW)
  *  ATTRIBUTES
  *    gid        number,             -- geometry id (cf rownum).
  *    geometry   mdsys.sdo_geometry, -- geometry object.
  *    tolerance  number,             -- Tolerance value associated with geometry object (normally T_GEOMETRY.tolerance object)
  *    dPrecision integer,            -- Decimal digits of precision value associated with geometry object (normally T_GEOMETRY.dPrecision object)
  *    projected  integer,            -- Projected value associated with geometry object (normally T_GEOMETRY.projected object)
  *  SOURCE
  */
   gid        number,
   geometry   mdsys.sdo_geometry,
   Tolerance  number,
   dPrecision integer,
   projected  integer
  /*******/
);
/
SHOW ERRORS

grant execute on &&INSTALL_SCHEMA..T_GEOMETRY_ROW to public with grant option;

/****s* OBJECT TYPE ARRAY/T_GEOMETRIES
*  NAME
*    T_GEOMETRIES -- Array (collection) of T_GEOMETRY_ROW Objects.
*  DESCRIPTION
*    An array if T_GEOMETRY_ROW objects used in PIPELINED Functions.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2005 - Original coding.
*    Simon Greener - Jan 2013 - Port from GEOM Package for &&INSTALL_SCHEMA..
*  COPYRIGHT
*    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
*  SOURCE
*/
CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_GEOMETRIES
           AS TABLE OF &&INSTALL_SCHEMA..T_GEOMETRY_ROW;
/*******/
/
SHOW ERRORS

grant execute on &&INSTALL_SCHEMA..T_GEOMETRIES to public with grant option;

-- ==========================================================
-- =====================   T_GEOMETRY   =====================
-- ==========================================================

CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_GEOMETRY
AUTHID DEFINER
AS OBJECT (

/****t* OBJECT TYPE/T_GEOMETRY
*  NAME
*    T_GEOMETRY Object Type
*  DESCRIPTION
*    An object type that represents a single SDO_GEOMETRY geometry object.
*    Includes Methods on that type.
*  WARNINGS
*    This type should only be used for programming and should not be stored in the database.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2005 - Original coding.
*    Simon Greener - Jan 2013 - Port from GEOM Package for &&INSTALL_SCHEMA..
*  COPYRIGHT
*    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/

  /****v* T_GEOMETRY/ATTRIBUTES(T_GEOMETRY)
  *  ATTRIBUTES
  *    geom       -- mdsys.sdo_geometry Object
  *    tolerance  -- Standard SDO_TOLERANCE value.
  *                  Since we need the geometry's tolerance for some operations eg sdo_area etc
  *                  let's add it to the type rather than have to supply it all the time to member functions
  *    dPrecision -- Number of Significant Decimal Digits of precision. (PRECISION is an Oracle name)
  *                  Some operations require the comparison of two ordinates. For geodetic data this is
  *                  not the same as an Oracle tolerance. We allow a user to supply this value for all data
  *                  but if set to null it will assume a value based on the tolerance.
  *    projected  -- Whether mdsys.sdo_geometry ordinates are Geodetic (0), Projected (1), or NULL (not defined).
  *                  When creating and using bearing and distances one needs to know if the geometry
  *                  is projected or not. While one could do this by dynamic query to the database
  *                  each time it is needed, an additional property helps us to record this once.
  *  SOURCE
  */
  geom       mdsys.sdo_geometry,
  tolerance  number,
  dPrecision integer,
  projected  integer,
  /*******/

  /****m* T_GEOMETRY/CONSTRUCTORS(STANDARD)
  *  NAME
  *    A collection of "standard" T_GEOMETRY Constructors.
  *  SOURCE
  */

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY)
                Return Self As Result,

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_geom      IN mdsys.sdo_geometry)
                Return Self As Result,

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_geom      in mdsys.sdo_geometry,
                                  p_tolerance in number)
                Return Self As Result,

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_geom      in mdsys.sdo_geometry,
                                  p_tolerance in number,
                                  p_dPrecision in integer)
                Return Self As Result,

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_geom      in mdsys.sdo_geometry,
                                  p_tolerance in number,
                                  p_dPrecision in integer,
                                  p_projected in varchar2)
                Return Self As Result,

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_vertex    in mdsys.vertex_type,
                                  p_srid      in integer,
                                  p_tolerance in number default 0.005)
                Return Self As Result,

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_segment   in &&INSTALL_SCHEMA..T_SEGMENT)
                Return Self As Result,
  /*******/

  /****m* T_GEOMETRY/CONSTRUCTOR(MDSYS.SDO_GEOMETRY_ARRAY)
  *  NAME
  *    T_GEOMETRY(sdo_geometry_array) -- Constructor that creates a GeometryCollection from an array of sdo_geometry objects.
  *  SYNOPSIS
  *    Constructor Function T_GEOMETRY(p_geoms IN mdsys.sdo_geometry_array)
  *                Return Self As Result,
  *  DESCRIPTION
  *    The p_geoms geometry array parameter should contain at least one element.
  *    The sdo_geometry objects within the array should have the same dimension, if not the lowest is chosen (cf ST_To2D etc).
  *    All p_geoms objects should be in the same SRID.
  *  ARGUMENTS
  *    p_geoms (mdsys.sdo_geometry_array) -- Any non-null, geometry array
  *  EXAMPLE
  *    With data as (
  *                select sdo_geometry('POINT(1 2)',null) as tgeom From Dual 
  *      UNION ALL select sdo_geometry(2001,NULL,SDO_POINT_TYPE(3,4,null),null,null) as tgeom From Dual 
  *      UNION ALL select sdo_geometry('LINESTRING(5 1,10 1,10 5,10 10,5 10,5 5)',null) as tgeom From Dual 
  *      UNION ALL select sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,10,0,10,5,10,10,5,10,5,5)) as tgeom From Dual 
  *      UNION ALL select sdo_geometry('MULTILINESTRING((-1 -1, 0 -1),(0 0,10 0,10 5,10 10,5 10,5 5))',null) as tgeom From Dual 
  *      UNION ALL select sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null) as tgeom From Dual 
  *      UNION ALL select sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null) as tgeom From Dual
  *   )
  *   select t_geometry(
  *            cast(collect(a.tgeom) as mdsys.sdo_geometry_array)
  *          ).geom as gArray 
  *     from data a;
  *
  *    GARRAYGEOM
  *    -----------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2004,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,1,1, 3,1,1, 5,2,1, 17,2,1, 29,2,1, 33,2,1, 45,1003,1, 55,2003,1, 65,1003,1, 75,2003,1, 85,2003,1, 95,1003,1),
  *                 SDO_ORDINATE_ARRAY(1,2, 3,4, 5,1, 10,1, 10,5, 10,10, 5,10, 5,5, 0,0, 10,0, 10,5, 10,10, 5,10, 5,5, -1,-1, 0,-1, 
  *                                    0,0, 10,0, 10,5, 10,10, 5,10, 5,5, 
  *                                    0,0, 20,0, 20,20, 0,20, 0,0, 
  *                                    10,10, 10,11, 11,11, 11,10, 10,10, 
  *                                    0,0, 20,0, 20,20, 0,20, 0,0, 
  *                                    10,10, 10,11, 11,11, 11,10, 10,10, 
  *                                    5,5, 5,7, 7,7, 7,5, 5,5, 
  *                                    100,100, 200,100, 200,200, 100,200, 100,100))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_geoms     IN mdsys.sdo_geometry_array)
                Return Self As Result,

  /****m* T_GEOMETRY/CONSTRUCTOR(EWKT)
  *  NAME
  *    T_GEOMETRY(EWKT CLOB)-- Constructor that creates an sdo_geometry object from the passed in EWKT.
  *  SYNOPSIS
  *    Constructor Function T_GEOMETRY(p_ewkt IN CLOB)
  *                Return Self As Result,
  *  DESCRIPTION
  *    The p_ewkt parameter can be a 2D or greater WKT object.
  *  ARGUMENTS
  *    p_ewkt (CLOB) -- Any non-null WKT or EWKT object
  *  EXAMPLE
  *    See ST_FromEWKT().
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_ewkt      IN CLOB)
                Return Self As Result,

  -- ********** Static Functions ************************

  /****f* T_GEOMETRY/ST_Release
  *  NAME
  *    ST_Release -- Returns Version Number for the code in the type.
  *  SYNOPSIS
  *    Static Function ST_Release
  *             Return VarChar2
  *  DESCRIPTION
  *    This function returns a version or release number for the code when distributed.
  *    Also includes versions of the databases the code was developed against .
  *  EXAMPLE
  *    select T_GEOMETRY.ST_Release()
  *      from dual;
  *
  *    T_GEOMETRY.ST_Release()
  *    -----------------------
  *    2.1.1 Databases(11.2, 12.1)
  *  RESULT
  *    Code Release Number (VarChar2) - eg 2.2.1 Databases(11.2, 12.1)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Static Function ST_Release
           Return Varchar2 Deterministic,

  -- ********** Member Functions ************************

  /****m* T_GEOMETRY/ST_AsGeometryRow
  *  NAME
  *    ST_AsGeometryRow -- Simply returned T_GEOMETRY as an T_GEOMETRYROW object.
  *  SYNOPSIS
  *    Member Function ST_AsGeometryRow (p_gid in integer default ),
  *             Return &&INSTALL_SCHEMA..T_GEOMETRYROW Deterministic,
  *  DESCRIPTION
  *    T_GEOMETRIES is defined as a table of T_GEOMETRYROW.
  *    Functions like ST_Dump break up an sdo_geometry and returns them as T_GEOMETRYROW objects within a T_GEOMETRIES object.
  *  EXAMPLE
  *    select &&INSTALL_SCHEMA..T_Geometry(SDO_GEOMETRY(2005, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 1, 1), SDO_ORDINATE_ARRAY(10.719, 8.644)),0.005,3,1)
  *                           .ST_AsGeometryRow() as geom 
  *      from dual;
  *    
  *    GEOM
  *    -------------------------------------------------------------------------------------------------------------------------------
  *    T_GEOMETRY_ROW(1, SDO_GEOMETRY(2005, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 1, 1), SDO_ORDINATE_ARRAY(10.719, 8.644)), 0.005, 3, 1)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jul 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsGeometryRow(p_gid in integer default 1)
           Return &&INSTALL_SCHEMA..T_Geometry_Row Deterministic,

  /****m* T_GEOMETRY/ST_SetSdoGtype
  *  NAME
  *    ST_SetSdoGtype -- Sets SDO_GTYPE for underlying geometry object.
  *  SYNOPSIS
  *    Member Function ST_SetSdoGtype (p_sdo_gtype in integer),
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    If the SDO_GTYPE property is not set by a constructor on instantiation,
  *    this Function can be used to set that property at any time.
  *  ARGUMENTS
  *    p_sdo_gtype (integer) : A valid sdo_gtype number.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jul 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SetSdoGtype (p_sdo_gtype in integer)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_SetSRID
  *  NAME
  *    ST_SetSRID -- Sets SDO_SRID for underlying geometry object.
  *  SYNOPSIS
  *    Member Function ST_SetSRID (SELF in out &&INSTALL_SCHEMA..T_GEOMETRY),
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    If the SDO_SRID property is not set by a constructor on instantiation,
  *    this Function can be used to set that property at any time.
  *  ARGUMENTS
  *    p_srid (integer) - Any valid sdo_srid number;
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jul 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SetSRID(p_srid in integer)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_SetProjection
  *  NAME
  *    ST_SetProjection -- Sets projected property of object after query of MDSYS CS metadata.
  *  SYNOPSIS
  *    Member Procedure ST_SetProjection  (SELF in out &&INSTALL_SCHEMA..T_GEOMETRY),
  *  DESCRIPTION
  *    The projected object property is used by the methods of the T_GEOMETRY object
  *    when executing SDO functions that require knowledge of whether the mdsys.sdo_geometry is
  *    coordinate system is projected or geodetic. If the property is not set by a constructor,
  *    on instantiation, this function can be used to set that property at any time.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Procedure ST_SetProjection  (SELF IN OUT NOCOPY T_GEOMETRY),

  /****m* T_GEOMETRY/ST_SetPrecision
  *  NAME
  *    ST_SetPrecision -- Sets dPrecision property value of object after construction.
  *  SYNOPSIS
  *    Member Function ST_SetPrecision (p_dPrecision in integer default 3),
  *  DESCRIPTION
  *    The dPrecision object property is normally set when the object is constructed.
  *    This member function allows the user to change the value dynamically.
  *  ARGUMENTS
  *    p_dPrecision : integer : Any valid integer value for the Oracle ROUND function.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jun 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SetPrecision(p_dPrecision in integer default 3)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_SetTolerance
  *  NAME
  *    ST_SetTolerance -- Sets tolerance value of object after construction.
  *  SYNOPSIS
  *    Member Function ST_SetTolerance (p_tolerance in integer default 0.005),
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    The tolerance object property is normally set when the object is constructed.
  *    This member function allows the user to change the value dynamically.
  *  ARGUMENTS
  *    p_tolerance : number : Any valid Oracle Spatial tolerance. Default is 5cm as per geodetic value.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jun 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SetTolerance (p_tolerance in number default 0.005)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_SetPoint
  *  NAME
  *    ST_SetPoint -- Sets, or replaces, SDO_POINT_TYPE element of underlying SDO_GEOMETRY.
  *  SYNOPSIS
  *    Member Function ST_SetPoint (p_point in mdsys.sdo_point_type),
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Replaces any, or no, SDO_POINT within underlying SDO_GEOMETRY object.
  *  ARGUMENTS
  *    p_point : mdsys.sdo_point_type : Any valid mdsys.sdo_point_type object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jun 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SetPoint (p_point in mdsys.sdo_point_type)
           Return &&INSTALL_SCHEMA..T_GEOMETRY   Deterministic,

  /****m* T_GEOMETRY/ST_GType
  *  NAME
  *    ST_GType -- Returns underlying mdsys.sdo_geometry's geometry type by executing mdsys.sdo_geometry method get_gtype().
  *  SYNOPSIS
  *    Member Function ST_GType
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Is a wrapper over the mdsys.sdo_geometry get_gtype() method ie SELF.GEOM.Get_Gtype()
  *  RESULT
  *    geometry type (Integer) -- 1:Point; 2:Linestring; 3:Polygon; 4:Collection; 5:MultiPoint; 6:MultiLinestring; 7:MultiPolygon
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_GType
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_Dims
  *  NAME
  *    ST_Dims -- Returns number of ordinate dimensions
  *  SYNOPSIS
  *    Member Function ST_Dims
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Is a wrapper over the mdsys.sdo_geometry get_dims() method ie SELF.GEOM.Get_Dims()
  *  RESULT
  *    dimension (Integer) -- 2 if data 2D; 3 if 3D; 4 if 4D
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Dims
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_SDO_GType
  *  NAME
  *    ST_SDO_GType -- Returns underlying mdsys.sdo_geometry's SDO_GTYPE attribute.
  *  SYNOPSIS
  *    Member Function ST_SDO_GType
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Is a wrapper over the mdsys.sdo_geometry SELF.GEOM.SDO_GTYPE attribute.
  *  RESULT
  *    geometry type (Integer) -- eg 2001 for 2D single point etc.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SDO_GType
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_SRID
  *  NAME
  *    ST_SRID -- Returns underlying mdsys.sdo_geometry's SDO_SRID attribute.
  *  SYNOPSIS
  *    Member Function ST_SRID
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Is a wrapper over the mdsys.sdo_geometry SELF.GEOM.SDO_SRID attribute.
  *  RESULT
  *    spatial reference id (Integer) -- eg 8311 etc.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Srid
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_AsWKB
  *  NAME
  *    ST_AsWKB -- Exports mdsys.sdo_geometry object to its Well Known Binary (WKB) representation by executing, and returning, result of mdsys.sdo_geometry method get_wkb().
  *  SYNOPSIS
  *    Member Function ST_AsWKB
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Is a wrapper over the mdsys.sdo_geometry method SELF.GEOM.GET_WKB(). Returns Well Known Binary representation of underlying mdsys.sdo_geometry.
  *  RESULT
  *    WKB (BLOB) -- eg Well Known Binary encoding of mdsys.sdo_geometry object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsWkb
           Return Blob Deterministic,

  /****m* T_GEOMETRY/ST_AsWKT
  *  NAME
  *    ST_AsWKT -- Exports mdsys.sdo_geometry object to its Well Known Text (WKT) representation by executing, and returning, result of mdsys.sdo_geometry method get_wkt().
  *  SYNOPSIS
  *    Member Function ST_AsWKT
  *             Return clob Deterministic,
  *  DESCRIPTION
  *    Is a wrapper over the mdsys.sdo_geometry method SELF.GEOM.GET_WKT().
  *    Returns Well Known Text representation of underlying mdsys.sdo_geometry.
  *    Only supports 2D geometries. See ST_AsEWKT for 3/4D.
  *  RESULT
  *    WKT (CLOB) -- eg Well Known Text encoding of mdsys.sdo_geometry object.
  *  EXAMPLE
  *    with data as (
  *      select 'CircularString (1)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,2),sdo_ordinate_array (10,15,15,20,20,15)) as geom from dual union all
  *      select 'CircularString (2)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,2),sdo_ordinate_array (10,35,15,40,20,35,25,30,30,35)) as geom from dual union all
  *      select 'CircularString (Closed)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,2),sdo_ordinate_array (15,65,10,68,15,70,20,68,15,65)) as geom from dual union all
  *      select 'CompoundCurve (1)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,4,3,1,2,1,3,2,2,7,2,1),sdo_ordinate_array (10,45,20,45,23,48,20,51,10,51)) as geom from dual union all
  *      select 'CompoundCurve (2)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,4,2,1,2,1,7,2,2),sdo_ordinate_array (10,78,10,75,20,75,20,78,15,80,10,78)) as geom from dual union all
  *      select 'CurvePolygon (Circle Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,4),sdo_ordinate_array (15,140,20,150,40,140)) as geom from dual union all
  *      select 'CurvePolygon (CircularArc Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,2),sdo_ordinate_array (15,115,20,118,15,120,10,118,15,115)) as geom from dual union all
  *      select 'CurvePolygon (Compound Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1005,2,1,2,1,7,2,2),sdo_ordinate_array (10,128,10,125,20,125,20,128,15,130,10,128)) as geom from dual union all
  *      select 'GeometryCollection (1)' as test,sdo_geometry (2004,null,null,sdo_elem_info_array (1,1,1,3,2,1,7,1003,1),sdo_ordinate_array (10,5,10,10,20,10,10,105,15,105,20,110,10,110,10,105)) as geom from dual union all
  *      select 'GeometryCollection (2)' as test,sdo_geometry(2004,NULL,NULL,sdo_elem_info_array(1,1003,3,5,1,1,9,2,1),sdo_ordinate_array(0,0,100,100,50,50,0,0,100,100.0)) as geom from dual union all
  *      select 'LineString (1)' as test,sdo_geometry(2002,NULL,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(100,100,900,900.0)) as geom from dual union all
  *      select 'LineString (2)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,1),sdo_ordinate_array (10,25,20,30,25,25,30,30)) as geom from dual union all
  *      select 'LineString (3)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,1),sdo_ordinate_array (10,10,20,10)) as geom from dual union all
  *      select 'LineString (Closed)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,1),sdo_ordinate_array (10,55,15,55,20,60,10,60,10,55)) as geom from dual union all
  *      select 'LineString (Self-Crossing)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,1),sdo_ordinate_array (10,85,20,90,20,85,10,90,10,85)) as geom from dual union all
  *      select 'MultiCurve (1)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,2,7,2,2),sdo_ordinate_array (50,35,55,40,60,35,65,35,70,30,75,35)) as geom from dual union all
  *      select 'MultiCurve (Touching)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,2,7,2,2),sdo_ordinate_array (50,65,50,70,55,68,55,68,60,65,60,70)) as geom from dual union all
  *      select 'MultiLine (Closed)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,1,9,2,1),sdo_ordinate_array (50,55,50,60,55,58,50,55,56,58,60,55,60,60,56,58)) as geom from dual union all
  *      select 'MultiLine (Crossing)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,1,5,2,1),sdo_ordinate_array (50,22,60,22,55,20,55,25)) as geom from dual union all
  *      select 'MultiLine (Stoked)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,1,5,2,1),sdo_ordinate_array (50,15,55,15,60,15,65,15)) as geom from dual union all
  *      select 'MultiPoint (2)' as test,sdo_geometry(2005,NULL,NULL,sdo_elem_info_array(1,1,2),sdo_ordinate_array(100,100,900,900.0)) as geom from dual union all
  *      select 'MultiPoint (3)' as test,sdo_geometry (2005,null,null,sdo_elem_info_array (1,1,1,3,1,1,5,1,1),sdo_ordinate_array (65,5,70,7,75,5)) as geom from dual union all
  *      select 'MultiPoint (4)' as test,sdo_geometry (2005,null,null,sdo_elem_info_array (1,1,3),sdo_ordinate_array (50,5,55,7,60,5)) as geom from dual union all
  *      select 'MultiPolygon (Disjoint)' as test,sdo_geometry (2007,null,null,sdo_elem_info_array (1,1003,1,11,1003,3),sdo_ordinate_array (50,105,55,105,60,110,50,110,50,105,62,108,65,112)) as geom from dual union all
  *      select 'MultiPolygon (Rectangles)' as test,sdo_geometry(2007,NULL,NULL,sdo_elem_info_array(1,1003,3,5,1003,3),sdo_ordinate_array(1500,100,1900,500,1900,500,2300,900.0)) as geom from dual union all
  *      select 'Point (Ordinate Encoding)' as test,sdo_geometry (2001,null,null,sdo_elem_info_array (1,1,1),sdo_ordinate_array (10,5)) as geom from dual union all
  *      select 'Point (SDO_POINT encoding)' as test,sdo_geometry(2001,NULL,sdo_point_type(900,900,NULL),NULL,NULL) as geom from dual union all
  *      select 'Polygon (No Holes)' as test,sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(100,100,500,500.0)) as geom from dual union all
  *      select 'Polygon (Stroked Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,1),sdo_ordinate_array (10,105,15,105,20,110,10,110,10,105)) as geom from dual union all
  *      select 'Polygon (With Point and a Hole)' as test,sdo_geometry(2003,NULL,MDSYS.SDO_POINT_TYPE(1000,1000,NULL),sdo_elem_info_array(1,1003,3,5,2003,3),sdo_ordinate_array(500,500,1500,1500,600,750,900,1050.0)) as geom from dual union all
  *      select 'Polygon (With Void)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,3,5,2003,3),sdo_ordinate_array (50,135,60,140,51,136,59,139)) as geom from dual union all
  *      select 'Rectangle (Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,3),sdo_ordinate_array (10,135,20,140)) as geom from dual union all
  *      select 'Rectangle (With Rectangular Hole)' as test,sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3,5,2003,3),sdo_ordinate_array(0,0,200,200,75,25,125,75.0)) as geom from dual
  *    )
  *    select a.test,
  *           T_GEOMETRY(a.geom,0.0005,3,1)
  *             .ST_Rectangle2Polygon()
  *             .ST_AsEWKT() as geom
  *      from data a
  *     order by 1;
  *
  *    TEST                                     GEOM
  *    ---------------------------------------- -----------------------------------------------------------------------------------------------------------------------------
  *    CircularString (1)                       CIRCULARSTRING (10 15, 15 20, 20 15.0)
  *    CircularString (2)                       CIRCULARSTRING (10 35, 15 40, 20 35, 25 30, 30 35.0)
  *    CircularString (Closed)                  CIRCULARSTRING (15 65, 10 68, 15 70, 20 68, 15 65.0)
  *    CompoundCurve (1)                        COMPOUNDCURVE ((10 45, 20 45.0), CIRCULARSTRING (20 45, 23 48, 20 51.0), (20 51, 10 51.0))
  *    CompoundCurve (2)                        COMPOUNDCURVE ((10 78, 10 75, 20 75, 20 78.0), CIRCULARSTRING (20 78, 15 80, 10 78.0))
  *    CurvePolygon (Circle Exterior Ring)      CURVEPOLYGON ((15 140, 27.5 127.5, 40 140, 27.5 152.5, 15 140.0))
  *    CurvePolygon (CircularArc Exterior Ring) CURVEPOLYGON (CIRCULARSTRING (15 115, 20 118, 15 120, 10 118, 15 115.0))
  *    CurvePolygon (Compound Exterior Ring)    CURVEPOLYGON (COMPOUNDCURVE ((10 128, 10 125, 20 125, 20 128.0), CIRCULARSTRING (20 128, 15 130, 10 128.0)))
  *    GeometryCollection (1)                   GEOMETRYCOLLECTION (POINT (10 5.0), LINESTRING (10 10, 20 10.0), POLYGON ((10 105, 15 105, 20 110, 10 110, 10 105.0)))
  *    GeometryCollection (2)                   GEOMETRYCOLLECTION (POLYGON ((0 0, 100 0, 100 100, 0 100, 0 0.0)), POINT (50 50.0), LINESTRING (100 100.0))
  *    LineString (1)                           LINESTRING (100 100, 900 900.0)
  *    LineString (2)                           LINESTRING (10 25, 20 30, 25 25, 30 30.0)
  *    LineString (3)                           LINESTRING (10 10, 20 10.0)
  *    LineString (Closed)                      LINESTRING (10 55, 15 55, 20 60, 10 60, 10 55.0)
  *    LineString (Self-Crossing)               LINESTRING (10 85, 20 90, 20 85, 10 90, 10 85.0)
  *    MultiCurve (1)                           MULTICURVE (CIRCULARSTRING (50 35, 55 40, 60 35.0), CIRCULARSTRING (65 35, 70 30, 75 35.0))
  *    MultiCurve (Touching)                    MULTICURVE (CIRCULARSTRING (50 65, 50 70, 55 68.0), CIRCULARSTRING (55 68, 60 65, 60 70.0))
  *    MultiLine (Closed)                       MULTILINESTRING ((50 55, 50 60, 55 58, 50 55.0), (56 58, 60 55, 60 60, 56 58.0))
  *    MultiLine (Crossing)                     MULTILINESTRING ((50 22, 60 22.0), (55 20, 55 25.0))
  *    MultiLine (Stoked)                       MULTILINESTRING ((50 15, 55 15.0), (60 15, 65 15.0))
  *    MultiPoint (2)                           MULTIPOINT ((100 100.0), (900 900.0))
  *    MultiPoint (3)                           MULTIPOINT ((65 5.0), (70 7.0), (75 5.0))
  *    MultiPoint (4)                           MULTIPOINT ((50 5.0), (55 7.0), (60 5.0))
  *    MultiPolygon (Disjoint)                  MULTIPOLYGON (((50 105, 55 105, 60 110, 50 110, 50 105.0)), ((62 108, 65 108, 65 112, 62 112, 62 108.0)))
  *    MultiPolygon (Rectangles)                MULTIPOLYGON (((1500 100, 1900 100, 1900 500, 1500 500, 1500 100.0)), ((1900 500, 2300 500, 2300 900, 1900 900, 1900 500.0)))
  *    Point (Ordinate Encoding)                POINT (10 5.0)
  *    Point (SDO_POINT encoding)               POINT (900 900.0)
  *    Polygon (No Holes)                       POLYGON ((100 100, 500 100, 500 500, 100 500, 100 100.0))
  *    Polygon (Stroked Exterior Ring)          POLYGON ((10 105, 15 105, 20 110, 10 110, 10 105.0))
  *    Polygon (With Point and a Hole)          POLYGON ((500 500, 1500 500, 1500 1500, 500 1500, 500 500.0), (900 750, 600 750, 600 1050, 900 1050, 900 750.0))
  *    Polygon (With Void)                      POLYGON ((50 135, 60 135, 60 140, 50 140, 50 135.0), (59 136, 51 136, 51 139, 59 139, 59 136.0))
  *    Rectangle (Exterior Ring)                POLYGON ((10 135, 20 135, 20 140, 10 140, 10 135.0))
  *    Rectangle (With Rectangular Hole)        POLYGON ((0 0, 200 0, 200 200, 0 200, 0 0.0), (125 25, 75 25, 75 75, 125 75, 125 25.0))
  *
  *     33 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsWKT
           Return Clob Deterministic,

  /****m* T_GEOMETRY/ST_AsEWKT
  *  NAME
  *    ST_AsEWKT -- Exports 3/4D mdsys.sdo_geometry object to an Extended Well Known Text (WKT) format.
  *  SYNOPSIS
  *    Member Function ST_AsEWKT(p_format_model in varchar2 default 'TM9')
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    If underlying geometry is 2D, ST_AsWKT() is called.
  *    If 3/4D this function creates an Extended WKT format result.
  *    This function allows the formatting of the ordinates in the EWKT string to be user defined.
  *  ARGUMENTS
  *    p_format_model (varchar2) -- Oracle Number Format Model (see documentation)
  *                                 default 'TM9')
  *  RESULT
  *    WKT (CLOB) -- Extended Well Known Text.
  *  EXAMPLE
  *    With data as (
  *     select t_geometry(sdo_geometry(3001,NULL,sdo_point_type(100,100,-37.38),NULL,NULL),0.005,2,1) as geom
  *       from dual union all
  *     select t_geometry(sdo_geometry(4001,NULL,NULL,
  *                                    sdo_elem_info_array(1,1,1),
  *                                    sdo_ordinate_array(100,100,-37.38,345.24)),0.005,2,1) as geom
  *       from dual union all
  *     select t_geometry(sdo_geometry(2002,28355,NULL,
  *                                    sdo_elem_info_array(1,2,2),
  *                                    sdo_ordinate_array(252230.478,5526918.373, 252400.08,5526918.373,252230.478,5527000.0)),0.0005,3,1) as geom
  *       from dual union all
  *     select t_geometry(sdo_geometry(2002,28355,NULL,
  *                                    sdo_elem_info_array(1,2,2),
  *                                    sdo_ordinate_array(252230.4743434348,5526918.37343433, 252400.034348,5526918.33434333473,252230.4434343378,5527000.433445660)),0.0005,3,1) as geom
  *       from dual union all
  *     select t_geometry(SDO_GEOMETRY(3302,28355,NULL,
  *                                    sdo_elem_info_array(1,2,2),
  *                                    sdo_ordinate_array(252230.478,5526918.373,0.0, 252400.08,5526918.373,417.4, 252230.478,5527000.0,506.88)),0.0005,3,1) as geom
  *       from dual union all
  *     select t_geometry(sdo_geometry(2002,NULL,NULL,
  *                                    sdo_elem_info_array(1,2,1),
  *                                    sdo_ordinate_array(100,100,900,900.0)),0.005,2,1) as geom
  *       from dual union all
  *     select t_geometry(sdo_geometry(3002,NULL,NULL,
  *                                    sdo_elem_info_array(1,2,1),
  *                                    sdo_ordinate_array(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as geom
  *       from dual union all
  *     select t_geometry(sdo_geometry(3302,NULL,NULL,
  *                                    sdo_elem_info_array(1,2,1),
  *                                    sdo_ordinate_array(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as geom
  *       from dual union all
  *     select t_geometry(sdo_geometry(4402,4283,null,
  *                                    sdo_elem_info_array(1,2,1),
  *                                    sdo_ordinate_array(147.5,-42.5,849.9,102.0, 147.6,-42.5,1923.0,2100.0)),0.005,2,0) as geom
  *      from dual union all
  *     Select T_GEOMETRY(sdo_geometry(3003,NULL,NULL,
  *                                    sdo_elem_info_array(1,1003,1),
  *                                    sdo_ordinate_array(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,2,1) as geom
  *       From Dual
  *    )
  *    select a.geom.geom.sdo_gtype as gtype,
  *           a.geom.ST_AsEWKT() as ewkt
  *      from data a;
  *
  *    GTYPE EWKT
  *    ----- -----------------------------------------------------------------------------------------------------------------------
  *     3001 POINTZ (100 100 -37.38)
  *     4001 POINTZM (100 100 -37.38 345.24)
  *     2002 CIRCULARSTRING (252230.478 5526918.373, 252400.08 5526918.373, 252230.478 5527000.0)
  *     2002 CIRCULARSTRING (252230.4743434348 5526918.37343433, 252400.034348 5526918.334343335, 252230.4434343378 5527000.43344566)
  *     3302 SRID=28355;CIRCULARSTRINGM (252230.478 5526918.373 0,252400.08 5526918.373 417.4,252230.478 5527000 506.88)
  *     2002 LINESTRING (100.0 100.0, 900.0 900.0)
  *     3002 LINESTRINGZ (0 0 1,10 0 2,10 5 3,10 10 4,5 10 5,5 5 6)
  *     3302 LINESTRINGM (0 0 1,10 0 2,10 5 3,10 10 4,5 10 5,5 5 6)
  *     4402 SRID=4283;LINESTRINGZM (147.5 -42.5 849.9 102,147.6 -42.5 1923 2100)
  *     3003 POLYGONZ ((0 0 1,10 0 2,10 5 3,10 10 4,5 10 5,5 5 6))
  *
  *     9 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsEWKT(p_format_model in varchar2 default 'TM9')
           Return Clob Deterministic,

  /****m* T_GEOMETRY/ST_AsText
  *  NAME
  *    ST_AsText -- Exports mdsys.sdo_geometry object to its Well Known Text (WKT) representation by executing, and returning, result of mdsys.sdo_geometry method get_wkt().
  *  SYNOPSIS
  *    Member Function ST_AsText
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Is a wrapper over the mdsys.sdo_geometry method SELF.GEOM.GET_WKT().
  *    Returns Well Known Text (WKT) representation of underlying mdsys.sdo_geometry.
  *  RESULT
  *    WKT (CLOB) -- eg Well Known Text encoding of mdsys.sdo_geometry object.
  *  EXAMPLE
  *    with data as (
  *      select 'CircularString (1)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,2),sdo_ordinate_array (10,15,15,20,20,15)) as geom from dual union all
  *      select 'CircularString (2)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,2),sdo_ordinate_array (10,35,15,40,20,35,25,30,30,35)) as geom from dual union all
  *      select 'CircularString (Closed)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,2),sdo_ordinate_array (15,65,10,68,15,70,20,68,15,65)) as geom from dual union all
  *      select 'CompoundCurve (1)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,4,3,1,2,1,3,2,2,7,2,1),sdo_ordinate_array (10,45,20,45,23,48,20,51,10,51)) as geom from dual union all
  *      select 'CompoundCurve (2)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,4,2,1,2,1,7,2,2),sdo_ordinate_array (10,78,10,75,20,75,20,78,15,80,10,78)) as geom from dual union all
  *      select 'CurvePolygon (Circle Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,4),sdo_ordinate_array (15,140,20,150,40,140)) as geom from dual union all
  *      select 'CurvePolygon (CircularArc Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,2),sdo_ordinate_array (15,115,20,118,15,120,10,118,15,115)) as geom from dual union all
  *      select 'CurvePolygon (Compound Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1005,2,1,2,1,7,2,2),sdo_ordinate_array (10,128,10,125,20,125,20,128,15,130,10,128)) as geom from dual union all
  *      select 'GeometryCollection (1)' as test,sdo_geometry (2004,null,null,sdo_elem_info_array (1,1,1,3,2,1,7,1003,1),sdo_ordinate_array (10,5,10,10,20,10,10,105,15,105,20,110,10,110,10,105)) as geom from dual union all
  *      select 'GeometryCollection (2)' as test,sdo_geometry(2004,NULL,NULL,sdo_elem_info_array(1,1003,3,5,1,1,9,2,1),sdo_ordinate_array(0,0,100,100,50,50,0,0,100,100.0)) as geom from dual union all
  *      select 'LineString (1)' as test,sdo_geometry(2002,NULL,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(100,100,900,900.0)) as geom from dual union all
  *      select 'LineString (2)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,1),sdo_ordinate_array (10,25,20,30,25,25,30,30)) as geom from dual union all
  *      select 'LineString (3)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,1),sdo_ordinate_array (10,10,20,10)) as geom from dual union all
  *      select 'LineString (Closed)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,1),sdo_ordinate_array (10,55,15,55,20,60,10,60,10,55)) as geom from dual union all
  *      select 'LineString (Self-Crossing)' as test,sdo_geometry (2002,null,null,sdo_elem_info_array (1,2,1),sdo_ordinate_array (10,85,20,90,20,85,10,90,10,85)) as geom from dual union all
  *      select 'MultiCurve (1)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,2,7,2,2),sdo_ordinate_array (50,35,55,40,60,35,65,35,70,30,75,35)) as geom from dual union all
  *      select 'MultiCurve (Touching)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,2,7,2,2),sdo_ordinate_array (50,65,50,70,55,68,55,68,60,65,60,70)) as geom from dual union all
  *      select 'MultiLine (Closed)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,1,9,2,1),sdo_ordinate_array (50,55,50,60,55,58,50,55,56,58,60,55,60,60,56,58)) as geom from dual union all
  *      select 'MultiLine (Crossing)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,1,5,2,1),sdo_ordinate_array (50,22,60,22,55,20,55,25)) as geom from dual union all
  *      select 'MultiLine (Stoked)' as test,sdo_geometry (2006,null,null,sdo_elem_info_array (1,2,1,5,2,1),sdo_ordinate_array (50,15,55,15,60,15,65,15)) as geom from dual union all
  *      select 'MultiPoint (2)' as test,sdo_geometry(2005,NULL,NULL,sdo_elem_info_array(1,1,2),sdo_ordinate_array(100,100,900,900.0)) as geom from dual union all
  *      select 'MultiPoint (3)' as test,sdo_geometry (2005,null,null,sdo_elem_info_array (1,1,1,3,1,1,5,1,1),sdo_ordinate_array (65,5,70,7,75,5)) as geom from dual union all
  *      select 'MultiPoint (4)' as test,sdo_geometry (2005,null,null,sdo_elem_info_array (1,1,3),sdo_ordinate_array (50,5,55,7,60,5)) as geom from dual union all
  *      select 'MultiPolygon (Disjoint)' as test,sdo_geometry (2007,null,null,sdo_elem_info_array (1,1003,1,11,1003,3),sdo_ordinate_array (50,105,55,105,60,110,50,110,50,105,62,108,65,112)) as geom from dual union all
  *      select 'MultiPolygon (Rectangles)' as test,sdo_geometry(2007,NULL,NULL,sdo_elem_info_array(1,1003,3,5,1003,3),sdo_ordinate_array(1500,100,1900,500,1900,500,2300,900.0)) as geom from dual union all
  *      select 'Point (Ordinate Encoding)' as test,sdo_geometry (2001,null,null,sdo_elem_info_array (1,1,1),sdo_ordinate_array (10,5)) as geom from dual union all
  *      select 'Point (SDO_POINT encoding)' as test,sdo_geometry(2001,NULL,sdo_point_type(900,900,NULL),NULL,NULL) as geom from dual union all
  *      select 'Polygon (No Holes)' as test,sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(100,100,500,500.0)) as geom from dual union all
  *      select 'Polygon (Stroked Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,1),sdo_ordinate_array (10,105,15,105,20,110,10,110,10,105)) as geom from dual union all
  *      select 'Polygon (With Point and a Hole)' as test,sdo_geometry(2003,NULL,MDSYS.SDO_POINT_TYPE(1000,1000,NULL),sdo_elem_info_array(1,1003,3,5,2003,3),sdo_ordinate_array(500,500,1500,1500,600,750,900,1050.0)) as geom from dual union all
  *      select 'Polygon (With Void)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,3,5,2003,3),sdo_ordinate_array (50,135,60,140,51,136,59,139)) as geom from dual union all
  *      select 'Rectangle (Exterior Ring)' as test,sdo_geometry (2003,null,null,sdo_elem_info_array (1,1003,3),sdo_ordinate_array (10,135,20,140)) as geom from dual union all
  *      select 'Rectangle (With Rectangular Hole)' as test,sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3,5,2003,3),sdo_ordinate_array(0,0,200,200,75,25,125,75.0)) as geom from dual
  *    )
  *    select a.test,
  *           T_GEOMETRY(a.geom,0.0005,3,1)
  *             .ST_Rectangle2Polygon()
  *             .ST_AsText() as geom
  *      from data a
  *     order by 1;
  *
  *    TEST                                     GEOM
  *    ---------------------------------------- -----------------------------------------------------------------------------------------------------------------------------
  *    CircularString (1)                       CIRCULARSTRING (10 15, 15 20, 20 15.0)
  *    CircularString (2)                       CIRCULARSTRING (10 35, 15 40, 20 35, 25 30, 30 35.0)
  *    CircularString (Closed)                  CIRCULARSTRING (15 65, 10 68, 15 70, 20 68, 15 65.0)
  *    CompoundCurve (1)                        COMPOUNDCURVE ((10 45, 20 45.0), CIRCULARSTRING (20 45, 23 48, 20 51.0), (20 51, 10 51.0))
  *    CompoundCurve (2)                        COMPOUNDCURVE ((10 78, 10 75, 20 75, 20 78.0), CIRCULARSTRING (20 78, 15 80, 10 78.0))
  *    CurvePolygon (Circle Exterior Ring)      CURVEPOLYGON ((15 140, 27.5 127.5, 40 140, 27.5 152.5, 15 140.0))
  *    CurvePolygon (CircularArc Exterior Ring) CURVEPOLYGON (CIRCULARSTRING (15 115, 20 118, 15 120, 10 118, 15 115.0))
  *    CurvePolygon (Compound Exterior Ring)    CURVEPOLYGON (COMPOUNDCURVE ((10 128, 10 125, 20 125, 20 128.0), CIRCULARSTRING (20 128, 15 130, 10 128.0)))
  *    GeometryCollection (1)                   GEOMETRYCOLLECTION (POINT (10 5.0), LINESTRING (10 10, 20 10.0), POLYGON ((10 105, 15 105, 20 110, 10 110, 10 105.0)))
  *    GeometryCollection (2)                   GEOMETRYCOLLECTION (POLYGON ((0 0, 100 0, 100 100, 0 100, 0 0.0)), POINT (50 50.0), LINESTRING (100 100.0))
  *    LineString (1)                           LINESTRING (100 100, 900 900.0)
  *    LineString (2)                           LINESTRING (10 25, 20 30, 25 25, 30 30.0)
  *    LineString (3)                           LINESTRING (10 10, 20 10.0)
  *    LineString (Closed)                      LINESTRING (10 55, 15 55, 20 60, 10 60, 10 55.0)
  *    LineString (Self-Crossing)               LINESTRING (10 85, 20 90, 20 85, 10 90, 10 85.0)
  *    MultiCurve (1)                           MULTICURVE (CIRCULARSTRING (50 35, 55 40, 60 35.0), CIRCULARSTRING (65 35, 70 30, 75 35.0))
  *    MultiCurve (Touching)                    MULTICURVE (CIRCULARSTRING (50 65, 50 70, 55 68.0), CIRCULARSTRING (55 68, 60 65, 60 70.0))
  *    MultiLine (Closed)                       MULTILINESTRING ((50 55, 50 60, 55 58, 50 55.0), (56 58, 60 55, 60 60, 56 58.0))
  *    MultiLine (Crossing)                     MULTILINESTRING ((50 22, 60 22.0), (55 20, 55 25.0))
  *    MultiLine (Stoked)                       MULTILINESTRING ((50 15, 55 15.0), (60 15, 65 15.0))
  *    MultiPoint (2)                           MULTIPOINT ((100 100.0), (900 900.0))
  *    MultiPoint (3)                           MULTIPOINT ((65 5.0), (70 7.0), (75 5.0))
  *    MultiPoint (4)                           MULTIPOINT ((50 5.0), (55 7.0), (60 5.0))
  *    MultiPolygon (Disjoint)                  MULTIPOLYGON (((50 105, 55 105, 60 110, 50 110, 50 105.0)), ((62 108, 65 108, 65 112, 62 112, 62 108.0)))
  *    MultiPolygon (Rectangles)                MULTIPOLYGON (((1500 100, 1900 100, 1900 500, 1500 500, 1500 100.0)), ((1900 500, 2300 500, 2300 900, 1900 900, 1900 500.0)))
  *    Point (Ordinate Encoding)                POINT (10 5.0)
  *    Point (SDO_POINT encoding)               POINT (900 900.0)
  *    Polygon (No Holes)                       POLYGON ((100 100, 500 100, 500 500, 100 500, 100 100.0))
  *    Polygon (Stroked Exterior Ring)          POLYGON ((10 105, 15 105, 20 110, 10 110, 10 105.0))
  *    Polygon (With Point and a Hole)          POLYGON ((500 500, 1500 500, 1500 1500, 500 1500, 500 500.0), (900 750, 600 750, 600 1050, 900 1050, 900 750.0))
  *    Polygon (With Void)                      POLYGON ((50 135, 60 135, 60 140, 50 140, 50 135.0), (59 136, 51 136, 51 139, 59 139, 59 136.0))
  *    Rectangle (Exterior Ring)                POLYGON ((10 135, 20 135, 20 140, 10 140, 10 135.0))
  *    Rectangle (With Rectangular Hole)        POLYGON ((0 0, 200 0, 200 200, 0 200, 0 0.0), (125 25, 75 25, 75 75, 125 75, 125 25.0))
  *
  *     33 rows selected
  *  NOTES
  *    Is an implementation of OGC ST_AsText method.
  *    Any polygon containing optimized rectangles rings is converted to its 5 point equivalent.
  *    Only supports 2D geometries.
  *  TODO
  *    Convert Optimized Rectangles to BBOX elements.
  *    Create ST_AsEWKT() method and ST_FromEWKT() or use SC4O Java methods.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsText
           Return Clob Deterministic,

  /****m* T_GEOMETRY/ST_FromText
  *  NAME
  *    ST_FromText -- This is a wrapper function that has the ST_FromText name common to users of PostGIS.
  *  SYNOPSIS
  *    Static Function ST_FromText(p_wkt  in clob,
  *                                p_srid in integer default NULL)
  *              Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Implements an import method for standard Well Known Text.
  *    Returns T_GEOMETRY with valid sdo_geometry object.
  *    Uses the SDO_GEOMETRY(CLOB,INTEGER) constructor to create a
  *    T_GEOMETRY object with default tolerance, dPrecision and projected variable values.
  *  RESULT
  *    New Geometry (T_GEOMETRY) -- T_GEOMETRY containing a valid 2D sdo_geometry object with default parameters.
  *  EXAMPLE
  *    with data as (
  *      select 'POINT (0.1 0.2)' as wkt from dual union all
  *      select 'LINESTRING (0.1 0.1,10 0,10 5,10 10,5 10,5 5)' as wkt from dual union all
  *      select 'MULTILINESTRING ((50.0 55.0, 50.0 60.0, 55.0 58.0, 50.0 55.0), (56.0 58.0, 60.0 55.0, 60.0 60.0, 56.0 58.0))' as wkt from dual union all
  *      select 'CIRCULARSTRING (10.0 15.0, 15.0 20.0, 20.0 15.0)' as wkt from dual union all
  *      select 'COMPOUNDCURVE ((10.0 45.0, 20.0 45.0), CIRCULARSTRING (20.0 45.0, 23.0 48.0, 20.0 51.0), (20.0 51.0, 10.0 51.0))' as wkt from dual union all
  *      select 'MULTICURVE (CIRCULARSTRING (50.0 35.0, 55.0 40.0, 60.0 35.0), CIRCULARSTRING (65.0 35.0, 70.0 30.0, 75.0 35.0))' as wkt from dual union all
  *      select 'CURVEPOLYGON (COMPOUNDCURVE ((10.0 128.0, 10.0 125.0, 20.0 125.0, 20.0 128.0), CIRCULARSTRING (20.0 128.0, 15.0 130.0, 10.0 128.0)))' as wkt from dual union all
  *      select 'MULTIPOLYGON (((1500.0 100.0, 1900.0 100.0, 1900.0 500.0, 1500.0 500.0, 1500.0 100.0)), ((1900.0 500.0, 2300.0 500.0, 2300.0 900.0, 1900.0 900.0, 1900.0 500.0)))' as wkt from dual union all
  *      select 'GEOMETRYCOLLECTION (POINT (10.0 5.0), LINESTRING (10.0 10.0, 20.0 10.0), POLYGON ((10.0 105.0, 15.0 105.0, 20.0 110.0, 10.0 110.0, 10.0 105.0)))' as wkt from dual
  *    )
  *    select T_GEOMETRY.ST_FromText(a.wkt).geom as geomFromWkt
  *      from data a;
  *
  *    GEOMFROMWKT
  *    ---------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(0.1,0.2,NULL),NULL,NULL)
  *    SDO_GEOMETRY(2002,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1),
  *                 SDO_ORDINATE_ARRAY(0.1,0.1,10,0,10,5,10,10,5,10,5,5))
  *    SDO_GEOMETRY(2006,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1,9,2,1),
  *                 SDO_ORDINATE_ARRAY(50,55,50,60,55,58,50,55,56,58,60,55,60,60,56,58))
  *    SDO_GEOMETRY(2002,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,2),
  *                 SDO_ORDINATE_ARRAY(10,15,15,20,20,15))
  *    SDO_GEOMETRY(2002,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,4,3,1,2,1,3,2,2,7,2,1),
  *                 SDO_ORDINATE_ARRAY(10,45,20,45,23,48,20,51,10,51))
  *    SDO_GEOMETRY(2006,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,2,7,2,2),
  *                 SDO_ORDINATE_ARRAY(50,35,55,40,60,35,65,35,70,30,75,35))
  *    SDO_GEOMETRY(2003,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,7,2,2),
  *                 SDO_ORDINATE_ARRAY(10,128,10,125,20,125,20,128,15,130,10,128))
  *    SDO_GEOMETRY(2007,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,1003,1,11,1003,1),
  *                 SDO_ORDINATE_ARRAY(1500,100,1900,100,1900,500,1500,500,1500,100,1900,500,2300,500,2300,900,1900,900,1900,500))
  *    SDO_GEOMETRY(2004,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,1,1,3,2,1,7,1003,1),
  *                 SDO_ORDINATE_ARRAY(10,5,10,10,20,10,10,105,15,105,20,110,10,110,10,105))
  *
  *     9 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Static Function ST_FromText(p_wkt  in clob,
                              p_srid in integer default NULL)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_FromEWKT
  *  NAME
  *    ST_FromEWKT -- Implements an import method for Extended Well Known Text including EWKT with Z and M ordinates..
  *  SYNOPSIS
  *    Static Function ST_FromEWKT(p_ewkt in clob)
  *              Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Implements an import method for Extended Well Known Text including EWKT with Z and M ordinates..
  *    Returns T_GEOMETRY with valid sdo_geometry object.
  *    Will import SQL Server Spatial (AsTextZM) and PostGIS EWKT.
  *    Supports EWKT like "POINT EMPTY".
  *  NOTES
  *    A description of the EWKT structure is available in the PostGIS documentation.
  *  RESULT
  *    New Geometry (T_GEOMETRY) -- T_GEOMETRY containing a valid sdo_geometry with 2, 3 or 4 dimensions.
  *  EXAMPLE
  *    with data as (
  *      select 'SRID=28355;POINTZ (0.1 0.2 0.3)' as ewkt
  *        from dual union all
  *      select 'SRID=28355;POINTZM (0.1 0.2 0.3 0.4)' as ewkt
  *        from dual union all
  *      select 'LINESTRING (0.1 0.1,10 0,10 5,10 10,5 10,5 5)' as ewkt
  *        from dual union all
  *      select 'SRID=28355;LINESTRINGZ (0.1 0.1 1,10 0 2,10 5 3,10 10 4,5 10 5,5 5 6)' as ewkt
  *        from dual union all
  *      select 'MULTILINESTRINGM ((50.0 55.0 1, 50.0 60.0 2, 55.0 58.0 3, 50.0 55.0 4), (56.0 58.0 5, 60.0 55.0 6, 60.0 60.0 7, 56.0 58.0 8))' as ewkt
  *        from dual union all
  *      select 'CIRCULARSTRINGZ (10.0 15.0 3.0, 15.0 20.0 3.0, 20.0 15.0 3.0)' as ewkt
  *        from dual union all
  *      select 'CIRCULARSTRINGZM (10.0 15.0 3.0 0.0, 15.0 20.0 3.0 5.67, 20.0 15.0 3.0 9.84)' as ewkt
  *        from dual union all
  *      select 'CIRCULARSTRINGM (10.0 15.0 0.0, 15.0 20.0 5.67, 20.0 15.0 9.84)' as ewkt
  *        from dual union all
  *      select 'COMPOUNDCURVEZ ((10.0 45.0 0.0, 20.0 45.0 1.6), CIRCULARSTRING (20.0 45.0 1.8, 23.0 48.0 1.8, 20.0 51.0 1.8), (20.0 51.0 1.8, 10.0 51.0 1.8))' as ewkt
  *        from dual union all
  *      select 'SRID=28355;MULTICURVEZ (CIRCULARSTRING (50.0 35.0 3.2, 55.0 40.0 3.2, 60.0 35.0 3.2), CIRCULARSTRING (65.0 35.0 4.6, 70.0 30.0 5.6, 75.0 35.0 2.3))' as ewkt
  *        from dual union all
  *      select 'CURVEPOLYGON (COMPOUNDCURVE ((10.0 128.0, 10.0 125.0, 20.0 125.0, 20.0 128.0), CIRCULARSTRING (20.0 128.0, 15.0 130.0, 10.0 128.0)))' as ewkt
  *        from dual union all
  *      select 'MULTIPOLYGONZ (((1500.0 100.0 0.0, 1900.0 100.0 0.1, 1900.0 500.0 0.2, 1500.0 500.0 0.3, 1500.0 100.0 0.0)), ((1900.0 500.0 2.0, 2300.0 500.0 2.1, 2300.0 900.0 2.2, 1900.0 900.0 1.8, 1900.0 500.0 2.0)))' as ewkt
  *        from dual union all
  *      select 'GEOMETRYCOLLECTION (POINT (10.0 5.0), LINESTRING (10.0 10.0, 20.0 10.0), POLYGON ((10.0 105.0, 15.0 105.0, 20.0 110.0, 10.0 110.0, 10.0 105.0)))' as ewkt
  *        from dual union all
  *      select 'SRID=28355;GEOMETRYCOLLECTIONZ (POINT (10.0 5.0 1.0), LINESTRING (10.0 10.0 1.1, 20.0 10.0 1.2), POLYGON ((10.0 105.0 1.3, 15.0 105.0 1.3, 20.0 110.0 1.4, 10.0 110.0 1.2, 10.0 105.0 1.3)))' as ewkt
  *        from dual
  *    )
  *    select T_GEOMETRY.ST_FromEWKT(a.ewkt).geom as geomFromEWkt
  *      from data a;
  *
  *    GEOMFROMEWKT
  *    ----------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(0.1,0.2,0.3),NULL,NULL)
  *    SDO_GEOMETRY(4401,28355,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,1,1),
  *                 SDO_ORDINATE_ARRAY(0.1,0.2,0.3,0.4))
  *    SDO_GEOMETRY(2002,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1),
  *                 SDO_ORDINATE_ARRAY(0.1,0.1,10,0,10,5,10,10,5,10,5,5))
  *    SDO_GEOMETRY(3002,28355,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1),
  *                 SDO_ORDINATE_ARRAY(0.1,0.1,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6))
  *    SDO_GEOMETRY(3306,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1,13,2,1),
  *                 SDO_ORDINATE_ARRAY(50,55,1,50,60,2,55,58,3,50,55,4,56,58,5,60,55,6,60,60,7,56,58,8))
  *    SDO_GEOMETRY(3002,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,2),
  *                 SDO_ORDINATE_ARRAY(10,15,3,15,20,3,20,15,3))
  *    SDO_GEOMETRY(4402,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,2),
  *                 SDO_ORDINATE_ARRAY(10,15,3,0,15,20,3,5.67,20,15,3,9.84))
  *    SDO_GEOMETRY(3302,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,2),
  *                 SDO_ORDINATE_ARRAY(10,15,0,15,20,5.67,20,15,9.84))
  *    SDO_GEOMETRY(3002,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,4,3,1,2,1,4,2,2,10,2,1),
  *                 SDO_ORDINATE_ARRAY(10,45,0,20,45,1.6,20,45,1.8,23,48,1.8,20,51,1.8,20,51,1.8,10,51,1.8))
  *    SDO_GEOMETRY(3006,28355,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,2,10,2,2),
  *                 SDO_ORDINATE_ARRAY(50,35,3.2,55,40,3.2,60,35,3.2,65,35,4.6,70,30,5.6,75,35,2.3))
  *    SDO_GEOMETRY(2003,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,7,2,2),
  *                 SDO_ORDINATE_ARRAY(10,128,10,125,20,125,20,128,15,130,10,128))
  *    SDO_GEOMETRY(3007,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,1003,1,16,1003,1),
  *                 SDO_ORDINATE_ARRAY(1500,100,0,1900,100,0.1,1900,500,0.2,1500,500,0.3,1500,100,0,1900,500,2,2300,500,2.1,2300,900,2.2,1900,900,1.8,1900,500,2))
  *    SDO_GEOMETRY(2004,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,1,1,3,2,1,7,1003,1),
  *                 SDO_ORDINATE_ARRAY(10,5,10,10,20,10,10,105,15,105,20,110,10,110,10,105))
  *    SDO_GEOMETRY(3004,28355,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,1,1,4,2,1,10,1003,1),
  *                 SDO_ORDINATE_ARRAY(10,5,1,10,10,1.1,20,10,1.2,10,105,1.3,15,105,1.3,20,110,1.4,10,110,1.2,10,105,1.3))
  *
  *     14 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Static Function ST_FromEWKT(p_ewkt in clob)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

 /****m* T_GEOMETRY/ST_AsTText
  *  NAME
  *    ST_AsTText -- Returns text Description of T_GEOMETRY
  *  SYNOPSIS
  *    Member Function ST_AsTText(p_linefeed     in integer default 1,
  *                               p_format_model in varchar2 default 'TM9')
  *             Return CLOB Deterministic,
  *  DESCRIPTION
  *    Returns textual description of T_GEOMETRY.
  *    Rounds ordinates via object dPrecision variable.
  *  ARGUMENTS
  *    p_linefeed (integer) - 1 if apply linefeed to coordinates
  *    p_format_model (varchar2) -- Oracle Number Format Model (see documentation)
  *                                 default 'TM9')
  *  RESULT
  *    textual description (string)
  *  EXAMPLE
  *    with data as (
  *      select 'POINT (0.1 0.2)' as wkt from dual union all
  *      select 'LINESTRING (0.1 0.1,10 0,10 5,10 10,5 10,5 5)' as wkt from dual union all
  *      select 'MULTILINESTRING ((50.0 55.0, 50.0 60.0, 55.0 58.0, 50.0 55.0), (56.0 58.0, 60.0 55.0, 60.0 60.0, 56.0 58.0))' as wkt from dual union all
  *      select 'CIRCULARSTRING (10.0 15.0, 15.0 20.0, 20.0 15.0)' as wkt from dual union all
  *      select 'COMPOUNDCURVE ((10.0 45.0, 20.0 45.0), CIRCULARSTRING (20.0 45.0, 23.0 48.0, 20.0 51.0), (20.0 51.0, 10.0 51.0))' as wkt from dual union all
  *      select 'MULTICURVE (CIRCULARSTRING (50.0 35.0, 55.0 40.0, 60.0 35.0), CIRCULARSTRING (65.0 35.0, 70.0 30.0, 75.0 35.0))' as wkt from dual union all
  *      select 'CURVEPOLYGON (COMPOUNDCURVE ((10.0 128.0, 10.0 125.0, 20.0 125.0, 20.0 128.0), CIRCULARSTRING (20.0 128.0, 15.0 130.0, 10.0 128.0)))' as wkt from dual union all
  *      select 'MULTIPOLYGON (((1500.0 100.0, 1900.0 100.0, 1900.0 500.0, 1500.0 500.0, 1500.0 100.0)), ((1900.0 500.0, 2300.0 500.0, 2300.0 900.0, 1900.0 900.0, 1900.0 500.0)))' as wkt from dual union all
  *      select 'GEOMETRYCOLLECTION (POINT (10.0 5.0), LINESTRING (10.0 10.0, 20.0 10.0), POLYGON ((10.0 105.0, 15.0 105.0, 20.0 110.0, 10.0 110.0, 10.0 105.0)))' as wkt from dual
  *    )
  *    select T_GEOMETRY.ST_FromText(a.wkt).ST_AsTText() as t_geom
  *      from data a;
  *
  *    T_GEOM
  *    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(0.1,0.2,NULL),NULL,NULL);TOLERANCE(.005),PRECISION(2),PROJECTED(1)
  *    T_GEOMETRY(SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.1,0.1,10.0,0.0,10.0,5.0,10.0,10.0,5.0,10.0,5.0,5.0));TOLERANCE(.005),PRECISION(2),PROJECTED(1)
  *    T_GEOMETRY(SDO_GEOMETRY(2006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,9,2,1),SDO_ORDINATE_ARRAY(50.0,55.0,50.0,60.0,55.0,58.0,50.0,55.0,56.0,58.0,60.0,55.0,60.0,60.0,56.0,58.0));TOLERANCE(.005),PRECISION(2),PROJECTED(1)
  *    T_GEOMETRY(SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(10.0,15.0,15.0,20.0,20.0,15.0));TOLERANCE(.005),PRECISION(2),PROJECTED(1)
  *    T_GEOMETRY(SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,4,3,1,2,1,3,2,2,7,2,1),SDO_ORDINATE_ARRAY(10.0,45.0,20.0,45.0,23.0,48.0,20.0,51.0,10.0,51.0));TOLERANCE(.005),PRECISION(2),PROJECTED(1)
  *    T_GEOMETRY(SDO_GEOMETRY(2006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2,7,2,2),SDO_ORDINATE_ARRAY(50.0,35.0,55.0,40.0,60.0,35.0,65.0,35.0,70.0,30.0,75.0,35.0));TOLERANCE(.005),PRECISION(2),PROJECTED(1)
  *    T_GEOMETRY(SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,7,2,2),SDO_ORDINATE_ARRAY(10.0,128.0,10.0,125.0,20.0,125.0,20.0,128.0,15.0,130.0,10.0,128.0));TOLERANCE(.005),PRECISION(2),PROJECTED(1)
  *    T_GEOMETRY(SDO_GEOMETRY(2007,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1,11,1003,1),SDO_ORDINATE_ARRAY(1500.0,100.0,1900.0,100.0,1900.0,500.0,1500.0,500.0,1500.0,100.0,1900.0,500.0,2300.0,500.0,2300.0,900.0,1900.0,900.0,1900.0,500.0));
  *               TOLERANCE(.005),PRECISION(2),PROJECTED(1)
  *    T_GEOMETRY(SDO_GEOMETRY(2004,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1,3,2,1,7,1003,1),SDO_ORDINATE_ARRAY(10.0,5.0,10.0,10.0,20.0,10.0,10.0,105.0,15.0,105.0,20.0,110.0,10.0,110.0,10.0,105.0));
  *               TOLERANCE(.005),PRECISION(2),PROJECTED(1)
  *
  *     9 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsTText(p_linefeed     in integer default 1,
                             p_format_model in varchar2 default 'TM9')
           Return Clob Deterministic,

  /****m* T_GEOMETRY/ST_CoordDimension
  *  NAME
  *    ST_CoordDimension -- Returns Coordinate Dimension of mdsys.sdo_geometry object.
  *  SYNOPSIS
  *    Member Function ST_CoordDimension
  *             Return Integer Deterministic,
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('POINT(0 0)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3001,NULL,SDO_POINT_TYPE(0,0,0),null,null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('MULTILINESTRING((-1 -1, 0 -1),(0 0,10 0,10 5,10 10,5 10,5 5))',null),0.005,3,1) as tgeom From Dual union all
  *      select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GeometryType()   as geomType,
  *           a.tGeom.ST_GType()          as sdo_gtype,
  *           a.tGeom.ST_CoordDimension() as coordDim,
  *           a.tgeom.ST_Dimension()      as geomDim
  *      from data a;
  *
  *    GEOMTYPE             SDO_GTYPE   COORDDIM    GEOMDIM
  *    ------------------- ---------- ---------- ----------
  *    ST_POINT                     1          2          0
  *    ST_POINT                     1          3          0
  *    ST_LINESTRING                2          2          1
  *    ST_LINESTRING                2          3          1
  *    ST_MULTILINESTRING           6          2          1
  *    ST_POLYGON                   3          2          2
  *    ST_MULTIPOLYGON              7          2          2
  *
  *     7 rows selected
  *
  *  DESCRIPTION
  *    Is a wrapper over the mdsys.sdo_geometry method SELF.GEOM.ST_CoordDimen().
  *    Returns Coordinate Dimension of mdsys.sdo_geometry object.
  *  RESULT
  *    Coordinate Dimension (SMALLINT) -- 2 if 2001; 3 is 3001 etc.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_CoordDimension
           Return Smallint Deterministic,

  /****m* T_GEOMETRY/ST_Dimension
  *  NAME
  *    ST_Dimension -- Returns spatial dimension of underlying geometry.
  *  SYNOPSIS
  *    Member Function ST_Dimension
  *             Return Integer Deterministic,
  *  NOTES
  *    Is an implementation of OGC ST_Dimension method.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('POINT(0 0)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('MULTILINESTRING((-1 -1, 0 -1),(0 0,10 0,10 5,10 10,5 10,5 5))',null),0.005,3,1) as tgeom From Dual union all
  *      select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom From Dual union all
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tGeom.ST_GType()        as sdo_gtype,
  *           a.tgeom.ST_GeometryType() as geomType,
  *           a.tgeom.ST_Dimension()    as geomDim
  *      from data a;
  *
  *    SDO_GTYPE GEOMTYPE             GEOMDIM
  *    --------- -------------------- -------
  *            1 ST_POINT                   0
  *            2 ST_LINESTRING              1
  *            6 ST_MULTILINESTRING         1
  *            3 ST_POLYGON                 2
  *            7 ST_MULTIPOLYGON            2
  *            7 ST_MULTIPOLYGON            2
  *
  *    6 rows selected
  *
  *  DESCRIPTION
  *    Is OGC method that returns the geometric dimension of the underlying geometry.
  *    The dimensions returned are:
  *    GeometryType Dimension
  *    ------------ ---------
  *           Point         0
  *      LineString         1
  *         Polygon         2
  *    OGC Dimension is not to be confused with coordinate dimension ie number of ordinates. See ST_CoordDimension.
  *  RESULT
  *    Dimension (Integer) -- 0 if 2001/3 if 3001; 1 if 2002/3302/3002; 2 if 2003/2007/3003/3007 etc.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Dimension
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_HasDimension
  *  NAME
  *    ST_HasDimension -- Returns spatial dimension of underlying geometry.
  *  SYNOPSIS
  *    Member Function ST_HasDimension (
  *                       p_dim  in integer default 2
  *                    )
  *             Return Integer Deterministic,
  *  EXAMPLE
  *
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('POINT(0 0)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GType()           as sdo_gtype,
  *           a.tgeom.ST_GeometryType()    as geomType,
  *           a.tgeom.ST_CoordDimension()  as coordDim,
  *           a.tgeom.ST_Dimension()       as geomDim,
  *           a.tgeom.ST_HasDimension(1)   as hasDim1
  *      from data a;
  *
  *    SDO_GTYPE GEOMTYPE       COORDDIM GEOMDIM HASDIM1
  *    --------- -------------- -------- ------- -------
  *            1 ST_POINT              2       0       0
  *            2 ST_LINESTRING         2       1       1
  *            3 ST_POLYGON            2       2       0
  *
  *  DESCRIPTION
  *    This method inspects the underlying geometry and determines if has specified Geometric Dimension (ST_Dimension).
  *    Returns 1 if geometry is of that dimension and 0 otherwise.
  *  RESULT
  *   true(1)/false(0) (Integer) -- If p_dim is 0 and underlying geometry is POINT then 1 is returned else 0.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_hasDimension   (p_dim  in integer default 2)
           Return Integer  Deterministic,

  /****m* T_GEOMETRY/ST_HasZ
  *  NAME
  *    ST_HasZ -- Checks if underlying geometry has z ordinate.
  *  SYNOPSIS
  *    Member Function ST_HasZ
  *             Return Integer Deterministic,
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('POINT(0 0)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3001,NULL,SDO_POINT_TYPE(0,0,0),null,null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GType()          as sdo_gtype,
  *           a.tgeom.ST_GeometryType()   as geomType,
  *           a.tgeom.ST_CoordDimension() as coordDim,
  *           a.tgeom.ST_HasZ()           as hasZ
  *    from data a;
  *
  *    SDO_GTYPE GEOMTYPE       COORDDIM HASZ
  *    --------- -------------- -------- ----
  *            1 ST_POINT              2    0
  *            1 ST_POINT              3    1
  *            2 ST_LINESTRING         2    0
  *            2 ST_LINESTRING         3    1
  *            2 ST_LINESTRING         3    0
  *  DESCRIPTION
  *    This method inspects the underlying geometry and determines if has a Z ordinate (3D).
  *    Returns 1 if geometry has Z ordinate and 0 otherwise.
  *  RESULT
  *   true(1)/false(0) (Integer) -- If 2001 POINT then 0; if 3001 then 1; if 3002 then1, if 3302 then 0.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_hasZ
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_hasM
  *  NAME
  *    ST_hasM -- Tests geometry to see if coordinates include a measure.
  *  SYNOPSIS
  *    Member Function ST_hasM
  *             Return Integer Deterministic,
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry(3301,NULL,SDO_POINT_TYPE(0,0,0),null,null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GType()          as sdo_gtype,
  *           a.tgeom.ST_GeometryType()   as geomType,
  *           a.tgeom.ST_CoordDimension() as coordDim,
  *           a.tgeom.ST_HasM()           as hasM
  *      from data a;
  *
  *    SDO_GTYPE GEOMTYPE       COORDDIM HASM
  *    --------- -------------- -------- ----
  *            1 ST_POINT              3    1
  *            2 ST_LINESTRING         2    0
  *            2 ST_LINESTRING         3    0
  *            2 ST_LINESTRING         3    1
  *  DESCRIPTION
  *    Examines SELF.GEOM.SDO_GTYPE (DLNN etc) to see if sdo_gtype has measure ordinate eg 3302 not 3002.
  *    Similar to SQL Server Spatial hasM method.
  *  RESULT
  *    BOOLEAN (Integer) -- 1 is measure ordinate exists, 0 otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_hasM
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_isValid
  *  NAME
  *    ST_isValid -- Executes, and returns, result of mdsys.sdo_geometry method ST_isValid().
  *  SYNOPSIS
  *    Member Function ST_isValid
  *             Return Integer Deterministic,
  *  NOTES
  *    Is an implementation of OGC ST_isValid method.
  *  DESCRIPTION
  *    Is a wrapper over the mdsys.sdo_geometry method SELF.GEOM.ST_isValid().
  *    See also SDO_GEOM.VALIDATE_GEOMETRY etc.
  *  RESULT
  *    BOOLEAN (Integer) -- If mdsys.sdo_geometry is valid (see SDO_GEOM.VALIDATE_GEOMETRY) returns 1 else 0.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isValid
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_Validate
  *  NAME
  *    ST_isValid -- Executes sdo_geom.validate_geometry or validate_geometry_with_context against underlying geometry and returns value.
  *  SYNOPSIS
  *    Member Function ST_Validate
  *             Return varchar2 Deterministic,
  *  DESCRIPTION
  *    If p_context = 0 then this function executes the SDO_GEOM.VALIDATE_GEOMETRY function and returns the result.
  *    If p_context = 1 then this function executes the SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT function and returns the result.
  *  ARGUMENTS
  *    p_context (integer) -- Value of 0 (no context); 1 (context)
  *  RESULT
  *    result (varchar2) -- Returns result of SDO_GEOM.VALIDATE_GEOMETRY/SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT function.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Validate (p_context in integer default 0)
           Return varchar2 Deterministic,

  /****m* T_GEOMETRY/ST_isValidContext
  *  NAME
  *    ST_isValidContext -- Executes sdo_geom.validate_geometry_with_context against underlying geometry and returns value.
  *  SYNOPSIS
  *    Member Function ST_isValidContext
  *             Return varchar2 Deterministic,
  *  DESCRIPTION
  *    This function executes the SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT function and returns the result.
  *  RESULT
  *    result (varchar2) -- Returns result of SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT function.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isValidContext
           Return varchar2 Deterministic,

  /****m* T_GEOMETRY/ST_isEmpty
  *  NAME
  *    ST_isEmpty -- Checks if underlying geometry object is empty.
  *  SYNOPSIS
  *    Member Function ST_isEmpty
  *             Return integer Deterministic,
  *  NOTES
  *    Is an implementation of OGC ST_isEmpty method.
  *    cf "POINT EMPTY"/"LINESTRING EMPTY"/"POLYGON EMPTY" OGC
  *  DESCRIPTION
  *    This function checks to see if the underlying object is empty.
  *    While some Spatial Types define empty via WKT string such as 'LINESTRING EMPTY', for oracle
  *    we determine that an sdo_geometry object is Empty if:
  *    1. The object is null;
  *    2. The object exists but all of its 5 attributes (sdo_gtype, sdo_srid, sdo_point, sdo_elem_info, sdo_ordinates) are null.
  *    3. Or the object exists but all of its 3 main geometric attributes (sdo_point, sdo_elem_info, sdo_ordinates) are null.
  *  RESULT
  *    1/0 (integer) -- 1 if Empty, 0 if not.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isEmpty
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_isClosed
  *  NAME
  *    ST_isClosed -- Checks if underlying geometry object is simple as per the OGC.
  *  SYNOPSIS
  *    Member Function ST_isClosed
  *             Return integer Deterministic,
  *  DESCRIPTION
  *    This function checks to see if the underlying linestring is closed.
  *    A closed linestring is one whose start/end points are the same as in a polygon ring.
  *  RESULT
  *    1/0 (integer) -- 1 if Closed, 0 if not.
  *    With data as (
  *      select 'Simple 2 point line' as test,
  *             t_geometry(sdo_geometry('LINESTRING(0 0,1 1)',null),0.005,2,1) as tGeom
  *        from dual union all
  *      select 'Line with 4 Points with two segments crossing' as test,
  *             t_geometry(sdo_geometry('LINESTRING(0 0,1 1,1 0,0 1)',null),0.005,2,1) as tGeom
  *        from dual union all
  *      select 'Line whose start/end points are the same (closed)' as test,
  *             t_geometry(sdo_geometry('LINESTRING(0 0,1 0,1 1,0 1,0 0)',null),0.005,2,1) as tGeom
  *        from dual
  *    )
  *    Select a.test, a.tGeom.ST_Closed() as isSimple
  *      from data a;
  *
  *    TEST                                              ISSIMPLE
  *    ------------------------------------------------- --------
  *    Simple 2 point line                                      1
  *    Line with 4 Points with two segments crossing            0
  *    Line whose start/end points are the same (closed)        1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isClosed
           Return integer deterministic,

  /****m* T_GEOMETRY/ST_isSimple
  *  NAME
  *    ST_isSimple -- Checks if underlying geometry object is simple as per the OGC.
  *  SYNOPSIS
  *    Member Function ST_isSimple
  *             Return integer Deterministic,
  *  NOTES
  *    Is an implementation of OGC ST_isSimple method.
  *  DESCRIPTION
  *    This function checks to see if the underlying object is simple.
  *    A simple linestring is one for which none of its segments cross each other.
  *    This is not the same as a closed linestring whose start/end points are the same as in a polygon ring.
  *    This function does this by using the Oracle MDSYS.ST_GEOMETRY.ST_isSimple method.
  *  RESULT
  *    1/0 (integer) -- 1 if Simple, 0 if not.
  *
  *    With data as (
  *      select 'Simple 2 point line' as test,
  *             t_geometry(sdo_geometry('LINESTRING(0 0,1 1)',null),0.005,2,1) as tGeom
  *        from dual union all
  *      select 'Line with 4 Points with two segments crossing' as test,
  *             t_geometry(sdo_geometry('LINESTRING(0 0,1 1,1 0,0 1)',null),0.005,2,1) as tGeom
  *        from dual union all
  *      select 'Line whose start/end points are the same (closed)' as test,
  *             t_geometry(sdo_geometry('LINESTRING(0 0,1 0,1 1,0 1,0 0)',null),0.005,2,1) as tGeom
  *        from dual
  *    )
  *    Select a.test, a.tGeom.ST_isSimple() as isSimple
  *      from data a;
  *
  *    TEST                                              ISSIMPLE
  *    ------------------------------------------------- --------
  *    Simple 2 point line                                      1
  *    Line with 4 Points with two segments crossing            0
  *    Line whose start/end points are the same (closed)        1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isSimple
           Return integer deterministic,

  /****m* T_GEOMETRY/ST_GeometryType
  *  NAME
  *    ST_GeometryType -- Returns underlying mdsys.sdo_geometry's SQLMM Geometry Type.
  *  SYNOPSIS
  *    Member Function ST_GeometryType
  *             Return VarChar2 Deterministic,
  *  DESCRIPTION
  *    Is a wrapper over the ST_GEOMETRY ST_GeometryType() method. Returns textual description of the geometry type
  *    eg ST_Polygon for x003 mdsys.sdo_geometry object.
  *  NOTES
  *    Is an implementation of OGC ST_GeometryType method.
  *  RESULT
  *    geometry type (Integer) -- 1:Point; 2:Linestring; 3:Polygon; 4:Collection; 5:MultiPoint; 6:MultiLinestring; 7:MultiPolygon
  *  EXAMPLE
  *    With Geometries As (
  *       select T_GEOMETRY(sdo_geometry(2001,NULL,sdo_point_type(10,11,null),null,null),0.005,2,1) as TGEOM
  *         From Dual Union All
  *       Select T_GEOMETRY(sdo_geometry(2002,NULL,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(10,45, 20,45, 23,48, 20,51, 10,51)),0.005,1,1) as TGEOM
  *         From Dual Union All
  *       Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(0,0, 10,10)),0.005,1,1) as TGEOM
  *         From Dual Union All
  *       select t_geometry(sdo_geometry(2003,null,null,sdo_elem_info_array(1,1005,2, 1,2,1, 7,2,2),
  *                         SDO_ORDINATE_ARRAY (10,128, 10,125, 20,125, 20,128, 15,130, 10,128)),0.005,2,1) as TGEOM
  *        From Dual Union All
  *       Select T_GEOMETRY(sdo_geometry(2002,null,null,sdo_elem_info_array(1,4,3, 1,2,1, 3,2,2, 7,2,1),
  *                         sdo_ordinate_array(10,45, 20,45, 23,48, 20,51, 10,51)),0.005,2,1) as TGEOM
  *        From Dual
  *    )
  *    select a.TGeom.ST_GTYPE() as gtype,
  *           a.TGeom.ST_GeometryType() as Geometrytype
  *      From Geometries a;
  *
  *    GTYPE GEOMETRYTYPE
  *    ----- ----------------
  *        1 ST_POINT
  *        2 ST_LINESTRING
  *        3 ST_POLYGON
  *        3 ST_CURVEPOLYGON
  *        2 ST_COMPOUNDCURVE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_GeometryType
           Return VarChar2 Deterministic,

  /****m* T_GEOMETRY/ST_NumGeometries
  *  NAME
  *    ST_NumGeometries -- Returns number of top level geometry elements in underlying mdsys.sdo_geometry.
  *  SYNOPSIS
  *    Member Function ST_NumGeometries()
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    This function is a wrapper over MdSys.SDO_Util.getNumElem().
  *    Returns number of geometry elements (eg LineString in MultiLineString) that describe the underlying mdsys.sdo_geometry.
  *  NOTES
  *    Is an implementation of OGC ST_NumGeometies method.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select a.tgeom.ST_NumGeometries() as numGeometries
  *      from data a;
  *
  *    NUMGEOMETRIES
  *    -------------
  *                2
  *  RESULT
  *    number of geometries (Integer) -- For example, if Point(2001), returns 1.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Aug 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumGeometries
           Return integer Deterministic,

  /****m* T_GEOMETRY/ST_NumVertices
  *  NAME
  *    ST_NumVertices -- Returns number of vertices (coordinates) in underlying mdsys.sdo_geometry.
  *  SYNOPSIS
  *    Member Function ST_NumVertices()
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    This function is a wrapper over MdSys.SDO_Util.GetNumVertices(). Returns number of vertices (coordinates) that describe the underlying mdsys.sdo_geometry.
  *  EXAMPLE
  *    With Geometries As (
  *      Select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null),0.005,3,1) as TPolygon
  *       From Dual
  *    )
  *    select a.TPolygon.ST_NumVertices() as numVertices
  *      from GEOMETRIES a;
  *
  *    NUMVERTICES
  *    -----------
  *             15
  *  RESULT
  *    number of vertices (Integer) -- For example, if Point(2001), returns 1.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumVertices
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_NumPoints
  *  NAME
  *    ST_NumPoints -- Returns number of points (coordinates) in underlying mdsys.sdo_geometry.
  *  SYNOPSIS
  *    Member Function ST_NumPoints()
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    This function is the same as ST_NumVertices.
  *    It is implemented using the MdSys.SDO_Util.GetNumVertices() function.
  *    The function returns number of points (coordinates) that describe the underlying mdsys.sdo_geometry.
  *  NOTES
  *    Is an implementation of OGC ST_NumPoints method.
  *  EXAMPLE
  *    With Geometries As (
  *      Select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null),0.005,3,1) as TPolygon
  *       From Dual
  *    )
  *    select a.TPolygon.ST_NumPoints() as NumPoints
  *      from GEOMETRIES a;
  *    NUMPOINTS
  *    ---------
  *           15
  *  RESULT
  *    number of points (Integer) -- For example, if Point(2001), returns 1.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumPoints
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_NumElements
  *  NAME
  *    ST_NumELems -- Returns number of top level elements of the underlying mdsys.sdo_geometry.
  *  SYNOPSIS
  *    Member Function ST_NumElements()
  *             Return Number Deterministic
  *  DESCRIPTION
  *    Wrapper over SDO_UTIL.GETNUMELEM().
  *  EXAMPLE
  *    With GEOMETRIES As (
  *      Select T_GEOMETRY(
  *               mdsys.sdo_geometry(2007,NULL,NULL,mdsys.sdo_elem_info_array (1,1005,2, 1,2,1, 7,2,2,13,1003,3),
  *                                 mdsys.sdo_ordinate_array (10,128, 10,125, 20,125, 20,128, 15,130, 10,128, 0,0, 10,10)),0.005,3,1) as TGEOM
  *        From Dual Union All
  *      Select T_GEOMETRY(
  *               mdsys.sdo_geometry(2002,NULL,NULL,mdsys.sdo_elem_info_array (1,4,3, 1,2,1, 3,2,2, 7,2,1),
  *                                  mdsys.sdo_ordinate_array (10,45, 20,45, 23,48, 20,51, 10,51)),0.005,3,1) as TGEOM
  *       From Dual
  *    )
  *    Select a.TGEOM.ST_NumElements() as NumElements
  *      From GEOMETRIES a;
  *
  *    NUMELEM
  *    -------
  *          2
  *          1
  *  RESULT
  *    Required Element Count (Integer)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2006 - Original coding in GEOM package.
  *    Simon Greener - Jan 2013 - Port to T_GEOMETRY object.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumElements
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_NumSubElements
  *  NAME
  *    ST_NumSubElements -- Interprets underlying mdsys.sdo_geometry's SDO_ELEM_INFO array returning either total count of elements or just underlying sub-elements.
  *  SYNOPSIS
  *    Member Function ST_NumSubElements(p_subArcs in integer default 0)
  *             Return Number Deterministic
  *  DESCRIPTION
  *    If a geometry is coded with an SDO_ELEM_INFO_ARRAY this function will examine the triplets that describe
  *    each element and returns one of counts depending on the input parameter.
  *    If the input parameter is 0 all elements are counted: For example is a single polygon has a single outer ring (1),
  *    but that ring is coded with vertex-connected and circular-arc segments (2), then 1 + 2 =3 is returned.
  *    If 1 is the supplied input only the number of sub-elements that describe the outer ring are counted and returned.
  *  EXAMPLE
  *    With geometries as (
  *      select t_geometry(sdo_geometry(2003,null,null,
  *                                     sdo_elem_info_array (1,1005,2, 1,2,1, 7,2,2),
  *                                     sdo_ordinate_array (10,128, 10,125, 20,125, 20,128, 15,130, 10,128)),
  *                        0.005,3,1) as tgeom
  *        from dual
  *      union all
  *      select t_geometry(sdo_geometry(2002,null,null,
  *                                     sdo_elem_info_array (1,4,3, 1,2,1, 3,2,2, 7,2,1),
  *                                     sdo_ordinate_array (10,45, 20,45, 23,48, 20,51, 10,51)),
  *                        0.005,3,1) as tgeom
  *        from dual
  *    )
  *    select a.tgeom.ST_GType() as gType,
  *           a.tgeom.ST_NumSubElements(0) as allElems,
  *           a.tgeom.ST_NumSubElements(1) as lowElems,
  *           a.tgeom.ST_NumSubElements(0) - a.tgeom.ST_NumSubElements(1) as TopElems
  *      from geometries a;
  *
  *         GTYPE   ALLELEMS   LOWELEMS   TOPELEMS
  *    ---------- ---------- ---------- ----------
  *             3          3          2          1
  *             2          4          3          1
  *
  *  RESULT
  *    Required Element Count (Integer)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2006 - Original coding in GEOM package.
  *    Simon Greener - Jan 2013 - Port to T_GEOMETRY object.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumSubElements (p_subArcs in integer default 0)
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_ElementTypeAt
  *  NAME
  *    ST_ElementTypeAt -- Element_Type value in Sdo_Elem_Info triplet index.
  *  SYNOPSIS
  *    Member Function ST_ElementTypeAt
  *           Return &&INSTALL_SCHEMA..T_ElemInfo
  *  DESCRIPTION
  *    If a geometry is coded with an SDO_ELEM_INFO_ARRAY this function will extract the triplet at index p_element,
  *    and return the element type (etype) stored in that triplet.
  *    An T_ElemInfo object is:
  *      CREATE TYPE &&INSTALL_SCHEMA..T_ElemInfo AS OBJECT (
  *        offset           Number,
  *        etype            Number,  <--- This is returned.
  *        interpretation   Number
  *      );
  *  EXAMPLE
  *    with data as (
  *      Select T_Geometry(
  *               SDO_GEOMETRY(2007,NULL,NULL,
  *                   SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2,
  *                                      11,2005,2, 11,2,1, 15,2,2,
  *                                      21,1005,2, 21,2,1, 25,2,2),
  *                   SDO_ORDINATE_ARRAY(  6,10, 10,1, 14,10, 10,14,  6,10,
  *                                       13,10, 10,2,  7,10, 10,13, 13,10,
  *                                     106,110, 110,101, 114,110, 110,114,106,110)
  *               ),0.005,2,1) as tgeom
  *      from dual
  *    )
  *    select a.tGeom.geom.sdo_elem_info           as elem_info,
  *           a.tGeom.ST_NumElementInfo()          as numElemInfos,
  *           t.IntValue                           as element_id,
  *           a.tgeom.ST_ElementTypeAt(t.IntValue) as elem_type_at
  *      from data a,
  *           TABLE(tools.generate_series(1,a.tgeom.ST_NumSubElements(),1)) t;
  *
  *    ELEM_INFO                                                                                 NUMELEMINFOS ELEMENT_ID ELEM_TYPE_AT
  *    ----------------------------------------------------------------------------------------- ------------ ---------- ------------
  *    SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2,21,1005,2,21,2,1,25,2,2)            9          1         1005
  *    SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2,21,1005,2,21,2,1,25,2,2)            9          2            2
  *    SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2,21,1005,2,21,2,1,25,2,2)            9          3            2
  *    SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2,21,1005,2,21,2,1,25,2,2)            9          4         2005
  *    SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2,21,1005,2,21,2,1,25,2,2)            9          5            2
  *    SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2,21,1005,2,21,2,1,25,2,2)            9          6            2
  *    SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2,21,1005,2,21,2,1,25,2,2)            9          7         1005
  *    SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2,21,1005,2,21,2,1,25,2,2)            9          8            2
  *    SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2,21,1005,2,21,2,1,25,2,2)            9          9            2
  *
  *     9 rows selected
  *
  *  RESULT
  *    Element Type (Integer)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2006 - Original coding in GEOM package.
  *    Simon Greener - Jan 2013 - Port to T_GEOMETRY object.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_ElementTypeAt (p_element in integer)
           Return integer Deterministic,

  /****m* T_GEOMETRY/ST_NumInteriorRing
  *  NAME
  *    ST_NumInteriorRing -- Returns number of interior rings in underlying polygon mdsys.sdo_geometry.
  *  SYNOPSIS
  *    Member Function ST_NumInteriorRing()
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    This function computes the number of interior rings by processing the sdo_elem_info array in the underlying sdo_geometry object.
  *    Returns number of inner ring elements of a polygon or multipolygon.
  *  NOTES
  *    Is an implementation of OGC ST_NumInteriorRing method.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select a.tgeom.ST_NumInteriorRing() as NumInteriorRings
  *      from data a;
  *
  *    NUMINTERIORRINGS
  *    ----------------
  *                   2
  *  RESULT
  *    Number of interior rings (Integer) -- For example, if Polygon with 1 exterior and 1 interior ring then 1 is returned.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Aug 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumInteriorRing
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_NumSegments
  *  NAME
  *    ST_NumSegments -- Returns number of two-point segments in the underlying linear or polygon geometry.
  *  SYNOPSIS
  *    Member Function ST_NumSegments()
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Returns number of two-point segments of a polygon or multipolygon.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('MULTILINESTRING((-1 -1, 0 -1),(0 0,10 0,10 5,10 10,5 10,5 5))',null),0.005,3,1) as tgeom From Dual union all
  *      select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom From Dual union all
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GeometryType()    as gType,
  *           a.tGeom.ST_NumGeometries()   as numGeoms,
  *           a.tGeom.ST_NumInteriorRing() as numIRings,
  *           a.tgeom.ST_NumPoints()       as numPoints,
  *           a.tgeom.ST_NumSegments()     as NumSegments
  *      from data a;
  *
  *    GTYPE               NUMGEOMS  NUMIRINGS  NUMPOINTS NUMSEGMENTS
  *    ------------------- -------- ---------- ---------- -----------
  *    ST_LINESTRING              1          0          6           5
  *    ST_MULTILINESTRING         2          0          8           6
  *    ST_POLYGON                 1          1         10           8
  *    ST_MULTIPOLYGON            2          0         10           8
  *    ST_MULTIPOLYGON            2          2         20          16
  *  RESULT
  *    Number of 2-point segments (Integer) -- For example, if LINESTRING has 6 vertices it has 5 segments.
  *  TODO
  *    Support for CircularString elements.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Sept 2015 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumSegments
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_isOrientedPoint
  *  NAME
  *    ST_isOrientedPoint -- A function that tests whether underlying mdsys.sdo_geometry is an oriented point.
  *  SYNOPSIS
  *    Member Function ST_isOrientedPoint
  *             Return integer Deterministic,
  *  DESCRIPTION
  *    Examines underlying point geometry to see if contains oriented points.
  *    Single Oriented Point:
  *      Sdo_Elem_Info = (1,1,1, 3,1,0), SDO_ORDINATE_ARRAY(12,14, 0.3,0.2)));
  *      The Final 1,0 In 3,1,0 Indicates That This Is An Oriented Point.
  *    Multi Oriented Point:
  *      Sdo_Elem_Info_Array(1,1,1, 3,1,0, 5,1,1, 7,1,0), Sdo_Ordinate_Array(12,14, 0.3,0.2, 12,10, -1,-1)));
  *  RESULT
  *    BOOLEAN (Integer) -- 1 if has orientes points.
  *  EXAMPLE
  *    with data as (
  *      select 1 as geomId, T_GEOMETRY(sdo_geometry(2001,null,null,sdo_elem_info_array(1,1,1, 3,1,0), sdo_ordinate_array(12,14, 0.3,0.2)),0.005,2,1) as tgeom
  *        From Dual union all
  *      select 2 as geomId, t_geometry(sdo_geometry('LINESTRING (100.0 0.0, 400.0 0.0)',NULL),0.005,2,1) as tgeom
  *        From Dual Union All
  *      select 3 as geomId, T_GEOMETRY(sdo_geometry(2005,null,null,Sdo_Elem_Info_Array(1,1,1, 3,1,0, 5,1,1, 7,1,0), Sdo_Ordinate_Array(12,14, 0.3,0.2, 12,10, -1,-1)),0.005,2,1) as tgeom
  *        From Dual Union All
  *      select 4 as geomId, T_GEOMETRY(sdo_geometry(2005,null,null,Sdo_Elem_Info_Array(1,1,1, 3,1,0, 5,1,1, 7,1,0, 9,1,1), Sdo_Ordinate_Array(12,14, 0.3,0.2, 12,10, -1,-1, -10,-10)),0.005,2,1) as tgeom
  *        From Dual
  *    )
  *    select a.geomId, a.tgeom.ST_GeometryType() as geomType, a.tgeom.ST_isOrientedPoint() as isOrientedPoint
  *      from data a;
  *
  *    GEOMID GEOMTYPE      ISORIENTEDPOINT
  *    ------ ------------- ---------------
  *         1 ST_POINT                    1
  *         2 ST_LINESTRING               0
  *         3 ST_MULTIPOINT               1
  *         4 ST_MULTIPOINT               1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Dec 2008 - Original coding within GEOM package.
  *    Simon Greener - Jan 2013 - Recoded for T_GEOMETRY.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isOrientedPoint
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_hasCircularArcs
  *  NAME
  *    ST_hasCircularArcs -- A function that tests whether underlying mdsys.sdo_geometry contains circular arcs.
  *  SYNOPSIS
  *    Member Function ST_hasCircularArcs
  *             Return integer Deterministic,
  *  DESCRIPTION
  *    Examines sdo_elem_info to see if contains ETYPE/Interpretation that describes a circular arc, or even a full circle.
  *  RESULT
  *    BOOLEAN (Integer) -- 1 if has circular arcs.
  *  EXAMPLE
  *    with data as (
  *      select 1 as geomId, T_GEOMETRY(sdo_geometry(2002,null,null,sdo_elem_info_array(1,4,2,1,2,1,3,2,2),sdo_ordinate_array(0,0,10,0,20,10,30,0)),0.005,2,1) as tgeom
  *        From Dual union all
  *      select 2 as geomId, t_geometry(sdo_geometry('LINESTRING (100.0 0.0, 400.0 0.0)',NULL),0.005,2,1) as tgeom
  *        From Dual
  *    )
  *    select a.geomId, a.tgeom.ST_HasCircularArcs() as hasCircularArc
  *      from data a;
  *
  *    GEOMID HASCIRCULARARC
  *    ------ --------------
  *         1              1
  *         2              0
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Dec 2008 - Original coding within GEOM package.
  *    Simon Greener - Jan 2013 - Recoded for T_GEOMETRY.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_hasCircularArcs
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_inCircularArc
  *  NAME
  *    ST_inCircularArc -- A function that checks if the provided point is part of a circular arc.
  *  SYNOPSIS
  *    Member Function ST_inCircularArc
  *             Return integer Deterministic,
  *  DESCRIPTION
  *    Examines underlying geometry and checks to see if the provided point reference (id) is part of a circular arc or not.
  *    Returns position in circular arc:
  *      0 means not in a circular arc
  *      1 means is first point in circular arc
  *      2 means is second point in circular arc
  *      3 means is third point in circular arc
  *  RESULT
  *    BOOLEAN (integer) -- Returns position of point in circular arc (0 if not part of a circular arc)
  *  EXAMPLE
  *    with data as (
  *      select T_GEOMETRY(sdo_geometry(2002,null,null,sdo_elem_info_array(1,4,2,1,2,1,3,2,2),sdo_ordinate_array(0,0,10,0,20,10,30,0)),0.005,2,1) as tgeom
  *        From Dual
  *    )
  *    select a.tgeom.ST_InCircularArc(t.IntValue) as positionInCircularArc
  *      from data a,
  *           table(tools.generate_series(1,a.tgeom.ST_NumPoints(),1)) t
  *
  *    POSITIONINCIRCULARARC
  *    ---------------------
  *                        0
  *                        1
  *                        2
  *                        3
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_inCircularArc(p_point_number in integer)
           Return Integer,

  /****m* T_GEOMETRY/ST_NumRectangles
  *  NAME
  *    ST_NumRectangles -- A function that returns the number of optimized rectangles in the underlying (multi)polygon geometry.
  *  SYNOPSIS
  *    Member Function ST_NumRectangles
  *             Return integer Deterministic,
  *  DESCRIPTION
  *    Examines sdo_elem_info ETYPE/Interpretation elements to count the number of optimized rectangles it finds.
  *    eg SDO_ELEM_INFO_ARRAY(1,1003,3) ie the interpretation value of 3 means optimized rectangle.
  *  RESULT
  *    Count (integer) -- 0 if no optimized rectangles, n where n > 0 if optimized rectangles found.
  *  EXAMPLE
  *    with data as (
  *      select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0))',null),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(0,0,20,20)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3,5,2003,3),sdo_ordinate_array(0,0,20,20, 10,10,15,15)),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select a.tgeom.ST_NumRectangles() as numRectangles
  *      from data a;
  *
  *    NUMRECTANGLES
  *    -------------
  *                0
  *                1
  *                2
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jun 2011 - Original coding for GEOM package.
  *    Simon Greener - Jan 2013 - Recoded for T_GEOMETRY.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumRectangles
           Return integer deterministic,

  /****m* T_GEOMETRY/ST_hasRectangles
  *  NAME
  *    ST_hasRectangles -- A function that tests whether underlying mdsys.sdo_geometry contains optimized rectangles.
  *  SYNOPSIS
  *    Member Function ST_hasRectanglles
  *             Return integer Deterministic,
  *  DESCRIPTION
  *    Examines sdo_elem_info to see if contains ETYPE/Interpretation that describes an optimized rectangle.
  *    eg SDO_ELEM_INFO_ARRAY(1,1003,3) ie the interpretation value of 3 means optimized rectangle.
  *  RESULT
  *    BOOLEAN (Integer) -- 1 if has optimized rectangles.
  *  EXAMPLE
  *    with data as (
  *      select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0))',null),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(0,0,20,20)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3,5,2003,3),sdo_ordinate_array(0,0,20,20, 10,10,15,15)),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select a.tgeom.ST_HasRectangles() as numRectangles
  *      from data a;
  *
  *    HASRECTANGLES
  *    -------------
  *                0
  *                1
  *                1
  *  NOTES
  *    Calls ST_NumRectangles and returns 1 if num is > 0 or 0 otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jun 2011 - Original coding for GEOM package.
  *    Simon Greener - Jan 2013 - Recoded for T_GEOMETRY.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_hasRectangles
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_Round
  *  NAME
  *    ST_Round -- Rounds X,Y,Z and m (w) ordinates to passed in decimal digits of precision.
  *  SYNOPSIS
  *    Member Function ST_Round(p_dec_places_x in integer default null,
  *                             p_dec_places_y in integer default null,
  *                             p_dec_places_z in integer default null,
  *                             p_dec_places_m in integer default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Applies relevant decimal digits of precision value to ordinates of mdsys.sdo_geometry.
  *    For example:
  *      SELF.x := ROUND(SELF.x,p_dec_places_x);
  *  ARGUMENTS
  *    p_dec_places_x (integer) - value applied to x Ordinate.
  *    p_dec_places_y (integer) - value applied to y Ordinate.
  *    p_dec_places_z (integer) - value applied to z Ordinate.
  *    p_dec_places_m (integer) - value applied to m Ordinate.
  *  RESULT
  *    geometry (T_GEOMETRY)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Round(p_dec_places_x In integer default 8,
                           p_dec_places_y In integer Default null,
                           p_dec_places_z In integer Default 3,
                           p_dec_places_m In integer Default 3)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_NumRings
  *  NAME
  *    ST_NumRings -- Returns Number of Rings of specified type in a polygon/mutlipolygon.
  *  SYNOPSIS
  *    Member Function ST_NumRings (
  *                       p_ring_type in integer default 0
  *                    )
  *             Return integer Deterministic,
  *  DESCRIPTION
  *    A polygon can have a single outer ring with no inner rings (holes) or it can have holes.
  *    A multipolygon can have multiple outer rings each with/without inner rings.
  *    This method counts the number of rings of the desired type as defined by the input parameter.
  *  ARGUMENTS
  *    p_ring_type : integer : 0 - Count all (inner and outer) rings; 1 Count only outer rings; 2 - Count only inner rings.
  *  RESULT
  *    Number Of Rings (Integer)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Dec 2008 - Original coding for GEOM package.
  *    Simon Greener - Jan 2013 - Port to T_GEOMETRY object.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumRings (p_ring_type in integer default 0)
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_ElemInfo
  *  NAME
  *    ST_ElemInfo -- Returns underlying mdsys.sdo_geometry's SDO_ELEM_INFO array as a Set of T_ElemInfo objects.
  *  SYNOPSIS
  *    Member Function ST_ElemInfo
  *           Return &&INSTALL_SCHEMA..T_ElemInfoSet pipelined
  *  DESCRIPTION
  *    If a geometry is coded with an SDO_ELEM_INFO_ARRAY this function will extract the triplets that describe
  *    each element and returns them as a set of T_ELEM_INFO objects.
  *    The T_ElemInfo object is:
  *      CREATE TYPE &&INSTALL_SCHEMA..T_ElemInfo AS OBJECT (
  *        offset           Number,
  *        etype            Number,
  *        interpretation   Number
  *      );
  *  RESULT
  *    Set of T_ElemInfo objects (Integer)
  *  NOTES
  *    Function is pipelined
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2006 - Original coding in GEOM package.
  *    Simon Greener - Jan 2013 - Port to T_GEOMETRY object.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_ElemInfo
           Return &&INSTALL_SCHEMA..T_ElemInfoSet pipelined,

  /****m* T_GEOMETRY/ST_NumElementInfo
  *  NAME
  *    ST_NumElementInfo -- Returns number of SDO_ELEM_INFO triplets that describe geometry.
  *  SYNOPSIS
  *    Member Function ST_NumElementInfo
  *             Return Integer deterministic
  *  DESCRIPTION
  *    If a geometry is coded with an SDO_ELEM_INFO_ARRAY this function will count the number of triplets that describe the geometry.
  *    For Example:
  *      1. sdo_geometry(2002,null,null,sdo_element_info_array(1,2,1),sdo_ordinate_array(0,0,1,1)) is described by 1 triplet.
  *      2. sdo_geometry(2003,null,null,sdo_element_info_array(1,1003,1,9,2003,1),sdo_ordinate_array(....)) is described by 2 triplets.
  *  EXAMPLE
  *    With GEOMETRIES As (
  *      Select T_GEOMETRY(sdo_geometry(2007,NULL,NULL,sdo_elem_info_array (1,1005,2, 1,2,1, 7,2,2,13,1003,3),
  *                                     sdo_ordinate_array (10,128, 10,125, 20,125, 20,128, 15,130, 10,128, 0,0, 10,10)),0.005,3,1) as TGEOM
  *        From Dual Union All
  *      Select T_GEOMETRY(sdo_geometry(2002,NULL,NULL,sdo_elem_info_array (1,4,3, 1,2,1, 3,2,2, 7,2,1),
  *                                     sdo_ordinate_array (10,45, 20,45, 23,48, 20,51, 10,51)),0.005,3,1) as TGEOM
  *       From Dual
  *    )
  *    Select a.TGEOM.ST_NumElementInfo() as NumElementInfoTriplets
  *      From GEOMETRIES a;
  *  RESULT
  *    Number of sdo_elem_info triplets (Integer)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2006 - Original coding in GEOM package.
  *    Simon Greener - Jan 2013 - Port to T_GEOMETRY object.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_NumElementInfo
           Return Integer deterministic,

  /****m* T_GEOMETRY/ST_Dump
  *  NAME
  *    ST_Dump -- Extracts all parts of a multipart linestring, polygon, or collection geometry.
  *  SYNOPSIS
  *    Member Function ST_Dump(p_subElements IN integer Default 0)
  *             Return &&INSTALL_SCHEMA..T_Geometries Pipelined
  *  DESCRIPTION
  *    Extracts all parts of an underlying geometry object.
  *    If p_subElemets is set to TRUE (1), all subElements of a complex element
  *    (eg compound outer ring of polygon) are extracted and returned as mdsys.sdo_geometry objects.
  *    Individual sdo_gemetry objects are returned in a T_GEOMETRY_ROW structure that has three fields: GID, GEOMETRY and TOLERANCE.
  *    GID values are generated in the order the elements appears in the sdo_elem_info structure.
  *  EXAMPLE
  *    with GEOMETRIES as (
  *      select t_geometry(
  *               mdsys.sdo_geometry(2007,null,null,
  *                            sdo_elem_info_array( 1,1003,1,11,2003,1,21,2003,1,
  *                                                31,1005,2,31,2,1,37,2,2,43,1003,3),
  *                            sdo_ordinate_array(0,0, 20,0, 20,20, 0,20, 0,0, 10,10, 10,11, 11,11, 11,10, 10,10, 5,5, 5,7, 7,7, 7,5, 5,5,
  *                                               110,128, 110,125, 120,125, 120,128, 115,130, 110,128,112,0, 113,10))
  *                      ,0.005,3,1) as tPolygon
  *        From dual
  *    )
  *    GID GEOMETRY                                                                                                            TOLERANCE
  *    --- ------------------------------------------------------------------------------------------------------------------- ---------
  *      1 mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,20,0,20,20,0,20,0,0,10,10))          0.005
  *      2 mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(10,10,10,11,11,11,11,10,10,10,5,5))      0.005
  *      3 mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(5,5,5,7,7,7,7,5,5,5))                    0.005
  *      1 mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(110,128,110,125,120,125,120,128))        0.005
  *      2 mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(120,128,115,130,110,128))                0.005
  *      1 mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,3),SDO_ORDINATE_ARRAY(112,0,113,10))                           0.005
  *
  *   6 rows selected
  *  RESULT
  *    Geometry (T_GEOMETRY_ROW) -- Table (T_GEOMETRIES) of T_GEOMETRY_ROW objects.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Dump( p_subElements IN integer Default 0)
           Return &&INSTALL_SCHEMA..T_Geometries Pipelined,

  /****m* T_GEOMETRY/ST_ExteriorRing
  *  NAME
  *    ST_ExteriorRing -- Returns All Outer Rings of a polygon or multipolygon.
  *  SYNOPSIS
  *    Member Function ST_ExteriorRing()
  *             Return T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    This function extracts all the exterior (outer) rings of a polygon/multipolygon and returns them as a T_GEOMETRY object.
  *  NOTES
  *    Is an implementation of OGC ST_ExteriorRing method.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select a.tgeom.ST_ExteriorRing().ST_AsText() as ExteriorRing
  *      from data a;
  *
  *    EXTERIORRING
  *    -----------------------------------------------------------------------------------------------
  *    MULTIPOLYGON (((0 0, 20 0, 20 20, 0 20, 0 0)), ((100 100, 200 100, 200 200, 100 200, 100 100)))
  *  RESULT
  *    Exterior ring(s) (T_GEOMETRY) -- For example, if a single Polygon with 1 exterior and 1 interior ring is provided, then a single polygon with a single exterior ring is returned.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Aug 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_ExteriorRing
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_Boundary
  *  NAME
  *    ST_Boundary -- Returns All Outer Rings of a polygon or multipolygon as a single linestring/multilinestring.
  *  SYNOPSIS
  *    Member Function ST_Boundary()
  *             Return T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    This function extracts all the exterior (outer) rings of a polygon/multipolygon and returns them in a T_GEOMETRY object as a linestring.
  *  NOTES
  *    Is an implementation of OGC ST_Boundary method.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select a.tgeom.ST_Boundary().ST_AsText() as Boundary
  *      from data a;
  *
  *    BOUNDARY
  *    ----------------------------------------------------------------------------------------------
  *    MULTILINESTRING ((0 0, 20 0, 20 20, 0 20, 0 0), (100 100, 200 100, 200 200, 100 200, 100 100))
  *  RESULT
  *    Exterior ring(s) (T_GEOMETRY) -- For example, if a single Polygon with 1 exterior and 1 interior ring is provided, then a single polygon with a single exterior ring is returned.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Aug 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Boundary
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_Length
  *  NAME
  *    ST_Length -- Returns length of underlying linestring or polygon (rings) sdo_geometry
  *  SYNOPSIS
  *    Member Function ST_Length (
  *                       p_unit  in varchar2 default NULL,
  *                       p_round in integer  default 0 )
  *                    )
  *             Return Number Deterministic
  *  ARGUMENTS
  *    p_unit (varchar2) - Oracle Unit of Measure eg unit=M.
  *    p_round (integer) - Whether to round result using PRECISION of T_GEOMETRY
  *  DESCRIPTION
  *    This function computes length of linestring or polygon boundary of underlying sdo_geometry.
  *    Result is in the distance units of the SDO_SRID, or in p_units where supplied.
  *    Result is rounded to SELF.PRECISION if p_round is true (1), otherwise false(0) no rounding.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual union all
  *      select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',28356),0.0005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_Length(case when a.tGeom.ST_Srid() = 28356 then 'unit=CENTIMETER' else null end,0) as length,
  *           a.tgeom.ST_Length(case when a.tGeom.ST_Srid() = 28356 then 'unit=CENTIMETER' else null end,1) as round_length
  *      from data a;
  *
  *         LENGTH ROUND_LENGTH
  *    ----------- ------------
  *             30           30
  *    30.44595368       30.446
  *             30           30
  *           8400         8400
  *  NOTES
  *    Length of 3D linestrings and polygons is an Enterprise Spatial feature.
  *    The function detects if licensed and computes length using sdo_geom.sdo_length.
  *    If the database is not licensed, the function computes 3D length itself (slower).
  *  RESULT
  *    length (Number) -- Length in SRID unit of measure or in supplied units (p_unit) possibly rounded to SELF.Precision
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Length (p_unit  in varchar2 default null,
                             p_round in integer default 0 )
           Return Number Deterministic,

  /****m* T_GEOMETRY/ST_Area
  *  NAME
  *    ST_Area -- Returns area of underlying polygon sdo_geometry
  *  SYNOPSIS
  *    Member Function ST_Area (
  *                       p_unit  in varchar2 default NULL,
  *                       p_round in integer  default 0 )
  *                    )
  *             Return Number Deterministic
  *  ARGUMENTS
  *    p_unit (varchar2) - Oracle Unit of Measure eg unit=M.
  *    p_round (integer) - Whether to round result using PRECISION of T_GEOMETRY
  *  DESCRIPTION
  *    This function computes the area of underlying sdo_geometry polygon.
  *    Result is expressed in the units of the SDO_SRID, or in p_units where supplied.
  *    Result is rounded to SELF.PRECISION if p_round is true (1), otherwise false(0) no rounding.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry(3003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual union all
  *      select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',28356),0.0005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_Area(case when a.tGeom.ST_Srid() = 28356 then 'unit=SQ_KM' else null end,0) as area_km,
  *           a.tgeom.ST_Area(case when a.tGeom.ST_Srid() = 28356 then 'unit=SQ_KM' else null end,1) as round_area_km
  *      from data a;
  *
  *        AREA_KM ROUND_AREA_KM
  *    ----------- -------------
  *    78.30229882        78.302
  *       0.000399             0
  *  RESULT
  *    area (Number) -- Area in SRID unit of measure or in supplied units (p_unit) possibly rounded to SELF.Precision
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Area   (p_unit in varchar2 default null,
                             p_round in integer default 0 )
           Return Number Deterministic,

  /****m* T_GEOMETRY/ST_Distance
  *  NAME
  *    ST_Distance -- Returns distance from current T_geometry (SELF) to supplied T_GEOMETRY.
  *  SYNOPSIS
  *    Member Function ST_Distance(p_geom  in &&INSTALL_SCHEMA..T_GEOMETRY,
  *                                p_unit  in varchar2 default NULL,
  *                                p_round in integer  default 0 )
  *             Return Number Deterministic
  *  ARGUMENTS
  *    p_geom  (T_GEOMETRY) - A T_GEOMETRY to which a distance is calculated.
  *    p_unit    (VarChar2) - Oracle Unit of Measure eg unit=M.
  *    p_round        (BIT) - Whether to round result using PRECISION of T_GEOMETRY
  *  DESCRIPTION
  *    This function computes a distance from the current object (SELF) to the supplied T_Geometry.
  *    Result is in the distance units of the SDO_SRID, or in p_units where supplied.
  *    Result is rounded to SELF.PRECISION if p_round is true (1), otherwise false(0) no rounding.
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('POINT(0 0)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3001,NULL,SDO_POINT_TYPE(0,0,0),null,null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,1, 10,0,2, 10,5,3, 10,10,4, 5,10,5, 5,5,6, 0,0,0)),0.005,3,1) as tgeom From Dual union all
  *      select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',28356),0.0005,3,1) as tgeom From Dual
  *    )
  *    select a.tGeom.ST_GeometryType() as geometryType,
  *           a.tgeom.ST_Srid()         as srid,
  *           case when a.tGeom.ST_Srid() = 28356 then 'CM' else 'M' end as unit,
  *           a.tgeom.ST_Distance(sdo_geometry('POINT(51 41)',a.tGeom.ST_Srid()),
  *                               case when a.tGeom.ST_Srid() = 28356 then 'unit=CM' else null end,
  *                               0) as distance,
  *           a.tgeom.ST_Distance(sdo_geometry('POINT(51 41)',a.tGeom.ST_Srid()),
  *                               case when a.tGeom.ST_Srid() = 28356 then 'unit=CM' else null end,
  *                               1) as round_distance
  *      from data a;
  *
  *    GEOMETRYTYPE   SRID UNIT     DISTANCE ROUND_DISTANCE
  *    -------------- ------ ---- ------------ --------------
  *    ST_POINT       (NULL)    M   65.4369926         65.437
  *    ST_POINT       (NULL)    M   65.4369926         65.437
  *    ST_LINESTRING  (NULL)    M   51.4003891           51.4
  *    ST_LINESTRING  (NULL)    M   51.4003891           51.4
  *    ST_POLYGON     (NULL)    M   51.4003891           51.4
  *    ST_POLYGON      28356   CM  3744.329045       3744.329
  *
  *     6 rows selected
  *
  *  RESULT
  *    distance (Number) -- Distance in SRID unit of measure or in supplied units (p_unit)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Distance (p_geom in mdsys.sdo_geometry,
                               p_unit  in varchar2 default null,
                               p_round in integer  default 0 )
           Return Number Deterministic,

  /****m* T_GEOMETRY/ST_Relate
   *  NAME
   *    ST_Relate - Determines spatial relations between two geometry instances.
   *  SYNOPSIS
   *    Member Function ST_Relate (
   *               p_geom      sdo_geometry,
   *               p_determine varchar2 default 'DETERMINE'
   *             )
   *      Return varchar2 deterministic
   *  DESCRIPTION
   *    Compares the first geometry against the second using SDO_GEOM.RELATE to discover if the two geometry objects have the required relationship.
   *    The relationhip names (from the Oracle documentation are):
   *
   *      DISJOINT           : The boundaries and interiors do not intersect.
   *      TOUCH              : The boundaries intersect but the interiors do not intersect.
   *      OVERLAPBDYDISJOINT : The interior of one object intersects the boundary and interior of the other object, but the two boundaries do not intersect.
   *                           This relationship occurs, for example, when a line originates outside a polygon and ends inside that polygon.
   *      OVERLAPBDYINTERSECT: The boundaries and interiors of the two objects intersect.
   *      EQUAL              : The two objects have the same boundary and interior.
   *      CONTAINS           : The interior and boundary of one object is completely contained in the interior of the other object.
   *      COVERS             : The interior of one object is completely contained in the interior or the boundary of the other object and their boundaries intersect.
   *      INSIDE             : The opposite of CONTAINS. A INSIDE B implies B CONTAINS A.
   *      COVEREDBY          : The opposite of COVERS. A COVEREDBY B implies B COVERS A.
   *      ON                 : The interior and boundary of one object is on the boundary of the other object.
   *                           This relationship occurs, for example, when a line is on the boundary of a polygon.
   *      ANYINTERACT        : The objects are non-disjoint.
   *
   *    If one does not know what relationships might exist, set the parameter p_determine to the value DETERMINE to discover what relationships exist.
   *  ARGUMENTS
   *    p_geom   (sdo_geometry) - Non-null geometry instance.
   *    p_determine  (varchar2) - One of the 9 Topological Relationship names (see above):
   *  RESULT
   *    Relationships (varchar) - Result of SDO_GEOM.RELATE()
   *  NOTES
   *    Uses MDSYS.SDO_GEOM.RELATE if Oracle database version is 12c or above,
   *    or if the customer is licensed for the Spatial object before 12c.
   *  ERRORS
   *    With throw exception if the user is not licensed to call MDSYS.SDO_GEOM.RELATE.
   *    -20102  MDSYS.SDO_GEOM.RELATE only supported for Locator users from 12c onwards.';
   *  EXAMPLE
   *    Select t_geometry(sdo_geometry('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',NULL),0.005,2,1)
   *             .ST_Relate ( sdo_geometry('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',NULL),
   *             'DETERMINE'
   *           ) as relations
   *      from dual;
   *
   *    RELATIONS
   *    -------------------
   *    OVERLAPBDYINTERSECT
   *
   *    Select t_geometry(  sdo_geometry('LINESTRING (100.0 0.0, 400.0 0.0)',NULL),0.005,2,1)
   *             .ST_Relate(sdo_geometry('LINESTRING (90.0 0.0, 100.0 0.0)',NULL),
   *             'DETERMINE'
   *           ) as relations
   *      from dual;
   *
   *    RELATIONS
   *    ---------
   *    TOUCH
   *
   *    Select t_geometry(  sdo_geometry('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',NULL),0.0005,2,1)
   *             .ST_Relate(sdo_geometry('POINT (250 150)',NULL),
   *             'DETERMINE'
   *           ) as relations
   *      from dual;
   *
   *    RELATIONS
   *    ---------
   *    CONTAINS
   *
   *    -- Example using different precision values and a specific "question": Are they equal?
   *    Select t_geometry(  sdo_geometry('POINT (250.001 150)'    ,NULL),DECODE(t.IntValue,2,0.005,3,0.0005),t.IntValue,1)
   *             .ST_Relate(sdo_geometry('POINT (250     150.002)',NULL),
   *             'EQUAL'
   *           ) as relations
   *      from table(tools.GENERATE_SERIES(2,3,1)) t
   *
   *    RELATIONS
   *    ---------
   *    EQUAL
   *    FALSE
   *  AUTHOR
   *    Simon Greener
   *  HISTORY
   *    Simon Greener - January 2018 - Original coding.
   *  COPYRIGHT
   *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Relate(p_geom      in mdsys.sdo_geometry,
                            p_determine in varchar2 default 'DETERMINE')
           Return varchar2 Deterministic,

  -- Editing and Processing Methods

  /****m* T_GEOMETRY/ST_SwapOrdinates
   *  NAME
   *    ST_SwapOrdinates - Allows for swapping ordinate pairs in a geometry.
   *  SYNOPSIS
   *    Member Function ST_SwapOrdinates (p_pair in varchar2 default 'XY' )
   *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
   *  DESCRIPTION
   *    Sometimes the ordinates of a geometry can be swapped such as latitude for X and Longitude for Y when it should be reversed.
   *    This function allows for the swapping of pairs of ordinates controlled by the p_pair parameter.
   *    The following pairs can be swapped in one call:
   *      * XY, XZ, XM, YZ, YM, ZM
   *  ARGUMENTS
   *    p_pair (varchar2) - One of XY, XZ, XM, YZ, YM, ZM
   *  RESULT
   *    Changed geometry (sdo_geometry) - T_Geometry whose internal geom has had its ordinates swapped.
   *  EXAMPLE
   *    select T_GEOMETRY(sdo_geometry(3001,null,sdo_point_type(1,20,30),null,null),0.005).ST_SwapOrdinates('XY').geom as Geom
   *      from dual;
   *
   *    GEOM
   *    ---------------------------------------------------------
   *    SDO_GEOMETRY(3001,null,SDO_POINT_TYPE(20,1,30),null,null)
   *
   *    select T_GEOMETRY(sdo_geometry(3001,null,sdo_point_type(1,20,30),null,null),0.005).ST_SwapOrdinates('XZ').geom as Geom
   *      from dual;
   *
   *    GEOM
   *    ---------------------------------------------------------
   *    SDO_GEOMETRY(3001,null,SDO_POINT_TYPE(30,20,1),null,null)
   *
   *    select T_GEOMETRY(sdo_geometry(3001,null,sdo_point_type(1,20,30),null,null),0.005).ST_SwapOrdinates('YZ').geom as Geom
   *      from dual;
   *
   *    GEOM
   *    ---------------------------------------------------------
   *    SDO_GEOMETRY(3001,null,SDO_POINT_TYPE(1,30,20),null,null)
   *
   *    select T_GEOMETRY(sdo_geometry('LINESTRING (-32 147, -33 180)'),0.005).ST_SwapOrdinates('XY').geom as Geom
   *      from dual;
   *
   *    GEOM
   *    --------------------------------------------------------------------------------------------
   *    SDO_GEOMETRY(2002,null,null,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147,-32, 180,-33))
   *
   *    select T_GEOMETRY(sdo_geometry('LINESTRING (0 50, 10 50, 10 55, 10 60, 20 50)'),0.005).ST_SwapOrdinates('XY').geom as Geom
   *      from dual;
   *
   *    GEOM
   *    ------------------------------------------------------------------------------------------------------------
   *    SDO_GEOMETRY(2002,null,null,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(50,0, 50,10, 55,10, 60,10, 50,20))
   *
   *    select T_GEOMETRY(
   *             sdo_geometry(3002,null,null,
   *                          sdo_elem_info_array(1,2,1),
   *                          sdo_ordinate_array(0,50,105, 10,50,110, 10,55,115, 10,60,120, 20,50,125)
   *                         ),
   *             0.005)
   *             .ST_SwapOrdinates('XZ').geom as Geom
   *      from dual;
   *
   *    GEOM
   *    --------------------------------------------------------------------------------------------------------------------------------
   *    SDO_GEOMETRY(3002,null,null,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(105,50,0, 110,50,10, 115,55,10, 120,60,10, 125,50,20))
   *
   *    select T_GEOMETRY(
   *             sdo_geometry(3002,null,SDO_POINT_TYPE(1,20,30),
   *                          sdo_elem_info_array(1,2,1),
   *                          sdo_ordinate_array(0,50,105, 10,50,110, 10,55,115, 10,60,120, 20,50,125)
   *                         ),
   *             0.005)
   *             .ST_SwapOrdinates('YZ').geom as Geom
   *      from dual;
   *
   *    GEOM
   *    ---------------------------------------------------------------------------------------------------------------------------------------------------
   *    SDO_GEOMETRY(3002,null,SDO_POINT_TYPE(1,30,20),SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,105,50, 10,110,50, 10,115,55, 10,120,60, 20,125,50))
   *
   *    select T_GEOMETRY(
   *             sdo_geometry(3302,null,null,
   *                          sdo_elem_info_array(1,2,1),
   *                          sdo_ordinate_array(5,10,0, 20,5,NULL, 35,10,NULL, 55,10,100)
   *                         ),
   *             0.005)
   *             .ST_SwapOrdinates('XM').geom as Geom
   *      from dual;
   *
   *    GEOM
   *    --------------------------------------------------------------------------------------------------------------------
   *    SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,10,5, null,5,20, null,10,35, 100,10,55))
   *
   *    select T_GEOMETRY(
   *             sdo_geometry(4402,null,null,
   *                          sdo_elem_info_array(1,2,1),
   *                          sdo_ordinate_array(5,10,500,0, 20,5,501,NULL, 35,10,502,NULL, 55,10,503,100)
   *                         ),
   *             0.005)
   *             .ST_SwapOrdinates('ZM').geom as Geom
   *      from dual;
   *
   *    GEOM
   *    ------------------------------------------------------------------------------------------------------------------------------------
   *    SDO_GEOMETRY(4402,null,null,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(5,10,0,500, 20,5,null,501, 35,10,null,502, 55,10,100,503))
   *  AUTHOR
   *    Simon Greener
   *  HISTORY
   *    Simon Greener - August 2009 - Original coding.
   *  COPYRIGHT
   *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SwapOrdinates (p_pair in varchar2 default 'XY')
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_FilterRings
  *  NAME
  *    ST_FilterRings -- Removes rings from polygon/multipolygon below supplied area.
  *  SYNOPSIS
  *    Member Function ST_FilterRings(p_area in number,
  *                                   p_unit in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    This function allows a user to remove inner rings from a polygon/multipolygon based on an area value.
  *    Will remove both outer and inner rings.
  *  ARGUMENTS
  *    p_area (Number)   - Area in square SRID units below which an inner ring is removed.
  *    p_unit (VarChar2) - Oracle Unit of Measure For SRID eg unit=M.
  *  RESULT
  *    polygon collection (T_GEOMETRIES) -- A set of one or more single rings derived from input polygon.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null),0.005,3,1) as TGeom
  *        From Dual
  *      Union All
  *      Select T_GEOMETRY(sdo_geometry(2007,NULL,NULL,
  *                                     sdo_elem_info_array(1,1005,2, 1,2,1, 7,2,2,13,1003,3),
  *                                     sdo_ordinate_array (10,128, 10,125, 20,125, 20,128, 15,130, 10,128, 0,0, 10,10)),0.005,3,1) as TGeom
  *        From Dual
  *    )
  *    Select a.tGeom.ST_Area()                          as originalArea,
  *           a.tGeom.ST_FilterRings(50.0).ST_Area()     as filteredArea,
  *           a.tGeom.ST_FilterRings(50.0).ST_Validate() as validate_geom
  *      From data a;
  *
  *    ORIGINALAREA FILTEREDAREA VGEOM
  *    ------------ ------------ -----
  *             395          400 TRUE
  *     143.7507329          100 TRUE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_FilterRings(p_area in number,
                                 p_unit in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY   Deterministic,

  /****m* T_GEOMETRY/ST_RemoveInnerRings
  *  NAME
  *    ST_RemoveInnerRings -- Removes all interior/inner rings from polygon/multipolygon.
  *  SYNOPSIS
  *    Member Function ST_RemoveInnerRings
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    This function allows a user to remove all inner rings from a polygon/multipolygon.
  *  RESULT
  *    geometry (T_GEOMETRY) -- A (multi)polygon with exterior ring(s) only.
  *  EXAMPLE
  *    with data as (
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        from dual
  *      union all
  *      Select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null),0.005,3,1) as tgeom
  *        from dual
  *    )
  *    select f.iRings                    as iRingBEfore, 
  *           f.geom.ST_NumInteriorRing() as iRingAfter,
  *           f.geom.ST_AsText()          as eRingPolygon
  *      from (select a.tgeom.ST_NumInteriorRing()  as iRings,
  *                   a.tgeom.ST_RemoveInnerRings() as geom
  *              from data a
  *          ) f;
  *
  *    IRINGBEFORE IRINGAFTER ERINGPOLYGON
  *    ----------- ---------- --------------------------------------------------------------------------------------------------------------------------------
  *              2          0 MULTIPOLYGON (((0.0 0.0, 20.0 0.0, 20.0 20.0, 0.0 20.0, 0.0 0.0)), ((100.0 100.0, 200.0 100.0, 200.0 200.0, 100.0 200.0, 100.0 100.0)))
  *              2          0 POLYGON ((0.0 0.0, 20.0 0.0, 20.0 20.0, 0.0 20.0, 0.0 0.0))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Spetember 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_RemoveInnerRings
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_Extract
  *  NAME
  *    ST_ExtractRings -- Extracts all single geometry objects from geometry collection, multi linestring or multi polygon.
  *  SYNOPSIS
  *    Member Function ST_Extract
  *             Return &&INSTALL_SCHEMA..T_GEOMETRIES Pipelined
  *  DESCRIPTION
  *    This function extracts all single geometry types (eg point, linestring, polygon) from the underlying geometry.
  *    The underlying geometry object must be a geometry collection (x004), multi linestring (x006) or multi polygon (x007).
  *  EXAMPLE
  *    with data as (
  *     select 1 as geomid, t_geometry(sdo_geometry(2004,null,null,sdo_elem_info_array(1,1,1, 3,2,1, 7,1003,1),       sdo_ordinate_array(10,5, 10, 10,20,10,10,105, 15,105, 20,110, 10,110, 10,105)),0.05) as tgeom
  *       from dual union all
  *     select 2 as geomid, t_geometry(sdo_geometry(2004,NULL,NULL,sdo_elem_info_array(1,1003,3,5,1, 1,9,2,1, 11,2,1),sdo_ordinate_array(0, 0,100,100,50,50, 0,  0,100,100,300,  0,310,  1        )),0.05) as tgeom
  *       from dual union all
  *     Select 3 as geomid, T_GEOMETRY(sdo_geometry('MULTILINESTRING((-1 -1, 0 -1),(0 0,10 0,10 5,10 10,5 10,5 5))',null),0.005,3,1) as tgeom
  *       From Dual union all
  *     Select 4 as geomid, T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0)),((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *       From Dual
  *   )
  *   select a.geomId,
  *          t.gid,
  *          t_geometry(t.geometry,t.tolerance,t.dPrecision,t.projected).ST_AsText() as tegeom
  *     from data a,
  *          table(a.tgeom.ST_Extract()) t;
  *
  *   GEOMID GID TEGEOM
  *   ------ --- -------------------------------------------------------
  *        1   1 POINT (10 5)
  *        1   2 LINESTRING (10 10, 20 10)
  *        1   3 POLYGON ((10 105, 15 105, 20 110, 10 110, 10 105))
  *        2   1 POLYGON ((0 0, 100 0, 100 100, 0 100, 0 0))
  *        2   2 POINT (50 50)
  *        2   3 LINESTRING (100 100)
  *        2   4 LINESTRING (300 0, 310 1)
  *        3   1 LINESTRING (-1 -1, 0 -1)
  *        3   2 LINESTRING (0 0, 10 0, 10 5, 10 10, 5 10, 5 5)
  *        4   1 POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0))
  *        4   2 POLYGON ((100 100, 200 100, 200 200, 100 200, 100 100))
  *
  *    11 rows selected
  *  RESULT
  *    polygon (T_GEOMETRY) -- All geometries are extracted and returned.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function ST_Extract
           Return &&INSTALL_SCHEMA..T_Geometries Pipelined,

  /****m* T_GEOMETRY/ST_Extract(p_geomType)
  *  NAME
  *    ST_ExtractRings -- Extracts required geometry types (point, line, polygon) from underlying geometry collection.
  *  SYNOPSIS
  *    Member Function ST_Extract (
  *                       p_geomType in varchar2
  *                     )
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic
  *  ARGUMENTS
  *    p_geomType (varchar2) - GeometryType to be extracted must be one of POINT,ST_POINT,LINE,LINESTRING,ST_LINESTRING,POLY,POLYGON,ST_POLYGON
  *  RESULT
  *    polygon (T_GEOMETRY) -- Geometries of required Geometry_Type.
  *  DESCRIPTION
  *    This function allows a user to extract all geometries of a particular type from the underlying geometry collection (x004).
  *    The resultant t_geometry object could be singular eg LINESTRING or multi eg MULTILINESTRING.
  *  EXAMPLE
  *    with data as (
  *      select 1 as geomid, t_geometry(sdo_geometry(2004,null,null,sdo_elem_info_array(1,1,1, 3,2,1, 7,1003,1),       sdo_ordinate_array(10,5, 10, 10,20,10,10,105, 15,105, 20,110, 10,110, 10,105)),0.05) as tgeom from dual union all
  *      select 2 as geomid, t_geometry(sdo_geometry(2004,NULL,NULL,sdo_elem_info_array(1,1003,3,5,1, 1,9,2,1, 11,2,1),sdo_ordinate_array(0, 0,100,100,50,50, 0,  0,100,100,300,  0,310,  1        )),0.05) as tgeom from dual
  *    )
  *    select geomId,
  *           case t.IntValue
  *                when 1 then 'Point'
  *                when 2 then 'Line'
  *                when 3 then 'Polygon'
  *            end as geomType,
  *           a.tgeom.ST_Extract(
  *                      case t.IntValue
  *                           when 1 then 'Point'
  *                           when 2 then 'Line'
  *                           when 3 then 'Polygon'
  *                       end
  *                   ).ST_AsText() as geom
  *      from data a,
  *           table(tools.generate_series(1,3,1)) t
  *
  *    GEOMID GEOMTYPE GEOM
  *    ------ -------- --------------------------------------------------
  *         1 Point    POINT (10 5)
  *         1 Line     LINESTRING (10 10, 20 10)
  *         1 Polygon  POLYGON ((10 105, 15 105, 20 110, 10 110, 10 105))
  *         2 Point    POINT (50 50)
  *         2 Line     MULTILINESTRING ((100 100), (300 0, 310 1))
  *         2 Polygon  POLYGON ((0 0, 100 0, 100 100, 0 100, 0 0))
  *
  *     6 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Extract (p_geomType in varchar2)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_ExtractRings
  *  NAME
  *    ST_ExtractRings -- Extracts all rings of a polygon/multipolygon into a set of simple T_GEOMETRY polygon objects.
  *  SYNOPSIS
  *    Member Function ST_ExtractRings()
  *             Return &&INSTALL_SCHEMA..T_GEOMETRIES Pipelined
  *  DESCRIPTION
  *    This function allows a user to extract all outer and inner rings from a polygon/multipolygon. The resultant set of
  *    individual inner or outer rings are accessible via the Oracle SQL TABLE function as in the example below.
  *  EXAMPLE
  *    With Data as (
  *      Select 1 as geomId, T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(0,0,20,0,20,20,0,20,0,0)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select 2 as geomId, T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,1,11,2003,1),sdo_ordinate_array(0,0,20,0,20,20,0,20,0,0, 5,5,5,10,10,10,10,5,5,5)),0.005,3,1) as tgeom
  *        From Dual
  *      union all
  *      Select 3 as geomId, T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),
  *                                                     ((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select a.geomid, t.gid as ringId, t_geometry(t.geometry,t.tolerance,t.dPrecision,t.projected).ST_AsText() as geom
  *      from data a,
  *            table(a.tgeom.ST_ExtractRings()) t;
  *
  *    GEOMID RINGID GEOM
  *    ------ ------ -------------------------------------------------------
  *         1      1 POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0))
  *         2      1 POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0))
  *         2      2 POLYGON ((5 5, 10 5, 10 10, 5 10, 5 5))
  *         3      1 POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0))
  *         3      2 POLYGON ((10 10, 11 10, 11 11, 10 11, 10 10))
  *         3      3 POLYGON ((5 5, 7 5, 7 7, 5 7, 5 5))
  *         3      1 POLYGON ((100 100, 200 100, 200 200, 100 200, 100 100))
  *
  *     7 rows selected
  *  RESULT
  *    polygon (T_GEOMETRY) -- All polygon rings retured as individual polygons.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_ExtractRings
           Return &&INSTALL_SCHEMA..T_GEOMETRIES Pipelined,

  /****m* T_GEOMETRY/ST_Vertices
  *  NAME
  *    ST_Vertices -- Extracts all vertices of the underlying geometry, and outputs them as a pipelined set of T_Vertex objects.
  *  SYNOPSIS
  *    Member Function ST_Vertices()
  *             Return &&INSTALL_SCHEMA..T_VERTICES Pipelined
  *  DESCRIPTION
  *    This function allows a user to extract all the vertices of the underlying geometry as a set of T_VERTEX objects.
  *  EXAMPLE
  *    With geometries As (
  *      Select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null),
  *                        0.005,3,1) as tPolygon
  *        From dual
  *    )
  *    Select t.ST_AsText() as vertex
  *      from GEOMETRIES a,
  *           Table(a.tPolygon.ST_Vertices()) t;
  *
  *    VERTEX
  *    -------------------------------------
  *    T_Vertex(X=0.0,Y=0.0,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=20.0,Y=0.0,Z=NULL,W=NULL,ID=2,GT=2001,SRID=NULL)
  *    T_Vertex(X=20.0,Y=20.0,Z=NULL,W=NULL,ID=3,GT=2001,SRID=NULL)
  *    T_Vertex(X=0.0,Y=20.0,Z=NULL,W=NULL,ID=4,GT=2001,SRID=NULL)
  *    T_Vertex(X=0.0,Y=0.0,Z=NULL,W=NULL,ID=5,GT=2001,SRID=NULL)
  *    T_Vertex(X=10.0,Y=10.0,Z=NULL,W=NULL,ID=6,GT=2001,SRID=NULL)
  *    T_Vertex(X=10.0,Y=11.0,Z=NULL,W=NULL,ID=7,GT=2001,SRID=NULL)
  *    T_Vertex(X=11.0,Y=11.0,Z=NULL,W=NULL,ID=8,GT=2001,SRID=NULL)
  *    T_Vertex(X=11.0,Y=10.0,Z=NULL,W=NULL,ID=9,GT=2001,SRID=NULL)
  *    T_Vertex(X=10.0,Y=10.0,Z=NULL,W=NULL,ID=10,GT=2001,SRID=NULL)
  *    T_Vertex(X=5.0,Y=5.0,Z=NULL,W=NULL,ID=11,GT=2001,SRID=NULL)
  *    T_Vertex(X=5.0,Y=7.0,Z=NULL,W=NULL,ID=12,GT=2001,SRID=NULL)
  *    T_Vertex(X=7.0,Y=7.0,Z=NULL,W=NULL,ID=13,GT=2001,SRID=NULL)
  *    T_Vertex(X=7.0,Y=5.0,Z=NULL,W=NULL,ID=14,GT=2001,SRID=NULL)
  *    T_Vertex(X=5.0,Y=5.0,Z=NULL,W=NULL,ID=15,GT=2001,SRID=NULL)
  *
  *     15 rows selected
  *  RESULT
  *    vertices (T_VERTICES) -- Table of T_Vertex objects.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Vertices
           Return &&INSTALL_SCHEMA..T_Vertices Pipelined,
           
 /****m* T_GEOMETRY/ST_Segmentize
  *  NAME
  *    ST_Segmentize -- This function processes underlying non-point geometries and returns all segments that fall within the defined parameters eg measures covered by range p_start_value .. p_end_value .
  *  SYNOPSIS
  *    Member Function ST_Segmentize(p_filter        in varchar2 default 'ALL',
  *                                  p_id            in integer  default null,
  *                                  p_vertex        in T_Vertex default null,
  *                                  p_filter_value  in number   default null,
  *                                  p_start_value   in number   default null,
  *                                  p_end_value     in number   default null,
  *                                  p_unit          in varchar2 default null)
  *             Return T_Segments deterministic,
  *  ARGUMENTS
  *    p_filter     (varchar2) -- One of ALL, DISTANCE, ID, MEASURE, RANGE, X or Y
  *    p_id          (integer) -- Segment id should be in range 1..SELF.ST_NumSegments. -1 means last.
  *    p_vertex     (t_vertex) -- Point object used to return nearest segments/segments.
  *    p_filter_value  (float) -- Single measure (or length) along line.
  *    p_start_value   (float) -- Measure/Length defining start point of located geometry.
  *    p_end_value     (float) -- Measure/Length defining end point of located geometry.
  *    p_unit       (varchar2) -- Unit of measure (UoM eg Centimeter) for length/distance calculations.
  *  RESULT
  *    Set of segments (T_SEGMENTs) -- A table array of T_SEGMENT objects.
  *  DESCRIPTION
  *    Given a start and end length, this function breaks the underlying linestring into its fundamental 2 Point LineString or 3 Point CircularStrings.
  *    What is returned depends on the value of p_filter. The following values are supported:
  *      1. ALL      -- All other parameters are ignored, and all segments are extracted and returned.
  *      2. DISTANCE -- Segments within shortest distance to p_vertex.
  *      3. ID       -- Returns segment at this position in geometry.
  *      4. MEASURE  -- All measured segments whose measure range contains p_filter_value value, or if not measured, all segments who length from start contains p_filter_value.
  *      5. RANGE    -- All segments whose measure range overlaps p_start_value .. p_end_value.
  *                     If the underlying geometry is not measured, p_start_value .. p_end_value are interpreted as lengths from the staring point ie p_start_Length..p_end_length.
  *      6. X        -- Find and return all segments whose X ordinate range (eg end.x = start.x) contains the supplied (p_filter_value) X ordinate value.
  *      7. Y        -- Find and return all segments whose Y ordinate range (eg end.Y = start.Y) contains the supplied (p_filter_value) Y ordinate value.
  *    If a segment's end point = p_start_value then it is not returned but the next segment, whose StartPoint = p_start_value is returned.
  *  NOTES
  *    Supports linestrings with CircularString elements.
  *    Return is NOT Pipelined
  *  EXAMPLE
  *    -- Compound line string
  *    with data as (
  *    select t_geometry(
  *             SDO_GEOMETRY(2002,NULL,NULL,
  *                          SDO_ELEM_INFO_ARRAY(1,4,2, 1,2,1, 3,2,2), -- compound line string
  *                          SDO_ORDINATE_ARRAY(252000,5526000,
  *                                             252700,5526700, 252644.346,5526736.414,
  *                                             252500,5526700, 252280.427,5526697.167, 252230.478,5526918.373
  *                                            )
  *             ),0.05,1,1) as tgeom
  *      from dual
  *    )
  *    SELECT a.tgeom.ST_Sdo_Gtype() as sdo_gtype,
  *           t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter => 'ALL' ) ) t;
  *
  *    SDO_GTYPE SEGMENT
  *    --------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *         2002 SEGMENT(1,1,1,Start(252000,5526000,NULL,NULL,1,2001,NULL),End(252700,5526700,NULL,NULL,2,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *         2002 SEGMENT(1,1,2,Start(252700,5526700,NULL,NULL,2,2001,NULL),Mid(252644.346,5526736.414,NULL,NULL,3,2001,NULL),End(252500,5526700,NULL,NULL,4,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *         2002 SEGMENT(1,1,3,Start(252500,5526700,NULL,NULL,4,2001,NULL),Mid(252280.427,5526697.167,NULL,NULL,5,2001,NULL),End(252230.478,5526918.373,NULL,NULL,6,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *
  *    -- Extract second circular arc in linestring
  *    WITH data as (
  *      SELECT t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (SELECT SDO_GEOMETRY(2002,NULL,NULL,
  *                                  SDO_ELEM_INFO_ARRAY(1,4,2, 1,2,1, 3,2,2), -- compound line string
  *                                  SDO_ORDINATE_ARRAY(
  *                                      252000,5526000,
  *                                      252700,5526700, 252644.346,5526736.414, 252500,5526700,
  *                                                                              252280.427,5526697.167, 252230.478,5526918.373
  *                                  )
  *                      ) as geom
  *                FROM DUAL
  *             ) f
  *    )
  *    SELECT 3 as p_id, t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter => 'ID',
  *                                       p_id     => 3) ) t;
  *
  *          P_ID SEGMENT
  *    ---------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *             3 SEGMENT(1,1,3,Start(252500,5526700,NULL,NULL,4,2001,NULL),Mid(252280.427,5526697.167,NULL,NULL,5,2001,NULL),End(252230.478,5526918.373,NULL,NULL,6,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *
  *    -- All sides of an optimized rectangle with rings
  *    WITH data as (
  *      SELECT t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (SELECT SDO_GEOMETRY(2003,28355,NULL,
  *                         SDO_ELEM_INFO_ARRAY(1,1003,3,5,2003,3),
  *                         SDO_ORDINATE_ARRAY(0,0,10,10,200,100,100,200)) AS GEOM
  *                FROM DUAL
  *             ) f
  *    )
  *    SELECT t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter => 'ALL') ) t;
  *
  *    SEGMENT
  *    ----------------------------------------------------------------------------------------------------------------------
  *    SEGMENT(1,1,1,Start(0,0,NULL,NULL,1,2001,28355),End(10,0,NULL,NULL,2,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *    SEGMENT(1,1,2,Start(10,0,NULL,NULL,2,2001,28355),End(10,10,NULL,NULL,3,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *    SEGMENT(1,1,3,Start(10,10,NULL,NULL,3,2001,28355),End(0,10,NULL,NULL,4,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *    SEGMENT(1,1,4,Start(0,10,NULL,NULL,4,2001,28355),End(0,0,NULL,NULL,5,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *    SEGMENT(1,2,1,Start(100,200,NULL,NULL,1,2001,28355),End(200,200,NULL,NULL,2,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *    SEGMENT(1,2,2,Start(200,200,NULL,NULL,2,2001,28355),End(200,100,NULL,NULL,3,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *    SEGMENT(1,2,3,Start(200,100,NULL,NULL,3,2001,28355),End(100,100,NULL,NULL,4,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *    SEGMENT(1,2,4,Start(100,100,NULL,NULL,4,2001,28355),End(100,200,NULL,NULL,5,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *
  *     8 rows selected
  *
  *    -- specific side in optimized rectangle
  *    WITH data as (
  *      SELECT t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (SELECT SDO_GEOMETRY(2003,28355,NULL,
  *                         SDO_ELEM_INFO_ARRAY(1,1003,3,5,2003,3),
  *                         SDO_ORDINATE_ARRAY(0,0,10,10,200,100,100,200)) AS GEOM
  *                FROM DUAL
  *             ) f
  *    )
  *    SELECT 3 as p_id, t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter => 'ID',
  *                                       p_id     => 3) ) t;
  *
  *          P_ID SEGMENT
  *    ---------- -----------------------------------------------------------------------------------------------------------------
  *             3 SEGMENT(1,1,3,Start(10,10,NULL,NULL,3,2001,28355),End(0,10,NULL,NULL,4,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *
  *    -- All segments of a 2D and 3D stroked linestring
  *    WITH data as (
  *      select t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (select SDO_GEOMETRY(2002,28355,NULL,
  *                         SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                            571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                            572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                            574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                            576238.453,324521.56, 576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)) AS GEOM
  *                from dual UNION ALL
  *              select SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                             571303.231,321126.963,110.0,   571551.298,321231.412,377.21,   572765.519,321322.805,1586.05,  572739.407,321845.051,2105.16,
  *                             572752.463,322641.476,2895.92, 573209.428,323398.732,3773.96,  573796.954,323555.406,4377.62,  574436.705,323790.416,5054.23,
  *                             574945.895,324051.539,5622.33, 575128.681,324652.122,6245.56,  575128.681,325161.311,6751.06,  575898.993,325213.536,7517.55,
  *                             576238.453,324521.56,8282.72,  576251.509,321048.626,11730.53, 575259.242,322615.364,13571.62, 574306.144,321296.693,15186.88)) as geom
  *                from dual
  *             ) f
  *    )
  *    select a.tgeom.ST_Sdo_Gtype() as sdo_gtype, t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter      => 'ALL',
  *                                       p_vertex      => NULL,
  *                                       p_filter_value=> NULL,
  *                                       p_start_value => NULL,
  *                                       p_end_value   => NULL,
  *                                       p_unit        => null)) t;
  *
  *     SDO_GTYPE segment
  *    --------- --------------------------------------------------------------------------------------------------------------------------------------------------------
  *         2002 segment(1,1,1,Start(571303.231,321126.963,NULL,NULL,1,2001,28355),End(571551.298,321231.412,NULL,NULL,2,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,2,Start(571551.298,321231.412,NULL,NULL,2,2001,28355),End(572765.519,321322.805,NULL,NULL,3,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,3,Start(572765.519,321322.805,NULL,NULL,3,2001,28355),End(572739.407,321845.051,NULL,NULL,4,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,4,Start(572739.407,321845.051,NULL,NULL,4,2001,28355),End(572752.463,322641.476,NULL,NULL,5,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,5,Start(572752.463,322641.476,NULL,NULL,5,2001,28355),End(573209.428,323398.732,NULL,NULL,6,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,6,Start(573209.428,323398.732,NULL,NULL,6,2001,28355),End(573796.954,323555.406,NULL,NULL,7,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,7,Start(573796.954,323555.406,NULL,NULL,7,2001,28355),End(574436.705,323790.416,NULL,NULL,8,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,8,Start(574436.705,323790.416,NULL,NULL,8,2001,28355),End(574945.895,324051.539,NULL,NULL,9,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,9,Start(574945.895,324051.539,NULL,NULL,9,2001,28355),End(575128.681,324652.122,NULL,NULL,10,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,10,Start(575128.681,324652.122,NULL,NULL,10,2001,28355),End(575128.681,325161.311,NULL,NULL,11,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,11,Start(575128.681,325161.311,NULL,NULL,11,2001,28355),End(575898.993,325213.536,NULL,NULL,12,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,12,Start(575898.993,325213.536,NULL,NULL,12,2001,28355),End(576238.453,324521.56,NULL,NULL,13,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,13,Start(576238.453,324521.56,NULL,NULL,13,2001,28355),End(576251.509,321048.626,NULL,NULL,14,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,14,Start(576251.509,321048.626,NULL,NULL,14,2001,28355),End(575259.242,322615.364,NULL,NULL,15,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         2002 segment(1,1,15,Start(575259.242,322615.364,NULL,NULL,15,2001,28355),End(574306.144,321296.693,NULL,NULL,16,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         3302 segment(1,1,1,Start(571303.231,321126.963,110,NULL,1,3301,28355),End(571551.298,321231.412,377.21,NULL,2,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,2,Start(571551.298,321231.412,377.21,NULL,2,3301,28355),End(572765.519,321322.805,1586.05,NULL,3,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,3,Start(572765.519,321322.805,1586.05,NULL,3,3301,28355),End(572739.407,321845.051,2105.16,NULL,4,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,4,Start(572739.407,321845.051,2105.16,NULL,4,3301,28355),End(572752.463,322641.476,2895.92,NULL,5,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,5,Start(572752.463,322641.476,2895.92,NULL,5,3301,28355),End(573209.428,323398.732,3773.96,NULL,6,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,6,Start(573209.428,323398.732,3773.96,NULL,6,3301,28355),End(573796.954,323555.406,4377.62,NULL,7,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,7,Start(573796.954,323555.406,4377.62,NULL,7,3301,28355),End(574436.705,323790.416,5054.23,NULL,8,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,8,Start(574436.705,323790.416,5054.23,NULL,8,3301,28355),End(574945.895,324051.539,5622.33,NULL,9,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,9,Start(574945.895,324051.539,5622.33,NULL,9,3301,28355),End(575128.681,324652.122,6245.56,NULL,10,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,10,Start(575128.681,324652.122,6245.56,NULL,10,3301,28355),End(575128.681,325161.311,6751.06,NULL,11,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,11,Start(575128.681,325161.311,6751.06,NULL,11,3301,28355),End(575898.993,325213.536,7517.55,NULL,12,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,12,Start(575898.993,325213.536,7517.55,NULL,12,3301,28355),End(576238.453,324521.56,8282.72,NULL,13,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,13,Start(576238.453,324521.56,8282.72,NULL,13,3301,28355),End(576251.509,321048.626,11730.53,NULL,14,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,14,Start(576251.509,321048.626,11730.53,NULL,14,3301,28355),End(575259.242,322615.364,13571.62,NULL,15,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *         3302 segment(1,1,15,Start(575259.242,322615.364,13571.62,NULL,15,3301,28355),End(574306.144,321296.693,15186.88,NULL,16,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *
  *     30 rows selected
  *
  *    -- Extract 3rd/8th segment of 2D/3D stroked linestring
  *    WITH data as (
  *      SELECT t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (SELECT SDO_GEOMETRY(2002,28355,NULL,
  *                         SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                            571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                            572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                            574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                            576238.453,324521.56, 576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)) AS GEOM
  *                FROM DUAL
  *                UNION ALL
  *              SELECT SDO_GEOMETRY(2002,NULL,NULL,
  *                                  SDO_ELEM_INFO_ARRAY(1,4,2, 1,2,1, 3,2,2), -- compound line string
  *                                  SDO_ORDINATE_ARRAY(
  *                                      252000,5526000,
  *                                      252700,5526700, 252644.346,5526736.414,
  *                                      252500,5526700, 252280.427,5526697.167, 252230.478,5526918.373
  *                                  )
  *                      ) as geom
  *                FROM DUAL
  *             ) f
  *    )
  *    SELECT case when a.tGeom.ST_HasCircularArcs()=1 then 3 else 8 end as id,
  *           a.tgeom.ST_Sdo_Gtype() as sdo_gtype,
  *           t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter => 'ID',
  *                                       p_id     => case when a.tGeom.ST_HasCircularArcs()=1 then 3 else 8 end )) t;
  *
  *    ID SDO_GTYPE SEGMENT
  *    -- --------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *     8      2002 SEGMENT(1,1,8,Start(574436.705,323790.416,NULL,NULL,1,2001,28355),End(574945.895,324051.539,NULL,NULL,2,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *     3      2002 SEGMENT(1,1,3,Start(252700,5526700,NULL,NULL,1,2001,NULL),Mid(252644.346,5526736.414,NULL,NULL,2,2001,NULL),End(252500,5526700,NULL,NULL,3,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *
  *    WITH data as (
  *      select t_geometry(
  *               SDO_GEOMETRY(2002,28355,NULL,
  *                            SDO_ELEM_INFO_ARRAY(1,2,1),
  *                            SDO_ORDINATE_ARRAY(
  *                              571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                              572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                              574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                              576238.453,324521.56, 576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)),
  *               0.0005,3,1) as tGeom
  *        from dual
  *    )
  *    select a.tgeom.ST_Sdo_Gtype() as sdo_gtype, t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter      => 'DISTANCE',
  *                                       p_vertex      => NULL,
  *                                       p_filter_value=> NULL,
  *                                       p_start_value => NULL,
  *                                       p_end_value   => NULL,
  *                                       p_unit        => null)) t;
  *
  *    Error report:
  *    SQL Error: ORA-20102: If p_filter DISTANCE, then p_vertex must not be NULL.
  *    ORA-06512: at "&&INSTALL_SCHEMA..T_GEOMETRY", line 1901
  *    ORA-06512: at line 1
  *
  *    -- Find nearest segment to supplied vertex.
  *    WITH data as (
  *      select t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (select SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                            571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                            572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                            574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                            576238.453,324521.56,  576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)) as geom
  *                from dual UNION ALL
  *              select SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                             571303.231,321126.963,110.0,   571551.298,321231.412,377.21,   572765.519,321322.805,1586.05,  572739.407,321845.051,2105.16,
  *                             572752.463,322641.476,2895.92, 573209.428,323398.732,3773.96,  573796.954,323555.406,4377.62,  574436.705,323790.416,5054.23,
  *                             574945.895,324051.539,5622.33, 575128.681,324652.122,6245.56,  575128.681,325161.311,6751.06,  575898.993,325213.536,7517.55,
  *                             576238.453,324521.56,8282.72,  576251.509,321048.626,11730.53, 575259.242,322615.364,13571.62, 574306.144,321296.693,15186.88)) as geom
  *                from dual
  *             ) f
  *    )
  *    select a.tgeom.ST_Sdo_Gtype() as sdo_gtype, t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter => 'DISTANCE',
  *                                       p_vertex => T_Vertex(SDO_GEOMETRY(2001,28355,SDO_POINT_TYPE(572804.687,323424.844,NULL),NULL,NULL)) )) t;
  *
  *    SDO_GTYPE segment
  *    --------- -------------------------------------------------------------------------------------------------------------------------------------------------------
  *         2002 segment(1,1,5,Start(572752.463,322641.476,NULL,NULL,5,2001,28355),End(573209.428,323398.732,NULL,NULL,6,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         3302 segment(1,1,5,Start(572752.463,322641.476,2895.92,NULL,5,3301,28355),End(573209.428,323398.732,3773.96,NULL,6,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *
  *    -- Find segments containing measure value
  *    WITH data as (
  *      select t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (select SDO_GEOMETRY(2002,28355,NULL,
  *                         SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                            571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                            572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                            574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                            576238.453,324521.56, 576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)) AS GEOM
  *                from dual UNION ALL
  *              select SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                             571303.231,321126.963,110.0,   571551.298,321231.412,377.21,   572765.519,321322.805,1586.05,  572739.407,321845.051,2105.16,
  *                             572752.463,322641.476,2895.92, 573209.428,323398.732,3773.96,  573796.954,323555.406,4377.62,  574436.705,323790.416,5054.23,
  *                             574945.895,324051.539,5622.33, 575128.681,324652.122,6245.56,  575128.681,325161.311,6751.06,  575898.993,325213.536,7517.55,
  *                             576238.453,324521.56,8282.72,  576251.509,321048.626,11730.53, 575259.242,322615.364,13571.62, 574306.144,321296.693,15186.88)) as geom
  *                from dual
  *             ) f
  *    )
  *    select a.tgeom.ST_Sdo_Gtype() as sdo_gtype,
  *           t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter      => 'MEASURE',
  *                                       p_filter_value=> 2100.0 )) t;
  *
  *    SDO_GTYPE segment
  *    --------- -------------------------------------------------------------------------------------------------------------------------------------------------------
  *         2002 segment(1,1,4,Start(572739.407,321845.051,NULL,NULL,4,2001,28355),End(572752.463,322641.476,NULL,NULL,5,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *         3302 segment(1,1,3,Start(572765.519,321322.805,1586.05,NULL,3,3301,28355),End(572739.407,321845.051,2105.16,NULL,4,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *
  *    -- Find data within measure range if measured or length range if not
  *    WITH data as (
  *      select t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (select SDO_GEOMETRY(2002,28355,NULL,
  *                         SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                            571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                            572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                            574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                            576238.453,324521.56, 576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)) AS GEOM
  *                from dual UNION ALL
  *              select SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                             571303.231,321126.963,110.0,   571551.298,321231.412,377.21,   572765.519,321322.805,1586.05,  572739.407,321845.051,2105.16,
  *                             572752.463,322641.476,2895.92, 573209.428,323398.732,3773.96,  573796.954,323555.406,4377.62,  574436.705,323790.416,5054.23,
  *                             574945.895,324051.539,5622.33, 575128.681,324652.122,6245.56,  575128.681,325161.311,6751.06,  575898.993,325213.536,7517.55,
  *                             576238.453,324521.56,8282.72,  576251.509,321048.626,11730.53, 575259.242,322615.364,13571.62, 574306.144,321296.693,15186.88)) as geom
  *                from dual
  *             ) f
  *    )
  *    select a.tgeom.ST_Sdo_Gtype() as sdo_gtype, t.segment.ST_SdoGeometry(a.tGeom.ST_Dims()) as geom
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter      => 'RANGE',
  *                                       p_start_value => 2100.0,
  *                                       p_end_value   => 4300.0
  *                                       )) t;
  *
  *    SDO_GTYPE GEOM
  *    --------- ----------------------------------------------------------------------------------------------------------------------------------------
  *         2002 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(572739.407,321845.051,572752.463,322641.476))
  *         2002 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(572752.463,322641.476,573209.428,323398.732))
  *         2002 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(573209.428,323398.732,573796.954,323555.406))
  *         2002 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(573796.954,323555.406,574436.705,323790.416))
  *         3302 SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(572765.519,321322.805,1586.05,572739.407,321845.051,2105.16))
  *         3302 SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(572739.407,321845.051,2105.16,572752.463,322641.476,2895.92))
  *         3302 SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(572752.463,322641.476,2895.92,573209.428,323398.732,3773.96))
  *         3302 SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(573209.428,323398.732,3773.96,573796.954,323555.406,4377.62))
  *
  *     8 rows selected
  *
  *    -- Select segments which cross X ordinate value
  *      WITH data as (
  *      SELECT t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (SELECT SDO_GEOMETRY(2002,28355,NULL,
  *                         SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                            571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                            572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                            574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                            576238.453,324521.56, 576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)) AS GEOM
  *                FROM DUAL UNION ALL
  *              SELECT SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                             571303.231,321126.963,110.0,   571551.298,321231.412,377.21,   572765.519,321322.805,1586.05,  572739.407,321845.051,2105.16,
  *                             572752.463,322641.476,2895.92, 573209.428,323398.732,3773.96,  573796.954,323555.406,4377.62,  574436.705,323790.416,5054.23,
  *                             574945.895,324051.539,5622.33, 575128.681,324652.122,6245.56,  575128.681,325161.311,6751.06,  575898.993,325213.536,7517.55,
  *                             576238.453,324521.56,8282.72,  576251.509,321048.626,11730.53, 575259.242,322615.364,13571.62, 574306.144,321296.693,15186.88)) as geom
  *                FROM DUAL
  *             ) f
  *    )
  *    SELECT a.tgeom.ST_Sdo_Gtype() as sdo_gtype,
  *           t.segment.ST_AsText() as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter      => 'X',
  *                                       p_filter_value=> 571551.0)) t;
  *
  *     SDO_GTYPE SEGMENT
  *    ---------- --------------------------------------------------------------------------------------------------------------------------------------------------
  *          2002 SEGMENT(1,1,1,Start(571303.231,321126.963,NULL,NULL,1,2001,28355),End(571551.298,321231.412,NULL,NULL,2,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *          3302 SEGMENT(1,1,1,Start(571303.231,321126.963,110,NULL,1,3301,28355),End(571551.298,321231.412,377.21,NULL,2,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *
  *    -- Find segments containing X ordinate value
  *    WITH data as (
  *      SELECT t_geometry(geom,0.0005,3,1) as tGeom
  *        FROM (SELECT SDO_GEOMETRY(2002,28355,NULL,
  *                         SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                            571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                            572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                            574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                            576238.453,324521.56, 576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)) AS GEOM
  *                FROM DUAL UNION ALL
  *              SELECT SDO_GEOMETRY(3302,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(
  *                             571303.231,321126.963,110.0,   571551.298,321231.412,377.21,   572765.519,321322.805,1586.05,  572739.407,321845.051,2105.16,
  *                             572752.463,322641.476,2895.92, 573209.428,323398.732,3773.96,  573796.954,323555.406,4377.62,  574436.705,323790.416,5054.23,
  *                             574945.895,324051.539,5622.33, 575128.681,324652.122,6245.56,  575128.681,325161.311,6751.06,  575898.993,325213.536,7517.55,
  *                             576238.453,324521.56,8282.72,  576251.509,321048.626,11730.53, 575259.242,322615.364,13571.62, 574306.144,321296.693,15186.88)) as geom
  *                FROM DUAL
  *             ) f
  *    )
  *    SELECT a.tgeom.ST_Sdo_Gtype() as sdo_gtype,
  *           t.segment.ST_AsText() as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter      => 'Y',
  *                                       p_filter_value=> 321231.412)) t;
  *
  *     SDO_GTYPE SEGMENT
  *    ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------
  *          2002 SEGMENT(1,1,1,Start(571303.231,321126.963,NULL,NULL,1,2001,28355),End(571551.298,321231.412,NULL,NULL,2,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *          2002 SEGMENT(1,1,2,Start(571551.298,321231.412,NULL,NULL,2,2001,28355),End(572765.519,321322.805,NULL,NULL,3,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *          2002 SEGMENT(1,1,14,Start(576251.509,321048.626,NULL,NULL,14,2001,28355),End(575259.242,322615.364,NULL,NULL,15,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *          3302 SEGMENT(1,1,1,Start(571303.231,321126.963,110,NULL,1,3301,28355),End(571551.298,321231.412,377.21,NULL,2,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *          3302 SEGMENT(1,1,2,Start(571551.298,321231.412,377.21,NULL,2,3301,28355),End(572765.519,321322.805,1586.05,NULL,3,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *          3302 SEGMENT(1,1,14,Start(576251.509,321048.626,11730.53,NULL,14,3301,28355),End(575259.242,322615.364,13571.62,NULL,15,3301,28355),SDO_GTYPE=3302,SDO_SRID=28355)
  *
  *     6 rows selected
  *
  *    -- Circular arc test showing mid point involved in determining if segment is selected for X ordinates.
  *    WITH data as (
  *      SELECT t_geometry(
  *               SDO_GEOMETRY(2002,NULL,NULL,
  *                            SDO_ELEM_INFO_ARRAY(1,2,2), -- Circular Arc line string
  *                            SDO_ORDINATE_ARRAY(252230.478,5526918.373, 252400.08,5526918.373,252230.478,5527000.0)
  *               ),0.0005,3,1)
  *               as tGeom
  *        FROM DUAL
  *    )
  *    SELECT t.segment.ST_AsText()  as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter       => 'X',
  *                                       p_filter_value => 252309.544 ) ) t;
  *
  *    SEGMENT
  *    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SEGMENT(1,1,1,Start(252230.478,5526918.373,NULL,NULL,1,2001,NULL),Mid(252400.08,5526918.373,NULL,NULL,2,2001,NULL),End(252230.478,5527000,NULL,NULL,3,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *
  *
  *    -- Circular arc test showing mid point involved in determining if segment is selected for Y ordinates.
  *    WITH data as (
  *      SELECT t_geometry(
  *               SDO_GEOMETRY(2002,NULL,NULL,
  *                            SDO_ELEM_INFO_ARRAY(1,2,2), -- Circular Arc line string
  *                            SDO_ORDINATE_ARRAY(252700,5526700, 252644.346,5526736.414, 252500,5526700)
  *               ),0.0005,3,1)
  *               as tGeom
  *        FROM DUAL
  *    )
  *    SELECT t.segment.ST_AsText() as segment
  *      FROM data a,
  *           table(a.tgeom.ST_Segmentize(p_filter       => 'Y',
  *                                       p_filter_value => 5526724.224 ) ) t;
  *
  *    SEGMENT
  *    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SEGMENT(1,1,1,Start(252700,5526700,NULL,NULL,1,2001,NULL),Mid(252644.346,5526736.414,NULL,NULL,2,2001,NULL),End(252500,5526700,NULL,NULL,3,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *
  *    -- Circle
  *    With data As (
  *    SELECT t_geometry(
  *             SDO_GEOMETRY(2003,28355,null,
  *                          sdo_elem_info_array(1,1003,4),
  *                          SDO_ORDINATE_ARRAY(252315.279,5526865.07512246, 252409.390377544,5526959.1865, 252315.279,5527053.29787754)
  *                          ),
  *             0.0005,3,1) as circlePoly
  *      FROM Dual
  *    )
  *    select t.segment.ST_AsText() as segment
  *      from data a,
  *           table(a.circlePoly.ST_Segmentize()) t;
  *
  *    SEGMENT
  *    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SEGMENT(1,1,1,
  *            Start(1,252315.279,5526865.07512246,NULL,NULL,2001,28355),
  *              Mid(2,252409.39037754,5526959.1865,NULL,NULL,2001,28355),
  *              End(3,252315.279,5527053.29787754,NULL,NULL,2001,28355),
  *            SDO_GTYPE=2002,SDO_SRID=28355)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - December 2017 - Original PLSQL Coding for Oracle
 ******/
  Member Function ST_Segmentize(p_filter       in varchar2  default 'ALL',
                                p_id           in integer   default null,
                                p_vertex       in &&INSTALL_SCHEMA..T_Vertex default null,
                                p_filter_value in number    default null,
                                p_start_value  in number    default null,
                                p_end_value    in number    default null,
                                p_unit         in varchar2  default null)
           Return &&INSTALL_SCHEMA..T_Segments deterministic,

/****f* T_GEOMETRY/ST_Flip_Segments
 *  NAME
 *    ST_Flip_Segments - Turns linestring and polygon rings into segments and then flips each vector until all point in the same direction.
 *  SYNOPSIS
 *    Member Function ST_Flip_Vectors 
 *             Return geometry
 *  EXAMPLE
 *    With gc As (
 *    select geometry::STGeomFromText(
 *    'GEOMETRYCOLLECTION(
 *    POLYGON((10 0,20 0,20 20,10 20,10 0)),
 *    POLYGON((20 0,30 0,30 20,20 20,20 0)),
 *    POINT(0 0))',0) as geom
 *    )
 *    select v.sx,v.sy,v.ex,v.ey,count(*)
 *      from gc as a
 *           cross apply
 *           [dbo].[STVectorize] (
 *             [dbo].[STFlipVectors] ( a.geom )
 *           ) as v
 *     group by v.sx,v.sy,v.ex,v.ey
 *    go
 *  DESCRIPTION
 *    This function extracts all vectors from supplied linestring/polygon rings, and then flips each vector until all point in the same direction.
 *    This function is useful for such operations as finding "slivers" between two polygons that are supposed to share a boundary.
 *    Once the function has flipped the vectors the calling function can analyse the vectors to do things like find duplicate segment
 *    which are part of a shared boundaries that are exactly the same (no sliver).
 *  RETURN
 *    geometry (GeometryCollection) - The set of flipped vectors.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_Flip_Segments(p_keep in integer default -1)
           Return &&INSTALL_SCHEMA..T_Segments Pipelined,

  /****m* T_GEOMETRY/ST_Rectangle2Polygon
  *  NAME
  *    ST_Rectangle2Polygon -- Converts Single Optimized Rectangle Exterior Ring Polygon element to its 5 vertex polygons.
  *  SYNOPSIS
  *    Member Function ST_Rectangle2Polygon()
  *             Return &&INSTALL_SCHEMA..T_Geometry Determinstic
  *  DESCRIPTION
  *    Converts a single exterior ring polygon described by an optimized rectangle to its 5 vertex equivalent polygon equivalent.
  *  EXAMPLE
  *    with data as (
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(0,0,20,20)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,3,5,2003,3),sdo_ordinate_array(0,0,20,20, 10,10,15,15)),0.005,3,1) as tgeom
  *        From Dual Union All
  *       Select T_GEOMETRY(sdo_geometry(2007,NULL,NULL,sdo_elem_info_array(1,1003,3, 5,2003,3, 9,2003,3, 13,1003,3),sdo_ordinate_array(0,0,20,20, 10,10,11,11, 5,5,7,7, 100,100,200,200)),0.005,1,1) as tgeom
  *         From Dual
  *    )
  *    select a.tGeom.ST_NumElements()                   as numElements,
  *           a.tGeom.ST_NumRings()                      as numRings,
  *           a.tgeom.ST_Rectangle2Polygon().ST_AsText() as tPoly
  *      from data a;
  *
  *    NUMELEMENTS NUMRINGS TPOLY
  *    ----------- -------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------
  *              1          1 POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0))
  *              1          2 MULTIPOLYGON (((0 0, 20 0, 20 20, 0 20, 0 0), (10 10, 10 15, 15 15, 15 10, 10 10)))
  *              2          4 MULTIPOLYGON (((0 0, 20 0, 20 20, 0 20, 0 0), (10 10, 10 11, 11 11, 11 10, 10 10), (5 5, 5 7, 7 7, 7 5, 5 5)), ((100 100, 200 100, 200 200, 100 200, 100 100)))
  *  RESULT
  *    polygon (T_GEOMETRY) -- Returns 5 vertex polygon.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June 2016 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Rectangle2Polygon
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_Polygon2Rectangle
  *  NAME
  *    ST_Polygon2Rectangle -- Converts optimized rectangles (rings) coded as 5 vertex/point polygons to rectangles.
  *  SYNOPSIS
  *    Member Function ST_Polygon2Rectangle()
  *             Return &&INSTALL_SCHEMA..T_Geometry Determinstic
  *  DESCRIPTION
  *    Converts any optimized rectangle equivalent 4 point polygon rings to their optimized rectangle equivalent.
  *  RESULT
  *    polygon (T_GEOMETRY) -- Returns polygon with rings converted to optimized rectangles where possible.
  *  EXAMPLE
  *    With Data as (
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(0,0,20,0,20,20,0,20,0,0)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,1,11,2003,1),sdo_ordinate_array(0,0,20,0,20,20,0,20,0,0, 5,5,5,10,10,10,10,5,5,5)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),
  *                                                   ((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select a.tgeom.ST_Polygon2Rectangle().geom as tPoly
  *      from data a;
  *
  *    TPOLY
  *    ------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(0,0,20,20))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3,5,2003,3),SDO_ORDINATE_ARRAY(0,0,20,20,5,5,10,10))
  *    SDO_GEOMETRY(2007,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3, 5,2003,3, 9,2003,3, 13,1003,3),SDO_ORDINATE_ARRAY(0,0, 20,20, 10,10, 11,11, 5,5, 7,7, 100,100, 200,200))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June 2016 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Polygon2Rectangle
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_DimInfo2Rectangle
  *  NAME
  *    ST_DimInfo2Rectangle -- Converts diminfo structure in XXX_SDO_GEOM_METADATA to a polygon with an optimized rectangle exterior ring.
  *  SYNOPSIS
  *    Static Function ST_DimInfo2Rectangle (
  *                       p_dim_array in mdsys.sdo_dim_array,
  *                       p_srid      in integer default NULL
  *                    )
  *             Return &&INSTALL_SCHEMA..T_Geometry Determinstic
  *  DESCRIPTION
  *    Converts any DIMINFO structure to a polygon by converted its SDO_DIM_ELEMENT X/Y sdo_lb/sdo_ub values to a single optimized rectangle exterior ring.
  *  RESULT
  *    polygon (T_GEOMETRY) -- Returns polygon with single optimized rectangle exterior ring.
  *  EXAMPLE
  *    select u.table_name, u.column_name, t_geometry.ST_DimInfo2Rectangle(u.diminfo,u.srid).geom as tgeom
  *      from user_sdo_geom_metadata u;
  *
  *    TABLE_NAME               COLUMN_NAME TGEOM
  *    ------------------------ ----------- --------------------------------------------------------------------------------------------------------------------------------------------------------
  *    LAND_PARCELS             GEOM        SDO_GEOMETRY(2003,2872,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(5979462.12680312,2085800.17222035,6024838.75881869,6024838.75881869))
  *    BASE_ADDRESSES           GEOM        SDO_GEOMETRY(2003,2872,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(5979545.39731847,2085905.79636266,6022316.7615783,6022316.7615783))
  *    BUILDING_FOOTPRINTS      GEOM        SDO_GEOMETRY(2003,2872,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(5980643.24426599,2086024.32003938,6024465.06003997,6024465.06003997))
  *    ROAD_CLINES              GEOM        SDO_GEOMETRY(2003,2872,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(5979762.10717428,2085798.82445402,6024890.06350611,6024890.06350611))
  *    WATER_AREAS              GEOM        SDO_GEOMETRY(2003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(-122.698410000002,37.44539000205,-122.049420001407,-122.049420001407))
  *    BANKS_3785               GEOM        SDO_GEOMETRY(2003,3785,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(16805978.88835578,-4028254.329242822,16823678.019474965,16823678.019474965))
  *    FEDERAL_LOWER_HOUSE_2016 GEOM        SDO_GEOMETRY(2003,4283,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(96.816766,-43.74051,159.109219,159.109219))
  *    PROJPOINT3D              GEOM        SDO_GEOMETRY(3003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(358312.903,-140.5,-140.5,5406991.847,5406991.847,359370.628))
  *    PROJPOINT2D              GEOM        SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(358312.903,359370.628,5406991.847,5406991.847))
  *    LAND_PARCELS             CENTROID    SDO_GEOMETRY(2003,2872,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(5979545.39704517,2085843.32119355,6022727.95207985,6022727.95207985))
  *
  *     10 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June 2016 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Static Function ST_Diminfo2Rectangle(p_dim_array in mdsys.sdo_dim_array,
                                       p_srid      in integer default NULL)
           Return &&INSTALL_SCHEMA..t_geometry Deterministic,

  /****m* T_GEOMETRY/ST_Geometry2DimInfo
  *  NAME
  *    ST_Geometry2DimInfo -- Converts any non-null geometry into an SDO_DIM_ARRAY capable of being written to USER_SDO_GEOM_METADATA by computing MBR of object.
  *  SYNOPSIS
  *    Static Function ST_Geometry2DimInfo (
  *                       p_dim_array in mdsys.sdo_dim_array,
  *                       p_srid      in integer default NULL
  *                    )
  *             Return &&INSTALL_SCHEMA..T_Geometry Determinstic
  *  DESCRIPTION
  *    Calculates a geometry's envelope and converts it to an SDO_DIM_ARRAY structure by populating its SDO_DIM_ELEMENT sdo_lb/sdo_ub values with computed envelope.
  *    If T_GEOMETRY's projected attribute is 1, X/Y are returned for the SDO_DIM_NAMES; if 0, LONG/LAT are returned as the SDO_DIM_NAMES
  *  RESULT
  *    polygon (T_GEOMETRY) -- Returns polygon with single optimized rectangle exterior ring.
  *  EXAMPLE
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),
  *                                                   ((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        From Dual
  *       Union All
  *      Select T_GEOMETRY(sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom
  *        From Dual
  *       Union All
  *     Select T_GEOMETRY(sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,projected=>0) as tgeom
  *       From Dual
  *    )
  *    select a.tgeom.ST_Geometry2Diminfo() as dimInfo
  *      from data a;
  *
  *    DIMINFO
  *    -----------------------------------------------------------------------------------------------------------------------------
  *    SDO_DIM_ARRAY(SDO_DIM_ELEMENT('X',   0,200,0.005), SDO_DIM_ELEMENT('Y',  0,200,0.005))
  *    SDO_DIM_ARRAY(SDO_DIM_ELEMENT('X',   0, 10,0.005), SDO_DIM_ELEMENT('Y',  0, 10,0.005), SDO_DIM_ELEMENT('Z',1,6,0.005))
  *    SDO_DIM_ARRAY(SDO_DIM_ELEMENT('LONG',0, 10,0.005), SDO_DIM_ELEMENT('LAT',0, 10,0.005), SDO_DIM_ELEMENT('Z',1,6,0.005))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June 2016 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Geometry2Diminfo
           Return mdsys.Sdo_Dim_Array Deterministic,

 /****m* T_GEOMETRY/ST_MBR
  *  NAME
  *    ST_MBR - Returns lower left and upper right coordinates of underlying geometry's minimum bounding rectangle (MBR).
  *  SYNOPSIS
  *    Member Function ST_MBR
  *             Return T_GEOMETRY Determinsitic
  *  EXAMPLE
  *    select T_Geometry(sdo_geometry('LINESTRING(0 0,0.1 0.1,0.5 0.5,0.8 0.8,1 1)',NULL),0.005,2,1).ST_MBR().geom as mbrGeom
  *      from dual;
  *
  *    MBRGEOM
  *    --------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(0,0,1,1))
  *  DESCRIPTION
  *    Supplied with a non-NULL geometry, this function returns the envelope or minimum bounding rectangle as a polygon geometry with one optimized rectangle exterior ring.
  *  RESULT
  *    MBR Geometry (T_GEOMETRY) -- Single Polygon with Optimized Rectangle Exterior Ring.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2011 - Converted to T_GEOMETRY from GEOM package.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_MBR
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

 /****m* T_GEOMETRY/ST_Envelope
  *  NAME
  *    ST_Envelope - Returns lower left and upper right coordinates of underlying geometry's envelope.
  *  SYNOPSIS
  *    Member Function ST_Envelope
  *             Return T_GEOMETRY Determinsitic
  *  RESULT
  *    MBR Geometry (T_GEOMETRY) -- Single Polygon with Optimized Rectangle Exterior Ring.
  *  DESCRIPTION
  *    Supplied with a non-NULL geometry, this function returns the envelope or minimum bounding rectangle as a polygon geometry with one optimized rectangle exterior ring.
  *  EXAMPLE
  *    select T_Geometry(sdo_geometry('LINESTRING(0 0,0.1 0.1,0.5 0.5,0.8 0.8,1 1)',NULL),0.005,2,1).ST_Envelope().geom as mbrGeom
  *      from dual;
  *
  *    MBRGEOM
  *    --------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(0,0,1,1))
  *  NOTES
  *    Wrapper over T_GEOMETRY.ST_MBR.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2005 - Original coding for GEOM package.
  *    Simon Greener - July 2011    - Converted to T_GEOMETRY from GEOM package.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Envelope
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_Polygon2Line
  *  NAME
  *    ST_Polygon2Line -- Converts Polygon or MultiPolygon rings to equivalent linestrings.
  *  SYNOPSIS
  *    Member Function ST_Polygon2Line()
  *             Return &&INSTALL_SCHEMA..T_Geometry Determinstic
  *  RESULT
  *    polygon (T_GEOMETRY) -- Returns polygon with rings converted to linestrings.
  *  DESCRIPTION
  *    Converts polygon rings to linestrings via MDSYS.SDO_UTIL.PolygonToLine function.
  *    Behavious is identical to underlying function.
  *  EXAMPLE
  *    With Data as (
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(0,0,20,0,20,20,0,20,0,0)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,1,11,2003,1),sdo_ordinate_array(0,0,20,0,20,20,0,20,0,0, 5,5,5,10,10,10,10,5,5,5)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),
  *                                                   ((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select a.tgeom.ST_Polygon2Line().ST_AsText() as line
  *      from data a;
  *
  *    LINE
  *    --------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    LINESTRING (0 0, 20 0, 20 20, 0 20, 0 0)
  *    MULTILINESTRING ((0 0, 20 0, 20 20, 0 20, 0 0), (5 5, 5 10, 10 10, 10 5, 5 5))
  *    MULTILINESTRING ((0 0, 20 0, 20 20, 0 20, 0 0), (10 10, 10 11, 11 11, 11 10, 10 10), (5 5, 5 7, 7 7, 7 5, 5 5), (100 100, 200 100, 200 200, 100 200, 100 100))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June 2016 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Polygon2Line
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_Multi
  *  NAME
  *    ST_Multi -- Converts any single sdo_geometry (point, line or polygon) to its multi equivalent (multipoint, multiline, multipolygon).
  *  SYNOPSIS
  *    Member Function ST_Multi ()
  *             Return &&INSTALL_SCHEMA..T_Geometry Determinstic
  *  RESULT
  *    MultiGeometry (T_GEOMETRY) -- If not already a multi geometry, returns multi-geometry object with 1 geometry;
  *  DESCRIPTION
  *    Converts underlying sdo_geometry objects that are single geometries (eg sdo_gtype of X001, X002, X003) to its multi equivalent (X005,X006,X007).
  *    Note that what is returned is a multi geometry with a one internal geometry.
  *  EXAMPLE
  *    With Data as (
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(0,0,20,0,20,20,0,20,0,0)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry(2003,NULL,NULL,sdo_elem_info_array(1,1003,1,11,2003,1),sdo_ordinate_array(0,0,20,0,20,20,0,20,0,0, 5,5,5,10,10,10,10,5,5,5)),0.005,3,1) as tgeom
  *        From Dual union all
  *      Select T_GEOMETRY(sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),
  *                                                   ((100 100,200 100,200 200,100 200,100 100)))',null),0.005,3,1) as tgeom
  *        From Dual
  *    )
  *    select case when a.tgeom.ST_GType() = 1  -- ST_AsText() converts 2005 with one point to POINT()
  *                then a.tgeom.ST_Multi().ST_AsTText()
  *                else a.tgeom.ST_Multi().ST_AsText()
  *            end as mGeom
  *      from data a;
  *
  *    MGEOM
  *    --------------------------------------------------------------------------------------------------------------
  *    &&INSTALL_SCHEMA..T_GEOMETRY(SDO_GEOMETRY(2005,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(0,0)); TOLERANCE(05)
  *    MULTILINESTRING ((0 0, 10 0, 10 5, 10 10, 5 10, 5 5))
  *    MULTILINESTRING ((-1 -1, 0 -1), (0 0, 10 0, 10 5, 10 10, 5 10, 5 5))
  *    MULTIPOLYGON (((0 0, 20 0, 20 20, 0 20, 0 0)))
  *    MULTIPOLYGON (((0 0, 20 0, 20 20, 0 20, 0 0)), ((10 10, 10 11, 11 11, 11 10, 10 10)))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June 2016 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Multi
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_Append
  *  NAME
  *    ST_Append -- Appends sdo_geometry to underlying sdo_geometry.
  *  SYNOPSIS
  *    Member Function ST_Append ()
  *             Return &&INSTALL_SCHEMA..T_Geometry Determinstic
  *  RESULT
  *    MultiGeometry (T_GEOMETRY) -- If not already a multi geometry, returns multi-geometry object with 1 geometry;
  *  DESCRIPTION
  *    Appends p_geom sdo_geometry value to underlying SELF.geom sdo_geometry.
  *    Can be used to append points to points, points to lines, lines to lines, lines to polygons etc.
  *    Detects if two adjacent vertices are within tolerance distance and merges if they are.
  *    For linestrings, p_concatenate mode of 0 appends without checking for duplicate end points and returns a multilinestring.
  *    If p_concatentate is 1 and an end/start point equality relationship is detected, only one coordinate is stored, and a single linestring returned.
  *    It is not implemented using SDO_UTIL.APPEND.
  *  NOTES
  *    Oracle's SDO_UTIL.APPEND supports 2 and 3D geometies but SDO_UTIL.CONCAT_LINES only supports 2D data.
  *    Also, if underlying linestring geometry is measured, SDO_LRS.CONCATENATE_GEOM_SEGMENTS must be called.
  *    This function implements all these Oracle functions under one "umbrella".
  *  EXAMPLE
  *    With data as (
  *      select t_geometry(SDO_GEOMETRY(3001,NULL,SDO_POINT_TYPE(157503.148,6568556.703,50.647),null,null)) as tPoint from dual
  *    )
  *    select 'Point+Point'      as test, a.tPoint.ST_Append(SDO_GEOMETRY(3001,null,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(158506.165,6568585.072,26.556))).geom as geom
  *      from data a union all
  *    select 'Point+SdoPoint'   as test, a.tPoint.ST_Append(SDO_GEOMETRY(3001,null,SDO_POINT_TYPE(158506.165,6568585.072,26.556),null,null)).geom as geom
  *      from data a union all
  *    select 'Point+MultiPoint' as test, a.tPoint.ST_Append(SDO_GEOMETRY(3005,null,NULL,SDO_ELEM_INFO_ARRAY(1,1,2),SDO_ORDINATE_ARRAY(157500.896,6568571.813,38.453, 158506.165,6568585.072,26.556))).geom as geom
  *      from data a;
  *
  *    TEST             GEOM
  *    ---------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    Point+Point      SDO_GEOMETRY(3005,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,2),SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,158506.165,6568585.072,26.556))
  *    Point+SdoPoint   SDO_GEOMETRY(3005,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,2),SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,158506.165,6568585.072,26.556))
  *    Point+MultiPoint SDO_GEOMETRY(3005,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,3),SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,157500.896,6568571.813,38.453,158506.165,6568585.072,26.556))
  *
  *    select 'Two 3002 Lines with common point => 3002/3006' as test,
  *           case when t.IntValue = 0 then 'Append' else 'Concatenate' end as testMode,
  *           t_geometry(SDO_GEOMETRY(3002,null,NULL,
  *                               SDO_ELEM_INFO_ARRAY(1,2,1),
  *                               SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,157512.499,6568585.998,15.573)))
  *                .ST_Append(SDO_GEOMETRY(3002,null,NULL,
  *                               SDO_ELEM_INFO_ARRAY(1,2,1),
  *                               SDO_ORDINATE_ARRAY(                              157512.499,6568585.998,15.573,157519.107,6568582.067,2.382)),
  *                           t.IntValue).geom as geom
  *      from dual a,
  *           table(tools.generate_series(0,1,1)) t
  *    union all
  *    select 'Two 2002 Lines with common point => 2002/2006' as test,
  *           case when t.IntValue = 0 then 'Append' else 'Concatenate' end as testMode,
  *           t_geometry(SDO_GEOMETRY(2002,null,NULL,
  *                               SDO_ELEM_INFO_ARRAY(1,2,1),
  *                               SDO_ORDINATE_ARRAY(157503.148,6568556.703,157512.499,6568585.998)))
  *                .ST_Append(SDO_GEOMETRY(2002,null,NULL,
  *                               SDO_ELEM_INFO_ARRAY(1,2,1),
  *                               SDO_ORDINATE_ARRAY(                       157512.499,6568585.998,157519.107,6568582.067)),
  *                           t.IntValue).geom
  *      from dual a,
  *           table(TOOLS.generate_series(0,1,1)) t
  *    union all
  *    select 'Two 3002 with no common point => 3006' as test,
  *           'Append' as test_mode,
  *           t_geometry(SDO_GEOMETRY(3002,null,NULL,
  *                               SDO_ELEM_INFO_ARRAY(1,2,1),
  *                               SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,157512.499,6568585.998,15.573)))
  *                .ST_Append(SDO_GEOMETRY(3002,null,NULL,
  *                               SDO_ELEM_INFO_ARRAY(1,2,1),
  *                               SDO_ORDINATE_ARRAY(157520.228,6568574.745,1.46,157512.15,6568564.565,28.219)),0).geom
  *      from dual
  *    union all
  *    select 'Two 2002 with no common point => 2006' as test,
  *           'Append' as test_mode,
  *           t_geometry(SDO_GEOMETRY(2002,null,NULL,
  *                               SDO_ELEM_INFO_ARRAY(1,2,1),
  *                               SDO_ORDINATE_ARRAY(157503.148,6568556.703,157512.499,6568585.998)))
  *                .ST_Append(SDO_GEOMETRY(2002,null,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                               SDO_ORDINATE_ARRAY(157520.228,6568574.745,157512.15,6568564.565)),0).geom
  *      from dual;
  *
  *    TEST                                          TESTMODE    GEOM
  *    --------------------------------------------- ----------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    Two 3002 Lines with common point => 3002/3006 Append      SDO_GEOMETRY(3006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,7,2,1),SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,157512.499,6568585.998,15.573,157512.499,6568585.998,15.573,157519.107,6568582.067,2.382))
  *    Two 3002 Lines with common point => 3002/3006 Concatenate SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,157512.499,6568585.998,15.573,157519.107,6568582.067,2.382))
  *    Two 2002 Lines with common point => 2002/2006 Append      SDO_GEOMETRY(2006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,5,2,1),SDO_ORDINATE_ARRAY(157503.148,6568556.703,157512.499,6568585.998,157512.499,6568585.998,157519.107,6568582.067))
  *    Two 2002 Lines with common point => 2002/2006 Concatenate SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(157503.148,6568556.703,157512.499,6568585.998,157519.107,6568582.067))
  *    Two 3002 with no common point => 3006         Append      SDO_GEOMETRY(3006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,7,2,1),SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,157512.499,6568585.998,15.573,157520.228,6568574.745,1.46,157512.15,6568564.565,28.219))
  *    Two 2002 with no common point => 2006         Append      SDO_GEOMETRY(2006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,5,2,1),SDO_ORDINATE_ARRAY(157503.148,6568556.703,157512.499,6568585.998,157520.228,6568574.745,157512.15,6568564.565))
  *
  *     6 rows selected
  *
  *    select case when t.IntValue = 0
  *                then 'Append Linestring 2002 and Point 2001 => 2004'
  *                else 'Concat Linestring 2002 and Point 2001 => 2002'
  *            end as test,
  *           t_geometry(SDO_GEOMETRY(2002,null,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(157503.148,6568556.703, 157512.499,6568585.998)))
  *                .ST_Append(SDO_GEOMETRY(2001,null,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(157512.499,6568585.998)),
  *                           t.IntValue).geom as geom
  *      from table(TOOLS.generate_series(0,1,1)) t
  *     Union all
  *    select case when t.IntValue = 0
  *                then 'Append Linestring 3002 and Point 3001 => 3004'
  *                else 'Concat Linestring 3002 and Point 3001 => 3002'
  *            end as test,
  *           t_geometry(SDO_GEOMETRY(3002,null,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647, 157512.499,6568585.998,15.573)))
  *                .ST_Append(SDO_GEOMETRY(3001,null,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(                               157512.499,6568585.998,15.573)),
  *                           t.IntValue).geom as geom
  *      from table(TOOLS.generate_series(0,1,1)) t;
  *
  *    TEST                                          GEOM
  *    --------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    Append Linestring 3002 and Point 3001 => 3004 SDO_GEOMETRY(3004,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1, 1,1,1),SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,157512.499,6568585.998,15.573,157512.499,6568585.998,15.573))
  *    Concat Linestring 3002 and Point 3001 => 3002 SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),       SDO_ORDINATE_ARRAY(157503.148,6568556.703,50.647,157512.499,6568585.998,15.573))
  *    Append Linestring 2002 and Point 2001 => 2004 SDO_GEOMETRY(2004,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,1,1,1), SDO_ORDINATE_ARRAY(157503.148,6568556.703,157512.499,6568585.998,157512.499,6568585.998))
  *    Concat Linestring 2002 and Point 2001 => 2002 SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),       SDO_ORDINATE_ARRAY(157503.148,6568556.703,157512.499,6568585.998))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June 2016 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Append(p_geom        in mdsys.sdo_geometry,
                            p_concatenate in integer default 0)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

-- ========================================================================================
-- =============================== Transformers ===========================================
-- ========================================================================================

/****m* T_GEOMETRY/ST_Rotate(p_angle p_dir p_rotate_point p_line1)
 *  NAME
 *    ST_Rotate -- Function which rotates the underlying geometry.
 *  SYNOPSIS
 *    Member Function ST_Rotate (
 *                       p_angle        in number,
 *                       p_dir          in integer,
 *                       p_rotate_point in mdsys.sdo_geometry,
 *                       p_line1        in mdsys.sdo_geometry
 *                    )
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
 *  DESCRIPTION
 *    Function which rotates the underlying geometry around a supplied rotation point p_rotate_point a required angle in radians.
 *    See NOTES for valid parameter values.
 *    Supports 2D and 3D geometry rotation.
 *  ARGUMENTS
 *    p_angle              (number) - Rotation angle expressed in degrees (see COGO.ST_Radians and COGO.ST_Degrees).
 *    p_dir               (integer) - Rotation parameter for x(0), y(1), or z(2)-axis roll.
 *                                    You cannot set p_dir => 0, 1 or 2, only -1, -2, -3. They don't see to affect the result.
 *    p_rotate_point (sdo_geometry) - XY/2D Point geometry
 *    p_line1        (sdo_geometry) - Y ordinate of rotation point.
 *  RESULT
 *    geometry -- Input geometry rotated by supplied values.
 *  NOTES
 *    Is wrapper over mdsys.SDO_UTIL.AffineTransforms
 *    For 2D geometry rotation, p_angle and p_rotate_point must not be null.
 *    For 3D geometry rotation, p_angle must not be null
 *    For 3D geometry rotation, both p_dir and p_line1 cannot be null
 *    For 3D geometries, rotation uses either:
 *      1. the angle and dir values, or
 *      2. the angle and line1 values.
 *  EXAMPLE
 *    With testGeom as (
 *      select T_GEOMETRY(mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,2,4,8,4,12,4,12,10,8,10,5,14)),005,2,1) as geom,
 *             SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0, 2,4,22.22, 8,4,374, 12,4,59.26, 12,10,747, 8,10,92.59, 5,14,100)) as geom3D,
 *             mdsys.sdo_geometry(2001,null,sdo_point_type(2,2,null),null,null) as rotatePoint
 *        from dual
 *    )
 *    select 'ST_Rotate(45/Dir/rPoint/Line1)' as rotate,
 *           a.geom.ST_Rotate(p_angle=>45,p_dir=>-1,p_rotate_point=>rotatePoint, p_line1=>null)
 *                 .ST_Round(a.geom.dPrecision,a.geom.dPrecision,2,2).geom as geom
 *      from testGeom a
 *      Union All
 *    select 'ST_Rotate3D(45/Dir/rPoint/Line1)' as rotate,
 *           a.geom3d.ST_Rotate(p_angle=>45,p_dir=>-1,p_rotate_point=>rotatePoint, p_line1=>null)
 *                 .ST_Round(a.geom.dPrecision,a.geom.dPrecision,2,2).geom as geom
 *      from testGeom a;
 *
 *    AFUNCTION                GEOM
 *    -------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------
 *    ST_Rotate(45/Dir/rPoint/line1)   SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0.59,3.41,4.83,7.66,7.66,10.49,3.41,14.73,0.59,11.9,-4.36,12.61))
 *    ST_Rotate3D(45/Dir/rPoint/line1) SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2.0,2.0,0.0, 0.59,3.41,22.22, 4.83,7.66,374.0, 7.66,10.49,59.26, 3.41,14.73,747.0, 0.59,11.9,92.59, -4.36,12.61,100.0))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2015 - New implementation to replace original PLSQL based rotation function.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Rotate (p_angle        in number,
                             p_dir          in integer,
                             p_rotate_point in mdsys.sdo_geometry,
                             p_line1        in mdsys.sdo_geometry)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

/****m* T_GEOMETRY/ST_Rotate(p_angle p_rx p_rx)
 *  NAME
 *    ST_Rotate -- Function which rotates the underlying geometry around a provided point or its centre.
 *  SYNOPSIS
 *    Member Function ST_Rotate (
 *                       p_angle in number,
 *                       p_rx    in number,
 *                       p_ry    in number
 *                    )
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
 *  DESCRIPTION
 *    Function which rotates the underlying geometry by the provided p_angle angle around a supplied rotation point p_rx,p_rx.
 *    If p_rx/p_ry is null, the centre of the geometry's envelope/MBR is chosen.
 *    Because of limited parameters this version only support 2D geometries.
 *    If underlying geometry is a point and no p_rx/p_rx values are provided, the same point is returned.
 *  ARGUMENTS
 *    p_angle (number) - Rotation angle expressed in degrees.
 *    p_rx    (number) - X ordinate of rotation point.
 *    p_ry    (number) - Y ordinate of rotation point.
 *  RESULT
 *    geometry -- Input geometry rotated by supplied values.
 *  NOTES
 *    Is wrapper over ST_Rotate(p_angle,p_dir,p_rotate_point,p_line1)
 *  EXAMPLE
 *    With testGeom as (
 *      select T_GEOMETRY(mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,2,4,8,4,12,4,12,10,8,10,5,14)),005,2,1) as geom,
 *             mdsys.sdo_geometry(2001,null,sdo_point_type(2,2,null),null,null) as rotatePoint
 *        from dual
 *    )
 *    Select 'ST_Rotate(90,null,null)' as rotate,
 *           a.geom.ST_Rotate(p_angle=>90,p_rx=>null,p_ry=>null)
 *                 .ST_Round(a.geom.dprecision,a.geom.dprecision,2,2).geom as geom
 *      From testGeom a
 *     Union All
 *    Select 'ST_Rotate(90,2,2)' as rotate,
 *           a.geom.ST_Rotate(p_angle=>90,p_rx=>a.rotatePoint.Sdo_Point.Y,p_ry=>a.rotatePoint.Sdo_Point.Y)
 *           .ST_Round(a.geom.dprecision,a.geom.dprecision,2,2).geom as geom
 *      From testGeom a;
 *
 *    ROTATE                  GEOM
 *    ----------------------- -------------------------------------------------------------------------------------------------------------
 *    ST_Rotate(90,null,null) SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(13,3,11,3,11,9,11,13,5,13,5,9,1,6))
 *    ST_Rotate(90,2,2)       SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0,2,0,8,0,12,-6,12,-6,8,-10,5))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2015 - New implementation to replace original PLSQL based rotation function.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Rotate (p_angle in number,
                             p_rx    in number,
                             p_ry    in number)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

/****m* T_GEOMETRY/ST_Rotate(p_angle p_rotate_point)
 *  NAME
 *    ST_Rotate -- Function which rotates the underlying geometry around a provided point or its centre.
 *  SYNOPSIS
 *    Member Function ST_Rotate (
 *                       p_angle        in number,
 *                       p_rotate_point in mdsys.sdo_geometry
 *                    )
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
 *  DESCRIPTION
 *    Function which rotates the underlying geometry by the provided p_angle angle (degrees see COGO.ST_Radians and COGO.ST_Degrees) around a supplied rotation point p_rotate_point.
 *    If p_rotate_point is null, the centre of the geometry's envelope/MBR is chosen.
 *    Because of limited parameters this version only support 2D geometries.
 *    If underlying geometry is a point and no p_rotate_point is provided, the same point is returned.
 *  ARGUMENTS
 *    p_angle (number) - Rotation angle expressed in radians.
 *    p_rx    (number) - X ordinate of rotation point.
 *    p_ry    (number) - Y ordinate of rotation point.
 *  RESULT
 *    geometry -- Input geometry rotated by supplied values.
 *  NOTES
 *    Is wrapper over ST_Rotate(p_angle,p_dir,p_rotate_point,p_line1)
 *  EXAMPLE
 *    With testGeom as (
 *      select T_GEOMETRY(mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,2,4,8,4,12,4,12,10,8,10,5,14)),005,2,1) as geom,
 *             mdsys.sdo_geometry(2001,null,sdo_point_type(2,2,null),null,null) as rotatePoint
 *        from dual
 *    )
 *    select 'ST_Rotate(90,NULL)' as rotate,
 *           a.geom.ST_Rotate(p_angle=>90,p_rotate_point=>null)
 *                 .ST_Round(a.geom.dprecision,a.geom.dprecision,2,2).geom as geom
 *      From testGeom a
 *     Union All
 *    select 'ST_Rotate(90,POINT)' as rotate,
 *           a.geom.ST_Rotate(p_angle=>90,p_rotate_point=>rotatePoint)
 *                 .ST_Round(a.geom.dprecision,a.geom.dprecision,2,2).geom as geom
 *      from testGeom a ;
 *
 *    ROTATE              GEOM
 *    ------------------- -------------------------------------------------------------------------------------------------------------------
 *    ST_Rotate(90,NULL)  SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(13,3, 11,3, 11,9, 11,13, 5,13, 5,9, 1,6))
 *    ST_Rotate(90,POINT) SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2, 0,2, 0,8, 0,12, -6,12, -6,8, -10,5))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2015 - New implementation to replace original PLSQL based rotation function.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Rotate (p_angle        in number,
                             p_rotate_point in mdsys.sdo_geometry)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

/****m* T_GEOMETRY/ST_Rotate(p_angle)
 *  NAME
 *    ST_Rotate -- Function which rotates the underlying geometry around the centre of its MBR.
 *  SYNOPSIS
 *    Member Function ST_Rotate (
 *                       p_angle in number
 *                    )
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
 *  DESCRIPTION
 *    Function which rotates the underlying geometry by the provided p_angle angle (degrees see COGO.ST_Radians and COGO.ST_Degrees) around the centre of the geometry's MBR.
 *    Because of limited parameters this version only support 2D geometries.
 *    If underlying geometry is a point, the same point is returned.
 *  ARGUMENTS
 *    p_angle              (number) - Rotation angle expressed in radians.
 *    p_rotate_point (sdo_geometry) - Point around which underlying geometry is rotated p_angle degrees
 *  RESULT
 *    geometry -- Input geometry rotated by supplied values.
 *  NOTES
 *    Is wrapper over ST_Rotate(p_angle,p_dir,p_rotate_point,p_line1)
 *  EXAMPLE
 *    With testGeom as (
 *      select T_GEOMETRY(mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,2,4,8,4,12,4,12,10,8,10,5,14)),005,2,1) as geom
 *        from dual
 *    )
 *    select 'ST_Rotate(90)' as rotate,
 *           a.geom.ST_Rotate(p_angle=>90)
 *                 .ST_Round(a.geom.dprecision,a.geom.dprecision,2,2).geom as geom
 *      From testGeom a ;
 *
 *    ROTATE            GEOM
 *    ----------------- -------------------------------------------------------------------------------------------------------------------
 *    ST_Rotate(90)     SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(13,3, 11,3, 11,9, 11,13, 5,13, 5,9, 1,6))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2015 - New implementation to replace original PLSQL based rotation function.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Rotate (p_angle in number)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  -- **********************************************************************************

/****m* T_GEOMETRY/ST_Scale(p_sx p_sy p_sz p_scale_point)
 *  NAME
 *    ST_Scale -- Function which scales the ordinates of the underlying geometry.
 *  SYNOPSIS
 *    Member Function ST_Scale (p_sx          in number,
 *                              p_sy          in number,
 *                              p_sz          in number default null,
 *                              p_scale_point in mdsys.sdo_geometrydefault null)
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
 *  DESCRIPTION
 *    Function which scales the ordinates of the underlying geometry using the provided scale factors: p_sx, p_sy, p_sz.
 *    If any of p_sx, p_sy, p_sz are null 0.0 is substituted for their value (no effect).
 *    p_scale_point is a point on the input geometry about which to perform the scaling.
 *    If p_scale_point is null a zero point (with 0,0 or 0,0,0 ordinates) is used to scale the geometry about the origin.
 *    If p_scale_point is not null, it should be a nonzero point with ordinates for scaling about a point other than the origin.
 *  ARGUMENTS
 *    p_sx          (number)       - Scale factor for X ordinates.
 *    p_sy          (number)       - Scale factor for Y ordinates.
 *    p_sz          (number)       - Scale factor for Z ordinates.
 *    p_scale_point (sdo_geometry) - Scale point.
 *  RESULT
 *    geometry -- Input geometry scaled using supplied values.
 *  NOTES
 *    Is wrapper over mdsys.SDO_UTIL.AffineTransforms
 *  EXAMPLE
 *    With testGeom as (
 *      select T_GEOMETRY(mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,2,4,8,4,12,4,12,10,8,10,5,14)),0.005,2,1) as tgeom,
 *             mdsys.sdo_geometry(2001,null,sdo_point_type(2,2,null),null,null) as scale_point
 *        from dual
 *       Union All
 *      select T_GEOMETRY(mdsys.sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,1, 2,4,2, 8,4,3, 12,4,4, 12,10,5, 8,10,6, 5,14,7)),0.005,2,1) as tgeom,
 *             mdsys.sdo_geometry(3001,null,sdo_point_type(2,2,2),null,null) as scale_point
 *        from dual
 *    )
 *    select a.tgeom.ST_CoordDimension() as coordDimension,
 *           'ST_Scale(p_sx,p_sy,p_sz,p_scale_point)' as ScaleTest,
 *           a.tgeom.ST_Scale(p_sx=>2,p_sy=>2,p_sz=>case when a.tgeom.ST_CoordDimension()=2 then null else 0.1 end,p_scale_point=>a.scale_point).geom as geom
 *      from testGeom a
 *
 *    COORDDIMENSION SCALETEST                              GEOM
 *    -------------- -----------------------------------    ----------------------------------------------------------------------------------------------------------------------------------------
 *                 2 ST_Scale(p_sx,p_sy,p_sz,p_scale_point) SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,2,6,14,6,22,6,22,18,14,18,8,26))
 *                 3 ST_Scale(p_sx,p_sy,p_sz,p_scale_point) SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,1.9,2,6,2,14,6,2.1,22,6,2.2,22,18,2.3,14,18,2.4,8,26,2.5))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2015 - New implementation to replace original PLSQL based rotation function.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Scale (p_sx          in number,
                            p_sy          in number,
                            p_sz          in number default null,
                            p_scale_point in mdsys.sdo_geometry default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

/****m* T_GEOMETRY/ST_Translate(p_tx p_ty p_tz)
 *  NAME
 *    ST_Translate -- Function which translates the underlying geometry to a new location.
 *  SYNOPSIS
 *    Member Function ST_Translate (p_tx in number,
 *                                  p_ty in number,
 *                                  p_tz in number default null )
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
 *  DESCRIPTION
 *    Function which translates the underlying geometry to a new location, by applying the translation values to its ordinates.
 *    The function MOVES the geometry to a new location.
 *  ARGUMENTS
 *    p_tx (number) - Translation factor for X ordinates.
 *    p_ty (number) - Translation factor for Y ordinates.
 *    p_tz (number) - Translation factor for Z ordinates (if null, the Z ordinate is not changed).
 *  RESULT
 *    geometry -- Input geometry translated (moved) using supplied values.
 *  NOTES
 *    Is wrapper over mdsys.SDO_UTIL.AffineTransforms
 *  EXAMPLE
 *    With testGeom as (
 *      select T_GEOMETRY(mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,2,4,8,4,12,4,12,10,8,10,5,14)),0.005,2,1) as tgeom
 *        from dual
 *       Union All
 *      select T_GEOMETRY(mdsys.sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,1, 2,4,2, 8,4,3, 12,4,4, 12,10,5, 8,10,6, 5,14,7)),0.005,2,1) as tgeom
 *        from dual
 *    )
 *    select a.tgeom.ST_CoordDimension() as coordDimension,
 *           'ST_Translate(p_tx,p_ty,p_tz)' as TranslateTest,
 *           a.tgeom.ST_Translate(p_tx=>10.0,p_ty=>10.0,p_tz=>case when a.tgeom.ST_CoordDimension()=2 then null else 5.0 end).geom as geom
 *      from testGeom a;
 *
 *    COORDDIMENSION TRANSLATETEST                GEOM
 *    -------------- ---------------------------- --------------------------------------------------------------------------------------------------------------------------------------
 *                 2 ST_Translate(p_tx,p_ty,p_tz) SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(12,12,12,14,18,14,22,14,22,20,18,20,15,24))
 *                 3 ST_Translate(p_tx,p_ty,p_tz) SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(12,12,6,12,14,7,18,14,8,22,14,9,22,20,10,18,20,11,15,24,12))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2015 - New implementation to replace original PLSQL based rotation function.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Translate (p_tx in number,
                                p_ty in number,
                                p_tz in number default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

/****m* T_GEOMETRY/ST_Reflect(p_reflect_geom p_reflect_plane)
 *  NAME
 *    ST_Reflect -- Function which reflects the underlying geometry to a new location using the provided parameters.
 *  SYNOPSIS
 *    Member Function ST_Reflect (p_reflect_geom  in mdsys.sdo_geometry,
 *                                p_reflect_plane in number default -1)
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
 *  DESCRIPTION
 *    Function which reflects the underlying geometry to a new location, by reflecting around or across p_reflect_geom depending on p_reflect_plane.
 *  ARGUMENTS
 *    p_reflect_geom  (sdo_geometry) -- Reflection geometry
 *    p_reflect_plane (number)       -- Whether to reflect underlying geometry across p_reflect_geom.
 *  RESULT
 *    geometry -- Input geometry reflected using supplied values.
 *  NOTES
 *    Is wrapper over mdsys.SDO_UTIL.AffineTransforms
 *  EXAMPLE
 *    With testGeom as (
 *      select T_GEOMETRY(mdsys.sdo_geometry('POINT(10 10)',null),0.005,2,1) as tgeom,
 *             mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(10,0,0,10)) as reflect_geom
 *        from dual
 *    )
 *    select 'ST_Reflect(p_reflect_geom,-1)' as ReflectTest,
 *           a.tgeom.ST_Reflect(p_reflect_geom=>a.reflect_geom,p_reflect_plane=>-1)
 *           .ST_Round(2,2,1,1)
 *           .ST_AsText()  as geom
 *      from testGeom a;
 *
 *    REFLECTTEST                   GEOM
 *    ----------------------------- ---------------
 *    ST_Reflect(p_reflect_geom,-1) POINT (0.0 0.0)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2015 - New implementation to replace original PLSQL based rotation function.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Reflect (p_reflect_geom  in mdsys.sdo_geometry,
                              p_reflect_plane in number default -1)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

/****m* T_GEOMETRY/ST_RotTransScale(p_reflect_geom p_reflect_plane)
 *  NAME
 *    ST_RotTransScale -- Function which reflects the underlying geometry to a new location using the provided parameters.
 *  SYNOPSIS
 *    Member Function ST_RotTransScale (p_angle     in number,
 *                                      p_rs_point  in mdsys.sdo_geometry,
 *                                      p_sx        in number,
 *                                      p_sy        in number,
 *                                      p_sz        in number,
 *                                      p_tx        in number,
 *                                      p_ty        in number,
 *                                      p_tz        in number)
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
 *  DESCRIPTION
 *    Function which applies a Rotation/Scale and Translate to the underlying geometry as a single operation.
 *    If equivalent of applying individual methods in one:
 *    select a.tgeom.ST_Scale(....).ST_Translate(....).ST_Rotate(....) from ...
 *    But is more efficient as it requires only one call to the mdsys.SDO_UTIL.AffineTransforms function.
 *  ARGUMENTS
 *    p_angle          (number) - Rotation angle expressed in radians.
 *    p_rs_point (sdo_geometry) - Single Rotate and Scale point.
 *    p_sx             (number) - Scale factor for X ordinates.
 *    p_sy             (number) - Scale factor for Y ordinates.
 *    p_sz             (number) - Scale factor for Z ordinates.
 *    p_tx             (number) - Translation factor for X ordinates.
 *    p_ty             (number) - Translation factor for Y ordinates.
 *    p_tz             (number) - Translation factor for Z ordinates (if null, the Z ordinate is not changed).
  RESULT
 *    geometry -- Input geometry transformed using supplied values.
 *  NOTES
 *    Is wrapper over mdsys.SDO_UTIL.AffineTransforms
 *  EXAMPLE
 *    With testGeom as (
 *      select T_GEOMETRY(mdsys.sdo_geometry('POINT(10 10)',null),0.005,2,1) as tgeom,
 *             mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(10,0,0,10)) as reflect_geom
 *        from dual
 *    )
 *    select 'ST_RotTransScale(p_reflect_geom,-1)' as ReflectTest,
 *           a.tgeom.ST_RotTransScale(p_reflect_geom=>a.reflect_geom,p_reflect_plane=>-1)
 *           .ST_Round(2,2,1,1)
 *           .ST_AsText()  as geom
 *      from testGeom a;
 *
 *    REFLECTTEST                   GEOM
 *    ----------------------------- ---------------
 *    ST_RotTransScale(,-1)         POINT (0.0 0.0)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2015 - New implementation to replace original PLSQL based rotation function.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_RotTransScale (p_angle     in number,
                                    p_rs_point  in mdsys.sdo_geometry,
                                    p_sx        in number,
                                    p_sy        in number,
                                    p_sz        in number,
                                    p_tx        in number,
                                    p_ty        in number,
                                    p_tz        in number)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_Affine
  *  NAME
  *    ST_Affine -- Applies a 3d affine transformation to the geometry to do things like translate, rotate, scale in one step.
  *  SYNOPSIS
  *    Member Function ST_Affine (
  *       p_a    in number,
  *       p_b    in number,
  *       p_c    in number,
  *       p_d    in number,
  *       p_e    in number,
  *       p_f    in number,
  *       p_g    in number,
  *       p_h    in number,
  *       p_i    in number,
  *       p_xoff in number,
  *       p_yoff in number,
  *       p_zoff in number)
  *       Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
  *  DESCRIPTION
  *    Applies a 3d affine transformation to the geometry to do things like translate, rotate, scale in one step.
  *    To apply a 2D affine transformation only supply a, b, d, e, xoff, yoff
  *    The vertices are transformed as follows:
  *       x' = a*x + b*y + c*z + xoff
  *       y' = d*x + e*y + f*z + yoff
  *       z' = g*x + h*y + i*z + zoff
  *  ARGUMENTS
  *    a, b, c, d, e, f, g, h, i, xoff, yoff, zoff (all number s)
  *    Represent the transformation matrix
  *    -----------------
  *    | a  b  c  xoff |
  *    | d  e  f  yoff |
  *    | g  h  i  zoff |
  *    | 0  0  0     1 |
  *    -----------------
  *  RESULT
  *    geometry (T_GEOMETRY) -- Transformed geometry
  *  EXAMPLE
  *  SELECT t_geometry(sdo_geometry(3001,null,sdo_point_type(1,2,3),null,null),0.05,1,1)
  *          .ST_Affine(p_a=>COS(COGO.pi()),
  *                     p_b=>0.0-SIN(COGO.pi()),
  *                     p_c=>0.0,
  *                     p_d=>SIN(COGO.pi()),
  *                     p_e=>COS(COGO.pi()),
  *                     p_f=>0.0,
  *                     p_g=>0.0,
  *                     p_h=>0.0,
  *                     p_i=>1.0,
  *                     p_xoff=>0.0,
  *                     p_yoff=>0.0,
  *                     p_zoff=>0.0).geom As affine_geom
  *  	FROM dual;
  *
  *  AFFINE_GEOM
  *  --------------------------------------------------------------
  *  SDO_GEOMETRY(3001,NULL,SDO_POINT_TYPE(-1.0,-2.0,3.0),NULL,NULL)
  *
  *  --Rotate a 3d line 180 degrees in both the x and z axis
  *  SELECT f.the_geom
  *          .ST_Affine(cos(COGO.PI()), -sin(COGO.PI()), 0, sin(COGO.PI()), cos(COGO.PI()), -sin(COGO.PI()), 0, sin(COGO.PI()), cos(COGO.PI()), 0, 0, 0).geom as affine_geom
  *  	FROM (select T_Geometry(sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,4,3)),0.005,2,1) As the_geom
  *            from dual
  *         ) f;
  *
  *  AFFINE_GEOM
  *  -----------
  *  SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(-1.0,-2.0,-3.0, -1.0,-4.0,-3.0))
  *
  *  -- Rotate a 3d line 180 degrees about the z axis.
  *  select t_geometry(sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3, 1,4,3)),0.05,1,1)
  *          .ST_Affine(p_a=>COS(COGO.pi()),
  *                     p_b=>0.0-SIN(COGO.pi()),
  *                     p_c=>0.0,
  *                     p_d=>SIN(COGO.pi()),
  *                     p_e=>COS(COGO.pi()),
  *                     p_f=>0.0,
  *                     p_g=>0.0,
  *                     p_h=>0.0,
  *                     p_i=>1.0,
  *                     p_xoff=>0.0,
  *                     p_yoff=>0.0,
  *                     p_zoff=>0.0).geom
  *            As affine_geom
  *  	from dual;
  *
  *  AFFINE_GEOM
  *  --------------------------------------------------------------------------------------------------------
  *  SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(-1.0,-2.0,3.0, -1.0,-4.0,3.0))
  *  REQUIRES
  *    SYS.UTL_NLA Package
  *    SYS.UTL_NLA_ARRAY_DBL Type
  *    SYS.UTL_NLA_ARRAY_INT Type
  *  NOTES
  *    Cartesian arithmetic only
  *    Not for Oracle XE. Only 10g and above.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Feb 2009 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Affine(p_a    in number,
                            p_b    in number,
                            p_c    in number,
                            p_d    in number,
                            p_e    in number,
                            p_f    in number,
                            p_g    in number,
                            p_h    in number,
                            p_i    in number,
                            p_xoff in number,
                            p_yoff in number,
                            p_zoff in number)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_FixOrdinates
  *  NAME
  *    ST_FixOrdinates -- Allows calculations expressed as formula to change the ordinates of the underlying Geometry
  *  SYNOPSIS
  *    Member Function ST_FixOrdinates(
  *                       p_x_formula in varchar2,
  *                       p_y_formula in varchar2,
  *                       p_z_formula in varchar2 := null,
  *                       p_w_formula in varchar2 := null
  *                    )
  *             Return mdsys.sdo_geometry Deterministic,
  *  ARGUMENTS
  *    p_x_formula (varchar2) -- Mathematical formula to be applied to X ordinate
  *    p_y_formula (varchar2) -- Mathematical formula to be applied to Y ordinate
  *    p_z_formula (varchar2) -- Mathematical formula to be applied to Z ordinate
  *    p_w_formula (varchar2) -- Mathematical formula to be applied to W/M ordinate
  *  RESULT
  *    Modified Geometry (T_Geometry) -- Original geometry with modified ordinates
  *  DESCRIPTION
  *    The formula may reference the ordinates of the geometry via the columns X, Y, Z and W
  *    (the T_Vertex fields produced by SDO_Util.GetVertices function) keywords.
  *    These keywords can be referred to multiple times in a formula
  *    (see 'ROUND ( z / ( z * dbms_random.value(1,10) ), 3 )' in the example
  *    that processes a 3D linestring below).
  *    Since the formula are applied via SQL even Oracle intrinsic columns like ROWNUM
  *    can be used (see '(rownum * w)' below). One can also use any Oracle function,
  *    eg RANDOM: this includes functions in packages such as DBMS_RANDOM
  *    eg 'ROUND ( Y * dbms_random.value ( 1,1000) ,3 )') as well.
  *  EXAMPLE
  *    select t_geometry(SDO_Geometry('POINT(1.25 2.44)'),0.005,2,1)
  *             .ST_FixOrdinates(
  *                 'ROUND(X * 3.141592653,3)',
  *                 'ROUND(Y * dbms_random.value(1,1000),3)',
  *                 NULL
  *             ).ST_AsText() as point
  *      from dual;
  *
  *    POINT
  *    ----------------------
  *    POINT (3.927 1240.552)
  *
  *    select t_geometry(SDO_Geometry(3001,null,sdo_point_type(1.25,2.44,3.09),null,null),0.005,2,1)
  *             .ST_FixOrdinates(
  *                 'ROUND(X * 3.141592653,3)',
  *                 'ROUND(Y * dbms_random.value(1,1000),3)',
  *                 'ROUND(Z / 1000,3)'
  *             ).geom as point
  *      from dual;
  *
  *    POINT
  *    ----------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,NULL,SDO_POINT_TYPE(3.927,1317.816,0.003),NULL,NULL)
  *
  *    select t_geometry(SDO_Geometry('LINESTRING(1.12345 1.3445,2.43534 2.03998398)',NULL),0.005,2,1)
  *             .ST_FixOrdinates(
  *                 'ROUND(X * 3.141592653,3)',
  *                 'ROUND(Y * dbms_random.value(1,1000),3)'
  *              ).ST_AsText() as line
  *      from dual;
  *
  *    LINE
  *    ---------------------------------------
  *    LINESTRING (3.529 49.26, 7.651 466.107)
  *
  *    select t_geometry(
  *             SDO_Geometry(3006,null,null,
  *                          sdo_elem_info_array(1,2,1,10,2,1),
  *                          sdo_ordinate_array(1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9,10,10,9,10,20,9)),0.005,2,1)
  *             .ST_FixOrdinates(
  *                 NULL,
  *                 NULL,
  *                 'ROUND(Y * dbms_random.value(1,1000),3)'
  *             ).geom as line
  *      from dual;
  *
  *    LINE
  *    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,10,2,1),SDO_ORDINATE_ARRAY(1.12345,1.3445,525.749,2.43534,2.03998398,952.99,3.43513,3.451245,948.895,10,10,2930.214,10,20,16775.12))
  *
  *    -- line string with 3 dimensions: X,Y,M
  *    select t_geometry(
  *            SDO_GEOMETRY(3302,NULL,NULL,
  *                         SDO_ELEM_INFO_ARRAY(1,2,1), -- one line string, straight segments
  *                         SDO_ORDINATE_ARRAY(2,2,0,
  *                                            2,4,2,
  *                                            8,4,8,
  *                                            12,4,12,
  *                                            12,10,NULL,
  *                                            8,10,22,
  *                                            5,14,27)),0.005,2,1)
  *             .ST_FixOrdinates(NULL,NULL,NULL,'(rownum * NVL(w,18))').geom as line
  *      from dual;
  *
  *    LINE
  *    ---------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0,2,4,4,8,4,24,12,4,48,12,10,90,8,10,132,5,14,189))
  *  HISTORY
  *    Simon Greener - February 2009 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_FixOrdinates   (p_x_formula in varchar2,
                                     p_y_formula in varchar2,
                                     p_z_formula in varchar2 := null,
                                     p_w_formula in varchar2 := null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  -- ========================================================================================
  -- =============================== INSPECTORS =============================================
  -- ========================================================================================

  /****m* T_GEOMETRY/ST_VertexN
  *  NAME
  *    ST_VertexN -- Returns number of vertices (coordinates) in underlying mdsys.sdo_geometry.
  *  SYNOPSIS
  *    Member Function ST_VertexN (p_vertex in integer)
  *             Return T_Vertex Deterministic
  *  ARGUMENTS
  *    p_vertex (integer) -- Vertex number between 1 and ST_NumVertices().
  *  RESULT
  *    Vertex (T_Vertex) -- Vertex at position p_vertex.
  *  DESCRIPTION
  *    Returns p_vertex vertex within underlying geometry.
  *    p_vertex can be -1 which means the last vertex.
  *    If p_vertex is -1, the actual point id of the last vertex is returned in the T_Vertex structure.
  *  EXAMPLE
  *    With data As (
  *      Select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null),0.005,3,1) as TPolygon
  *       From Dual
  *    )
  *    select a.TPolygon.ST_VertexN(-1).ST_AsText() as VertexN
  *      from data a;
  *
  *    VERTEXN
  *    -----------------------------------------------------------
  *    T_Vertex(X=5.0,Y=5.0,Z=NULL,W=NULL,ID=15,GT=2001,SRID=NULL)
  *
  *    With data As (
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,20 0,20 20,10 20,0 20)',null),0.005,3,1) as tLine
  *        From Dual
  *    )
  *    select a.tLine.ST_VertexN(t.IntValue).ST_AsText() as vertex
  *      from data a,
  *           table(tools.generate_series(1,a.tLine.ST_NumVertices(),1)) t;
  *
  *    VERTEX
  *    ------------------------------------------------------------
  *    T_Vertex(X=0.0,Y=0.0,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=20.0,Y=0.0,Z=NULL,W=NULL,ID=2,GT=2001,SRID=NULL)
  *    T_Vertex(X=20.0,Y=20.0,Z=NULL,W=NULL,ID=3,GT=2001,SRID=NULL)
  *    T_Vertex(X=10.0,Y=20.0,Z=NULL,W=NULL,ID=4,GT=2001,SRID=NULL)
  *    T_Vertex(X=0.0,Y=20.0,Z=NULL,W=NULL,ID=5,GT=2001,SRID=NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_VertexN (p_vertex in integer)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /****m* T_GEOMETRY/ST_StartVertex
  *  NAME
  *    ST_StartVertex -- Returns first vertex in underlying geometry.
  *  SYNOPSIS
  *    Member Function ST_StartVertex
  *             Return T_Vertex Deterministic
  *  RESULT
  *    Vertex (T_Vertex) -- Vertex at start of geometry.
  *  DESCRIPTION
  *    Returns first vertex at start of underlying geometry.
  *  EXAMPLE
  *    With data As (
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,20 0,20 20,10 20,0 20)',null),0.005,3,1) as tLine
  *        From Dual
  *    )
  *    select a.tLine.ST_StartVertex().ST_AsText() as start_vertex
  *      from data a;
  *
  *    VERTEX
  *    ----------------------------------------------------------
  *    T_Vertex(X=0.0,Y=0.0,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_StartVertex
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /****m* T_GEOMETRY/ST_EndVertex
  *  NAME
  *    ST_EndVertex -- Returns last vertex in underlying geometry.
  *  SYNOPSIS
  *    Member Function ST_EndVertex
  *             Return T_Vertex Deterministic
  *  RESULT
  *    Vertex (T_Vertex) -- Vertex at end of geometry.
  *  DESCRIPTION
  *    Returns last vertex describing underlying geometry.
  *    Actual end vertex ID is provided in returned T_Vertex object.
  *  EXAMPLE
  *    With data As (
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,20 0,20 20,10 20,0 20)',null),0.005,3,1) as tLine
  *        From Dual
  *    )
  *    select a.tLine.ST_EndVertex().ST_AsText() as end_vertex
  *      from data a;
  *
  *    VERTEX
  *    -----------------------------------------------------------
  *    T_Vertex(X=0.0,Y=20.0,Z=NULL,W=NULL,ID=5,GT=2001,SRID=NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_EndVertex
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /****m* T_GEOMETRY/ST_PointN
  *  NAME
  *    ST_PointN -- Returns point (coordinate) at position p_point in underlying geometry.
  *  SYNOPSIS
  *    Member Function ST_PointN(p_point in integer)
  *             Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
  *  ARGUMENTS
  *    p_point (integer) -- Point number between 1 and ST_NumPoints().
  *  RESULT
  *    Point (T_GEOMETRY) -- Point at position p_point.
  *  DESCRIPTION
  *    Returns p_point point within underlying geometry.
  *    p_point should be between 1 and ST_NumPoints().
  *    p_point can be -1 which means the last point.
  *  EXAMPLE
  *    With data As (
  *      Select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null),0.005,3,1) as TPolygon
  *        From Dual
  *    )
  *    select a.TPolygon.ST_PointN(-1).ST_AsText() as PointN
  *      from data a;
  *
  *    POINTN
  *    ---------------
  *    POINT (5.0 5.0)
  *
  *    With data As (
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,20 0,20 20,10 20,0 20)',null),0.005,3,1) as tLine
  *        From Dual
  *    )
  *    select t.IntValue as PointId,
  *           a.tLine.ST_PointN(t.IntValue).ST_AsText() as Point
  *      from data a,
  *           table(tools.generate_series(1,a.tLine.ST_NumVertices(),1)) t;
  *
  *    POINTID POINT
  *    ------- ------------------
  *          1 POINT (0.0 0.0)
  *          2 POINT (20.0 0.0)
  *          3 POINT (20.0 20.0)
  *          4 POINT (10.0 20.0)
  *          5 POINT (0.0 20.0)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_PointN(p_point in integer)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_StartPoint
  *  NAME
  *    ST_StartPoint -- Returns first Point in underlying geometry.
  *  SYNOPSIS
  *    Member Function ST_StartPoint
  *             Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
  *  DESCRIPTION
  *    Returns first point in underlying geometry.
  *  EXAMPLE
  *    With data As (
  *      Select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null),0.005,3,1) as TPolygon
  *        From Dual
  *    )
  *    select a.TPolygon.ST_StartPoint().ST_AsText() as Start_Point
  *      from data a;
  *
  *    START_POINT
  *    ---------------
  *    POINT (0.0 0.0)
  *  RESULT
  *    Point (T_GEOMETRY) -- First point in underlying geometry.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_StartPoint
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_EndPoint
  *  NAME
  *    ST_EndPoint -- Returns last Point in underlying geometry.
  *  SYNOPSIS
  *    Member Function ST_EndPoint
  *             Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
  *  DESCRIPTION
  *    Returns last point in underlying geometry.
  *  EXAMPLE
  *    With data As (
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,20 0,20 20,10 20,0 20)',null),0.005,3,1) as tLine
  *        From Dual
  *    )
  *    select a.tLine.ST_EndPoint().ST_AsText() as end_Point
  *      from data a;
  *
  *    END_POINT
  *    ----------------
  *    POINT (0.0 20.0)
  *  RESULT
  *    Point (T_GEOMETRY) -- First point in underlying geometry.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_EndPoint
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_SegmentN
  *  NAME
  *    ST_SegmentN -- Returns the segment referenced by p_segment in the underlying linear or polygonal geometry.
  *  SYNOPSIS
  *    Member Function ST_SegmentN(p_segment in integer)
  *             Return &&INSTALL_SCHEMA..T_Segment Deterministic,
  *  DESCRIPTION
  *    Returns the 2-point segment identified by p_segment in a polygon or linestring.
  *  EXAMPLE
  *    With data as (
  *     Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *     select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GeometryType() as gType,
  *           (row_number() over (partition by a.tgeom.ST_GeometryType() order by 1)) ||
  *             ' of ' ||
  *             a.tGeom.ST_NumSegments() as reference,
  *           a.tGeom.ST_SegmentN(t.IntValue).ST_AsText()  as segment
  *      from data a,
  *           table(TOOLS.generate_series(1,a.tgeom.ST_NumSegments(),1)) t;
  *
  *    GTYPE         REFERENCE SEGMENT
  *    ------------- --------- --------------------------------------------------------------------------------------------------------------
  *    ST_LINESTRING    1 of 5 SEGMENT(1,1,1,Start(0,0,NULL,NULL,1,2001,NULL),End(10,0,NULL,NULL,2,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_LINESTRING    2 of 5 SEGMENT(1,1,2,Start(10,0,NULL,NULL,2,2001,NULL),End(10,5,NULL,NULL,3,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_LINESTRING    3 of 5 SEGMENT(1,1,3,Start(10,5,NULL,NULL,3,2001,NULL),End(10,10,NULL,NULL,4,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_LINESTRING    4 of 5 SEGMENT(1,1,4,Start(10,10,NULL,NULL,4,2001,NULL),End(5,10,NULL,NULL,5,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_LINESTRING    5 of 5 SEGMENT(1,1,5,Start(5,10,NULL,NULL,5,2001,NULL),End(5,5,NULL,NULL,6,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON       1 of 8 SEGMENT(1,1,1,Start(0,0,NULL,NULL,1,2001,NULL),End(20,0,NULL,NULL,2,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON       2 of 8 SEGMENT(1,1,2,Start(20,0,NULL,NULL,2,2001,NULL),End(20,20,NULL,NULL,3,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON       3 of 8 SEGMENT(1,1,3,Start(20,20,NULL,NULL,3,2001,NULL),End(0,20,NULL,NULL,4,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON       4 of 8 SEGMENT(1,1,4,Start(0,20,NULL,NULL,4,2001,NULL),End(0,0,NULL,NULL,5,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON       5 of 8 SEGMENT(1,2,1,Start(10,10,NULL,NULL,1,2001,NULL),End(10,11,NULL,NULL,2,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON       6 of 8 SEGMENT(1,2,2,Start(10,11,NULL,NULL,2,2001,NULL),End(11,11,NULL,NULL,3,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON       7 of 8 SEGMENT(1,2,3,Start(11,11,NULL,NULL,3,2001,NULL),End(11,10,NULL,NULL,4,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON       8 of 8 SEGMENT(1,2,4,Start(11,10,NULL,NULL,4,2001,NULL),End(10,10,NULL,NULL,5,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *
  *     13 rows selected
  *  RESULT
  *    A 2 point segment (T_SEGMENT) -- Function supplied with p_segment of 3 will return 3rd segment composed of 4th and 5th points.
  *  TODO
  *    Support for CircularString elements.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Sept 2015 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SegmentN (p_segment in integer)
           Return &&INSTALL_SCHEMA..T_Segment Deterministic,

  /****m* T_GEOMETRY/ST_StartSegment
  *  NAME
  *    ST_StartSegment -- Returns first Segment in underlying geometry.
  *  SYNOPSIS
  *    Member Function ST_StartSegment
  *             Return &&INSTALL_SCHEMA..T_Segment Deterministic,
  *  DESCRIPTION
  *    Returns first segment in underlying geometry.
  *  EXAMPLE
  *    With data as (
  *     Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *     select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GeometryType()             as geometryType,
  *           a.tGeom.ST_StartSegment().ST_AsText() as start_segment
  *      from data a;
  *
  *    GEOMETRYTYPE  START_SEGMENT
  *    ------------- ------------------------------------------------------------------------------------------------------------
  *    ST_LINESTRING SEGMENT(1,1,1,Start(0,0,NULL,NULL,1,2001,NULL),End(10,0,NULL,NULL,2,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON    SEGMENT(1,1,1,Start(0,0,NULL,NULL,1,2001,NULL),End(20,0,NULL,NULL,2,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *  RESULT
  *    Segment (T_GEOMETRY) -- First segment in underlying geometry.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_StartSegment
           Return &&INSTALL_SCHEMA..T_Segment Deterministic,

  /****m* T_GEOMETRY/ST_EndSegment
  *  NAME
  *    ST_EndSegment -- Returns last Segment in underlying geometry.
  *  SYNOPSIS
  *    Member Function ST_EndSegment
  *             Return &&INSTALL_SCHEMA..T_Segment Deterministic,
  *  DESCRIPTION
  *    Returns last segment in underlying geometry.
  *  EXAMPLE
  *    With data as (
  *     Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *     select T_GEOMETRY(sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GeometryType()           as geometryType,
  *           a.tGeom.ST_EndSegment().ST_AsText() as end_segment
  *      from data a;
  *
  *    GEOMETRYTYPE  END_SEGMENT
  *    ------------- -----------------------------------------------------------------------------------------------------------
  *    ST_LINESTRING SEGMENT(1,1,5,Start(5,10,NULL,NULL,5,2001,NULL),End(5,5,NULL,NULL,6,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *    ST_POLYGON    SEGMENT(1,2,4,Start(11,10,NULL,NULL,4,2001,NULL),End(10,10,NULL,NULL,5,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *  RESULT
  *    Segment (T_GEOMETRY) -- Last segment in underlying geometry.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_EndSegment
           Return &&INSTALL_SCHEMA..t_SEGMENT Deterministic,

  -- ========================================================================================
  -- ================================== EDITORS =============================================
  -- ========================================================================================

/****m* T_GEOMETRY/ST_InsertVertex
 *  NAME
 *    ST_InsertVertex -- Function which inserts new coordinate (p_vertex) at position p_vertex.id into the supplied geometry.
 *  SYNOPSIS
 *    Function ST_InsertVertex (
 *               p_vertex T_Vertex
 *             )
 *     Returns T_Geometry
 *  DESCRIPTION
 *    Function that inserts the vertex p_vertex into into supplied geometry as position p_vertex.id.
 *    All existing vertices are shuffled down ie Insert is "add before" except at end.
 *    Supplied p_vertex must have Z and W coded correctly.
 *    p_vertex.id values:
 *      1. null -> defaults to 1;
 *      2. -1   -> maximum number of points ie SELF.ST_NumPoints()
 *      3. Greater than SELF.ST_NumPoints() -> maximum number of points ie SELF.ST_NumPoints()
 *    The inserted coordinate's XY ordinates are rounded to SELF.dprecision number of decimal digits of dprecision.
 *  ARGUMENTS
 *    p_vertex    (t_vertex) -- Insert coordinate. p_vertex.id is position in geometry to insert new vertex: between 1 and SELF.ST_NumPoints.
 *  RESULT
 *    geometry -- Geometry with coordinate inserted.
 *  EXAMPLE
 *    -- Insert 2D vertex into 2D linestring
 *    select t_geometry(sdo_geometry('LINESTRING(0 0,2 2)',null),0.005,2,1)
 *              .ST_InsertVertex(
 *                  T_Vertex(p_id       =>2,
 *                           p_x        =>1,
 *                           p_y        =>1,
 *                           p_sdo_gtype=>2001,
 *                           p_sdo_srid =>NULL)
 *            ).ST_AsText() as newGeom
 *       from dual;
 *
 *
 *    NEWGEOM
 *    --------------------------
 *    LINESTRING (0 0, 1 1, 2 2)
 *
 *    -- Update 3D point....
 *    select t_geometry(sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1, 2,2,2)),0.005,2,1)
 *              .ST_InsertVertex(
 *                  T_Vertex(p_id       =>2,
 *                           p_x        =>1.5,
 *                           p_y        =>1.5,
 *                           p_z        =>1.5,
 *                           p_sdo_gtype=>3001,
 *                           p_sdo_srid =>NULL)
 *            ).geom as UpdatedGeom
 *       from dual;
 *
 *    UPDATEDGEOM
 *    ---------------------------------------------------------------------------------------------
 *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,1.5,1.5,1.5))
 *
 *    -- Insert 3D point into 3D linestring.
 *    select t_geometry(sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,2,2,2)),0.005,2,1)
 *              .ST_InsertVertex(
 *                  T_Vertex(p_id       =>2,
 *                           p_x        =>1,
 *                           p_y        =>1,
 *                           p_z        =>1.5,
 *                           p_sdo_gtype=>2001,
 *                           p_sdo_srid =>NULL)
 *            ).geom as newGeom
 *       from dual;
 *
 *    NEWGEOM
 *    -----------------------------------------------------------------------------------------------
 *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,1,1,1.5,2,2,2))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2006 - Original Coding for GEOM package.
 *    Simon Greener - July 2011     - Port to T_GEOMETRY.
 *  COPYRIGHT
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_InsertVertex (p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

/****m* T_GEOMETRY/ST_UpdateVertex(p_vertex)
 *  NAME
 *    ST_UpdateVertex -- Function which updates the coordinate at position v_vertex.id of the underlying geometry with ordinates in v_vertex.x etc.
 *  SYNOPSIS
 *   Member Function ST_UpdateVertex (p_vertex in &&INSTALL_SCHEMA..T_Vertex)
 *            Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
 *  EXAMPLE
 *    select t_geometry(sdo_geometry('LINESTRING(0 0,2 2)',NULL),0.005,2,1)
 *             .ST_UpdateVertex(
 *                T_Vertex(p_x         => 1.0,
 *                         p_y         => 1.0,
 *                         p_id        => 2,
 *                         p_sdo_gtype => 2001,
 *                         p_sdo_srid  => NULL)
 *                  ).ST_AsText() as updatedGeom
 *       from dual;
 *
 *    UPDATEDGEOM
 *    -------------------
 *    LINESTRING(0 0,1 1)
 *  DESCRIPTION
 *    Function that updates coordinate in the underlying geometry identified by p_vertex.id with the ordinate values in p_vertex.
 *    p_verted.id Values:
 *      1. null -> defaults to 1;
 *      2. -1   -> maximum number of points ie STNumPoints(p_geometry)
 *      3. Greater than ST_NumPoints(p_geometry) -> maximum number of points ie ST_NumPoints(p_geometry)
 *  ARGUMENTS
 *    p_vertex (t_vertex) - Replacement coordinate.
 *  RESULT
 *    updated geom (geometry) - Geometry with coordinate replaced.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2006 - Original Coding for GEOM package.
 *    Simon Greener - July 2011     - Port to T_GEOMETRY.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_UpdateVertex (p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

/****m* T_GEOMETRY/ST_UpdateVertex( p_old_vertex p_new_vertex )
 *  NAME
 *    ST_UpdateVertex -- Function that updates (replaces) all geometry points that are equal to the supplied point with the replacement point.
 *  SYNOPSIS
 *    Member Function ST_UpdateVertex (p_old_vertex in &&INSTALL_SCHEMA..T_Vertex,
 *                                     p_new_vertex in &&INSTALL_SCHEMA..T_Vertex)
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
 *  DESCRIPTION
 *    Function that updates all coordinates that equal p_old_vertex with the supplied p_old_vertex.
 *    SELF.dprecision is used when comparing geometry point's XY ordinates to p_old_vertex's.
 *    Note that this version of ST_UpdateVertex allows for the update of the first and last vertex in a polygon thereby not invalidating it.
 *  ARGUMENTS
 *    p_old_vertex (T_Vertex) - Original coordinate to be replaced.
 *    p_new_vertex (T_Vertex) - Replacement coordinate
 *  RESULT
 *    geometry (geometry) - Underlying geometry with one or more coordinates replaced.
 *  EXAMPLE
 *    select t_geometry(sdo_geometry('POLYGON((0 0,10 0,10 10,0 10,0 0))',NULL),0.005,2,1)
 *             .ST_UpdateVertex(
 *               T_Vertex(p_x         => 0.0,
 *                        p_y         => 0.0,
 *                        p_id        => 1,
 *                        p_sdo_gtype => 2001,
 *                        p_sdo_srid  => NULL),
 *               T_Vertex(p_x         => 1.0,
 *                        p_y         => 1.0,
 *                        p_id        => 1,
 *                        p_sdo_gtype => 2001,
 *                        p_sdo_srid  => NULL)
 *           ).ST_AsText() as updatedGeom
 *      from dual;
 *
 *    UPDATEDGEOM
 *    ---------------------------------------
 *    POLYGON ((1 1, 10 0, 10 10, 0 10, 1 1))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2006 - Original Coding for GEOM package.
 *    Simon Greener - July 2011     - Port to T_GEOMETRY.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_UpdateVertex (p_old_vertex in &&INSTALL_SCHEMA..T_Vertex,
                                   p_new_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

/****m* T_GEOMETRY/ST_DeleteVertex
 *  NAME
 *    ST_DeleteVertex -- Function which deletes the coordinate at position p_vertex_id from the underlying geometry.
 *  SYNOPSIS
 *   Member Function ST_DeleteVertex (p_vertex_id in integer)
 *            Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
 *  DESCRIPTION
 *    Function that deletes the coordinate at position p_vertex_id in the underlying geometry.
 *    p_verted_id Values:
 *      1. null -> defaults to -1;
 *      2. -1   -> maximum number of points ie ST_NumPoints()
 *      3. Greater than ST_NumPoints() -> maximum number of points ie ST_NumPoints(p_geometry)
 *  ARGUMENTS
 *    p_vertex_id (integer) - Coordinate to be deleted.
 *  RESULT
 *    updated geom (geometry) - Geometry with coordinate deleted.
 *  EXAMPLE
 *    select t_geometry(
 *             sdo_geometry('LINESTRING(0 0,1 1,2 2)',NULL),0.005,2,1
 *           ).ST_DeleteVertex(
 *                 p_vertex_id => 2
 *             ).ST_AsText() as updatedGeom
 *      from dual;
 *
 *    UPDATEDGEOM
 *    -------------------
 *    LINESTRING(0 0,1 1)
 *  ERRORS
 *    Can throw one of the following exceptions:
 *      1. ORA-20122: Deletion of vertex within an existing circular arc not allowed.
 *      2. ORA-20123: Deletion vertex position is invalid.
 *      3. ORA-20124: Vertex delete invalidated geometry, with reason of: <Reason>
 *    Exception ORA-20124 will include result from SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2006 - Original Coding for GEOM package.
 *    Simon Greener - July 2011     - Port to T_GEOMETRY.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_DeleteVertex (p_vertex_id in integer)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

/****m* T_GEOMETRY/ST_RemoveDuplicateVertices
 *  NAME
 *    ST_RemoveDuplicateVertices -- Function that removes duplicate points in underlying linear or polygonal geometry.
 *  SYNOPSIS
 *    Member Function ST_RemoveDuplicateVertices
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
 *  DESCRIPTION
 *    Function that calls MDSYS.SDO_UTIL.REMOVE_DUPLICATE_VERTICES(sdo_geometry,tolerance);
 *    Tolerance used is SELF.TOLERANCE or 0.005 if null.
 *  RESULT
 *    Modified linestring (geometry) - Input linestring/polygon with duplicate points removed.
 *  EXAMPLE
 *    -- Example of exception
 *    select t_geometry(
 *             sdo_geometry('POINT(0 0)',NULL),0.05,2,1
 *           ).ST_RemoveDuplicateVertices()
 *            .ST_AsText() as updatedGeom
 *      from dual;
 *
 *    SQL Error: ORA-20121: Geometry must be a linestring or polygon.
 *    ORA-06512: at "T_GEOMETRY", line 2807
 *
 *    -- Linestring example
 *    select t_geometry(
 *             sdo_geometry('LINESTRING(0 0,1 1,1.004 1, 2 2)',NULL),0.005,2,1
 *           ).ST_RemoveDuplicateVertices()
 *            .ST_AsText() as updatedGeom
 *      from dual;
 *
 *    UPDATEDGEOM
 *    -------------------
 *    LINESTRING (0 0, 1 1, 2 2)
 *
 *    -- Polygon example
 *    -- Example where tolerance is over-ridden
 *    with data as (
 *      select t_geometry(
 *               sdo_geometry('POLYGON((0 0,1 0,1.004 0,1 2,0 2,0 0))',NULL),0.0005,3,1
 *             ) as tGeom
 *        from dual
 *    )
 *    select a.tGeom
 *            .ST_SetTolerance(0.05)
 *            .ST_RemoveDuplicateVertices()
 *            .ST_AsText()
 *                as tolGeom,
 *           a.tGeom
 *            .ST_RemoveDuplicateVertices()
 *            .ST_AsText()
 *                as rGeom
 *      from data a;
 *
 *    TOLGEOM                             RGEOM
 *    ----------------------------------- --------------------------------------------
 *    POLYGON ((0 0, 1 0, 1 2, 0 2, 0 0)) POLYGON ((0 0, 1 0, 1.004 0, 1 2, 0 2, 0 0))
 *  ERRORS
 *    Can throw the following exception:
 *      ORA--20121: Geometry must be a linestring or polygon.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2011 - Original Coding.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_RemoveDuplicateVertices
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

/****m* T_GEOMETRY/ST_Extend
 *  NAME
 *    ST_Extend -- Function that lengthens underlying linestring at one or both ends.
 *  SYNOPSIS
 *    Member Function ST_Extend (p_length    in number,
 *                               p_start_end in varchar2 default 'START',
 *                               p_unit      in varchar2 default null)
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
 *  DESCRIPTION
 *    Function that extends the supplied linestring at either its start or end (p_end).
 *    p_length should alway be positive. If it is negative ST_Reduce is called: see ST_Reduce documentation.
 *    And extension occurs in the direction of a line formed by the first and second vertices (if START) or last and second last vertices (if END).
 *    p_end value of BOTH means line is extended at both ends.
 *  TODO
 *    Add p_keep parameter:
 *      If p_keep is set to 1, the start or end vertex is kept and a new vertex added at the extended length from the start/end.
 *      If p_keep is 0, the actual first or last vertex is moved.
 *  EXAMPLE
 *    -- Extend linestring at start 50 feet.
 *    With road_clines As (
 *    select T_GEOMETRY(
 *             SDO_GEOMETRY(2002,2872,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
 *                          SDO_ORDINATE_ARRAY(5995293.06,2105941.35, 5995094.87,2105871.28,
 *                                             5995044.46,2105492.80, 5995033.03,2105411.14,
 *                                             5995012.60,2105371.13, 5994950.04,2105332.47)),
 *             0.005,2,1)
 *            as tgeom
 *      from dual
 *    )
 *    SELECT round(rl.tgeom.ST_Length('unit=U.S. Foot'),2) as original_Length,
 *           round(rl.tgeom
 *             .ST_Extend(90,'START','unit=U.S. Foot')
 *             .ST_Round()
 *             .ST_Length('unit=U.S. Foot'),2) as new_length,
 *           rl.tgeom
 *             .ST_Extend(90,'START','unit=U.S. Foot')
 *             .ST_Round()
 *             .ST_AsText() as sGeom
 *      FROM road_clines rl;
 *
 *    ORIGINAL_LENGTH NEW_LENGTH SGEOM
 *    --------------- ---------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
 *             792.96     882.96 LINESTRING (5995377.91274448 2105971.34965591, 5995094.87 2105871.28, 5995044.46 2105492.8, 5995033.03 2105411.14, 5995012.6 2105371.13, 5994950.04 2105332.47)
 *
 *    -- MultiLineString Extend Example ...
 *    With data As (
 *    select T_Geometry(
 *             sdo_geometry('MULTILINESTRING((1 1,2 2,3 3,4 4),(0 2,1 3,2 4,3 5))',null),
 *             0.005,2,1) as tgeom
 *      from dual
 *    )
 *    select Start_end,
 *           seLength,
 *           gLength as originalLength,
 *           f.tGeom.ST_Length(p_round=>f.tGeom.dprecision) as newLength,
 *           f.tGeom.ST_Round(f.tGeom.dprecision,1,1).ST_AsText() as geom
 *      from (select a.tgeom.ST_Length(p_round=>a.tGeom.dprecision) as gLength,
 *                   'START' as Start_End,
 *                   1.414   as seLength,
 *                   a.tgeom.ST_Extend(1.414,'START') as tgeom
 *              from data a
 *             union all
 *            select a.tgeom.ST_Length(p_round=>a.tGeom.dprecision) as gLength,
 *                   'BOTH' as Start_End,
 *                   1.414  as seLength,
 *                   a.tgeom.ST_Extend(1.414,'BOTH')  as tgeom
 *              from data a
 *             union all
 *            select a.tgeom.ST_Length(p_round=>a.tGeom.dprecision) as gLength,
 *                   'END' as Start_End,
 *                   1.414 as seLength,
 *                   a.tgeom.ST_Extend(1.414,'END') as tgeom
 *              from data a
 *           ) f;
 *
 *    START_END SELENGTH ORIGINALLENGTH  NEWLENGTH GEOM
 *    --------- -------- -------------- ---------- ------------------------------------------------------------
 *    START        1.414           8.49        9.9 MULTILINESTRING ((0 0, 2 2, 3 3, 4 4), (0 2, 1 3, 2 4, 3 5))
 *    BOTH         1.414           8.49      11.31 MULTILINESTRING ((0 0, 2 2, 3 3, 4 4), (0 2, 1 3, 2 4, 4 6))
 *    END          1.414           8.49        9.9 MULTILINESTRING ((1 1, 2 2, 3 3, 4 4), (0 2, 1 3, 2 4, 4 6))
 *  NOTES
 *    Points, GeometryCollections, Polygons, MultiPolygons, CircularStrings are not supported.
 *    Assumes planar projection eg UTM.
 *  ARGUMENTS
 *    p_length       (number) - If negative ST_Reduce is called on the linestring.
 *                              If positive the linestring is extended.
 *                              Distance must be expressed in SRID or p_unit units
 *    p_start_end  (varchar2) - START means extend line at the start; END means extend at the end, and BOTH means extend at both START and END of line.
 *    p_unit       (varchar2) - Allows default Oracle unit of measure (UoM) to be overridden eg if unit M is default for SRID then unit=CM will compute in centimeters.
 *    p_keep            (int) - (Future) Keep existing first/last vertex and add new (1) vertices, or move (0) existing start/end vertex.
 *  RESULT
 *    linestring (t_geometry) - Input geometry extended as instructed.
 *  ERRORS
 *    The following exceptions can be thrown:
 *      ORA-20120 - Geometry must not be null or empty (*ERR*)
 *                  Where *ERR* is replaced with specific error
 *      ORA-20121 - Geometry must be a single linestring.
 *      ORA-20122 - Start/End parameter value (*VALUE*) must be START, BOTH or END
 *                  Where *VALUE* is the supplied, incorrect, value.
 *      ORA-20123 - p_length value must not be 0 or NULL.
 *  AUTHOR
 *    Simon Greener
 *    Simon Greener - December 2006 - Original Coding for GEOM Package
 *    Simon Greener - July 2011     - Port to T_GEOMETRY
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Extend (p_length    in number,
                             p_start_end in varchar2 default 'START',
                             p_unit      in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

 /****m* T_GEOMETRY/ST_Reduce
 *  NAME
 *    ST_Reduce -- Function that can shorten underlying linestring at one or both ends.
 *  SYNOPSIS
 *    Member Function ST_Reduce (p_length    in number,
 *                               p_start_end in varchar2 default 'START',
 *                               p_unit      in varchar2 default null)
 *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
 *  DESCRIPTION
 *    Function that reduces the supplied linestring at either its start or end (p_start_end).
 *    A p_start_end value of BOTH means line is reduced at both ends.
 *    p_length is always assumed to be positive, any negative value is passed through the ABS function.
 *    If p_length is 0 the geometry is returned unchanged.
 *    A reduction can be thought of as the equivalent of extracting a new segment between two measures: p_length ... (SELF.ST_Length() - p_length).
 *  ARGUMENTS
 *    p_length       (number) - If negative the linestring is shortened.
 *                              If positive the linestring is extended via a call to ST_Extend.
 *                              Distance must be expressed in SRID or p_unit units
 *    p_start_end  (varchar2) - START means reduce line at the start; END means reduce at the end, and BOTH means reduce at both START and END of line.
 *    p_unit       (varchar2) - Allows default Oracle unit of measure (UoM) to be overridden eg if unit M is default for SRID then unit=CM will compute in centimeters.
 *  RESULT
 *    linestring (t_geometry) - Input geometry reduced as instructed.
 *  EXAMPLE
 *    -- Reduce more than length of line.
 *    Select T_Geometry(
 *             mdsys.sdo_geometry('LINESTRING(1 1,2 2)',NULL),
 *             0.05,1,1
 *           )
 *           .ST_Reduce(0.708,'BOTH')
 *           .geom
 *              as geom
 *      From dual;
 *
 *    SQL Error: ORA-20124: Reducing geometry of length (1.4142135623731) by (.708) at both ends would result in a zero length geometry.
 *    ORA-06512: at "T_GEOMETRY", line 3450
 *
 *    -- Changes that remove whole segments.
 *    With data As (
 *    select -- Distance between all segments is 1.414
 *           T_Geometry(
 *             mdsys.sdo_geometry('LINESTRING(1 1,2 2,3 3,4 4)',NULL),0.05,1,1) as tgeom
 *      from dual
 *    )
 *    select 1.414    as seLength,
 *           'START'  as Start_end,
 *           a.tgeom.ST_Reduce(1.414,'START').ST_Round(2,1,1).ST_AsText() as tgeom,
 *           a.tgeom.ST_Length(p_round=>a.tGeom.dprecision) as gLength,
 *           a.tgeom.ST_Reduce(1.414,'START').ST_Length(p_round=>a.tGeom.dPrecision) as newLength
 *      from data a union all
 *    select 1.414   as seLength,
 *           'END'   as Start_end,
 *           a.tgeom.ST_Reduce(1.414,'END').ST_Round(2,1,1).ST_AsText() as tgeom,
 *           a.tgeom.ST_Length(p_round=>a.tGeom.dPrecision) as gLength,
 *           a.tgeom.ST_Reduce(1.414,'END').ST_Length(p_round=>a.tGeom.dPrecision) as newLength
 *      from data a union all
 *    select 1.414  as seLength,
 *           'BOTH' as Start_end,
 *           a.tgeom.ST_Reduce(1.414,'BOTH').ST_Round(2,1,1).ST_AsText() as tgeom,
 *           a.tgeom.ST_Length(p_round=>a.tGeom.dPrecision) as gLength,
 *           a.tgeom.ST_Reduce(1.414,'BOTH').ST_Length(p_round=>a.tGeom.dPrecision) as newLength
 *      from data a;
 *
 *    SELENGTH START_END TGEOM                      GLENGTH NEWLENGTH
 *    -------- --------- -------------------------- ------- ---------
 *       1.414 START     LINESTRING (2 2, 3 3, 4 4)     4.2       2.8
 *       1.414 END       LINESTRING (1 1, 2 2, 3 3)     4.2       2.8
 *       1.414 BOTH      LINESTRING (2 2, 3 3)          4.2       1.4
 *  NOTES
 *    Points, GeometryCollections, Polygons, MultiPolygons, CircularStrings are not supported.
 *    Assumes planar projection eg UTM.
 *  ERRORS
 *    The following exceptions can be thrown:
 *      ORA-20120 - Geometry must not be null or empty (*ERR*)
 *                  Where *ERR* is replaced with specific error
 *      ORA-20121 - Geometry must be a single linestring.
 *      ORA-20122 - Start/End parameter value (*VALUE*) must be START, BOTH or END
 *                  Where *VALUE* is the supplied, incorrect, value.
 *      ORA-20123 - p_extend_dist value must not be 0 or NULL.
 *      ORA-20124 - Reducing geometry of length (*GLEN*) by (*DIST*) at *STARTEND* would result in a zero length geometry.
 *                  Where *GLEN* is the length of the existing geometry, *DIST* is ABS(p_length), and *STARTEND* is p_start_end.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2006 - Original Coding for GEOM Package
 *    Simon Greener - July 2011     - Port to T_GEOMETRY
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_Reduce (p_length    in number,
                             p_start_end in varchar2 default 'START',
                             p_unit      in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

-- ========================================================================================
-- ======================================= COGO ===========================================
-- ========================================================================================

/****m* T_GEOMETRY/ST_Cogo2Line
 *  NAME
 *   ST_Cogo2Line - Creates linestring from supplied bearing and distance instructions.
 *  SYNOPSIS
 *    Member Function ST_Cogo2Line(p_bearings_and_distances in &&INSTALL_SCHEMA..T_BEARING_DISTANCES)
 *             Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
 *  DESCRIPTION
 *    This function takes a set of bearings and distances supplied using array of t_bearing_and_distance instructions, and creates a linestring from it.
 *    The underlying geometry must be a single start point.
 *    The final geometry's XY ordinates are not rounded.
 *  ARGUMENTS
 *    p_bearings_and_distances (t_bearings_distances) - Array of T_BEARING_DISTANCE instructions.
 *  RESULT
 *    linestring (t_geometry) - New linestring geometry object.
 *  NOTE
 *    Measures not supported: see LRS functions.
 *  TODO
 *    Create Static version where all instructions are provided including start point.
 *  EXAMPLE
 *    -- Build 2D Line from default constructor
 *    select F.line.ST_Validate() as vLine,
 *           f.line.geom          as line,
 *           round(f.line.ST_Length(),2) as meters
 *      from (select t_geometry(sdo_geometry(2001,null,sdo_point_type(0.0,3.5,null),null,null),0.005,2,1)
 *                     .ST_Cogo2Line (
 *                          t_bearing_distances(
 *                              t_bearing_distance(180.00,3.50,null),
 *                              t_bearing_distance( 90.00,3.50,null),
 *                              t_bearing_distance(  0.00,3.50,null),
 *                              t_bearing_distance( 43.02,5.43,null),
 *                              t_bearing_distance(270.00,9.50,null)
 *                          )
 *                     )
 *                     .ST_Round(8,8) as line
 *              from dual
 *           ) f;
 *
 *    VLINE LINE                                                                                                                                                        METERS
 *    ----- ----------------------------------------------------------------------------------------------------------------------------------------------------------- ------
 *    TRUE  SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.0,3.5, 0.0,0.0, 3.5,0.0, 3.5,3.5, 7.2046371,7.46995768, -2.2953629,7.46995768))  25.43
 *
 *    -- Build 3D line by decimal degrees using default constructor
 *    select F.line.ST_Validate()        as vLine,
 *           f.line.geom                 as line,
 *           round(f.line.ST_Length(),2) as meters
 *      from (select T_Geometry(sdo_geometry(3001,null,sdo_point_type(0,3.5,0),null,null),0.005,2,1)
 *                       .ST_Cogo2Line(
 *                           p_bearings_and_distances=>
 *                             t_bearing_distances(
 *                              t_bearing_distance(180,  3.5, 0.1),
 *                              t_bearing_distance(90,   3.5, 0.5),
 *                              t_bearing_distance(0,    3.5, 1.6),
 *                              t_bearing_distance(43.02,5.43,2.123),
 *                              t_bearing_distance(270,  9.5, 0.5)
 *                           )
 *                        )
 *                       .ST_Round(8,8) as line
 *              from dual
 *            ) f;
 *
 *    VLINE LINE                                                                                                                                                                                  METERS
 *    ----- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------
 *    TRUE  SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.0,3.5,0.0, 0.0,0.0,0.1, 3.5,0.0,0.5, 3.5,3.5,1.6, 7.2046371,7.46995768,2.123, -2.2953629,7.46995768,0.5))  25.79
 *
 *    -- Line by degrees using text constructor
 *    select F.line.ST_Validate()        as vLine,
 *           f.line.geom                 as line,
 *           round(f.line.ST_Length(),2) as meters
 *      from (select T_Geometry(sdo_geometry(3001,null,sdo_point_type(0,3.5,0),null,null),0.005,2,1)
 *                       .ST_Cogo2Line(
 *                           p_bearings_and_distances=>
 *                             t_bearing_distances(
 *                              t_bearing_distance(p_sDegMinSec=>'180',         p_distance=>3.5,  p_z=>0.1),
 *                              t_bearing_distance(p_sDegMinSec=>'90',          p_distance=>3.5,  p_z=>0.5),
 *                              t_bearing_distance(p_sDegMinSec=>'0',           p_distance=>3.5,  p_z=>1.6),
 *                              t_bearing_distance(p_sDegMinSec=>'43^01''21"',  p_distance=>5.43, p_z=>2.0),
 *                              t_bearing_distance(p_sDegMinSec=>'270',         p_distance=>9.5,  p_z=>0.5),
 *                              t_bearing_distance(p_sDegMinSec=>'149^58''6.3"',p_distance=>4.613,p_z=>0.1))
 *                          )
 *                      .ST_Round(8,8) as line
 *              from dual
 *            ) f;
 *
 *    VLINE LINE                                                                                                                                                                                                             METERS
 *    ----- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------
 *    TRUE  SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.0,3.5,0.0, 0.0,0.0,0.1, 3.5,0.0,0.5, 3.5,3.5,1.6, 7.20481032,7.46979603,2.0, -2.29518968,7.46979603,0.5, 0.01351213,3.47609287,0.1))  30.39
 *
 *    -- Build 3D line using mixed constructors
 *    select F.line.ST_Validate()        as vLine,
 *           f.line.geom                 as line,
 *           round(f.line.ST_Length(),2) as Meters
 *      from (select T_Geometry(sdo_geometry(3001,null,sdo_point_type(0,3.5,0),null,null),0.005,2,1)
 *                       .ST_Cogo2Line(
 *                           p_bearings_and_distances=>
 *                             t_bearing_distances(
 *                               t_bearing_distance(              180.0,                     3.5,       0.1),  -- << Default Constructor
 *                               t_bearing_distance(p_sDegMinSec=>'90',          p_distance=>3.5,  p_z=>0.5),
 *                               t_bearing_distance(              0.0,                       3.5,       1.6),  -- << Default Constructor
 *                               t_bearing_distance(p_sDegMinSec=>'43^01''21"',  p_distance=>5.43, p_z=>2.0),
 *                               t_bearing_distance(p_sDegMinSec=>'270',         p_distance=>9.5,  p_z=>0.5),
 *                               t_bearing_distance(p_sDegMinSec=>'149^58''6.3"',p_distance=>4.613,p_z=>0.1))
 *                          )
 *                      .ST_Round(8,8) as line
 *              from dual
 *            ) f;
 *
 *    VLINE LINE                                                                                                                                                                                                             METERS
 *    ----- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------
 *    TRUE  SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.0,3.5,0.0, 0.0,0.0,0.1, 3.5,0.0,0.5, 3.5,3.5,1.6, 7.20481032,7.46979603,2.0, -2.29518968,7.46979603,0.5, 0.01351213,3.47609287,0.1))  30.39
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original coding.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_Cogo2Line(p_bearings_and_distances in &&INSTALL_SCHEMA..T_BEARING_DISTANCES)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

/****m* T_GEOMETRY/ST_Line2Cogo
 *  NAME
 *   ST_Line2Cogo - Creates Cogo Instructions from linestring segments.
 *  SYNOPSIS
 *   Member Function ST_Line2Cogo
 *            Return &&INSTALL_SCHEMA..T_BEARING_DISTANCES Pipeline,
 *  DESCRIPTION
 *    This function converts the underlying simple linestring to a set of bearings and distances in T_BEARINGS_DISTANCES array format.
 *    The first T_BEARING_DISTANCE element will be the bearing and distance from an implied start point of 0,0.
 *  ARGUMENTS
 *    p_unit (varchar2) - For when SRID <> NULL, an oracle unit of measure eg unit=M.
 *  RESULT
 *    Cogo Instructions - Cogo instructions coded as T_BEARING_DISTANCES array of T_BEARING_DISTANCE
 *  EXAMPLE
 *    -- Create 2D Line from COGO then reverse back to COGO ....
 *    With data as (
 *    select f.line
 *      from (select t_geometry(sdo_geometry(2001,null,sdo_point_type(0.0,3.5,null),null,null),0.005,2,1)
 *                     .ST_Cogo2Line (
 *                          t_bearing_distances(
 *                              t_bearing_distance(180.00,3.50,null),
 *                              t_bearing_distance( 90.00,3.50,null),
 *                              t_bearing_distance(  0.00,3.50,null),
 *                              t_bearing_distance( 43.02,5.43,null),
 *                              t_bearing_distance(270.00,9.50,null))
 *                          ) as line
 *              from dual
 *           ) f
 *    )
 *    select COGO.DD2DMS(COGO.ST_Degrees(t.bearing)) as bearing,
 *           Round(t.distance,3) as distance
 *      from data a,
 *           table(a.line.ST_Line2Cogo()) t;
 *
 *    BEARING  DISTANCE
 *    -------- --------
 *    0°0'0"        3.5
 *    180°0'0"      3.5
 *    90°0'0"       3.5
 *    0°0'0"        3.5
 *    43°1'12"     5.43
 *    270°0'0"      9.5
 *
 *     6 rows selected
 *
 *    -- Create 3D Line from COGO then reverse back to COGO ....
 *    With data as (
 *    select f.line
 *      from (select t_geometry(sdo_geometry(3001,null,sdo_point_type(0.0,3.5,0.2),null,null),0.005,2,1)
 *                     .ST_Cogo2Line (
 *                          t_bearing_distances(
 *                              t_bearing_distance(180.00,3.50,1.1),
 *                              t_bearing_distance( 90.00,3.50,2.0),
 *                              t_bearing_distance(  0.00,3.50,3.0),
 *                              t_bearing_distance( 43.02,5.43,4.4),
 *                              t_bearing_distance(270.00,9.50,5.2))
 *                          ) as line
 *              from dual
 *           ) f
 *    )
 *    select COGO.DD2DMS(COGO.ST_Degrees(t.bearing)) as bearing,
 *           Round(t.distance,3)                     as distance,
 *           t.z
 *      from data a,
 *           table(a.line.ST_Line2Cogo()) t;
 *
 *    BEARING  DISTANCE   Z
 *    -------- -------- ---
 *    0°0'0"      3.506 0.2
 *    180°0'0"    3.614 1.1
 *    90°0'0"     3.614   2
 *    0°0'0"      3.64    3
 *    43°1'12"    5.608 4.4
 *    270°0'0"    9.534 5.2
 *
 *     6 rows selected
 *  NOTE
 *    Measures not supported: see LRS functions.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - June 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_Line2Cogo (p_unit in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_BEARING_DISTANCES Pipelined,

/****m* T_GEOMETRY/ST_Cogo2Polygon
 *  NAME
 *   ST_Cogo2Polygon - Creates single polygon exterior ring from supplied bearing and distance instructions.
 *  SYNOPSIS
 *    Member Function ST_Cogo2Polygon(p_bearings_and_distances in &&INSTALL_SCHEMA..T_BEARING_DISTANCES)
 *             Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
 *  DESCRIPTION
 *    This function takes a set of bearings and distances supplied using array of t_bearing_and_distance instructions, and creates a closed exterior ring from it.
 *    The underlying geometry must be a single start point.
 *    The final geometry will have its XY ordinates rounded to SELF.dPrecision.
 *    Z ordinates are not rounded as they are provided (as is) in the t_bearing_distance.z values.
 *  ARGUMENTS
 *    p_bearings_and_distances (t_bearings_distances) - Array of T_BEARING_DISTANCE instructions.
 *  RESULT
 *    polygon (t_geometry) - New polygon object with a single exterior ring.
 *  NOTE
 *    Measured polygons not supported.
 *  TODO
 *    Create Static version where all instructions are provided including start point.
 *  EXAMPLE
 *    -- Polygon built from default constructor...
 *    select F.poly.ST_Validate()      as vPoly,
 *           f.poly.ST_AsText()        as pWKT,
 *           round(f.Poly.ST_Area(),2) as sqM
 *      from (select t_geometry(sdo_geometry(2001,null,sdo_point_type(0,3.5,null),null,null),0.005,2,1)
 *                     .ST_Cogo2Polygon(
 *                          t_bearing_distances(
 *                              t_bearing_distance(180,3.5,null),
 *                              t_bearing_distance(90,3.5,null),
 *                              t_bearing_distance(0,3.5,null),
 *                              t_bearing_distance(43.02,5.43,null),
 *                              t_bearing_distance(270,9.5,null))
 *                      )
 *                     .ST_Round(3,3) as poly
 *              from dual
 *           ) f;
 *
 *    VPOLY PWKT                                                                               SQM
 *    ----- -------------------------------------------------------------------------------- -----
 *    TRUE  POLYGON ((0.0 3.5, 0.0 0.0, 3.5 0.0, 3.5 3.5, 7.205 7.47, -2.295 7.47, 0.0 3.5)) 38.06
 *
 *    -- Different way of building directions.
 *    -- Simple bearing/distance constructors used
 *    With data as (
 *    select CAST(MULTISET(
 *             Select bd
 *               from (select 1 as rin, t_bearing_distance(180.0,3.5) as bd                      from dual union all
 *                     select 2,        t_bearing_distance( 90.0,3.5)                            from dual union all
 *                     select 3,        t_bearing_distance(  0.0,3.5)                            from dual union all
 *                     select 4,        t_bearing_distance(43.02,round(sqrt(4.5*4.5+2.2*4.2),2)) from dual union all
 *                     select 5,        t_bearing_distance(270.0,(4.5+3.4+1.6))                  from dual )
 *                     order by rin
 *           ) as t_bearing_distances ) as directions
 *      from dual
 *    )
 *    select F.poly.ST_Validate()      as vPoly,
 *           f.poly.ST_AsText()        as pWKT,
 *           round(f.Poly.ST_Area(),2) as sqM
 *      from (select t_geometry(sdo_geometry(2001,null,sdo_point_type(0,3.5,null),null,null),0.005,2,1)
 *                     .ST_Cogo2Polygon (
 *                         p_bearings_and_distances=>a.directions
 *                      )
 *                     .ST_Round(3,3) as poly
 *              from data a
 *            ) f;
 *
 *    VPOLY PWKT                                                                               SQM
 *    ----- -------------------------------------------------------------------------------- -----
 *    TRUE  POLYGON ((0.0 3.5, 0.0 0.0, 3.5 0.0, 3.5 3.5, 7.205 7.47, -2.295 7.47, 0.0 3.5)) 38.06
 *
 *    -- Mixed Constructors with Z for 3D Polygon...
 *    select F.poly.ST_Validate()      as vPoly,
 *           f.poly.geom               as polygon,
 *           round(f.Poly.ST_Area(),2) as sqM
 *      from (select t_geometry(sdo_geometry(3001,null,sdo_point_type(0,3.5,10.0),null,null),0.005,2,1)
 *                     .ST_Cogo2Polygon (
 *                         t_bearing_distances(
 *                              t_bearing_distance(180,3.5,11.1),
 *                              t_bearing_distance(p_sDegMinSec=>'90^0''0"',p_distance=>3.5,p_z=>12.2),
 *                              t_bearing_distance(0.0,3.5,13.3),
 *                              t_bearing_distance(p_sDegMinSec=>'43^01''12"',p_distance=>5.43,p_z=>14.4),
 *                              t_bearing_distance(270.0,9.5,13.3)
 *                          )
 *                      )
 *                     .ST_Round(3,3) as poly
 *              from dual
 *           ) f;
 *
 *    VPOLY POLYGON                                                                                                                                                                                  SQM
 *    ----- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -----
 *    TRUE  SDO_GEOMETRY(3003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0.0,3.5,10.0, 0.0,0.0,11.1, 3.5,0.0,12.2, 3.5,3.5,13.3, 7.205,7.47,14.4, -2.295,7.47,13.3, 0.0,3.5,10.0)) 43.37
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original coding.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_Cogo2Polygon(p_bearings_and_distances in &&INSTALL_SCHEMA..T_BEARING_DISTANCES)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

-- ========================================================================================
-- ======================================= NETWORK ========================================
-- ========================================================================================

/****m* T_GEOMETRY/ST_TravellingSalesman
 *  NAME
 *    ST_TravellingSalesman - Constructs a path through a set of points.
 *  SYNOPSIS
 *    Member Function ST_TravellingSalesman(p_start_gid   in integer,
 *                                          p_start_point in mdsys.sdo_point_type,
 *                                          p_geo_fence   in mdsys.sdo_geometry,
 *                                          p_unit        in varchar2 default 'Meter' )
 *             Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
 *  DESCRIPTION
 *    This function implements a very simple traveling salesman's route through a set of points.
 *    The underlying geometry must be a MultiPoint object.
 *    The starting point may be a point within the existing underlying geometry or a user provided point.
 *    When p_geo_fence is provided it should be a MultiLineString object eg a set of street centrelines aggregated using SDO_AGGR_UNION.
 *    If p_geo_fence is 2D all linestrings in it are of equal weight.
 *    If p_geo_fence has a Z ordinate, its values define an order in the geofences. 
 *    The value that must be assigned to the z ordinate of a linestring which forms a hard boundary (such as a physical fence) must be 9.
 *    All other Z values should be given values below 9. So, z=5 could denote a major road, while z=1 is a local street, and z=0 might mean a walking track.
 *    When determining the next point to move to, this z ordering is used in determining where to move.
 *    If the set of nearby objects contained a z=9 object, it would be removed from the set and the next highest chosen.
 *  ARGUMENTS
 *    p_start_gid          (integer) - A vertex that exists in the underlying geometry whose Z has this value.
 *    p_start_point (sdo_point_type) - A vertex that may not exist in the underlying geometry, algorithm finds nearest point in underlying geometry to start.
 *    p_geo_fence     (sdo_geometry) - A collection of linestrings (multilinestring) containing fences or objects that cannot be crossed unless there is nowhere else to go,
 *                                     when determining the shortest path.
 *    p_unit              (varchar2) - Oracle Unit of Measure eg unit=M.
 *  RESULT
 *    linestring (t_geometry) - New linestring object which is contains the directed set of points defining the salesman's path.
 *  EXAMPLE
 *    With data As (
 *      SELECT SDO_GEOMETRY(2005,NULL,NULL,
 *                          SDO_ELEM_INFO_ARRAY(1,1,50),
 *                          SDO_ORDINATE_ARRAY(1597.39,170.16,1374.14,4381.71,7720.98,338.55,
 *                                             9288.02,4197.86,99.25,3835.6,4486.08,769.94,
 *                                             1172.92,4010.55,7203.14,227.14,4946.58,3065.22,
 *                                             3922.71,2841.87,2114.37,1038.88,633.82,2754.83,
 *                                             4911.44,3446.1,4227.88,3860.79,6007.5,2562.07,
 *                                             109.36,4410.63,7965.02,4621.98,6552.41,4739.78,
 *                                             2105.39,956.52,7707.73,4672.84,2853.76,424.77,
 *                                             6436.58,41.46,882.33,4735.71,1196.23,1433.89,
 *                                             247.33,1300.91,2305.01,4556.07,5322.28,3006.77,
 *                                             7840.55,2048.4,5852.83,3900.91,7725.62,4559.27,
 *                                             707.68,0,6445.65,3296.85,9618.51,2502.49,293.1,
 *                                             900.11,7373.91,4209.42,1707.32,3876.35,6503.14,
 *                                             1959.38,0,3205.12,139.89,4699.76,5526.69,4247.66,
 *                                             1165.67,1553.33,6049.36,2047.12,1562.06,1562.93,
 *                                             3773.35,732.55,8844.67,2498.88,2714.68,3630.44,446.82,
 *                                             3063.99,727.39,47.89,4120.27,1188.79,6328.6,2695.57)) as geom
 *        FROM dual
 *    )
 *    select T_Geometry(a.geom,0.005,2,1).ST_TravellingSalesman(3,null).geom as tsGeom
 *      from data a;
 *
 *    TSGEOM
 *    --------------------------------------------------------------------------------------------------------------------------
 *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
 *                 SDO_ORDINATE_ARRAY(7720.98,338.55,7203.14,227.14,6436.58,41.46,6503.14,1959.38,6049.36,2047.12,6007.5,2562.07,
 *                                    6328.6,2695.57,6445.65,3296.85,5852.83,3900.91,5526.69,4247.66,4911.44,3446.1,4946.58,3065.22,
 *                                    5322.28,3006.77,4227.88,3860.79,3922.71,2841.87,2714.68,3630.44,2305.01,4556.07,1707.32,3876.35,
 *                                    1172.92,4010.55,1374.14,4381.71,882.33,4735.71,139.89,4699.76,109.36,4410.63,99.25,3835.6,0,
 *                                    3205.12,446.82,3063.99,633.82,2754.83,1165.67,1553.33,1196.23,1433.89,1562.06,1562.93,2114.37,1038.88,
 *                                    2105.39,956.52,2853.76,424.77,3773.35,732.55,4120.27,1188.79,4486.08,769.94,1597.39,170.16,727.39,47.89,
 *                                    707.68,0,293.1,900.11,247.33,1300.91,6552.41,4739.78,7373.91,4209.42,7725.62,4559.27,7707.73,4672.84,
 *                                    7965.02,4621.98,9288.02,4197.86,9618.51,2502.49,8844.67,2498.88,7840.55,2048.4))
 *
 *     With data As (
 *      SELECT SDO_GEOMETRY(2005,NULL,NULL,
 *                          SDO_ELEM_INFO_ARRAY(1,1,50),
 *                          SDO_ORDINATE_ARRAY(1597.39,170.16,1374.14,4381.71,7720.98,338.55,
 *                                             9288.02,4197.86,99.25,3835.6,4486.08,769.94,
 *                                             1172.92,4010.55,7203.14,227.14,4946.58,3065.22,
 *                                             3922.71,2841.87,2114.37,1038.88,633.82,2754.83,
 *                                             4911.44,3446.1,4227.88,3860.79,6007.5,2562.07,
 *                                             109.36,4410.63,7965.02,4621.98,6552.41,4739.78,
 *                                             2105.39,956.52,7707.73,4672.84,2853.76,424.77,
 *                                             6436.58,41.46,882.33,4735.71,1196.23,1433.89,
 *                                             247.33,1300.91,2305.01,4556.07,5322.28,3006.77,
 *                                             7840.55,2048.4,5852.83,3900.91,7725.62,4559.27,
 *                                             707.68,0,6445.65,3296.85,9618.51,2502.49,293.1,
 *                                             900.11,7373.91,4209.42,1707.32,3876.35,6503.14,
 *                                             1959.38,0,3205.12,139.89,4699.76,5526.69,4247.66,
 *                                             1165.67,1553.33,6049.36,2047.12,1562.06,1562.93,
 *                                             3773.35,732.55,8844.67,2498.88,2714.68,3630.44,446.82,
 *                                             3063.99,727.39,47.89,4120.27,1188.79,6328.6,2695.57)) as geom
 *        FROM dual
 *    )
 *    select T_Geometry(a.geom,0.005,2,1).ST_TravellingSalesman(null,Sdo_Point_Type(359052.5,5407258.2,NULL)).geom as tsGeom
 *      from data a;
 *
 *    TSGEOM
 *    ------------------------------------------------------------------------------------------------------------------------------
 *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
 *                 SDO_ORDINATE_ARRAY(359052.5,5407258.2,7707.73,4672.84,7725.62,4559.27,7965.02,4621.98,7373.91,
 *                                    4209.42,6552.41,4739.78,5852.83,3900.91,5526.69,4247.66,4911.44,3446.1,4946.58,
 *                                    3065.22,5322.28,3006.77,6007.5,2562.07,6328.6,2695.57,6445.65,3296.85,6049.36,2047.12,
 *                                    6503.14,1959.38,7840.55,2048.4,8844.67,2498.88,9618.51,2502.49,9288.02,4197.86,7720.98,338.55,
 *                                    7203.14,227.14,6436.58,41.46,4486.08,769.94,4120.27,1188.79,3773.35,732.55,2853.76,424.77,
 *                                    2105.39,956.52,2114.37,1038.88,1562.06,1562.93,1196.23,1433.89,1165.67,1553.33,247.33,
 *                                    1300.91,293.1,900.11,727.39,47.89,707.68,0,1597.39,170.16,633.82,2754.83,446.82,3063.99,0,
 *                                    3205.12,99.25,3835.6,109.36,4410.63,139.89,4699.76,882.33,4735.71,1374.14,4381.71,1172.92,
 *                                    4010.55,1707.32,3876.35,2305.01,4556.07,2714.68,3630.44,3922.71,2841.87,4227.88,3860.79))
 *  NOTE
 *    This is a naive, simple, and inefficient algorithm.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2016 - Original coding.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_TravellingSalesman(p_start_gid   in integer,
                                        p_start_point in mdsys.sdo_point_type default NULL,
                                        p_geo_fence   in mdsys.sdo_geometry   default NULL,
                                        p_unit        in varchar2             default NULL )
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

-- ========================================================================================
-- ==================================== INPUT / OUTPUT ====================================
-- ========================================================================================

/****m* T_GEOMETRY/ST_Compress
  *  NAME
  *   ST_Compress - Turns coordinate array of linestring/polygon into equivalent to MoveTo and LineTo components.
  *  SYNOPSIS
  *    Member Function ST_Decompress(p_delta_factor in number default 1,
  *                                  p_origin       in &&INSTALL_SCHEMA..T_Vertex default null )
  *             Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
  *  DESCRIPTION
  *    Starting point as abolute value is kept if p_origin is null.
  *    p_origin could contain lower left ordinate of the MBR of the geometry.
  *    Extracts pairs of adjacent vertices, substracts their ordinates and applies delta factor.
  *    p_delta_factor is scalar applied to difference between two vertices in a linestring.
  *    EG:
  *      * 1.0 leaves delta XY alone
  *      * 0.5 divides each delta x and y by 2
  *      * 0.1 divides each delta x and y by 10
  *    No rounding occurs as full precision is needed for ST_Decompress.
  *  ARGUMENTS
  *    p_delta_factor (number)   -- Coordinate delta multiplying factor.
  *    p_origin       (t_vertex) -- Contains starting point for decompressing geometry cf MoveTo in SVG.
  *  RESULT
  *    Compressed Linestring (t_geometry) - New polygon/linestring object with coordinates compressed.
  *  EXAMPLE
  *    -- ST_Compress
  *    With data As (
  *    select 0.1 as delta_factor,
  *           t_geometry(Sdo_Geometry(2002,2154,Null,
  *                                   Sdo_Elem_Info_Array(1,2,1),
  *                                   Sdo_Ordinate_Array(210124.235,6860562.134, 189291.0,6855606.0, 185644.0,6870204.0, 130465.0,6856274.0, 124851.0,6831829.0, 162802.0,6840716.0, 148600.0,6829212.0, 162326.0,6831137.0)),
  *                      0.005,2,1) as original,
  *           t_vertex(
  *             p_x=>210124.235,
  *             p_y=>6860562.134,
  *             p_id=>0,
  *             p_sdo_gtype=>2001,
  *             p_sdo_srid=>2154
  *           ) as origin
  *      from dual
  *    )
  *    Select DBMS_LOB.GetLength(f.original.ST_AsText()  ) as originalSize,
  *           DBMS_LOB.GetLength(f.compressed.ST_AsText()) as compressedSize,
  *           f.compressed.ST_AsText()                     as compressed
  *      From (Select a.original
  *                     .ST_Compress(
  *                         p_delta_factor => a.delta_factor,
  *                         P_origin       => a.origin
  *                     ) As compressed,
  *                   a.original,
  *                   a.delta_factor,
  *                   a.origin
  *             From data a
  *            ) f;
  *
  *    ORIGINALSIZE COMPRESSEDSIZE COMPRESSED
  *    ------------ -------------- ---------------------------------------------------------------------------------------------------------------------------------------
  *             175            135 LINESTRING (0.0 0.0, -2083.3235 -495.6134, -364.7 1459.8, -5517.9 -1393.0, -561.4 -2444.5, 3795.1 888.7, -1420.2 -1150.4, 1372.6 192.5)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - December 2015 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_Compress (p_delta_factor in number default 1,
                               p_origin       in &&INSTALL_SCHEMA..T_Vertex default null )
           Return &&INSTALL_SCHEMA..T_Geometry DETERMINISTIC,

 /****m* T_GEOMETRY/ST_Decompress
  *  NAME
  *   ST_Decompress - Reverse Compress applied by ST_Compress with same p_factor_applied and p_origin.
  *  SYNOPSIS
  *    Member Function ST_Decompress(p_delta_factor in number default 1)
  *             Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
  *  DESCRIPTION
  *    Starting point as abolute value is kept if p_origin is null.
  *    p_origin could contain lower left ordinate of the MBR of the geometry.
  *    Extracts pairs of adjacent vertex deltas, applies inverse delta factor to each, and creates new point.
  *    p_delta_factor is scalar applied to difference between two vertices in a linestring.
  *    Must be same p_delta_factor applied to original ST_Compress:
  *      * 1.0 leaves delta XY alone
  *      * 0.5 divides each delta x and y by 2
  *      * 0.1 divides each delta x and y by 10
  *  ARGUMENTS
  *    p_delta_factor (number)   -- Coordinate delta multiplying factor.
  *    p_origin       (t_vertex) -- Contains starting point for decompressing geometry cf MoveTo in SVG.
  *  RESULT
  *    Decompressed Linestring (t_geometry) - New polygon/linestring object with coordinates compressed.
  *  EXAMPLE
  *    -- ST_Decompress
  *    With data As (
  *    select 0.1 as delta_factor,
  *           t_geometry(Sdo_Geometry(2002,2154,Null,
  *                                   Sdo_Elem_Info_Array(1,2,1),
  *                                   Sdo_Ordinate_Array(210124.235,6860562.134, 189291.0,6855606.0, 185644.0,6870204.0, 130465.0,6856274.0, 124851.0,6831829.0, 162802.0,6840716.0, 148600.0,6829212.0, 162326.0,6831137.0)),
  *                      0.005,2,1) as original,
  *           t_vertex(
  *             p_x=>210124.235,
  *             p_y=>6860562.134,
  *             p_id=>0,
  *             p_sdo_gtype=>2001,
  *             p_sdo_srid=>2154
  *           ) as origin
  *      from dual
  *    )
  *    Select DBMS_LOB.GetLength(f.original.ST_AsText()  ) as originalSize,
  *           DBMS_LOB.GetLength(f.compressed.ST_AsText()) as compressedSize,
  *           f.compressed
  *            .ST_Decompress(
  *               p_delta_factor => f.delta_factor,
  *               P_origin       => f.origin
  *           ).ST_Equals(
  *               p_geometry    => f.original.geom,
  *               p_z_precision => null,
  *               p_m_precision => null
  *           ) as before_after_equals,
  *           f.compressed.ST_AsText() as compressed
  *      From (Select a.original
  *                     .ST_Compress(
  *                         p_delta_factor => a.delta_factor,
  *                         P_origin       => a.origin
  *                     ) As compressed,
  *                   a.original,
  *                   a.delta_factor,
  *                   a.origin
  *             From data a
  *            ) f;
  *
  *    ORIGINALSIZE COMPRESSEDSIZE BEFORE_AFTER_EQUALS COMPRESSED
  *    ------------ -------------- ------------------- --------------------------------------------------------------------------------------------------------------------------------------
  *             175            135               EQUAL LINESTRING (0.0 0.0, -2083.3235 -495.6134, -364.7 1459.8, -5517.9 -1393.0, -561.4 -2444.5, 3795.1 888.7, -1420.2 -1150.4, 1372.6 192.5)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - December 2015 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_Decompress (p_delta_factor in number default 1,
                                 p_origin       in &&INSTALL_SCHEMA..T_Vertex default null )
           Return &&INSTALL_SCHEMA..T_Geometry DETERMINISTIC,

  /** Point Structure Utilities */

  /****m* T_GEOMETRY/ST_SdoPoint2Ord
  *  NAME
  *    ST_SdoPoint2Ord -- Changes point encoding from SDO_POINT_TYPE to SDO_ELEM_INFO_ARRAY/SDO_ORDINATE_ARRAY.
  *  SYNOPSIS
  *   Function ST_SdoPoint2Ord
  *     Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic
  *  DESCRIPTION
  *    Converts underlying Point encoded in SDO_POINT_TYPE structure to one
  *    encoded in sdo_elem_info_array/sdo_ordinate_array elements.
  *    Honours any measure
  *  RESULT
  *    SELF (TO_GEOMETRY) -- Original Point with structure changed.
  *  EXAMPLE
  *    select &&INSTALL_SCHEMA..T_Geometry(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(10.719,8.644,NULL),NULL,NULL),0.005,3,1)
  *                           .ST_SdoPoint2Ord()
  *                           .geom as geom 
  *     from dual;
  *    
  *    GEOM
  *    -----------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2001, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 1, 1), SDO_ORDINATE_ARRAY(10.719, 8.644))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener, Jan 2013 - Port to Object method.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SdoPoint2Ord
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_Ord2SdoPoint
  *  NAME
  *    ST_Ord2SdoPoint -- Changes point encoding from SDO_ELEM_INFO_ARRAY/SDO_ORDINATE_ARRAY to SDO_POINT_TYPE.
  *  SYNOPSIS
  *   Function ST_Ord2SdoPoint
  *     Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic
  *  DESCRIPTION
  *    Converts underlying point encoded in SDO_ELEM_INFO_ARRAY/SDO_ORDINATE_ARRAY
  *    elements to one encoded in SDO_POINT_TYPE element.
  *    Gives precidence to measure where exists and point is 4D.
  *  RESULT
  *    SELF (TO_GEOMETRY) -- Original Point with structure changed.
  *  EXAMPLE
  *    select &&INSTALL_SCHEMA..T_Geometry(SDO_GEOMETRY(2005, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 1, 1), SDO_ORDINATE_ARRAY(10.719, 8.644)),0.005,3,1)
  *                           .ST_Ord2SdoPoint()
  *                           .geom as geom 
  *     from dual;
  *    
  *    GEOM
  *    -------------------------------------------------------------------------
  *    SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(10.719, 8.644, NULL), NULL, NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener, Jul 2017 - New Method.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Ord2SdoPoint
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_toMultiPoint
  *  NAME
  *    ST_toMultiPoint -- Adds SDO_POINT_TYPE to existing SDO_ORDINATE_ARRAY.
  *  SYNOPSIS
  *   Function ST_toMultiPoint
  *     Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic
  *  DESCRIPTION
  *    Converts underlying geometry by adding ordinate data in SDO_POINT_TYPE structure 
  *    to point data held in sdo_elem_info_array/sdo_ordinate_array elements.
  *    Honours any measure (if measure is Z ordinate in SDO_POINT_TYPE.
  *  RESULT
  *    SELF (TO_GEOMETRY) -- Original geometry with SDO_POINT added to SDO_ORDINATES
  *  EXAMPLE
  *    select &&INSTALL_SCHEMA..T_Geometry(SDO_GEOMETRY(2005,NULL,SDO_POINT_TYPE(10.719,8.644,NULL),SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,10)),0.005,3,1)
  *                           .ST_ToMultiPoint()
  *                           .geom as geom 
  *     from dual;
  *    
  *    GEOM
  *    ---------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2005,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,2),SDO_ORDINATE_ARRAY(8,10,10.719,8.644))
  *  NOTES
  *    See also ST_SdoPoint2Ord and ST_Ord2SdoPoint.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener, January 2013 - Port to Object method.
  *    Simon Greener, August 2019  - Documented and fixed operation.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_toMultiPoint
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  -- =================== Dimensional Adjustment =====================

  /****m* T_GEOMETRY/ST_To2D
  *  NAME
  *    ST_To2D -- Converts underlying 3D or 4D mdsys.sdo_geometry to 2D (xy).
  *  SYNOPSIS
  *    Member Function ST_To2D
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic
  *  DESCRIPTION
  *    This Function checks if underlying mdsys.sdo_geometry is 2D and returns unchanged.
  *    If mdsys.sdo_geometry has more than xy ordinates (ie xyz or xym or xyzm) the geometry
  *    is stripped of its non-xy ordinates, returning a 2D mdsys.sdo_geometry with only XY ordinates.
  *  RESULT
  *    SELF (TO_GEOMETRY) -- With 2D Underlying mdsys.sdo_geometry.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Albert Godfrind, July 2006, Original Coding
  *    Bryan Hall,      July 2006, Modified to handle points
  *    Simon Greener,   July 2006, Integrated into geom with GF.
  *    Simon Greener,   Aug  2009, Removed GF; Modified Byan Hall's version to handle compound elements.
  *    Simon Greener,   Jan 2013 - Port to Object method.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_To2D
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_To3D(p_zOrdToKeep)
  *  NAME
  *    ST_To3D -- Converts underlying 2D or 4D geometry to a 3D geometry.
  *  SYNOPSIS
  *    Member Function ST_To3D (p_zOrdToKeep IN Integer)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic
  *  DESCRIPTION
  *    This Function checks if underlying mdsys.sdo_geometry is 2D, converts it to 3D with NULL Z ordinates.
  *    If mdsys.sdo_geometry is 4D it is reduced to 3D with p_zordtokeep indicating which non-2D ordinate
  *    to keep eg if 4 then result is XYW; if 3 then XYZ.
  *  ARGUMENTS
  *    p_zOrdToKeep -- Ignored if 2D, otherwise if moving down from 4D to 3D indicates which ord to keep ie 3 or 4 (cf LRS)
  *  RESULT
  *    New 3D Geom (T_GEOMETRY) -- Underlying mdsys.sdo_geometry reduced or increased to 3D.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener,   May 2007 Original coding in GEOM package.
  *    Simon Greener,   Aug 2009 Added support for interpolating Z values
  *    Simon Greener,   Jan 2013 - Port to Object method.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_To3D(p_zordtokeep IN Integer)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_To3D(p_start_z p_end_z p_unit)
  *  NAME
  *    ST_To3D -- Converts underlying 2D or 4D geometry to a 3D geometry.
  *  SYNOPSIS
  *    Member Function ST_To3D(p_start_z IN Number,
  *                            p_end_z   IN Number,
  *                            p_unit    IN varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic
  *  DESCRIPTION
  *    If underlying mdsys.sdo_geometry object is a 2D line, it converts it to 3D with supplied start and end z values.
  *    If mdsys.sdo_geometry is 4D it is reduced to 3D with any measures being removed.
  *    Z ordinates are using start and end values ie result is XYZ.
  *  ARGUMENTS
  *    p_start_z (Number) -- Assigned to first coordinates' new Z ordinate.
  *    p_end_z   (Number) -- Assigned to last coordinate's new Z ordinate.
  *    p_unit  (VarChar2) -- Unit of measure for distance calculations.
  *  RESULT
  *    New Geom (TO_GEOMETRY) -- 3D mdsys.sdo_geometry line encoded with start and end z ordinate vakyes.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener,   May 2007 Original coding in GEOM package.
  *    Simon Greener,   Aug 2009 Added support for interpolating Z values
  *    Simon Greener,   Jan 2013 - Port to Object method.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_To3D(p_start_z IN Number,
                          p_end_z   IN Number,
                          p_unit    in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_To3D(p_default_z)
  *  NAME
  *    ST_FixZ -- Replaces and measure/elevation NULL values with supplied value eg -9999
  *  SYNOPSIS
  *    Member Function ST_FixZ(p_default_z IN Number := -9999 )
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic
  *  DESCRIPTION
  *    It is not uncommon to see linear geometries having a Z or W/M value encoded as NULL while others have numeric values.
  *    This function allows for the replacement of the NULL values with a provided value.
  *  ARGUMENTS
  *    p_default_z (Number) -- New geometry with all Z ordinates to the supplied value.
  *  RESULT
  *    SELF (TO_GEOMETRY) -- Corrected mdsys.sdo_geometry object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener,   May 2007 Original coding in GEOM package.
  *    Simon Greener,   Aug 2009 Added support for interpolating Z values
  *    Simon Greener,   Jan 2013 - Port to Object method.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_FixZ(p_default_z IN Number := -9999 )
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

/****m* T_GEOMETRY/ST_Tile
 *  NAME
 *    ST_Tile -- Covers envelope of supplied goemetry with a mesh of tiles of size p_Tile_X and p_Tile_Y.
 *  SYNOPSIS
 *    Member Function ST_Tile (
 *       p_tile_X    in number,
 *       p_tile_Y    in number,
 *       p_grid_type in varchar2 Default 'TILE',
 *       p_option    in varchar2 default 'TOUCH',
 *       p_unit      in varchar2 default NULL
 *    )
 *    Returns T_GRIDS PIPELINED
 *  USAGE
 *    With poly As (
 *         select t_geometry(sdo_geometry('POLYGON ((0 0,10 0,10 10,0 10,0 0))',null),0.005,2,1) as poly from dual
 *    )
 *    select row_number() over (order by t.gcol, t.grow) as rid,
 *           t.gCol, t.gRow, t.geom.get_wkt()  as geom
 *      FROM poly a,
 *           TABLE(a.poly.ST_Tile(5.0,5.0,'TILE','TOUCH',NULL)) t;
 *
 *    RID GCOL GROW GEOM
 *    --- ---- ---- ---------------------------------------
 *      1    0    0 POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0))
 *      2    0    1 POLYGON ((0 5, 5 5, 5 10, 0 10, 0 5))
 *      3    1    0 POLYGON ((5 0, 10 0, 10 5, 5 5, 5 0))
 *      4    1    1 POLYGON ((5 5, 10 5, 10 10, 5 10, 5 5))
 *
 *  DESCRIPTION
 *    Function that computes spatial extent of internal geometry, then uses the
 *    p_tile_x and p_tile_y extents to compute the number of tiles that cover it.
 *    The number of columns and rows (tiles) that cover this area is calculated using p_Tile_X/p_Tile_Y which are in SRID units.
 *    The tiles are written out with their col/row reference using the T_GRID object type
 *    All rows and columns are visited, with geometry objects being created that represent each tile.
 *    Geometry object created can be:
 *      TILE  -- Single polygon per grid cell/Tile (optimized rectangle).
 *      POINT -- Centre point of each grid cell/Tile
 *      BOTH  -- Single polygon per grid cell/Tile (optimized rectangle) with centre point coded in SDO_POINT_TYPE structure.
 *    When polygon tiles are to be returned, they can represent:
 *      MBR       -- The entire extent of the underlying geometry;
 *      TOUCH     -- Just those touching the input geometry (Intersects);
 *      CLIP      -- Where tile has geometric intersection with the underlying geometry it is clipped to the underlying geometry.
 *      HALFCLIP  -- Clipped tiles that touch boundary where area is > 1/2 tile
 *      HALFTOUCH -- Tiles that touch boundary where area is > 1/2 tile
 *  ARGUMENTS
 *    p_Tile_X      (number) -- Size of a Tile's X dimension in real world units.
 *    p_Tile_Y      (number) -- Size of a Tile's Y dimension in real world units.
 *    p_grid_type (varchar2) -- Returned geometry is either 'TILE','POINT' or 'BOTH'
 *    p_option    (varchar2) -- MBR       -- Tiles for all geometry's MBR
 *                              TOUCH     -- Only tiles that touch geometry
 *                              CLIP      -- Return tiles for geometry only but clip using geometry boundary
 *                              HALFCLIP  -- Return clipped tiles that touch boundary where area is > 1/2 tile
 *                              HALFTOUCH -- Return tiles that touch boundary where area is > 1/2 tile
 *    p_unit      (varchar2) -- Unit of measure for distance calculations.
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      gcol Integer      -- The column reference for a tile
 *      grow Integer      -- The row reference for a tile
 *      geom sdo_geometry -- The polygon geometry covering the area of the Tile.
 *    )
 *  NOTES
 *    Following exceptions can the thrown:
 *      -20120 'Geometry must not be null or empty (*ERR*)'
 *      -20121 'Unsupported geometry type (*GTYPE*)'
 *      -20122 'p_grid_type parameter value (*VALUE*) must be TILE, POINT or BOTH'
 *      -20123 'p_option value (*VALUE*) must be MBR, TOUCH, CLIP, HALFCLIP or HALFTOUCH.'
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2006 - Original Coding for GEOM package.
 *    Simon Greener - July 2011     - Port to T_GEOMETRY.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
   Member Function ST_Tile(p_Tile_X    In number,
                          p_Tile_Y    In Number,
                          p_grid_type in varchar2 Default 'TILE',
                          p_option    in varchar2 default 'TOUCH',
                          p_unit      in varchar2 default null)
            Return &&INSTALL_SCHEMA..T_Grids Pipelined,

 /****m* T_GEOMETRY/ST_SmoothTile
  *  NAME
  *    ST_SmoothTile -- Smoothly polygon created from raster to segment conversion
  *  SYNOPSIS
  *    Member Function ST_SmoothTile
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    A polygon created from raster to segment conversion, will have many vertices falling
  *    along the same straight line. And whose sides will be "stepped".
  *    This function removes coincident points on a side so that a side will be defined by
  *    only a start and end vertex. The stepped sies will be replaced with vertices in the midpoint of each step
  *    so that any consistent stepped side will be replaced by a single line.
  *  NOTES
  *    Only supports polygons and multipolygons.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Grid shaped polygon replaced by polygons with straight sides.
  *  NOTES
  *    Uses
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 - Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SmoothTile
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

 /****m* T_GEOMETRY/ST_RemoveCollinearPoints
  *  NAME
  *    ST_RemoveCollinearPoints -- Removes any collinear points in a linestring
  *  SYNOPSIS
  *    Member Function ST_RemoveColliearPoints
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    Removes any collinear points in a linestring
  *    Collinear points are any three points in a line allowing for the middle one to be removed.
  *    SELF.dprecision is vital to determining collinearity.
  *  NOTES
  *    Only supports linestrings, multilinestrings.
  *    Does not support linestrings with circular arcs.
  *  RESULT
  *    geometry (T_GEOMETRY) -- geometry with any collinear points removed.
  *  TODO
  *    Support polygon and multipolygons.
  *    Support linestrings with circular arcs.
  *  EXAMPLE
  *    -- 1. ST_RemoveCollinearPoints
  *    with data as (
  *    select t_geometry(f.geom,0.005,2,1) as tGeom,
  *           f.test
  *      from (select 'Is Collinear 3D' as test, sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,0,10,10,10,20,20,20)) as geom
  *              from dual
  *             union all
  *            select 'Is Collinear 2D' as test, sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,10,10,20,20)) as geom
  *              from dual
  *             union all
  *            select 'Not Collinear 3D' as test, sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,0, 10,11,10, 20,0,21)) as geom
  *              from dual
  *             union all
  *            select 'Not Collinear 2D' as test,
  *                   sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,10,10,20,0)) as geom
  *              from dual
  *           ) f
  *    )
  *    select a.tGeom.ST_Dims() as dims,
  *           a.test,
  *           a.tGeom.ST_RemoveCollinearPoints().geom as rcpGeom
  *      from data a;
  *
  *    DIMS TEST             RCPGEOM
  *    ---- ---------------- --------------------------------------------------------------------------------------------------
  *       3 Is Collinear 3D  SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,0,20,20,20))
  *       2 Is Collinear 2D  SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,20,20))
  *       3 Not Collinear 3D SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,0,10,11,10,20,0,21))
  *       2 Not Collinear 2D SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,10,10,20,0))
  *
  *    -- 2. MultiLineString 3D Geometries.
  *    with data as (
  *    select t_geometry(f.geom,0.005,2,1) as tGeom,
  *           f.test
  *      from (select 'Collinear First and Second LineStrings (same Z)' as test,
  *                    sdo_geometry(3006,null,null,sdo_elem_info_array(1,2,1,10,2,1),
  *                                 sdo_ordinate_array(  0,  0, 0,  10, 10, 0,  20, 20, 0,
  *                                                    100,100,90, 110,110,90, 200,200,90)) as geom
  *              from dual
  *             union all
  *            select 'Multi: Collinear First Linestring (same Z), Not Collinear Second LineString (diff Z)' as test,
  *                   sdo_geometry(3006,null,null,sdo_elem_info_array(1,2,1,10,2,1),
  *                                sdo_ordinate_array(0,0,0,       10,10,10,   20, 20,20,
  *                                                   100,100,90, 110,120,90, 200,201,95)) as geom
  *              from dual
  *             union all
  *            select 'Multi: Neither part with collinear points' as test,
  *                   sdo_geometry(3006,null,null,sdo_elem_info_array(1,2,1,10,2,1),
  *                                sdo_ordinate_array(0,0,0,       10,10,10,   20,  0,20,
  *                                                   100,100,90, 110,120,75, 200, 1,50)) as geom
  *              from dual
  *           ) f
  *    )
  *    select a.tGeom.ST_Dims() as dims,
  *           a.test,
  *           a.tGeom.ST_RemoveCollinearPoints().geom as rcp
  *      from data a;
  *
  *    DIMS TEST                                            RCP
  *    ---- ----------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------
  *       3 Collinear First and Second LineStrings (same Z) SDO_GEOMETRY(3006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,7,2,1),SDO_ORDINATE_ARRAY(0,0,0,20,20,0,100,100,90,200,200,90))
  *       3 Multi: Collinear First Linestring (same Z),
  *                Not Collinear Second LineString (diff Z) SDO_GEOMETRY(3006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,7,2,1),SDO_ORDINATE_ARRAY(0,0,0,20,20,20,100,100,90,110,120,90,200,201,95))
  *       3 Multi: Neither part with collinear points       SDO_GEOMETRY(3006,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,10,2,1),SDO_ORDINATE_ARRAY(0,0,0,10,10,10,20,0,20,100,100,90,110,120,75,200,1,50))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - February 2018 - Original TSQL Coding for SQL Spatial.
  *    Simon Greener - August 2018   - Port to Oracle.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_RemoveCollinearPoints
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

 /****m* T_GEOMETRY/ST_Densify
  *  NAME
  *    ST_Densify -- Implements a basic geometry densification algorithm.
  *  SYNOPSIS
  *    Member Function ST_Densify(p_distance In Number,
  *                               p_unit     In Varchar2 Default NULL)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    This function add vertices to an existing vertex-to-vertex described (m)linestring or (m)polygon sdo_geometry.
  *    New vertices are added in such a way as to maintain existing vertices.
  *    That is, no existing vertices are removed.
  *    Densification occurs on a single vertex-to-vertex segment basis.
  *    If segment length is < p_distance no vertices are added.
  *    No vertex is ever added such that the distance to the next vertex is < SELF.tolerance.
  *    The implementation does not guarantee that the added vertices will be exactly p_distance apart.
  *    The final vertex separation will be BETWEEN p_distance AND p_distance * 2 .
  *
  *    The implementation honours 3D and 4D shapes and averages these dimension values
  *    for the new vertices.
  *
  *    The function does not support compound objects or objects with circles,
  *    optimised rectangles or described by arcs.
  *
  *    Any non (m)polygon/(m)linestring shape is simply returned as it is.
  *  ARGUMENTS
  *    p_distance (Number) -- The desired optimal distance between added vertices. Must be > SELF.tolerance.
  *    p_unit   (varchar2) -- Unit of measure associated with p_distance and for calculations.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Densified geometry.
  *  EXAMPLE
  *     -- Simple Straight line.
  *    select t_geometry(
  *             sdo_geometry(2002,NULL,NULL,
  *                          sdo_elem_info_array(1,2,1),
  *                          sdo_ordinate_array(100,100,900,900.0)),
  *             0.005,2,1)
  *             .ST_Densify(p_distance=>125.0,
  *                         p_unit=>null)
  *             .ST_Round(3,3,2,1)
  *             .geom as geom
  *      from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(188.889,188.889,277.778,277.778,366.667,366.667,455.556,455.556,544.444,544.444,633.333,633.333,722.222,722.222,811.111,811.111))
  *
  *    -- Simple Linestring with Z
  *    select t_geometry(
  *             sdo_geometry(3002,NULL,NULL,
  *                          sdo_elem_info_array(1,2,1),
  *                          sdo_ordinate_array(100,100,1.0, 900,900.0,9.0)),
  *             0.005,2,1)
  *             .ST_Densify(p_distance=>125.0,
  *                         p_unit=>null)
  *             .ST_Round(3,3,2,1)
  *             .geom as geom
  *      from dual;
  *
  *    GEOM
  *    -------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3002,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1),
  *                 SDO_ORDINATE_ARRAY(100,100,1,188.889,188.889,1.89,277.778,277.778,2.78,366.667,366.667,3.67,455.556,455.556,4.56,
  *                                    544.444,544.444,5.44,633.333,633.333,6.33,722.222,722.222,7.22,811.111,811.111,8.11,900,900,9))
  *
  *    -- Simple LineString with Z and Measures
  *    select t_geometry(
  *             sdo_geometry(4402,NULL,NULL,
  *                          sdo_elem_info_array(1,2,1),
  *                          sdo_ordinate_array(100,100,  -4.56,   0.99, 
  *                                             900,900.0,-6.73,1131.2)),
  *             0.005,2,1)
  *             .ST_Densify(p_distance=>125.0,
  *                         p_unit=>null)
  *             .ST_Round(3,3,2,2)
  *             .geom as geom
  *      from dual;
  *
  *    GEOM
  *    ----------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(4402,NULL,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1),
  *                 SDO_ORDINATE_ARRAY(100.0,100.0,-4.56,0.99, 166.667,166.667,-4.74,95.17, 233.333,233.333,-4.92,189.36, 300.0,300.0,-5.1,283.54, 
  *                                    366.667,366.667,-5.28,377.73, 433.333,433.333,-5.46,471.91, 500.0,500.0,-5.65,566.1, 566.667,566.667,-5.83,660.28,
  *                                    633.333,633.333,-6.01,754.46, 700.0,700.0,-6.19,848.65, 766.667,766.667,-6.37,942.83, 833.333,833.333,-6.55,1037.02, 
  *                                    900.0,900.0,-6.73,1131.2))
  *
  *    with data as (
  *      select t_geometry(
  *               SDO_GEOMETRY(2002,NULL,NULL,
  *                            SDO_ELEM_INFO_ARRAY(1,2,1),
  *                            SDO_ORDINATE_ARRAY(
  *                              1100.765,964.286, 1161.99,739.796, 963.01,596.939, 677.296,775.51,
  *                              460.459,880.102, 253.827,793.367, 174.745,630.102, 228.316,497.449,
  *                              455.357,528.061, 718.112,446.429, 713.01,290.816, 598.214,125.0,
  *                              373.724,81.633, 67.602,267.857)),
  *               0.05,2,1)
  *                as "Original Geometry"
  *      from dual
  *    )
  *    select a."Original Geometry".ST_Densify(p_distance=>25.0).ST_Round(2).geom as "Densified Geometry" from data a;
  *
  *    Densified Geometry
  *    --------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1100.77,964.29,1107.57,939.34,1114.37,914.4,1121.17,889.46,1127.98,864.51,
  *                 1134.78,839.57,1141.58,814.63,1148.38,789.68,1155.19,764.74,1161.99,739.8,1139.88,723.92,1117.77,708.05,1095.66,692.18,1073.55,676.3
  *                 1051.45,660.43,1029.34,644.56,1007.23,628.69,985.12,612.81,963.01,596.94,941.03,610.68,919.05,624.41,897.08,638.15,875.1,651.88,853.12,
  *                  665.62,831.14,679.36,809.16,693.09,787.19,706.83,765.21,720.57,743.23,734.3,721.25,748.04,699.27,761.77,677.3,775.51,653.2,787.13,629.11,
  *                  798.75,605.02,810.37,580.92,822,556.83,833.62,532.74,845.24,508.65,856.86,484.55,868.48,460.46,880.1,434.63,869.26,408.8,858.42,382.97,
  *                  847.58,357.14,836.73,331.31,825.89,305.49,815.05,279.66,804.21,253.83,793.37,242.53,770.04,231.23,746.72,219.93,723.4,208.64,700.07,197.34,
  *                  676.75,186.04,653.43,174.75,630.1,185.46,603.57,196.17,577.04,206.89,550.51,217.6,523.98,228.32,497.45,253.54,500.85,278.77,504.25,304,507.65,
  *                  329.22,511.05,354.45,514.46,379.68,517.86,404.9,521.26,430.13,524.66,455.36,528.06,479.24,520.64,503.13,513.22,527.02,505.8,550.9,498.38,574.79,
  *                  490.96,598.68,483.53,622.56,476.11,646.45,468.69,670.34,461.27,694.23,453.85,718.11,446.43,717.26,420.49,716.41,394.56,715.56,368.62,714.71,
  *                  342.69,713.86,316.75,713.01,290.82,698.66,270.09,684.31,249.36,669.96,228.64,655.61,207.91,641.26,187.18,626.91,166.45,612.56,145.73,598.21,125,
  *                  573.27,120.18,548.33,115.36,523.38,110.54,498.44,105.73,473.5,100.91,448.55,96.09,423.61,91.27,398.67,86.45,373.72,81.63,351.86,94.93,329.99,
  *                  108.24,308.13,121.54,286.26,134.84,264.39,148.14,242.53,161.44,220.66,174.75,198.8,188.05,176.93,201.35,155.07,214.65,133.2,227.95,111.33,241.25,
  *                  89.47,254.56,67.6,267.86))
  *  NOTES
  *    Only supports stroked (m)linestrings and (m)polygon rings.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June   2006 - Original coding in GEOM package.
  *    Simon Greener - August 2018 - Port/Rewrite to T_GEOMETRY object function member.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Densify(p_distance In Number,
                             p_unit     In Varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

 /****m* T_GEOMETRY/ST_LineShift
  *  NAME
  *    ST_LineShift -- Moves linestring parallel to imaginary line drawnn from first to last vertex.
  *  SYNOPSIS
  *    Member Function ST_LineShift(p_distance in number)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    Function that extracts the first and last vertex of a linestring, compute a single offset at right angles to an
  *    imaginary line from first to last vertex, then apply offset to all vertices in the linestring.
  *    Is a "simple" version of the more complex ST_Parallel.
  *  ARGUMENTS
  *    p_distance (Number)   - Value +/- integer value.
  *  NOTES
  *    Only supports linestrings.
  *  TODO
  *    Add support for SRID units of measure (ie parameter p_unit).
  *  RESULT
  *    geometry (T_GEOMETRY) -- Input linestring moved parallel by p_distance units
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - December 2008 - Original coding in GEOM package.
  *    Simon Greener - January 2013  - Port/Rewrite to T_GEOMETRY object function member.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LineShift (p_distance in number)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

 /****m* T_GEOMETRY/ST_Parallel
  *  NAME
  *    ST_Parallel -- Moves linestring parts of underlying Geometry left (-ve) or right (+ve)  depending of distance value.
  *  SYNOPSIS
  *    Member Function ST_Parallel(p_offset in number,
  *                                p_curved in number default 0,
  *                                p_unit   in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    Function that moves the linestring components of the underlying mdsys.sdo_geometry left/right by a fixed amount.
  *    Bends in the linestring, when moved, can remain vertex-connected or be converted to curves.
  *    Does not handle situations where supplied distance results in a segment disappearing.
  *  ARGUMENTS
  *    p_offset  (Number) - Value +/- integer value.
  *    p_curved (Integer) - Boolean flag
  *    p_unit  (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Input geometry moved parallel by p_distance units
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - December 2008 - Original coding in GEOM package.
  *    Simon Greener - January 2013  - Port/Rewrite to T_GEOMETRY object function member.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Parallel(p_offset in number,
                              p_curved in number default 0,
                              p_unit   in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_Rectangle
  *  NAME
  *    ST_Rectangle -- Creates a rectangle polygon around all point objects within the underlying mdsys.sdo_geometry.
  *  SYNOPSIS
  *    Member Function ST_Rectangle(p_length in number,
  *                                 p_width  in number)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
  *  DESCRIPTION
  *    Function that creates a rectangle/polygon geometry around each point in the underlying point/multipoint mdsys.sdo_geometry.
  *    As there is no angle parameter, the rectangles are oriented to the XY axes.
  *    If the rectangles need to be rotated, consider using ST_Rotate until such time that this function is modified to support angles.
  *  ARGUMENTS
  *    p_length (Number)   - +ve value that describes the longest side of the retangle.
  *    p_width  (Number)   - +ve value that describes the shortest side of the retangle.
  *  NOTES
  *    Only supports point or multipoint geometries.
  *    If geometry is measured, measure will be lost.
  *  TODO
  *    Add support for rotating the rectangles by adding a p_angle and a p_unit parameter.
  *  RESULT
  *    geometry (T_GEOMETRY) -- (Multi)Polygon geometry where all input vertices are converted to rectangles.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013  - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Rectangle(p_length in number,
                               p_width  in number)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,


  /****m* T_GEOMETRY/ST_Centroid_L
  *  NAME
  *    ST_Centroid_L -- Creates a centroid for a linestring mdsys.sdo_geometry object.
  *  SYNOPSIS
  *    Member Function ST_Centroid_L(p_option in varchar2 := 'LARGEST',
  *                                  p_unit   in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    This function creates a single centroid if the line-string being operated on
  *    has a single part. The position of the centroid is either the mid-length point
  *    if the line is not measured, or the mid-measure position if measured. For a single
  *    line-string any supplied p_option value is ignored.
  *    If the geometry is a multi-linestring a number of options are available.
  *       - LARGEST  -- Returns centroid of largest (measure/length) line-string in multi-linestring (DEFAULT)
  *       - SMALLEST -- Returns centroid of smallest (measure/length) line-string in multi-linestring
  *       - MULTI    -- Returns all centroid for all parts of multi-linestring as a single multi-point (x005 gtype) geometry.
  *    The centroid of each part is constructed using the same rules as for a single line-string.
  *  ARGUMENTS
  *    p_option (VarChar2) - LARGEST, SMALLEST, or MULTI. Ignored if single linestring.
  *    p_unit   (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    point (T_GEOMETRY) - Centroid of input object.
  *  EXAMPLE
  *    -- Largest
  *    -- Smallest
  *    -- Multi
  *  AUTHOR
  *    Simon Greener
  *    Simon Greener - January 2006 - Original coding.
  *    Simon Greener - January 2012 - Added p_seed_x support.
  *    Simon Greener - August  2018 - Added to T_GEOMETRY.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Centroid_L(p_option in varchar2 := 'LARGEST',
                                p_unit   in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_Centroid_P
  *  NAME
  *    ST_Centroid_P -- Creates a centroid for a multipoint object.
  *  SYNOPSIS
  *    Member Function ST_Centroid_P
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    This function creates a single centroid from the underlying MultiPoint geometry.
  *    If the underlying geometry is a point, it is returned.
  *    If the underlying geometry is not a point or multipoint an exception is thrown.
  *    The centroid is returned with the XY ordinates rounded to SELF.dPrecision.
  *    Measured (4x05) objects are not supported.
  *  RESULT
  *    point (T_GEOMETRY) - Centroid of input object.
  *  EXAMPLE
  *    -- Single point is returned as it is.
  *    select T_Geometry(sdo_geometry('POINT(45 45)',null),0.005,2,1)
  *             .ST_Centroid_P()
  *             .ST_AsText() as cPoint
  *      from dual;
  *
  *    CPOINT
  *    --------------------------------------------------------------------------------
  *    POINT (45.0 45.0)
  *
  *    -- Points around 0,0, which should return 0.0!
  *    select T_Geometry(sdo_geometry('MULTIPOINT((45 45),(-45 45),(-45 -45),(45 -45))',null),0.005,2,1)
  *             .ST_Centroid_P()
  *             .ST_AsText() as cPoint
  *      from dual;
  *
  *    CPOINT
  *    ---------------
  *    POINT (0.0 0.0)
  *
  *    -- 3D MultiPoint
  *    select T_Geometry(
  *             mdsys.sdo_geometry(3005,null,null,mdsys.sdo_elem_info_array(1,1,3),mdsys.sdo_ordinate_array(1.1,2.0,-0.8, 3.3,4.2,-0.95, 5.5,6.8,1.04)),
  *             0.005,2,1)
  *           .ST_Centroid_P()
  *           .ST_Round(2,2,3)
  *           .geom as cPoint
  *      from dual;
  *
  *    CPOINT
  *    ----------------------------------------------------------------
  *    SDO_GEOMETRY(3001,NULLSDO_POINT_TYPE(3.3,4.33,-0.237),NULL,NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2006 - Original coding.
  *    Simon Greener - January 2012 - Added p_seed_x support.
  *    Simon Greener - August  2018 - Added to T_GEOMETRY.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Centroid_P
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_Centroid_A
  *  NAME
  *    ST_Centroid_A -- Creates a centroid for a polygon mdsys.sdo_geometry object.
  *  SYNOPSIS
  *    Member Function ST_Centroid_A(
  *                       P_method     In Integer Default 1,
  *                       P_Seed_Value In Number  Default Null,
  *                       p_loops      in integer Default 10)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    This function creates a single centroid if a single polygon.
  *    The position of the centroid is computed in the longest segment defined by a constant X or Y ordinate.
  *    There are a number of options for computing a centroid controlled by p_method; these are described
  *    in the ARGUMENTS section of this document.
  *  ARGUMENTS
  *    p_method     (integer) --  0 = Use average of all Area's X Ordinates for starting centroid Calculation
  *                              10 = Use average of all Area's Y Ordinates for starting centroid Calculation
  *                               1 = Use centre X Ordinate of geometry MBR
  *                              11 = Use centre Y Ordinate of geometry MBR
  *                               2 = User supplied starting seed X ordinate value
  *                              12 = User supplied starting seed Y ordinate value
  *                               3 = Use MDSYS.SDO_GEOM.SDO_CENTROID function
  *                               4 = Use MDSYS.SDO_GEOM.SDO_POINTONSURFACE function.
  *    p_seed_value (number) -- Starting ordinate X/Y for which a Y/X that is inside the polygon is returned.
  *    p_loops     (integer) -- In the rare case that the first pass calculation of a centroid fails (not p_method 3 or 4)
  *                              if p_loops is > 0 then the p_seed_value is adjusted by SELF.tolerance and another attempt it made.
  *                              When the number of loops is exhausted NULL is returned (very rare).
  *  RESULT
  *    point (T_GEOMETRY) - Centroid of input object.
  *  EXAMPLE
  *    -- Process ALL options in one.
  *    With data as (
  *      select T_GEOMETRY(
  *               sdo_geometry(
  *                 'POLYGON((2300 -700, 2800 -300, 2300 700, 2800 1100, 2300 1100,
  *                           1800 1100, 2300 800, 2000 600, 2300 600, 2300 500, 2400 400,
  *                           2300 400, 2300 300, 2300 200, 2500 150, 2100 100, 2500 100,
  *                           2300 -200, 1800 -300, 2300 -500, 2200 -400, 2400 -400, 2300 -700),
  *                          (2300 1000, 2400 900, 2200 900, 2300 1000),
  *                          (2400 -400, 2450 -300, 2550 -400, 2400 -400),
  *                          (2300 1000, 2400 1050, 2400 1000, 2300 1000))',null),
  *               0.005,2,1) as tgeom
  *        from dual
  *    )
  *    select t.IntValue as method_id,
  *           case t.IntValue
  *                when  0 then 'Avg of Area''s X Ordinates as Centroid Seed'
  *                when 10 then 'Avg of Area''s Y Ordinates as Centroid Seed'
  *                when  1 then 'Centre X Ordinate of geom MBR as seed'
  *                when 11 then 'Centre Y Ordinate of geom MBR as seed'
  *                when  2 then 'User X ordinate'
  *                when 12 then 'User Y ordinate'
  *                when  3 then 'MDSYS.SDO_GEOM.SDO_CENTROID'
  *                when  4 then 'MDSYS.SDO_GEOM.SDO_PointOnSurface'
  *            end as Method_Text,
  *           a.tGeom.ST_Centroid_A(
  *             p_method     => t.IntValue,
  *             P_Seed_Value => case t.IntValue when 2 then X eg 2035.4 when 12 then Y eg 284.6 else NULL end,
  *             p_loops      => 5
  *           ).ST_AsText() as centroid
  *      from data a,
  *           table(TOOLS.generate_series(0,12,1)) t
  *     where t.IntValue in (0, 1, 2, 3, 4, 10, 11, 12)
  *     order by 2 asc;
  *
  *     METHOD_ID METHOD_TEXT                                CENTROID
  *    ---------- ------------------------------------------ --------------------------------------------------------------------------------
  *             0 Avg of Area's X Ordinates as Centroid Seed POINT (2322.86 -282.855)
  *            10 Avg of Area's Y Ordinates as Centroid Seed POINT (2396.43 314.29)
  *             1 Centre X Ordinate of geom MBR as seed      POINT (2300.0 -300.0)
  *            11 Centre Y Ordinate of geom MBR as seed      POINT (2425.0 200.0)
  *             3 MDSYS.SDO_GEOM.SDO_CENTROID                POINT (2377.12121212121 234.772727272727)
  *             4 MDSYS.SDO_GEOM.SDO_PointOnSurface          POINT (2300.0 -700.0)
  *             2 User X ordinate                            POINT (2035.4 -323.54)
  *            12 User Y ordinate                            POINT (2403.85 284.6)
  *
  *     8 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2006 - Original coding.
  *    Simon Greener - January 2012 - Added p_seed_x support.
  *    Simon Greener - August  2018 - Added to T_GEOMETRY.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Centroid_A(
                     P_method     In Integer Default 1,
                     P_Seed_Value In Number  Default Null,
                     p_loops      in integer Default 10)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_Multi_Centroid
  *  NAME
  *    ST_Multi_Centroid -- Computes centroid for all parts of supplied multilinestring or multipolygon.
  *  SYNOPSIS
  *      Member Function ST_Multi_Centroid(
  *                        p_method IN integer  := 1,
  *                        p_unit   IN varchar2 := NULL
  *                      )
  *               Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic;
  *  DESCRIPTION
  *    For an underlying MultiPolygon this function creates a single centroid for each polygon in it, returning a MultiPoint geometry object.
  *    For a MultiPolygon this function calls ST_Centroid_A with only the following p_method values:
  *       0 = Use average of all Area's X Ordinates for starting centroid Calculation
  *      10 = Use average of all Area's Y Ordinates for starting centroid Calculation
  *       1 = Use centre X Ordinate of geometry MBR
  *      11 = Use centre Y Ordinate of geometry MBR
  *       3 = Use MDSYS.SDO_GEOM.SDO_CENTROID function
  *       4 = Use MDSYS.SDO_GEOM.SDO_POINTONSURFACE function.
  *    For an underlying MultiLineString this function creates a single centroid for each linestring in it, returning a MultiPoint geometry object.
  *    For a MultiLineString this function calls ST_Centroid_L with the p_option set to 'MULTI'.
  *    Since ST_Centroid_L can take a p_unit value, it is exposed in this function.
  *  RESULT
  *    multipoint (T_GEOMETRY) - Centroids of all parts of the supplied MultiPolygon/MultiLineString object.
  *  EXAMPLE
  *    -- MultiCentroid for MultiPolygon
  *    with data as (
  *    select t_geometry (
  *             SDO_GEOMETRY(2007,NULL,NULL,
  *                          SDO_ELEM_INFO_ARRAY(1,1003,1,11,1003,1),
  *                          SDO_ORDINATE_ARRAY(0,0,100,0,100,100,0,100,0,0,1000,1000,1100,1000,1100,1100,1000,1100,1000,1000.0)),
  *             0.005,2,1)
  *             as tGeom
  *      from dual
  *    )
  *    select a.tGeom
  *            .ST_Multi_Centroid(p_method => 0)
  *            .ST_AsText() as mCentroid
  *      from data a;
  *
  *    MCENTROID
  *    ---------------------------------
  *    MULTIPOINT ((40 50), (1040 1050))
  *
  *    -- MutiCentroid for MultiLineString
  *    with data as (
  *    select t_geometry (
  *             SDO_GEOMETRY(2006,NULL,NULL,
  *                          SDO_ELEM_INFO_ARRAY(1,2,1,11,2,1),
  *                          SDO_ORDINATE_ARRAY(0,0,100,0,100,100,0,100,0,0,1000,1000,1100,1000,1100,1100,1000,1100,1000,1000.0)),
  *             0.005,2,1)
  *             as tGeom
  *      from dual
  *    )
  *    select a.tGeom
  *            .ST_Multi_Centroid()
  *            .ST_AsText() as mCentroid
  *      from data a;
  *
  *    MCENTROID
  *    -----------------------------------
  *    MULTIPOINT ((100 100), (1100 1100))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2006 - Original coding.
  *    Simon Greener - January 2012 - Added p_seed_x support.
  *    Simon Greener - August  2018 - Added to T_GEOMETRY.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Multi_Centroid(
                    p_method IN integer  := 1,
                    p_unit   IN varchar2 := NULL
                  )
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  -- ==================================================
  -- ========= Line/SEGMENT Splitting Methods =========
  -- ==================================================

  /****m* T_GEOMETRY/ST_Split_Segments(p_vertex p_unit p_pairs)
  *  NAME
  *    ST_Split_Segments -- Splits geometry at nearest point on the geometry to supplied vertex.
  *  SYNOPSIS
  *    Member Function ST_Split_Segments(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
  *                                     p_unit   in varchar2    DEFAULT null,
  *                                     p_pairs  in integer DEFAULT 0)
  *                                 Return &&INSTALL_SCHEMA..T_SEGMENTs Deterministic,
  *  DESCRIPTION
  *    Using supplied vertex, the geometry is split at the nearest point on the geometry.
  *    Normally the vertex should lie on the linestring at a specific vertex or between two
  *    vertices but the algorithm used will split a line even if the supplied vertex does not
  *    lie on the line. Where the point does not lie on the linestring the algorithm approximates
  *    the nearest point on the linestring to the supplied point and splits it there.
  *    Where a linestring splits an existing segment between two vertices, two halfs of the segment
  *    are returned. If the split point is at an exact vertex the segment before and after are returned.
  *    If the linestring is split at the start, the previous segment returned is null, and for the end
  *    point the second segment returns is null. Two segments are always returned.
  *    Since the closest point may occur more than once because the supplied vertex is perfectly between
  *    two line-string segments all possible results are returned. The first pair occurs earlier in the
  *    linestring than the later ones.
  *    If p_pairs is set to 0, only the first split segments are returned.
  *    The algorithm is ratio based and will not necessarily be accurate for geodetic data.
  *    The function supports linestrings with circular arcs.
  *  ARGUMENTS
  *    p_vertex (T_VERTEX) - A vertex point used to split the linestring.
  *    p_unit   (VarChar2) - Unit of measure for distance calculations.
  *    p_pairs  (Integer)  - 0 : Return first split point's segments if more than one exists;
  *                          1 : Return all split point segments.
  *  RESULT
  *    segments (T_SEGMENTS) - One or more segment objects.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  DEPRECATED
  *    April 30th. Use ...
  ******/
  Member Function ST_Split_Segments(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
                                   p_unit   in varchar2 DEFAULT null,
                                   p_pairs  in integer  DEFAULT 0)
           Return &&INSTALL_SCHEMA..T_SEGMENTs Deterministic,

  /****m* T_GEOMETRY/ST_Split_Segments(p_point p_unit p_pairs)
  *  NAME
  *    ST_Split_Segments -- Splits geometry at nearest point to supplied mdsys.sdo_geometry 2001 point.
  *  SYNOPSIS
  *    Member Function ST_Split_Segments  (p_point in mdsys.sdo_geometry,
  *                                       p_unit  in varchar2    DEFAULT null,
  *                                       p_pairs in integer DEFAULT 0)
  *             Return &&INSTALL_SCHEMA..T_SEGMENTs Deterministic,
  *  DESCRIPTION
  *    Wrapper member function allowing mdsys.sdo_geometry 2001 point rather than T_Vertex.
  *  SEE ALSO
  *    ST_Split_Segments(p_vertex t_vertex...);
  *  ARGUMENTS
  *    p_point (MDSYS.SDO_GEOMETRY) - A point used to split the linestring.
  *    p_unit  (VarChar2)           - Unit of measure for distance calculations.
  *    p_pairs (Integer)            - 0 : Return first split point's segments if more than one exists;
  *                                   1 : Return all split point segments.
  *  RESULT
  *    segments (T_SEGMENTS) - One or more segment objects.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  DEPRECATED
  *    April 30th. Use ....
  ******/
  Member Function ST_Split_Segments(p_point  in mdsys.sdo_geometry,
                                    p_unit   in varchar2    DEFAULT null,
                                    p_pairs  in integer DEFAULT 0)
           Return &&INSTALL_SCHEMA..T_SEGMENTs Deterministic,

  /****m* T_GEOMETRY/ST_Split(p_vertex p_unit)
  *  NAME
  *    ST_Split -- Splits linestring or multi-linestring object at closest point on linestring to supplied T_Vertex.
  *  SYNOPSIS
  *    Member Function ST_Split (p_vertex in &&INSTALL_SCHEMA..T_Vertex,
  *                              p_unit   in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRIES Deterministic,
  *  DESCRIPTION
  *    Using supplied point, this function splits a linestring or multi-linestring object
  *    at its closest point on linestring. Since the closest point may occur more than once,
  *    multiple linestrings may be returned. Normally the point should lie on the linestring at
  *    a vertex or between two vertices but the algorithm used will split a line even if
  *    the point does not lie on the line. Where the point does not lie on the linestring
  *    the algorithm approximates the nearest point on the linestring to the supplied point
  *    and splits it there: the algorithm is ratio based and will not necessarily be accurate
  *    for geodetic data. The function supports linestrings with circular arcs.
  *  ARGUMENTS
  *    p_point (MDSYS.SDO_GEOMETRY) - A point(2001) mdsys.sdo_geometry object describing the point for splitting the linestring.
  *    p_unit  (VarChar2)           - Unit of measure for distance calculations.
  *  RESULT
  *    geometry (T_GEOMETRIES) - One or more geometry objects.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Split (p_vertex in &&INSTALL_SCHEMA..T_Vertex,
                            p_unit   in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRIES Deterministic,

  /****m* T_GEOMETRY/ST_Split(p_point p_unit)
  *  NAME
  *    ST_Split -- Splits linestring or multi-linestring object at closest point on linestring to supplied point mdsys.sdo_geometry.
  *  SYNOPSIS
  *    Member Function ST_Split (p_point in mdsys.sdo_geometry,
  *                              p_unit  in varchar2 DEFAULT null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRIES Deterministic,
  *  DESCRIPTION
  *    Wrapper member function allowing mdsys.sdo_geometry 2001 point rather than T_Vertex.
  *  SEE ALSO
  *    ST_Split(p_vertex in T_VERTEX...);
  *  ARGUMENTS
  *    p_point (MDSYS.SDO_GEOMETRY) - A point used to split the linestring.
  *    p_unit  (VarChar2)           - Unit of measure for distance calculations.
  *  RESULT
  *    geometry (T_GEOMETRIES) - One or more geometry objects.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2014 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Split (p_point  in mdsys.sdo_geometry,
                            p_unit   in varchar2 DEFAULT null)
           Return &&INSTALL_SCHEMA..T_GEOMETRIES Deterministic,

  /****m* T_GEOMETRY/ST_Split(p_measure p_unit)
  *  NAME
  *    ST_Split -- Splits linestring or multi-linestring object at measure point.
  *  SYNOPSIS
  *    Member Function ST_Split (p_measure in number,
  *                              p_unit    in varchar2  DEFAULT null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Wrapper member function allowing split point to be determined by a measure
  *  SEE ALSO
  *    ST_Split(p_vetex in T_VERTEX...);
  *  ARGUMENTS
  *    p_measure (Number)   - Measure defining split point.
  *    p_unit    (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    geometry (T_GEOMETRIES) - One or more geometry objects.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Apr 2014 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Split (p_measure in number,
                            p_unit    in varchar2  DEFAULT null)
           Return &&INSTALL_SCHEMA..T_GEOMETRIES Deterministic,

  /****m* T_GEOMETRY/ST_Snap
  *  NAME
  *    ST_Snap -- The function snaps a point to a linestring(2002) or multi-linestring (2006).
  *  SYNOPSIS
  *    Member Function ST_Snap (p_point in mdsys.sdo_geometry,
  *                             p_unit  in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRIES Deterministic,
  *  DESCRIPTION
  *    The function snaps a point to a linestring(2002) or multi-linestring (2006).
  *    More than one result point may be returned if p_point was equidistant from two
  *    separate segments/segments of the line-string.
  *  ARGUMENTS
  *    p_point (MDSYS.SDO_GEOMETRY) - A point(2001) mdsys.sdo_geometry object describing the
  *                                   point for splitting the linestring.
  *    p_unit  (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    snapped_points (T_GEOMETRIES) -- One or more points where supplied point has snapped to the linestring.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Snap (p_point in mdsys.sdo_geometry,
                           p_unit  in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRIES Deterministic,

  /****m* T_GEOMETRY/ST_SnapN
  *  NAME
  *    ST_SnapN -- The function snaps a point to a (multi)linestring (2002/2006) and returns the requested point as a single geometry.
  *  SYNOPSIS
  *    Member Function ST_SnapN(p_point in mdsys.sdo_geometry,
  *                             p_id    in integer,
  *                             p_unit  in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
  *  DESCRIPTION
  *    The function snaps a point to a linestring(2002) or multi-linestring (2006).
  *    ST_Snap which is called by this function can return more than one point if p_point was equidistant from two
  *    separate segments/segments of the line-string: this function allows the caller to select a single geometry.
  *  ARGUMENTS
  *    p_point (Sdo_Geometry) -- A point(2001) mdsys.sdo_geometry object describing the
  *                              point for splitting the linestring.
  *    p_id         (integer) -- Point to return. If p_id is null or > number of geometries the last is returned.
  *    p_unit      (VarChar2) -- Unit of measure for distance calculations.
  *  RESULT
  *    Single Snap Point (T_Geometry) -- Nominated snapped point is returned.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SnapN(p_point in mdsys.sdo_geometry,
                           p_id    in integer,
                           p_unit  in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,
 
  /****m* T_GEOMETRY/ST_Add_SEGMENT
  *  NAME
  *    ST_Add_SEGMENT -- Adds a segment to an existing geometry.
  *  SYNOPSIS
  *    Member Function ST_Add_SEGMENT     (p_SEGMENT in &&INSTALL_SCHEMA..T_SEGMENT)
  *             Return &&INSTALL_SCHEMA..T_Geometry deterministic,
  *  DESCRIPTION
  *    Adds a segment to an existing geometry.
  *    If last vertex of existing geometry equals first vertex of segment the point is not repeated.
  *    Supports segments that define a circular arc.
  *  ARGUMENTS
  *    p_SEGMENT (T_SEGMENT) - Valid segment. Supports 2 vertex or 3 vertex circular arc segments.
  *  RESULT
  *    geometry (T_GEOMETRY) - Modified geometry
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Add_SEGMENT(p_SEGMENT in &&INSTALL_SCHEMA..T_SEGMENT)
           Return &&INSTALL_SCHEMA..T_Geometry deterministic,

  /****m* T_GEOMETRY/ST_Reverse_Linestring
  *  NAME
  *    ST_Reverse_Linestring -- Reverses linestring including multi-linestring.
  *  SYNOPSIS
  *    Member Function ST_Reverse_Linestring
  *             Return T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Reverses linestring including multi-linestring. Honours circular arcs and measures.
  *  RESULT
  *    linestring (T_GEOMETRY) -- Reverse of input Linestring.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Reverse_Linestring
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_Reverse_Geometry
  *  NAME
  *    ST_Reverse_Geometry -- Reverses non-point geometries
  *  SYNOPSIS
  *    Member Function ST_Reverse_Linestring
  *             Return T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Reverses geometries.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Reverse of SELF geom.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Aug 2017 - Port from GEOM.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Reverse_Geometry
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_Which_Side
  *  NAME
  *    ST_Which_Side -- Returns the side the supplied point lies on.
  *  SYNOPSIS
  *    Member Function ST_Which_Side(p_point in mdsys.sdo_geometry,
  *                                  p_unit  in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Given a point this function returns the side the point lies on.
  *    Wrapper over ST_Find_Offset
  *  SEE ALSO
  *    ST_Find_Offset(p_point in mdsys.sdo_geometry...);
  *  ARGUMENTS
  *    p_point (MDSYS.SDO_GEOMETRY) - Point geometry for which a measure is needed.
  *    p_unit  (VarChar2)           - Unit of measure for distance calculations.
  *  RESULT
  *    side (VarChar2) - L if negative offset; R is positive offset; O if on line.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Which_Side(p_point  in mdsys.sdo_geometry,
                                p_unit   in varchar2 default null)
           Return varchar2 Deterministic,

  /****m* T_GEOMETRY/ST_Concat_Line
  *  NAME
  *    ST_Concat_Line -- Adds supplied linestring to start/end of underlying linestring depending on geometric relationship.
  *  DESCRIPTION
  *   Joins two linestrings together depending on start/end relationships of the supplied
  *   linestring and the underlying linestring.
  *   Does not support point or polygon geometries.
  *  ARGUMENTS
  *    p_line (SDO_GEOMETRY) - Geometry to be added to underlying mdsys.sdo_geometry.
  *  RESULT
  *    linestring (T_GEOMETRY) - Line that is the result of concatenating the two linestrings.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  ******/
  Member Function ST_Concat_Line(p_line in mdsys.sdo_geometry)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

-- ========================================================================================
-- ===================================== GeoProcessing ====================================
-- ========================================================================================

 /****m* T_GEOMETRY/ST_Intersection
  *  NAME
  *    ST_Intersection -- Returns the spatial intersection of two sdo_geometry objects.
  *  SYNOPSIS
  *    Member Function ST_Intersection(p_geometry in mdsys.sdo_geometry,
  *                                    p_order    in varchar2 Default 'FIRST')
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    This function intersects two linestrings, polygons or a mix of either.
  *    The p_order parameter determines whether SELF.geom is the first argument to sdo_intersection or second.
  *    Intersection could result in a Point, Line, Polygon or GeometryCollection.
  *  ARGUMENTS
  *    p_geometry (sdo_geometry) -- A linestring or polygon.
  *    p_order        (varchar2) -- Should be FIRST or SECOND.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Result of intersecting the geometries.
  *  NOTES
  *    Uses MDSYS.SDO_GEOM.SDO_INTERSECTION if Oracle database version is 12cR1 or above
  *    or if the customer is licensed for the Spatial object before 12c.
  *  ERRORS
  *    Will throw exception if the user is not licensed to call MDSYS.SDO_GEOM.SDO_INTERSECTION.
  *    -20102  MDSYS.SDO_GEOM.SDO_INTERSECTION only supported for Locator users from 12c onwards.';
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Intersection(p_geometry in mdsys.sdo_geometry,
                                  p_order    in varchar2 Default 'FIRST')
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

 /****m* T_GEOMETRY/ST_Difference
  *  NAME
  *    ST_Difference -- Returns the spatial difference between two sdo_geometry objects.
  *  SYNOPSIS
  *    Member Function ST_Difference(p_geometry in mdsys.sdo_geometry,
  *                                  p_order    in varchar2 Default 'FIRST')
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    This function determines the difference between two linestrings, polygons or a mix of either.
  *    The p_order parameter determines whether SELF.geom is the first argument to sdo_difference or second.
  *  ARGUMENTS
  *    p_geometry (sdo_geometry) -- A linestring or polygon.
  *    p_order        (varchar2) -- Should be FIRST or SECOND.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Result of differencing the geometries.
  *  NOTES
  *    Uses MDSYS.SDO_GEOM.SDO_DIFFERENCE if Oracle database version is 12cR1 or above
  *    or if the customer is licensed for the Spatial object before 12c.
  *  ERRORS
  *    Will throw exception if the user is not licensed to call MDSYS.SDO_GEOM.SDO_DIFFERENCE.
  *    -20102  MDSYS.SDO_GEOM.SDO_DIFFERENCE only supported for Locator users from 12c onwards.';
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Difference(p_geometry in mdsys.sdo_geometry,
                                p_order    in varchar2 Default 'FIRST')
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

 /****m* T_GEOMETRY/ST_Buffer
  *  NAME
  *    ST_Buffer -- Creates a buffer around input geometry.
  *  SYNOPSIS
  *    Member Function ST_Buffer(p_distance in number,
  *                              p_unit     in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    This function creates a square buffer around all linestrings in an object.
  *    A negative buffer is not possible.
  *  ARGUMENTS
  *    p_distance (Number)   - Value > 0.0
  *    p_unit     (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    polygon (T_GEOMETRY) - Result of buffering input geometry.
  *  NOTES
  *    Uses MDSYS.SDO_GEOM.SDO_BUFFER if Oracle database version is 12c or above,
  *    or if the customer is licensed for the Spatial object before 12c.
  *  ERRORS
  *    Will throw exception if the user is not licensed to call MDSYS.SDO_GEOM.SDO_BUFFER.
  *    -20102  MDSYS.SDO_GEOM.SDO_BUFFER only supported for Locator users from 12c onwards.';
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Buffer(p_distance in number,
                            p_unit     in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

 /****m* T_GEOMETRY/ST_SquareBuffer
  *  NAME
  *    ST_SquareBuffer -- Creates a square buffer around (multi)linestrings.
  *  SYNOPSIS
  *    Member Function ST_SquareBuffer(p_distance in number,
  *                                    p_curved   in number default 0,
  *                                    p_unit     in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    This function creates a square buffer around all linestrings in an object.
  *    A negative buffer is not possible.
  *  ARGUMENTS
  *    p_distance (Number)   - value > 0.0
  *    p_curved   (Number)   - 0 = no; 1 = yes for angles in linestring (See ST_Parallel)
  *    p_unit     (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    polygon (T_GEOMETRY) - Result of square buffering linestrings
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SquareBuffer   (p_distance in number,
                                     p_curved   in number default 0,
                                     p_unit     in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

 /****m* T_GEOMETRY/ST_OneSidedBuffer
  *  NAME
  *    ST_OneSidedBuffer -- Creates a square buffer to left or right of a linestring.
  *  SYNOPSIS
  *    Member Function ST_OneSidedBuffer(p_distance in number,
  *                                      p_curved   in number default 0,
  *                                      p_unit     in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  DESCRIPTION
  *    This function creates a square buffer to left or right of a linestring.
  *  ARGUMENTS
  *    p_distance (Number)   - if < 0 then left side buffer; if > 0 then right sided buffer.
  *    p_curved   (Number)   - 0 = no; 1 = yes for angles in linestring (See ST_Parallel)
  *    p_unit     (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    polygon (T_GEOMETRY) - Result of one sided buffering of a linestring.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_OneSidedBuffer (p_distance in number,
                                     p_curved   in number default 0,
                                     p_unit     in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

-- ========================================================================================
-- ================================== LRS Related Functions ===============================
-- ========================================================================================

  /****m* T_GEOMETRY/ST_LRS_Dim
  *  NAME
  *    ST_LRS_Dim -- Tests underlying mdsys.sdo_geometry to see if coordinates include a measure ordinate and returns measure ordinate's position.
  *  SYNOPSIS
  *    Member Function ST_Lrs_Dim
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Examines SDO_GTYPE (DLNN etc) measure ordinate position (L) and returns it.
  *  RESULT
  *    BOOLEAN (Integer) -- L from DLNN.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Dim
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_LRS_isMeasured
  *  NAME
  *    ST_LRS_isMeasured -- Tests geometry to see if coordinates include a measure.
  *  SYNOPSIS
  *    Member Function ST_LRS_isMeasured
  *             Return Integer Deterministic,
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GType()          as sdo_gtype,
  *           a.tgeom.ST_GeometryType()   as geomType,
  *           a.tgeom.ST_CoordDimension() as coordDim,
  *           a.tgeom.ST_LRS_isMeasured() as isMeasured
  *      from data a;
  *
  *    SDO_GTYPE GEOMTYPE       COORDDIM isMeasured
  *    --------- -------------- -------- ----------
  *            2 ST_LINESTRING         2          0
  *            2 ST_LINESTRING         3          0
  *            2 ST_LINESTRING         3          1
  *  DESCRIPTION
  *    Examines SDO_GTYPE (DLNN etc) to see if sdo_gtype has measure ordinate eg 3302 not 3002.
  *  RESULT
  *    BOOLEAN (Integer) -- 1 is measure ordinate exists, 0 otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_isMeasured
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Get_Measure
  *  NAME
  *    ST_LRS_Get_Measure -- The function returns the measure of the T_GEOMETRY point object.
  *  SYNOPSIS
  *    Member Function ST_LRS_Get_Measure
  *             Return number deterministic,
  *  DESCRIPTION
  *    Returns the measure value of a measured point.
  *    If point 3301, the value of the Z attribute is returned etc.
  *  RESULT
  *    Measure Value (Number)       - Measure value of point (ie 3301, 4301, 4401). If n001 returns NULL.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - June 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Get_Measure
          Return number deterministic,

  /****m* T_GEOMETRY/ST_LRS_Project_Point
  *  NAME
  *    ST_LRS_Project_Point -- The function uses ST_Snap to snap a point to a linestring(2002) or multi-linestring (2006).
  *  SYNOPSIS
  *    Member Function ST_LRS_Project_Point(P_Point In Mdsys.Sdo_Geometry,
  *                                         p_unit  In varchar2 Default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
  *  DESCRIPTION
  *    This is a wrapper function for ST_Snap. The function uses ST_Snap to snap a point
  *    to a linestring(2002) or multi-linestring (2006).
  *    However, where ST_Snap may return more than one result point if p_point was
  *    equidistant from two separate segments/segments of the line-string, ST_Project_Point
  *    returns the first.
  *  ARGUMENTS
  *    p_point (MDSYS.SDO_GEOMETRY) - A point(2001) mdsys.sdo_geometry object describing the point for splitting the linestring.
  *    p_unit  (VarChar2)           - Unit of measure for distance calculations.
  *  RESULT
  *    snapped_points (T_GEOMETRIES) -- One or more points where supplied point has snapped to the linestring.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Project_Point(P_Point In Mdsys.Sdo_Geometry,
                                       p_unit  In varchar2 Default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_LRS_Find_Measure
  *  NAME
  *    ST_LRS_Find_Measure -- Snaps input point to measured linestring returning measure value(s)
  *  SYNOPSIS
  *    Member Function ST_LRS_Find_Measure(p_geom     in mdsys.sdo_geometry,
  *                                        p_measureN in integer default 1,
  *                                        p_unit     in varchar2    default null)
  *             Return mdsys.sdo_ordinate_array Deterministic,
  *  DESCRIPTION
  *    Given a point near a measured linestring, this function returns the measures
  *    of all lines that have same distance to the linestring.
  *  ARGUMENTS
  *    p_geom     (MDSYS.SDO_GEOMETRY) - Geometry for which a measure is needed.
  *    p_measureN (Integer)            - Particular measure to be returned. 0 = all possible measures, 1 is the first etc.
  *    p_unit     (VarChar2)           - Unit of measure for distance calculations.
  *  RESULT
  *    measure (MDSYS.SDO_ORDINATE_ARRAY) -- All measures where more than one is closest to line.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Find_Measure(p_geom     in mdsys.sdo_geometry,
                                      p_measureN in integer  default 1,
                                      p_unit     in varchar2 default null)
           Return mdsys.sdo_ordinate_array Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Find_MeasureN
  *  NAME
  *    ST_LRS_Find_MeasureN -- Returns nominated measure nearest to supplied point if it exists.
  *  SYNOPSIS
  *    Member Function ST_LRS_Find_MeasureN(p_geom     in mdsys.sdo_geometry,
  *                                         p_measureN in integer default 1,
  *                                         p_unit     in varchar2    default null)
  *             Return mdsys.sdo_ordinate_array Deterministic,
  *  DESCRIPTION
  *    Given a point near a measured linestring, this function returns the nominated
  *    measure nearest to that point if it exists. For example, requesting p_measureN=2
  *    may return NULL if only one measure exists that is closest to the linestring at some point.
  *  ARGUMENTS
  *    p_geom     (MDSYS.SDO_GEOMETRY) - Geometry for which a measure is needed.
  *    p_measureN (Integer)            - Particular measure to be returned. 1..AllPossibleMeasures
  *    p_unit     (VarChar2)           - Unit of measure for distance calculations.
  *  RESULT
  *    measure (Number) - First measure on line closest to point.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Find_MeasureN(p_geom     in mdsys.sdo_geometry,
                                       p_measureN in integer  default 1,
                                       p_unit     in varchar2 default null)
           Return Number Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Find_Offset
  *  NAME
  *    ST_LRS_Find_Offset -- Returns smallest (perpendicular) offset from supplied point to the linestring.
  *  SYNOPSIS
  *    Member Function ST_LRS_Find_Offset(p_geom in mdsys.sdo_geometry,
  *                                       p_unit in varchar2    default null)
  *             Return Number Deterministic,
  *  DESCRIPTION
  *    Given a point this function returns the smallest (perpendicular) offset from
  *    the point to the line-string.
  *  ARGUMENTS
  *    p_point (MDSYS.SDO_GEOMETRY) - Point geometry for which a measure is needed.
  *    p_unit  (VarChar2)           - Unit of measure for distance calculations.
  *  RESULT
  *    offset (Number) - Perpendicular offset distance from point to nearest point on line.
  *                      Value is negative if on left of line; positive if on right.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Find_Offset(p_point in mdsys.sdo_geometry,
                                     p_unit  in varchar2 default null)
           Return Number Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Add_Measure
  *  NAME
  *    ST_LRS_Add_Measure -- Adds measures to 2D (multi)linestring.
  *  SYNOPSIS
  *    Member Function ST_LRS_Add_Measure(p_start_measure IN Number Default NULL,
  *                                       p_end_measure   IN Number Default NULL,
  *                                       p_unit          IN VarChar2 Default NULL)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
  *  DESCRIPTION
  *    Takes a 2D geometry and assigns supplied measures to the start/end vertices
  *    and adds proportioned measure values to all vertices in between.
  *  ARGUMENTS
  *    p_start_measure (Number)   - Measure defining start point for geometry.
  *    p_end_measure   (Number)   - Measure defining end point for geometry.
  *    p_unit          (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Measured geometry
  *  EXAMPLE
  *    select t_geometry(SDO_GEOMETRY(2002,28355,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1),
  *                 SDO_ORDINATE_ARRAY(
  *                    571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                    572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                    574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                    576238.453,324521.56, 576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)),
  *                    0.0005,3,1)
  *             .ST_LRS_ADD_Measure(110.0)
  *             .ST_Round(3,3,1,2)
  *             .geom as mGeom
  *      from dual;
  *
  *    MGEOM
  *    ---------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3302,28355,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1),
  *                 SDO_ORDINATE_ARRAY(
  *                     571303.231,321126.963,110.0,   571551.298,321231.412,377.21,   572765.519,321322.805,1586.05,  572739.407,321845.051,2105.16,
  *                     572752.463,322641.476,2895.92, 573209.428,323398.732,3773.96,  573796.954,323555.406,4377.62,  574436.705,323790.416,5054.23,
  *                     574945.895,324051.539,5622.33, 575128.681,324652.122,6245.56,  575128.681,325161.311,6751.06,  575898.993,325213.536,7517.55,
  *                     576238.453,324521.56,8282.72,  576251.509,321048.626,11730.53, 575259.242,322615.364,13571.62, 574306.144,321296.693,15186.88))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Add_Measure(p_start_measure IN Number Default NULL,
                                     p_end_measure   IN Number Default NULL,
                                     p_unit          IN VarChar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_LRS_Update_Measures
  *  NAME
  *    ST_LRS_Update_Measures -- Updates existing measures.
  *  SYNOPSIS
  *    Member Function ST_LRS_Update_Measures(p_start_measure IN Number,
  *                                           p_end_measure   IN Number,
  *                                           p_unit          IN VarChar2 Default NULL)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
  *  DESCRIPTION
  *    Takes an existing measured linestring and updates all measures based on segment length/total length ratios.
  *  NOTES
  *    Does not currently handle circular arc segments
  *  ARGUMENTS
  *    p_start_measure (Number)   - Measure defining start point for geometry.
  *    p_end_measure   (Number)   - Measure defining end point for geometry.
  *    p_unit          (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Measured geometry
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Aug 2017 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Update_Measures(p_start_measure IN Number,
                                         p_end_measure   IN Number,
                                         p_unit          IN VarChar2 DEFAULT NULL)
           Return &&INSTALL_SCHEMA..T_GEOMETRY DETERMINISTIC,

  /****m* T_GEOMETRY/ST_LRS_Reset_Measure
  *  NAME
  *    ST_LRS_Reset_Measure -- Wipes all existing assigned measures.
  *  SYNOPSIS
  *    Member Function ST_LRS_Reset_Measure
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Sets all measures of a measured linesting to null values leaving sdo_gtype
  *    alone. So, 3302 remains 3302, but all measures are set to NULL eg
  *    Coord 2 of 10.23,5.75,2.65 => 10.23,5.75,NULL
  *  NOTES
  *    This is not the same as ST_To2D which removes measures etc and returns a pure 2D (200x object).
  *  RESULT
  *    linestring (T_GEOMETRY) -- All measures reset
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *     Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Reset_Measure
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Reverse_Measure
  *  NAME
  *    ST_LRS_Reverse_Measure -- Reverses vertices measures: first becomes last, second becomes second last etc.
  *  SYNOPSIS
  *    Member Function ST_LRS_Reverse_Measure
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Reverses vertices measures: first becomes last, second becomes second last etc.
  *    This is not the same as ST_Reverse_Linestring which reverses xy direction of whole linestring.
  *  RESULT
  *    linestring (T_GEOMETRY) - All measures reversed
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *     Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Reverse_Measure
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Scale_Measures
  *  NAME
  *    ST_LRS_Scale_Measures -- Rescales geometry measures and optionally offsets them, stretching the geometry.
  *  SYNOPSIS
  *    Member Function ST_LRS_Scale_Measures
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    This function can redistribute measure values between the supplied
  *    p_start_measure (start vertex) and p_end_measure (end vertex) by adjusting/scaling
  *    the measure values of all in between coordinates. In addition, if p_shift_measure
  *    is not 0 (zero), the supplied value is added to each modified measure value
  *    performing a translation/shift of those values.
  *  ARGUMENTS
  *    p_start_measure (Number) - Measure defining start point for geometry.
  *    p_end_measure   (Number) - Measure defining end point for geometry.
  *    p_shift_measure (Number) - Unit of measure for distance calculations.
  *  RETURN
  *    linestring (T_GEOMETRY) - All measures scales.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *     Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Scale_Measures(p_start_measure IN Number,
                                        p_end_measure   IN Number,
                                        p_shift_measure IN Number DEFAULT 0.0 )
           Return &&INSTALL_SCHEMA..T_geometry Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Concatenate
  *  NAME
  *    ST_LRS_Concatenate -- Rescales geometry measures and optionally offsets them, stretching the geometry.
  *  SYNOPSIS
  *    Member Function ST_LRS_Concatenate(p_lrs_segment IN mdsys.sdo_geometry)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    This function appends the provided lrs segment to the SELF.
  *    Ensures measures are updated.
  *  ARGUMENTS
  *    p_lrs_segment (MDSYS.SDO_GEOMETRY) - LRS Linestring.
  *  RETURN
  *    concatenated linestring (T_GEOMETRY)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *     Simon Greener - Aug 2017 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Concatenate(p_lrs_segment IN mdsys.sdo_geometry,
                                     p_unit        IN VarChar2 DEFAULT NULL)
           Return &&INSTALL_SCHEMA..T_Geometry Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Start_Measure
  *  NAME
  *    ST_LRS_Start_Measure -- Returns M value of first vertex in measured geometry.
  *  SYNOPSIS
  *    Member Function ST_LRS_Start_Measure
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Returns start measure associated with first vertex in a measured line-string.
  *    If the line-string is not measured it returns 0.
  *  RESULT
  *    measure (Number) -- Measure value of first vertex in a measured line-string: 0 if 2D.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Start_Measure
           Return Number deterministic,

  /****m* T_GEOMETRY/ST_LRS_End_Measure
  *  NAME
  *    ST_LRS_End_Measure -- Returns M value of last vertex in measured geometry.
  *  SYNOPSIS
  *    Member Function ST_LRS_End_Measure
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Returns end measure associated with last vertex in a measured line-string.
  *    If the line-string is not measured it returns the length of the linestring.
  *  ARGUMENTS
  *    p_unit (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    measure (Number)  - Measure value of first vertex in a measured line-string: 0 if not measured.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_End_Measure(p_unit in varchar2 default null)
           Return Number deterministic,

  /****m* T_GEOMETRY/ST_LRS_Measure_Range
  *  NAME
  *    ST_LRS_Measure_Range -- Returns Last Vertex M Value - First Vertex M Value.
  *  SYNOPSIS
  *    Member Function ST_LRS_Measure_Range(p_unit in varchar2 default null)
  *             Return Number deterministic,
  *  DESCRIPTION
  *    Returns end vertex measure value - start vertex measure value.
  *    If line-string not measured, returns length of line.
  *  ARGUMENTS
  *    p_unit (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    measure (Number) -- Measure range for measured line-string: length if not measured.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Measure_Range(p_unit in varchar2 default null)
           Return Number deterministic,

  /****m* T_GEOMETRY/ST_LRS_Is_Measure_Decreasing
  *  NAME
  *    ST_LRS_Is_Measure_Decreasing -- Checks if M values decrease in value over all of the linestring.
  *  SYNOPSIS
  *    Member Function ST_LRS_Is_Measure_Decreasing
  *             Return varchar2 deterministic,
  *  DESCRIPTION
  *    Checks all measures of all vertices in a linestring from start to end.
  *    Computes difference between each pair of measures. If all measure differences
  *    decrease then TRUE is returned, otherwise FALSE. For non-measured line-strings
  *    the value is always FALSE.
  *  RESULT
  *    True/False (VarChar2) - TRUE if measures are decreasing, FALSE otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Is_Measure_Decreasing
           Return varchar2 Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Is_Measure_Increasing
  *  NAME
  *    ST_LRS_Is_Measure_Increasing -- Checks if M values increase in value over all of the linestring.
  *  SYNOPSIS
  *    Member Function ST_LRS_Is_Measure_Increasing
  *             Return varchar2 deterministic,
  *  DESCRIPTION
  *    Checks all measures of all vertices in a linestring from start to end.
  *    Computes difference between each pair of measures. If all measure differences
  *    increase then TRUE is returned, otherwise FALSE. For non-measured line-strings
  *    the value is always TRUE.
  *  RESULT
  *    True/False (VarChar2) -- TRUE if measures are increasing, FALSE otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Is_Measure_Increasing
           Return varchar2 Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Is_Shape_Pt_Measure
  *  NAME
  *    ST_LRS_Is_Shape_Pt_Measure -- Checks if M value is associated with a vertex.
  *  SYNOPSIS
  *    Member Function ST_LRS_Is_Shape_Pt_Measure(p_measure in number)
  *             Return varchar2 deterministic,
  *  DESCRIPTION
  *    Checks all measures of all vertices in a linestring from start to end to see
  *    if a measure on a shape vertex has the same measure value as p_measure.
  *    Uses measure increasing/decreasing to avoid having to test all vertices in linestring.
  *  RESULT
  *    True/False (VarChar2) -- TRUE if measure exists at a shape vertex.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2017 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Is_Shape_Pt_Measure(p_measure IN Number)
           Return Varchar2 Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Measure_To_Percentage
  *  NAME
  *    ST_LRS_Measure_To_Percentage -- Converts supplied M value to percentage of M range.
  *  SYNOPSIS
  *    Member Function ST_LRS_Measure_To_Percentage(p_measure IN Number DEFAULT 0,
  *                                                 p_unit    in varchar2 default null)
  *             Return Number deterministic,
  *  DESCRIPTION
  *    The end measure minus the start measure of a measured line-string defines
  *    the range of the measures (see ST_Measure_Range). The supplied measure is
  *    divided by this range and multiplied by 100 to return the measure as a percentage.
  *    For non measured line-strings all values are computed using lengths.
  *  ARGUMENTS
  *    p_percentage (Number)   - Value between 0 and 100
  *    p_unit       (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    Percentage (Number) - Value between 0 and 100.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Measure_To_Percentage(p_measure in number default 0,
                                               p_unit    in varchar2 default null)
           Return Number deterministic,

  /****m* T_GEOMETRY/ST_LRS_Percentage_To_Measure
  *  NAME
  *    ST_LRS_Percentage_To_Measure -- Converts supplied Percentage value to Measure.
  *  SYNOPSIS
  *    Member Function ST_LRS_Percentage_To_Measure(p_percentage IN Number DEFAULT 0,
  *                                                 p_unit       in varchar2 default null)
  *             Return Number deterministic,
  *  DESCRIPTION
  *    The supplied percentage value (between 0 and 100) is multipled by
  *    the measure range (see ST_Measure_Range) to return a measure value between
  *    the start and end measures. For non measured line-strings all values are
  *    computed using lengths.
  *  ARGUMENTS
  *    p_percentage (Number)   - Value between 0 and 100
  *    p_unit       (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    Measure (Number) - Value between Start Measure and End Measure.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  ******/
  Member Function ST_LRS_Percentage_To_Measure(p_percentage in number default 0,
                                               p_unit       in varchar2 default null)
           Return Number deterministic,

  /****m* T_GEOMETRY/ST_LRS_Locate_Measure
  *  NAME
  *    ST_LRS_Locate_Measure -- Returns point geometry at supplied measure along linestring.
  *  SYNOPSIS
  *    Member Function ST_LRS_Locate_Measure (p_measure in number,
  *                                           p_offset  in number   default 0,
  *                                           p_unit    in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
  *  DESCRIPTION
  *    Given a measure or length, this function returns a mdsys.sdo_geometry point
  *    at that measure or offset the supplied amount.
  *  NOTES
  *    Handles line-strings with reversed measures.
  *  ARGUMENTS
  *    p_measure (Number)   - Measure defining point to be located.
  *    p_offset  (Number)   - Offset value left (negative) or right (positive) in p_units.
  *    p_unit    (VarChar2) - Unit of measure for distance calculations when defining snap point
  *  RESULT
  *    point (T_GEOMETRY) - Point at measure/offset.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Locate_Measure (p_measure in number,
                                         p_offset  in number   default 0,
                                         p_unit    in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_LRS_Locate_Point
  *  NAME
  *    ST_LRS_Locate_Point -- Wrapper over ST_LRS_Locate_Measure
  *  SYNOPSIS
  *    Member Function ST_LRS_Locate_Point (p_measure in number,
  *                                         p_offset  in number default 0)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,
  *  DESCRIPTION
  *    Given a measure or length, this function returns a mdsys.sdo_geometry point
  *    at that measure or offset the supplied amount.
  *  NOTES
  *    Handles line-strings with reversed measures.
  *  ARGUMENTS
  *    p_measure (Number)   - Measure defining point to be located.
  *    p_offset  (Number)   - Offset value left (negative) or right (positive) in p_units.
  *  RESULT
  *    point (T_GEOMETRY) - Point at measure/offset.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2017 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Locate_Point(p_measure in number,
                                      p_offset  in number default 0)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_LRS_Locate_Along
  *  NAME
  *    ST_LRS_Locate_Along -- Wrapper over ST_LRS_Locate_Measure
  *  SYNOPSIS
  *    Member Function ST_LRS_Locate_Along(p_measure in number,
  *                                        p_offset  in number   default 0,
  *                                        p_unit    in varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic
  *  ARGUMENTS
  *    p_measure (Number)   - Measure defining point to be located.
  *    p_offset  (Number)   - Offset value left (negative) or right (positive) in p_units.
  *    p_unit    (VarChar2) - Unit of measure for distance calculations when defining snap point
  *  RESULT
  *    point (T_GEOMETRY) - Point at measure/offset.
  *  SEE ALSO
  *    ST_Locate_Measure(p_measure in number, ...)
  ******/
  Member Function ST_LRS_Locate_Along(p_measure in number,
                                      p_offset  in number   default 0,
                                      p_unit    in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  /****m* T_GEOMETRY/ST_LRS_Locate_Measures
  *  NAME
  *    ST_LRS_Locate_Measures -- Converts supplied measures into single point or linestring.
  *  SYNOPSIS
  *    Member Function ST_LRS_Locate_Measures(p_start_measure in number,
  *                                           p_end_measure   in number,
  *                                           p_offset        in number default 0,
  *                                           p_unit          varchar2 default null)
  *             Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    Given two measures or lengths, this function returns the point defined by
  *    those measure (if equal) or a line-string if not. The geometry may be offset
  *    the supplied amount.
  *  NOTES
  *    Currently does not handle line-strings with reversed measures.
  *  ARGUMENTS
  *    p_start_measure (Number)   - Measure defining start point of located geometry.
  *    p_end_measure   (Number)   - Measure defining end point of located geometry.
  *    p_offset        (Number)   - Offset value left (negative) or right (positive) in p_units.
  *    p_unit          (VarChar2) - Unit of measure for distance calculations when defining snap point
  *  RESULT
  *    point (T_GEOMETRY) - Point at measure/offset.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  ******/
  Member Function ST_LRS_Locate_Measures(p_start_measure in number,
                                         p_end_measure   in number,
                                         p_offset        in number default 0,
                                         p_unit          varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic,

  /****m* T_GEOMETRY/ST_LRS_Locate_Between
  *  NAME
  *    ST_LRS_Locate_Between -- Converts supplied measures into single point or linestring.
  *  DESCRIPTION
  *    Wrapper over ST_LRS_Locate_Between
  *  ARGUMENTS
  *    p_start_measure (Number)   - Measure defining start point of located geometry.
  *    p_end_measure   (Number)   - Measure defining end point of located geometry.
  *    p_offset        (Number)   - Offset value left (negative) or right (positive) in p_units.
  *    p_unit          (VarChar2) - Unit of measure for distance calculations when defining snap point
  *  RESULT
  *    point (T_GEOMETRY) - Point or Line between start/end measure with offset.
  *  SEE ALSO
  *    ST_Locate_Measures(p_start_measure in number, ...)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original Coding.
  ******/
  Member Function ST_LRS_Locate_Between(p_start_measure in number,
                                        p_end_measure   in number,
                                        p_offset        in number default 0,
                                        p_unit          in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

 /****m* T_GEOMETRY/ST_LRS_Valid_Measure
  *  NAME
  *    ST_LRS_Valid_Measure -- Checks if supplied measure falls within the linestring's measure range.
  *  SYNOPSIS
  *    Member Function ST_LRS_Valid_Measure(p_measure in number)
  *             Return varchar2 Deterministic,
  *  DESCRIPTION
  *    Function returns TRUE string if measure falls within the underlying linestring's measure range
  *    or the FALSE string if the supplied measure does not fall within the measure range.
  *  ARGUMENTS
  *    p_measure (number) - Measure value.
  *  RESULT
  *    TRUE/FASE (string) - TRUE if measure within range, FALSE otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Valid_Measure(p_measure in number)
           Return varchar2 deterministic,

 /****m* T_GEOMETRY/ST_LRS_Valid_Point
  *  NAME
  *    ST_LRS_Valid_Point -- Checks if underlying LRS point is valid.
  *  SYNOPSIS
  *    Member Function ST_LRS_Valid_Point(p_diminfo in mdsys.sdo_dim_array)
  *             Return varchar2 Deterministic,
  *  DESCRIPTION
  *    Function returns TRUE string if point is valid and FALSE if point is not valid.
  *    A valid LRS point has measure information. It is checkeds for the geometry type
  *    (point) and the number of dimensions.
  *    The Oracle equivalent for this function requires that "All LRS point data must be
  *    stored in the SDO_ELEM_INFO_ARRAY and SDO_ORDINATE_ARRAY, and cannot be stored in
  *    the SDO_POINT field in the SDO_GEOMETRY definition of the point", however, this
  *    implementation allows for the storage of 3301 Points within the SDO_POINT_TYPE structure.
  *  ARGUMENTS
  *    p_diminfo (mdsys.sdo_dim_array) - DIMINFO structure with a measure sdo_dim_element
  *  TODO
  *    Current implementation does NOT examine the supplied diminfo array.
  *  RESULT
  *    TRUE/FASE (string) - TRUE if LRS POint is Valid, FALSE otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Valid_Point(p_diminfo in mdsys.sdo_dim_array)
           Return varchar2 deterministic,

 /****m* T_GEOMETRY/ST_LRS_Valid_Segment
  *  NAME
  *    ST_LRS_Valid_Segment -- Checks if underlying LRS linestring is valid.
  *  SYNOPSIS
  *    Member Function ST_LRS_Valid_Segment(p_diminfo in mdsys.sdo_dim_array)
  *             Return varchar2 Deterministic,
  *  DESCRIPTION
  *    Function returns TRUE string if underlying linestring is a valid LRS linestring and FALSE otherwise.
  *    The supplied SDO_DIM_ARRAY must have measure information with a SDO_DIMNAME of M (uppercase)
  *    This function only checks that the geometry type is measured eg 3302 and the linestring dims (dL0N)
  *  ARGUMENTS
  *    p_diminfo (mdsys.sdo_dim_array) - DIMINFO structure with a measure sdo_dim_element
  *  TODO
  *    Current implementation does NOT examine the supplied diminfo array.
  *  RESULT
  *    TRUE/FASE (string) - TRUE if LRS linestring is Valid, FALSE otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Valid_Segment(p_diminfo in mdsys.sdo_dim_array)
           Return varchar2 deterministic,

  /****m* T_GEOMETRY/ST_LRS_Valid_Geometry
  *  NAME
  *    ST_LRS_Valid_Geometry -- Checks if underlying LRS linestring is valid.
  *  SYNOPSIS
  *    Member Function ST_LRS_Valid_Geometry(p_diminfo in mdsys.sdo_dim_array)
  *             Return varchar2 Deterministic,
  *  DESCRIPTION
  *    Function returns TRUE string if underlying linestring is a valid LRS linestring and FALSE otherwise.
  *    The supplied SDO_DIM_ARRAY must have measure information with a SDO_DIMNAME of M (uppercase)
  *    This function checks that the geometry type is measured eg 3302 and has the right number of dimensions (dL0N)
  *    The function also checks that sdo_ordinate array has measure values within the range of the supplied diminfo structure.
  *  ARGUMENTS
  *    p_diminfo (mdsys.sdo_dim_array) - DIMINFO structure with a measure sdo_dim_element
  *  TODO
  *    Current implementation does NOT examine the supplied diminfo array.
  *  RESULT
  *    TRUE/FASE (string) - TRUE if LRS linestring is Valid, FALSE otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Valid_Geometry(p_diminfo in mdsys.sdo_dim_array)
           Return varchar2 deterministic,

  /****m* T_GEOMETRY/ST_LRS_Intersection
  *  NAME
  *    ST_LRS_Intersection -- Intersects input geometry against measured linestring.
  *  SYNOPSIS
  *    Member Function ST_LRS_Intersection(P_GEOM In Mdsys.Sdo_Geometry,
  *                                        P_unit in varchar2 default null)
  *             Return t_geometry Deterministic,
  *  DESCRIPTION
  *    Takes as input a linestring, multi-linestring, polygon, MultiPolygon or point.
  *    SELF must be a measured linestring.
  *  ARGUMENTS
  *    p_geom (mdsys.sdo_geometry) - Geometry for which a intersection calculation is needed.
  *    p_unit           (VarChar2) - Oracle Unit of Measure eg unit=M.
  *  RESULT
  *    Geometry (T_GEOMETRY) - Measured Linestring or point
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jul 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Intersection(p_geom In Mdsys.Sdo_Geometry,
                                      P_unit in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY deterministic,

  -- ==========================================
  -- =============== Tools ====================
  -- ==========================================

  /****m* T_GEOMETRY/ST_Sdo_Point_Equal
  *  NAME
  *    ST_Sdo_Point_Equal -- Compares current object (SELF) geometry's GEOM.SDO_POINT with supplied mdsys.sdo_point_type
  *  SYNOPSIS
  *    Member Function ST_Sdo_Point_Equal(p_sdo_point   in mdsys.sdo_point_type,
  *                                       p_z_precision in integer default 2)
  *             Return varchar2 deterministic
  *  DESCRIPTION
  *    This function compares current t_geometry object' SELF.GEOM.SDO_POINT object to supplied p_sdo_point.
  *    Result can be one of the following:
  *       0 if one or other sdo_point structure is null but not both.
  *       1 if two non-null structures and all ordinates are equal;
  *      -1 if sdo_point's X/Y/Z ordinates not equal
  *  ARGUMENTS
  *    p_sdo_point   (SDO_POINT) -- SDO_Point that is to be compared to current object geometry's SELF.GEOM.Sdo_Point element.
  *    p_z_precision   (integer) -- Z Ordinate precision for comparison using ROUND
  *  RESULT
  *    -1,0,1 (Integer) --  0 if one or other sdo_point structures are null but not both.
  *                     --  1 if two non-null structures and all ordinates are equal;
  *                     -- -1 if sdo_point's X/Y/Z ordinates not equal
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Sdo_Point_Equal(p_sdo_point   in mdsys.sdo_point_type,
                                     p_z_precision in integer default 2)
           Return Integer Deterministic,

/****m* T_GEOMETRY/ST_Elem_Info_Equal
  *  NAME
  *    ST_Elem_Info_Equal -- Compares current object (SELF) geometry's GEOM.SDO_ELEM_INFO object with supplied p_elem_info mdsys.sdo_elem_info_array.
  *  SYNOPSIS
  *    Member Function ST_Elem_Info_Equal(p_elem_info in mdsys.sdo_elem_info_array)
  *             Return Integer Deterministic
  *  DESCRIPTION
  *    This function compares current t_geometry object's SELF.GEOM.SDO_ELEM_INFO object to supplied p_sdo_elem_info object.
  *    Result can be one of the following:
  *       0 if one or other sdo_elem_info_array structures are null but not both.
  *       1 if two non-null structures and all offset/etype/interpretation ordinates are equal;
  *      -1 if sdo_elem_info not all offset/etype/interpretation ordinates are equal
  *  ARGUMENTS
  *    p_elem_info (sdo_elem_info_array) -- sdo_elem_info array that is to be compared to current object geometry's SELF.GEOM.sdo_elem_info object.
  *  RESULT
  *    -1,0,1 (Integer) --  0 if one or other sdo_elem_info_array structures are null but not both.
  *                     --  1 if two non-null structures and all offset/etype/interpretation ordinates are equal;
  *                     -- -1 if sdo_elem_info not all offset/etype/interpretation ordinates are equal
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Elem_Info_Equal(p_elem_info in mdsys.sdo_elem_info_array)
           Return Integer Deterministic,

/****m* T_GEOMETRY/ST_Ordinates_Equal
  *  NAME
  *    ST_Ordinates_Equal -- Compares current object (SELF) geometry's GEOM.sdo_ordinates with supplied mdsys.sdo_ordinate_array
  *  SYNOPSIS
  *    Member Function ST_Ordinates_Equal(p_ordinates   in mdsys.sdo_ordinate_array,
  *                                       p_z_precision in integer default 2,
  *                                       p_m_precision in integer default 3)
  *             Return Integer deterministic
  *  DESCRIPTION
  *    This function compares current t_geometry object' SELF.GEOM.SDO_ORDINATES object to supplied p_ordinates.
  *    Result can be one of the following:
  *       0 if one or other sdo_ordinates structures are null but not both.
  *       1 if two non-null structures and all ordinates are equal;
  *      -1 if sdo_ordinates's X/Y/Z/M ordinates not equal
  *  ARGUMENTS
  *    p_ordinates (sdo_ordinate_array) -- p_ordinate that is to be compared to current object geometry's SELF.GEOM.Sdo_Ordinate_Array element.
  *    p_z_precision          (integer) -- Z Ordinate precision for comparison using ROUND
  *    p_m_precision          (integer) -- M Ordinate precision for comparison using ROUND
  *  RESULT
  *    -1,0,1 (Integer) --  0 if one or other sdo_ordinates structure is null but not both.
  *                     --  1 if two non-null structures and all ordinates are equal;
  *                     -- -1 if any of the sdo_ordinates's X/Y/Z/M ordinates not equal.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Ordinates_Equal(p_ordinates   in mdsys.sdo_ordinate_array,
                                     p_z_precision in integer default 2,
                                     p_m_precision in integer default 3)
           Return Integer Deterministic,

  /****m* T_GEOMETRY/ST_Equals
  *  NAME
  *    ST_Equals -- Compares current object (SELF) with supplied T_GEOMETRY.
  *  SYNOPSIS
  *    Member Function ST_Equals(p_geometry    in mdsys.sdo_geometry,
  *                              p_z_precision in integer default 2,
  *                              p_m_precision in integer default 3)
  *             Return varchar2 deterministic
  *  DESCRIPTION
  *    This function compares current t_geometry object's sdo_geometry (SELF.GEOM) to supplied p_geometry object.
  *    Only compares SDO_GEOMETRY objects.
  *    Result can be one of the following:
  *      EQUAL
  *      FAIL:DIMS
  *      FAIL:SDO_ELEM_INFO
  *      FAIL:SDO_ELEM_INFO
  *      FAIL:SDO_GTYPE
  *      FAIL:SDO_POINT
  *      FAIL:SDO_SRID
  *      FALSE:NULL
  *      Result of mdsys.sdo_geom.relate (if licensed)
  *  ARGUMENTS
  *    p_geometry (SDO_GEOMETRY) -- SDO_GEOMETRY that is to be compared to current object geometry (SELF.GEOM).
  *    p_z_precision   (integer) -- Z Ordinate precision for comparison using ROUND
  *    p_m_precision   (integer) -- M Ordinate precision for comparison using ROUND
  *  RESULT
  *    EQUAL/FAIL     (VarChar2) -- EQUAL or FAIL:{Reason}
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2017 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Equals(p_geometry    in mdsys.sdo_Geometry,
                            p_z_precision in integer default 2,
                            p_m_precision in integer default 3)
           Return VarChar2 Deterministic,

  /****m* T_GEOMETRY/OrderBy
  *  NAME
  *    OrderBy -- Implements ordering function that can be used to sort a collection of T_GEOMETRY objects.
  *  SYNOPSIS
  *    Order Member Function OrderBy(p_compare_geom in &&INSTALL_SCHEMA..T_GEOMETRY)
  *          Return Number deterministic
  *  ARGUMENTS
  *    p_compare_geom (T_GEOMETRY) - Order pair
  *  DESCRIPTION
  *    This order by function allows a collection of T_GEOMETRY objects to be sorted.
  *    For example in the ORDER BY clause of a select statement. Comparison uses all ordinates: X, Y, Z and W.
  *  EXAMPLE
  *    With geometries as (
  *      select t_geometry(sdo_geometry(2001,null,
  *                                     sdo_point_type(dbms_random.value(0,level),
  *                                                    dbms_random.value(0,level),
  *                                                    null),
  *                                    null,null),
  *                        0.005,
  *                        3,
  *                        1) as tgeom
  *        from dual
  *      connect by level < 10
  *    )
  *    select a.tgeom.st_astext(2) as sGeom
  *      from geometries a
  *     order by a.tgeom;
  *
  *    SGEOM
  *    ------------------------------------------------------------------------------------------
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(0.39,0.87,NULL),NULL,NULL);TOLERANCE(.05)
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(0.71,0.04,NULL),NULL,NULL);TOLERANCE(.05)
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(1.68,1.03,NULL),NULL,NULL);TOLERANCE(.05)
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(1.72,1.45,NULL),NULL,NULL);TOLERANCE(.05)
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(2.68,1.99,NULL),NULL,NULL);TOLERANCE(.05)
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(3.12,1.14,NULL),NULL,NULL);TOLERANCE(.05)
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(3.38,0.71,NULL),NULL,NULL);TOLERANCE(.05)
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(4.75,4.46,NULL),NULL,NULL);TOLERANCE(.05)
  *    T_GEOMETRY(SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(5.49,6.87,NULL),NULL,NULL);TOLERANCE(.05)
  *
  *     9 rows selected
  *  RESULT
  *    order value (Number) - -1 less than; 0 equal; 1 greater than
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Order Member Function OrderBy(p_compare_geom in &&INSTALL_SCHEMA..T_GEOMETRY)
        Return number Deterministic

);
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'T_GEOMETRY';
BEGIN
   FOR rec IN (select object_name,object_Type, status
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE'
               order by object_type
              )
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
   EXECUTE IMMEDIATE 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
END;
/
SHOW ERRORS

EXIT SUCCESS;


