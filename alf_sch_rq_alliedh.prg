/**********************************************************************************************************************
#m     Module                 :     SurgiNet
***********************************************************************************************************************
#n     Program Common Name    :     alf_sch_rq_alliedh.prg
#n     Program Object Name    :     alf_sch_rq_alliedh
#n     Program Run From       :     Scheduler - Request List
***********************************************************************************************************************
#d     Description            :     This program generates the CGMC Allied Health Request List
#d
#d     Categories             :
************************************************************************************************************************
#a     Site                   :     Alfred Healthcare Group
                                    Commercial Road, Melbourne
                                    Victoria, 3004
                                    Australia
************************************************************************************************************************
#t     Tables                 :
************************************************************************************************************************
#v     Version                :     Cerner Command Language Version 7.8
************************************************************************************************************************
#m     Modification Control Log
************************************************************************************************************************
#m     Mod #     By                 Date            Description
       -----     ----------------   --------------  --------------------------------------------------------------------
                 John Everts        03/11/2011      Initial Release based on alf_sch_rq_cgarl1
       001       John Everts        21/11/2011      Add Referral Type column
       002       John Everts        30/11/2011      Add Financial Class and Priority columns
       003       John Everts        27/04/2012      Add Additional Referral Information, Review in Clinic and Date
                                                    Referral Received Columns
       004       Phuong Pham        01/06/2012      Add Clinical Urgency column.
       005       John Everts        18/06/2012      Fixed typo that had stopped the select of order details.
       006       John Everts        04/12/2012      Changed column heading from Additional Referral Info to Clinical
                                                    Notes and Request
	   007		 Steven White		31/08/2015		Added Disability Column
	   008		 Karel Young 		04/05/2016		Added Sinlge MRN Logic
	   009		 Mandeep Singh		03/02/2017		Added check for mobile numbers
	   010		 Arun Gupta			24/10/2017		Service Request: 38248 , Added Current Location and Discharge for
	   												Podiatry (Alfred) Request List
	   011		 Mandeep Singh		27/11/2017		Service Request: 38400 	- Added "MAPT Score" from OP OAHKS powerform
	   																		- Added "MAPT Received Date" from OP OAHKS powerform
************************************************************************************************************************/
 
DROP   PROGRAM alf_sch_rq_alliedh: DBA GO
CREATE PROGRAM alf_sch_rq_alliedh: DBA
 
SET FALSE                = 0
SET TRUE                 = 1
SET GEN_NBR_ERROR        = 3
SET INSERT_ERROR         = 4
SET UPDATE_ERROR         = 5
SET REPLACE_ERROR        = 6
SET DELETE_ERROR         = 7
SET UNDELETE_ERROR       = 8
SET REMOVE_ERROR         = 9
SET ATTRIBUTE_ERROR      = 10
SET LOCK_ERROR           = 11
SET NONE_FOUND           = 12
SET SELECT_ERROR         = 13
SET UPDATE_CNT_ERROR     = 14
SET NOT_FOUND            = 15
SET VERSION_INSERT_ERROR = 16
SET INACTIVATE_ERROR     = 17
SET ACTIVATE_ERROR       = 18
SET VERSION_DELETE_ERROR = 19
SET UAR_ERROR            = 20
SET FAILED               = FALSE
SET TABLE_NAME           = FILLSTRING ( 50 ,  " " )
SET CALL_ECHO_IND        = FALSE
SET I_VERSION            = 0
SET PROGRAM_NAME         = FILLSTRING ( 30 ,  " " )
SET SCH_SECURITY_ID      = 0.0
 
IF ((VALIDATE(SCHUAR_DEF,  999) = 999))
  CALL ECHO("Declaring schuar_def")
  DECLARE  SCHUAR_DEF = I2 WITH PERSIST
  SET      SCHUAR_DEF = 1
  DECLARE  UAR_SCH_CHECK_SECURITY (( SEC_TYPE_CD = F8 ( REF ))
                                 , ( PARENT1_ID  = F8 ( REF ))
                                 , ( PARENT2_ID  = F8 ( REF ))
                                 , ( PARENT3_ID  = F8 ( REF ))
                                 , ( SEC_ID      = F8 ( REF ))
                                 , ( USER_ID     = F8 ( REF))
                                  ) =  I4  WITH  IMAGE_AXP = "shrschuar"
                                               , IMAGE_AIX = "libshrschuar.a(libshrschuar.o)"
                                               , UAR       = "uar_sch_check_security"
                                               , PERSIST
  DECLARE  UAR_SCH_SECURITY_INSERT (( USER_ID     = F8 ( REF ))
                                  , ( SEC_TYPE_CD = F8 ( REF ))
                                  , ( PARENT1_ID  = F8 ( REF ))
                                  , ( PARENT2_ID  = F8 ( REF ))
                                  , ( PARENT3_ID  = F8 ( REF ))
                                  , ( SEC_ID      = F8 ( REF ))
                                   ) =  I4  WITH  IMAGE_AXP = "shrschuar"
                                                , IMAGE_AIX = "libshrschuar.a(libshrschuar.o)"
                                                , UAR       = "uar_sch_security_insert"
                                                , PERSIST
  DECLARE  UAR_SCH_SECURITY_PERFORM () =  I4  WITH  IMAGE_AXP = "shrschuar"
                                                  , IMAGE_AIX = "libshrschuar.a(libshrschuar.o)"
                                                  , UAR       = "uar_sch_security_perform"
                                                  , PERSIST
  DECLARE  UAR_SCH_CHECK_SECURITY_EX (( USER_ID     = F8 ( REF ))
                                    , ( SEC_TYPE_CD = F8 ( REF ))
                                    , ( PARENT1_ID  = F8 ( REF ))
                                    , ( PARENT2_ID  = F8 ( REF ))
                                    , ( PARENT3_ID  = F8 ( REF ))
                                    , ( SEC_ID      = F8 ( REF ))
                                     ) =  I4  WITH  IMAGE_AXP = "shrschuar"
                                                  , IMAGE_AIX = "libshrschuar.a(libshrschuar.o)"
                                                  , UAR       = "uar_sch_check_security_ex"
                                                  , PERSIST
ENDIF
 
SET SCH_I18N_CD      = 0.0
SET SCH_I18N_MEANING = FILLSTRING(12 ," ")
SET SCH_I18N_MEANING = "I18NSCRIPTS"
SET STAT             = UAR_GET_MEANING_BY_CODESET(16127, SCH_I18N_MEANING, 1, SCH_I18N_CD)
 
CALL ECHO (BUILD("UAR_GET_MEANING_BY_CODESET(16127,",SCH_I18N_MEANING,",1,",SCH_I18N_CD,")"))
 
IF ((STAT = 0) AND (SCH_I18N_CD > 0))
  DECLARE  UAR_I18NLOCALIZATIONINIT (( P1 = I4 ), ( P2 = VC ), ( P3 = VC ), ( P4 = F8 )) =  I4
  DECLARE  UAR_I18NGETMESSAGE (( P1 = I4 ), ( P2 = VC ), ( P3 = VC )) =  VC
  DECLARE  UAR_I18NBUILDMESSAGE () =  VC
 
  IF ((VALIDATE(I18NUAR_DEF, 999) = 999))
    CALL ECHO("Declaring i18nuar_def")
    DECLARE  I18NUAR_DEF = I2 WITH PERSIST
    SET      I18NUAR_DEF = 1
    DECLARE  UAR_I18NGETHIJRIDATE (( IMONTH          = I2 ( VAL ))
                                 , ( IDAY            = I2 ( VAL ))
                                 , ( IYEAR           = I2 ( VAL ))
                                 , ( SDATEFORMATTYPE = VC ( REF ))
                                  ) =  C50  WITH  IMAGE_AXP = "shri18nuar"
                                                , IMAGE_AIX = "libi18n_locale.a(libi18n_locale.o)"
                                                , UAR       = "uar_i18nGetHijriDate"
                                                , PERSIST
    DECLARE  UAR_I18NBUILDFULLFORMATNAME (( SFIRST    = VC ( REF ))
                                        , ( SLAST     = VC ( REF ))
                                        , ( SMIDDLE   = VC ( REF ))
                                        , ( SDEGREE   = VC ( REF ))
                                        , ( STITLE    = VC ( REF ))
                                        , ( SPREFIX   = VC ( REF ))
                                        , ( SSUFFIX   = VC ( REF ))
                                        , ( SINITIALS = VC ( REF ))
                                        , ( SORIGINAL = VC ( REF ))
                                         ) = C250 WITH IMAGE_AXP = "shri18nuar"
                                                     , IMAGE_AIX = "libi18n_locale.a(libi18n_locale.o)"
                                                     , UAR       = "i18nBuildFullFormatName"
                                                     , PERSIST
  ENDIF
 
  SET I18NHANDLE = 0
  SET STAT       = UAR_I18NLOCALIZATIONINIT (I18NHANDLE,CURPROG,"",CURCCLREV)
  CALL ECHO(BUILD("UAR_I18NLOCALIZATIONINIT(",I18NHANDLE,",",CURPROG,",",CHAR(34),CHAR(34),",",CURCCLREV,")"))
ELSE
  SET SCH_I18N_CD = 0.0
ENDIF
 
SET TRACE = RECPERSIST
 
RECORD  REPLY
( 1  ATTR_QUAL_CNT = I4
  1  ATTR_QUAL [*]
    2  ATTR_NAME  = C31
    2  ATTR_LABEL = C60
    2  ATTR_TYPE  = C8
  1  QUERY_QUAL_CNT = I4
  1  QUERY_QUAL [*]
    2  HIDE#SCHENTRYID        = F8
    2  HIDE#SCHEVENTID        = F8
    2  HIDE#SCHEDULEID        = F8
    2  HIDE#SCHEDULESEQ       = I4
    2  HIDE#REQACTIONID       = F8
    2  HIDE#ACTIONID          = F8
    2  HIDE#SCHAPPTID         = F8
    2  HIDE#STATEMEANING      = VC
    2  HIDE#EARLIESTDTTM      = DQ8
    2  HIDE#LATESTDTTM        = DQ8
    2  HIDE#REQMADEDTTM       = DQ8
    2  HIDE#ENTRYSTATEMEANING = C12
    2  HIDE#REQACTIONMEANING  = C12
    2  HIDE#ENCOUNTERID       = F8
    2  HIDE#PERSONID          = F8
    2  HIDE#BITMASK           = I4
    2  HIDE#FORMATID          = F8
    2  HIDE#REFUNIT           = F8
    2  HIDE#REASONVISIT       = F8
    2  Earliest_dt_tm         = DQ8
    2  Patient_Ward           = VC
    2  Referring_Unit         = VC
    2  Referring_Ward         = VC
    2  Appt_Type_display      = VC
    2  Person_Name            = VC
    2  MRN 					  = VC
    2  Date_Birth             = VC
    2  Referral_Received_From = VC
    2  Referring_Agency       = VC
    2  Urgency_of_referral    = VC
    2  Reason_for_Referral    = VC
    2  Referral_type          = VC
    2  Diagnosis              = VC
    2  Request_Date           = DQ8
    2  Phone                  = VC
    2  Prsnl_name             = VC
    2  Discharge_Date         = DQ8
    2  Address                = VC
    2  Req_action_display     = VC
    2  Potential_Service      = VC
    2  Comments               = VC
    2  Fin_Class              = VC
    2  Priority               = VC
    2  Additional_info        = VC
    2  Review_in_Clinic       = VC
	2  Disability			  = VC ;007 Addition
    2  Clinical_Urgency       = VC
    2  Referral_Received_Date = DQ8
 
    2  Location				  = VC ; 010 Addition
    2  Discharge_Status 	  = VC ; 010 Addition
    2  MAPT_Score			  = f8 ; mod#011
    2  MAPT_Rcvd_Date		  = dq8 ; mod#011
 
  1  STATUS_DATA
    2  STATUS = C1
    2  SUBEVENTSTATUS[1]
      3  OPERATIONNAME     = C25
      3  OPERATIONSTATUS   = C1
      3  TARGETOBJECTNAME  = C25
      3  TARGETOBJECTVALUE = VC
)
 
SET TRACE = NORECPERSIST
 
SET REPLY->ATTR_QUAL_CNT = 47 ;007 - Incremented by 1 , 010 - Increment by 2, mod#011 - Incemented by 2
SET T_INDEX              = 0
SET STAT                 = ALTERLIST(REPLY->ATTR_QUAL,  REPLY->ATTR_QUAL_CNT)
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#schentryid"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#SCHENTRYID"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "f8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#scheventid"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#SCHEVENTID"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "f8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#scheduleid"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#SCHEDULEID"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "f8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#scheduleseq"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#SCHEDULESEQ"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "i4"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#reqactionid"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#REQACTIONID"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "f8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#actionid"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#ACTIONID"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "f8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#schapptid"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#SCHAPPTID"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "f8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#statemeaning"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#STATEMEANING"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#earliestdttm"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#EARLIESTDTTM"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "dq8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#latestdttm"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#LATESTDTTM"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "dq8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#reqmadedttm"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#REQMADEDTTM"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "dq8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#entrystatemeaning"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#ENTRYSTATEMEANING"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#reqactionmeaning"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#REQACTIONMEANING"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#encounterid"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#ENCOUNTERID"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "f8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#personid"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#PERSONID"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "f8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#bitmask"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#BITMASK"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "i4"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#formatid"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#FORMATID"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "F8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#refunit"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#REFUNIT"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "F8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "hide#reasonvisit"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "HIDE#REASONVISIT"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "F8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Request_Date"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Request Date"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "DQ8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Prsnl_name"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Prsnl"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "VC"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "MRN"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "MRN"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "VC"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "person_name"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Person Name"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Date_Birth"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Date of Birth"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Address"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Address"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Phone"
;mod#009 - begin
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Home/Mob/Bus Phone"
;mod#009 - end
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Appt_Type_Display"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Referral Name"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Referral_Received_From"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Referral Received From"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Referring_Agency"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Agency"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Urgency_of_Referral"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Urgency of Referral"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Reason_for_Referral"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Reason for Referral"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Referral_Type"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Referral Type"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Diagnosis"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Diagnosis"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
/*
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Discharge_Date"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Discharge Date"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "DQ8"
*/
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Req_action_display"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Action"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Referring_Unit"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Referring Unit"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
/*
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Referring_Ward"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Referring Ward"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Potential_Service"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Potential Service"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
*/
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Comments"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Comments"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Fin_class"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Fin Class"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Priority"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Priority"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Referral_Received_Date"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Date Referral Received"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "dq8"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Additional_info"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Clinical Notes and Request"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Review_in_clinic"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Review in Clinic"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Clinical_Urgency"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Clinical Urgency"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Disability" ;007 Addition
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Disability"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Location" ;010 Addition
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Location"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "Discharge_Status" ;010 Addition
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "Discharge Status"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "vc"
 
;mod#011
SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "MAPT_Score"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "MAPT Score"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "f8"

SET T_INDEX = (T_INDEX + 1)
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_NAME  = "MAPT_Rcvd_Date"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_LABEL = "MAPT Received Date"
SET REPLY->ATTR_QUAL[T_INDEX]->ATTR_TYPE  = "dq8"
 
; Put titles in for column headers
 
IF (SCH_I18N_CD > 0.0)
  FOR (I18N = 1 TO REPLY->ATTR_QUAL_CNT)
    IF (NOT((REPLY->ATTR_QUAL[I18N]->ATTR_LABEL IN ("HIDE#*", "DATA#*"))))
      CALL ECHO(BUILD("Before [",I18N,"] UAR_I18NGETMESSAGE(",I18NHANDLE,",",REPLY->ATTR_QUAL[I18N]->ATTR_LABEL))
      SET REPLY->ATTR_QUAL[I18N]->ATTR_LABEL =
                     TRIM(UAR_I18NGETMESSAGE(I18NHANDLE,VALUE(REPLY->ATTR_QUAL[I18N]->ATTR_LABEL)
                                             ,VALUE(REPLY->ATTR_QUAL[I18N]->ATTR_LABEL)))
      CALL ECHO(BUILD("       [",I18N,"] UAR_I18NGETMESSAGE(",I18NHANDLE,",",REPLY->ATTR_QUAL[I18N]->ATTR_LABEL))
    ENDIF
  ENDFOR
ENDIF
 
SET REPLY->QUERY_QUAL_CNT = 0
SET STAT                  = ALTERLIST(REPLY->QUERY_QUAL,  REPLY->QUERY_QUAL_CNT)
 
FREE SET T_RECORD
 
RECORD  T_RECORD
( 1  QUEUE_ID                 = F8
  1  PERSON_ID                = F8
  1  RESOURCE_CD              = F8
  1  LOCATION_CD              = F8
  1  BEG_DT_TM                = DQ8
  1  END_DT_TM                = DQ8
  1  ATGROUP_ID               = F8
  1  LOCGROUP_ID              = F8
  1  RES_GROUP_ID             = F8
  1  APPT_TYPE_CD             = F8
  1  TITLE                    = VC
  1  APPTTYPE_QUAL_CNT        = I4
  1  APPTTYPE_QUAL [*]
    2  APPT_TYPE_CD           = F8
  1  USER_DEFINED             = VC
  1  FORMAT_ID                = F8
  1  ORDER_TYPE_CD            = F8
  1  ORDER_TYPE_MEANING       = C12
  1  PENDING_STATE_CD         = F8
  1  PENDING_STATE_MEANING    = C12
  1  USERDEFINED_TYPE_CD      = F8
  1  USERDEFINED_TYPE_MEANING = C12
  1  TEMP_BEG_DT_TM           = DQ8
  1  TEMP_END_DT_TM           = DQ8
  1  TEMP_ISOLATION_CD        = F8
  1  ORDCOMMENT_CD            = F8
  1  ORDCOMMENT_MEANING       = C12
)
 
CALL ECHO ("Checking the input fields...")
 
FOR (I_INPUT = 1 TO SIZE(REQUEST->QUAL, 5))
  IF (REQUEST->QUAL[I_INPUT]->OE_FIELD_MEANING_ID = 0)
    CASE (REQUEST->QUAL[I_INPUT]->OE_FIELD_MEANING)
    OF "QUEUE"    :SET T_RECORD->QUEUE_ID     = REQUEST->QUAL[I_INPUT]->OE_FIELD_VALUE
    OF "PERSON"   :SET T_RECORD->PERSON_ID    = REQUEST->QUAL[I_INPUT]->OE_FIELD_VALUE
    OF "RESOURCE" :SET T_RECORD->RESOURCE_CD  = REQUEST->QUAL[I_INPUT]->OE_FIELD_VALUE
    OF "LOCATION" :SET T_RECORD->LOCATION_CD  = REQUEST->QUAL[I_INPUT]->OE_FIELD_VALUE
    OF "BEGDTTM"  :SET T_RECORD->BEG_DT_TM    = REQUEST->QUAL[I_INPUT]->OE_FIELD_DT_TM_VALUE
    OF "ENDDTTM"  :SET T_RECORD->END_DT_TM    = REQUEST->QUAL[I_INPUT]->OE_FIELD_DT_TM_VALUE
    OF "ATGROUP"  :SET T_RECORD->ATGROUP_ID   = REQUEST->QUAL[I_INPUT]->OE_FIELD_VALUE
    OF "LOCGROUP" :SET T_RECORD->LOCGROUP_ID  = REQUEST->QUAL[I_INPUT]->OE_FIELD_VALUE
    OF "RESGROUP" :SET T_RECORD->RES_GROUP_ID = REQUEST->QUAL[I_INPUT]->OE_FIELD_VALUE
    OF "TITLE"    :SET T_RECORD->TITLE        = REQUEST->QUAL[I_INPUT]->OE_FIELD_DISPLAY_VALUE
    OF "APPTTYPE" :SET T_RECORD->APPT_TYPE_CD = REQUEST->QUAL[I_INPUT]->OE_FIELD_VALUE
    ENDCASE
  ELSE
    CASE (REQUEST->QUAL[I_INPUT]->LABEL_TEXT)
    OF  "<Label Text Goes Here>" :
       SET T_RECORD->USER_DEFINED = REQUEST->QUAL[I_INPUT]-> OE_FIELD_DISPLAY_VALUE
    ENDCASE
  ENDIF
ENDFOR
 
SET T_RECORD->PENDING_STATE_CD      = 0.0
SET T_RECORD->PENDING_STATE_MEANING = FILLSTRING ( 12 ,  " " )
SET T_RECORD->PENDING_STATE_MEANING = "PENDING"
SET STAT = UAR_GET_MEANING_BY_CODESET(23018,T_RECORD->PENDING_STATE_MEANING,1,T_RECORD->PENDING_STATE_CD)
 
CALL ECHO(BUILD("UAR_GET_MEANING_BY_CODESET(23018,",T_RECORD->PENDING_STATE_MEANING,",1,"
                              ,T_RECORD->PENDING_STATE_CD,")"))
 
IF ((STAT != 0) OR (T_RECORD->PENDING_STATE_CD <= 0))
  IF (CALL_ECHO_IND)
    CALL ECHO (BUILD("stat = " ,  STAT ))
    CALL ECHO (BUILD("t_record->pending_state_cd = " ,  T_RECORD->PENDING_STATE_CD ))
    CALL ECHO (BUILD("Invalid select on CODE_SET (23018), CDF_MEANING(",T_RECORD->PENDING_STATE_MEANING,")"))
  ENDIF
  GO TO  EXIT_SCRIPT
ENDIF
 
SET alf_alias_cd  = uar_get_code_by("DISPLAYKEY", 263, "ALFREDURNUMBERPOOL")
SET sdmh_alias_cd = uar_get_code_by("DISPLAYKEY", 263, "SDMHURNUMBERPOOL")
SET cgmc_alias_cd = uar_get_code_by("DISPLAYKEY", 263, "CGMCURPOOL")
DECLARE newPAS = VC
DECLARE AHU_UR = f8
 
SET newPAS = UAR_GET_DEFINITION(uar_get_code_by("DISPLAYKEY", 101018, "NEWPAS"))
if(newPAS = "YES")
        set AHU_UR = uar_get_code_by("DISPLAYKEY", 263, "ALFREDHEALTH")
else
        set AHU_UR = -1
endif
 
Declare Home_phone_cd     = f8
Declare Business_phone_cd = f8
 
;mod#009 - begin
Declare mob_phone_cd = f8
;mod#009 - end
 
Declare Home_addr_cd      = f8
 
Set Home_phone_cd     = uar_get_code_by("DISPLAYKEY", 43, "HOME")
Set Business_phone_cd = uar_get_code_by("DISPLAYKEY", 43, "BUSINESS")
 
;mod#009 - begin
Set mob_phone_cd = uar_get_code_by("DISPLAYKEY", 43, "MOBILE")
;mod#009 - end
 
Set Home_addr_cd      = uar_get_code_by("DISPLAYKEY", 212,"HOME")
 
; mod#011
declare mapt_score_cd = f8
set 	mapt_score_cd = uar_get_code_by("DISPLAYKEY", 72,"ORTHOOAHKSREFRECSCORE")

declare mapt_rcvd_dt_cd = f8
set 	mapt_rcvd_dt_cd = uar_get_code_by("DISPLAYKEY", 72,"ORTHOOAHKSREFRECDT")
 
declare in_error_cd = f8
set 	in_error_cd = uar_get_code_by("MEANING", 8,"INERROR")
 
 
SELECT INTO  "nl:"
    AD_EXISTS = DECODE (AD.SEQ, 1, 0)
  , L_EXISTS  = DECODE (L.SEQ,  1, 0)
  , A.QUEUE_ID
 
FROM SCH_ENTRY       A
  , SCH_EVENT_ACTION EA
  , SCH_EVENT        E
  , DUMMYT           D5
  , SCH_EVENT_ATTACH SEA
  , PRSNL            PR
  , PERSON           P
  , PERSON_ALIAS     PA
  , DUMMYT           D1
  , SCH_LOCK         L
  , DUMMYT           D2
  , SCH_ACTION_DATE  AD
  , DUMMYT           D3
  , ADDRESS          ADDR
  , DUMMYT           D4
  , PHONE            PH
 
PLAN A
   WHERE A.QUEUE_ID        = T_RECORD->QUEUE_ID
   AND   A.ENTRY_STATE_CD  = T_RECORD->PENDING_STATE_CD
   AND   A.VERSION_DT_TM   = CNVTDATETIME ( "31-DEC-2100 00:00:00.00" )
 
JOIN EA
   WHERE EA.SCH_ACTION_ID = A.SCH_ACTION_ID
   AND   EA.VERSION_DT_TM = CNVTDATETIME ("31-DEC-2100 00:00:00.00" )
 
JOIN E
   WHERE E.SCH_EVENT_ID  = EA.SCH_EVENT_ID
   AND   E.VERSION_DT_TM = CNVTDATETIME ("31-DEC-2100 00:00:00.00" )
 
JOIN PR
   WHERE EA.ACTION_PRSNL_ID = PR.PERSON_ID
 
JOIN P
   WHERE P.PERSON_ID = A.PERSON_ID
 
JOIN PA
   WHERE PA.PERSON_ID            = P.PERSON_ID
   AND   PA.ALIAS_POOL_CD IN (alf_alias_cd, cgmc_alias_cd, sdmh_alias_cd,AHU_UR)
   AND   PA.END_EFFECTIVE_DT_TM >= cnvtdatetime(CURDATE, CURTIME3)
   AND   PA.ACTIVE_IND           = 1
 
JOIN D5
 
JOIN SEA
   WHERE SEA.SCH_EVENT_ID  = E.SCH_EVENT_ID
   AND   SEA.VERSION_DT_TM = CNVTDATETIME ("31-DEC-2100 00:00:00.00" )
JOIN D1
   WHERE D1.SEQ = 1
 
JOIN L
   WHERE L.PARENT_TABLE  = "SCH_EVENT"
   AND   L.PARENT_ID     = A.SCH_EVENT_ID
   AND   L.VERSION_DT_TM = CNVTDATETIME ( "31-DEC-2100 00:00:00.00" )
 
JOIN D2
   WHERE D2.SEQ = 1
 
JOIN AD
   WHERE AD.SCH_ACTION_ID = A.SCH_ACTION_ID
   AND   AD.SCENARIO_NBR  = 1
   AND   AD.SEQ_NBR       = 1
   AND   AD.VERSION_DT_TM = CNVTDATETIME ( "31-DEC-2100 00:00:00.00" )
 
JOIN D3
 
JOIN ADDR
   WHERE ADDR.PARENT_ENTITY_ID   = P.PERSON_ID
   AND   ADDR.ACTIVE_IND         = 1
   AND   ADDR.ADDRESS_TYPE_CD    = Home_addr_cd
   AND   ADDR.parent_entity_name = "PERSON"
   AND   ADDR.address_type_seq   = 1
 
JOIN D4
 
JOIN PH
   WHERE PA.PERSON_ID          = PH.PARENT_ENTITY_ID
   AND   PH.ACTIVE_IND         = 1
   ;mod#009 - begin
   AND   PH.PHONE_TYPE_CD IN (Home_phone_cd, Business_phone_cd, mob_phone_cd)
   ;mod#009 - end
   AND   PH.parent_entity_name = "PERSON"
   AND   PH.phone_type_seq     = 1
 
ORDER BY A.SCH_ACTION_ID  ; A.sch_entry_id
 
HEAD REPORT
   REPLY->QUERY_QUAL_CNT = 0
 
HEAD A.SCH_ACTION_ID
 
   REPLY->QUERY_QUAL_CNT = REPLY->QUERY_QUAL_CNT + 1
 
   IF (MOD(REPLY->QUERY_QUAL_CNT, 100) = 1)
      STAT = ALTERLIST(REPLY->QUERY_QUAL, (REPLY->QUERY_QUAL_CNT + 99))
   ENDIF
 
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#SCHENTRYID        = A.SCH_ENTRY_ID
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#SCHEVENTID        = A.SCH_EVENT_ID
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#SCHEDULEID        = A.SCHEDULE_ID
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#SCHEDULESEQ       = E.SCHEDULE_SEQ
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#REQACTIONID       = A.SCH_ACTION_ID
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#ACTIONID          = EA.REQ_ACTION_ID
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#SCHAPPTID         = A.SCH_APPT_ID
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#STATEMEANING      = E.SCH_MEANING
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#EARLIESTDTTM      = CNVTDATETIME (A.EARLIEST_DT_TM)
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#LATESTDTTM        = CNVTDATETIME (A.LATEST_DT_TM)
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#REQMADEDTTM       = CNVTDATETIME (A.REQUEST_MADE_DT_TM)
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#ENTRYSTATEMEANING = A.ENTRY_STATE_MEANING
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#REQACTIONMEANING  = A.REQ_ACTION_MEANING
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#ENCOUNTERID       = A.ENCNTR_ID
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#PERSONID          = A.PERSON_ID
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#BITMASK           = 0
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->HIDE#FORMATID          = E.APPT_TYPE_CD
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->Date_Birth             = format(p.birth_dt_tm,"DD/MM/YYYY;;DATE")
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->Prsnl_name             = trim(pr.name_full_formatted)
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->EARLIEST_DT_TM         = CNVTDATETIME (A.EARLIEST_DT_TM)
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->Request_Date           = CNVTDATETIME (A.EARLIEST_DT_TM)
 
   IF ( (A.EARLIEST_DT_TM = CNVTDATETIME ( "01-JAN-1800 00:00:00.00" )) )
      REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->Request_Date   = cnvtdatetime(ea.action_dt_tm)
   ENDIF
 
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->Req_action_display = UAR_GET_CODE_DISPLAY(A.REQ_ACTION_CD)
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->APPT_TYPE_DISPLAY  = SEA.DESCRIPTION
 
   IF ( L_EXISTS = 1 AND L.STATUS_FLAG = 1 )
      REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->PERSON_NAME = "RECORD LOCKED, UPDATING NOT PERMITTED"
   ELSE
      IF ( (A.PERSON_ID> 0 ) )
         REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->PERSON_NAME = P.NAME_FULL_FORMATTED
      ELSE
         REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->PERSON_NAME = ""
      ENDIF
   ENDIF
 
   amrn           = fillstring(9," ")
   cmrn           = fillstring(9," ")
   smrn           = fillstring(9," ")
   umrn           = fillstring(9," ")
   Home_phone     = fillstring(15," ")
   Business_phone = fillstring(15," ")
 
    ;mod#009 - begin
	Mob_phone 	  = fillstring(15," ")
	;mod#009 - end
 
   Home_address   = fillstring(50," ")
   Home_address1  = fillstring(50," ")
 
DETAIL
   IF (pa.alias_pool_cd = alf_alias_cd)
      amrn = concat(format(pa.alias,"#######;P0"),"A,")
   ENDIF
 
   IF (pa.alias_pool_cd = cgmc_alias_cd)
      cmrn = concat(format(pa.alias,"#######;P0"),"C,")
   ENDIF
 
   IF (pa.alias_pool_cd = sdmh_alias_cd)
      smrn = concat(format(pa.alias,"#######;P0"),"S,")
   ENDIF
 
    IF (pa.alias_pool_cd = AHU_UR)
      umrn = concat(format(pa.alias,"#######;P0"),"U,")
   ENDIF
   CASE (PH.PHONE_TYPE_CD)
      OF Home_phone_cd     : Home_phone     = trim(substring(1,15,(PH.PHONE_NUM)))
      OF Business_phone_cd : Business_phone = trim(substring(1,15,(PH.PHONE_NUM)))
 
      ;mod#009 - begin
	  OF mob_phone_cd 		: Mob_phone 		= trim(substring(1,15,(PH.PHONE_NUM)))
	  ;mod#009 - end
 
   ENDCASE
 
   IF (ADDR.ADDRESS_TYPE_CD  = Home_addr_cd)
      Home_address = concat(trim(addr.street_addr),", ",trim(addr.street_addr2),", ",trim(addr.city))
   ENDIF
 
FOOT A.SCH_ENTRY_ID
 
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->MRN     = build(amrn,cmrn,smrn,umrn)
 
   ;mod#009 - begin
   if(textlen(trim(Mob_phone,3)) > 0)
   		REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->Phone   = build(Home_phone,"/",Mob_phone)
   else
   		REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->Phone   = build(Home_phone,"/",Business_phone)
   endif
   ;mod#009 - end
 
   REPLY->QUERY_QUAL[REPLY->QUERY_QUAL_CNT]->Address = Home_address
 
FOOT REPORT
 
   IF ((MOD(REPLY->QUERY_QUAL_CNT, 100) != 0 ))
      STAT = ALTERLIST(REPLY->QUERY_QUAL, REPLY->QUERY_QUAL_CNT)
   ENDIF
 
WITH  NOCOUNTER,
      OUTERJOIN = D5,
      DONTCARE  = SEA,
      OUTERJOIN = D1,
      DONTCARE  = L,
      OUTERJOIN = D2,
      DONTCARE  = AD,
      OUTERJOIN = D3,
      OUTERJOIN = D4
 
IF ((REPLY->QUERY_QUAL_CNT <= 0 ))
   GO TO EXIT_SCRIPT
ENDIF
 
; Get Event Details
 
SELECT  INTO  "nl:"
 
FROM (DUMMYT D WITH SEQ = VALUE(REPLY->QUERY_QUAL_CNT))
  ,SCH_EVENT        SE
  ,SCH_APPT_TYPE    SAT
  ,OE_FORMAT_FIELDS O
  ,SCH_EVENT_DETAIL SED
 
PLAN  D
   WHERE REPLY->QUERY_QUAL[D.SEQ]->HIDE#SCHEVENTID > 0
 
JOIN SE
   WHERE SE.SCH_EVENT_ID = REPLY->QUERY_QUAL[D.SEQ]->HIDE#SCHEVENTID
   AND   SE.ACTIVE_IND = 1
 
JOIN SAT
   WHERE SE.APPT_TYPE_CD = SAT.APPT_TYPE_CD
 
JOIN O
   WHERE O.OE_FORMAT_ID = SAT.OE_FORMAT_ID
   AND   CNVTUPPER(O.LABEL_TEXT) in ("COMMENTS")
 
JOIN SED
   WHERE SED.SCH_EVENT_ID = REPLY->QUERY_QUAL[D.SEQ]->HIDE#SCHEVENTID
   AND   SED.ACTIVE_IND   = 1
   AND   O.OE_FIELD_ID    = SED.OE_FIELD_ID
 
DETAIL
   CASE (CNVTUPPER(O.LABEL_TEXT))
      OF "COMMENTS": REPLY->QUERY_QUAL[D.SEQ]->Comments = SED.OE_FIELD_DISPLAY_VALUE
   ENDCASE
 
WITH  NOCOUNTER
 
; Get encounter data
 
SELECT INTO "nl:"
FROM (DUMMYT D WITH SEQ = VALUE(REPLY->QUERY_QUAL_CNT)),
   ENCOUNTER E
PLAN D
JOIN E
   WHERE E.PERSON_ID     = REPLY->QUERY_QUAL[D.SEQ]->HIDE#PERSONID
   AND   E.ARRIVE_DT_TM <= CNVTDATETIME(CURDATE,CURTIME3)
   AND   E.DISCH_DT_TM   = NULL
   AND   E.ACTIVE_IND    = 1
 
DETAIL
   REPLY->QUERY_QUAL[D.SEQ]->Fin_class = UAR_GET_CODE_DISPLAY(E.FINANCIAL_CLASS_CD)
WITH NOCOUNTER
 
; 010 get current encounter details
SELECT INTO "nl:"
FROM (DUMMYT D WITH SEQ = VALUE(REPLY->QUERY_QUAL_CNT)),
   ENCOUNTER E
PLAN D
JOIN E
   WHERE E.encntr_id     = REPLY->QUERY_QUAL[D.SEQ]->HIDE#ENCOUNTERID
   AND   E.ARRIVE_DT_TM <= CNVTDATETIME(CURDATE,CURTIME3)
   AND   E.ACTIVE_IND    = 1
DETAIL
   REPLY->QUERY_QUAL[D.SEQ]->Location  = concat( trim(UAR_GET_CODE_DISPLAY(E.loc_nurse_unit_cd))
   												, "  ( ", trim(UAR_GET_CODE_DISPLAY(E.loc_room_cd))
   												, " ; ", trim(UAR_GET_CODE_DISPLAY(E.loc_bed_cd))," )"
   												)
   if ( E.disch_dt_tm = NULL )
   REPLY->QUERY_QUAL[D.SEQ]->Discharge_Status = ""
   else
   REPLY->QUERY_QUAL[D.SEQ]->Discharge_Status = "Discharged"
   endif
 
WITH NOCOUNTER
 
; 011 get MAPT Score and Received Date from the OP OAHKS Powerform...
 
SELECT INTO "nl:"
FROM
	(DUMMYT D WITH SEQ = VALUE(REPLY->QUERY_QUAL_CNT)),
   	clinical_event c,
   	clinical_event c1,
   	ce_date_result cdr,
   	dcp_forms_activity dfa
   	
PLAN D
JOIN c WHERE 
	c.person_id	  		= REPLY->QUERY_QUAL[D.SEQ]->HIDE#PERSONID
   	and
   	c.event_cd 			= mapt_score_cd
   	and	 
   	c.result_status_cd	!= in_error_cd
  	and
  	c.valid_until_dt_tm > sysdate

JOIN c1 WHERE 
	c1.person_id	  	= c.person_id
   	and
   	c1.parent_event_id	= c.parent_event_id
   	and
   	c1.event_cd 		= mapt_rcvd_dt_cd
   	and
   	c1.result_status_cd	!= in_error_cd
   	and
   	c1.valid_until_dt_tm > sysdate
   
JOIN cdr WHERE	   
	cdr.event_id = c1.event_id
	and
	cdr.valid_until_dt_tm > sysdate

JOIN dfa WHERE
	dfa.dcp_forms_activity_id = cnvtreal(substring(1, findstring(".",c.reference_nbr)-1, c.reference_nbr))
	and
	dfa.description = "OP OAHKS"
	and
	dfa.active_ind = 1   
 
ORDER BY c.valid_from_dt_tm
 
DETAIL
	if (textlen(trim(c.result_val,3)) > 0 )
		REPLY->QUERY_QUAL[D.SEQ]->MAPT_Score  = cnvtreal(trim(c.result_val,3))
	endif
	
	REPLY->QUERY_QUAL[D.SEQ]->MAPT_Rcvd_Date  = cdr.result_dt_tm
	 
WITH NOCOUNTER
 
; Get referral details from the order
 
SELECT  INTO  "nl:"
 
FROM (DUMMYT D WITH SEQ = VALUE(REPLY->QUERY_QUAL_CNT)),
   SCH_EVENT_ATTACH SEA,
   ORDER_DETAIL     O,
   ORDERS           ORDE,
   OE_FORMAT_FIELDS OFO
 
PLAN D
 
JOIN SEA
   WHERE SEA.SCH_EVENT_ID = REPLY->QUERY_QUAL[D.SEQ]->HIDE#SCHEVENTID
   AND   SEA.ACTIVE_IND   = 1
 
JOIN O
   WHERE SEA.ORDER_ID = O.ORDER_ID
 
JOIN ORDE
   WHERE ORDE.ORDER_ID = O.ORDER_ID
 
JOIN OFO
   WHERE OFO.OE_FIELD_ID    =  o.oe_field_id
   AND   OFO.OE_FORMAT_ID   =  orde.oe_format_id
   AND   OFO.ACTION_TYPE_CD = 1823
 
ORDER BY sea.order_id
 
HEAD sea.order_id
   reas_cnt = 0
   reas = fillstring(200," ")
   REPLY->QUERY_QUAL[D.SEQ]->Referral_Received_From = "%"
 
DETAIL
 
   CASE (CNVTUPPER(OFO.label_text))
      OF "REFERRAL RECEIVED FROM"   : REPLY->QUERY_QUAL[D.SEQ]->Referral_Received_From = O.OE_FIELD_DISPLAY_VALUE
      OF "URGENCY OF REFERRAL"      : REPLY->QUERY_QUAL[D.SEQ]->Urgency_of_Referral    = O.OE_FIELD_DISPLAY_VALUE
      OF "REFERRING AGENCY"         : REPLY->QUERY_QUAL[D.SEQ]->Referring_Agency       = O.OE_FIELD_DISPLAY_VALUE
      OF "DIAGNOSIS"                : REPLY->QUERY_QUAL[D.SEQ]->Diagnosis              = O.OE_FIELD_DISPLAY_VALUE
      OF "REFERRAL TYPE"            : REPLY->QUERY_QUAL[D.SEQ]->Referral_Type          = O.OE_FIELD_DISPLAY_VALUE
      OF "PRIORITY"                 : REPLY->QUERY_QUAL[D.SEQ]->Priority               = O.OE_FIELD_DISPLAY_VALUE
;     OF "POTENTIAL SERVICE"        : REPLY->QUERY_QUAL[D.SEQ]->Potential_Service      = O.OE_FIELD_DISPLAY_VALUE
      OF "ADDITIONAL REFERRAL INFORMATION": REPLY->QUERY_QUAL[D.SEQ]->Additional_info  = O.OE_FIELD_DISPLAY_VALUE
      OF "CLINICAL NOTES AND REQUEST"     : REPLY->QUERY_QUAL[D.SEQ]->Additional_info  = O.OE_FIELD_DISPLAY_VALUE
      OF "REVIEW IN CLINIC"         : REPLY->QUERY_QUAL[D.SEQ]->Review_in_Clinic       = O.OE_FIELD_DISPLAY_VALUE
      OF "CLINICAL URGENCY"         : REPLY->QUERY_QUAL[D.SEQ]->Clinical_Urgency       = O.OE_FIELD_DISPLAY_VALUE
      OF "DATE REFERRAL RECEIVED"   : REPLY->QUERY_QUAL[D.SEQ]->Referral_Received_date = O.OE_FIELD_DT_TM_VALUE
      OF "REFERRING UNIT*"          : REPLY->QUERY_QUAL[D.SEQ]->Referring_Unit         = O.OE_FIELD_DISPLAY_VALUE
      OF "REFERRING WARD*"          : REPLY->QUERY_QUAL[D.SEQ]->Referring_Ward         = O.OE_FIELD_DISPLAY_VALUE
                                      IF (REPLY->QUERY_QUAL[D.SEQ]->Referral_Received_From = "%")
                                         REPLY->QUERY_QUAL[D.SEQ]->Referral_Received_From = O.OE_FIELD_DISPLAY_VALUE
                                      ENDIF
/*    OF "ESTIMATED DISCHARGE DATE*": REPLY->QUERY_QUAL[D.SEQ]->Discharge_Date         = O.OE_FIELD_DT_TM_VALUE
 
      OF "REASON FOR REFERRAL (YOU MAY CHOOSE MULTIPLE REASONS)" :
         IF (reas_cnt = 0)
            reas = build(reas,o.oe_field_display_value)
            reas_cnt = 1
         ELSE
            reas = build(reas,",",o.oe_field_display_value)
         ENDIF
*/
      OF "REASON FOR REFERRAL*":
         IF (reas_cnt = 0)
            reas = build(reas,o.oe_field_display_value)
            reas_cnt = 1
         ELSE
            reas = build(reas,",",o.oe_field_display_value)
         ENDIF
/*
      OF "REASON FOR REFERRAL (CHOOSE UP TO 5 IF REQUIRED)" :
         IF (reas_cnt = 0)
            reas = build(reas,o.oe_field_display_value)
            reas_cnt = 1
         ELSE
            reas = build(reas,",",o.oe_field_display_value)
         ENDIF
 
      OF "REASON FOR REFERRAL/GOALS TO BE ADDRESSED":
         IF (reas_cnt = 0)
            reas = build(reas,o.oe_field_display_value)
            reas_cnt = 1
         ELSE
            reas = build(reas,",",o.oe_field_display_value)
         ENDIF
*/
	OF "PATIENT*DISABILITY*": REPLY->QUERY_QUAL[D.seq]->Disability = O.oe_field_display_value ;007 Addition
   ENDCASE
 
FOOT sea.order_id
 
   REPLY->QUERY_QUAL[D.SEQ]->Reason_for_Referral = trim(reas)
 
   IF (REPLY->QUERY_QUAL[D.SEQ]->Referral_Received_From = "%")
      REPLY->QUERY_QUAL[D.SEQ]->Referral_Received_From = ""
   ENDIF
 
WITH NOCOUNTER
 
# EXIT_SCRIPT
 
IF ( FAILED = FALSE )
   SET REPLY->STATUS_DATA->STATUS = "S"
ELSE
   SET REPLY->STATUS_DATA->STATUS = "Z"
   IF ( FAILED != TRUE )
      CASE ( FAILED )
          OF SELECT_ERROR :
             SET      REPLY->STATUS_DATA->SUBEVENTSTATUS[1]->OPERATIONNAME = "SELECT"
             ELSE SET REPLY->STATUS_DATA->SUBEVENTSTATUS[1]->OPERATIONNAME = "UNKNOWN"
      ENDCASE
      SET REPLY->STATUS_DATA->SUBEVENTSTATUS[1]->OPERATIONSTATUS   = "Z"
      SET REPLY->STATUS_DATA->SUBEVENTSTATUS[1]->TARGETOBJECTNAME  = "TABLE"
      SET REPLY->STATUS_DATA->SUBEVENTSTATUS[1]->TARGETOBJECTVALUE = TABLE_NAME
   ENDIF
ENDIF
 
FREE SET T_RECORD
END GO
 
