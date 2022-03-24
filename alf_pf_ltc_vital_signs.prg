/************************************************************************************************************
#m     Module                 :  POWERCHART
*****************************************************************************************************************************
#n     Program Common Name    :  ALF_PF_LTC_VITAL_SIGNS
#n     Program Object Name    :  ALF_PF_LTC_VITAL_SIGNS
#n     Program Run From       :  POWERFORM
*****************************************************************************************************************************
#d     Description            :  This template pulls in the latest "Vital Signs" of a patient as displayed in Powerchart,
								 which were posted the same day.
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
#m		001		Mandeep Singh	23 AUG 2017		Initial version
 
 
*****************************************************************************************************************************/
 
drop 	program alf_pf_ltc_vital_signs go
create 	program alf_pf_ltc_vital_signs
 
;************************************
;******* Variable declaration *******
;************************************
 
set RHEAD = "{\rtf1\ansi \deff0{\fonttbl{\f0\fswiss Arial;}}{\colortbl;\red0\green0\blue0;\red255\green255\blue255;}\deftab1134"
 
set RH2R  = "\plain \f0 \fs21 \cb2 \pard\sl0 "
 
set RTFEOF = "} "
 
set REOL = "\par "
 
 
declare person_id = f8
set		person_id = REQUEST->PERSON[1]->PERSON_ID
 
declare event_set_cd	= f8
set		event_set_cd	= uar_get_code_by("DISPLAYKEY", 93, "VITALSIGNS")
 
 
declare pat_height_cd	= f8
set		pat_height_cd	= uar_get_code_by("DISPLAYKEY", 72, "PATIENTHEIGHT")
 
declare pat_weight_cd	= f8
set		pat_weight_cd	= uar_get_code_by("DISPLAYKEY", 72, "PATIENTWEIGHT")
 
declare pat_BMI_cd		= f8
set		pat_BMI_cd		= uar_get_code_by("DISPLAYKEY", 72, "BMI")
 
 
declare no_more_processing = i2 ; flag
set	 	no_more_processing = 0
 
declare result = vc
set		result = "No vital signs available"
 
declare vital_sign_type = vc
set		vital_sign_type = " "
 
 
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
 
/*** fetch the most recent of each type of "vital sign" and then order all the signs by most recent first ***/
 
select
		ex.event_cd
		, c.event_end_dt_tm
		, c.valid_from_dt_tm
		, c.result_val
		, result_unit		= UAR_GET_CODE_DISPLAY(c.result_units_cd)
from
	V500_EVENT_SET_EXPLODE ex
	, clinical_event c
 
plan ex where
	ex.event_set_cd = event_set_cd ; vital signs
	and
	ex.event_cd not in (pat_height_cd, pat_weight_cd, pat_BMI_cd)
 
join c where
	c.person_id = person_id
	and
	c.event_cd = ex.event_cd
	and
	c.valid_until_dt_tm > sysdate
	and
	; fetch the most recent of a particular vital sign. Event_end_dt_tm is the date visible in Results in powerchart
	c.event_end_dt_tm = ( 	select max(c1.event_end_dt_tm)
							from clinical_event c1
							where
							c1.event_cd = c.event_cd
							and
							c1.person_id = person_id
							and
							c1.valid_until_dt_tm > sysdate
						)
 
order by c.event_end_dt_tm desc
 
HEAD REPORT
 
	no_more_processing = 0
 
 
HEAD c.event_end_dt_tm
 
	if (no_more_processing = 0)
 
		;result = trim(concat("\ul As on \b ", format(c.event_end_dt_tm, "mmm dd, yyyy"), "\b0\ul0\par"),3)
		result = concat("\qc\ul As on ", format(c.event_end_dt_tm, "dd-mm-yyyy"),"\ul0\par\ql\fs20 ")
 
	endif
 
DETAIL
 
	if (no_more_processing = 0)
 
		vital_sign_type = " "
		vital_sign_type = uar_get_code_description(ex.event_cd)
 
		;result = concat(result, trim(vital_sign_type,3),": ",trim(c.result_val,3), " ", trim(result_unit,3))
		result = concat(result," \par\b ", trim(vital_sign_type,3), " : \b0 ", trim(c.result_val,3), " ", trim(result_unit,3))
 
	endif
 
FOOT c.event_end_dt_tm
 
	no_more_processing = 1 ; No more processing reqd as most recent vital signs have been fetched.Ignore the rest.
 
 
WITH nocounter
 
/*** Set the reply string ***/
 
set REPLY->TEXT = concat(RHEAD, RH2R, result, RTFEOF)
 
end
go
