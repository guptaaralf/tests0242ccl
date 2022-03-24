/************************************************************************************************************
#m     Module                 :  POWERCHART
*****************************************************************************************************************************
#n     Program Common Name    :  ALF_PF_LTC_VITAL_SIGNS
#n     Program Object Name    :  ALF_PF_LTC_VITAL_SIGNS
#n     Program Run From       :  POWERFORM
*****************************************************************************************************************************
#d     Description            :  This template pulls in the latest pathology results of a patient as displayed in Powerchart,
								 which were posted the same day. Following pathology results are fetched, if available:
 
								 1. FBE: Hb, WCC, Neutrophil, Platelets
								 2. Routine Biochem: Creatinine, Urea, Potassium, Magnesium
								 3. Immunosuppressants
								 4. General Drugs
 
*****************************************************************************************************************************
#a     Site                   :  The Alfred
#a                               Commercial Road, Melbourne
#a                               Victoria, 3004
#a                               Australia
*****************************************************************************************************************************
#t     Tables                 :  V500_EVENT_SET_EXPLODE, CLINICAL_EVENT
*****************************************************************************************************************************
#v     Version                :  DiscernVisualDeveloper  Version 2012.09.1.56
*****************************************************************************************************************************
#m     Modification Control Log
*****************************************************************************************************************************
#m     	Mod #   Author          Date           	Description
#m     	-----	--------------  -----------		--------------------------------------------------------------------------
#m		001		Mandeep Singh	05 SEP 2017		Initial version
		002 	Mandeep Singh	30 NOV 2017		Fetching eGFR
 
*****************************************************************************************************************************/
 
drop 	program alf_pf_ltc_pathology go
create 	program alf_pf_ltc_pathology
 
 
;************************************
;******* Variable declaration *******
;************************************
 
set RHEAD = "{\rtf1\ansi \deff0{\fonttbl{\f0\fswiss Arial;}}{\colortbl;\red0\green0\blue0;\red255\green255\blue255;}\deftab1134"
 
set RH2R  = "\plain \f0 \fs21 \cb2 \pard\sl0\fs20 "
 
set RTFEOF = "} "
 
set REOL = "\par "
 
 
declare person_id = f8
set		person_id = REQUEST->PERSON[1]->PERSON_ID
 
declare fbe_event_set_cd	= f8
set		fbe_event_set_cd	= uar_get_code_by("DISPLAYKEY", 93, "FBE")
 
; hard-coding all the below ones as multiple entries exist in codeset 72
 
declare hb1_cd = f8
set		hb1_cd = 16263.00
 
declare hb2_cd = f8
set		hb2_cd = 16264.00
 
declare hb3_cd = f8
set		hb3_cd = 1952691.00
 
declare neutro_cd = f8
set		neutro_cd = 16391.00
 
declare plate1_cd = f8
set		plate1_cd = 16426.00
 
declare plate2_cd = f8
set		plate2_cd = 16427.00
 
declare plate3_cd = f8
set		plate3_cd = 1952693.00
 
declare wbc1_cd = f8
set		wbc1_cd = 16567.00
 
declare wbc2_cd = f8
set		wbc2_cd = 16568.00
 
declare wbc3_cd = f8
set		wbc3_cd = 1952692.00
 
 
declare bio_event_set_cd	= f8
set		bio_event_set_cd	= uar_get_code_by("DISPLAYKEY", 93, "ROUTINEBIOCHEM")
 
declare creat1_cd = f8
set		creat1_cd = 16150.00
 
declare creat2_cd = f8
set		creat2_cd = 170191248.00
 
;mod#002
declare eGFR_cd = f8
set		eGFR_cd = uar_get_code_by("DISPLAYKEY", 72, "EGFR")
;mod#002
 
declare urea_cd = f8
set		urea_cd = uar_get_code_by("DISPLAYKEY", 72, "UREA")
 
declare pota_cd = f8
set		pota_cd = uar_get_code_by("DISPLAYKEY", 72, "POTASSIUM")
 
declare mgm_cd = f8
set		mgm_cd = uar_get_code_by("DISPLAYKEY", 72, "MAGNESIUMLEVEL")
 
 
declare immuno_event_set_cd	= f8
set		immuno_event_set_cd	= uar_get_code_by("DISPLAYKEY", 93, "IMMUNOSUPPRESSANTS")
 
declare siro_cd = f8
set		siro_cd = uar_get_code_by("DISPLAYKEY", 72, "SIROLIMUSLEVEL")
 
declare tacro_cd = f8
set		tacro_cd = uar_get_code_by("DISPLAYKEY", 72, "TACROLIMUSLEVEL")
 
declare evero_cd = f8
set		evero_cd = uar_get_code_by("DISPLAYKEY", 72, "EVEROLIMUSLEVEL")
 
declare cyclo_cd = f8
set		cyclo_cd = uar_get_code_by("DISPLAYKEY", 72, "CYCLOSPORINLEVEL")
 
 
declare drugs_event_set_cd	= f8
set		drugs_event_set_cd	= uar_get_code_by("DISPLAYKEY", 93, "GENERALDRUGS")
 
declare posa_cd = f8
set		posa_cd = uar_get_code_by("DISPLAYKEY", 72, "POSACONAZOLELEVEL")
 
declare vori_cd = f8
set		vori_cd = uar_get_code_by("DISPLAYKEY", 72, "VORICONAZOLELEVEL")
 
 
declare inerrer_cd = f8
set     inerror_cd = uar_get_code_by("MEANING", 8, "INERROR")
 
 
declare no_more_processing = i2 ; flag
set	 	no_more_processing = 0
 
declare result = vc
set		result = "";Pathology test results"
 
declare newline = c5
set		newline = "\par "
 
declare newpara = c9
set		newpara = "\par\par "
 
declare category_name = vc
set		category_name = " "
 
 
/*
declare result_dt = vc
set		result_dt = ""
 
declare updated_by = vc
set		updated_by = ""
 
declare update_dttm = vc
set 	update_dttm = ""
 
declare filler = vc
set		filler = " by \b"
*/
 
;************************************
;******* Program logic begins *******
;************************************
 
/*** fetch the most recent tests (within the last 3 months) and then order by most recent first within the respective categories ***/
 
SELECT
	event_set_order = 	if 		(ex.event_set_cd = fbe_event_set_cd) 	1
						elseif  (ex.event_set_cd = bio_event_set_cd) 	2
						elseif  (ex.event_set_cd = immuno_event_set_cd) 3
						else  	4 ;drugs
						endif
 
	, event_set_name 	 = uar_get_code_description(ex.event_set_cd)
	, test_name 	 	 = uar_get_code_description(ex.event_cd)
	, c.event_end_dt_tm  "@SHORTDATETIME"
	, day 				 = CNVTDATE(c.event_end_dt_tm)
	, c.valid_from_dt_tm "@SHORTDATETIME"
	, c.updt_dt_tm 		 "@SHORTDATETIME"
	, c.result_val
	, C_RESULT_UNITS_DISP = UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD)
	, *
 
FROM
	V500_EVENT_SET_EXPLODE   ex
	, clinical_event   c
 
plan ex where
	(	ex.event_set_cd = fbe_event_set_cd
		and
		ex.event_cd in (hb1_cd, hb2_cd, hb3_cd, neutro_cd, plate1_cd, plate2_cd, plate3_cd, wbc1_cd, wbc2_cd, wbc3_cd)
	)
 
	or
	(	ex.event_set_cd = bio_event_set_cd
		and									 ;mod#002 - added eGFR_cd
		ex.event_cd in (creat1_cd, creat2_cd, eGFR_cd, urea_cd, pota_cd, mgm_cd)
 
	)
	or
	(	ex.event_set_cd = immuno_event_set_cd
		and
		ex.event_cd in (siro_cd, tacro_cd, evero_cd, cyclo_cd)
 
	)
	or
	(	ex.event_set_cd = drugs_event_set_cd
		and
		ex.event_cd in (posa_cd, vori_cd)
 
	)
 
join c where
	c.person_id = person_id
	and
	c.event_cd = ex.event_cd
	and
	c.valid_until_dt_tm > sysdate
	and
	c.result_status_cd != inerror_cd
	and
	c.event_end_dt_tm = ( 	select max(c1.event_end_dt_tm)
							from clinical_event c1
							where
							c1.event_cd = c.event_cd
							and
							c1.person_id = person_id
							and
							c1.valid_until_dt_tm > sysdate
							and
							c1.result_status_cd != inerror_cd
							and 								 ; fetch results not more than 3 months old
							c1.event_end_dt_tm >= CNVTLOOKBEHIND("3,M",cnvtdatetime(cnvtdate(sysdate), 000000))
						)
 
ORDER BY
	;event_set_order, day DESC, c.event_end_dt_tm desc
	event_set_order, day DESC
 
 
HEAD event_set_order
 
 	if (event_set_order = 3)
 		category_name = "Immunosuppression"
 
  	elseif  (event_set_order = 4)
  		category_name = "Anti-fungal"
 
  	else
 		category_name = event_set_name
 
 	endif
 
 
 	if (trim(result,3) = "")
		result = concat(newpara, " \ul ", trim(category_name,3), " as on ", trim(format(c.event_end_dt_tm, "dd-mm-yyyy"),3), "....... \ul0" )
	else
		result = concat(trim(result,3), newpara, " \ul ", trim(category_name,3), " as on ", trim(format(c.event_end_dt_tm, "dd-mm-yyyy"),3), "....... \ul0" )
	endif
 
	same_day_records_processed 	= 0
 
HEAD day
 
 	first_record = 0
 
DETAIL
 
	if (same_day_records_processed = 0)
 
 		if (first_record = 0)
 
			result = concat( trim(result,3), newline, " \b ", trim(test_name,3), ": \b0 ", trim(c.result_val,3), " ", trim(C_RESULT_UNITS_DISP,3))
 
			first_record = 1
 
		else
			result = concat( trim(result,3),"        \b ", trim(test_name,3), ": \b0 ", trim(c.result_val,3), " ", trim(C_RESULT_UNITS_DISP,3))
		endif
 
	endif
 
 
FOOT day
 
	same_day_records_processed = 1
 
;FOOT event_set_order
 
;	newlines = "\par\par "
 
WITH nocounter
 
/*** Set the reply string ***/
 
set REPLY->TEXT = concat(RHEAD, RH2R, result, RTFEOF)
 
 
 
end
go
 
