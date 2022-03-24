/*-------------------------------------------------------------------------------------------------------------------
 
Module 				: ALF_OP_EXCEPTION_EXTRACT
Program Run From 	: OPS SCHEDULER
 
---------------------------------------------------------------------------------------------------------------------
DESCRIPTION 		: CCL TO EXECUTE ALF_OP_TASK_EXCEPTION_EXTRACT.PRG AND THEN SEND IT TO RECIPIENTS VIA EMAIL
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
		000		NEHA NAROTA					24-OCT-2017		INITIAL RELEASE
 		001		NEHA NAROTA					26-OCT-2017		ADDED PROMPTS AND CASE-STATEMENT TO ALLOW FOR SELECTION 
 															OF DIFFERENT EXCEPTION REPORTS
---------------------------------------------------------------------------------------------------------------------*/
 
 
drop program alf_op_exception_extract go
create program alf_op_exception_extract

prompt 
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Exception Report for" = "" 

with OUTDEV, excpt_rpt


;----LOCAL VARIABLES----

DECLARE KSH_SELECT = VC
	SET KSH_SELECT = FILLSTRING(250, " ")

declare dclcom = vc with noconstant("")	


; ------ CASE SELECT ------
	
CASE($excpt_rpt)

	OF "A" :	;---------OVERDUE TASKS----------
			execute ALF_OP_TASK_EXCEPTION_EXTRACT "File", "A"
 			
 			CALL PAUSE (2)
 			
 			set dclcom = concat("$cust_proc/alf_op_overdue_tasks.ksh ", "n.narota@alfred.org.au" )
 	
 	OF "B" :	;---------INCORRECT ENCOUNTER----------
 			execute ALF_OP_TASK_EXCEPTION_EXTRACT "File", "B"
 			
 			CALL PAUSE (2)
 			
 	OF "C" :	;---------INCORRECT ORDER---------	
 			execute ALF_OP_TASK_EXCEPTION_EXTRACT "File", "C"
 			
 			CALL PAUSE (2)	
 			
 			
ENDCASE


/*------ CALL THE SHELL SCRIPT TO SEND THE CSV FILE AS AN ATTACHEMENT ------
		 TO THE INTENDED RECIPIENTS											*/

set status = 0
set len = size(trim(dclcom))
 
call echo(dclcom)
call dcl(dclcom, len, status)
 
end
go
 
