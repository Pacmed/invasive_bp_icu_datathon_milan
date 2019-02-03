-- Norepinephrine

SELECT
dose.icustay_id,
dose.starttime,
dose.endtime,
dose.vaso_rate,
dose.vaso_amount        
FROM `physionet-data.mimiciii_derived.norepinephrine_dose` as dose
INNER JOIN `milan-datathon.temp7.icustays` as icustays
ON icustays.ids = dose.icustay_id
ORDER BY icustay_id
