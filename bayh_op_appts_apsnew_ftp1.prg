/***************************************************************************************************************************
#m     Module                 :     SurgiNet
*****************************************************************************************************************************
#n     Program Common Name    :     BAYH_OP_APPTS_APSNEW_FTP1.PRG
#n     Program Object Name    :     BAYH_OP_APPTS_APSNEW_FTP1
#n     Program Run From       :     Explorer Menu/ Ops scheduler
*****************************************************************************************************************************
#d     Description            :     This program generates an extract of all appointments for The Alfred
                                    with given appointment type -- eg AO*
#d
#d     Categories             :
*****************************************************************************************************************************
#a     Site                   :     Alfred Healthcare Group
                                    Commercial Road, Melbourne
                                    Victoria, 3004
                                    Australia
*****************************************************************************************************************************
#t     Tables                 :     SCH_APPT_BOOK
                                    SCH_BOOK_LIST
                                    SCH_APPT
                                    SCH_SLOT_TYPE
*****************************************************************************************************************************
#v     Version                :     Cerner Command Language Version 7.8
*****************************************************************************************************************************
#m     Modification Control Log
*****************************************************************************************************************************
#m  Mod #  By                   Date          Description
    -----  ------------------   ------------  -------------------
           John Everts          20/11/2007    Initial release based on bayh_op_appts_apsnew.prg & bayh_op_appts_apsftp.prg
           John Everts          26/06/2008    Add AP orders not related to appointments
           John Everts          19/03/2009    Pick up all resources if there are more than one for an appointment.
           John Everts          14/09/2009	  Add Research field from order details.
           John Everts          30/05/2011    Stopped APS orders being picked up along with the AP orders.
      005  Phuong Pham          01/11/2012    Change FTP code to Linux.
      006  Bernie Hair          05/03/2013    Fix up timing issues, removed unnecessary table reads, use table indexes
      007  Karel Young          25/05/2015    Added new Universal MRN components to the code
      008  NEHA NAROTA			05/07/2016	  'AH MRN' IS REMOVED FROM THE REPORT AND IS MAPPED TO EXISTING
      										  'ALF MRN' COLUMN. REFER TO INCIDENT - 77820 FOR MORE DETAILS
      009  NEHA NAROTA			31/10/2017	  APPENDED 2 COLUMNS TO DISPLAY SERVICE PROVIDED & SERVICE LOCATION
*****************************************************************************************************************************/
 
DROP   PROGRAM bayh_op_appts_apsnew_ftp1 GO
CREATE PROGRAM bayh_op_appts_apsnew_ftp1
 
prompt
	"Output to File/Printer/MINE" = "MINE"
	, "Enter Start Date (format DDMMYYYY)" = CURDATE
	, "Enter End Date (format DDMMYYYY)" = CURDATE
 
with prompt1, prompt2, prompt3
 
set MaxSecs = 0
 
IF (VALIDATE(IsOdbc, 0)) SET MaxSecs = 15  ENDIF
 
Declare dest_path        = VC
Declare first_resource   = VC
Declare prev_resource_cd = F8
Declare prev_schedule_id = F8
 
set ftptrue = 0
 
IF (CNVTDATE($2,E) = CNVTDATE("31122100",E))
 
;  need to set up to run for previous month and set up output file name based on campus & code
 
   SET This_day   = DAY(CURDATE) ;get the day of the current month.
   SET Start_date = CNVTDATE2(FORMAT(CURDATE - This_day,"01MMYYYY;;D"),"DDMMYYYY")
   SET End_date   = CURDATE-THIS_DAY
 
   IF (month(start_date) <= 9)
      SET Xmonth = CONCAT("0",CNVTSTRING(month(start_date),2))
   ELSE
      SET Xmonth = CNVTSTRING(month(start_date),2)
   ENDIF
 
   SET dest_path  = "AlfPsych\"
   SET Xyear      = CNVTSTRING(year(start_date),4)
   SET Output_loc = BUILD("cust_extracts:APS_",XMonth,Xyear,".txt")
 
ELSEIF (CNVTDATE($2,E) = CNVTDATE("25122100",E))
;  current month from 1-15
 
   SET Start_date = CNVTDATE2(FORMAT(CURDATE ,"01MMYYYY;;D"),"DDMMYYYY")
   SET End_date   = CNVTDATE2(FORMAT(CURDATE ,"15MMYYYY;;D"),"DDMMYYYY")
 
   IF (month(start_date) <= 9)
      SET Xmonth = CONCAT("0",CNVTSTRING(month(start_date),2))
   ELSE
      SET Xmonth = CNVTSTRING(month(start_date),2)
   ENDIF
 
   SET dest_path  = "AlfPsych\"
   SET Xyear      = CNVTSTRING(year(start_date),4)
   SET Output_loc = BUILD("cust_extracts:APS_1_15_",XMonth,Xyear,".txt")
 
ELSEIF (CNVTDATE($2,E) = CNVTDATE("26122100",E))
;  previous month 16 - month end
 
   SET This_day   = DAY(CURDATE) ;get the day of the current month.
   SET Start_date = CNVTDATE2(FORMAT(CURDATE - This_day,"16MMYYYY;;D"),"DDMMYYYY")
   SET End_date   = CURDATE-THIS_DAY
 
   IF (month(start_date) <= 9)
       SET Xmonth = CONCAT("0",CNVTSTRING(month(start_date),2))
   ELSE
      SET Xmonth = CNVTSTRING(month(start_date),2)
   ENDIF
 
   SET dest_path  = "AlfPsych\"
   SET Xyear      = CNVTSTRING(year(start_date),4)
   SET Output_loc = BUILD("cust_extracts:APS_16_end_",XMonth,Xyear,".txt")
 
ELSEIF (CNVTDATE($2,E) = CNVTDATE("27122100",E))
;  Previous week
 
   SET Start_date = CNVTDATE2(FORMAT(CURDATE - 7, "DDMMYYYY;;D"), "DDMMYYYY")
   SET End_date   = CNVTDATE2(FORMAT(CURDATE - 1, "DDMMYYYY;;D"), "DDMMYYYY")
   SET dest_path  = "AlfPsych\"
   SET Output_loc = BUILD("cust_extracts:APS_Weekly.txt")
ELSE
   SET start_date  = cnvtdate($2,E)
   SET end_date    = cnvtdate($3,E)
   SET output_loc  = $1
ENDIF
 
IF   (CNVTDATE($2,E) = CNVTDATE("31122100",E)
   or CNVTDATE($2,E) = CNVTDATE("25122100",E)
   or CNVTDATE($2,E) = CNVTDATE("26122100",E)
   or CNVTDATE($2,E) = CNVTDATE("27122100",E))
      set ftp_filename = cnvtlower(trim(substring(15,60,output_loc)))
      set ftp_pathname = "alfpsych"
      set ftptrue = 1
ENDIF
 
 
set Onum     = 0
set delim    = char(9)
set ALF_MRN  = FILLSTRING(7, " ")
set CGMC_MRN = FILLSTRING(7, " ")
set SDMH_MRN = FILLSTRING(6, " ")
set startpos = 0
set age      = 0
 
declare long_display_str   = vc
declare long_display_str1  = vc
declare appt_Checkedout_cd = f8
declare appt_Checkedin_cd  = f8
declare appt_confirmed_cd  = f8
declare appt_cancelled_cd  = f8
declare appt_scheduled_cd  = f8
declare appt_noshow_cd     = f8
 
set appt_checkedout_cd  = uar_get_code_by("DISPLAYKEY",14233,"CHECKEDOUT")
set appt_checkedin_cd   = uar_get_code_by("DISPLAYKEY",14233,"CHECKEDIN")
set appt_confirmed_cd   = uar_get_code_by("DISPLAYKEY",14233,"CONFIRMED")
set appt_noshow_cd      = uar_get_code_by("DISPLAYKEY",14233,"NOSHOW")
set appt_scheduled_cd   = uar_get_code_by("DISPLAYKEY",14233,"SCHEDULED")
set appt_rescheduled_cd = uar_get_code_by("DISPLAYKEY",14233,"RESCHEDULED")
set appt_cancelled_cd   = uar_get_code_by("DISPLAYKEY",14233,"CANCELED")
 
declare home_addr_cd = f8
set     home_addr_cd = uar_get_code_by("DISPLAYKEY",212,"HOME")
 
set Book_cd       = 0
set Shuffle_cd    = 0
set cancel_cd     = 0
set Reschedule_cd = 0
set Confirm_cd    = 0
set Checkin_cd    = 0
set checkout_cd   = 0
 
SELECT into "nl:"
      c.code_value
FROM  code_value c
WHERE c.code_set = 14232
AND   c.active_ind = 1
 
DETAIL
   CASE (C.CDF_MEANING)
      OF "SCHEDULE"  :  book_cd       = C.CODE_VALUE
      OF "SHUFFLE"   :  shuffle_cd    = C.CODE_VALUE
      OF "CANCEL"    :  cancel_cd     = C.CODE_VALUE
      OF "RESCHEDULE":  reschedule_cd = C.CODE_VALUE
      OF "CONFIRM"   :  confirm_cd    = C.CODE_VALUE
      OF "CHECKIN"   :  checkin_cd    = C.CODE_VALUE
      OF "CHECKOUT"  :  checkout_cd   = C.CODE_VALUE
   ENDCASE
 
WITH nocounter
 
set ah_mrn_cd  = 0
set alf_mrn_cd  = 0
set sdmh_mrn_cd = 0
set cgmc_mrn_cd = 0
 
SET newPAS = UAR_GET_DEFINITION(uar_get_code_by("DISPLAYKEY", 101018, "NEWPAS"))
if(newPAS = "YES")
	set ah_mrn_cd = uar_get_code_by("DISPLAYKEY", 263, "ALFREDHEALTH")
else
	set ah_mrn_cd = -1
ENDIF
 
SELECT into "nl:"
   C.CODE_VALUE
   FROM CODE_VALUE C
   WHERE C.CODE_SET   = 263
   AND   C.DISPLAY_KEY IN ("ALFREDURNUMBERPOOL","CGMCURPOOL","SDMHURNUMBERPOOL")
   AND   C.ACTIVE_IND = 1
 
DETAIL
   CASE (C.DISPLAY_KEY)
      OF "ALFREDURNUMBERPOOL" : alf_mrn_cd  = C.CODE_VALUE
      OF "CGMCURPOOL"         : cgmc_mrn_cd = C.CODE_VALUE
      OF "SDMHURNUMBERPOOL"   : sdmh_mrn_cd = C.CODE_VALUE
   ENDCASE
 
WITH NOCOUNTER
 
set curr_name_cd = 0
 
SELECT into "nl:"
     cv.code_value
FROM code_value cv
WHERE cv.code_set    = 213
AND   cv.cdf_meaning = "CURRENT"
AND   cv.active_ind  = 1
 
DETAIL
   curr_name_cd = cv.code_value
 
WITH nocounter
 
set nbr_appts = 0
 
RECORD apptinfo
( 1 data[*]
    2 sch_event_id     = f8
    2 person_id        = f8
    2 oe_format_id     = f8
    2 Clinic_name      = c40
    2 description      = vc
    2 Appt_type        = c20
    2 appt_desc        = vc
    2 appt_date        = dq8
    2 end_dttm         = dq8
    2 duration         = I4
    2 actual_duration  = I4
    2 resource         = vc
    2 state            = vc
    2 patient          = vc
    2 ah_mrn           = c7
    2 alf_mrn          = c7
    2 cgmc_mrn         = c7
    2 sdmh_mrn         = c7
    2 Book_dt_tm       = dq8
    2 Reschedule_dt_tm = dq8
    2 Confirm_dt_tm    = dq8
    2 cancel_dt_tm     = dq8
    2 checkin_dt_tm    = dq8
    2 checkout_dt_tm   = dq8
    2 wait_time        = c11
    2 Reason           = vc
    2 ref_dr           = vc
    2 ref_unit         = c30
    2 cost_centre      = c10
    2 pat_type         = c20
    2 birth_dt_tm      = dq8
    2 addr1            = vc
    2 addr2            = vc
    2 city             = vc
    2 pcode            = c4
    2 priority         = vc
    2 Booked_by_id     = f8
    2 booked_by_name   = vc
    2 sex              = c1
    2 title            = c6
    2 wrt              = c30
    2 Cancel_Reason    = vc
    2 Ord_Name = vc
    2 ODetail1 = vc
    2 ODetail2 = vc
    2 ODetail3 = vc
    2 ODetail4 = vc
    2 ODetail5 = vc
    2 ODetail6 = vc
    2 ODetail7 = vc
    2 EDetail1 = vc
    2 EDetail2 = vc
    2 EDetail3 = vc
    2 EDetail4 = vc
    2 EDetail5 = vc
    2 Odet[40]
       3 Ord_Name     = vc
       3 Order_id     = f8
       3 Ord_duration = vc
       3 ODetail1     = vc
       3 ODetail2     = vc
       3 ODetail3     = vc
       3 ODetail4     = vc
       3 ODetail5     = vc
       3 ODetail6     = vc
       3 ODetail7     = vc
    2  SRVC_PROVIDED   = VC
    2  SRVC_LOC		   = VC
)
 
SELECT INTO "nl:"
     appt_dt = format(sa.beg_dt_tm,"dd/mm/yy hh:mm;;d")
   ,  SE.SCH_EVENT_ID
   , SA.SCHEDULE_ID
   , se.appt_synonym_free
   , sa2.person_id
 
 
FROM
    SCH_APPT         SA
  , SCH_EVENT        SE
  , SCH_APPT         SA2
  , SCH_EVENT_ACTION SEA
 
;  , PERSON           P
;  , PERSON_ALIAS     PA,
;    PERSON_NAME      PN
;  , ADDRESS          A
 
 
 
PLAN  SA
   WHERE SA.BEG_DT_TM between cnvtdatetime(start_date,000000)
     AND cnvtdatetime(end_date,235959)
   AND   SA.ACTIVE_IND = 1
   AND   SA.ROLE_MEANING IN ("RESOURCE", "ATTENDING")
   AND   SA.SCH_STATE_CD IN (appt_Checkedout_cd, appt_Checkedin_cd, appt_confirmed_cd,
                             appt_cancelled_cd,  appt_scheduled_cd, appt_noshow_cd)
 
JOIN SE
   WHERE SA.SCH_EVENT_ID                 = SE.SCH_EVENT_ID
     AND SE.APPT_SYNONYM_FREE in( "APC *", "APS*")
     and se.version_dt_tm > cnvtdatetime(curdate,curtime3)
JOIN SA2
   WHERE SA.SCHEDULE_ID   = SA2.SCHEDULE_ID
     and SA2.ROLE_MEANING = "PATIENT"
     AND SA2.ACTIVE_IND   = 1
 
JOIN SEA
   WHERE SA.SCH_EVENT_ID = SEA.SCH_EVENT_ID
   AND   SA.SCHEDULE_ID  = SEA.SCHEDULE_ID
   AND   SEA.ACTIVE_IND  = 1
   AND   SEA.SCH_ACTION_CD in (Book_cd, Shuffle_cd, Cancel_cd, Reschedule_cd,
                               Confirm_cd, Checkin_cd, Checkout_cd )
 
 
; Not in use
;JOIN P
;   WHERE SA2.PERSON_ID = P.PERSON_ID
;   AND   P.ACTIVE_IND  = 1
 
;JOIN PA
;   WHERE PA.PERSON_ID            = SA2.PERSON_ID
;   AND   PA.ALIAS_POOL_CD IN (alf_mrn_cd, sdmh_mrn_cd, cgmc_mrn_cd)
;   AND   PA.END_EFFECTIVE_DT_TM >= cnvtdatetime("31-dec-2100 00:00:00.00")
;   AND   PA.ACTIVE_IND           = 1
 
;JOIN PN
;   WHERE PA.person_id    = pn.person_id
;   AND   pn.name_type_cd = curr_name_cd
;   AND   pn.active_ind   = 1
 
;JOIN A
;   WHERE A.ACTIVE_IND         = 1
;   AND   A.PARENT_ENTITY_NAME = "PERSON"
;   AND   A.PARENT_ENTITY_ID   = P.PERSON_ID
;   AND   A.ADDRESS_TYPE_CD    = home_addr_cd
 
ORDER BY
     SA.SCH_EVENT_ID
   , SA.SCHEDULE_ID
   , SA.RESOURCE_CD
 
HEAD REPORT
   STAT         = ALTERLIST(apptinfo->data,10)
   SCH_EVENT_ID = 0
   oe_format_id = 0
 
HEAD SA.SCHEDULE_ID
 
  nbr_appts = nbr_appts + 1
 
  IF ((MOD(nbr_appts,10) = 1) AND (nbr_appts != 1))
     STAT = ALTERLIST(apptinfo->data,nbr_appts + 9)
  ENDIF
 
  Checkedout = 0
  Cin        = CNVTDATETIME(Curdate, curtime)
  Cout       = CNVTDATETIME(Curdate, curtime)
 
  apptinfo->data[nbr_appts].reason    = "%"
  apptinfo->data[nbr_appts].ref_dr    = "%"
  apptinfo->data[nbr_appts].wait_time = " "
 
  first_resource   = "Y"
  prev_resource_cd = 0
  prev_schedule_id = 0
 
HEAD SA.RESOURCE_CD
 
  if (first_resource = "Y")
     first_resource = "N"
  else
     nbr_appts = nbr_appts + 1
 
     IF ((MOD(nbr_appts,10) = 1) AND (nbr_appts != 1))
        STAT = ALTERLIST(apptinfo->data,nbr_appts + 9)
     ENDIF
 
     Checkedout = 0
     Cin        = CNVTDATETIME(Curdate, curtime)
     Cout       = CNVTDATETIME(Curdate, curtime)
 
     apptinfo->data[nbr_appts].reason    = "%"
     apptinfo->data[nbr_appts].ref_dr    = "%"
     apptinfo->data[nbr_appts].wait_time = " "
  endif
 
DETAIL
 
   CASE (SEA.SCH_ACTION_CD)
      OF Book_cd       : apptinfo->data[nbr_appts].Book_dt_tm       = SEA.ACTION_DT_TM
                         apptinfo->data[nbr_appts].booked_by_id     = SEA.ACTION_PRSNL_ID
      OF Shuffle_cd    : apptinfo->data[nbr_appts].reschedule_dt_tm = SEA.ACTION_DT_TM
      OF Cancel_cd     : apptinfo->data[nbr_appts].cancel_dt_tm     = SEA.ACTION_DT_TM
      OF Reschedule_cd : apptinfo->data[nbr_appts].reschedule_dt_tm = SEA.ACTION_DT_TM
      OF Confirm_cd    : apptinfo->data[nbr_appts].confirm_dt_tm    = SEA.ACTION_DT_TM
      OF Checkin_cd    : apptinfo->data[nbr_appts].checkin_dt_tm    = SEA.ACTION_DT_TM
                         cin         = SEA.ACTION_DT_TM
      OF Checkout_cd   : apptinfo->data[nbr_appts].checkout_dt_tm   = SEA.ACTION_DT_TM
                         cout        = SEA.ACTION_DT_TM
                         Checked_out = 1
   ENDCASE
 
   SCH_EVENT_ID = SA.SCH_EVENT_ID
   OE_FORMAT_ID = SE.OE_FORMAT_ID
 
FOOT SA.RESOURCE_CD
 
   apptinfo->data[nbr_appts].sch_event_id = SCH_EVENT_ID
   apptinfo->data[nbr_appts].oe_format_id = OE_FORMAT_ID
   apptinfo->data[nbr_appts].person_id    = SA2.PERSON_ID
 
   IF (Checked_out = 1)
      apptinfo->data[nbr_appts].wait_time = CNVTSTRING(DATETIMEDIFF(Cout, Cin, 4), 11,0)
   ENDIF
 
   startpos = 1
   apptinfo->data[nbr_appts].Clinic_name = substring(1, size(UAR_GET_CODE_DISPLAY(SE.APPT_TYPE_CD),1)-1
                  ,UAR_GET_CODE_DISPLAY(SE.APPT_TYPE_CD))
 
   apptinfo->data[nbr_appts].Clinic_name = CNVTUPPER( apptinfo->data[nbr_appts].Clinic_name)
   apptinfo->data[nbr_appts].Clinic_name = replace(apptinfo->data[nbr_appts].Clinic_name,"CLINIC","",1)
 
   IF (FINDSTRING("NEW", cnvtupper(UAR_GET_CODE_DISPLAY(SE.APPT_TYPE_CD))) > 0
      OR FINDSTRING("NEW", cnvtupper(UAR_GET_CODE_DISPLAY( Se.APPT_SYNONYM_CD ))) > 0
      OR FINDSTRING("NEW", cnvtupper( Se.APPT_SYNONYM_FREE )) > 0)
      apptinfo->data[nbr_appts].Appt_type   = "NEW"
      apptinfo->data[nbr_appts].Clinic_name = replace(apptinfo->data[nbr_appts].Clinic_name,"NEW","",1)
   ENDIF
 
   IF (FINDSTRING("REVIEW", cnvtupper(UAR_GET_CODE_DISPLAY(SE.APPT_TYPE_CD))) > 0
      OR FINDSTRING("REVIEW", cnvtupper(UAR_GET_CODE_DISPLAY( Se.APPT_SYNONYM_CD ))) > 0
      OR FINDSTRING("REVIEW", cnvtupper( Se.APPT_SYNONYM_FREE )) > 0)
      apptinfo->data[nbr_appts].Appt_type   = "REVIEW"
      apptinfo->data[nbr_appts].Clinic_name = replace(apptinfo->data[nbr_appts].Clinic_name,"REVIEW","",1)
  ENDIF
 
   apptinfo->data[nbr_appts].description = trim(SA.DESCRIPTION)
   apptinfo->data[nbr_appts].appt_date   = SA.BEG_DT_TM
   apptinfo->data[nbr_appts].duration    = SA.DURATION
   apptinfo->data[nbr_appts].resource    = UAR_GET_CODE_DISPLAY( SA.RESOURCE_CD )
   apptinfo->data[nbr_appts].state    = UAR_GET_CODE_DISPLAY(SA.SCH_STATE_CD)
   apptinfo->data[nbr_appts].Reason   = "&"
   apptinfo->data[nbr_appts].Ref_dr   = "&"
 
   prev_resource_cd = SA.RESOURCE_CD
   prev_schedule_id = SA.SCHEDULE_ID
 
FOOT SA.SCHEDULE_ID
 
   IF (SA.SCHEDULE_ID != prev_schedule_id OR SA.RESOURCE_CD != prev_resource_cd)
 
      apptinfo->data[nbr_appts].sch_event_id = SCH_EVENT_ID
      apptinfo->data[nbr_appts].oe_format_id = OE_FORMAT_ID
      apptinfo->data[nbr_appts].person_id    = SA2.PERSON_ID
 
      IF (Checked_out = 1)
         apptinfo->data[nbr_appts].wait_time = CNVTSTRING(DATETIMEDIFF(Cout, Cin, 4), 11,0)
      ENDIF
 
      startpos = 1
      apptinfo->data[nbr_appts].Clinic_name = substring(1, size(UAR_GET_CODE_DISPLAY(SE.APPT_TYPE_CD),1)-1
                     ,UAR_GET_CODE_DISPLAY(SE.APPT_TYPE_CD))
 
      apptinfo->data[nbr_appts].Clinic_name = CNVTUPPER( apptinfo->data[nbr_appts].Clinic_name)
      apptinfo->data[nbr_appts].Clinic_name = replace(apptinfo->data[nbr_appts].Clinic_name,"CLINIC","",1)
 
      IF (FINDSTRING("NEW", cnvtupper(UAR_GET_CODE_DISPLAY(SE.APPT_TYPE_CD))) > 0
         OR FINDSTRING("NEW", cnvtupper(UAR_GET_CODE_DISPLAY( Se.APPT_SYNONYM_CD ))) > 0
         OR FINDSTRING("NEW", cnvtupper( Se.APPT_SYNONYM_FREE )) > 0)
         apptinfo->data[nbr_appts].Appt_type   = "NEW"
         apptinfo->data[nbr_appts].Clinic_name = replace(apptinfo->data[nbr_appts].Clinic_name,"NEW","",1)
      ENDIF
 
      IF (FINDSTRING("REVIEW", cnvtupper(UAR_GET_CODE_DISPLAY(SE.APPT_TYPE_CD))) > 0
         OR FINDSTRING("REVIEW", cnvtupper(UAR_GET_CODE_DISPLAY( Se.APPT_SYNONYM_CD ))) > 0
         OR FINDSTRING("REVIEW", cnvtupper( Se.APPT_SYNONYM_FREE )) > 0)
         apptinfo->data[nbr_appts].Appt_type   = "REVIEW"
         apptinfo->data[nbr_appts].Clinic_name = replace(apptinfo->data[nbr_appts].Clinic_name,"REVIEW","",1)
      ENDIF
 
      apptinfo->data[nbr_appts].description = trim(SA.DESCRIPTION)
      apptinfo->data[nbr_appts].appt_date   = SA.BEG_DT_TM
      apptinfo->data[nbr_appts].duration    = SA.DURATION
      apptinfo->data[nbr_appts].resource    = UAR_GET_CODE_DISPLAY( SA.RESOURCE_CD )
      apptinfo->data[nbr_appts].state    = UAR_GET_CODE_DISPLAY(SA.SCH_STATE_CD)
      apptinfo->data[nbr_appts].Reason   = "&"
      apptinfo->data[nbr_appts].Ref_dr   = "&"
   ENDIF
 
WITH NULLREPORT, COUNTER
 
set size_array = SIZE(apptinfo->data,5)
 
; *******************************
; ***** Prsnl doing booking *****
; *******************************
SELECT INTO "nl:"
 
FROM PRSNL P
  , (DUMMYT D WITH SEQ = VALUE(size_array))
 
PLAN D
 
JOIN P
   WHERE P.PERSON_ID = apptinfo->data[d.seq].booked_by_id
 
DETAIL
   apptinfo->data[d.seq].booked_by_name = P.NAME_FULL_FORMATTED
 
WITH NOCOUNTER
 
 
; ******************************************
; ***** order details for appointments *****
; ******************************************
 
SELECT INTO "nl:"
 
FROM (DUMMYT D WITH SEQ = VALUE(size_array))
  , sCH_EVENT_ATTACH   SEA
  , ORDERS             O
  , ORDER_DETAIL       OD
  , SCH_ORDER_DURATION SOD
  , OE_FORMAT_FIELDS   OEF
 
PLAN D
 
JOIN SEA
   WHERE SEA.SCH_EVENT_ID   = apptinfo->data[d.seq].sch_event_id
   AND   SEA.ACTIVE_IND     = 1
   AND   SEA.VERSION_DT_TM >= cnvtdatetime("31-DEC-2100 00:00:00:00")
 
JOIN O
   WHERE SEA.ORDER_ID  = O.ORDER_ID
 
JOIN OD
   WHERE O.ORDER_ID = OD.ORDER_ID
 
JOIN SOD
   WHERE O.CATALOG_CD       = SOD.CATALOG_CD
   AND   SOD.DURATION_UNITS > 0
 
JOIN OEF
   WHERE OD.OE_FIELD_ID = OEF.OE_FIELD_ID
     and O.OE_FORMAT_ID = OEF.OE_FORMAT_ID
 
ORDER SEA.SCH_EVENT_ID, O.ORDER_ID
 
HEAD SEA.SCH_EVENT_ID
 
   Onum = 0
 
HEAD O.ORDER_ID
 
   Onum = Onum + 1
 
DETAIL
 
   apptinfo->data[d.seq]->Odet[Onum].ord_Name     = SEA.DESCRIPTION
   apptinfo->data[d.seq]->Odet[Onum].ord_duration = cnvtstring(SOD.DURATION_UNITS)
 
   CASE (CNVTUPPER(oef.label_text))
      OF "CONTACT TYPE"         :
          apptinfo->data[d.seq]->Odet[Onum].ODetail1 = OD.OE_FIELD_DISPLAY_VALUE
      OF "SERVICE MEDIUM"       :
          apptinfo->data[d.seq]->Odet[Onum].ODetail2 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "SERVICE LOCATION"     :
  	      apptinfo->data[d.seq]->Odet[Onum].ODetail3 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "NO. PROVIDING SERVICE":
  	      apptinfo->data[d.seq]->Odet[Onum].ODetail4 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "NO. RECEIVING SERVICE":
  	      apptinfo->data[d.seq]->Odet[Onum].ODetail5 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "SERVICE RECIPIENT"    :
  	      apptinfo->data[d.seq]->Odet[Onum].ODetail6 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "RESEARCH"             :
  	      apptinfo->data[d.seq]->Odet[Onum].ODetail7 = OD.OE_FIELD_DISPLAY_VALUE
   ENDCASE
 
WITH NOCOUNTER
 
; ***************************************************
; ***** Schedule event details for appointments *****
; ***************************************************
 
; why dummyt, take it out for testing purposes
 
SELECT INTO "nl:"
    oe_id   = decode(sed.seq, SED.OE_FIELD_ID, 0.0)
  , seq_nbr = decode(sed.seq, SED.SEQ_NBR, -1)
 
FROM
    SCH_EVENT_DETAIL SED
  , (DUMMYT D WITH SEQ = VALUE(size_array))
;  , DUMMYT           D1
  , OE_FORMAT_FIELDS OEF
 
PLAN D
 
JOIN SED
   WHERE SED.SCH_EVENT_ID   = apptinfo->data[d.seq].sch_event_id
   AND   SED.ACTIVE_IND     = 1
   AND   SED.VERSION_DT_TM >= cnvtdatetime("31-DEC-2100 00:00:00:00")
 
;JOIN D1
 
JOIN OEF
   WHERE OEF.OE_FORMAT_ID = apptinfo->data[d.seq].OE_FORMAT_ID
     AND OEF.ACTION_TYPE_CD in (3622, 3625)
     and SED.OE_FIELD_ID  = OEF.OE_FIELD_ID
 
 
ORDER BY
    SED.OE_FIELD_ID
  , SED.SEQ_NBR
 
HEAD SED.OE_FIELD_ID
 
   CASE (SED.OE_FIELD_MEANING)
      OF "REASONFOREXAM":
         IF (substring(1,1,apptinfo->data[d.seq].reason) = "&")
            apptinfo->data[d.seq].Reason = SED.OE_FIELD_DISPLAY_VALUE
         ENDIF
      OF "REFERPHYS"    :
         IF (substring(1,1, apptinfo->data[d.seq].ref_dr) = "&")
            apptinfo->data[d.seq].Ref_dr = SED.OE_FIELD_DISPLAY_VALUE
         ENDIF
   ENDCASE
 
DETAIL
   IF (seq_nbr >= 0)
      CASE (CNVTUPPER(OEF.LABEL_TEXT))
         OF "IS THIS AN EMERGENCY APPT, APPROVED BY THE DOCTOR?" :
             apptinfo->data[d.seq].EDetail1 = SED.OE_FIELD_DISPLAY_VALUE
         OF "SELECT LOCATION:"  :
             apptinfo->data[d.seq].EDetail2 = SED.OE_FIELD_DISPLAY_VALUE
         OF "SELECT TEAM:"      :
             apptinfo->data[d.seq].EDetail3 = SED.OE_FIELD_DISPLAY_VALUE
         OF "SELECT CLINICIAN/S (CLICK THE * BUTTON TO SELECT MULTIPLES):" :
             apptinfo->data[d.seq].EDetail4 = SED.OE_FIELD_DISPLAY_VALUE
         OF "CMI CLIENT NUMBER:":
             apptinfo->data[d.seq].EDetail5 = SED.OE_FIELD_DISPLAY_VALUE
         OF "APC SERVICE PROVIDED" :   apptinfo->data[d.seq].SRVC_PROVIDED = SED.OE_FIELD_DISPLAY_VALUE
         OF "APC SERVICE LOCATION" :   apptinfo->data[d.seq].SRVC_LOC = SED.OE_FIELD_DISPLAY_VALUE
      ENDCASE
   ENDIF
 
WITH NOCOUNTER ;,
;     OUTERJOIN = D1
 
; *********************************************
; ***** Get order details non-appointment *****
; ***** related AP orders such as phone   *****
; ***** contacts                          *****
; *********************************************
 
SELECT DISTINCT INTO "nl:"
 
FROM
    ORDERS             O
  ,	ORDER_DETAIL       OD
  , OE_FORMAT_FIELDS   OEF
  , SCH_ORDER_DURATION SOD
 
PLAN O
   WHERE O.CURRENT_START_DT_TM >= cnvtdatetime(start_date,000000)
   AND   O.CURRENT_START_DT_TM <= cnvtdatetime(end_date,235959)
   AND   O.ACTIVE_IND           = 1
   AND   O.ORDER_MNEMONIC       = "AP *"
   AND   O.ORDER_MNEMONIC      != "APS *"
 
 
JOIN OD
   WHERE O.ORDER_ID = OD.ORDER_ID
 
JOIN SOD
   WHERE O.CATALOG_CD       = SOD.CATALOG_CD
   AND   SOD.DURATION_UNITS > 0
 
JOIN OEF
   WHERE OD.OE_FIELD_ID = OEF.OE_FIELD_ID
   AND   O.OE_FORMAT_ID = OEF.OE_FORMAT_ID
 
ORDER O.ORDER_ID
 
HEAD O.ORDER_ID
 
   nbr_appts = nbr_appts + 1
 
   IF ((MOD(nbr_appts,10) = 1) AND (nbr_appts != 1))
      STAT = ALTERLIST(apptinfo->data,nbr_appts + 9)
   ENDIF
 
DETAIL
 
;  Note: the change of AP to APS is to cater for a substring command when printing
 
   apptinfo->data[nbr_appts]->Odet[1].ord_Name     = replace(O.ORDER_MNEMONIC,"AP ","APS ")
   apptinfo->data[nbr_appts]->Odet[1].ord_duration = cnvtstring(SOD.DURATION_UNITS)
   apptinfo->data[nbr_appts]->Odet[1].order_id     = O.ORDER_ID
   apptinfo->data[nbr_appts].appt_date             = O.CURRENT_START_DT_TM
   apptinfo->data[nbr_appts].person_id             = O.PERSON_ID
 
   CASE (CNVTUPPER(OEF.LABEL_TEXT))
      OF "*CONTACT TYPE"         :
          apptinfo->data[nbr_appts]->Odet[1].ODetail1 = OD.OE_FIELD_DISPLAY_VALUE
      OF "*SERVICE MEDIUM"       :
          apptinfo->data[nbr_appts]->Odet[1].ODetail2 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "*SERVICE LOCATION"     :
  	      apptinfo->data[nbr_appts]->Odet[1].ODetail3 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "*NO. PROVIDING SERVICE":
  	      apptinfo->data[nbr_appts]->Odet[1].ODetail4 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "*NO. RECEIVING SERVICE":
  	      apptinfo->data[nbr_appts]->Odet[1].ODetail5 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "*SERVICE RECIPIENT"    :
  	      apptinfo->data[nbr_appts]->Odet[1].ODetail6 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "*RESEARCH"             :
  	      apptinfo->data[nbr_appts]->Odet[1].ODetail7 = OD.OE_FIELD_DISPLAY_VALUE
  	  OF "DURATION"      :
  	      apptinfo->data[nbr_appts]->Actual_Duration  = cnvtint(OD.OE_FIELD_DISPLAY_VALUE)
  	  OF "SELECT LOCATION"     :
  	      apptinfo->data[nbr_appts].EDetail2          = OD.OE_FIELD_DISPLAY_VALUE
      OF "SELECT TEAM:"         :
          apptinfo->data[nbr_appts].EDetail3          = OD.OE_FIELD_DISPLAY_VALUE
      OF "SELECT CLINICIAN*" :
          apptinfo->data[nbr_appts].EDetail4          = OD.OE_FIELD_DISPLAY_VALUE
          apptinfo->data[nbr_appts].resource          = OD.OE_FIELD_DISPLAY_VALUE
   ENDCASE
foot report
 STAT = ALTERLIST(apptinfo->data,nbr_appts)
 
WITH NOCOUNTER
 
set size_array = SIZE(apptinfo->data,5)
 
; Get person demographics and produce the extract
 
SELECT INTO VALUE(output_loc)
    persid = apptinfo->data[d.seq].person_id
FROM
   (DUMMYT D WITH SEQ = VALUE(size_array))
 ,  PERSON       P
 ,  PERSON_ALIAS PA
 ,  PERSON_NAME  PN
 ,  ADDRESS      A
 
PLAN D
 
join p
   where P.PERSON_ID    = apptinfo->data[d.seq].person_id
 
JOIN Pn
 
   WHERE P.PERSON_ID    = pn.person_id
   AND   PN.NAME_TYPE_CD = curr_name_cd
   AND   PN.ACTIVE_IND   = 1
   and pn.end_effective_dt_tm > cnvtdatetime(curdate,curtime)
 
JOIN PA
   WHERE Pn.PERSON_ID             = Pa.PERSON_ID
     and pa.person_alias_type_cd = 69 ;mrn
  ; AND   PA.ALIAS_POOL_CD IN (alf_mrn_cd, sdmh_mrn_cd, cgmc_mrn_cd)
     AND PA.END_EFFECTIVE_DT_TM >= SYSDATE;cnvtdatetime("31-dec-2100 00:00:00.00")
     AND PA.ACTIVE_IND           = 1
 
JOIN A
   WHERE Pa.PERSON_ID  = A.PARENT_ENTITY_ID
     AND A.PARENT_ENTITY_NAME = "PERSON"
     AND A.ADDRESS_TYPE_CD    = home_addr_cd
     and a.address_type_seq   = 1
     and A.ACTIVE_IND         = 1
 
 
 
;head persid
 detail
   apptinfo->data[d.seq].patient     = P.NAME_FULL_FORMATTED
   apptinfo->data[d.seq].addr1       = trim(A.STREET_ADDR)
   apptinfo->data[d.seq].addr2       = trim(A.STREET_ADDR2)
   apptinfo->data[d.seq].city        = trim(A.CITY)
   apptinfo->data[d.seq].pcode       = trim(A.ZIPCODE)
   apptinfo->data[d.seq].birth_dt_tm = P.BIRTH_DT_TM
   apptinfo->data[d.seq].sex         = UAR_GET_CODE_DISPLAY(P.SEX_CD)
   apptinfo->data[d.seq].title       = substring(1,6,PN.NAME_PREFIX)
 
 
   CASE (PA.ALIAS_POOL_CD)
      OF ah_mrn_cd   : apptinfo->data[d.seq].AH_MRN   = FORMAT(PA.ALIAS, "#######;P0")
      OF alf_mrn_cd  : apptinfo->data[d.seq].ALF_MRN  = FORMAT(PA.ALIAS, "#######;P0")
      OF cgmc_mrn_cd : apptinfo->data[d.seq].CGMC_MRN = FORMAT(PA.ALIAS, "#######;P0")
      OF sdmh_mrn_cd :
         IF  (UAR_GET_CODE_DISPLAY(P.SPECIES_CD ) = "S")
             apptinfo->data[d.seq].SDMH_MRN = format(PA.ALIAS,"######;P0")
         ELSE
             apptinfo->data[d.seq].SDMH_MRN = format(PA.ALIAS,"#######;P0")
         ENDIF
   ENDCASE
 
FOOT REPORT
 
   Long_display_str = BUILD("Clinic"
                   , delim, "Appt_type"
                   , delim, "Slot Type"
                   , delim, "Appt Date"
                   , delim, "Appt Time"
                   , delim, "Appt Yr-Month"
                   , delim, "Duration(mins)"
                   , delim, "Duration (hours)"
                   , delim, "Resource"
                   , delim, "Appt Status"
                   , delim, "Patient name"
                   , delim, "Sex"
                   , delim, "ALF MRN"
                   , delim, "CGMC MRN"
                   , delim, "SDMH MRN"
                   , delim, "Booked date"
                   , delim, "Reschedule date"
                   , delim, "Confirm Date"
                   , delim, "Cancelled date"
                   , delim, "Cancellation Reason"
                   , delim, "Checkin Date"
                   , delim, "Checkout date"
                   , delim, "Clinic wait time (mins)"
                   , delim, "Is this an Emergency Appt, approved by the doctor?"
                   , delim, "Select Location:"
                   , delim, "Select Team:"
                   , delim, "Select Clinician/s"
                   , delim, "CMI Client Number"
                   , delim, "DOB"
                   , delim, "Age"
                   , delim, "Addr_line1"
                   , delim, "Addr_line2"
                   , delim, "Suburb"
                   , delim, "Postcode"
                   , delim, "Booked by"
                   , delim, "Title"
                   , delim, "Order Name"
                   , delim, "Contact Type"
                   , delim, "Service Medium"
                   , delim, "Service Location"
                   , delim, "No Proving"
                   , delim, "No Receiving"
                   , delim, "Service Recipients"
                   , delim, "Research"
                   , delim, "Order Duration(mins)"
                   , delim, "Actual Duration"
                   , DELIM,	"Service Provided"
                   , delim,	"Service Location")
 
 /* COMMENTED FOR CHANGES DONE FOR 008 *
	if(newPAS = "YES")
		long_display_str = build(long_display_str,delim,"AH MRN")
	endif
  --------------------------*/
 
  Col 0 long_display_str
  Row + 1
 
  FOR (i = 1 to nbr_appts )
 
     age = CNVTINT(SUBSTRING(1,4, trim(CNVTAGE(apptinfo->data[i].birth_dt_tm))))
 
     IF (substring(1,1,apptinfo->data[i].reason) = "&")
        apptinfo->data[i].reason = ""
     ENDIF
 
     IF (substring(1,1, apptinfo->data[i].ref_dr) = "&")
        apptinfo->data[i].Ref_dr = ""
     ENDIF
 
 	/* CHANGES FOR 008 */
 	 if(newPAS = "YES")
 	 	apptinfo->data[i].ALF_MRN = apptinfo->data[i].AH_MRN
 	 ENDIF
 	 /* CHANGES FOR 008 */
 
     Long_display_str = BUILD(trim(apptinfo->data[i].Clinic_name)
                     , delim, trim(apptinfo->data[i].Appt_type)
                     , delim, trim(apptinfo->data[i].description)
                     , delim, format(apptinfo->data[i].appt_date,"dd/mmm/yyyy;;D")
                     , delim, format(apptinfo->data[i].appt_date,"HH:MM;;D")
                     , delim, format(apptinfo->data[i].appt_date,"yyyy-mm;;D")
                     , delim, apptinfo->data[i].duration
                     , delim, format(CNVTREAL(apptinfo->data[i].duration)/60.0, "######.#;;F")
                     , delim, trim(apptinfo->data[i].resource)
                     , delim, trim(apptinfo->data[i].state)
                     , delim, trim(apptinfo->data[i].patient)
                     , delim, trim(apptinfo->data[i].SEX)
                     , delim, trim(apptinfo->data[i].ALF_MRN)
                     , delim, trim(apptinfo->data[i].CGMC_MRN)
                     , delim, trim(apptinfo->data[i].SDMH_MRN)
                     , delim, format(apptinfo->data[i].Book_dt_tm,"dd/mmm/yyyy HH:MM;;D")
                     , delim, format(apptinfo->data[i].Reschedule_dt_tm,"dd/mmm/yyyy HH:MM;;D")
                     , delim, format(apptinfo->data[i].Confirm_dt_tm,"dd/mmm/yyyy HH:MM;;D")
                     , delim, format(apptinfo->data[i].cancel_dt_tm,"dd/mmm/yyyy HH:MM;;D")
                     , delim, trim(apptinfo->data[i].Cancel_Reason)
                     , delim, format(apptinfo->data[i].checkin_dt_tm,"dd/mmm/yyyy HH:MM;;D")
                     , delim, format(apptinfo->data[i].checkout_dt_tm,"dd/mmm/yyyy HH:MM;;D")
                     , delim, CNVTSTRING(DATETIMEDIFF(apptinfo->data[i].checkout_dt_tm, apptinfo->data[i].checkin_dt_tm, 4), 11,0)
                     , delim, trim(apptinfo->data[i].EDetail1)
                     , delim, trim(apptinfo->data[i].EDetail2)
                     , delim, trim(apptinfo->data[i].EDetail3)
                     , delim, trim(apptinfo->data[i].EDetail4)
                     , delim, trim(apptinfo->data[i].EDetail5)
                     , delim, format(apptinfo->data[i].BIRTH_DT_TM, "dd/mm/yyyy;;D")
                     , delim, age
                     , delim, trim(apptinfo->data[i].ADDR1)
                     , delim, trim(apptinfo->data[i].ADDR2)
                     , delim, trim(apptinfo->data[i].CITY)
                     , delim, trim(apptinfo->data[i].pcode)
                     , delim, trim(apptinfo->data[i].booked_by_name)
                     , delim, trim(apptinfo->data[i].title))
  Long_display_str1 = BUILD(Long_display_str
    , delim, trim(substring(5,size(apptinfo->data[i]->Odet[1].Ord_name,1)-4,apptinfo->data[i]->Odet[1].Ord_name))
    , delim, trim(apptinfo->data[i]->Odet[1].ODetail1 )
    , delim, trim(apptinfo->data[i]->Odet[1].ODetail2 )
    , delim, trim(apptinfo->data[i]->Odet[1].ODetail3 )
    , delim, trim(apptinfo->data[i]->Odet[1].ODetail4 )
    , delim, trim(apptinfo->data[i]->Odet[1].ODetail5 )
    , delim, trim(apptinfo->data[i]->Odet[1].ODetail6 )
    , delim, trim(apptinfo->data[i]->Odet[1].ODetail7 )
    , delim, trim(apptinfo->data[i]->Odet[1].Ord_duration)
    , delim, apptinfo->data[i].Actual_Duration
    , delim, apptinfo->data[i].SRVC_PROVIDED
    , delim, apptinfo->data[i].SRVC_LOC)
 
/* COMMENTED FOR CHANGES DONE FOR 008 *
	if(newPAS = "YES")
		Long_display_str1 = build(Long_display_str1,delim,trim(apptinfo->data[i].AH_MRN))
	endif
  --------------------------------------------*/
     Col 0 Long_display_str1
     Row + 1
 
     FOR (x = 2 TO 40 )
        if (apptinfo->data[i]->Odet[x].Ord_name != "")
			  Long_display_str1 = concat(Long_display_str
              , delim, trim(substring(5,size(apptinfo->data[i]->Odet[x].Ord_name,1)-4,apptinfo->data[i]->Odet[x].Ord_name))
              , delim, trim(apptinfo->data[i]->Odet[x].ODetail1 )
              , delim, trim(apptinfo->data[i]->Odet[x].ODetail2 )
              , delim, trim(apptinfo->data[i]->Odet[x].ODetail3 )
              , delim, trim(apptinfo->data[i]->Odet[x].ODetail4 )
              , delim, trim(apptinfo->data[i]->Odet[x].ODetail5 )
              , delim, trim(apptinfo->data[i]->Odet[x].ODetail6 )
              , delim, trim(apptinfo->data[i]->Odet[x].ODetail7 )
              , delim, trim(apptinfo->data[i]->Odet[x].Ord_duration ) )
 /* COMMENTED FOR CHANGES DONE FOR 008 *
			if(newPAS = "YES")
				Long_display_str1 = build(Long_display_str1,delim,delim,trim(apptinfo->data[i].AH_MRN))
			endif
 --------------------------*/
            Col 0 Long_display_str1
           Row + 1
        endif
     ENDFOR
 
 
  ENDFOR
 
WITH MAXCOL = 2100,
     maxrow = 1,
     TIME   = VALUE( MaxSecs ),
     NULLREPORT,
     NOHEADING,
     FORMAT    = VARIABLE,
     FORMFEED  = NONE
 
;IF   (CNVTDATE($2,E) = CNVTDATE("31122100",E)
;   or CNVTDATE($2,E) = CNVTDATE("25122100",E)
;   or CNVTDATE($2,E) = CNVTDATE("26122100",E)
;   or CNVTDATE($2,E) = CNVTDATE("27122100",E))
 
;   SET temp_file_name = BUILD("CCL_FTP_CERDATA", FORMAT(CURDATE, "DDMMYY;;D"), FORMAT(CURTIME, "HHMM;;M"),".ftp")
;
;   SELECT INTO VALUE(temp_file_name)
;   FROM DUMMYT D
;
;   DETAIL
;      putstr = CONCAT("Put ", VALUE(output_loc), " ",VALUE(dest_path), TRIM(output_loc))
;      col 1 putstr
;      Row + 1
;      Col 1 "Close"
;      Row + 1
;      COl 1 "bye"
;      Row + 1
;   WITH NOCOUNT
;
;;  Note THE QUOTES - THE SUBMITTED FILE NAME HAS A . IN IT SO NEEDS TO BE ENCLOSED IN DOUBLE QUOTES
;
;   SET dclcom = CONCAT('@bayh_ftpcerdata "', value(temp_file_name),'"')
;   SET len    = SIZE(TRIM(dclcom))
;   SET status = 0
;
;   CALL dcl(dclcom, len, status)
 
/* New code for Linux */
if (ftptrue = 1)
       declare dclcom = vc with noconstant("")
 
       set dclcom = concat("$cust_proc/bayh_ftpcerdata.ksh ",
                           value(ftp_filename),
                           " 7.184.180.102 ftpUSER ftpUSER1911 ",
                           ftp_pathname)
       set status = 0
       set len = size(trim(dclcom))
       call echo(dclcom)
       call dcl(dclcom, len, status)
 
ENDIF
 
END
GO
