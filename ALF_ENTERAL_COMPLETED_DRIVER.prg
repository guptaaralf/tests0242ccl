/********************************************************************************
#m     Module                 :  CareNet
*********************************************************************************
#n     Program Common Name    :  ALF_ENTERAL_COMPLETED_DRIVER.PRG
#n     Porgram Object Name    :  ALF_ENTERAL_COMPLETED_DRIVER
#n     Program Run From       :  Powerchart
*********************************************************************************
#d     Description            :  This program is a driver program to allow user select output format
*********************************************************************************
#a     Site                   :  Alfred Healthcare Group
                                 Commercial Road, Melbourne
                                 Victoria, 3004
                                 Australia
 
#m     Mod #     Author          Date             Description
       -----     --------------- ---------------  -------------------
                 Mohammed Al-Kaf  08 Jan 2018	  Released.
********************************************************************************/
 
drop program ALF_ENTERAL_COMPLETED_DRIVER go
create program ALF_ENTERAL_COMPLETED_DRIVER
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "From" = "CURDATE"
	, "To" = "CURDATE"
	, "Output Type" = "Report"
 
with OUTDEV, fdate, tdate, reportType
 
case($reportType)
	of 'Report':
		execute ALF_LP_ENTERAL_COMPLETED $1, $2, $3
	of 'Extract':
		EXECUTE alf_ENTERAL_COMPLETED_extract $1, $2, $3
 
endcase
 
end
go
 
