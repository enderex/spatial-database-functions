SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STMorton] ...';
GO

-- Show Morton Grid Cells with Morton Key under Queensland 
SELECT [$(owner)].[ST_MORTON]( f.gridCell.EnvelopeCenter() ) as MortonKey, f.gridCell.STAsText() as gridCell
  FROM (SELECT [$(owner)].[STMBR2GEOGRAPHY](138+(  a.gcol*0.5),-29.5+(  b.grow*0.602941),
                                       138+(1+a.gcol)*0.5,-29.5+(1+b.grow)*0.602941,
                                       4283,10) as gridCell
         FROM (SELECT 0 + g.IntValue as gcol from [$(owner)].[GENERATE_SERIES](0,33,1) as g) as a
               CROSS APPLY
              (SELECT 0 + g.IntValue as grow from [$(owner)].[GENERATE_SERIES](0,33,1) as g) as b
       ) as f;
GO


