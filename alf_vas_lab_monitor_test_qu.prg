/**************************************************************************************************************
#m     Module                 :     PM
#n     Program Common Name    :     ALF_VAS_LAB_MONITOR_TEST_QU.PRG
#n     Porgram Object Name    :     ALF_VAS_LAB_MONITOR_TEST_QU
#n     Program Run From       :     EXPLORER MENU
***************************************************************************************************************
#d     Description            :     This program produces the reports that are Verified/ Unverified/ Transcribed
#d                            :      relating to Vascular Lab
#d                            :     Ultrasound scan.
#d                            :     Requested by Justine Carder, Infra call no. 902240
***************************************************************************************************************
#a     Site                   :     Alfred Healthcare Group
                                    Commercial Road, Melbourne
                                    Victoria, 3004
                                    Australia
***************************************************************************************************************
#t     Tables                 :
                              :
                              ;
                              ;
                              :
                              :
                              :
***************************************************************************************************************
#v     Version                :     Cerner Command Language Version 8.0+++
***************************************************************************************************************
#m     Modification Control Log
***************************************************************************************************************
#m     Mod #     Author                   Date             Description
       -----     -----------------------  ---------------  -------------------
         1       Arun Gupta               25/02/2014       Initial Version
         2       Phuong / Amit            15/05/2014       Added Sonographer in report
         3       John Everts              17/06/2014       Added option to produce extract rather than report
 		 4		 Neha Narota			  06/04/2017	   115460 - add column to display whether the patient
 		 												   is an Inpatien or an Outpatient
		 5		 Mohammed Al-Kaf		  18/05/2017	   112888 added time differnce between perform and sign
		 6		 Neha Narota			  21/09/2017	   37686 - 'Sonographer' details not showing in the output
***************************************************************************************************************/
 
drop program alf_vas_lab_monitor_test_qu go
create program alf_vas_lab_monitor_test_qu
 
prompt
	"Output to File/Printer/MINE" = "MINE"
	, "Start Performed Date" = CURDATE
	, "End Performed Date" = CURDATE
	;<<hidden>>"Display Message" = ""
	;<<hidden>>"checkDate" = ""
	, "Report or Extract" = ""
 
with OUTDEV, SPDATE, EPDATE, runtype
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
set nbr_appts = 0
 
declare mrow     = i2
declare line_out = vc
set     delim    = char(9)
 
if ($runtype = "R")
   set mrow   = 56
   set dioval = 8
   set ffval  = "POST"
else
   set mrow   = 1
   set dioval = 0
   set ffval  = "NONE"
endif
 
set linefeed = char(10)
set htab     = char(9)
 
declare encntID = f8
declare evenID  = f8
 
declare xcnt = i2
set     xcnt = 0
 
free record MsgData
record MsgData
(
 1 MsgValue = VC
)
 
free record MsgheaderD
record MsgheaderD
(
 1 MsgValue = VC
 2 Title2 = c17
 2 Title3 = c11
 2 Title4 = c26
 2 Title5 = c31
 2 Title6 = c18
 2 Title7 = c26
 2 Title8 = c17
 2 Title9 = vc
)
;Free record MsgheaderD
;record MsgheaderD
;( title2d = c17
;        Title3 = c11
;        Title4 = c26 ;"EventTitle"
;        Title5 = c31;"ResultType"
;        Title6 = c18;"ResultStatus"
;        Title7 = c26;"VerifiedBY"
;        Title8 = c17;"VerifiedDate"
;)
 
 
;declare MsgData = VC
;set MsgData = ""
;
 
 
declare rescnt = i2
set rescnt = 0
 
declare cnt = i2
set cnt = 0
 
declare pos = i2
set pos = 0
 
free record apptinfo
record apptinfo
(
 1 data [*]
	2 prfm_by= VC
 	2 prfm_date = c17
 	2 person_id = c11
 	2 eventTitle =  c26
 	2 ResultType = c31
 	2 ResultStatus = c18
 	2 VerifiedBy = c26 ;VC
 	2 VerifiedDate = c17
 	2 ENCNTRALIAS = c11
 	2 position = vc
 	2 ENCNTR_TYP = vc
 	2 TIME_DIFF = vc ;mod 005
 	2 EVENT_ID = F8  ;MOD 06
)
 
 
FREE record resevents
record resevents
 (1 qual [*]
    2 indx = i2
    2 evnt_cd = f8
    )
 
declare event_class = F8
set event_class = UAR_GET_CODE_BY("MEANING",53,"MDOC")
 
declare result_in_progress = F8
set result_in_progress = UAR_GET_CODE_BY("DisplayKey",8,"INPROGRESS")
 
declare MRN_CODE = F8
set MRN_CODE =  UAR_GET_CODE_BY("DisplayKey",319,"MRN")
 
set ocfcd = 573
DECLARE doc_event_class = f8
set doc_event_class = uar_get_code_by("DISPLAYKEY", 53, "DOC")
 
 
set root_cd = 0
set child_cd = 0
 
select into "nl:"
    c.code_value
    from code_value c
    where c.code_set = 24
    and c.active_ind = 1
detail
  case (c.cdf_meaning)
    of "ROOT":
       root_cd = c.code_value
    of "CHILD":
       child_cd = c.code_value
  endcase
with nocounter
 
/**************************************************************
; DVDev Start Coding
**************************************************************/
 
/*******Get the values of all child code set for Vascular lab in array ****/
set rescnt = 0
 
select into "nl:"
                V.EVENT_CD
FROM
                V500_EVENT_SET_EXPLODE   V
                , CODE_VALUE   CV1
 
PLAN cv1
where cv1.code_set = 93
  and cv1.display_key = "VASCULARLABORATORY" ;*****VASCULAR LAB SET********
join v
where cv1.code_value = v.event_set_cd
head report
  stat = alterlist(resevents->qual,10)
detail
 
  rescnt = rescnt + 1
   IF ((MOD(rescnt,10) =1)  AND (rescnt != 1))
           STAT = ALTERLIST(resevents->qual,rescnt + 9)
   ENDIF
 
 
  resevents->qual[rescnt].indx = 1
  resevents->qual[rescnt].evnt_cd = v.event_cd
 
foot report
        STAT = ALTERLIST(resevents->qual,rescnt)
 
with nocounter
 
/*
select into $1
from (dummyt d with seq = value(rescnt))
detail
cnt = cnt +1
col 1  resevents->qual[cnt].evnt_cd
col 100 colDate
row +1
 */
; *****************************************
; **** Get results from clinical_event ****
; *****************************************
 
 
 
SELECT INTO ($OUTDEV)
	Performed_by = pers.name_full_formatted
	, Position = uar_get_code_display(pers.position_cd)
	, ce.person_id
	, ce.event_title_text
	, Result_Type = UAR_GET_CODE_DISPLAY(CE.event_cd)
	, Result_Status = UAR_GET_CODE_DISPLAY(Ce.RESULT_STATUS_CD)
	, Performed_Date = ce.performed_dt_tm
	, ce.updt_dt_tm
	, Verified_by = pers2.name_full_formatted
	, Verfied_date = ce.verified_dt_tm
	, encntrAlias = ea.alias
	, EncntID = ce.encntr_id
	, E_ENCNTR_TYPE_DISP = UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CD)
	, DIFF = DATETIMEDIFF(ce.verified_dt_tm ,ce.performed_dt_tm) ;mod 5
 
FROM
	(dummyt   d  with seq = value(rescnt))
	, clinical_event   ce
	, Prsnl   pers
	, Prsnl   pers2
	, ENCOUNTER   E
	, ENCNTR_ALIAS   EA
	, dummyt   d1
	, clinical_event   ce2
	, ce_blob   cb
 
Plan d
 
join ce
where
 ce.performed_dt_tm  between cnvtdatetime(cnvtdate($spdate,e),0)
                    and cnvtdatetime(cnvtdate($epdate,e),235959)
;cnvtdatetime(cnvtdate($epdate,e),235959)
; ce.performed_dt_tm  between cnvtdatetime("01-JAN-2013 00:00:00")
;                   and cnvtdatetime("17-JAN-2013 23:59:59")
and  ce.event_class_cd = event_class ; mdoc
and ce.event_cd = resevents->qual[d.seq].evnt_cd
and ce.event_id = ce.parent_event_id
and ce.result_status_cd != result_in_progress
 
Join Pers
where pers.person_id =  ce.performed_prsnl_id
;and pers.position_cd = 32798.00
 
join e
WHERE CE.encntr_id = E.encntr_id
 
Join EA
where ea.encntr_id = ce.encntr_id
and ea.encntr_alias_type_cd = MRN_CODE
 
 
Join pers2
where ce.verified_prsnl_id =  pers2.person_id
 
;PP - Start outerjoin from here to if there is ce_blob data.
join d1
 
join ce2
where CE.EVENT_ID = CE2.PARENT_EVENT_ID
and CE2.event_class_cd =  doc_event_class ; 263.00
and CE2.event_reltn_cd =  child_cd   ; 186.00
and CE2.valid_until_dt_tm + 0 >= cnvtdatetime(curdate,curtime3)
 
JOIN CB
 
WHERE CE2.EVENT_ID = CB.EVENT_ID
	and cb.compression_cd = ocfcd
	and cb.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
 
ORDER BY
	ce.performed_prsnl_id
	, ce.event_id
	, ce.updt_cnt  desc
 
Head Report
 
 STAT = ALTERLIST(apptinfo->data,10)
 
head ce.performed_prsnl_id
	null
 
head ce.event_id
 
;detail
 
		nbr_appts = nbr_appts + 1
 
        IF ((MOD(nbr_appts,10) =1)  AND (nbr_appts != 1))
           STAT = ALTERLIST(apptinfo->data,nbr_appts + 9)
        ENDIF
 
 
;		apptinfo->data[nbr_appts].prfm_by = trim(Performed_by)
;		apptinfo->data[nbr_appts].prfm_date = trim(format(Performed_Date,"DD/MM/YYYY HH:MM;;d"))
;		apptinfo->data[nbr_appts].person_id = trim(cnvtstring(ce.person_id))
; 		apptinfo->data[nbr_appts].eventTitle = trim(substring(0,25,ce.event_title_text))
; 		apptinfo->data[nbr_appts].ResultType = trim(substring(0,25,Result_Type))
; 		apptinfo->data[nbr_appts].ResultStatus = trim(Result_Status)
; 		apptinfo->data[nbr_appts].VerifiedBy = trim(substring(0,19,Verified_by))
;  		apptinfo->data[nbr_appts].VerifiedDate =trim(format(Verfied_date,"DD/MM/YYYY HH:MM;;d"))
 
        apptinfo->data[nbr_appts].prfm_by = Performed_by ;Performed_by
 		pos = findstring(":",Performed_by,1,0)
 		if(pos > 0)
 		apptinfo->data[nbr_appts].prfm_by = substring(1,pos-1,Performed_by) ;Performed_by
 		endif
		apptinfo->data[nbr_appts].prfm_date = format(Performed_Date,"DD/MM/YYYY HH:MM;;d")
		apptinfo->data[nbr_appts].person_id = cnvtstring(ce.person_id)
 
 		apptinfo->data[nbr_appts].eventTitle = ce.event_title_text
 		apptinfo->data[nbr_appts].ResultType = Result_Type
 		apptinfo->data[nbr_appts].ResultStatus = Result_Status
 		if(Result_Status = "Auth (Verified)")
 			Result_Status = "Auth (Ver)"
 			apptinfo->data[nbr_appts].ResultStatus = Result_Status
 		endif
        apptinfo->data[nbr_appts].VerifiedBy = Verified_by ;Verified_by
 		pos = findstring(":",Verified_by,1,0)
 		if(pos > 0)
 		apptinfo->data[nbr_appts].VerifiedBy = substring(1,pos-1,Verified_by) ;Verified_by
 		endif
 		apptinfo->data[nbr_appts].VerifiedDate =format(Verfied_date,"DD/MM/YYYY HH:MM;;d")
 		apptinfo->data[nbr_appts].ENCNTRALIAS = trim(cnvtstring(encntrAlias),3)
 		apptinfo->data[nbr_appts].ENCNTR_TYP = TRIM(E_ENCNTR_TYPE_DISP)
 		if(trim(apptinfo->data[nbr_appts].VerifiedDate) != "")
 			apptinfo->data[nbr_appts].TIME_DIFF = FORMAT(DIFF, "DD days HH hours MM minutes;;Z"); mod 005
 		endif
 
detail
    xx = "Nothing"
    encntID = ce.encntr_id
	IF (CE2.EVENT_ID > 0 and apptinfo->data[nbr_appts].ResultStatus != "In Error")
    blob_out = fillstring(32000," ")
    blob_ret_len = 0
    blob_len = 0
    blob_len = textlen(trim(cb.blob_contents))
    call uar_ocf_uncompress(cb.blob_contents,blob_len,blob_out,32000,blob_ret_len)
 
    print_blob = trim(substring(0, 32000, blob_out))
	start_pos = findstring("PERFORMED BY:",cnvtupper(blob_out),1,0)
	end_pos = start_pos+13
;	b1 = findstring("\PAR\PAR REPORT",cnvtupper(blob_out),1,0)
	mid_pos = findstring("\PAR",cnvtupper(blob_out),end_pos,0) ;PP - Start searching from C1
 
;   PP - don't use temp1 as a variable because CCL will set its size to be the length of the very first string found.
;	temp1 = substring(c1,b1-c1,cnvtupper(blob_out))
 /*
    apptinfo->data[nbr_appts].position = substring(1,26,trim(substring(end_pos,mid_pos-end_pos,cnvtupper(blob_out)),3))
 
 	checkgarbage = substring(1,11,apptinfo->data[nbr_appts].position);
 	if(checkgarbage = "ANSICPG1252" )
    apptinfo->data[nbr_appts].position = ""
    endif
 */
	ENDIF
    CALL ECHO (CE.event_id)
    CALL ECHO (CE.parent_event_id)
    APPTINFO->DATA[NBR_APPTS].EVENT_ID = CE.event_id
foot report
        STAT = ALTERLIST(apptinfo->data,nbr_appts)
 
WITH NOCOUNTER, OUTERJOIN = D1, SEPARATOR=" ", FORMAT
 
 
/****************************************************
	MOD 6 # FIND SONOGRAPHER
	PROXY PERSONNEL AGAINST THE ONE THAT PERFORMED
	THE TASK
****************************************************/
SELECT INTO ($OUTDEV)
 
	SONOGRAPHER = PERS.name_full_formatted
FROM
	(dummyt   d  with seq = value(nbr_appts))
	, clinical_event   c
	, CE_EVENT_PRSNL   CE
	, Prsnl   pers
 
Plan d
 
join c
where
/* c.performed_dt_tm  between cnvtdatetime(cnvtdate($spdate,e),0)
                    and cnvtdatetime(cnvtdate($epdate,e),235959)*/
 C.event_id = APPTINFO->DATA[d.SEQ].EVENT_ID
 and c.event_class_cd = event_class ; mdoc
; and c.event_cd = resevents->qual[d.seq].evnt_cd
 and c.event_id = c.parent_event_id
 and c.result_status_cd != result_in_progress
 
JOIN CE
WHERE C.event_id = CE.event_id
 
Join Pers
where pers.person_id =  ce.proxy_prsnl_id
AND PERS.end_effective_dt_tm > SYSDATE
 
order by c.performed_dt_tm
 
detail
 
	Apptinfo->data[D.SEQ].position = sonographer
 
with nocounter, format
 
 
/***************************************************/
; PRINT THE REPORT
/***************************************************/
 
 
SELECT INTO $1
	s1= apptinfo->data[D.seq].prfm_by,
	s2 = apptinfo->data[nbr_appts].prfm_date
;	s3= apptinfo->data[D.seq].person_id
FROM  (DUMMYT D WITH SEQ = VALUE(nbr_appts))
 
order by s1,s2
 
 
Head Report
 
     if ($runtype = "R")
		daterange = concat("( ",format(cnvtdate($spdate,e),"DD/MM/YYYY;;D")," - ",format(cnvtdate($epdate,e),"DD/MM/YYYY;;D")," )")
 
        PrintPSHeader = 0
        Col 0, "{PS/0 0 translate 90 rotate/}"
        Col + 0 "{CPI/13}"
        Row + 1
        Stars = fillstring(190,"*")
 
        ProgName    = "(ALF_VAS_LAB_MONITOR ver1.0)"
        PrintedDate = concat(trim("Printed on")," ",format(curdate,"DD MMM, YYYY;;D"))
        PrintedTime = concat(trim(" at")," ",format(curtime,"HH:MM;;S"))
        Audit       = build(PrintedDate," ",PrintedTime)
        Pages       = "Page:"
        MainTitle   = "Vascular Lab Monitoring Report"
        Ctr         = 0
        Pagebreak   = 0
     endif
 
     Title1 = "Performed By"
     Title2 = "PerformedDate"
     Title3 = "MRN"
     Title4 = "EventTitle"
     Title5 = "ResultType"
     Title6 = "ResultStatus"
     Title7 = "VerifiedBy"
     Title8 = "VerifiedDate"
     Title9 = "Sonographer"
     Title10 = "EncounterType"
     Title11 = "TimeDiff" ;mod 005
 
     if ($runtype = "E")
        line_out = build(Title1, delim,
                         Title2, delim,
                         Title3, delim,
                         Title5, delim,
                         Title6, delim,
                         Title7, delim,
                         Title8, delim,
                         Title9, delim,
                         Title10, delim,
                         Title11, delim)
        col 0 line_out
        row + 1
     endif
 
Head Page
 
     if ($runtype = "R")
        if (PrintPSHeader)
           Col 0, "{PS/0 0 translate 90 rotate/}"
           Row + 1
        endif
        PrintPSHeader = 1
        Row + 2
        Col 0 Stars
        Row + 1
        Col 0   ProgName
        Col 50 "{B}"
        Col + 0 MainTitle
        Col + 0"{ENDB}"
        Row + 1
 
        Col 0 Audit
        Col 51 "{B}"
        Col + 0 daterange
        Col + 0"{ENDB}"
 
        Col 100 Pages
        Col 105 Curpage "##"
 
		Row + 1
        Col 0   Stars
		Row + 1
     endif
 
 ;stat = alterlist(MsgData->MsgValue,5)
 
 
;
;		MsgheaderD->Title2 = "PerformedDate"
;		MsgheaderD->Title3 = "MRN"
;		MsgheaderD->Title4 = "EventTitle"
;		MsgheaderD->Title5 = "ResultType"
;		MsgheaderD->Title6 = "ResultStatus"
;		MsgheaderD->Title7 = "VerifiedBY"
;		MsgheaderD->Title8 = "VerifiedDate"
 
head s1
 
    if ($runtype = "R")
       Row + 1
	   Col 2 "{U}"
	   Col + 0   Title1, ": "
 
 	   if(nbr_appts>0)
		  Col 20  apptinfo->data[D.seq].prfm_by
	   endif
	   Col + 0  "{ENDU}"
 
	   Row + 2
 
 
	   Col 1 Title2
	   Col 20 Title3
	   Col 29 Title5
	   Col 58 Title6
	   Col 71 Title7
	   Col 92 Title8
	   COl 110 Title9
	   COl 125 title10
	   Col 140 title11 ;mod 005 note that there is no enough space to view this column, so advised the user to use extract instead
 
	   Row + 2
 
       countUnverRec = 0
       countTotalRec = 0
       countInpatRec = 0
       countOutpatRec = 0
       countOtherRec = 0
    endif
 
;   MsgData->MsgValue = concat(MsgData->MsgValue,linefeed,"Performed By :",htab,apptinfo->data[D.seq].prfm_by,linefeed)
;   MsgData->MsgValue  = concat(MsgData->MsgValue,htab,MsgheaderD->Title2,htab,MsgheaderD->Title3,htab,MsgheaderD->Title6,htab,\
;   MsgheaderD->Title7,htab,MsgheaderD->Title8,htab,htab,MsgheaderD->Title5,linefeed)
 
detail
 
 ;str_ver_by = textlen(apptinfo->data[D.seq].VerifiedBy)
    if (nbr_appts > 0)
       if ($runtype = "R")
          resultTypeCut = SUBSTRING(1,28,apptinfo->data[D.seq].ResultType)
 
          Col 1   apptinfo->data[D.seq].prfm_date
	      Col 20  apptinfo->data[D.seq].ENCNTRALIAS
	      Col 29  resultTypeCut
		  Col 58  apptinfo->data[D.seq].ResultStatus
		  Col 71  apptinfo->data[D.seq].VerifiedBy
		  Col 92  apptinfo->data[D.seq].VerifiedDate
		  Col 110 apptinfo->data[D.seq].position
		  col 125 apptinfo->data[D.seq].ENCNTR_TYP
		  col 140 apptinfo->data[D.seq].TIME_DIFF ;mod 005
 
 
 
	;	MsgData->MsgValue = concat(MsgData->MsgValue,htab,\
	;							  apptinfo->data[D.seq].prfm_date,  htab,apptinfo->data[D.seq].person_id,htab,\
	;							  apptinfo->data[D.seq].ResultStatus,htab, apptinfo->data[D.seq].VerifiedBy,  htab,\
	;							  apptinfo->data[D.seq].VerifiedDate,htab,htab,htab,apptinfo->data[D.seq].ResultType,linefeed )
	      Row + 1
 
		  if (apptinfo->data[D.seq].ResultStatus != 'Auth (Ver)')
		     countUnverRec = countUnverRec+1;
		  endif
 
 		  ; Count of Inpatients
 		  case (apptinfo->data[D.seq].ENCNTR_TYP)
 
 		  	of "Inpatient" : countInpatRec = countInpatRec + 1
 
 		  	of "Outpatient": countOutpatRec = countOutpatRec + 1
 
 		  	else 		     countOtherRec = countOtherRec + 1
 		  endcase
 
		  countTotalRec = countTotalRec + 1
;         col 0 MsgData
;         Row + 1
       else
          line_out = build(apptinfo->data[D.seq].Prfm_by,      delim,
                           apptinfo->data[D.seq].Prfm_date,    delim,
                           apptinfo->data[D.seq].Encntralias,  delim,
                           apptinfo->data[D.seq].ResultType,   delim,
                           apptinfo->data[D.seq].ResultStatus, delim,
                           apptinfo->data[D.seq].VerifiedBy,   delim,
                           apptinfo->data[D.seq].VerifiedDate, delim,
                           apptinfo->data[D.seq].Position,     delim,
                           apptinfo->data[D.seq].ENCNTR_TYP,   delim,
                           apptinfo->data[D.seq].TIME_DIFF,   delim)
          col 0 line_out
          row + 1
	   endif
	endif
;
;    col 0 MsgData
;    Row + 1
;
foot s1
    if (nbr_appts > 0)
       if ($runtype = "R")
	      countTotalRecVer = countTotalRec-countUnverRec
		  Row + 1
		  Col 2 "{U}{B}"
	      Col + 0 "Summary - "apptinfo->data[D.seq].prfm_by
	      Col + 0"{ENDB}{ENDU}"
		  Row + 2
		  Col 2 "{B}"
	      Col + 0 "Number of documents Unverified(Transcribed, In error,Unauth) : "
	      Col 67 countUnverRec
	      Col + 0"{ENDB}"
	      Row + 1
		  Col 2 "{B}"
	      Col + 0 "Number of documents Verified : "
	      Col 67 countTotalRecVer
	      Col + 0"{ENDB}"
	      Row + 1
		  Col 2 "{B}"
	      Col + 0 "Total number of documents : "
	      Col 67 countTotalRec
	      Col + 0"{ENDB}"
	      Row + 1
	      Col 2 "{B}"
	      Col + 0 "Inpatient Encounters : "
	      Col 67 countInpatRec
	      Col + 0"{ENDB}"
	      Row + 1
	      Col 2 "{B}"
	      Col + 0 "Outpatient Encounters : "
	      Col 67 countOutpatRec
	      Col + 0"{ENDB}"
	      Row + 1
	      Col 2 "{B}"
	      Col + 0 "Others : "
	      Col 67 countOtherRec
	      Col + 0"{ENDB}"
          Row + 2
       endif
	endif
 
WITH MAXCOL = 250, DIO = value(dioval), NULLREPORT, NOHEADING, FORMAT = VARIABLE, MAXROW = value(mrow), LANDSCAPE
 
 
;	Set PrintedDate = concat(trim(" on")," ",format(curdate,"DD MMM, YYYY;;D"))
;
;	FREE SET MSGSUBJECT
;	SET MSGSUBJECT = concat("Vascular Lab Monitoring Report",PrintedDate)
;
;	FREE SET MSGBODY
;	SET MSGBODY = concat(MsgData->MsgValue,linefeed,linefeed,linefeed,"***********IMPORTANT -This is an auto generated mail,\
;Please do not reply. ***********",linefeed,linefeed,"In case of any concern please contact
;ITS helpdesk on (03) 9076 3300",linefeed)
;
;	call uar_send_mail("a.gupta@alfred.org.au",MSGSUBJECT,MSGBODY,"ITS_Helpdesk"\
;	,1,"High")
 
end
go
 
