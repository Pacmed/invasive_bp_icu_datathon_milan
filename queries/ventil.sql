with tmp1 as(
SELECT 
icustay_id, charttime,
max (
 case
      when itemid is null or value is null then 0 -- can't have null values
      when itemid = 720 and value != 'Other/Remarks' THEN 1  -- VentTypeRecorded
      when itemid = 223848 and value != 'Other' THEN 1
      when itemid = 223849 then 1 -- ventilator mode
      when itemid = 467 and value = 'Ventilator' THEN 1 -- O2 delivery device == ventilator
      when itemid in
        (
        445, 448, 449, 450, 1340, 1486, 1600, 224687 -- minute volume
        , 639, 654, 681, 682, 683, 684,224685,224684,224686 -- tidal volume
        , 218,436,535,444,459,224697,224695,224696,224746,224747 -- High/Low/Peak/Mean/Neg insp force ("RespPressure")
        , 221,1,1211,1655,2000,226873,224738,224419,224750,227187 -- Insp pressure
        , 543 -- PlateauPressure
        , 5865,5866,224707,224709,224705,224706 -- APRV pressure
        , 60,437,505,506,686,220339,224700 -- PEEP
        , 3459 -- high pressure relief
        , 501,502,503,224702 -- PCV
        , 223,667,668,669,670,671,672 -- TCPCV
        , 224701 -- PSVlevel
        )
        THEN 1
      else 0
    end
    ) as MechVent,
    max(
      case
        -- initiation of oxygen therapy indicates the ventilation has ended
        when itemid = 226732 and value in
        (
          'Nasal cannula', -- 153714 observations
          'Face tent', -- 24601 observations
          'Aerosol-cool', -- 24560 observations
          'Trach mask ', -- 16435 observations
          'High flow neb', -- 10785 observations
          'Non-rebreather', -- 5182 observations
          'Venti mask ', -- 1947 observations
          'Medium conc mask ', -- 1888 observations
          'T-piece', -- 1135 observations
          'High flow nasal cannula', -- 925 observations
          'Ultrasonic neb', -- 9 observations
          'Vapomist' -- 3 observations
        ) then 1
        when itemid = 467 and value in
        (
          'Cannula', -- 278252 observations
          'Nasal Cannula', -- 248299 observations
          -- 'None', -- 95498 observations
          'Face Tent', -- 35766 observations
          'Aerosol-Cool', -- 33919 observations
          'Trach Mask', -- 32655 observations
          'Hi Flow Neb', -- 14070 observations
          'Non-Rebreather', -- 10856 observations
          'Venti Mask', -- 4279 observations
          'Medium Conc Mask', -- 2114 observations
          'Vapotherm', -- 1655 observations
          'T-Piece', -- 779 observations
          'Hood', -- 670 observations
          'Hut', -- 150 observations
          'TranstrachealCat', -- 78 observations
          'Heated Neb', -- 37 observations
          'Ultrasonic Neb' -- 2 observations
        ) then 1
      else 0
      end
    ) as OxygenTherapy,
    max(
      CASE WHEN itemid IS NULL OR value IS NULL THEN 0
        -- extubated indicates ventilation event has ended
        WHEN itemid = 640 AND value = 'Extubated' THEN 1
        WHEN itemid = 640 AND value = 'Self Extubation' THEN 1
      ELSE 0
      END
      )
      AS Extubated,
      MAX(
      CASE WHEN itemid IS NULL OR value IS NULL THEN 0
        WHEN itemid = 640 AND value = 'Self Extubation' THEN 1
      ELSE 0
      END
      )
      AS SelfExtubated
      FROM `physionet-data.mimiciii_clinical.chartevents` AS ce
      WHERE ce.value IS NOT NULL
      AND itemid IN
      (
    -- the below are settings used to indicate ventilation
      720, 223849 -- vent mode
    , 223848 -- vent type
    , 445, 448, 449, 450, 1340, 1486, 1600, 224687 -- minute volume
    , 639, 654, 681, 682, 683, 684,224685,224684,224686 -- tidal volume
    , 218,436,535,444,224697,224695,224696,224746,224747 -- High/Low/Peak/Mean ("RespPressure")
    , 221,1,1211,1655,2000,226873,224738,224419,224750,227187 -- Insp pressure
    , 543 -- PlateauPressure
    , 5865,5866,224707,224709,224705,224706 -- APRV pressure
    , 60,437,505,506,686,220339,224700 -- PEEP
    , 3459 -- high pressure relief
    , 501,502,503,224702 -- PCV
    , 223,667,668,669,670,671,672 -- TCPCV
    , 224701 -- PSVlevel

    -- the below are settings used to indicate extubation
    , 640 -- extubated

    -- the below indicate oxygen/NIV, i.e. the end of a mechanical vent event
    , 468 -- O2 Delivery Device#2
    , 469 -- O2 Delivery Mode
    , 470 -- O2 Flow (lpm)
    , 471 -- O2 Flow (lpm) #2
    , 227287 -- O2 Flow (additional cannula)
    , 226732 -- O2 Delivery Device(s)
    , 223834 -- O2 Flow

    -- used in both oxygen + vent calculation
    , 467 -- O2 Delivery Device
)
group by icustay_id, charttime
UNION ALL

SELECT 
icustay_id, starttime as charttime
  , 0 as MechVent
  , 0 as OxygenTherapy
  , 1 as Extubated
  , case when itemid = 225468 then 1 else 0 end as SelfExtubated
FROM `physionet-data.mimiciii_clinical.procedureevents_mv` 
WHERE itemid IN
(
  227194 -- "Extubation"
, 225468 -- "Unplanned Extubation (patient-initiated)"
, 225477 -- "Unplanned Extubation (non-patient initiated)"
)
),
  tmp2 AS
  (
  SELECT
  icustay_id,
  CASE
        when MechVent=1 then
          LAG(CHARTTIME, 1) OVER (partition by icustay_id, MechVent order by charttime)
        else null
      end AS charttime_lag
    , charttime
    , MechVent
    , OxygenTherapy
    , Extubated
    , SelfExtubated
  from tmp1
),
vd1 as
(
  select
      icustay_id
      , charttime_lag
      , charttime
      , MechVent
      , OxygenTherapy
      , Extubated
      , SelfExtubated

      -- if this is a mechanical ventilation event, we calculate the time since the last event
      , case
          -- if the current observation indicates mechanical ventilation is present
          -- calculate the time since the last vent event
          when MechVent=1 then
           DATETIME_DIFF(CHARTTIME, charttime_lag, hour)
--           CHARTTIME - charttime_lag
          else null
        end as ventduration

      , LAG(Extubated,1)
      OVER
      (
      partition by icustay_id, case when MechVent=1 or Extubated=1 then 1 else 0 end
      order by charttime
      ) as ExtubatedLag

      -- now we determine if the current mech vent event is a "new", i.e. they've just been intubated
      , case
        -- if there is an extubation flag, we mark any subsequent ventilation as a new ventilation event
          --when Extubated = 1 then 0 -- extubation is *not* a new ventilation event, the *subsequent* row is
          when
            LAG(Extubated,1)
            OVER
            (
            partition by icustay_id, case when MechVent=1 or Extubated=1 then 1 else 0 end
            order by charttime
            )
            = 1 then 1
          -- if patient has initiated oxygen therapy, and is not currently vented, start a newvent
          when MechVent = 0 and OxygenTherapy = 1 then 1
            -- if there is less than 8 hours between vent settings, we do not treat this as a new ventilation event
         when DATETIME_DIFF(CHARTTIME, charttime_lag, hour) >  8
         --when (CHARTTIME - charttime_lag) >  '8 hours'
            then 1
        else 0
        end as newvent
  -- use the staging table with only vent settings from chart events
  FROM tmp2
),
vd2 as
(
  select vd1.*
  -- create a cumulative sum of the instances of new ventilation
  -- this results in a monotonic integer assigned to each instance of ventilation
  , case when MechVent=1 or Extubated = 1 then
      SUM( newvent )
      OVER ( partition by icustay_id order by charttime )
    else null end
    as ventnum
  --- now we convert CHARTTIME of ventilator settings into durations
  from vd1
)
select icustay_id
  -- regenerate ventnum so it's sequential
  --, ROW_NUMBER() over (partition by icustay_id order by ventnum) as ventnum
  , min(charttime) as starttime
  , max(charttime) as endtime
  --, 1 as ventilation_flag
  --, extract(epoch from max(charttime)-min(charttime))/60/60 AS duration_hours
from vd2
INNER JOIN `milan-datathon.temp7.icustays` as icustays
ON icustays.ids = vd2.icustay_id
where vd2.icustay_id IS NOT NULL
group by icustay_id --ventnum
--having min(charttime) != max(charttime)
-- patient had to be mechanically ventilated at least once
-- i.e. max(mechvent) should be 1
-- this excludes a frequent situation of NIV/oxygen before intub
-- in these cases, ventnum=0 and max(mechvent)=0, so they are ignored
--and max(mechvent) = 1
order by icustay_id--, ventnum;
