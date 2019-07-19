--vent on and off time
DROP MATERIALIZED VIEW IF EXISTS ventduration_on_off_time ;
CREATE MATERIALIZED VIEW  ventduration_on_off_time as
with ventsettings_not_null as ( -- remove records consisting of all null values
    select *
    from ventsettings
    where mechvent =1 or oxygentherapy =1 or extubated =1 or unplanned =1
    order by charttime DESC
)
, lead_info as ( -- add the next record for each record
    select icustay_id, charttime, mechvent,oxygentherapy, extubated, unplanned,
    lead(icustay_id) over (order by icustay_id, charttime) as next_id,
    lead(charttime) over (order by icustay_id, charttime) as next_charttime,
    lead(mechvent) over (order by icustay_id, charttime) as next_mechvent,
    lead(oxygentherapy) over (order by icustay_id, charttime) as next_oxygentherapy,
    lead(extubated) over (order by icustay_id, charttime) as next_extubated,
    lead(unplanned) over (order by icustay_id, charttime) as next_unplanned
    from ventsettings_not_null
)
, tmp_off_case as (-- check all off cases on each patient
        SELECT *
        FROM( SELECT icustay_id, charttime, mechvent, oxygentherapy,extubated, unplanned, next_id, next_charttime, next_mechvent,next_oxygentherapy,next_extubated,next_unplanned,
                CASE WHEN (icustay_id=next_id and (mechvent=1 and (extubated=1 or unplanned=1 or oxygentherapy=1)))THEN charttime
                     WHEN (icustay_id=next_id and (mechvent=1 and (next_extubated=1 or next_unplanned=1))) THEN next_charttime
                     WHEN (icustay_id=next_id and (mechvent=1 and next_oxygentherapy=1)) THEN charttime
                     END AS off_time
                FROM lead_info
                ) tmp_off
        WHERE off_time IS NOT NULL
)
, nextstart_ventnum as( -- extract next starting time for each ventduration number from VIEW ventdurations generated from ventsetting.sql
        SELECT icustay_id, ventnum, starttime,
        LEAD(starttime) OVER (PARTITION BY icustay_id ORDER BY ventnum ASC )AS next_starttime,
        endtime, duration_hours
        FROM ventdurations
)
, vd_temp as ( -- define off time for each ventilation number 
        SELECT nv.icustay_id, nv.ventnum, nv.starttime as vent_on_time, 
        nv.next_starttime, tmp_off_case.off_time as tmp_vent_off_time, nv.endtime, tmp_off_case.unplanned, tmp_off_case.next_unplanned
        FROM nextstart_ventnum AS nv
        LEFT JOIN tmp_off_case on nv.icustay_id = tmp_off_case.icustay_id and
        ( nv.starttime <= tmp_off_case.off_time  and COALESCE(tmp_off_case.off_time < nv.next_starttime , TRUE)) 
        where tmp_off_case.off_time IS NOT NULL  -- removes vent_event w/o explicit extubation, oxygentherapy, selfextubation
)
-- drop duplicates
,vd_on_off as ( --  need to recompute the ventnum since we removed the vent_event w/o explicit extubation
        SELECT vd_temp.icustay_id, vd_temp.vent_on_time, vd_temp.ventnum,
        min(vd_temp.tmp_vent_off_time) as vent_off_time, --  Select the fastest time among several tmp_vent_off_times as vent_off_time
        CASE WHEN( max(vd_temp.unplanned)=1 or max(vd_temp.next_unplanned)=1) THEN 1
        ELSE 0 END AS unplanned -- include unplanned column
        FROM vd_temp
        GROUP BY vd_temp.icustay_id, vd_temp.vent_on_time, vd_temp.ventnum
        ORDER BY vd_temp.icustay_id, vd_temp.vent_on_time, vd_temp.ventnum
)
SELECT vd_on_off.icustay_id,
 --row_number() over ( partition by vd_on_off.icustay_id order by vd_on_off.vent_on_time  ASC) as ventnum, --recompute the ventnum
 vd_on_off.vent_on_time, vd_on_off.vent_off_time, vd_on_off.unplanned, ventnum
FROM vd_on_off
;





