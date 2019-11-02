CREATE OR REPLACE 
FUNCTION GRIDSMOOTH (P_GEOMETRY IN MDSYS.SDO_GEOMETRY,
                     P_DEC_PLACES IN INTEGER DEFAULT 3) 
RETURN mdsys.sdo_geometry deterministic 
AS 
   v_ordinate_array  mdsys.sdo_ordinate_array;
   v_elem_info_array mdsys.sdo_elem_info_array;
   v_ordinates       mdsys.sdo_ordinate_array;
   v_i               pls_integer := 0;
   v_ord_count       pls_integer := 0;
   v_element         pls_integer := 0;
   v_num_elements    pls_integer := 0;
   v_num_rings       pls_integer := 0;
   v_ring            pls_integer := 0;
   v_ring_geom       mdsys.sdo_geometry;
   V_PREV_ORD_COUNT  PLS_INTEGER := 1;
   v_dec_places      integer := NVL(p_dec_places,3);
   
   Function isCompound(p_elem_info in mdsys.sdo_elem_info_array)
      return boolean
    Is
      v_elements  number;
    Begin
      v_elements := ( ( p_elem_info.COUNT / 3 ) - 1 );
      <<element_extraction>>
      for v_i IN 0 .. v_elements LOOP
         if ( ( /* etype */         p_elem_info(v_i * 3 + 2) = 2 AND 
                /* interpretation*/ p_elem_info(v_i * 3 + 3) = 2 ) 
              OR
              ( /* etype */         p_elem_info(v_i * 3 + 2) in (1003,2003) AND 
                /* interpretation*/ p_elem_info(v_i * 3 + 3) IN (2,4) ) ) then 
                return true;
         end If;
      end loop element_extraction;
      return false;
    End Iscompound;
  
Begin
   If ( p_geometry is null ) Then
       raise_application_error(-20001,'p_geometry may not be null',true);
    End If;
   if ( p_geometry.get_gtype() in (1,5,8,9) ) Then
       return p_geometry;
   elsif ( p_geometry.get_gtype() in (4) ) Then
       raise_application_error(-20001,'compound geometries are not supported.',true);
   End If;
   if ( p_geometry.sdo_elem_info is null ) then
       raise_application_error(-20001,'p_geometry has null sdo_elem_info.',true);
   End if;
   if ( isCompound(p_geometry.sdo_elem_info ) ) then
       raise_application_error(-20001,'Compound geometries are not supported.',true);
   End If;

   v_num_elements := mdsys.sdo_util.getNumElem(p_geometry);
   for v_element in 1..v_num_elements loop
      v_num_rings := sdo_util.GetNumRings(mdsys.sdo_util.extract(p_geometry,v_element));
      for v_ring in 1..v_num_rings loop
          v_ring_geom := mdsys.sdo_util.extract(p_geometry,v_element,v_ring);
          -- smooth the ordinates
          select case when a.lid = 1 then mx else my end 
          bulk collect into v_ordinates
            FROM (SELECT LEVEL AS LID FROM DUAL CONNECT BY LEVEL < 3) A,
                 (SELECT RID, ROUND(SLOPE,v_dec_places) AS SLOPE, ROUND(NEXT_SLOPE,v_dec_places) AS NEXT_SLOPE, MX, MY
                   from (select rid,
                                slope,
                                lag(slope,1)  over (order by rid) as prev_Slope,
                                lead(slope,1) over (order by rid) as next_Slope,
                                mx,my
                           from (select rid,
                                        CASE WHEN (mx - lag(mx,1) over (order by rid)) = 0 
                                             THEN 10 
                                             ELSE (mY - lag(my,1) over (order by rid)) / (mx - lag(mx,1) over (order by rid)) 
                                         END as slope,
                                        lag(mx,1) over (order by rid) as lagX,
                                        lag(my,1) over (order by rid) as lagY,
                                        mx, my
                                   from ( select rownum as rid, 
                                                 (V.STARTCOORD.X + V.ENDCOORD.X) / 2 AS MX, 
                                                 (V.STARTCOORD.Y + V.ENDCOORD.Y) / 2 AS MY
                                            from table(Vectorize(v_ring_geom)) v
                                        )
                                ) v
                        ) 
                 ) b
           where b.slope is null
              or b.slope <> b.next_slope
              or b.next_slope is null
           order by rid,lid;
         
           if ( v_ordinates is not null ) then
              v_ordinates.EXTEND(2); 
              v_ordinates(v_ordinates.COUNT-1) := v_ordinates(1);
              v_ordinates(v_ordinates.COUNT  ) := v_ordinates(2);
              v_i := v_i + 1;
              if ( v_i = 1 ) then
                  v_elem_info_array := v_ring_geom.sdo_elem_info;
                  v_ordinate_array  := v_ordinates;
              else
                  v_elem_info_array.EXTEND(3); 
                  v_elem_info_array(v_elem_info_array.COUNT)   := v_ring_geom.sdo_elem_info(1); /* interpretation */
                  IF ( v_ring <> 1 and v_ring_geom.sdo_elem_info(2) in (1003,1005) ) THEN
                      v_elem_info_array(v_elem_info_array.COUNT-1) := 1000 + v_ring_geom.sdo_elem_info(2); /* etype */
                      v_ord_count := v_ordinate_array.COUNT;
                      v_ordinate_array.EXTEND(v_ordinates.COUNT);
                      v_i := 1;
                      FOR i IN REVERSE 1..(v_ordinates.COUNT / 2) LOOP
                         v_ordinate_array(v_ord_count+v_i) := v_ordinates(i*2-1);
                         v_i := v_i + 1;
                         v_ordinate_array(v_ord_count+v_i) := v_ordinates(i*2);
                         v_i := v_i + 1;
                      END LOOP;
                  ELSE 
                      v_elem_info_array(v_elem_info_array.COUNT-1) := v_ring_geom.sdo_elem_info(2); /* etype */
                      v_ord_count := v_ordinate_array.COUNT;
                      v_ordinate_array.EXTEND(v_ordinates.COUNT);
                      FOR i IN v_ordinates.FIRST..v_ordinates.LAST LOOP
                          v_ordinate_array(v_ord_count+i) := v_ordinates(i);
                      END LOOP;
                  end if;
                  v_elem_info_array(v_elem_info_array.COUNT-2) := v_prev_ord_count;                  
              end if;
              v_prev_ord_count := v_ordinates.COUNT + v_prev_ord_count;
           end if;
        end loop;
   end loop;
   RETURN mdsys.sdo_geometry(p_geometry.sdo_gtype,
                             p_geometry.sdo_srid,
                             p_geometry.sdo_point,
                             v_elem_info_array,
                             v_ordinate_array);
END GRIDSMOOTH;
/
SHOW ERRORS
