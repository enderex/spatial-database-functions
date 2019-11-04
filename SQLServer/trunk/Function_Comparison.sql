use devdb
go

select a.routine_name, b.routine_name  as file_routine_name
  from (select routine_name
          from [INFORMATION_SCHEMA].[ROUTINES]
         where routine_schema in ('lrs')
            and specific_name not like 'sp%'
            and specific_name not like 'fn%'
        ) as a
		right join 
		(select 'STAddMeasure' as routine_name
union all select 'STEndMeasure' as routine_name
union all select 'STFilterLineSegmentByLength' as routine_name
union all select 'STFilterLineSegmentByMeasure' as routine_name
union all select 'STFindArcPointByLength' as routine_name
union all select 'STFindArcPointByMeasure' as routine_name
union all select 'STFindMeasure' as routine_name
union all select 'STFindMeasureByPoint' as routine_name
union all select 'STFindOffset' as routine_name
union all select 'STFindPointByLength' as routine_name
union all select 'STFindPointByMeasure' as routine_name
union all select 'STFindPointByRatio' as routine_name
union all select 'STFindSegmentByLengthRange' as routine_name
union all select 'STFindSegmentByMeasureRange' as routine_name
union all select 'STFindSegmentByZRange' as routine_name
union all select 'STInterpolatePoint' as routine_name
union all select 'STIsMeasureDecreasing' as routine_name
union all select 'STIsMeasureIncreasing' as routine_name
union all select 'STIsMeasured' as routine_name
union all select 'STLineInterpolatePoint' as routine_name
union all select 'STLineLocatePoint' as routine_name
union all select 'STLineSubstring' as routine_name
union all select 'STLocateAlong' as routine_name
union all select 'STLocateBetween' as routine_name
union all select 'STLocateBetweenElevations' as routine_name
union all select 'STMeasureRange' as routine_name
union all select 'STMeasureToPercentage' as routine_name
union all select 'STPercentageToMeasure' as routine_name
union all select 'STPointToCircularArc' as routine_name
union all select 'STProjectPoint' as routine_name
union all select 'STRemoveMeasure' as routine_name
union all select 'STResetMeasure' as routine_name
union all select 'STReverseMeasure' as routine_name
union all select 'STScaleMeasure' as routine_name
union all select 'STSetM' as routine_name
union all select 'STSetMeasure' as routine_name
union all select 'STSplit' as routine_name
union all select 'STSplitCircularStringByLength' as routine_name
union all select 'STSplitCircularStringByMeasure' as routine_name
union all select 'STSplitLineSegmentByLength' as routine_name
union all select 'STSplitLineSegmentByMeasure' as routine_name
union all select 'STSplitProcedure' as routine_name
union all select 'STStartMeasure' as routine_name
union all select 'STUpdateMeasure' as routine_name
union all select 'STValidLrsGeometry' as routine_name
union all select 'STValidLrsPoint' as routine_name
union all select 'STValidMeasure' as routine_name
) as b
on b.routine_name = a.ROUTINE_NAME
order by routine_name
go

