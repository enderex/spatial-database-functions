SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

declare @v_linestring geometry = geometry::STGeomFromText('LINESTRING(0 0,10 10,20 20,30 30,40 40,50 50,60 60,70 70,80 80,90 90,100 100)',0),
        @v_point      geometry = geometry::STGeomFromText('POINT(50 50)',0),
        @v_line1      geometry,
        @v_line2      geometry;
exec [$(lrsowner)].[STSplitProcedure]
                    @p_linestring=@v_linestring,
                    @p_point=@v_point,
					@p_line1=@v_line1 OUTPUT,
					@p_line2=@v_line2 OUTPUT,
					@p_round_xy=3,
					@p_round_zm=8;
select @v_line1.STAsText() as line1, @v_line2.STAsText() as line2;
go

with data as (
  select geometry::STGeomFromText('LINESTRING(0 0,10 10,20 20,30 30,40 40,50 50,60 60,70 70,80 80,90 90,100 100)',0) as line,
         geometry::STGeomFromText('POINT(50 50)',0) as point
)
select s.line1.AsTextZM() as line1, 
       s.line2.AsTextZM() as line2
  from data as a
       cross apply 
       [$(lrsowner)].[STSplit](
             a.line,
             a.point,
             3,
             2
       ) as s;
GO


