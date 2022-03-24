/************************************************************************************************************
#m     Module                 :  POWERCHART
*****************************************************************************************************************************
#n     Program Common Name    :  ALF_PF_LTC_VITAL_SIGNS
#n     Program Object Name    :  ALF_PF_LTC_VITAL_SIGNS
#n     Program Run From       :  POWERFORM
*****************************************************************************************************************************
#d     Description            :  This template pulls in the latest data from the lung function grid (today).
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
#m		001		Mandeep Singh	06 SEP 2017		Initial version
		002 	Mandeep Singh	02 NOV 2017		Fetch the Previous lung function comments
 
*****************************************************************************************************************************/
 
drop 	program alf_pf_ltc_lungfunc go
create 	program alf_pf_ltc_lungfunc
 
 
;************************************
;******* Variable declaration *******
;************************************
 
set RHEAD = "{\rtf1\ansi \deff0{\fonttbl{\f0\fswiss Arial;}}{\colortbl;\red0\green0\blue0;\red255\green255\blue255;}\deftab1134"
 
set RH2R  = "\plain \f0 \fs21 \cb2 \pard\sl0\fs20 "
 
set RTFEOF = "} "
 
set REOL = "\par "
 
 
declare person_id = f8
set		person_id = REQUEST->PERSON[1]->PERSON_ID
 
declare lung_func_cd	= f8
set		lung_func_cd	= uar_get_code_by("DISPLAYKEY", 72, "LTCLUNGFUNCTODAYGRID")
 
declare newline = c5
set		newline = "\par "
 
declare no_more_processing = i2 ; flag
set	 	no_more_processing = 0
 
declare result = vc
set		result = ""
 
declare tab = c4
set		tab = "    "
 
;mod#002
declare parent_event_id = f8
set		parent_event_id = 0.0
 
declare lung_func_cmnts_cd	= f8
set		lung_func_cmnts_cd	= uar_get_code_by("DISPLAYKEY", 72, "LTCLUNGFUNCCOMMENTS")
 
 
 
;************************************
;******* Program logic begins *******
;************************************
 
select
	; grid.event_id
	;,grid.result_val
	;, grid.collating_seq
	;,grow.parent_event_id
	grow.event_id
	;,grow.result_val
	,grow.collating_seq
	,grow.event_title_text
	;,row_header = substring(21,textlen(grow.event_tag)-20, grow.event_tag)
	,row_header = 	if 		(findstring("FEV",grow.event_tag) > 0) "FEV1"
					elseif 	(findstring("FVC",grow.event_tag) > 0) "FVC"
					elseif 	(findstring("FER",grow.event_tag) > 0) "FER"
					;elseif 	(findstring("Other",grow.event_tag) > 0) "Other"
					else	grow.event_tag
					endif
	;,gcol.parent_event_id
	;,gcol.event_id
	,gcol.collating_seq
	,col_header = gcol.event_title_text
	,gcol.event_tag
	,gcol.result_val
 
from
	clinical_event grid
	, clinical_event grow
	, clinical_event gcol
 
plan grid where
	grid.person_id = person_id
	and
	grid.event_cd = lung_func_cd
	and
	grid.valid_until_dt_tm > sysdate
 
join grow where
	grow.parent_event_id = grid.event_id
	and
	grow.valid_until_dt_tm > sysdate
 
join gcol where
	gcol.parent_event_id = grow.event_id
	and
	gcol.valid_until_dt_tm > sysdate
 
order by grid.event_end_dt_tm desc, grow.collating_seq, gcol.collating_seq
 
HEAD grid.event_end_dt_tm
 
	x = 0
 
HEAD grow.collating_seq
 
	if (no_more_processing = 0)
 
		if (trim(result,3) = "")
			result = concat( "\qc\b ", trim(format(grid.valid_from_dt_tm, "dd-mm-yyyy"),3), "\b0\par\par\ql\ul ", trim(row_header,3), "\ul0 " )
		else
			result = concat( trim(result,3), newline, "\ul ", trim(row_header,3), "\ul0 " )
		endif
 
		first_col = 0
 		;mod#002
 		parent_event_id = grid.parent_event_id
 
 	endif
 
DETAIL
 
 	if (no_more_processing = 0)
 
	 	if (first_col = 0)
	 		result = concat( trim(result,3), tab, "\b ", trim(col_header,3), ": \b0 ",  trim(gcol.result_val,3)  )
	 		first_col = 1
	 	else
			result = concat( trim(result,3), "     \b ", trim(col_header,3), ": \b0 ", trim(gcol.result_val,3)  )
		endif
 
	endif
 
 
FOOT grid.event_end_dt_tm
 
	no_more_processing = 1  ; No more processing reqd as most recent grid data has been fetched.Ignore the rest.
 
WITH nocounter
 
 
/*** Fetch last entered comments for Lung Function ***/
 
select
	c.result_val
from
	clinical_event c
where
	c.parent_event_id = parent_event_id
	and
	c.person_id = person_id
	and
	c.event_cd = lung_func_cmnts_cd
	and
	c.valid_until_dt_tm > sysdate
 
DETAIL
 
	result = concat( trim(result,3), newline,newline, trim("Previous Lung Function (comments):",3), " ", trim(c.result_val,3)  )
 
WITH nocounter
 
/*** Set the reply string ***/
 
set REPLY->TEXT = concat(RHEAD, RH2R, result, RTFEOF)
 
 
end
go
 
