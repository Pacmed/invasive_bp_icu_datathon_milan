SELECT
a.itemid,
b.label,
a.HADM_ID,
c.icustay_id,
a.CHARTTIME,
a.VALUE,
a.VALUENUM,
a.VALUEUOM,
a.FLAG
FROM `physionet-data.mimiciii_clinical.labevents` AS a
INNER JOIN `physionet-data.mimiciii_clinical.d_labitems` AS b
ON a.itemid = b.itemid
INNER JOIN `physionet-data.mimiciii_clinical.icustays` as c
ON c.hadm_id = a.hadm_id
WHERE a.itemid in (51493, 50811, 51300, 51516, 51274, 51237, 50889, 50912, 50802, 50813, 50809, 50818, 50821, 50820)
AND a.hadm_id IS NOT NULL