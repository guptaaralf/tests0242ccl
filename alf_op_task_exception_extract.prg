/*-------------------------------------------------------------------------------------------------------------------
 
Module 				: EXTRACT TO REPORT EXCEPTION CASES ENCOUNTERED DURING PROCESSING OF OUTPATIENT APPOINTMENTS
Program Run From 	: EXPLORER MENU/DISCERN EXPLORER OR OPS SCHEDULER
 
---------------------------------------------------------------------------------------------------------------------
Description 		: THIS PROGRAM GENERATES AN EXTRACT TO REPORT THE EXCEPTIONS GENERATED WHILE PROCESSING
					  OUTPATIENT REFERRALS.
---------------------------------------------------------------------------------------------------------------------
Owner 				: Alfred Health
					  Commercial Road, Melbourne
					  Victoria, 3004
	 				  Australia
---------------------------------------------------------------------------------------------------------------------
Modification Control Log
---------------------------------------------------------------------------------------------------------------------
		Mod # 	Author 						Date 			Description
		----- 	----------------------- 	--------------- -----------------------------------
		000		NEHA NAROTA					20-OCT-2017		INITIAL RELEASE
 		001		NEHA NAROTA					23-OCT-2017		WRITE THE CSV TO CUST_EXTRACTS FOLDER AND THEN SEND IT TO
 															THE USER DIRECTLY VIA EMAIL
 	    002		NEHA NAROTA					24-OCT-2017		ADDING EXCEPTION QUERY FOR SCC TRIAGE ORDERS PLACED ON
 	    													NON-STATISTICALOP ENCOUNTERS
---------------------------------------------------------------------------------------------------------------------*/
 
 
drop program alf_op_task_exception_extract go
create program alf_op_task_exception_extract
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Exception Report for" = ""
 
with OUTDEV, exception_sel
 
;------ RECORD STRUCTURE ------
FREE RECORD OUTPATIENT_REC
 
RECORD OUTPATIENT_REC
(1 RECNUM[*]
	;------PERSON DETAILS-------
	2	P_PERSON_ID			= 	F8
	2	P_FIRST_NM			= 	VC
	2	P_LAST_NM			=	VC
	2	P_FULL_NM			= 	VC
	2	P_DOB				= 	VC
	2	P_SEX				= 	VC
	;------ENCOUNTER DETAILS------
	2	P_ENC_ID			= 	F8
	2	P_ENC_TYP			= 	VC
	2	P_ENC_ALIAS			= 	VC
	2	P_ENC_ALIAS_POOL	= 	VC
	2	P_ADMIT_DT			= 	VC
	2	P_DISCH_DT			= 	VC
	2	P_MED_UNIT			=	VC
	2	P_WARD				=	VC
	2	P_LOCATION			= 	VC
	;------TASK DETAILS------
 	2   P_TSK_NAME			= 	VC
 	2	P_TSK_CREATE_DTTM	=	VC
 	2	P_TSK_ID			= 	F8
 	2	P_TSK_OVERDUE		=	I4		; OVERDUE FROM THE CURRENT DATE
 	;------ORDER DETAILS-----
 	2	P_ORDR_ID			= 	F8
 	2	P_ORDR_TYPE			=	VC
 	2	P_ORDR_STA			=	VC
 
)
 
;------ LOCAL VARIABLES ------
 
DECLARE OUTPUT_STR = VC
	SET OUTPUT_STR = ""
 
DECLARE CSV = VC
	set csv = ","
 
DECLARE RECS = I4
	SET RECS = 0
 
DECLARE CSV_FILE_NAME  = VC
	SET CSV_FILE_NAME  = FILLSTRING(250, " ")
 
DECLARE MRN_CD = F8
	SET MRN_CD = uar_get_code_by("DISPLAYKEY", 319, "MRN")
 
DECLARE TSK_OP_TRIAGE_ENT = F8
	SET TSK_OP_TRIAGE_ENT = uar_get_code_by("DISPLAYKEY", 6026, "OPTRIAGEENT1")
 
DECLARE TSK_OP_TRIAGE_NSURG = F8
	SET TSK_OP_TRIAGE_NSURG = uar_get_code_by("DISPLAYKEY", 6026, "OPTRIAGENSURG")
 
DECLARE TSK_OP_TRIAGE_ORT = F8
	SET TSK_OP_TRIAGE_ORT = uar_get_code_by("DISPLAYKEY", 6026, "OPTRIAGEORT")
 
DECLARE TSK_OP_TRIAGE_RHM = F8
	SET TSK_OP_TRIAGE_RHM = uar_get_code_by("DISPLAYKEY", 6026, "OPTRIAGERHEUM")
 
DECLARE TSK_OP_TRIAGE_CH_SIN = F8
	SET TSK_OP_TRIAGE_CH_SIN = uar_get_code_by("DISPLAYKEY", 6026, "OPREVIEWCHRONICSINUSITIS")
 
DECLARE TSK_OP_RVW_OSTEO = F8
	SET TSK_OP_RVW_OSTEO = uar_get_code_by("DISPLAYKEY", 6026, "OPREVIEWOSTEOARTHRITIS")
 
DECLARE TSK_OP_RBK_ORTHO = F8
	SET TSK_OP_RBK_ORTHO = uar_get_code_by("DISPLAYKEY", 6026, "OPREVIEWRADBACKSORTHO")
 
DECLARE TSK_OP_RBK_NSURG = F8
	SET TSK_OP_RBK_NSURG = uar_get_code_by("DISPLAYKEY", 6026, "OPREVIEWRADBACKSNSUR")
 
DECLARE TSK_OP_DSCHG = F8
	SET TSK_OP_DSCHG = 0.0			;uar_get_code_by("DISPLAYKEY", 6026, "OPDISCHARGE")
 
DECLARE TSK_STA_INERROR = F8
	SET TSK_STA_INERROR = uar_get_code_by("DISPLAYKEY", 79, "INERROR")
 
DECLARE TSK_STA_INPROCESS = F8
	SET TSK_STA_INPROCESS = uar_get_code_by("DISPLAYKEY", 79, "INPROCESS")
 
DECLARE TSK_STA_ONHOLD = F8
	SET TSK_STA_ONHOLD = uar_get_code_by("DISPLAYKEY", 79, "ONHOLD")
 
DECLARE TSK_STA_OVRDUE = F8
	SET TSK_STA_OVRDUE = uar_get_code_by("DISPLAYKEY", 79, "OVERDUE")
 
DECLARE TSK_STA_PNDING = F8
	SET TSK_STA_PNDING = uar_get_code_by("DISPLAYKEY", 79, "PENDING")
 
DECLARE TSK_STA_SUSPEND = F8
	SET TSK_STA_SUSPEND = uar_get_code_by("DISPLAYKEY", 79, "SUSPENDED")
 
DECLARE ORD_TYP_ENT1 = F8
	SET ORD_TYP_ENT1 = uar_get_code_by("DISPLAYKEY", 200, "SCCTRIAGEENT1HEADNECK")
 
DECLARE ORD_TYP_NSURG = F8
	SET ORD_TYP_NSURG = uar_get_code_by("DISPLAYKEY", 200, "SCCTRIAGENSURG")
 
DECLARE ORD_TYP_ORTHO = F8
	SET ORD_TYP_ORTHO = uar_get_code_by("DISPLAYKEY", 200, "SCCTRIAGEORTHO")
 
DECLARE ORD_TYP_RHEUM = F8
	SET ORD_TYP_RHEUM = uar_get_code_by("DISPLAYKEY", 200, "SCCTRIAGERHEUM")
 
DECLARE ENC_TYP_STATOP = F8
	SET ENC_TYP_STATOP = uar_get_code_by("DISPLAYKEY", 71, "STATISTICALOP")
 
DECLARE ORD_STA_COMP = F8
	SET ORD_STA_COMP = uar_get_code_by("DISPLAYKEY", 6004, "COMPLETED")
 
DECLARE ORD_STA_FUTR = F8
	SET ORD_STA_FUTR = uar_get_code_by("DISPLAYKEY", 6004, "FUTURE")
 
DECLARE ORD_STA_INCOMP = F8
	SET ORD_STA_INCOMP = uar_get_code_by("DISPLAYKEY", 6004, "INCOMPLETE")
 
DECLARE ORD_STA_INPRO = F8
	SET ORD_STA_INPRO = uar_get_code_by("DISPLAYKEY", 6004, "INPROCESS")
 
DECLARE ORD_STA_ORD = F8
	SET ORD_STA_ORD = uar_get_code_by("DISPLAYKEY", 6004, "ORDERED")
 
DECLARE ORD_STA_PREW = F8
	SET ORD_STA_PREW = uar_get_code_by("DISPLAYKEY", 6004, "PENDINGREVIEW")
 
DECLARE ORD_STA_HOLD = F8
	SET ORD_STA_HOLD = uar_get_code_by("DISPLAYKEY", 6004, "ONHOLDMEDSTUDENT")
 
DECLARE ORD_STA_PCOMP = F8
	SET ORD_STA_PCOMP = uar_get_code_by("DISPLAYKEY", 6004, "PENDING COMPLETE")
 
;-----------------------------------------------------------------------------------------------------------
CASE ($exception_sel)
 
	OF "A" : ;---- OVERDUE TASKS ----
 
			SELECT INTO "NL:"
 
			FROM
				TASK_ACTIVITY   T
				, ORDER_TASK   O
				, PERSON   P
				, ENCOUNTER   E
				, ENCNTR_ALIAS   EA
 
			PLAN T
			WHERE T.task_type_cd IN (TSK_OP_TRIAGE_ENT			; OP Triage ENT 1
									 , TSK_OP_TRIAGE_NSURG		; OP Triage NSURG
									 , TSK_OP_TRIAGE_ORT		; OP Triage ORT
									 , TSK_OP_TRIAGE_RHM		; OP Triage RHEUM
									 , TSK_OP_TRIAGE_CH_SIN		; OP Review Chronic Sinusitis
									 , TSK_OP_RVW_OSTEO			; OP Review Osteoarthritis
									 , TSK_OP_RBK_ORTHO			; OP Review RadBackS - ORTHO
									 , TSK_OP_RBK_NSURG			; OP Review RadBackS - NSUR
									 , TSK_OP_DSCHG				; OP Discharge
									)
 
			and t.task_status_cd in(TSK_STA_INERROR			;INERROR
									, TSK_STA_INPROCESS		; INPROCESS
									, TSK_STA_ONHOLD		; ONHOLD
									, TSK_STA_OVRDUE		; OVERDUE
									, TSK_STA_PNDING		; PENDING
									, TSK_STA_SUSPEND		; SUSPENDED
			 					    )		;(79)
 
			AND 4 <= datetimediff(sysdate, t.task_create_dt_tm)
 
			JOIN O
			WHERE O.reference_task_id = T.reference_task_id
			AND O.task_type_cd = T.task_type_cd
			AND O.active_ind = 1
 
			JOIN P
			WHERE T.person_id = P.person_id
 
			JOIN E
			WHERE E.encntr_id = T.encntr_id
			AND E.active_ind = 1
 
			JOIN EA
			WHERE EA.encntr_id = T.encntr_id
			AND EA.encntr_alias_type_cd = MRN_CD
			AND EA.active_ind = 1
			AND EA.end_effective_dt_tm > SYSDATE
 
			ORDER BY
				P.name_full_formatted
 
			DETAIL
 
				RECS = RECS + 1
 
				; ALLOCATE MEMORY FOR PATIENT RECORDS
				if (MOD(RECS,10) = 1)
				      		STAT = ALTERLIST(OUTPATIENT_REC->RECNUM,RECS + 9)
				endif
 
			 	OUTPATIENT_REC->RECNUM[RECS].P_PERSON_ID		= 	P.person_id
				OUTPATIENT_REC->RECNUM[RECS].P_FIRST_NM			= 	CNVTUPPER(TRIM(P.name_first))
				OUTPATIENT_REC->RECNUM[RECS].P_LAST_NM			=	CNVTUPPER(TRIM(P.name_last))
				OUTPATIENT_REC->RECNUM[RECS].P_FULL_NM			= 	CNVTUPPER(TRIM(P.name_full_formatted))
				OUTPATIENT_REC->RECNUM[RECS].P_DOB				= 	FORMAT(P.birth_dt_tm, "dd/mm/YYYY;;d")
				OUTPATIENT_REC->RECNUM[RECS].P_SEX				= 	UAR_GET_CODE_DISPLAY(P.SEX_CD)
				;------ENCOUNTER DETAILS------
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_ID			= 	E.encntr_id
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_TYP			= 	UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CD)
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_ALIAS		= 	EA.alias
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_ALIAS_POOL	= 	UAR_GET_CODE_DISPLAY(EA.alias_pool_cd)
				OUTPATIENT_REC->RECNUM[RECS].P_ADMIT_DT			= 	FORMAT(E.arrive_dt_tm, "dd/mm/YYYY - HH:MM;;d")
				OUTPATIENT_REC->RECNUM[RECS].P_DISCH_DT			= 	FORMAT(E.disch_dt_tm, "dd/mm/YYYY - HH:MM;;d")
				OUTPATIENT_REC->RECNUM[RECS].P_MED_UNIT			=	REPLACE(UAR_GET_CODE_DISPLAY(E.MED_SERVICE_CD), ",", ";")
				OUTPATIENT_REC->RECNUM[RECS].P_LOCATION			= 	REPLACE(UAR_GET_CODE_DISPLAY(T.LOCATION_CD), ",", ";")
				;------TASK DETAILS------
			 	OUTPATIENT_REC->RECNUM[RECS].P_TSK_NAME			= 	O.TASK_DESCRIPTION		;UAR_GET_CODE_DISPLAY(T.TASK_TYPE_CD)
			 	OUTPATIENT_REC->RECNUM[RECS].P_TSK_CREATE_DTTM	=	FORMAT(T.task_create_dt_tm, "dd/mm/YYYY - HH:MM;;d")
			 	OUTPATIENT_REC->RECNUM[RECS].P_TSK_ID			= 	T.task_id
			 	OUTPATIENT_REC->RECNUM[RECS].P_TSK_OVERDUE		=	CNVTINT(datetimediff(sysdate, t.task_create_dt_tm)); OVERDUE CURRENT DATE
			 	;------ORDER DETAILS-----
			 	OUTPATIENT_REC->RECNUM[RECS].P_ORDR_ID			= 	T.order_id
 
			WITH NOCOUNTER, SEPARATOR=" ", FORMAT
 
			SET CSV_FILE_NAME = "ALF_OP_OVERDUE_TASKS_EXTRACT.csv"
 
;---------------------------------------------------------------------------------------------------------------------------------
 
	OF "B" : ;---- ORDERS ASSOCIATED WITH INCORRECT ENCOUNTERS ----
 
			SELECT INTO "NL:"
			O_CATALOG_DISP = UAR_GET_CODE_DISPLAY(O.CATALOG_CD)
 
			FROM
				ORDERS   O
				, ENCOUNTER   E
				, PERSON   P
				, ENCNTR_ALIAS   EA
 
			PLAN O
			WHERE O.catalog_cd IN (  ORD_TYP_ENT1		;SCC Triage ENT 1 Head + Neck
									,ORD_TYP_NSURG 		;SCC Triage NSURG
									,ORD_TYP_ORTHO 		;SCC Triage ORTHO
									,ORD_TYP_RHEUM		;SCC Triage RHEUM
								  )
 
			AND O.order_status_cd IN (  ORD_STA_COMP	;COMPLETED  6004
									  , ORD_STA_FUTR	;FUTURE
									  , ORD_STA_INCOMP	;INCOMPLETE
									  , ORD_STA_INPRO	;INPROCESS
									  , ORD_STA_ORD		;ORDERED
									  , ORD_STA_PREW	;PENDING REVIEW
									  , ORD_STA_HOLD	; ON HOLD, MED STUDENT
									  , ORD_STA_PCOMP	;PENDING COMPLETE
									  )
 
			AND O.active_ind = 1
 
	  		JOIN E
			WHERE O.encntr_id = E.encntr_id
			AND E.encntr_type_cd != ENC_TYP_STATOP		;StatisticalOP
 			AND ( E.disch_dt_tm > SYSDATE
    				OR
    	  		  E.disch_dt_tm IS NULL )
    		AND E.active_ind = 1
 
		    JOIN P
			WHERE P.person_id = E.person_id
 
			JOIN EA
			WHERE EA.encntr_id = E.encntr_id
			AND EA.encntr_alias_type_cd = MRN_CD
			AND EA.end_effective_dt_tm > SYSDATE
			AND EA.active_ind = 1
 
 			ORDER BY O.order_id
 
 			DETAIL
 
				RECS = RECS + 1
 
				; ALLOCATE MEMORY FOR PATIENT RECORDS
				if (MOD(RECS,10) = 1)
				      		STAT = ALTERLIST(OUTPATIENT_REC->RECNUM,RECS + 9)
				endif
 
			 	OUTPATIENT_REC->RECNUM[RECS].P_PERSON_ID		= 	P.person_id
				OUTPATIENT_REC->RECNUM[RECS].P_FIRST_NM			= 	CNVTUPPER(TRIM(P.name_first))
				OUTPATIENT_REC->RECNUM[RECS].P_LAST_NM			=	CNVTUPPER(TRIM(P.name_last))
				OUTPATIENT_REC->RECNUM[RECS].P_FULL_NM			= 	CNVTUPPER(TRIM(P.name_full_formatted))
				OUTPATIENT_REC->RECNUM[RECS].P_DOB				= 	FORMAT(P.birth_dt_tm, "dd/mm/YYYY;;d")
				OUTPATIENT_REC->RECNUM[RECS].P_SEX				= 	UAR_GET_CODE_DISPLAY(P.SEX_CD)
				;------ENCOUNTER DETAILS------
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_ID			= 	E.encntr_id
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_TYP			= 	REPLACE(UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CD), ",", ";")
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_ALIAS		= 	EA.alias
				OUTPATIENT_REC->RECNUM[RECS].P_ADMIT_DT			= 	FORMAT(E.arrive_dt_tm, "dd/mm/YYYY - HH:MM;;d")
				OUTPATIENT_REC->RECNUM[RECS].P_DISCH_DT			= 	FORMAT(E.disch_dt_tm, "dd/mm/YYYY - HH:MM;;d")
				OUTPATIENT_REC->RECNUM[RECS].P_MED_UNIT			=	REPLACE(UAR_GET_CODE_DISPLAY(E.MED_SERVICE_CD), ",", ";")
				;------ORDER DETAILS-----
			 	OUTPATIENT_REC->RECNUM[RECS].P_ORDR_ID			= 	O.order_id
 				OUTPATIENT_REC->RECNUM[RECS].P_ORDR_TYPE		= 	REPLACE(O_CATALOG_DISP, ",", ";")
 				OUTPATIENT_REC->RECNUM[RECS].P_ORDR_STA			= 	UAR_GET_CODE_DISPLAY(O.order_status_cd)
 
			WITH NOCOUNTER, SEPARATOR=" ", FORMAT
 
 			SET CSV_FILE_NAME = "ALF_OP_INCORRECT_ENTR_EXTRACT.csv"
;---------------------------------------------------------------------------------------------------------------------------------
 
	OF "C" : ;---- INCORRECT ORDERS FOR STATISTICALOP ENCOUNTERS ----
 
			SELECT INTO "NL:"
			O_CATALOG_DISP = UAR_GET_CODE_DISPLAY(O.CATALOG_CD)
 
			FROM
				ORDERS   O
				, ORDER_DETAIL   OD
				, ENCOUNTER   E
				, CODE_VALUE_GROUP   C
				, PERSON   P
				, ENCNTR_ALIAS   EA
 
			PLAN O
			WHERE O.catalog_cd IN (  ORD_TYP_ENT1		;SCC Triage ENT 1 Head + Neck
									,ORD_TYP_NSURG 		;SCC Triage NSURG
									,ORD_TYP_ORTHO 		;SCC Triage ORTHO
									,ORD_TYP_RHEUM		;SCC Triage RHEUM
								  )
			AND O.order_status_cd IN (  ORD_STA_COMP	;COMPLETED  6004
									  , ORD_STA_FUTR	;FUTURE
									  , ORD_STA_INCOMP	;INCOMPLETE
									  , ORD_STA_INPRO	;INPROCESS
									  , ORD_STA_ORD		;ORDERED
									  , ORD_STA_PREW	;PENDING REVIEW
									  , ORD_STA_HOLD	; ON HOLD, MED STUDENT
									  , ORD_STA_PCOMP	;PENDING COMPLETE
									  )
 
			AND O.active_ind = 1
 
			JOIN OD
			WHERE OD.order_id = O.order_id
			AND OD.oe_field_id =    61124423.00
 
			JOIN E
			WHERE O.encntr_id = E.encntr_id
			AND E.encntr_type_cd = ENC_TYP_STATOP
 
			JOIN C
			WHERE C.code_set = 101113
			AND C.parent_code_value = E.med_service_cd
			AND C.child_code_value != OD.oe_field_value
 
			JOIN EA
			WHERE EA.encntr_id = E.encntr_id
			AND EA.encntr_alias_type_cd = MRN_CD
			AND EA.active_ind = 1
			AND EA.end_effective_dt_tm > SYSDATE
 
			JOIN P
			WHERE P.person_id= O.person_id
 
 			ORDER BY O.order_id
 
 			DETAIL
 
				RECS = RECS + 1
 
				; ALLOCATE MEMORY FOR PATIENT RECORDS
				if (MOD(RECS,10) = 1)
				      		STAT = ALTERLIST(OUTPATIENT_REC->RECNUM,RECS + 9)
				endif
 
			 	OUTPATIENT_REC->RECNUM[RECS].P_PERSON_ID		= 	P.person_id
				OUTPATIENT_REC->RECNUM[RECS].P_FIRST_NM			= 	CNVTUPPER(TRIM(P.name_first))
				OUTPATIENT_REC->RECNUM[RECS].P_LAST_NM			=	CNVTUPPER(TRIM(P.name_last))
				OUTPATIENT_REC->RECNUM[RECS].P_FULL_NM			= 	CNVTUPPER(TRIM(P.name_full_formatted))
				OUTPATIENT_REC->RECNUM[RECS].P_DOB				= 	FORMAT(P.birth_dt_tm, "dd/mm/YYYY;;d")
				OUTPATIENT_REC->RECNUM[RECS].P_SEX				= 	UAR_GET_CODE_DISPLAY(P.SEX_CD)
				;------ENCOUNTER DETAILS------
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_ID			= 	E.encntr_id
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_TYP			= 	REPLACE(UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CD), ",", ";")
				OUTPATIENT_REC->RECNUM[RECS].P_ENC_ALIAS		= 	EA.alias
				OUTPATIENT_REC->RECNUM[RECS].P_ADMIT_DT			= 	FORMAT(E.arrive_dt_tm, "dd/mm/YYYY - HH:MM;;d")
				OUTPATIENT_REC->RECNUM[RECS].P_DISCH_DT			= 	FORMAT(E.disch_dt_tm, "dd/mm/YYYY - HH:MM;;d")
				OUTPATIENT_REC->RECNUM[RECS].P_MED_UNIT			=	REPLACE(UAR_GET_CODE_DISPLAY(E.MED_SERVICE_CD), ",", ";")
				;------ORDER DETAILS-----
			 	OUTPATIENT_REC->RECNUM[RECS].P_ORDR_ID			= 	O.order_id
 				OUTPATIENT_REC->RECNUM[RECS].P_ORDR_TYPE		= 	REPLACE(O_CATALOG_DISP, ",", ";")
 				OUTPATIENT_REC->RECNUM[RECS].P_ORDR_STA			= 	UAR_GET_CODE_DISPLAY(O.order_status_cd)
 
			WITH NOCOUNTER, SEPARATOR=" ", FORMAT
 
			SET CSV_FILE_NAME = "ALF_OP_INCORRECT_ORD_EXTRACT.csv"
ENDCASE
 
;------- CREATE EXTRACT ------
if ($OUTDEV in ("File", "FILE", "file"))
	set output_loc = build("cust_extracts:",CSV_FILE_NAME )
else
	set output_loc = $1
endif
 
SELECT INTO VALUE(output_loc)
 
 		;PERSONNM = OUTPATIENT_REC->RECNUM[D.SEQ].P_FULL_NM
 
FROM (dummyt d with seq = value(RECS))
 
PLAN D WHERE VALUE(RECS) != 0
 
;ORDER BY
	;PERSONNM
 
HEAD PAGE
 
 		OUTPUT_STR = fillstring(3000, " ")
 
 		OUTPUT_STR = BUILD(OUTPUT_STR,
 						  "MEDICAL RECORD NUMBER", CSV,
						  "FIRST NAME", CSV,
						  "SURNAME", CSV,
						  "DATE OF BIRTH", CSV,
						  "SEX", CSV)
 
		CASE ($exception_sel)
 
			OF "A" :  OUTPUT_STR = BUILD(OUTPUT_STR,
						  				 "TASK DESCRIPTION", CSV,
						  				 "SCHEDULED DATE/TIME", CSV,
				  					  	 "TASK OVERDUE FOR(DAYS)"
						  				 )
 
			OF "B" :
			OF "C" :  OUTPUT_STR = BUILD(OUTPUT_STR,
										 "ORDER DESCRIPTION", CSV,
										 "ORDER STATUS", CSV,
										 "ENCOUNTER TYPE", CSV,
										 "MEDICAL SERVICE", CSV,
										 "ADMIT DATE-TIME", CSV,
										 "DISCHARGE DATE-TIME"
										)
 
 		ENDCASE
 
		COL 0 OUTPUT_STR
		ROW + 1
 
;HEAD PERSONID
DETAIL
 		OUTPUT = ""
		OUTPUT_STR = fillstring(3000, " ")
 
		OUTPUT_STR = BUILD(OUTPUT_STR,
 							OUTPATIENT_REC->RECNUM[D.SEQ].P_ENC_ALIAS, CSV,
							OUTPATIENT_REC->RECNUM[D.SEQ].P_FIRST_NM, CSV,
							OUTPATIENT_REC->RECNUM[D.SEQ].P_LAST_NM, CSV,
							OUTPATIENT_REC->RECNUM[D.SEQ].P_DOB, CSV,
							OUTPATIENT_REC->RECNUM[D.SEQ].P_SEX, CSV
						  )
 
		CASE ($exception_sel)
 
			OF "A" :	OUTPUT_STR = BUILD(	OUTPUT_STR,
											OUTPATIENT_REC->RECNUM[D.SEQ].P_TSK_NAME, CSV,
											OUTPATIENT_REC->RECNUM[D.SEQ].P_TSK_CREATE_DTTM, CSV,
											FORMAT(OUTPATIENT_REC->RECNUM[D.SEQ].P_TSK_OVERDUE, "######")
										  )
 			OF "B" :
			OF "C" :	OUTPUT_STR = BUILD(	OUTPUT_STR,
											OUTPATIENT_REC->RECNUM[D.SEQ].P_ORDR_TYPE, CSV,
											OUTPATIENT_REC->RECNUM[D.SEQ].P_ORDR_STA, CSV,
											OUTPATIENT_REC->RECNUM[D.SEQ].P_ENC_TYP, CSV,
											OUTPATIENT_REC->RECNUM[D.SEQ].P_MED_UNIT, CSV,
											OUTPATIENT_REC->RECNUM[D.SEQ].P_ADMIT_DT, CSV,
											OUTPATIENT_REC->RECNUM[D.SEQ].P_DISCH_DT
										  )
 
 		ENDCASE
 
		COL 0 OUTPUT_STR
		ROW + 1
 
FOOT REPORT
 
	STAT = ALTERLIST(OUTPATIENT_REC->RECNUM,RECS)
 
WITH  MAXCOL = 1200, dio = 0, LANDSCAPE, NOHEADING, NOFORMFEED, FORMAT = VARIABLE
 
;set ftp_filename = "ALF_OP_OVERDUE_TASKS_EXTRACT.csv"
 
;CALL ECHO(CNVTRECTOJSON( OUTPATIENT_REC))
end
go
 
 
 
 
