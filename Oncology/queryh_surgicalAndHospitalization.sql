 add jar /home/hadoop/brickhouse-0.6.0.jar;
create temporary function collect  as 'brickhouse.udf.collect.CollectUDAF';
set hive.strict.checks.cartesian.product=false
set hive.mapred.mode=nonstrict
set hive.vectorized.execution.enabled=true;
set hive.vectorized.execution.reduce.enabled =true;



with p0 as ( select distinct  patient_id from patient_tumor_line_of_therapy   where tumor='NSCLC_STAGE3' ),
     p1 as ( select o.patient_id,o.claim_date,o.claim_type_sub_class, count(*) as surgery from patient_tumor_onc_universal_claims o,p0 where o.patient_id =p0.patient_id
                and o.claim_type_category = 'SURGERY'
              group by o.patient_id,o.claim_date,o.claim_type_sub_class ),
     p2 as ( select patient_id,sum(surgery) as surgery from p1 group by patient_id),
     p4 as ( select distinct o.patient_id,o.claim_date,o.claim_type_sub_class from patient_tumor_onc_universal_claims o,p0 where o.patient_id =p0.patient_id
                and o.place_of_service IN('INPATIENT','INPATIENT HOSPITAL','EMERGENCY ROOM - HOSPITAL')),
     p5 as ( select patient_id, count(*) as inpatient from p4 group by patient_id),
     p6 as ( select patient_id, sum(abnormalHospitalization) abnormalHospitalization, max(abnormalHospitalization) as maxAbnormalHospotalizationDays, count(abnormalHospitalization) totalAbnormalHospitalization from (
                    select patient_id,min(claim_date), max(claim_date), datediff(max(claim_date),min(claim_date)) as abnormalHospitalization from (
                           select o.patient_id,o.claim_date, row_number() over(order by o.patient_id,o.claim_date) as i
                             from patient_tumor_onc_universal_claims o 
                            where o.place_of_service IN('INPATIENT','INPATIENT HOSPITAL','EMERGENCY ROOM - HOSPITAL')
                            group by o.patient_id, o.claim_date ) a
                    group by patient_id, date_add(claim_date,-i)
                   having datediff(max(claim_date),min(claim_date))  >=7 ) H
            group by patient_id )
insert overwrite local directory '/home/hadoop/query/result/surgicalAndHospitalization'
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' 
SELECT p0.patient_id , 
       COALESCE(p2.surgery,0) as surgery,
       COALESCE(p5.inpatient,0) as inpatient,
       COALESCE(p6.abnormalHospitalization,0) as abnormalHospitalization,
       COALESCE(p6.maxAbnormalHospotalizationDays,0) as maxAbnormalHospotalizationDays,
       COALESCE(p6.totalAbnormalHospitalization,0) as totalAbnormalHospitalization
FROM P0
left outer join p2 on p0.patient_id = p2.patient_id
left outer join p5 on p0.patient_id = p5.patient_id
left outer join p6 on p0.patient_id = p6.patient_id;


