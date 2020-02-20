 add jar /home/hadoop/brickhouse-0.6.0.jar;
create temporary function collect  as 'brickhouse.udf.collect.CollectUDAF';
set hive.strict.checks.cartesian.product=false
set hive.mapred.mode=nonstrict
set hive.vectorized.execution.enabled=true;
set hive.vectorized.execution.reduce.enabled =true;

with c1 as ( select 0 as state,from_unixtime(unix_timestamp("Fri Jan 1 09:28:20 UTC 2000","EEE MMM dd HH:mm:ss zzz yyyy")) as refdate, date_add(current_timestamp,-4500)  as refdate1 ),
     tp as ( SELECT p.patient_id,
                    p.tumor,
                    p.claim_type,
                    p.claim_type_class,
                    p.claim_date,
                    0 as state
             FROM patient_tumor_onc_universal_claims p
             WHERE p.patient_id IN  (SELECT distinct patient_id FROM patient_tumor_line_of_therapy  WHERE tumor='NSCLC_STAGE3') AND p.claim_type_class IN ('DX_SECONDARY','DX_PRIMARY'))
insert overwrite local directory '/home/hadoop/query/result/diagnosis_hcp'
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT  "NSCLC_STAGE3" as tumor,
 	a.patient_id,
        a.claim_type,
        dx["CLL"] as dx_cll,
        dx["NSCLC"] as dx_nsclc,
        dx["HCL"] as dx_hcl,
        dx["PROSTATE"] as dx_prostate,
        dx["BREAST"] as dx_breast,
        dx["BLADDER"] as dx_bladder,
        dx["PANCREATIC"] as dx_pancreatic,
        dx["MCL"] as dx_mcl,
        dx["OVARIAN"] as dx_ovarian,
         dx_secondary["CLL"] as dx_secondary_cll,
        dx_secondary["NSCLC"] as dx_secondary_nsclc,
        dx_secondary["HCL"] as dx_secondary_hcl,
        dx_secondary["PROSTATE"] as dx_secondary_prostate,
        dx_secondary["BREAST"] as dx_secondary_breast,
        dx_secondary["BLADDER"] as dx_secondary_bladder,
        dx_secondary["PANCREATIC"] as dx_secondary_pancreatic,
        dx_secondary["MCL"] as dx_secondary_mcl,
        dx_secondary["OVARIAN"] as dx_secondary_ovarian,
        case
 	when dx["CLL"] >=  COALESCE(dx["NSCLC"] ,c1.refdate ) and
               dx["CLL"] >=  COALESCE(dx["HCL"] ,c1.refdate ) and
               dx["CLL"] >=  COALESCE(dx["PROSTATE"] ,c1.refdate) and
               dx["CLL"] >=  COALESCE(dx["BREAST"] ,c1.refdate ) and
               dx["CLL"] >=  COALESCE(dx["BLADDER"] ,c1.refdate ) and
               dx["CLL"] >=  COALESCE(dx["PANCREATIC"] ,c1.refdate)  and
               dx["CLL"] >=  COALESCE(dx["MCL"] ,c1.refdate)  and
               dx["CLL"] >=  COALESCE(dx["OVARIAN"] ,c1.refdate)
               then "CLL"
	 when dx["NSCLC"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["NSCLC"] >=  COALESCE(dx["HCL"] ,c1.refdate ) and
               dx["NSCLC"] >=  COALESCE(dx["PROSTATE"] ,c1.refdate) and
               dx["NSCLC"] >=  COALESCE(dx["BREAST"] ,c1.refdate ) and
               dx["NSCLC"] >=  COALESCE(dx["BLADDER"] ,c1.refdate ) and
               dx["NSCLC"] >=  COALESCE(dx["PANCREATIC"] ,c1.refdate)  and
               dx["NSCLC"] >=  COALESCE(dx["MCL"] ,c1.refdate)  and
               dx["NSCLC"] >=  COALESCE(dx["OVARIAN"] ,c1.refdate)
               then "NSCLC"
	 when dx["HCL"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["HCL"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["HCL"] >=  COALESCE(dx["PROSTATE"] ,c1.refdate) and
               dx["HCL"] >=  COALESCE(dx["BREAST"] ,c1.refdate ) and
               dx["HCL"] >=  COALESCE(dx["BLADDER"] ,c1.refdate ) and
               dx["HCL"] >=  COALESCE(dx["PANCREATIC"] ,c1.refdate)  and
               dx["HCL"] >=  COALESCE(dx["MCL"] ,c1.refdate)  and
               dx["HCL"] >=  COALESCE(dx["OVARIAN"] ,c1.refdate)
               then "HCL"
	 when dx["PROSTATE"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["PROSTATE"] >=  COALESCE(dx["HCL"] ,c1.refdate ) and
               dx["PROSTATE"] >=  COALESCE(dx["CLL"] ,c1.refdate) and
               dx["PROSTATE"] >=  COALESCE(dx["BREAST"] ,c1.refdate ) and
               dx["PROSTATE"] >=  COALESCE(dx["BLADDER"] ,c1.refdate ) and
               dx["PROSTATE"] >=  COALESCE(dx["PANCREATIC"] ,c1.refdate)  and
               dx["PROSTATE"] >=  COALESCE(dx["MCL"] ,c1.refdate)  and
               dx["PROSTATE"] >=  COALESCE(dx["OVARIAN"] ,c1.refdate)
               then "PROSTATE"
	 when dx["BREAST"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["BREAST"] >=  COALESCE(dx["HCL"] ,c1.refdate ) and
               dx["BREAST"] >=  COALESCE(dx["PROSTATE"] ,c1.refdate) and
               dx["BREAST"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["BREAST"] >=  COALESCE(dx["BLADDER"] ,c1.refdate ) and
               dx["BREAST"] >=  COALESCE(dx["PANCREATIC"] ,c1.refdate)  and
               dx["BREAST"] >=  COALESCE(dx["MCL"] ,c1.refdate)  and
               dx["BREAST"] >=  COALESCE(dx["OVARIAN"] ,c1.refdate)
               then "BREAST"
 	when dx["BLADDER"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["BLADDER"] >=  COALESCE(dx["HCL"] ,c1.refdate ) and
               dx["BLADDER"] >=  COALESCE(dx["PROSTATE"] ,c1.refdate) and
               dx["BLADDER"] >=  COALESCE(dx["BREAST"] ,c1.refdate ) and
               dx["BLADDER"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["BLADDER"] >=  COALESCE(dx["PANCREATIC"] ,c1.refdate)  and
               dx["BLADDER"] >=  COALESCE(dx["MCL"] ,c1.refdate)  and
               dx["BLADDER"] >=  COALESCE(dx["OVARIAN"] ,c1.refdate)
               then "BLADDER"
	when dx["PANCREATIC"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["PANCREATIC"] >=  COALESCE(dx["HCL"] ,c1.refdate ) and
               dx["PANCREATIC"] >=  COALESCE(dx["CLL"] ,c1.refdate) and
               dx["PANCREATIC"] >=  COALESCE(dx["BREAST"] ,c1.refdate ) and
               dx["PANCREATIC"] >=  COALESCE(dx["BLADDER"] ,c1.refdate ) and
               dx["PANCREATIC"] >=  COALESCE(dx["CLL"] ,c1.refdate)  and
               dx["PANCREATIC"] >=  COALESCE(dx["MCL"] ,c1.refdate)  and
               dx["PANCREATIC"] >=  COALESCE(dx["OVARIAN"] ,c1.refdate)
               then "PANCREATIC"
	 when dx["MCL"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["MCL"] >=  COALESCE(dx["HCL"] ,c1.refdate ) and
               dx["MCL"] >=  COALESCE(dx["PROSTATE"] ,c1.refdate) and
               dx["MCL"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["MCL"] >=  COALESCE(dx["BLADDER"] ,c1.refdate ) and
               dx["MCL"] >=  COALESCE(dx["PANCREATIC"] ,c1.refdate)  and
               dx["MCL"] >=  COALESCE(dx["CLL"] ,c1.refdate)  and
               dx["MCL"] >=  COALESCE(dx["OVARIAN"] ,c1.refdate)
               then "MCL"
 	when dx["OVARIAN"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["OVARIAN"] >=  COALESCE(dx["HCL"] ,c1.refdate ) and
               dx["OVARIAN"] >=  COALESCE(dx["PROSTATE"] ,c1.refdate) and
               dx["OVARIAN"] >=  COALESCE(dx["BREAST"] ,c1.refdate ) and
               dx["OVARIAN"] >=  COALESCE(dx["CLL"] ,c1.refdate ) and
               dx["OVARIAN"] >=  COALESCE(dx["PANCREATIC"] ,c1.refdate)  and
               dx["OVARIAN"] >=  COALESCE(dx["MCL"] ,c1.refdate)  and
               dx["OVARIAN"] >=  COALESCE(dx["CLL"] ,c1.refdate)
               then "OVARIAN"
          else "none"

        end as dx_primary
  FROM (   
	SELECT  patient_id,
        	claim_type,
         	claim_type_class,
         	collect(tumor,from_utc_timestamp(claim_date,'yyyy-MM-dd')) as dx,
                0 as state FROM (
		SELECT  patient_id,
        		tumor,
         		claim_type,
         		claim_type_class,
        		min(claim_date) as claim_date

		FROM tp
		WHERE claim_type_class = 'DX_PRIMARY'
		group by patient_id, tumor,claim_type,claim_type_class
 	) g
	group by patient_id, claim_type,claim_type_class
) a 
left outer join 
(
	SELECT   patient_id,
        	 claim_type,
         	collect(tumor,from_utc_timestamp(claim_date,'yyyy-MM-dd')) as dx_secondary from (
		SELECT  patient_id,
        		tumor,
         		claim_type,
         		claim_type_class,
        		min(claim_date) as claim_date

		FROM tp
		WHERE claim_type_class = 'DX_SECONDARY'
		group by patient_id, tumor,claim_type,claim_type_class
	 ) g
	group by patient_id, claim_type
) b
on a.patient_id=b.patient_id
left join c1
on a.state = c1.state
