DROP MATERIALIZED VIEW IF EXISTS ptsinfo_vent;
CREATE MATERIALIZED VIEW ptsinfo_vent AS
WITH load_ventdurations as (
    SELECT vent.* , icu.subject_id
    FROM icustays as icu, ventduration_on_off_time as vent
    WHERE icu.icustay_id = vent.icustay_id
)
, temp_patient as (
    -- death time, haspital admission time 
    SELECT p.subject_id, adm.hadm_id, p.gender, p.dob as birth_time,
    admittime, dischtime,
    LEAST(COALESCE(p.dod , adm.deathtime) ,COALESCE(adm.deathtime,p.dod)) as death_time  
   FROM patients as p, admissions as adm
   WHERE p.subject_id = adm.subject_id 
)
, temp as (
SELECT 
    a.icustay_id, hadm_id , a.subject_id, gender, birth_time,
    (ROUND((cast(vent_on_time as date) - cast(birth_time as date)) / 365.242,2)) AS extu_age,
    admittime, dischtime, death_time, 
    CASE WHEN death_time <= vent_off_time then 1 else 0 end as death,
    ventnum, vent_on_time, vent_off_time, unplanned
   FROM temp_patient
INNER JOIN load_ventdurations as a
ON temp_patient.subject_id = a.subject_id
and admittime < vent_off_time and  vent_on_time < dischtime
)
, trache_temp as(
select icustay_id, chartevents.itemid, label, charttime, value 
    from chartevents 
    LEFT JOIN d_items on chartevents.itemid = d_items.itemid  
    where chartevents.itemid in  ( 
        -- related to trachostomy 
        940,970, 977, 1022, 1091, 1120,4603,4441,687, 688,689, 690,691,692,1832,1855,1948,6084, 
        5646,2877,2993,6151,8287,6375, 7118,7286,7474,7528,8479,6898
    ) 
)
, trache_event_list as (
select * from trache_temp
    EXCEPT SELECT * FROM trache_temp where    
    (itemid = 687 and (value = 'refused' or value = 'Not Done')) or 
    (itemid = 940 and (value = 'no' or value =  'notdone')) or 
    (itemid = 970 and (value = 'NOTDONE' or value = 'notdone')) or
    (itemid = 8479 and (value = 'No' or value = 'Not Applicable')) 
    order by icustay_id, itemid, charttime
)
, tracheo as (
    SELECT icustay_id, case when MIN(tra_list.itemid)>0 then 1 else 0 end as trache, MIN(tra_list.charttime) as trache_time
    FROM trache_event_list as tra_list
    GROUP BY icustay_id
)
SELECT temp.icustay_id, hadm_id, temp.subject_id, temp.gender, birth_time, temp.extu_age, admittime,
    ventnum, temp.vent_on_time, temp.vent_off_time,
    extract(epoch from temp.vent_off_time - temp.vent_on_time)/60/60 AS duration_hours,
    temp.unplanned,
    case when temp.vent_on_time < trache_time and trache_time <temp.vent_off_time then 1 else 0 end as tra_used, trache_time,
    dischtime, death_time, death 
from temp
LEFT JOIN tracheo
on temp.icustay_id = tracheo.icustay_id
ORDER BY temp.icustay_id, ventnum, vent_on_time
;

