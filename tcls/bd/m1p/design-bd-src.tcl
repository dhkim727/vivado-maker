####################################################################################################
# Deprecated compatibility wrapper for the m1p board.
#
# Board/design-specific block design Tcl files are now stored under:
#   tcls/bd/<BOARD>/<DESIGN>/design-bd-src.tcl
#
# For m1p, use:
#   tcls/bd/m1p/<DESIGN>/design-bd-src.tcl
####################################################################################################

if {![info exists ::env(DESIGN)]} {
    set design_name main_design
} else {
    set design_name $::env(DESIGN)
}

set bd_tcl_file tcls/bd/m1p/$design_name/design-bd-src.tcl
if {![file exists $bd_tcl_file]} {
    error "Board/design-specific BD Tcl does not exist: $bd_tcl_file"
}

source $bd_tcl_file
