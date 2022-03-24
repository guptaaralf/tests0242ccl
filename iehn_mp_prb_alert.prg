/********************************************************************************************************************
*   Program Run From : Called from cust_script:iehn_mp_prb_alert.html which is called by a Discern Rule
*********************************************************************************************************************
*   Description :     Returns JSON containing PERSON demographics (not ENCOUNTER, as the OPENCHART event has no
*                    ENCOUNTER context), and details (including comments) of active PROBLEMS for a given patient
*                    and a given set of Problem Nomenclatures.
*
*                    Example Parameters: ^MINE^,123.00, value('Behaviours of Concern','MRSA')
*					**************************************************************
*					a problem list must be maintained and synced with Discern Rule
*					**************************************************************
*
*********************************************************************************************************************
*    Used With:        HTML FILE: cust_script:iehn_mp_prb_alert.html
*                    DISCERN RULE: ALERT_NOTIFY_CHK_PRB
*
*********************************************************************************************************************
*   Owner :         Alfred Health
*                    Commercial Road, Melbourne
*                    Victoria, 3004
*                    Australia
*********************************************************************************************************************
*   Modification Control Log
*********************************************************************************************************************
*    Mod#	Author			Date			Description
*    001	Steven White	21 APR 2016		Initial Commit to PROD
*    002	Mohammed Al-Kaf	04 MAY 2016		fix the issue when there is more than 2 problems. By ignoring PROBLEMS parameter
*    003    Mohammed Al-Kaf 12 MAY 2016		add a check if problem display is empty
**********************************************************************************************************************/
 
drop program iehn_mp_prb_alert go
create program iehn_mp_prb_alert
prompt
	"Output to" = "MINE"
	, "PERSON ID" = 0.0
	, "PROBLEMS" = ""
 
with OUTDEV, PID, PRB
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare ACTIVE_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",12030,"ACTIVE")),protect ; mod 002
declare PROBLEM_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",400,"BAYSIDEPROBLEM")),protect ; mod 002
 
declare personId = f8 with constant(cnvtreal($PID))
declare inerror_cd = f8 with constant(uar_get_code_by("MEANING",8,"INERROR"))
declare recorder_cd = f8 with constant(uar_get_code_by("MEANING", 12038 , "RECORDER"))
declare mrn_cd = f8 with constant(uar_get_code_by("DISPLAYKEY", 319,"MRN"))
declare fin_cd = f8 with constant(uar_get_code_by("MEANING", 319, "FIN NBR"))
declare alert_cd = f8 with constant(uar_get_code_by("DISPLAYKEY", 72, "PATIENTALERTS"))
 
 
declare p = i4 with noconstant(0)
declare c = i4 with noconstant(0)
declare a = i4 with noconstant(0)
declare ERRORHANDLER (
    (OPERATIONNAME = VC),
    (OPERATIONSTATUS = VC),
    (TARGETOBJECTNAME = VC),
    (TARGETOBJECTVALUE = VC)
    ) = NULL
declare lstat = i4 with protect, noconstant(0)
declare sScriptName = vc with protect, constant("iehn_mp_mro_alert")
declare errmsg = c132 with protect, noconstant(fillstring(132, " "))
declare error_check = i2 with protect, noconstant(ERROR(ERRMSG, 1))
FREE RECORD REPLY
RECORD REPLY (
    1 PERSON_ID = f8
    1 FIN_NBR = vc
    1 MRN = vc
    1 LOC_DISP = vc
    1 PERSON_NAME = vc
    1 SBIRTH_DT = vc
    1 SEX_DISP = vc
    1 PROBLEM[*]
        2 PROBLEM_ID = f8
        2 PROBLEM_DISP = vc
        2 RECORDER_PRSNL = vc
        2 SRECORDER_DT = vc
        2 SONSET_DT = vc
        2 COMMENT[*]
            3 COMMENT_DISP = vc
            3 COMMENT_PRSNL = vc
            3 SCOMMENT_DT_TM = vc
    1 ALERTS[*]
        2 EVENT_ID = f8
        2 EVENT_TITLE_TEXT = vc
        2 SEVENT_END_DT_TM = vc
    1 UPDT_ID = f8
    1 UPDT_NAME = vc
    1 UPDT_DT_TM = dq8
    1 SUPDT_DT_TM = vc
    1 COMMIT_IND = i2
    1 POSITION_CD = f8
    1 POSITION_DISP = vc
    1 UPDT_APP = i4
    1 UPDT_TASK = i4
    1 UPDT_REQ = i4
    1 UPDT_APPLCTX = i4
    1 EXECUTABLE = vc
    1 SCRIPT_NAME = vc
%i cclsource:status_block.inc
)
SET MODIFY RECORDALTER
set lstat = setStatus(0)
set lstat = getDemographics(0)
set lstat = getProblems(0)
;set lstat = getAlerts(0) ;Option to add "Patient Alerts" documents
SUBROUTINE setStatus(NULL)
    SET REPLY->STATUS_DATA.STATUS = "Z" ;Default to Zero Returned Records
    SET REPLY->UPDT_ID = REQINFO->UPDT_ID
    SET REPLY->UPDT_DT_TM = sysdate
    SET REPLY->SUPDT_DT_TM = FORMAT(REPLY->UPDT_DT_TM , "@SHORTDATETIME")
    SET REPLY->COMMIT_IND = REQINFO->COMMIT_IND
    SET REPLY->POSITION_CD = REQINFO->POSITION_CD
    SET REPLY->POSITION_DISP = uar_get_code_display(REQINFO->POSITION_CD)
    SET REPLY->UPDT_APP = REQINFO->UPDT_APP
    SET REPLY->UPDT_REQ = REQINFO->UPDT_REQ
    SET REPLY->UPDT_APPLCTX = REQINFO->UPDT_APPLCTX
    SET REPLY->SCRIPT_NAME = sScriptName
    SELECT INTO "nl:"
    FROM PRSNL P
    WHERE P.person_id= REPLY->UPDT_ID
    DETAIL
        REPLY->UPDT_NAME = TRIM(P.name_full_formatted)
    WITH NOCOUNTER, TIME=5
    SET REPLY->EXECUTABLE = "powerchart.exe" ;Default to Powerchart
    SELECT INTO "n"
    FROM APPLICATION A
    WHERE A.application_number = REQINFO->UPDT_APP
    DETAIL
        REPLY->EXECUTABLE = A.object_name
    WITH NOCOUNTER, TIME = 30
    SET ERROR_CHECK = ERROR(ERRMSG,0)
    IF (ERROR_CHECK !=0)
        CALL ERRORHANDLER ("setStatus" , "F" , "Status Error" , ERRMSG)
    ENDIF
    RETURN (0)
END ;setStatus
SUBROUTINE getDemographics(NULL)
    SELECT INTO "NL:"
    FROM PERSON P
    PLAN P    WHERE P.person_id = personId
    DETAIL
        REPLY->PERSON_ID = personId
        REPLY->PERSON_NAME = P.name_full_formatted
        REPLY->SBIRTH_DT = format(P.birth_dt_tm, "@SHORTDATE4YR")
        REPLY->SEX_DISP = uar_get_code_display(P.sex_cd)
    WITH NOCOUNTER
    SET ERROR_CHECK = ERROR(ERRMSG,0)
    IF (ERROR_CHECK !=0)
        CALL ERRORHANDLER ("getDemographics" , "F" , "Getting Person Info" , ERRMSG)
    ENDIF
    RETURN (0)
END ;getDemographics
SUBROUTINE getAlerts(NULL)
    declare d = i4 with noconstant(0)
    SELECT INTO "NL:"
    FROM CLINICAL_EVENT CE
    PLAN CE WHERE
        CE.person_id = personId AND
        CE.event_cd = alert_cd AND
        CE.valid_until_dt_tm > sysdate AND
        CE.view_level = 1 AND
        CE.result_status_cd != inerror_cd
    DETAIL
        d += 1
        REPLY->ALERTS[d].EVENT_ID = CE.event_id
        REPLY->ALERTS[d].EVENT_TITLE_TEXT = CE.event_title_text
        REPLY->ALERTS[d].SEVENT_END_DT_TM = format(CE.event_end_dt_tm, "@SHORTDATETIMENOSEC")
    WITH NOCOUNTER
    SET ERROR_CHECK = ERROR(ERRMSG,0)
    IF (ERROR_CHECK !=0)
        CALL ERRORHANDLER ("getAlerts" , "F" , "Getting Alerts" , ERRMSG)
    ENDIF
    RETURN (0)
END ;getAlerts
SUBROUTINE getProblems(NULL)
	declare filterList = vc ; mod 002
	set filterList = "  n.SOURCE_STRING_KEYCAP in ('CONTACT OF CPE PATIENT','VRE - REQUIRES ISOLATION. CONTACT INFECTION CONTROL','VISA - REQUIRES ISOLATION. CONTACT INFECTION CONTROL','MRSA - REQUIRES ISOLATION. CONTACT INFECTION CONTROL','MBL REQUIRES ISOLATION. CONTACT INFECTION CONTROL','HIGHLY RESISTANT/ TRANSMISSIBLE MICROORGANISM','VRE HISTORY - REFER TO MULTI RESISTENT ORGANISMS (MRO) GUIDELINE FOR ALL PATIENTS WITH THIS STATUS', 'VRE VAN B HISTORY - REFER TO MULTI RESISTENT ORGANISMS (MRO) GUIDELINE FOR ALL PATIENTS WITH THIS STATUS')" ;mod 002
SELECT INTO "NL:"
    FROM
        PROBLEM   PR
        , PROBLEM_PRSNL_R   PPR
        , PROBLEM_COMMENT   PC
        , PRSNL   P1
        , PRSNL   P2
        , NOMENCLATURE N
    PLAN PR WHERE
        PR.person_id = personId AND
        PR.active_ind = 1 AND
        PR.end_effective_dt_tm > sysdate and
        pr.life_cycle_status_cd = ACTIVE_VAR ; mod 002
    JOIN N WHERE
        N.nomenclature_id = PR.nomenclature_id ;AND
       ; N.source_string = $PRB
       and parser(filterList) ;mod 002
      ; and n.active_ind = 1 ;mod 002
       and n.source_vocabulary_cd = PROBLEM_VAR ;mod 002
    JOIN PPR WHERE
        PPR.problem_id = PR.problem_id AND
        PPR.active_ind = 1 AND
        PPR.end_effective_dt_tm > sysdate AND
        PPR.problem_reltn_cd = recorder_cd
    JOIN P1 WHERE
        P1.person_id = PPR.problem_reltn_prsnl_id
    JOIN PC WHERE
        PC.problem_id = OUTERJOIN(PR.problem_id) AND
        PC.active_ind = OUTERJOIN(1)
    JOIN P2 WHERE
        P2.person_id = OUTERJOIN(PC.comment_prsnl_id)
    ORDER BY PR.problem_id, PC.problem_comment_id DESC
    HEAD REPORT
        REPLY->STATUS_DATA.STATUS = "S"
    HEAD PR.problem_id
        p += 1
        c = 0
        REPLY->PROBLEM[p].PROBLEM_ID = PR.problem_id
        IF(trim(PR.annotated_display)!='') ;mod 003 added as several patients have problem records with empty annotated display
        	REPLY->PROBLEM[p].PROBLEM_DISP = PR.annotated_display
        ELSE
        	REPLY->PROBLEM[p].PROBLEM_DISP = N.source_string
        ENDIF
        REPLY->PROBLEM[p].RECORDER_PRSNL = P1.name_full_formatted
        REPLY->PROBLEM[p].SRECORDER_DT = format(PPR.problem_reltn_dt_tm, "@SHORTDATE4YR")
        REPLY->PROBLEM[p].SONSET_DT = NULLCHECK(
            BUILD(format(PR.onset_dt_tm, "@SHORTDATE4YR")),
            "Unknown",
            NULLIND(PR.onset_dt_tm))
    HEAD PC.problem_comment_id
        IF (PC.problem_comment_id > 0)
            c += 1
            REPLY->PROBLEM[p].COMMENT[c].COMMENT_DISP = PC.problem_comment
            REPLY->PROBLEM[p].COMMENT[c].COMMENT_PRSNL = P2.name_full_formatted
            REPLY->PROBLEM[p].COMMENT[c].SCOMMENT_DT_TM = format(PC.comment_dt_tm, "@SHORTDATETIMENOSEC")
        ENDIF
    WITH NOCOUNTER
    SET ERROR_CHECK = ERROR(ERRMSG,0)
    IF (ERROR_CHECK !=0)
        CALL ERRORHANDLER ("getProblems" , "F" , "Query Error" , ERRMSG)
    ENDIF
    RETURN (0)
END ;getProblems
SUBROUTINE ERRORHANDLER(OPERATIONNAME,OPERATIONSTATUS,TARGETOBJECTNAME,TARGETOBJECTVALUE)
    DECLARE ERROR_CNT = I2 WITH PRIVATE , NOCONSTANT (0)
    SET ERROR_CNT = SIZE(REPLY->STATUS_DATA->SUBEVENTSTATUS,5)
    IF ((ERROR_CNT > 1) OR (ERROR_CNT = 1 AND REPLY->STATUS_DATA->SUBEVENTSTATUS[ERROR_CNT]->OPERATIONSTATUS!=""))
        SET ERROR_CNT = (ERROR_CNT +1)
        SET LSTAT = ALTER(REPLY->STATUS_DATA->SUBEVENTSTATUS,ERROR_CNT)
    ENDIF
 
    SET REPLY->STATUS_DATA->STATUS = "F"
    SET REPLY->STATUS_DATA->SUBEVENTSTATUS[ERROR_CNT]->OPERATIONNAME = OPERATIONNAME
    SET REPLY->STATUS_DATA->SUBEVENTSTATUS[ERROR_CNT]->OPERATIONSTATUS = OPERATIONSTATUS
    SET REPLY->STATUS_DATA->SUBEVENTSTATUS[ERROR_CNT]->TARGETOBJECTNAME = TARGETOBJECTNAME
    SET REPLY->STATUS_DATA->SUBEVENTSTATUS[ERROR_CNT]->TARGETOBJECTVALUE = TARGETOBJECTVALUE
    GO TO EXIT_SCRIPT
END ;ERRORHANDLER Subroutine
# EXIT_SCRIPT
    set _memory_reply_string = cnvtrectojson(REPLY)
    FREE RECORD REPLY
END
GO
 
