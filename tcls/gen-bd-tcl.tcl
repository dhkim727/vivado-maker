####################################################################################################
# AUTHOR: FARNAM KHALILI MAYBODI
# DATE: 2022/01/21
# This tcl is sourced from the main Makefile, and 
# The main purpose of it is to open the block design, create 
# a tcl file from the latest block design (should be verified before by the 
# user) then close it. This tcl should be issued when
# the user wants to issue "git push" , becuase in the 
# .gitignore we have ignored to push all generated output files as
# well as the board/design-specific Vivado project source folders.
# So, this is a must procedure before doing git push,  otherwise you loose latest updates of your .bd 
####################################################################################################
source tcls/settings.tcl

# check if the project is not opened, then open it
set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
    open_project $FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.xpr
}

open_bd_design $FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.srcs/sources_1/bd/$FM::DESIGN_NAME/$FM::DESIGN_NAME.bd

# before generting the block design it is required that the design validated.
validate_bd_design -force

# generate equivalent board/design-specific tcl scripts of the block design.
file mkdir [file dirname $FM::BD_TCL_FILE]
write_bd_tcl $FM::BD_TCL_FILE -force

save_bd_design  [current_bd_design]
close_bd_design  [current_bd_design] 

exit 
#####################################################################################################