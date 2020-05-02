
With geometryCollection as (
select geometry::STGeomFromText(
'GEOMETRYCOLLECTION(POLYGON ((-164647.92 -1486881.52, -163875.03 -1486692.41, -164269.84 -1485141.98, -165838.38 -1485528.05, -165633.91 -1486298.35, -164844.56 -1486103.07, -164647.92 -1486881.52)),
                    POLYGON ((-165838.38 -1485528.05, -165633.91 -1486298.35, -164844.56 -1486103.07, -164647.92 -1486881.52, -163875.03 -1486692.41, -164269.84 -1485141.98, -165838.38 -1485528.05)),
                    POLYGON ((-164647.92 -1486881.52, -164844.56 -1486103.07, -165633.91 -1486298.35, -165428.42 -1487072.49, -164647.92 -1486881.52)),
                    POLYGON ((-164171.02 -1485530.06, -163373.06 -1485340.89, -163470.61 -1484944.89, -164269.84 -1485141.98, -164171.02 -1485530.06)),
                    POLYGON ((-165428.42 -1487072.49, -164647.92 -1486881.52, -164844.56 -1486103.07, -165633.91 -1486298.35, -165428.42 -1487072.49)),
                    POLYGON ((-164647.92 -1486881.52, -163875.03 -1486692.41, -164171.02 -1485530.06, -164171.02 -1485530.06, -164269.84 -1485141.98, -165838.38 -1485528.05, -165633.91 -1486298.35, -164844.56 -1486103.07, -164647.92 -1486881.52)),
                    POINT(0 0),
                    POINT(0 0),
                    POINT(1 1),
                    LINESTRING(0 0,1 1),
                    LINESTRING(0 0,1 1),
                    LINESTRING(0 1,1 1)
                    )',0) as geom
)
SELECT gType.IntValue as geom_type,
       b.geom.STAsText() as sGeom, 
       r.geom.STAsText() as rGeom
  FROM geometryCollection as b
       cross apply
       [$(owner)].[generate_series](0,3,1) as gType
       cross apply
       [$(owner)].[STCollectionDeduplicate] (b.geom,gType.IntValue,0.99999) as r
 ORDER BY geom_type;
GO

 