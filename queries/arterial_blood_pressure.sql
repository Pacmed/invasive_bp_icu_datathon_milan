SELECT * 

WITH
invasive_bpa AS (SELECT *
  FROM `physionet-data.mimiciii_clinical.chartevents` ce
  WHERE itemid = 220052
  ORDER BY charttime
  ),
non_inv_bpa as (SELECT *
  FROM `physionet-data.mimiciii_clinical.chartevents` ce
  WHERE itemid = 220181
  ORDER BY charttime
),
temp as (SELECT 
  invasive_bpa.icustay_id as id,
  invasive_bpa.value as invasive_value, 
  non_inv_bpa.value as ninv_value, 
  invasive_bpa.charttime as invasive_time,
  non_inv_bpa.charttime as ninv_time,
  ABS(DATETIME_DIFF(invasive_bpa.charttime, non_inv_bpa.charttime, MINUTE)) as time_diff
  from invasive_bpa 
  join non_inv_bpa
  ON invasive_bpa.icustay_id = non_inv_bpa.icustay_id
  WHERE ABS(DATETIME_DIFF(invasive_bpa.charttime, non_inv_bpa.charttime, MINUTE)) <= 0
),
grouped_temp as (SELECT
  temp.id as icustay_id,
  temp.time_diff as time_diff,
  temp.invasive_value as invasive_value, 
  temp.ninv_value as ninv_value,
  temp.invasive_time as invasive_time,
  temp.ninv_time as ninv_time,
  RANK() OVER (PARTITION BY temp.id, temp.invasive_time ORDER BY temp.time_diff ASC) as ranky
  FROM temp
)

SELECT
icustay_id,
time_diff,
invasive_value, 
ninv_value,
invasive_time,
ninv_time
FROM grouped_temp
INNER JOIN `milan-datathon.temp7.icustays` as icustays
ON icustays.ids = grouped_temp.icustay_id
WHERE ranky = 1
ORDER BY icustay_id
