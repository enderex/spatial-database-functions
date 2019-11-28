SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(cogoowner)].[STLine2CogoAsTable] ....';
GO

SELECT *
  FROM [$(cogoowner)].[STLine2CogoAsTable](geometry::STGeomFromText('MULTILINESTRING((0 0,1 1,2 2),(100 100,110 110,130 130))',0), NULL,NULL,NULL) as t
 ORDER BY t.segment_id;
GO
/*
segment_id    element_id    dms    bearing    distance    deltaZ
1    1      45° 0'0.000"    45    1.4142135623731    NULL
2    1      45° 0'0.000"    45    1.4142135623731    NULL
3    2      45° 0'0.000"    45    14.142135623731    NULL
4    2      45° 0'0.000"    45    28.2842712474619    NULL
*/

Print 'Testing [$(cogoowner)].[STLine2Cogo] ....';
GO

SELECT [$(cogoowner)].[STLine2COGO](geometry::STGeomFromText('LINESTRING (382.875 -422.76, 381.038 -415.726, 531.63 -397.328, 530.44 -407.652, 543.796 -406.729, 542.673 -415.759, 603.73 -415.063, 603.693 -403.377, 614.665 -404.601, 612.239 -376.561, 617.793 -375.878)',28356),NULL,NULL,NULL) as t;
GO

select [$(cogoowner)].[STLine2Cogo] (geometry::STGeomFromText(' MULTILINESTRING ( (10 10, 8.163 17.034, 158.755 35.432, 157.565 25.108, 170.921 26.031), (100 100, 98.877 90.97, 159.934 91.666, 159.897 103.352), (200 200, 210.972 198.776, 208.546 226.816, 214.1 227.499))',0),null,null,null) as cogoObj;
GO

Print 'Testing [STCogo2Line] ....';
GO

Declare @v_xml XML;
SET @v_xml = 
'<Cogo><Segments>
<Segment id="1"><DegMinSec>45° 0''0.000"</DegMinSec><Distance>1.41421</Distance><DeltaZ>1</DeltaZ></Segment>
<Segment id="2"><DegMinSec>45° 0''0.000"</DegMinSec><Distance>1.41421</Distance><DeltaZ>2</DeltaZ></Segment>
<Segment id="3"><DegMinSec>45° 0''0.000"</DegMinSec><Distance>14.1421</Distance><DeltaZ>3</DeltaZ></Segment>
<Segment id="4"><DegMinSec>45° 0''0.000"</DegMinSec><Distance>28.2843</Distance><DeltaZ>4</DeltaZ></Segment>
</Segments></Cogo>';
select cogoLine.AsTextZM() as cogoLineWKT
  from (select [$(cogoowner)].[STCogo2Line] (@v_xml, 3, 2) as cogoLine) as f;
GO

Declare @v_cogo xml;
SET @v_cogo = 
'<Cogo><Segments>
<Segment id="1"><DegMinSec> 345°21''48.75"</DegMinSec><Distance>7.26992</Distance><DeltaZ>1</DeltaZ></Segment>
<Segment id="2"><DegMinSec>  83° 2''4.652"</DegMinSec><Distance>151.712</Distance><DeltaZ>2</DeltaZ></Segment>
<Segment id="3"><DegMinSec> 186°34''30.73"</DegMinSec><Distance>10.3924</Distance><DeltaZ>3</DeltaZ></Segment>
<Segment id="4"><DegMinSec>  86° 2''48.18"</DegMinSec><Distance>13.3879</Distance><DeltaZ>4</DeltaZ></Segment>
<Segment id="5"><DegMinSec> 187° 5''20.73"</DegMinSec><Distance>9.09956</Distance><DeltaZ>5</DeltaZ></Segment>
<Segment id="6"><DegMinSec>  89°20''48.85"</DegMinSec><Distance>61.061</Distance><DeltaZ>6</DeltaZ></Segment>
<Segment id="7"><DegMinSec> 359°49''6.930"</DegMinSec><Distance>11.6861</Distance><DeltaZ>7</DeltaZ></Segment>
<Segment id="8"><DegMinSec>  96°21''55.47"</DegMinSec><Distance>11.0401</Distance><DeltaZ>8</DeltaZ></Segment>
<Segment id="9"><DegMinSec> 355° 3''18.45"</DegMinSec><Distance>28.1448</Distance><DeltaZ>9</DeltaZ></Segment>
<Segment id="10"><DegMinSec>  82°59''21.42"</DegMinSec><Distance>5.59584</Distance><DeltaZ>10</DeltaZ></Segment>
</Segments></Cogo>';
select cogoLine, cogoLine.AsTextZM() as cogoLineWKT
  from (select [$(cogoowner)].[STCogo2Line] (@v_cogo, 3, 2) as cogoLine) as f;
GO

SELECT [$(cogoowner)].[STCogo2Line] ( f.cogoXML, 3,2) as linestring
  FROM (SELECT [$(cogoowner)].[STLine2Cogo] (
                 geometry::STGeomFromText('MULTILINESTRING((0 0,1 1,2 2),(100 100,110 110,130 130))',0),
                 CHAR(176),
                 CHAR(39),
                 '"'
               ) as cogoXML 
        ) as f;
GO

Declare @v_cogo xml;
SET @v_cogo = 
'<Cogo srid="28356"><Segments>
<Segment id="1"><MoveTo>10 10 -10</MoveTo><DegMinSec> 345°21''48.75"</DegMinSec><Distance>7.26992</Distance><DeltaZ>1</DeltaZ></Segment>
<Segment id="2"><DegMinSec>  83° 2''4.652"</DegMinSec><Distance>151.712</Distance><DeltaZ>2</DeltaZ></Segment>
<Segment id="3"><DegMinSec> 186°34''30.73"</DegMinSec><Distance>10.3924</Distance><DeltaZ>3</DeltaZ></Segment>
<Segment id="4"><DegMinSec>  86° 2''48.18"</DegMinSec><Distance>13.3879</Distance><DeltaZ>4</DeltaZ></Segment>
<Segment id="5"><DegMinSec> 187° 5''20.73"</DegMinSec><Distance>9.09956</Distance><DeltaZ>5</DeltaZ></Segment>
<Segment id="6"><DegMinSec>  89°20''48.85"</DegMinSec><Distance>61.061</Distance><DeltaZ>6</DeltaZ></Segment>
<Segment id="7"><DegMinSec> 359°49''6.930"</DegMinSec><Distance>11.6861</Distance><DeltaZ>7</DeltaZ></Segment>
<Segment id="8"><MoveTo>100 100 -15</MoveTo><DegMinSec>  96°21''55.47"</DegMinSec><Distance>11.0401</Distance><DeltaZ>8</DeltaZ></Segment>
<Segment id="9"><DegMinSec> 355° 3''18.45"</DegMinSec><Distance>28.1448</Distance><DeltaZ>9</DeltaZ></Segment>
<Segment id="10"><DegMinSec>  82°59''21.42"</DegMinSec><Distance>5.59584</Distance><DeltaZ>10</DeltaZ></Segment>
</Segments></Cogo>';
--select [$(cogoowner)].[STCogo2Line] (@v_cogo, 3, 2) as cogoLine
select cogoLine, cogoLine.AsTextZM() as cogoLineWKT from (select [$(cogoowner)].[STCogo2Line] (@v_cogo, 3, 2) as cogoLine) as f;
GO


