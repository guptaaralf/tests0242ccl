/*****************************************************************************************************************************
#m     Module                 :     CareNet
*****************************************************************************************************************************
#n     Program Common Name    :     BAYH_STAT_EXTNEW.PRG
#n     Program Object Name    :     BAYH_STAT_EXTNEW
#n     Program Run From       :     Explorer Menu
*****************************************************************************************************************************
#d     Description            :     This program generates a STAT extract for CCHS for a date range.
#d
*****************************************************************************************************************************
#a     Site                   :     Alfred Healthcare Group
                                    Commercial Road, Melbourne
                                    Victoria, 3004
                                    Australia
*****************************************************************************************************************************
#v     Version                :     Cerner Command Language Version 7.8
*****************************************************************************************************************************
#m     Modification Control Log
*****************************************************************************************************************************
#m     Mod #     By                 Date            Description
       -----     -----------------  --------------  -------------------------------------------------------------------------
                 John Everts        30/06/2011      New release based on bayh_stat_extnew.
       001       John Everts        24/04/2012      Add event details that are entered on action of check out.
       002       John Everts        02/05/2012      Add podiatry, non-client and group appointment types.
       003       John Everts        02/08/2012      Add health promotion strategy from event details.
       004       Phuong Pham        30/10/2012      Change FTP code to Linux.
       005       John Everts        10/05/2013      Change CGPDTY appointment type to CGPOD.
       006       John Everts        22/06/2013      Add option to run for previous week
       007       John Everts        29/10/2013      Add Appt Location and Indirect Tasks
       008       Karel Young        27/05/2015      Added new Universal MRN components to the code
       009       Dylan McCarthy     02/07/2015      Updated End Effective Date for PERSON_ALIAS
 	   010		 Neha Narota		06/12/2016		Changes for 100777
 	   												1) File should be written to FTP when input date is either 31/12/2100(monthly)
 	   												   or 30/12/2100(weekly)
 	   												2) Weekly extract runs on every MONDAY.
 	   011       Neha Narota		20/12/2017	    140527 - Append E Receipt details from Checkin
****************************************************************************************************************************/
 
DROP   PROGRAM CGCCHS_STAT_EXT:dba GO
CREATE PROGRAM CGCCHS_STAT_EXT:dba
 
prompt
	"Output to File/Printer/MINE" = "MINE"                        ;* File is a file on VMS backend
	, "Enter Start Date" = "CURDATE"
	, "Enter End Date" = "CURDATE"
	, "Enter Full Directory Path" = "AlliedHealth/CGMC_AH/CCHS"   ;* i.e.,where output file is to go. (if run via scheduler) eg Al
 
with prompt1, prompt2, prompt3, prompt4
 
set resline           = fillstring(3000," ")
set delim             = char(9)
set LF                = char(10)
set CR                = char(13)
set i                 = 0
set match             = 0
set no_of_rows        = 0
declare temp_str      = vc
declare dest_path     = vc
declare last_cd       = f8
declare add_resources = vc
declare cchs_fee      = vc
declare prev_cchs_fee = vc
declare change_found  = vc
declare temp_time     = vc
set dest_path         = trim($4)
set clinic_name       = fillstring(20," ")
set output_name       = fillstring(20," ")
 
 
if (cnvtdate($2,E) = cnvtdate("31122100",E))
;  Run for previous month
   set this_day   = day(curdate) ;get the day of the current month.
   set start_date = cnvtdate2(format(curdate - this_day,"01mmyyyy;;d"),"ddmmyyyy")
   set end_date   = curdate - this_day
 
   if (month(start_date) <= 9)
      set Xmonth = concat("0",cnvtstring(month(start_date),2))
   else
      set Xmonth = cnvtstring(month(start_date),2)
   endif
 
   set Xyear      = cnvtstring(year(start_date),4)
   set output_loc = build("cust_extracts:CCHS_MTHLY_",XMonth,Xyear,".txt")
   set ftp_filename = cnvtlower(build("CCHS_MTHLY_",XMonth,Xyear,".txt"))
   set ftp_pathname = cnvtlower(trim($4))
else
   if (cnvtdate($2,E) = cnvtdate("30122100",E))
   ;  Run on Tuesday for previous week
      set start_date   = curdate - 7
      set end_date     = curdate - 1
      set output_loc   = build("cust_extracts:CCHS_WKLY_", format(end_date, "ddmmyy;;d"), ".txt")
      set ftp_filename = cnvtlower(build("CCHS_WKLY_", format(end_date, "ddmmyy;;d"),".txt"))
      set ftp_pathname = cnvtlower(trim($4))
   else
      set output_loc = $1
      set start_date = cnvtdate($2,E)
      set end_date   = cnvtdate($3,E)
   endif
endif
 
set checkin_cd    = 0
set checkout_cd   = 0
set confirmed_cd  = 0
set cancel_cd     = 0
set reschedule_cd = 0
 
select into "nl:"
   from code_value c
   where c.code_set   = 14233
   and   c.active_ind = 1
   and   c.display_key in ("CONFIRMED", "CHECKEDIN", "CHECKEDOUT", "CANCELED", "RESCHEDULED")
   detail
      case (c.display_key)
         of "CONFIRMED"  : confirmed_cd  = c.code_value
         of "CHECKEDIN"  : checkin_cd    = c.code_value
         of "CHECKEDOUT" : checkout_cd   = c.code_value
         of "CANCEL"     : cancel_cd     = c.code_value
         of "RESCHEDULE" : reschedule_cd = c.code_value
      endcase
with nocounter
 
declare nbr_appts = I4
set     nbr_appts = 0
 
free record apptinfo
 
record apptinfo
( 1 appt_data[*]
    2 sch_event_id     = f8
    2 schedule_id      = f8
    2 encntr_id        = f8
    2 oe_format_id     = f8
    2 schedule_date    = dq8
    2 duration         = i4
    2 dur_hours        = c10
    2 ah_mrn          = c7
    2 alf_mrn          = c7
    2 cgmc_mrn         = c7
    2 sdmh_mrn         = c7
    2 pat_name         = vc
    2 pat_gender       = vc
    2 pat_age          = vc
    2 pat_dob          = vc
    2 pat_country      = vc
    2 pat_address1     = vc
    2 pat_address2     = vc
    2 pat_address3     = vc
    2 pat_suburb       = vc
    2 pat_pcode        = vc
    2 pat_indig_stat   = vc
    2 pat_preflang     = vc
    2 appt_type        = vc
    2 appt_location    = vc
    2 nbr_res          = i2
    2 appt_status      = vc
    2 action_date      = dq8
    2 action_prsnl     = vc
    2 cancel_reason    = vc
    2 service_type     = vc
    2 health_strategy  = vc
    2 fin_class        = vc
    2 fin_prsnl        = vc
    2 fin_date         = vc
    2 prev_fin         = vc
    2 change_found     = vc
    2 car_pool_zone    = vc
    2 wagon_sedan      = vc
    2 new_review       = vc
    2 service_type     = vc
    2 cchs_fee         = vc
    2 int_required     = vc
    2 language         = vc
    2 int_location     = vc
    2 int_loc_oc       = vc
    2 int_contact      = vc
    2 int_type         = vc
    2 priority         = vc
    2 status           = vc
    2 resources[10]
      3 Resource       = vc
      3 Resource_cd    = f8
    2 add_resources    = vc
    2 stream           = vc
    2 grpsession_id    = f8
    2 funding_stream   = vc
    2 location         = vc
    2 direct_cont_tm   = vc
    2 indirect_cont_tm = vc
    2 travel_time      = vc
    2 indirect_tasks   = vc
    2 e_receipt		   = vc)   ;MOD 11
 
declare temp_appts = i4
set     temp_appts = 0
 
free record tempinfo
 
record tempinfo
( 1 temp_data[*]
    2 sch_event_id   = f8
    2 schedule_id    = f8
    2 encntr_id      = f8
    2 oe_format_id   = f8
    2 schedule_date  = dq8
    2 duration       = i4
    2 dur_hours      = c10
    2 ah_mrn        = c7
    2 alf_mrn        = c7
    2 cgmc_mrn       = c7
    2 sdmh_mrn       = c7
    2 pat_name       = vc
    2 pat_gender     = vc
    2 pat_age        = vc
    2 pat_dob        = vc
    2 pat_country    = vc
    2 pat_address1   = vc
    2 pat_address2   = vc
    2 pat_address3   = vc
    2 pat_suburb     = vc
    2 pat_pcode      = vc
    2 pat_indig_stat = vc
    2 pat_preflang   = vc
    2 appt_type      = vc
    2 appt_location  = vc)
 
declare alf_mrn_cd    = f8
declare cgmc_mrn_cd   = f8
declare sdmh_mrn_cd   = f8
declare cchs_cd       = f8
declare nonclient_cd  = f8
declare pdty_cd       = f8
declare cchs_str      = vc
declare nonclient_str = vc
declare pdty_str      = vc
declare home_addr_cd  = f8
 
set alf_mrn_cd    = uar_get_code_by("DISPLAYKEY", 263,   "ALFREDURNUMBERPOOL")
set cgmc_mrn_cd   = uar_get_code_by("DISPLAYKEY", 263,   "CGMCURPOOL")
set sdmh_mrn_cd   = uar_get_code_by("DISPLAYKEY", 263,   "SDMHURNUMBERPOOL")
set cchs_cd       = uar_get_code_by("DISPLAYKEY", 14230, "CCHSCLIENT")
set nonclient_cd  = uar_get_code_by("DISPLAYKEY", 14230, "CCHSNONCLIENT")
set pdty_cd       = uar_get_code_by("DISPLAYKEY", 14230, "CGPOD")
set home_addr_cd  = uar_get_code_by("DISPLAYKEY", 212,   "HOME")
set cchs_str      = cnvtstring(cchs_cd)
set nonclient_str = cnvtstring(nonclient_cd)
set pdty_str      = cnvtstring(pdty_cd)
 
DECLARE ah_pool_cd = F8
SET newPAS = UAR_GET_DEFINITION(uar_get_code_by("DISPLAYKEY", 101018, "NEWPAS"))
if(newPAS = "YES")
	set ah_pool_cd = uar_get_code_by("DISPLAYKEY", 263, "ALFREDHEALTH")
else
	set ah_pool_cd = -1
ENDIF
 
set appt_code_str = fillstring(400," ")
set first_value   = 1
 
select into "nl:"
      cv.code_value
from  code_value cv
where cv.code_set = 14230
and   cv.display_key = "CCHSGROUP*"
detail
   if (first_value = 1)
      appt_code_str = build(cchs_str, ",", nonclient_str, ",", pdty_str, ",", cnvtstring(cv.code_value))
      first_value   = 0
   else
      appt_code_str = build(appt_code_str, ",", cnvtstring(cv.code_value))
   endif
with nocounter
 
;******************************************
;**** Get Initial List of Appointments ****
;******************************************
 
set grpsession_flg = 0
set nbr_res        = 1
 
select into  "nl:"
 
from sch_appt          s
   , sch_event         se
   , sch_event_patient sep
   , person            p
   , person_alias      pa
   , address           ad
 
plan s
   where s.beg_dt_tm >= cnvtdatetime(start_date,000000)
   and   s.beg_dt_tm <= cnvtdatetime(end_date,235959)
   and   s.role_meaning in ("GRPSROLE","RESOURCE")
   and   s.resource_cd != 74067585  ;Foreign films
 
join se
   where s.sch_event_id  = se.sch_event_id
;   and  se.appt_type_cd = cchs_cd
   and   findstring(cnvtstring(se.appt_type_cd), appt_code_str) > 0
 
join sep
   where outerjoin(s.sch_event_id)     = sep.sch_event_id
   and   sep.version_dt_tm >= outerjoin(cnvtdatetime("31-dec-2100 00:00:00.00"))
  ; and sep.person_id =    39011748.00
 
join p
   where outerjoin(sep.person_id) = p.person_id
 
join pa
   where outerjoin(p.person_id)  = pa.person_id
;   and   pa.alias_pool_cd        in (alf_mrn_cd, cgmc_mrn_cd, sdmh_mrn_cd, ah_pool_cd)
   and   pa.end_effective_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))
   and   pa.active_ind           = outerjoin(1)
 
join ad
   where outerjoin(p.person_id) = ad.parent_entity_id
   and   ad.parent_entity_name  = outerjoin("PERSON")
   and   ad.address_type_cd     = outerjoin(home_addr_cd)
   and   ad.active_ind          = outerjoin(1)
   and   ad.address_type_seq    = outerjoin(1)
 
order by
   s.sch_event_id
  ,s.schedule_id
  ,s.beg_dt_tm
 
head s.sch_event_id
 
  temp_appts = temp_appts + 1
  if (mod(temp_appts,10) = 1)
    stat = alterlist(tempinfo->temp_data,temp_appts + 9)
  endif
 
  tempinfo->temp_data[temp_appts].ah_mrn       = " "
  tempinfo->temp_data[temp_appts].alf_mrn      = " "
  tempinfo->temp_data[temp_appts].cgmc_mrn     = " "
  tempinfo->temp_data[temp_appts].sdmh_mrn     = " "
  tempinfo->temp_data[temp_appts].pat_address1 = ad.street_addr
  tempinfo->temp_data[temp_appts].pat_address2 = ad.street_addr2
  tempinfo->temp_data[temp_appts].pat_address3 = ad.street_addr3
  tempinfo->temp_data[temp_appts].pat_suburb   = ad.city
  tempinfo->temp_data[temp_appts].pat_pcode    = ad.zipcode
 
detail
 
  case (pa.alias_pool_cd)
     of ah_pool_cd  : tempinfo->temp_data[temp_appts].ah_mrn   = format(pa.alias,"#######;P0")
     of alf_mrn_cd  : tempinfo->temp_data[temp_appts].alf_mrn  = format(pa.alias,"#######;P0")
     of cgmc_mrn_cd : tempinfo->temp_data[temp_appts].cgmc_mrn = format(pa.alias,"#######;P0")
     of sdmh_mrn_cd : tempinfo->temp_data[temp_appts].sdmh_mrn = format(pa.alias,"#######;P0")
  endcase
 
foot s.sch_event_id
 
   tempinfo->temp_data[temp_appts].schedule_date  = s.beg_dt_tm
   tempinfo->temp_data[temp_appts].duration       = cnvtint(s.duration)
   tempinfo->temp_data[temp_appts].dur_hours      = format((s.duration / 60.0),"###.##")
   tempinfo->temp_data[temp_appts].appt_type      = trim(se.appt_synonym_free)
   tempinfo->temp_data[temp_appts].appt_location  = trim(uar_get_code_display(s.appt_location_cd))
   tempinfo->temp_data[temp_appts].pat_name       = trim(p.name_full_formatted)
   tempinfo->temp_data[temp_appts].pat_gender     = trim(uar_get_code_display(p.sex_cd))
   tempinfo->temp_data[temp_appts].pat_preflang   = trim(uar_get_code_display(p.language_cd))
   tempinfo->temp_data[temp_appts].pat_country    = trim(uar_get_code_display(p.ethnic_grp_cd))
   tempinfo->temp_data[temp_appts].pat_indig_stat = trim(uar_get_code_display(p.race_cd))
   tempinfo->temp_data[temp_appts].pat_dob        = format(p.birth_dt_tm,"dd/mm/yyyy;;d")
   tempinfo->temp_data[temp_appts].pat_age        = trim(cnvtage(p.birth_dt_tm))
   tempinfo->temp_data[temp_appts].sch_event_id   = s.sch_event_id
   tempinfo->temp_data[temp_appts].schedule_id    = s.schedule_id
   tempinfo->temp_data[temp_appts].oe_format_id   = se.oe_format_id
 
Foot report
 
    stat = alterlist(tempinfo->temp_data, temp_appts)
 
with nocounter
 
; ***********************
; **** Get Resources ****
; ***********************
 
select into  "nl:"
     appt_dt_tm = tempinfo->temp_data[d1.seq].schedule_date
 
from (dummyt d1 with seq = value(temp_appts))
   , sch_appt  s
 
plan d1
 
join s
   where s.sch_event_id = tempinfo->temp_data[d1.seq].sch_event_id
   and   s.schedule_id  = tempinfo->temp_data[d1.seq].schedule_id
   and   s.role_meaning in ("GRPSROLE","RESOURCE")
   and   s.resource_cd != 74067585 ;Foreign films
 
order by
   appt_dt_tm
  ,s.sch_event_id
  ,s.schedule_id
  ,s.resource_cd
 
Head s.sch_event_id
 
   nbr_appts = nbr_appts + 1
   if (mod(nbr_appts, 10) = 1)
      stat = alterlist(apptinfo->appt_data, nbr_appts + 9)
   endif
 
   hold_res_cd = 0.00
   nbr_res     = 1
   grp_res     = "N"
 
   for (i = 1 to 10)
      apptinfo->appt_data[nbr_appts]->resources[i].resource = ""
   endfor
 
   resource_role_disp = trim(uar_get_code_display(s.sch_role_cd))
 
   if (s.role_meaning = "GRPSROLE") ; collecting resources from Grp Session
      nbr_res = 0
      grp_res = "Y"
   else
      apptinfo->appt_data[nbr_appts]->resources[1].resource = uar_get_code_display(s.resource_cd)
   endif
 
   apptinfo->appt_data[nbr_appts].nbr_res       = nbr_res
   apptinfo->appt_data[nbr_appts].grpsession_id = 0
 
   if (s.grpsession_id > 0)
      grpsession_flg = 1
      grp_res        = "Y"
      apptinfo->appt_data[nbr_appts].grpsession_id = s.grpsession_id
   endif
 
foot s.sch_event_id
 
   apptinfo->appt_data[nbr_appts].schedule_date  = tempinfo->temp_data[d1.seq].schedule_date
   apptinfo->appt_data[nbr_appts].duration       = tempinfo->temp_data[d1.seq].duration
   apptinfo->appt_data[nbr_appts].dur_hours      = tempinfo->temp_data[d1.seq].dur_hours
   apptinfo->appt_data[nbr_appts].appt_type      = tempinfo->temp_data[d1.seq].appt_type
   apptinfo->appt_data[nbr_appts].appt_location  = tempinfo->temp_data[d1.seq].appt_location
   apptinfo->appt_data[nbr_appts].pat_name       = tempinfo->temp_data[d1.seq].pat_name
   apptinfo->appt_data[nbr_appts].pat_gender     = tempinfo->temp_data[d1.seq].pat_gender
   apptinfo->appt_data[nbr_appts].pat_preflang   = tempinfo->temp_data[d1.seq].pat_preflang
   apptinfo->appt_data[nbr_appts].pat_address1   = tempinfo->temp_data[d1.seq].pat_address1
   apptinfo->appt_data[nbr_appts].pat_address2   = tempinfo->temp_data[d1.seq].pat_address2
   apptinfo->appt_data[nbr_appts].pat_address3   = tempinfo->temp_data[d1.seq].pat_address3
   apptinfo->appt_data[nbr_appts].pat_suburb     = tempinfo->temp_data[d1.seq].pat_suburb
   apptinfo->appt_data[nbr_appts].pat_pcode      = tempinfo->temp_data[d1.seq].pat_pcode
   apptinfo->appt_data[nbr_appts].pat_country    = tempinfo->temp_data[d1.seq].pat_country
   apptinfo->appt_data[nbr_appts].pat_indig_stat = tempinfo->temp_data[d1.seq].pat_indig_stat
   apptinfo->appt_data[nbr_appts].pat_dob        = tempinfo->temp_data[d1.seq].pat_dob
   apptinfo->appt_data[nbr_appts].pat_age        = tempinfo->temp_data[d1.seq].pat_age
   apptinfo->appt_data[nbr_appts].sch_event_id   = tempinfo->temp_data[d1.seq].sch_event_id
   apptinfo->appt_data[nbr_appts].schedule_id    = tempinfo->temp_data[d1.seq].schedule_id
   apptinfo->appt_data[nbr_appts].oe_format_id   = tempinfo->temp_data[d1.seq].oe_format_id
   apptinfo->appt_data[nbr_appts].ah_mrn         = tempinfo->temp_data[d1.seq].ah_mrn
   apptinfo->appt_data[nbr_appts].alf_mrn        = tempinfo->temp_data[d1.seq].alf_mrn
   apptinfo->appt_data[nbr_appts].cgmc_mrn       = tempinfo->temp_data[d1.seq].cgmc_mrn
   apptinfo->appt_data[nbr_appts].sdmh_mrn       = tempinfo->temp_data[d1.seq].sdmh_mrn
   apptinfo->appt_data[nbr_appts].add_resources  = ""
 
foot report
 
   stat = alterlist(apptinfo->appt_data, nbr_appts)
 
with nocounter
 
; ********************************
; **** Get Appointment Status ****
; ********************************
 
select into "nl:"
 
from (dummyt d1 with seq = value(nbr_appts)),
      sch_appt         s,
      sch_event_action sea,
      prsnl            p
 
plan d1
 
join s where  s.sch_event_id = apptinfo->appt_data[d1.seq].sch_event_id
       and    s.schedule_id  = apptinfo->appt_data[d1.seq].schedule_id
;       and    s.role_meaning = "PATIENT"
 
join sea where s.sch_event_id = sea.sch_event_id
         and   s.schedule_id  = sea.schedule_id
         and   sea.sch_action_id > 0
         and   sea.action_meaning != "VIEW"
 
join p where sea.action_prsnl_id = p.person_id
       and   p.active_ind        = 1
 
order by s.candidate_id,
         cnvtdatetime(s.beg_dt_tm),
         sea.candidate_id
 
foot s.sch_event_id
 
   apptinfo->appt_data[d1.seq].appt_status  = trim(uar_get_code_display(s.sch_state_cd))
   apptinfo->appt_data[d1.seq].action_date  = sea.action_dt_tm
   apptinfo->appt_data[d1.seq].action_prsnl = p.name_full_formatted
   apptinfo->appt_data[d1.seq].encntr_id    = s.encntr_id
 
with nocounter
 
; *******************************
; **** Get Fee & Fee Changes ****
; *******************************
 
select into "nl:"
 
from (dummyt d1 with seq = value(nbr_appts)),
      encounter             e,
      encntr_financial_hist efh,
      prsnl                 p
 
plan d1
 
join e where e.encntr_id = apptinfo->appt_data[d1.seq].encntr_id
       and   e.encntr_id > 0
 
join efh where e.encntr_financial_id = efh.encntr_financial_id
         and   e.encntr_id           = efh.encntr_id
 
join p where efh.updt_id = p.person_id
 
order by d1.seq,
         efh.encntr_fin_hist_id desc
 
head d1.seq
 
   prev_cchs_fee = ""
   change_found  = "No"
   no_of_rows    = 0
 
head efh.encntr_fin_hist_id
 
   no_of_rows = no_of_rows + 1
 
   if (no_of_rows = 1)
      cchs_fee      = trim(uar_get_code_display(efh.financial_class_cd))
      prev_cchs_fee = trim(uar_get_code_display(efh.financial_class_cd))
      apptinfo->appt_data[d1.seq].fin_class = trim(uar_get_code_display(efh.financial_class_cd))
      apptinfo->appt_data[d1.seq].fin_prsnl = p.name_full_formatted
      apptinfo->appt_data[d1.seq].fin_date  = format(efh.transaction_dt_tm, "dd/mm/yyyy hh:mm;;d")
   else
      if (change_found = "No" and trim(uar_get_code_display(efh.financial_class_cd)) != prev_cchs_fee)
         if (trim(uar_get_code_display(efh.financial_class_cd)) != "")
            prev_cchs_fee = trim(uar_get_code_display(efh.financial_class_cd))
            change_found  = "Yes"
         endif
      endif
   endif
 
foot d1.seq
 
   if (change_found = "No")
      apptinfo->appt_data[d1.seq].fin_prsnl = ""
      apptinfo->appt_data[d1.seq].fin_date  = ""
   endif
 
   apptinfo->appt_data[d1.seq].prev_fin     = prev_cchs_fee
   apptinfo->appt_data[d1.seq].change_found = change_found
 
with nocounter
 
; ********************************
; **** Fetch group resources  ****
; ********************************
 
if (grpsession_flg = 1)
   ; need to find extra resources, if there are any group sessions being reported
   select into "nl:"
      grpsess = apptinfo->appt_data[d1.seq].grpsession_id
   from (dummyt d1 with seq = value(nbr_appts)),
      sch_appt s
   plan d1 where  apptinfo->appt_data[d1.seq].grpsession_id > 0
   join s
      where  s.grpsession_id = apptinfo->appt_data[d1.seq].grpsession_id
      and    s.role_meaning  = "RESOURCE"
      and    s.active_ind    = 1
   order by d1.seq,
            s.grpsession_id,
            s.resource_cd
   head d1.seq
      last_cd = 0
   detail
   	if (s.resource_cd > 0)
      if (s.resource_cd != last_cd and s.resource_cd != apptinfo->appt_data[d1.seq]->Resources[1].resource_cd)
         nbr_res = apptinfo->appt_data[d1.seq].nbr_res
         nbr_res = nbr_res + 1
         apptinfo->appt_data[d1.seq].nbr_res                       = nbr_res
         apptinfo->appt_data[d1.seq]->resources[nbr_res].resource  = trim(uar_get_code_display(s.resource_cd))
         last_cd = s.resource_cd
      endif
   endif
   with nocounter
endif
 
/* ---------------------------------------------------------------------------
	Mod # 11 : added query to fetch E-receipt details for appointments
			   in Checked In status
---------------------------------------------------------------------------- */
 
SELECT event_id = apptinfo->appt_data[d1.seq].sch_event_id
 
FROM (dummyt d1 with seq = value(nbr_appts))
	, SCH_EVENT_ACTION   SE
	, SCH_EVENT_DETAIL   S
	, OE_FORMAT_FIELDS   O
 
plan d1
 
join se
where se.sch_event_id = apptinfo->appt_data[d1.seq].sch_event_id
and se.active_ind = 1
and se.end_effective_dt_tm > sysdate
 
join s
where s.sch_event_id =  se.sch_event_id
and s.sch_action_id =   se.sch_action_id
and s.active_ind = 1
 
join o
where o.oe_field_id = s.oe_field_id
and o.oe_field_id = 201120161
and o.oe_format_id = apptinfo->appt_data[d1.seq].oe_format_id
 
order by event_id
 
detail
 
	if((apptinfo->appt_data[d1.seq].appt_status = "Checked In") and (trim(o.label_text) = "E Receipt Fee"))
   		apptinfo->appt_data[d1.seq].e_receipt = s.oe_field_display_value
    endif
 
WITH nocounter
 
 
; ***************************************
; ******** Report data collected ********
; ***************************************
 
select into value(output_loc)
    appt_date = apptinfo->appt_data[d1.seq].schedule_date
 
from (dummyt d1 with seq = value(nbr_appts))
  ,  sch_event_detail sed
  ,  oe_format_fields oef
 
plan d1
 
join sed
   where sed.sch_event_id   = apptinfo->appt_data[d1.seq]->sch_event_id
   and   sed.active_ind     = 1
   and   sed.version_dt_tm >= cnvtdatetime("31-dec-2100 00:00:00.00")
 
join oef
   where sed.oe_field_id  = oef.oe_field_id
   and   oef.oe_format_id = apptinfo->appt_data[d1.seq]->oe_format_id
 
order by appt_date
 
Head Report
    resline = build("Schedule Date", delim,
                    "Month", delim,
                    "Duration", delim,
                    "Hours", delim,
                    "ALF MRN", delim,
                    "CGMC MRN", delim,
                    "SDMH MRN", delim ,
                    "Patient Name", delim,
                    "Age", delim,
                    "DOB", delim,
                    "Address1", delim,
                    "Address2", delim,
                    "Suburb", delim,
                    "Postcode", delim,
                    "Country of Birth", delim,
                    "Preferred Language", delim,
                    "Indigenous Status", delim,
                    "Gender", delim,
                    "CCHS Fee", delim,
                    "Fee Change Personnel", delim,
                    "Fee Change Date", delim,
                    "Appointment Type", delim,
                    "Appointment Location", delim,
                    "Appointment Status", delim,
                    "Action Date", delim,
                    "Action Personnel", delim,
                    "Cancel/Reschedule Reason", delim,
                    "Resource", delim, "Resource", delim, "Resource", delim, "Resource", delim, "Resource", delim,
                    "Choose Car Pool Zone", delim,
                    "Additional Resources Required", delim,
                    "Station Wagon or Sedan CCHS", delim,
                    "New/Review", delim,
                    "Service Type", delim,
                    "Health Promotion Strategy", delim,
                    "Interpreter Required", delim,
                    "Language", delim,
                    "Interpreter Location", delim,
                    "Interpreter Location (off Campus)", delim,
                    "Interpreter Contact Person & Ext No", delim,
                    "Priority", delim,
                    "Status", delim,
                    "Interpreter Type", delim,
                    "Funding Stream", delim,
                    "Location", delim,
                    "Direct Contact Time", delim,
                    "Indirect Contact Time", delim,
                    "Travel Time", delim,
                    "Indirect Tasks")
 
	if(newPAS = "YES")
		resline = build(resline,delim,"AH MRN")
	endif
 
	resline = build(resline, delim, "E-Receipt")	;MOD 11
 
   Col 0  resline
    Row + 1
 
detail
 
   case (cnvtupper(oef.label_text))
 
      of "CHOOSE CAR POOL ZONE"             : apptinfo->appt_data[d1.seq]->car_pool_zone    = sed.oe_field_display_value
      of "STATION WAGON OR SEDAN CCHS"      : apptinfo->appt_data[d1.seq]->wagon_sedan      = sed.oe_field_display_value
      of "NEW/REVIEW"                       : apptinfo->appt_data[d1.seq]->new_review       = sed.oe_field_display_value
      of "SERVICE TYPE"                     : apptinfo->appt_data[d1.seq]->service_type     = sed.oe_field_display_value
      of "INTERPRETER REQUIRED"             : apptinfo->appt_data[d1.seq]->int_required     = sed.oe_field_display_value
      of "LANGUAGE"                         : apptinfo->appt_data[d1.seq]->language         = sed.oe_field_display_value
      of "INTERPRETER LOCATION"             : apptinfo->appt_data[d1.seq]->int_location     = sed.oe_field_display_value
      of "INTERPRETER LOCATION (OFF CAMPUS)": apptinfo->appt_data[d1.seq]->int_loc_oc       = sed.oe_field_display_value
      of "INTERPRETER TYPE"                 : apptinfo->appt_data[d1.seq]->int_type         = sed.oe_field_display_value
      of "PRIORITY"                         : apptinfo->appt_data[d1.seq]->priority         = sed.oe_field_display_value
      of "STATUS"                           : apptinfo->appt_data[d1.seq]->status           = sed.oe_field_display_value
      of "FUNDING STREAM"                   : apptinfo->appt_data[d1.seq]->funding_stream   = sed.oe_field_display_value
      of "LOCATION"                         : apptinfo->appt_data[d1.seq]->location         = sed.oe_field_display_value
      of "INDIRECT TASKS"                   : apptinfo->appt_data[d1.seq]->indirect_tasks   = sed.oe_field_display_value
      of "DIRECT CONTACT TIME"              : temp_time = replace(sed.oe_field_display_value, " mins", "")
                                              apptinfo->appt_data[d1.seq]->direct_cont_tm   = temp_time
      of "INDIRECT CONTACT TIME*"           : temp_time = replace(sed.oe_field_display_value, " mins", "")
                                              apptinfo->appt_data[d1.seq]->indirect_cont_tm = temp_time
      of "TRAVEL TIME"                      : temp_time = replace(sed.oe_field_display_value, " mins", "")
                                              apptinfo->appt_data[d1.seq]->travel_time      = temp_time
      of "NAME/PROFESSION + EXT./PAGER OF PERSON REQ INTERP":
                                              apptinfo->appt_data[d1.seq]->int_contact      = sed.oe_field_display_value
      of "HEALTH PROMOTION STRATEGY (IF RELEVANT)"          :
                                              apptinfo->appt_data[d1.seq]->health_strategy  = sed.oe_field_display_value
      of "ADDITIONAL RESOURCES REQUIRED (CHOOSE FROM LIST)" :
         add_resources = apptinfo->appt_data[d1.seq]->add_resources
         if (add_resources = "")
            add_resources = sed.oe_field_display_value
         else
            add_resources = build(add_resources, ", ", sed.oe_field_display_value)
         endif
         apptinfo->appt_data[d1.seq]->add_resources = add_resources
   endcase
 
   if (trim(oef.label_text) = "Choose Appointment Resource*")
      if (apptinfo->appt_data[d1.seq]->Resources[1].resource = "")
         apptinfo->appt_data[d1.seq]->Resources[1].resource = sed.oe_field_display_value
      else
         if (apptinfo->appt_data[d1.seq]->Resources[2].resource = "")
            apptinfo->appt_data[d1.seq]->Resources[2].resource = sed.oe_field_display_value
         else
            if (apptinfo->appt_data[d1.seq]->Resources[3].resource = "")
               apptinfo->appt_data[d1.seq]->Resources[3].resource = sed.oe_field_display_value
            else
               if (apptinfo->appt_data[d1.seq]->Resources[4].resource = "")
                  apptinfo->appt_data[d1.seq]->Resources[4].resource = sed.oe_field_display_value
               else
                  apptinfo->appt_data[d1.seq]->Resources[5].resource = sed.oe_field_display_value
               endif
            endif
         endif
      endif
   endif
 
 
   if (apptinfo->appt_data[d1.seq].appt_status in ("Rescheduled", "Canceled"))
      if (trim(oef.label_text) = "Cancel Reschedule Reason")
         temp_str = sed.oe_field_display_value
         temp_str = replace(temp_str,delim," ",0)
         temp_str = replace(temp_str,LF," ",0)
         temp_str = replace(temp_str,CR," ",0)
         apptinfo->appt_data[d1.seq]->Cancel_reason = temp_str
      endif
   endif
 
 
foot report
   if (nbr_appts > 0)
      for (i = 1 to nbr_appts)
         if (trim(apptinfo->appt_data[i].appt_type) != "")
 
            resline = build(format(apptinfo->appt_data[i].schedule_date, "dd/mm/yyyy hh:mm;;d")
                  , delim, trim(format(apptinfo->appt_data[i].schedule_date, "mmmmmmmmm;;d"),3)
                  , delim, format(apptinfo->appt_data[i].duration, "####")
                  , delim, trim(apptinfo->appt_data[i].dur_hours)
                  , delim, trim(apptinfo->appt_data[i].alf_mrn)
                  , delim, trim(apptinfo->appt_data[i].cgmc_mrn)
                  , delim, trim(apptinfo->appt_data[i].sdmh_mrn)
                  , delim, trim(apptinfo->appt_data[i].pat_name)
                  , delim, trim(apptinfo->appt_data[i].pat_age)
                  , delim, trim(apptinfo->appt_data[i].pat_dob)
                  , delim, trim(apptinfo->appt_data[i].pat_address1)
                  , delim, trim(apptinfo->appt_data[i].pat_address2)
                  , delim, trim(apptinfo->appt_data[i].pat_suburb)
                  , delim, trim(apptinfo->appt_data[i].pat_pcode)
                  , delim, trim(apptinfo->appt_data[i].pat_country)
                  , delim, trim(apptinfo->appt_data[i].pat_preflang)
                  , delim, trim(apptinfo->appt_data[i].pat_indig_stat)
                  , delim, trim(apptinfo->appt_data[i].pat_gender)
                  , delim, trim(apptinfo->appt_data[i].fin_class)
                  , delim, trim(apptinfo->appt_data[i].fin_prsnl)
                  , delim, trim(apptinfo->appt_data[i].fin_date)
                  , delim, trim(apptinfo->appt_data[i].appt_type)
                  , delim, trim(apptinfo->appt_data[i].appt_location)
                  , delim, trim(apptinfo->appt_data[i].appt_status)
                  , delim, format(apptinfo->appt_data[i].action_date, "dd/mm/yyyy hh:mm;;d")
                  , delim, trim(apptinfo->appt_data[i].action_prsnl)
                  , delim, trim(apptinfo->appt_data[i].cancel_reason)
                  , delim, trim(apptinfo->appt_data[i]->Resources[1].resource)
                  , delim, trim(apptinfo->appt_data[i]->Resources[2].resource)
                  , delim, trim(apptinfo->appt_data[i]->Resources[3].resource)
                  , delim, trim(apptinfo->appt_data[i]->Resources[4].resource)
                  , delim, trim(apptinfo->appt_data[i]->Resources[5].resource)
                  , delim, trim(apptinfo->appt_data[i]->car_pool_zone)
                  , delim, trim(apptinfo->appt_data[i]->add_resources)
                  , delim, trim(apptinfo->appt_data[i]->wagon_sedan)
                  , delim, trim(apptinfo->appt_data[i]->new_review)
                  , delim, trim(apptinfo->appt_data[i]->service_type)
                  , delim, trim(apptinfo->appt_data[i]->health_strategy)
                  , delim, trim(apptinfo->appt_data[i]->int_required)
                  , delim, trim(apptinfo->appt_data[i]->language)
                  , delim, trim(apptinfo->appt_data[i]->int_location)
                  , delim, trim(apptinfo->appt_data[i]->int_loc_oc)
                  , delim, trim(apptinfo->appt_data[i]->int_contact)
                  , delim, trim(apptinfo->appt_data[i]->priority)
                  , delim, trim(apptinfo->appt_data[i]->status)
                  , delim, trim(apptinfo->appt_data[i]->int_type)
                  , delim, trim(apptinfo->appt_data[i]->funding_stream)
                  , delim, trim(apptinfo->appt_data[i]->location)
                  , delim, trim(apptinfo->appt_data[i]->direct_cont_tm)
                  , delim, trim(apptinfo->appt_data[i]->indirect_cont_tm)
                  , delim, trim(apptinfo->appt_data[i]->travel_time)
                  , delim, trim(apptinfo->appt_data[i]->indirect_tasks))
 
 
			if(newPAS = "YES")
				resline = build(resline,delim,trim(apptinfo->appt_data[i].ah_mrn))
			endif
            resline = build(resline,delim, trim(apptinfo->appt_data[i].e_receipt))		;MOD 11
 
            col 0 resline
            row + 1
         endif
      endfor
   else
      col 1 "No data found " , Clinic_name
      row + 1
   endif
 
with maxrow   = 1,
     maxcol   = 3500,
     format   = variable,
     formfeed = none,
     nullreport,
     noheading,
     nocounter
 
if ((cnvtdate($2,E) = cnvtdate("31122100",E)) OR (cnvtdate($2,E) = cnvtdate("30122100",E)))
;   set temp_file_name build("CCL_FTP_CERDATA", format(curdate, "ddmmyy;;d"), format(curtime, "hhmm;;m"),".ftp")
;
;   select into value(temp_file_name)
;   from dummyt d
;   detail
;      putstr = concat("Put ", value(output_loc), " ",value(dest_path), "\",trim(output_loc))
;      col 1 putstr
;      row + 1
;      col 1 "Close"
;      row + 1
;      col 1 "bye"
;      row + 1
;   with nocounter
;
;;  Note THE QUOTES - THE SUBMITTED FILE NAME HAS A . IN IT SO NEEDS TO BE ENCLOSED IN DOUBLE QUOTES
;
;   set dclcom = concat('@bayh_ftpcerdata "', value(temp_file_name),'"')
;   set len    = size(trim(dclcom))
;   set status = 0
;   call dcl(dclcom, len, status)
 
/* New code for Linux */
       declare dclcom = vc with noconstant("")
 
       set dclcom = concat("$cust_proc/bayh_ftpcerdata.ksh ",
                           value(ftp_filename),
                           " 7.184.180.102 ftpUSER ftpUSER1911 ",
                           ftp_pathname)
       set status = 0
       set len = size(trim(dclcom))
       call echo(dclcom)
       call dcl(dclcom, len, status)
 
endif
 
END
GO
