-- ****************************************************************************************************
-- Drop and Create T_Grid Type

DROP     TYPE IF EXISTS spdba.T_Grid cascade;

CREATE TYPE spdba.T_Grid AS (
 gcol  int4,
 grow  int4,
 geom  geometry
);


