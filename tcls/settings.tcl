#######################################################################################################
# AUTHOR: FARNAM KHALILI MAYBODI
# DATE: 2022/02/05
# The environment variables, and processes are defined here
#######################################################################################################

namespace eval ::FM {

	variable VIVADO_PROJECT
	variable VIVADO_PROJECT_NAME
	variable PART_NAME
	variable BOARD_NAME
	variable DESIGN_NAME
	variable BD_TCL_FILE
	variable HDL_LANGUAGE
	variable OOC_MAX_JOBS

	proc print_gvars {} {
      		put $FM::VIVADO_PROJECT
		put $FM::VIVADO_PROJECT_NAME
      		put $FM::PART_NAME
      		put $FM::BOARD_NAME
		put $FM::DESIGN_NAME
		put $FM::BD_TCL_FILE
      		put $FM::HDL_LANGUAGE
      		put $FM::OOC_MAX_JOBS
	}

	proc refresh_bd_wrapper {} {
		set bd_file $FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.srcs/sources_1/bd/$FM::DESIGN_NAME/$FM::DESIGN_NAME.bd

		if {![file exists $bd_file]} {
			catch {common::send_msg_id "FM-004" "ERROR" "BD file does not exist: $bd_file"}
			exit 1
		}

		catch {save_bd_design}

		set bd_files [get_files -quiet $bd_file]
		if {$bd_files eq ""} {
			set bd_files [get_files -quiet -of_objects [get_filesets sources_1] *$FM::DESIGN_NAME.bd]
		}
		if {$bd_files eq ""} {
			set bd_files [get_files -quiet *$FM::DESIGN_NAME.bd]
		}
		if {$bd_files eq ""} {
			catch {common::send_msg_id "FM-005" "ERROR" "BD file is not tracked by project sources_1: $bd_file"}
			exit 1
		}

		put "Refresh Block Design HDL wrapper for: $bd_file"
		make_wrapper -files $bd_files -top -force

		if {[get_property target_language [current_project]] eq "VHDL"} {
			set wrapper_ext vhd
		} else {
			set wrapper_ext v
		}

		set wrapper_candidates [list \
			$FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.gen/sources_1/bd/$FM::DESIGN_NAME/hdl/${FM::DESIGN_NAME}_wrapper.$wrapper_ext \
			$FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.srcs/sources_1/bd/$FM::DESIGN_NAME/hdl/${FM::DESIGN_NAME}_wrapper.$wrapper_ext \
		]

		set wrapper_file ""
		foreach wrapper_candidate $wrapper_candidates {
			if {[file exists $wrapper_candidate]} {
				set wrapper_file $wrapper_candidate
				break
			}
		}

		if {$wrapper_file ne ""} {
			if {[get_files -quiet $wrapper_file] eq ""} {
				add_files -fileset sources_1 -norecurse $wrapper_file
			}
			set_property top ${FM::DESIGN_NAME}_wrapper [get_filesets sources_1]
			update_compile_order -fileset sources_1
			set_property top ${FM::DESIGN_NAME}_wrapper [get_filesets sources_1]
		} else {
			catch {common::send_msg_id "FM-006" "ERROR" "BD wrapper file was not created. Checked paths: [join $wrapper_candidates {, }]"}
			exit 1
		}
	}

	 # Process to import xci files to the project, and generate
	 # Out of Context (OOC) output products for each IP that is used in the bd design.
	proc run_ooc_ips {} {
	    
	    if {[file exists $FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.srcs/sources_1/bd/$FM::DESIGN_NAME/ip]} {
	        set bd_file $FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.srcs/sources_1/bd/$FM::DESIGN_NAME/$FM::DESIGN_NAME.bd
	        update_compile_order -fileset sources_1

	        if {[file exists $bd_file]} {
	            put "Generate Block Design output products for: $bd_file"
	            set bd_files [get_files -quiet $bd_file]
	            if {$bd_files ne ""} {
	                generate_target all $bd_files
	                catch {export_ip_user_files -of_objects $bd_files -no_script -sync -force -quiet}
	            }
	        }

	        FM::refresh_bd_wrapper

	        set ip_names {}
	        catch {set ip_names [get_ips]}
	        set ooc_max_jobs $FM::OOC_MAX_JOBS
	        if {$ooc_max_jobs < 1} {
	            set ooc_max_jobs 1
	        }
	        set active_ooc_runs {}
	        foreach ip $ip_names {
		           ## gets IPs name as they are instantiated, and the corresponding *.xci files are generated.
		           set ip_xci $FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.srcs/sources_1/bd/$FM::DESIGN_NAME/ip/${ip}/${ip}.xci
		           if {[file exists $ip_xci]} {
		             set ip_file [get_files -quiet -of_objects [get_fileset sources_1] $ip_xci]
		             if {$ip_file eq ""} {
		               set ip_file [get_files -quiet $ip_xci]
		             }
		             if {$ip_file eq ""} {
		               read_ip $ip_xci
		               set ip_file [get_files -quiet $ip_xci]
		             }

		             if {$ip_file eq ""} {
		               catch {common::send_msg_id "FM-002" "WARNING" "Unable to find IP file in project: $ip_xci"}
		               continue
		             }

		             if {[get_property generate_synth_checkpoint $ip_file] == 1 && [get_property is_enabled $ip_file] == 1} {
		           	put "Run OOC (Out of Context) IP for: $ip"
		               if {[get_runs -quiet ${ip}_synth_1] eq ""} {
		                 create_ip_run $ip_file
		               }
		               # it is important to reset the synth_1 before launching the run.
			       reset_run ${ip}_synth_1
			       launch_run -jobs 8 ${ip}_synth_1
		               lappend active_ooc_runs ${ip}_synth_1
		               if {[llength $active_ooc_runs] >= $ooc_max_jobs} {
		                 foreach active_ooc_run $active_ooc_runs {
		                   wait_on_run $active_ooc_run
		                 }
		                 set active_ooc_runs {}
		               }
		             }
		           }
	        }

	        foreach active_ooc_run $active_ooc_runs {
	          wait_on_run $active_ooc_run
	        }
	    }
	}

	proc read_xci {} {
	                if {[file exists $FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.srcs/sources_1/bd/$FM::DESIGN_NAME/ip]} {
                        update_compile_order -fileset sources_1
                        set ip_names {}
                        catch {set ip_names [get_ips]}
                        foreach ip $ip_names {
                                set ip_xci $FM::VIVADO_PROJECT/$FM::VIVADO_PROJECT_NAME.srcs/sources_1/bd/$FM::DESIGN_NAME/ip/${ip}/${ip}.xci
                                if {[file exists $ip_xci]} {
                                        put ${ip}
                                        read_ip $ip_xci
                                }
                        }
                }
        }



	proc read_user_lib_1 {} {
        	
        	if {[file exists srcs/libs/user_lib_1]} {

        		set vhd_files [glob srcs/libs/user_lib_1/*.vhd]
        		put $vhd_files
        		catch {$vhd_files}
        		foreach vhd $vhd_files {
        	             add_files -norecurse ${vhd}
        	             set_property library user_lib_1 [get_files ${vhd}]
        		}
        	 	update_compile_order -fileset sources_1
        	}

        }


}

set FM::VIVADO_PROJECT $::env(VIVADO_WORK_DIR)
set FM::VIVADO_PROJECT_NAME $::env(VIVADO_PROJECT_NAME)
set FM::PART_NAME $::env(XILINX_PART)
set FM::BOARD_NAME $::env(BOARD)
set FM::DESIGN_NAME $::env(DESIGN)
set FM::BD_TCL_FILE $::env(BD_TCL_FILE)
set FM::HDL_LANGUAGE $::env(HDL_LANGUAGE) 
set FM::OOC_MAX_JOBS $::env(OOC_JOBS) 



#######################################################################################################


