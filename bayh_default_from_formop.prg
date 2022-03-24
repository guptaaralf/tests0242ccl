/*********************************************************************************************************************************
*
*   Program Run From : Order Processing Script
;*********************************************************************************************************************************
*   Description : 	Based on bayh_default_from_form, but returns items specific for Outpatients
*
;*********************************************************************************************************************************
*   Owner : 		Alfred Health
*					Commercial Road, Melbourne
*					Victoria, 3004
*					Australia
;*********************************************************************************************************************************
*   Modification Control Log
;*********************************************************************************************************************************
*
*	Mod #	Author			Date			Description
*	-----	--------------- -----------		-------------------
* 	001		Steven White	08 JUN 2017		Initial Write (NOT RELEASED)
*	002		Mohammed Alkaf	29 JUN 2017		added a codeset. Also, fixed a bug with event_end_dt_tm in case the form is saved
*											before it gets signed. Also, note that if the order field got a default value.
*											It wont be updated.
* 	003		Mohammed Alkaf	25 JUL 2017		added two more OE Format Fields
	004		Mohammed Alkaf	27 JUL 2017		added more fields
 
*********************************************************************************************************************************/
 
DROP   PROGRAM bayh_default_from_formop GO
CREATE PROGRAM bayh_default_from_formop
 
RECORD REPLY (
	1  ORDERCHANGEFLAG = I2
	1  ORDERID         = F8
	1  DETAILLIST[*]
		2  OEFIELDID           = F8
		2  OEFIELDVALUE        = F8
		2  OEFIELDDISPLAYVALUE = VC
		2  OEFIELDDTTMVALUE    = DQ8
		2  OEFIELDMEANINGID    = F8
		2  VALUEREQUIREDIND    = I2
%i cclsource:status_block.inc
)
SET REPLY->STATUS_DATA->STATUS = "Z"
;*********************************************************************************************************************************
;*	Constant and Variable Declarations
;*********************************************************************************************************************************
 
declare eventCd = f8 with noconstant(0)
declare i = i4 with noconstant(1)
declare j = i4 with noconstant(0)
declare oevalue = f8 with noconstant(0)
declare oedisplay = vc with noconstant("")
declare oefielddttmvalue = dq8 with noconstant(0)
 
; sometimes, cycleing is needed. In order to ensure the latest CCL is executed. Change the email subject.
call uar_send_mail(nullterm("m.alkaf@alfred.org.au"),
	nullterm("REQUEST 101010"),
	nullterm(cnvtrectojson(REQUEST)),
	nullterm("bayh_default_from_formop@alfred.org.au"),
	1,
	nullterm("IPM.NOTE")
	)
 
 
FOR (i = 1 to size(REQUEST->DETAILLIST, 5))
	set eventCd = 0 ; Mohammed: not sure why not setting this to zero
	IF (REQUEST->DETAILLIST[i]->OEFIELDDISPLAYVALUE <= " ")
		CASE (REQUEST->DETAILLIST[i].OEFIELDID)
		OF 707337.00 	: SET eventCd = uar_get_code_by("DISPLAYKEY", 72, "OPREASONFORVISIT")
		OF 863579.00 	: SET eventCd = uar_get_code_by("DISPLAYKEY", 72, "OPLANGUAGE") ;mod 002
		OF 11469010.00 	: SET eventCd = uar_get_code_by("DISPLAYKEY", 72, "ORTHOCLINICCONSULTANT") ;mod 003
		OF 9869660.00 	: SET eventCd = uar_get_code_by("DISPLAYKEY", 72, "NEUROSURGERYCLINICIANS") ;mod 003
		OF 98062850.00 	: SET eventCd = uar_get_code_by("DISPLAYKEY", 72, "NEUROSURGERYPHYSIOCLINICS")
		OF 16594893.00	: SET eventCd = uar_get_code_by("DISPLAYKEY", 72, "RHEUMATOLOGYCLINIC") ;mod 003
		of 156584706.00	: set eventCd = uar_get_code_by("DISPLAYKEY", 72, "OPENTCLINDAYS") ;mod 005
		of 9517845.00	: SET eventCd = uar_get_code_by("DISPLAYKEY", 72, "OPCLINICPRIORITY")
		of 61124423.00  : SET eventCd = uar_get_code_by("DISPLAYKEY", 72, "OPALTERNATEUNIT")
		; mod 004 this is a special case as the DTA is not an online codeset
 
		ENDCASE
	ENDIF
 	IF (eventCd > 0)
 	/*	;becareful, this will flood your email
 	call uar_send_mail(nullterm("m.alkaf@alfred.org.au"),
	nullterm("FOUND"),
	nullterm(cnvtstring(eventCD)),
	nullterm("bayh_default_from_formop@alfred.org.au"),
	1,
	nullterm("IPM.NOTE")
	)
	*/
		set stat = getEventValue(eventCd)
		IF (oevalue >= 0)
			set j += 1
			set stat = alterlist(REPLY->DETAILLIST, j)
			set REPLY->STATUS_DATA->STATUS = "S"
			set REPLY->DETAILLIST[j].OEFIELDID = REQUEST->DETAILLIST[i].OEFIELDID
			set REPLY->ORDERCHANGEFLAG = 1
			set REPLY->ORDERID = REQUEST->ORDERID
			set REPLY->DETAILLIST[j].OEFIELDVALUE = oevalue
			set REPLY->DETAILLIST[j].OEFIELDDISPLAYVALUE = oedisplay
			set REPLY->DETAILLIST[j].OEFIELDDTTMVALUE = oefielddttmvalue
		ENDIF
	ENDIF
ENDFOR
 
SUBROUTINE getEventValue(eventCd)
	call echo(BUILD("Getting event code: ", eventCd))
	declare inerror_cd = f8 with constant(uar_get_code_by("MEANING", 8, "INERROR"))
	declare powerform_cd = f8 with constant(uar_get_code_by("MEANING", 29520, "POWERFORMS"))
	set oevalue = -1.0
	set oedisplay = ""
	set oefielddttmvalue = 0
 
	SELECT INTO "NL:"
	FROM CLINICAL_EVENT CE,
		CE_CODED_RESULT CCR,
		CE_DATE_RESULT CDR
	PLAN CE WHERE
		CE.person_id = REQUEST->PERSONID AND
		CE.event_cd = eventCd AND
		CE.view_level = 1 AND
		CE.publish_flag = 1 AND
		CE.valid_until_dt_tm > sysdate AND
		CE.entry_mode_cd = powerform_cd AND
		;CE.event_end_dt_tm >= cnvtlookbehind("5, MIN", sysdate) AND
		CE.updt_dt_tm >= cnvtlookbehind("5, MIN", sysdate) AND ;mod 002
		CE.authentic_flag = 1
	JOIN CCR WHERE
		CCR.event_id = OUTERJOIN(CE.event_id) AND
		CCR.valid_until_dt_tm > OUTERJOIN(sysdate)
	JOIN CDR WHERE
		CDR.event_id = OUTERJOIN(CE.event_id) AND
		CDR.valid_until_dt_tm > OUTERJOIN(sysdate)
	ORDER BY CE.event_end_dt_tm DESC
	HEAD REPORT
		REPLY->STATUS_DATA->STATUS = "S"
		IF (CCR.event_id > 0)
			oevalue = CCR.result_cd
			oedisplay = CE.result_val
			if(oeValue = 0)
			;mod 004
				case (CE.result_val)
				of 'P1 (1-2 weeks)':
					oedisplay = '1 Urgent 1-2 Weeks'
					oeValue = uar_get_code_by("DESCRIPTION",100595,oedisplay); 9517885 ;not sure of there is a UAR function
				of 'P2 (3-4 weeks)':
					oedisplay = '2 Soon 3-6 Weeks'
					oeValue = uar_get_code_by("DESCRIPTION",100595,oedisplay);
				of 'P3 (5 weeks - 12 months)':
					oedisplay = '3 Intermediate 6 Weeks to 3 Months'
					oeValue = uar_get_code_by("DESCRIPTION",100595,oedisplay);
				else
					oeValue = uar_get_code_by("DESCRIPTION",100400,oedisplay)
				endcase
			endif
		ELSEIF (CDR.event_id > 0)
			oefielddttmvalue = CDR.result_dt_tm
			oevalue = 0
			CASE (CDR.date_type_flag)
			OF 1: oedisplay = format(CDR.result_dt_tm, "@SHORTDATE4YR")
			OF 2: oedisplay = format(CDR.result_dt_tm, "@TIMENOSECONDS")
			ELSE oedisplay = format(CDR.result_dt_tm, "@SHORTDATETIMENOSEC")
			ENDCASE
		ELSE
			oedisplay = CE.result_val
			oevalue = 0
		ENDIF
	WITH NOCOUNTER
	RETURN (0)
END ;getEventValue
 
call uar_send_mail(nullterm("m.alkaf@alfred.org.au"),
	nullterm("REPLY 100"),
	nullterm(cnvtrectojson(REPLY)),
	nullterm("bayh_default_from_formop@alfred.org.au"),
	1,
	nullterm("IPM.NOTE")
	)
 
END GO
 
