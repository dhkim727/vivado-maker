####################################################################################################
# Deprecated compatibility wrapper.
#
# Board/design-specific block design Tcl files are now stored under:
#   tcls/bd/<BOARD>/<DESIGN>/design-bd-src.tcl
#
# The normal project flow sources the board-specific file directly from
# tcls/run-vivado-prj.tcl. This wrapper remains only for manual compatibility.
####################################################################################################

if {![info exists ::env(BOARD)]} {
    error "BOARD environment variable is not set. Use tcls/bd/<BOARD>/<DESIGN>/design-bd-src.tcl directly or run make with BOARD=<board> DESIGN=<design>."
}

if {![info exists ::env(DESIGN)]} {
    error "DESIGN environment variable is not set. Use tcls/bd/<BOARD>/<DESIGN>/design-bd-src.tcl directly or run make with BOARD=<board> DESIGN=<design>."
}

set bd_tcl_file tcls/bd/$::env(BOARD)/$::env(DESIGN)/design-bd-src.tcl
if {![file exists $bd_tcl_file]} {
    error "Board-specific BD Tcl does not exist: $bd_tcl_file"
}

source $bd_tcl_file
