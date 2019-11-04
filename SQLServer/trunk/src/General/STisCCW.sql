USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '****************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

PRINT 'Dropping [$(owner)].[STOrientationIndexFilter]...'
GO
IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STOrientationIndexFilter]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STOrientationIndexFilter];
  PRINT 'Dropped [$(owner)].[STOrientationIndexFilter] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STIsCCW]') 
       AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STIsCCW];
  PRINT 'Dropped [$(owner)].[STIsCCW] ...';
END;
GO

/* *************************** FUNCTIONS ************************************* */

PRINT 'Creating [$(owner)].[STOrientationIndexFilter]...'
GO

CREATE FUNCTION [$(owner)].[STOrientationIndexFilter] (
 @p_pa geometry,  /* All points */
 @p_pb geometry,
 @p_pc geometry
)
Returns integer
As
/****f* COGO/STOrientationIndexFilter (2008)
 *  NAME
 *    STOrientationIndexFilter -- A filter for computing the orientation index of three coordinates.
 *  SYNOPSIS
 *    Function STOrientationIndexFilter (
 *               @p_pa geometry,  
 *               @p_pb geometry,
 *               @p_pc geometry
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    If the orientation can be computed safely this routine returns the orientation index.
 *    Otherwise, a value i > 1 is returned. In this case the orientation index must be computed using some other more robust method.
 *  INPUTS
 *    @p_pa (geometry) -- Point A  
 *    @p_pb (geometry) -- Point B
 *    @p_pc (geometry) -- Point C
 *  RESULT
 *    orientation index (integer) -- The orientation index if it can be computed safely or index > 1 if the orientation index cannot be computed safely
 *  NOTE
 *    This is a port of the algorithm in JTS.
 *    Uses an approach due to Jonathan Shewchuk, which is in the public domain.
 *  EXAMPLE
 *    with data as (
 *      SELECT geometry::STGeomFromText('POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0), (1 1, 1 9, 9 9, 9 1, 1 1))',0) as polygon
 *    )
 *    select 'Exterior' as Ring, [$(owner)].[STisCCW](d.polygon.STExteriorRing()) as isCCW from data as d
 *    union all
 *    select 'Interior' as Ring, [$(owner)].[STisCCW](d.polygon.STInteriorRingN(1)) as isCCW from data as d;
 *    GO
 *      
 *    Ring     isCCW
 *    Exterior 1
 *    Interior 0
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Martin Davis  - Original Java coding for Java Topology Suite
 *    Simon Greener - October 2019 - Ported to SQL Server TSQL.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  DECLARE 
    @DP_SAFE_EPSILON float = 1e-15,
    @v_errbound      float,
    @v_detsum        float,
    @v_detleft       float,
    @v_detright      float,
    @v_det           float;

  SET @v_detleft  = (@p_pa.STX - @p_pc.STX) * (@p_pb.STY - @p_pc.STY);
  SET @v_detright = (@p_pa.STY - @p_pc.STY) * (@p_pb.STX - @p_pc.STX);
  SET @v_det      =  @v_detleft- @v_detright;

  IF (@v_detleft > 0.0) 
  BEGIN
    IF (@v_detright <= 0.0) 
      Return SIGN(@v_det)
    ELSE 
      SET @v_detsum = @v_detleft + @v_detright;
  END
  ELSE 
  BEGIN
    IF (@v_detleft < 0.0) 
    BEGIN
      IF (@v_detright >= 0.0) 
        Return SIGN(@v_det)
      ELSE 
        SET @v_detsum = -1 * @v_detleft - @v_detright;
    END
    ELSE
    BEGIN
      Return SIGN(@v_det)
    END;
  END;

  SET @v_errbound = @DP_SAFE_EPSILON * @v_detsum;
  IF ((@v_det >= @v_errbound) OR (-1 * @v_det >= @v_errbound)) 
  BEGIN
    return SIGN(@v_det)
  END;

  Return 2;
END;
GO

PRINT 'Creating [$(owner)].[STIsCCW]...'
GO

CREATE FUNCTION [$(owner)].[STisCCW] (
  @p_ring geometry
)
returns bit
As
/****f* INSPECTION/STIsCCW (2008)
 *  NAME
 *    STIsCCW -- Computes whether a LinearRing is oriented counter-clockwise.
 *  SYNOPSIS
 *    Function STIsCCW (
 *               @p_ring geometry
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    The linestring is assumed to have the first and last points equal ie is a LinearRing.
 *    This will handle coordinate lists which contain repeated points.
 *    This algorithm is only guaranteed to work with valid rings. 
 *    If the ring is invalid (e.g. self-crosses or touches), the computed result may not be correct.
 *  INPUTS
 *    @p_ring (geometry) -- LineString whose start/end points are the same (LinearRing)
 *  RESULT
 *    true/false (bit) -- True (1) if the ring is oriented counter-clockwise false (0) otherwise.
 *  NOTE
 *    This is a port of the algorithm in JTS.
 *  EXAMPLE
 *    with data as (
 *      SELECT geometry::STGeomFromText('POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0), (1 1, 1 9, 9 9, 9 1, 1 1))',0) as polygon
 *    )
 *    select 'Exterior' as Ring, [$(owner)].[STisCCW](d.polygon.STExteriorRing()) as isCCW from data as d
 *    union all
 *    select 'Interior' as Ring, [$(owner)].[STisCCW](d.polygon.STInteriorRingN(1)) as isCCW from data as d;
 *    GO
 *      
 *    Ring     isCCW
 *    Exterior 1
 *    Interior 0
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Martin Davis  - Original Java coding for Java Topology Suite
 *    Simon Greener - October 2019 - Ported to SQL Server TSQL.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  Declare
    @v_isCCW   bit,
    @v_index   int,
    @v_i       int,
    @v_nPts    int,
    @v_hiIndex int,
    @v_iPrev   int,
    @v_iNext   int,
    @v_disc    int,
    @v_dx1     float,
    @v_dy1     float,
    @v_dx2     float,
    @v_dy2     float,
    @v_point   geometry,
    @v_prev    geometry, 
    @v_next    geometry,
    @v_hiPt    geometry;

    -- # of points without closing endpoint
    SET @v_nPts = @p_ring.STNumPoints();
    -- sanity check
    if (@v_nPts < 3)
      Return null;
      -- Ring has fewer than 4 points, so orientation cannot be determined

    -- find highest point
    SET @v_hiPt    = @p_ring.STStartPoint();
    SET @v_hiIndex = 1;
    SET @v_i       = 2;
    WHILE ( @v_i <= @v_nPts) BEGIN
      SET @v_point = @p_ring.STPointN(@v_i);
      if (@v_point.STY > @v_hiPt.STY) BEGIN
        SET @v_hiPt    = @v_point;
        SET @v_hiIndex = @v_i;
      END;
      SET @v_i = @v_i + 1;
    END; -- WHILE LOOP

    -- find distinct point before highest point
    SET @v_iPrev = @v_hiIndex;
    WHILE (@v_iPrev >= 1 ) BEGIN
      SET @v_iPrev = @v_iPrev - 1;
      if (@v_iPrev < 0)
        SET @v_iPrev = @v_nPts;
      IF ( NOT @p_ring.STPointN(@v_iPrev).STEquals(@v_hiPt)=1 AND @v_iPrev != @v_hiIndex )
        BREAK;
    END;

    -- find distinct point after highest point
    SET @v_iNext = @v_hiIndex;
    WHILE (@v_iNext >= @v_hiIndex) BEGIN
      SET @v_iNext = (@v_iNext + 1) % @v_nPts;
      IF NOT (@p_ring.STPointN(@v_iNext).STEquals(@v_hiPt)=1 AND @v_iNext != @v_hiIndex)
        BREAK;
    END;

    SET @v_prev = @p_ring.STPointN(@v_iPrev);
    SET @v_next = @p_ring.STPointN(@v_iNext);

    /**
     * This check catches cases where the ring contains an A-B-A configuration
     * of points. This can happen if the ring does not contain 3 distinct points
     * (including the case where the input array has fewer than 4 elements), or
     * it contains coincident line segments.
     */
    if (@v_prev.STEquals(@v_hiPt)=1 OR 
        @v_next.STEquals(@v_hiPt)=1 OR 
        @v_prev.STEquals(@v_next)=1 )
      return 0;

    -- fast filter for orientation index
    -- avoids use of slow extended-precision arithmetic in many cases
    SET @v_index = [$(owner)].[STOrientationIndexFilter](@v_prev, @v_hiPt,@v_next);
    IF (@v_index <= 1) 
      SET @v_disc = @v_index;
    ELSE
    BEGIN
      -- normalize coordinates
      SET @v_dx1 = @v_hiPt.STX + -1 * @v_prev.STX;
      SET @v_dy1 = @v_hiPt.STY + -1 * @v_prev.STY;
      SET @v_dx2 = @v_next.STX + -1 * @v_hiPt.STX;
      SET @v_dy2 = @v_next.STY + -1 * @v_hiPt.STY;
      -- sign of determinant
      SET @v_disc = SIGN(@v_dx1 * @v_dy2 - @v_dy1 * @v_dx2);
    END;

    /**
     * If disc is exactly 0, lines are collinear. There are two possible cases:
     * (1) the lines lie along the x axis in opposite directions (2) the lines
     * lie on top of one another
     * 
     * (1) is handled by checking if next is left of prev ==> CCW (2) will never
     * happen if the ring is valid, so don't check for it (Might want to assert
     * this)
     */
    SET @v_isCCW = 0;
    IF (@v_disc = 0) 
    BEGIN
      -- poly is CCW if prev x is right of next x
      SET @v_isCCW = CASE WHEN (@v_prev.STX > @v_next.STX) THEN 1 ELSE 0 END
    END
    ELSE
    BEGIN
      -- if area is positive, points are ordered CCW
      SET @v_isCCW = CASE WHEN (@v_disc > 0) THEN 1 ELSE 0 END
    END;
    return @v_isCCW;
END
GO

PRINT 'Testing [$(owner)].[STIsCCW]...'
GO

with data as (
  SELECT geometry::STGeomFromText('POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0), (1 1, 1 9, 9 9, 9 1, 1 1))',0) as polygon
)
select 'Exterior' as test, [$(owner)].[STisCCW](d.polygon.STExteriorRing()) as isCCW from data as d
union all
select 'Interior' as test, [$(owner)].[STisCCW](d.polygon.STInteriorRingN(1)) as isCCW from data as d;
GO

SELECT [$(owner)].[STisCCW] ( geometry::STGeomFromText('LINESTRING (63.29 914.361, 73.036 899.855, 80.023 897.179, 79.425 902.707, 91.228 903.305, 79.735 888.304, 98.4 883.584, 115.73 903.305, 102.284 923.026, 99.147 899.271, 110.8 902.707, 90.78 887.02, 96.607 926.911, 95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279,63.29 914.361)',0) ) as isCCW;
go

SELECT [$(owner)].[STisCCW] ([$(owner)].[STReverse](geometry::STGeomFromText('LINESTRING (63.29 914.361, 73.036 899.855, 80.023 897.179, 79.425 902.707, 91.228 903.305, 79.735 888.304, 98.4 883.584, 115.73 903.305, 102.284 923.026, 99.147 899.271, 110.8 902.707, 90.78 887.02, 96.607 926.911, 95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279,63.29 914.361)',0),3,1)) as isCCW;
GO

QUIT;
GO

