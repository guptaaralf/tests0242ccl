/********************************************************************************
#m     Module                 :  CareNet
*********************************************************************************
#n     Program Common Name    :  ALF_PUMP_REPORT_WARD_EXTRACT.PRG
#n     Porgram Object Name    :  ALF_PUMP_REPORT_WARD_EXTRACT
#n     Program Run From       :  Powerchart
*********************************************************************************
#d     Description            :  This program generates extract for pump reports.
								 it generates a CSV extract for the same data in
								 ALF_LP_PUMP_REPORT_WARD
*********************************************************************************
#a     Site                   :  Alfred Healthcare Group
                                 Commercial Road, Melbourne
                                 Victoria, 3004
                                 Australia
 
#m     Mod #     Author          Date             Description
       -----     --------------- ---------------  -------------------
                 Mohammed Al-Kaf  08 Jan 2018	  Released.
********************************************************************************/
 
drop program alf_pump_report_ward_extract go
create program alf_pump_report_ward_extract
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "From" = "CURDATE"
	, "To" = "CURDATE"
 
with OUTDEV, fdate, tdate
 
 
SELECT into $1
	P.NAME_FULL_FORMATTED
	, T_LOCATION_DISP = UAR_GET_CODE_DISPLAY(T.LOCATION_CD)
	, ea.alias
	, schedule = format(T.SCHEDULED_DT_TM,"DD/MM/YYYY ;;D")
	, issueDate = format(T.ACTIVE_STATUS_DT_TM,"DD/MM/YYYY ;;D")
	, ceaseDate = format(T.updt_dt_tm,"DD/MM/YYYY ;;D")
	, T_TASK_STATUS_DISP = UAR_GET_CODE_DISPLAY(T.TASK_STATUS_CD)
	, od.oe_field_display_value
	, OA_ACTION_TYPE_DISP = UAR_GET_CODE_DISPLAY(OA.ACTION_TYPE_CD)
	, pr.name_full_formatted
	, T_TASK_STATUS_REASON_DISP = UAR_GET_CODE_DISPLAY(T.TASK_STATUS_REASON_CD)
	, od.updt_dt_tm
 
FROM
	TASK_ACTIVITY   T
	, ORDER_DETAIL   OD
	, PERSON   P
	, ENCOUNTER   E
	, ENCNTR_ALIAS   EA
	, order_action   oa
	, prsnl   pr
 
PLAN T
	WHERE T.task_type_cd IN (value(uar_get_code_by('DISPLAY',6026,'Enteral Feed Sandringham'))
							,value(uar_get_code_by('DISPLAY',6026,'Enteral Feed Caulfield'))
							,value(uar_get_code_by('DISPLAY',6026,'Enteral Feed Alfred'))
							)
		and t.task_status_cd not in (value(uar_get_code_by('DISPLAY',79,'Dropped'))
									,value(uar_get_code_by('DISPLAY',79,'Canceled'))
									,value(uar_get_code_by('DISPLAY',79,'Complete')))
 
	and (T.SCHEDULED_DT_TM is not null or ( t.updt_dt_tm  between cnvtdatetime(cnvtdate($fdate),000000) and cnvtdatetime(
cnvtdate($tdate),235959)))
JOIN OD
	WHERE OD.order_id = outerjoin(t.order_id)
		and od.oe_field_id = outerjoin(value(uar_get_code_by('DISPLAY',16449,'AH Enteral Feed Pump Number')))
 
 
			JOIN P
			WHERE T.person_id = P.person_id
 
			JOIN E
			WHERE E.encntr_id = T.encntr_id
			AND E.active_ind = 1
 
			JOIN EA
			WHERE EA.encntr_id = T.encntr_id
			AND EA.encntr_alias_type_cd = 863.00;MRN_CD
			AND EA.active_ind = 1
			AND EA.end_effective_dt_tm > SYSDATE
 
join oa
	where t.order_id = oa.order_id
		and oa.action_type_cd = value(uar_get_code_by('DISPLAY',6003,'Order'))
 
join pr
	where pr.person_id = oa.updt_id
 
ORDER BY
	T_LOCATION_DISP
	, P.NAME_FULL_FORMATTED
	, od.oe_field_display_value
	, T.ACTIVE_STATUS_DT_TM
 
HEAD REPORT
	COL 0 "Ward, Equipment, Contact, Dietitian, Issued Date, Due Date"
	ROW+1
	DS_STR = FILLSTRING(599," ")
	CSV = ","
 
HEAD P.NAME_FULL_FORMATTED
	;do nothing
	temp = 0
 
FOOT od.oe_field_display_value
	DS_STR = CONCAT('"',TRIM(T_LOCATION_DISP),'"',CSV,
					'"',TRIM(od.oe_field_display_value),'"',CSV,
					'"',TRIM(p.name_full_formatted),'"',CSV,
					'"',TRIM(pr.name_full_formatted),'"',CSV,
					'"',TRIM(issueDate),'"',CSV,
					'"',TRIM(ceaseDate),'"')
	COL 0 DS_STR
	ROW+1
 
 
with nocounter, MAXCOL = 600, MAXROW = 1, NOFORMFEED,FORMAT = VARIABLE
 
 
 
end
go
 
