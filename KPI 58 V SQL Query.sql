WITH Kpi58shift AS (
    SELECT
        "Id",
        "Kpi Date",
        "Zone",
        "Bin Rfid Number",
        "Bin Out Timings",
        "Facility Name",
        "Auto Updated",
        CASE
            WHEN substring("Bin Out Timings" from 1 for 2) IS NULL
                OR substring("Bin Out Timings" from 1 for 2) = '' THEN ''
            WHEN substring("Bin Out Timings" from 1 for 2) IN ('05', '06', '07') THEN 'A'
            WHEN substring("Bin Out Timings" from 1 for 2) IN ('13', '14') THEN 'B'
            WHEN substring("Bin Out Timings" from 1 for 2) IN ('20', '21', '22') THEN 'C'
            ELSE ''
        END AS "Shift",
        CASE
            WHEN "Zone" IN ('9', '10', '13') THEN 'V'
            WHEN "Zone" IN ('11', '12', '14', '15') THEN 'II'
            ELSE NULL
        END AS "Package"
    FROM
        public."KPI_58"
    WHERE
        "Kpi Date" BETWEEN '2025/09/01' AND '2025/09/30'
),

-- Count of Auto Updated rows for Shift A and Package V
shiftAauto AS (
    SELECT
        "Kpi Date",
        8466 AS "target_a",
        COUNT(*) AS "a_auto"
    FROM
        Kpi58shift
    WHERE
        "Auto Updated" = 'Yes'
        AND "Shift" = 'A'
        AND "Package" = 'V'
    GROUP BY
        "Kpi Date"
),

-- Count of Manual Updated rows for Shift A and Package V
shiftAmanual AS (
    SELECT
        "Kpi Date",
        COUNT(*) AS "a_manual"
    FROM
        Kpi58shift
    WHERE
        "Auto Updated" = 'No'
        AND "Shift" = 'A'
        AND "Package" = 'V'
    GROUP BY
        "Kpi Date"
),

-- Count of Auto Updated rows for Shift B and Package V
shiftBauto AS (
    SELECT
        "Kpi Date",
		1038 as "target_b",
        COUNT(*) AS "b_auto"
    FROM
        Kpi58shift
    WHERE
        "Auto Updated" = 'Yes'
        AND "Shift" = 'B'
        AND "Package" = 'V'
    GROUP BY
        "Kpi Date"
),

-- Count of Manual Updated rows for Shift B and Package V
shiftBmanual AS (
    SELECT
        "Kpi Date",
        COUNT(*) AS "b_manual"
    FROM
        Kpi58shift
    WHERE
        "Auto Updated" = 'No'
        AND "Shift" = 'B'
        AND "Package" = 'V'
    GROUP BY
        "Kpi Date"
),

-- Count of Auto Updated rows for Shift C and Package V
shiftCauto AS (
    SELECT
        "Kpi Date",
		1140 as "target_c",
        COUNT(*) AS "c_auto"
    FROM
        Kpi58shift
    WHERE
        "Auto Updated" = 'Yes'
        AND "Shift" = 'C'
        AND "Package" = 'V'
    GROUP BY
        "Kpi Date")
,
-- Count of Manual Updated rows for Shift B and Package V
shiftCmanual AS (
    SELECT
        "Kpi Date",
        COUNT(*) AS "c_manual"
    FROM
        Kpi58shift
    WHERE
        "Auto Updated" = 'No'
        AND "Shift" = 'C'
        AND "Package" = 'V'
    GROUP BY
        "Kpi Date"
)
,

--CONSOLIDATE 1 - REPLACE NULL TO ZERO
consolidate1 as (Select
    a."Kpi Date" as "Kpi Date",
	coalesce(a."target_a",0) as Target_A,coalesce(a."a_auto",0) as Auto_A,coalesce(am."a_manual",0) as Manual_A,
	coalesce(b."target_b",0) as Target_B,coalesce(b."b_auto",0) as Auto_B,coalesce(bm."b_manual",0) as Manual_B,
	coalesce(c."target_c",0) as Target_C,coalesce(c."c_auto",0) as Auto_C,coalesce(cm."c_manual",0) as Manual_C
From 
    shiftAauto a 
Left join 
    shiftAmanual am on a."Kpi Date"=am."Kpi Date"
left join
     shiftBauto b on a."Kpi Date"=b."Kpi Date"
left join
    shiftBmanual bm on b."Kpi Date"=bm."Kpi Date"
left join 
     shiftCauto c on b."Kpi Date"=c."Kpi Date"
left join 
     shiftCmanual cm on c."Kpi Date"=cm."Kpi Date"),


--CONSOLIDATE 2 - CALCULATE TOTAL 
consolidate2 as (Select "Kpi Date",
      (Target_A+Target_B+Target_C)as overall_target, 
	  (Auto_A+Auto_B+Auto_C) as Overall_auto,
	  (Manual_A+Manual_B+Manual_C) as overall_manual
from consolidate1),


--OVERALL CONSOLIDATE - MAKE STRUCTURED TABLE FOR CALCULATE THE ACHEIVEMENT
Overall_consolidate as (Select 
     c1."Kpi Date" as kd,
	 c1.Target_A as TA,c1.Auto_A as AA,c1.Manual_A as MA,
	 c1.Target_B as TB,c1.Auto_B as AB,c1.Manual_B as MB,
	 c1.Target_C as TC,c1.Auto_C as AC,c1.Manual_C as MC,
	 c2.overall_target as OT,c2.Overall_auto as OA,c2.overall_manual as OM
from
    consolidate1 c1
	join
	consolidate2 c2
	on c1."Kpi Date" = c2."Kpi Date")
	

---CALCULATED THE ACHEIVEMENT AND ITS A FINAL OUTPUT TABLE 

Select 
     kd As "Date",
	 TA as "Target A",AA as "Auto A",MA as "Manual A", ROUND(((AA+ MA)::numeric / TA), 4) AS "Achievement A",
	 TB as "Target B",AB as "Auto B",MB as "Manual B", ROUND(((AB+ MB)::numeric / TB), 4) AS "Achievement B",
	 TC as "Target C",AC as "Auto C",MC as "Manual C", ROUND(((AC+ MC)::numeric / TC), 4) AS "Achievement C",
	 OT as "OverAll Target",OA as "OverAll Auto",OM as "OverAll Manual", ROUND(((OA+ OM)::numeric / OT), 4) AS "Achievement OverAll"
From
   Overall_consolidate 
;	 