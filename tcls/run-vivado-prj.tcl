##################################################################################
# DATE:  2022/01/18
# AUTHOR: FARNAM KHALILI MAYBODI
# DESCRIPTION: 
# This tcl file is responsible to create a vivado project, select the part number 
# based on the specified board (i.e., BOARD) by the user during the "make vivado"
# command. It is also respnsible to source the stored tcl of "*.bd", and 
# eventually, wrap it based on selected default hdl language
##################################################################################
source tcls/settings.tcl

set project $FM::VIVADO_PROJECT_NAME 
create_project $project $FM::VIVADO_PROJECT/ -force -part $FM::PART_NAME
set_param general.maxThreads 8
set_property target_language $FM::HDL_LANGUAGE [current_project]

set_msg_config -id {[Synth 8-5858]} -new_severity "info"
set_msg_config -id {[Synth 8-4480]} -limit 1000

reset_run synth_1
reset_run impl_1
reset_project


put $FM::PART_NAME
put $FM::BOARD_NAME

proc fm_collect_xdc_files_recursive {root_dir} {
      set collected_files {}

      if {![file exists $root_dir]} {
            return $collected_files
      }

      foreach entry [glob -nocomplain -directory $root_dir *] {
            if {[file isdirectory $entry]} {
                  set child_files [fm_collect_xdc_files_recursive $entry]
                  foreach child_file $child_files {
                        lappend collected_files $child_file
                  }
            } elseif {[string tolower [file extension $entry]] eq ".xdc"} {
                  lappend collected_files $entry
            }
      }

      return [lsort -unique $collected_files]
}

set board_constraint_dir constraints/$FM::BOARD_NAME
set board_xdc_files [fm_collect_xdc_files_recursive $board_constraint_dir]
if {[llength $board_xdc_files] > 0} {
      add_files -fileset constrs_1 -norecurse $board_xdc_files
}
	        
			     		       
# you should put all your custom IPs into the folder "ips"
set_property  ip_repo_paths  { \
                              ips \
                              } [current_fileset]
update_ip_catalog

# Standalone XCI IPs must be read before RTL sources when RTL instantiates IP
# modules generated from XCI files.
if {[file exists tcls/add-xci-sources.tcl]} {
      source tcls/add-xci-sources.tcl
}

# RTL module references used inside a BD Tcl must be resolvable before the BD Tcl
# is sourced. Optional source roots are managed in tcls/add-rtl-sources.tcl.
if {[file exists tcls/add-rtl-sources.tcl]} {
      source tcls/add-rtl-sources.tcl
}

# If your project has a block design, source the board/design-specific BD Tcl here.
if {![file exists $FM::BD_TCL_FILE]} {
      catch {common::send_msg_id "FM-001" "ERROR" "Board/design-specific BD Tcl does not exist: $FM::BD_TCL_FILE"}
      exit 1
}
source $FM::BD_TCL_FILE


#if your project has HDL_LANGUAGE libraries please add here with the specific tcl proc that we defined: 
#example:
#FM::read_user_lib_1
#FM::read_user_lib_2


#if there are source files
#please add your *.vhd *.sv, *.v sources 
#here. 
# source add_sources.tcl
#if your design does not include block design, you must specify the top module of your design here:
# set_property top <the entity name of your top module hdl code> [current_fileset]

# If your design contains a block design, automatically create or refresh the
# HDL wrapper, add it to the project if needed, and make it the top module.
FM::refresh_bd_wrapper

exit
##################################################################################
