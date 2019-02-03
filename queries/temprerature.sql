SELECT 
  icu.icustay_id,
      CASE
        WHEN ce.itemid IN (223762, 676, 677) THEN ce.valuenum -- celsius
        WHEN ce.itemid IN (223761, 678, 679) THEN (ce.valuenum - 32) * 5 / 9 --fahrenheit
      END
      AS temperature,
    
  ce.charttime
  FROM `physionet-data.mimiciii_clinical.icustays` as icu
  INNER JOIN `physionet-data.mimiciii_clinical.chartevents` as ce
  ON icu.icustay_id = ce.icustay_id
  WHERE itemid IN
  (
      676 -- Temperature C
    , 677 -- Temperature C (calc)
    , 678 -- Temperature F
    , 679 -- Temperature F (calc)
    , 223761 -- Temperature Fahrenheit
    , 223762 -- Temperature Celsius
  )
  order by icustay_id, charttime
