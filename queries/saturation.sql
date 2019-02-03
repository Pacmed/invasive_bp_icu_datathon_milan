SELECT 
  ce.ICUSTAY_ID,
  ce.ITEMID,
  ce.CHARTTIME,
  ce.STORETIME,
  ce.CGID,
  ce.VALUE,
  ce.VALUENUM,
  ce.VALUEUOM,
  ce.WARNING,
  ce.ERROR,
  ce.RESULTSTATUS,
  ce.STOPPED
FROM `physionet-data.mimiciii_clinical.chartevents` as ce
INNER JOIN `milan-datathon.temp7.icustays` as icustays
ON icustays.ids = ce.icustay_id
WHERE ITEMID in (646, 220277) -- CV and MV
ORDER BY icustay_id
