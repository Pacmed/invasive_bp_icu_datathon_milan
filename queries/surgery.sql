WITH co AS (
  SELECT
    icu.subject_id,
    icu.hadm_id,
    icu.icustay_id,
    pat.dob,
    DATETIME_DIFF(icu.outtime, icu.intime, DAY) AS icu_length_of_stay,
    DATE_DIFF(DATE(icu.intime), DATE(pat.dob), YEAR) AS age,
    RANK() OVER (PARTITION BY icu.subject_id ORDER BY icu.intime) AS icustay_id_order
  FROM `physionet-data.mimiciii_clinical.icustays` AS icu
  INNER JOIN `physionet-data.mimiciii_clinical.patients` AS pat
    ON icu.subject_id = pat.subject_id
  ORDER BY hadm_id DESC),
serv AS (
  SELECT
    icu.hadm_id,
    icu.icustay_id,
    se.curr_service,
    IF(curr_service like '%SURG' OR curr_service = 'ORTHO', 1, 0) AS surgical,
    RANK() OVER (PARTITION BY icu.hadm_id ORDER BY se.transfertime DESC) as rank
  FROM `physionet-data.mimiciii_clinical.icustays` AS icu
  INNER JOIN `physionet-data.mimiciii_clinical.services` AS se
   ON icu.hadm_id = se.hadm_id
  AND se.transfertime < DATETIME_ADD(icu.intime, INTERVAL 12 HOUR)
  ORDER BY icustay_id)
SELECT
  co.subject_id,
  co.hadm_id,
  co.icustay_id,
  co.icu_length_of_stay,
  co.age,
  IF(co.icu_length_of_stay < 2, 1, 0) AS short_stay,
  IF(co.icustay_id_order = 1, 0, 1) AS first_stay,
  serv.surgical
FROM co
LEFT JOIN serv USING (icustay_id, hadm_id)
INNER JOIN `milan-datathon.temp7.icustays` as icustays
ON icustays.ids = serv.icustay_id
WHERE
  serv.rank = 1 AND age < 100
ORDER BY icustay_id