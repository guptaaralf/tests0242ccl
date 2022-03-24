/*******************************************************************************************************************************
#m     Module                 :     PowerChart
#n     Program Common Name    :     alf_src_ffl_enteral_feed.prg
#n     Program Object Name    :     alf_src_ffl_enteral_feed
#n     Program Run From       :     Explorer Menue through a free form label report
********************************************************************************************************************************
#d     Description            :     This Programme is used a driver program for alf_ffl_enteral_feed_3
									It reads data from "Enteral Feed" PowerForm and generate labels based on selected number of
									labels
********************************************************************************************************************************
#a     Site                   :     Alfred Healthcare Group
                                    Commercial Road, Melbourne
                                    Victoria, 3004
                                    Australia
********************************************************************************************************************************
#v     Version                :     Cerner Command Language Version 8.0+++
********************************************************************************************************************************
#m     Modification Control Log
********************************************************************************************************************************
#m		Mod #  	Author                  	Date       	Description
       	-----  	-----------------------  	-------- 	-------------------
               	Jose Sanchez           		UNKNOWN
         001	Mohammed Al-Kaf			  	29/07/2016	PRODUCTION: Reviewed the codesets and added comments to the code
 		 002	Mohammed Al-Kaf				21/09/2017  changed the design to read from orders instead of powerforms
 		 003	Mohammed Al-kaf				02/03/2018	removed the date prompts
********************************************************************************************************************************/
drop program alf_src_ffl_enteral_feed go
create program alf_src_ffl_enteral_feed
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "site" = ""
 
with OUTDEV, site
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare CONTINUOUS_SANDY_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",200,"ENTERALFEEDCONTINUOUSSANDRINGHAM")),protect
declare CONTINUOUS_CAULF_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",200,"ENTERALFEEDCONTINUOUSCAULFIELD")),protect
declare ORDERED_VAR = f8 with Constant(uar_get_code_by("MEANING",6004,"ORDERED")),protect
declare CONTINUOUS_ALFRED_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",200,"ENTERALFEEDCONTINUOUSALFRED")),protect
declare BOLUS_ALFRED_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",200,"ENTERALFEEDBOLUSALFRED")),protect
declare BOLUS_CAULF_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",200,"ENTERALFEEDBOLUSCAULFIELD")),protect
declare BOLUS_SANDY_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",200,"ENTERALFEEDBOLUSSANDRINGHAM")),protect
 
 
 
 
set POOL_VAR = uar_get_code_by( 'DISPLAYKEY', 263, 'ALFREDHEALTH')
set MRN_VAR = uar_get_code_by( 'DISPLAYKEY', 4, 'MRN')
set WARD_VAR = uar_get_code_by( 'DISPLAYKEY', 72, 'NEFWARDCODESET')
 
 
; get the order fields ID
declare unit_var = f8
declare unit_ch_var = f8
declare unit_sh_var = f8
declare product1_var = f8
declare product2_var = f8
declare target_rate_var = f8
declare pump_var = f8
declare instr_var = f8
declare labels_var = f8
declare route_var = f8
declare regime_var = f8
declare feed_var = f8
declare comments_var = f8
declare other_var = f8
declare kitchen_var = f8
 
;set sDate = $2
;set eDate = $3
 
;if(sDate = "31-DEC-2100 00:00:00")
;	set sDate = concat(format(CURDATE-1,'DD-MMM-YYYY ;;D'),' 14:00:00')
;	set eDate = concat(format(CURDATE,'DD-MMM-YYYY ;;D'),' 13:59:59')
;endif
 
 
SELECT
	o.oe_field_id
	, o.description
 
FROM
	ORDER_ENTRY_FIELDS   O
	where o.description in ('AA Generic Referring Unit'
	,'AH Enteral Feed Continuous Product','AH Enteral Feed Bolus Product'
	, 'AH Enteral Feed Route'
	, 'AH Enteral Feed Start Up Regime'
	, 'AH Enteral Feed Target Regime'
	, 'AH Enteral Feed Time'
	, 'AA Social Work RC Contact Details'
	, 'AH Enteral Feed Number of Labels'
	, 'AH Enteral Feed Pump Number'
	, 'AH Enteral Feed Special Comments'
	, 'AH Enteral Feed Other Product'
	, 'AH Enteral Feed Kitchen Instructions'
	, 'AH Enteral Feed Caulfield Referral Area'
	, 'AH Enteral Feed Sandringham Referral Area')
Detail
	case(o.description)
	of 'AA Generic Referring Unit':
		unit_var = o.oe_field_id
	of 'AH Enteral Feed Caulfield Referral Area':
		unit_ch_var = o.oe_field_id
	of 'AH Enteral Feed Sandringham Referral Area':
		unit_sh_var = o.oe_field_id
	of 'AH Enteral Feed Continuous Product':
		product1_var = o.oe_field_id
	of 'AH Enteral Feed Bolus Product':
		product2_var = o.oe_field_id
	of 'AH Enteral Feed Target Regime':
		target_rate_var = o.oe_field_id
	of 'AH Enteral Feed Pump Number':
		pump_var = o.oe_field_id
	of 'AA Social Work RC Contact Details':
		instr_var = o.oe_field_id
	of 'AH Enteral Feed Number of Labels':
		labels_var = o.oe_field_id
	of 'AH Enteral Feed Route':
		route_var = o.oe_field_id
	of 'AH Enteral Feed Start Up Regime':
		regime_var = o.oe_field_id
	of 'AH Enteral Feed Time':
		feed_var = o.oe_field_id
	of 'AH Enteral Feed Special Comments':
		comments_var = o.oe_field_id
	of 'AH Enteral Feed Other Product':
		other_var = o.oe_field_id
	of 'AH Enteral Feed Kitchen Instructions':
		kitchen_var = o.oe_field_id
	endcase
 
with nocounter
 
 
record recs(
	1 labels[*]
		2 person_name = vc
		2 mrn = vc
		2 dob = vc
		2 ward = vc
		2 date = vc
		2 dietitian = vc
		2 unit = vc ;1
		2 product = vc ;2
		2 rate = vc ;3
		2 pump = vc ;4
		2 instructions = vc ;5
		2 no_labels = i4 ;6
		2 curr_label = vc ;6a
		2 type = vc ;7
		2 regime = vc ;8
		2 feedTime = vc ;9
		2 comments = vc ;10
		2 feeding = vc ;10
		2 other = vc
		2 kitchen = vc
)
 
;Counter for labels
declare labels_list_counter = i4
set labels_list_counter = 0
declare temp_counter = i4
set temp_counter = 0
 
declare index_i = i4
set index_i = 0
 
declare site_var = f8
declare site2_var = f8
;check the selected site
case($site)
	of 'A':
		set site_var = CONTINUOUS_ALFRED_VAR
		set site2_var= BOLUS_ALFRED_VAR
	of 'C':
		set site_var = CONTINUOUS_CAULF_VAR
		set site2_var= BOLUS_CAULF_VAR
	of 'S':
		set site_var = CONTINUOUS_SANDY_VAR
		set site2_var= BOLUS_SANDY_VAR
endcase
; Main query
SELECT
	o.ACTIVE_IND
	, o.order_id
	, p.name_full_formatted
	, pa.alias
	, pr.name_full_formatted
	, ordered = format(o.ORIG_ORDER_DT_TM,"@SHORTDATETIME")
	, lastUpdate = format(o.updt_dt_tm,"@SHORTDATETIME")
	, O_CATALOG_DISP = UAR_GET_CODE_DISPLAY(O.CATALOG_CD)
	, O_ORDER_STATUS_DISP = UAR_GET_CODE_DISPLAY(O.ORDER_STATUS_CD)
	, unit = od1.oe_field_display_value
	, E_LOC_NURSE_UNIT_DISP = UAR_GET_CODE_DISPLAY(E.LOC_NURSE_UNIT_CD)
	, od1.action_sequence
	, labels = od2.oe_field_display_value
 
FROM
	orders   o
	, person p
	, prsnl pr
	, person_alias pa
	, encounter e
	, order_detail od1
	, order_detail od2
 
plan o
where o.catalog_cd in (site_var, site2_var)
;and o.updt_dt_tm between cnvtdatetime(sDate) ;date is removed. we will print all
;				and cnvtdatetime(eDate)
and o.order_status_cd in (ORDERED_VAR)
 
join p
where p.person_id = o.person_id
 
join pr
where pr.person_id = o.updt_id
 
join pa
where pa.person_id = p.person_id
	and pa.active_ind = 1
    and pa.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
    and pa.person_alias_type_cd = MRN_VAR
    AND pa.alias_pool_cd =       POOL_VAR
 
join e
where e.encntr_id = o.encntr_id
 
join od1
where outerjoin(o.order_id) = od1.order_id
and od1.oe_field_id  in (unit_var,unit_ch_var,unit_sh_var
					,product1_var
					,product2_var
					,target_rate_var
					,pump_var
					,instr_var
					,route_var
					,regime_var
					,feed_var
					,comments_var
					,other_var
					, kitchen_var)
join od2
where outerjoin(o.order_id) = od2.order_id
and od2.oe_field_id = labels_var ; labels
 
ORDER BY
	 o.order_id
	 , od1.oe_field_id
	 , od2.action_sequence desc
	 , od1.action_sequence desc
 
 
head report
	labels_list_counter = 0
	temp_counter = 0
 
head o.order_id
	if (labels != "" and cnvtint(labels) > 0 )
		; Setting the size to the list
		stat = alterlist(recs->labels, size(recs->labels, 5) +  cnvtint(labels) )
 
		temp_counter = labels_list_counter
 
		for( index_i = 1 to cnvtint(labels) )
			labels_list_counter = labels_list_counter + 1
			recs->labels[labels_list_counter]->person_name = p.name_full_formatted
			recs->labels[labels_list_counter]->mrn = pa.alias
			recs->labels[labels_list_counter]->dob = trim(format(p.birth_dt_tm, "dd/mm/yyyy ;;d"),3)
			recs->labels[labels_list_counter]->ward = trim(E_LOC_NURSE_UNIT_DISP)
			recs->labels[labels_list_counter]->date = trim(format(o.updt_dt_tm,  "dd/mm/yyyy ;;d"),3)
			recs->labels[labels_list_counter]->no_labels = cnvtint(labels)
			recs->labels[labels_list_counter]->curr_label = build2( trim(cnvtstring(index_i)), " of ", labels)
			recs->labels[labels_list_counter]->dietitian = trim(pr.name_full_formatted)
		endfor
	endif
head od1.oe_field_id
	case(od1.oe_field_id)
		of unit_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->unit = trim(od1.oe_field_display_value)
			endfor
		of unit_ch_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->unit = trim(od1.oe_field_display_value)
			endfor
		of unit_sh_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->unit = trim(od1.oe_field_display_value)
			endfor
		of product1_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->product = trim(od1.oe_field_display_value)
				recs->labels[temp_counter+index_i]->feeding = 'cont'
			endfor
		of product2_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->product = trim(od1.oe_field_display_value)
				recs->labels[temp_counter+index_i]->feeding = 'bolus'
			endfor
		of target_rate_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->rate = trim(od1.oe_field_display_value)
			endfor
		of pump_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->pump = trim(od1.oe_field_display_value)
			endfor
		of instr_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->instructions = trim(od1.oe_field_display_value)
			endfor
		of route_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->type = UAR_GET_CODE_DISPLAY(od1.oe_field_value) ; trim(od1.oe_field_display_value)
			endfor
		of regime_var :
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->regime = trim(od1.oe_field_display_value)
			endfor
		of feed_var:
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->feedTime = trim(od1.oe_field_display_value)
			endfor
		of comments_var:
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->comments = trim(od1.oe_field_display_value)
			endfor
		of other_var:
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->other = trim(od1.oe_field_display_value)
			endfor
		of kitchen_var:
			for( index_i = 1 to cnvtint(labels) )
				recs->labels[temp_counter+index_i]->kitchen = trim(od1.oe_field_display_value)
			endfor
	endcase
;foot report
;	stat = alterlist(recs->labels, labels_list_counter)
 
with nocounter
 
;call echo(CNVTRECTOJSON(recs))
;set _Memory_Reply_String = CNVTRECTOJSON(recs)
 
end
go
 
