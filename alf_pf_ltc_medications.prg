/************************************************************************************************************
#m     Module                 :  POWERCHART
*****************************************************************************************************************************
#n     Program Common Name    :  ALF_PF_LTC_MEDICATIONS
#n     Program Object Name    :  ALF_PF_LTC_MEDICATIONS
#n     Program Run From       :  POWERFORM
*****************************************************************************************************************************
#d     Description            :  This template creates a layout for the users to specify medications related to Immunosuppression,
								 Prophylaxis etc.
 
*****************************************************************************************************************************
#a     Site                   :  The Alfred
#a                               Commercial Road, Melbourne
#a                               Victoria, 3004
#a                               Australia
*****************************************************************************************************************************
#t     Tables                 :  None (just an empty layout with no data from backend)
*****************************************************************************************************************************
#v     Version                :  DiscernVisualDeveloper  Version 2012.09.1.56
*****************************************************************************************************************************
#m     Modification Control Log
*****************************************************************************************************************************
#m     	Mod #   Author          Date           	Description
#m     	-----	--------------  -----------		--------------------------------------------------------------------------
#m		001		Mandeep Singh	25 OCT 2017		Initial version
 
*****************************************************************************************************************************/
 
drop 	program alf_pf_ltc_medications go
create 	program alf_pf_ltc_medications
 
;************************************
;******* Variable declaration *******
;************************************
 
set RHEAD = "{\rtf1\ansi \deff0{\fonttbl{\f0\fswiss Arial;}}{\colortbl;\red0\green0\blue0;\red255\green255\blue255;}\deftab1134"
 
set RH2R  = "\plain \f0 \fs18 \cb2 \pard\sl0"
 
set RTFEOF = "} "
 
set REOL = "\par "
 
 
 
/*** Set the reply string ***/
 
set REPLY->TEXT = concat(RHEAD, RH2R, 	"\par\par",
										"\ul \b Immunosuppression: \b0 \ul0 \par \par \par \par ",
										"\ul \b Prophylaxis - Antibiotic/fungal/viral: \b0 \ul0 \par \par \par \par ",
										"\ul \b Treatment - Antibiotic/fungal/viral: \b0 \ul0 \par \par \par \par ",
										"\ul \b Other: \b0 \ul0 \par \par \par \par ",
						RTFEOF)
 
 
 
;set REPLY->TEXT = concat(RHEAD, RH2R, cntct_bsnsPh, RTFEOF)
 
end
go
 
