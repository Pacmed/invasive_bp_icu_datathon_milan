SELECT
a.ICUSTAY_ID,
a.CHARTTIME,
a.STORETIME,
a.CGID,
a.VALUE,
a.VALUENUM,
a.VALUEUOM,
a.WARNING,
a.ERROR,
a.RESULTSTATUS,
a.STOPPED,
b.label,
a.itemid
FROM `physionet-data.mimiciii_clinical.chartevents` as a
INNER JOIN `physionet-data.mimiciii_clinical.d_items` as b
ON a.itemid = b.itemid
INNER JOIN `milan-datathon.temp7.icustays` as icustays
ON icustays.ids = a.icustay_id
WHERE b.itemid in (220046, 211, 220047, 220045)
ORDER BY icustay_id

