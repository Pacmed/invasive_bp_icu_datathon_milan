SELECT
diag.icd9_code,
diag_types.short_title,
diag_types.long_title
FROM `physionet-data.mimiciii_clinical.icustays` AS icustay
INNER JOIN `physionet-data.mimiciii_clinical.diagnoses_icd` AS diag
ON icustay.hadm_id = diag.hadm_id
INNER JOIN `physionet-data.mimiciii_clinical.d_icd_diagnoses` as diag_types
ON diag.icd9_code = diag_types.icd9_code
INNER JOIN `milan-datathon.temp7.icustays` as icustays
ON icustays.ids = icustay.icustay_id