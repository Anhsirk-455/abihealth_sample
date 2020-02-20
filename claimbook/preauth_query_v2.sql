-- CHANGES MADE FROM PREVIOUS VERSION:
  -- V1 UPDATE
    -- > Left joined all required additional tables with oltp_pre_authorisation to minimize loss of data.
    -- > Removed "grouptype" from medical_history
    
  -- V2 UPDATE
    -- > Joined target data (claims) to the preauth data.
    

WITH
demographics_info AS (SELECT pre.preauth_claim_id, ptb.mrn, person.first_name, person.gender, person.age, person.birth_of_year, 
        person.birth_of_month, person.birth_of_day, person.primary_insured_name,addr.address_line1,addr.pincode
            FROM {hospital}.oltp_pre_authorisation pre
    LEFT JOIN {hospital}.oltp_patient_tb ptb ON ptb.patient_id = pre.patient_id
    LEFT JOIN {hospital}.oltp_person person ON person.person_id = ptb.person_id
    LEFT JOIN {hospital}.oltp_person_address addr ON addr.person_address_id=pre.person_address_id),

insurance_info AS (SELECT policy.insurance_policy_id, mto.name AS tpa_name, policy.provider_id,
        policy.insurance_policy_number, policy.payor_zone, policy.policy_type, 
        policy.insurer_name, policy.tpa_member_id, policy.policy_type_description,
        ins_prsn.patient_identifier AS employed, ins_prsn.corporate_name, ins_prsn.employee_id, ins_prsn.employee_name
            FROM {hospital}.oltp_insurance_policy policy
    LEFT JOIN {hospital}.oltp_insured_person ins_prsn ON policy.insured_person_id=ins_prsn.insured_person_id
    LEFT JOIN mtdm.mtdm_tpa_organization_tb mto ON mto.tpa_organization_id = policy.tpa_organization_id),

medical_history_info AS (SELECT mh.preauth_claim_id, mh.preauth_medical_history_id, mh.chief_complaints, mh.past_history,
        mh.route_of_drug_administration, -- mh.reason_for_hospitalization,
        mhcp.name -- , mhcp.grouptype
            FROM {hospital}.oltp_preauth_medical_history mh
    LEFT JOIN (SELECT string_agg(distinct name, ',') AS name, preauth_medical_history_id
            FROM {hospital}.oltp_medical_historychronicalpersonalfamily 
            GROUP BY preauth_medical_history_id) mhcp
    ON mhcp.preauth_medical_history_id=mh.preauth_medical_history_id),

examination_findings_info AS (SELECT preauth_claim_id,relevantclinicalfindings FROM {hospital}.oltp_examination_finding),

diagnosis_info AS (SELECT preauth_claim_id, string_agg(distinct diagnosis_description, ',') AS diagnosis_description
            FROM {hospital}.oltp_preauth_diagnosis_info WHERE diagnosis_category = 'Provisional'
        GROUP BY preauth_claim_id),

treatment_tbl AS (SELECT treatment_id, preauth_claim_id,
    CASE WHEN is_icumanagement = True THEN 'ICU' ELSE NULL END AS icu,
    CASE WHEN is_dialysis = True THEN 'DIALYSIS' ELSE NULL END AS dialysis,
    CASE WHEN is_chemotherapy = True THEN 'CHEMOTHERAPY' ELSE NULL END AS chemo,
    CASE WHEN is_radiation = True THEN 'RADIATION' ELSE NULL END as radiation,
    CASE WHEN is_medicalmanagement = True THEN 'MEDICAL_MANAGEMENT' ELSE NULL END AS mm,
    CASE WHEN is_surgicalmanagement = True THEN 'SURGERY' ELSE NULL END AS surgery,
    CASE WHEN is_investigation = True THEN 'INVESTIGATION' ELSE NULL END AS invg,
    CASE WHEN is_non_allopathic = True THEN 'NON_ALLOPATHIC' ELSE NULL END AS non_aptic
    FROM {hospital}.oltp_treatment),

treatment_denorm AS (select treatment_id, preauth_claim_id, CONCAT_WS(', ', icu, dialysis,
    chemo, radiation, mm , surgery, invg, non_aptic) AS treatment
        FROM treatment_tbl),

treatment_into AS (SELECT distinct tdn.preauth_claim_id, tdn.treatment, m_dept.department, -- sm.is_gipsa,
    t_info.oltp_master_treatment_doctor_id as treatment_doctor_id
        FROM treatment_denorm AS tdn
    LEFT JOIN {hospital}.oltp_treatment_info t_info ON tdn.treatment_id=t_info.treatment_id
    LEFT JOIN {hospital}.oltp_master_department m_dept on t_info.deparment_id=m_dept.oltp_master_department_id
    LEFT JOIN {hospital}.oltp_surgical_management sm on t_info.treatment_id=sm.treatment_id),

billing_info AS (SELECT preauth_claim_id, type_of_admission, dateofadmission, dateofdischarge,
    stayindays, expectedcosthospitalization, actualcosthospitalization, patientresponsibility,
    patientdiscount, patientpayable
    FROM {hospital}.oltp_billing_info),
--TARGETS   
claims_target_table as (SELECT cltr.claim_id, cltr.amount, tr.transaction_date, tr.transaction_type_id, tr.transaction_id,
        tr.transaction_number, tr.bank_id  FROM {hospital}.oltp_claim_transaction cltr
    JOIN {hospital}.oltp_transaction tr ON cltr.transaction_id = tr.transaction_id),
    
reduced_cols as (SELECT claim_id, SUM(DISTINCT amount) as total_amount, MAX(transaction_date) transaction_date, 
        transaction_type_id FROM claims_target_table 
    GROUP BY claim_id, transaction_type_id),

tpa_cols as (SELECT claim_id, total_amount as tpa_amount, transaction_date as tpa_transaction_date from reduced_cols 
    WHERE transaction_type_id=1),
    
patient_cols as (SELECT claim_id, total_amount as patient_amount, transaction_date as patient_transaction_date from reduced_cols 
    WHERE transaction_type_id=2),

targets as (SELECT t1.claim_id,t3.preauth_id, t3.claim_amount, t3.closed as claim_closed, t1.tpa_amount as tpa_paid_amount, t1.tpa_transaction_date, t2.patient_amount patient_paid_amount, t2.patient_transaction_date
    FROM tpa_cols t1
    LEFT JOIN patient_cols t2 ON t1.claim_id = t2.claim_id
    JOIN {hospital}.oltp_claims t3 ON t3.claim_id = t1.claim_id)

SELECT 
    pre.preauth_claim_id, pre.created_date_time, pre.isclosed, pre.modified_date_time,
        pre.al_number, pre.is_reopened, pre.is_forwarded_to_claims, pre.final_bill_number, pre.discharge_flag, pre.case_type,
        pre.manual_upload_status, pre.portal_status, pre.forwarded_to_claims_date, pre.rpa_enabled,-- pre.handling_by,
    dem.mrn, dem.first_name, dem.gender, dem.age, dem.birth_of_year, dem.birth_of_month, 
        dem.birth_of_day, dem.primary_insured_name,dem.address_line1,dem.pincode,
    ins.tpa_name, ins.provider_id, ins.insurance_policy_number, ins.payor_zone, ins.policy_type, ins.insurer_name, 
        ins.tpa_member_id, ins.policy_type_description, ins.employed, ins.corporate_name, ins.employee_id, ins.employee_name,
    vt.visit_type,
    ps.requested_amount, ps.status_update_date_time,
    st.name workflow_status,
    wrt.code as request_type,
    mh.chief_complaints, mh.past_history, mh.route_of_drug_administration, 
        mh.name as medical_hist_name, -- mh.reason_for_hospitalization, mh.grouptype, 
    ef.relevantclinicalfindings,
    di.diagnosis_description,
    ti.treatment, ti.department, ti.treatment_doctor_id, -- ti.is_gipsa,
    bi.type_of_admission, bi.dateofadmission, bi.dateofdischarge, bi.stayindays, bi.expectedcosthospitalization,
        bi.actualcosthospitalization,bi.patientresponsibility,bi.patientdiscount,bi.patientpayable,
    y.claim_id, y.tpa_paid_amount, y.tpa_transaction_date, y.patient_paid_amount, y.patient_transaction_date, 
        y.claim_amount, y.claim_closed,
    '{hospital}' as hospital_name

FROM {hospital}.oltp_pre_authorisation pre
    LEFT JOIN demographics_info dem ON dem.preauth_claim_id = pre.preauth_claim_id
    LEFT JOIN insurance_info ins ON ins.insurance_policy_id = pre.insurance_policy_id
    JOIN {hospital}.oltp_master_preauth_visit_type_tb vt ON vt.visit_type_id = pre.preauth_visit_type_id
    JOIN {hospital}.oltp_preauth_status ps ON ps.preauth_status_id = pre.preauth_status_id
    JOIN {hospital}.oltp_workflow_state st ON st.workflow_state_id = ps.workflow_state_id
    JOIN {hospital}.oltp_workflow_request_type wrt ON wrt.request_type_id = ps.request_type_id
    LEFT JOIN medical_history_info mh ON mh.preauth_claim_id = pre.preauth_claim_id
    LEFT JOIN examination_findings_info ef ON ef.preauth_claim_id = pre.preauth_claim_id
    LEFT JOIN diagnosis_info di ON di.preauth_claim_id = pre.preauth_claim_id
    LEFT JOIN treatment_into ti ON ti.preauth_claim_id = pre.preauth_claim_id
    LEFT JOIN billing_info bi ON bi.preauth_claim_id = pre.preauth_claim_id
    LEFT JOIN targets y ON y.preauth_id = pre.preauth_claim_id
WHERE pre.isclosed = true