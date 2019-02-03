WITH
diabete as (SELECT
   icustay.hadm_id,
   IF(SUM(IF (REGEXP_CONTAINS(diag.icd9_code, r'250'), 1, 0)) > 0, 1, 0) as diag_diabete_250,
   IF(SUM(IF (REGEXP_CONTAINS(diag.icd9_code, r'2507'), 1, 0)) > 0, 1, 0) as diag_diabete_2507
 FROM `physionet-data.mimiciii_clinical.icustays` AS icustay
 INNER JOIN `physionet-data.mimiciii_clinical.diagnoses_icd` AS diag
 ON icustay.hadm_id = diag.hadm_id
 GROUP BY hadm_id
),
liver_transplant as (SELECT 
  icustay.hadm_id,
  IF(SUM(IF(proc.icd9_code in (5051, 5059), 1, 0)) > 0, 1, 0) as liver_tranplant_during_admission
  FROM `physionet-data.mimiciii_clinical.icustays` AS icustay
  INNER JOIN `physionet-data.mimiciii_clinical.procedures_icd` as proc
   ON icustay.hadm_id = proc.hadm_id
  INNER JOIN `physionet-data.mimiciii_clinical.d_icd_procedures` as proc_items
   ON proc.icd9_code = proc_items.icd9_code
 GROUP BY hadm_id
),
smoke as (SELECT
   icustay.hadm_id,
   IF(SUM(IF (diag.icd9_code in ('E8694', '3051', 'V1582', '9592', '5082', '64902', '64900', '98984', '64903', '64904', '64901'), 1, 0)) > 0, 1, 0) as smoking
 FROM `physionet-data.mimiciii_clinical.icustays` AS icustay
 INNER JOIN `physionet-data.mimiciii_clinical.diagnoses_icd` AS diag
 ON icustay.hadm_id = diag.hadm_id
 GROUP BY hadm_id
),
CPB as (SELECT -- Cardiopulmonary bypass
    icustay.hadm_id,
    IF(SUM(IF(proc.icd9_code in (3966), 1, 0)) > 0, 1, 0) as CPB_done
    FROM `physionet-data.mimiciii_clinical.icustays` AS icustay
    INNER JOIN `physionet-data.mimiciii_clinical.procedures_icd` as proc
    ON icustay.hadm_id = proc.hadm_id
    INNER JOIN `physionet-data.mimiciii_clinical.d_icd_procedures` as proc_items
   ON proc.icd9_code = proc_items.icd9_code
 GROUP BY hadm_id
)
SELECT
 icustay.subject_id,
 icustay.hadm_id,
 icustay.icustay_id,
 icustay.dbsource,
 icustay.first_careunit,
 icustay.last_careunit,
 icustay.first_wardid,
 icustay.last_wardid,
 icustay.intime,
 icustay.outtime,
 pat.gender,
 pat.dob,
 pat.dod,
 pat.dod_hosp,
 pat.dod_ssn,
 pat.expire_flag,
 icustay.los as length_o_stay_d_precise,
 DATETIME_DIFF(icustay.outtime, icustay.intime, DAY) AS icu_length_of_stay_d,
 DATE_DIFF(DATE(icustay.intime), DATE(pat.dob), YEAR) AS age_y,
 sepsis.infection as sepsis_infection,
 sepsis.explicit_sepsis as sepsis_explicit_sepsis,
 sepsis.organ_dysfunction as sepsis_organ_dysfunction,
 sepsis.mech_vent as sepsis_mech_vent,
 sepsis.angus as sepsis_angus,
 diabete.diag_diabete_250,
 diabete.diag_diabete_2507,
 liver_transplant.liver_tranplant_during_admission,
 smoke.smoking,
  cpb.CPB_done as cpb_duing_admission,
  rrt.rrt as rrt_during_admission,
  surgery.short_stay,
  surgery.first_stay,
  surgery.surgical        
FROM `physionet-data.mimiciii_clinical.icustays` AS icustay
INNER JOIN `physionet-data.mimiciii_clinical.patients` as pat
 ON icustay.subject_id = pat.subject_id
INNER JOIN `physionet-data.mimiciii_derived.angus_sepsis` as sepsis
 ON icustay.hadm_id = sepsis.hadm_id
INNER JOIN diabete
 ON icustay.hadm_id = diabete.hadm_id
INNER JOIN liver_transplant
 ON icustay.hadm_id = liver_transplant.hadm_id
INNER JOIN smoke
 ON icustay.hadm_id = smoke.hadm_id
INNER JOIN CPB
ON icustay.hadm_id= CPB.hadm_id
INNER JOIN `milan-datathon.temp7.icustays` as icustays
ON icustays.ids = icustay.icustay_id
INNER JOIN `milan-datathon.temp7.RRT` as RRT
ON icustay.icustay_id = RRT.icustay_id
INNER JOIN `milan-datathon.temp7.surgery` as surgery
ON surgery.icustay_id = icustay.icustay_id
ORDER BY icustay_id
