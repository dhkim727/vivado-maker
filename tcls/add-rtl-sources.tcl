##################################################################################
# DESCRIPTION:
# Add project RTL sources before sourcing a block-design Tcl.
#
# This is required when a block design contains RTL module references created with
# commands such as:
#   create_bd_cell -type module -reference <module_name> <cell_name>
#
# The referenced modules must already be resolvable by Vivado before the BD Tcl is
# sourced, otherwise the BD Tcl's can_resolve_reference/create_bd_cell checks fail.
##################################################################################

proc fm_collect_files_recursive {root_dir extensions} {
      set collected_files {}

      if {![file exists $root_dir]} {
            return $collected_files
      }

      foreach entry [glob -nocomplain -directory $root_dir *] {
            if {[file isdirectory $entry]} {
                  set child_files [fm_collect_files_recursive $entry $extensions]
                  foreach child_file $child_files {
                        lappend collected_files $child_file
                  }
            } else {
                  set ext [string tolower [file extension $entry]]
                  if {[lsearch -exact $extensions $ext] >= 0} {
                        lappend collected_files $entry
                  }
            }
      }

      return [lsort -unique $collected_files]
}

set rtl_source_dirs [list \
      srcs/rtl/common \
      srcs/rtl/$FM::BOARD_NAME/common \
      srcs/rtl/$FM::BOARD_NAME/$FM::DESIGN_NAME \
      srcs/rtl/$FM::DESIGN_NAME \
]

set rtl_source_extensions [list .v .sv .vhd .vhdl]
set rtl_header_extensions [list .vh .svh]

set rtl_files {}
set rtl_include_dirs {}
set rtl_header_files {}

foreach rtl_dir $rtl_source_dirs {
      foreach rtl_file [fm_collect_files_recursive $rtl_dir $rtl_source_extensions] {
            lappend rtl_files $rtl_file
      }

      foreach header_file [fm_collect_files_recursive $rtl_dir $rtl_header_extensions] {
            lappend rtl_header_files $header_file
            lappend rtl_include_dirs [file dirname $header_file]
      }

      set explicit_include_dir $rtl_dir/include
      if {[file exists $explicit_include_dir]} {
            lappend rtl_include_dirs $explicit_include_dir
      }
}

set rtl_files [lsort -unique $rtl_files]
set rtl_header_files [lsort -unique $rtl_header_files]
set rtl_include_dirs [lsort -unique $rtl_include_dirs]

if {[llength $rtl_files] > 0} {
      puts "Adding RTL source files: $rtl_files"
      add_files -fileset sources_1 -norecurse $rtl_files
}

if {[llength $rtl_header_files] > 0} {
      puts "Adding RTL header files: $rtl_header_files"
      add_files -fileset sources_1 -norecurse $rtl_header_files
}

if {[llength $rtl_include_dirs] > 0} {
      puts "Setting RTL include directories: $rtl_include_dirs"
      set_property include_dirs $rtl_include_dirs [current_fileset]
}

if {[llength $rtl_files] > 0 || [llength $rtl_header_files] > 0} {
      update_compile_order -fileset sources_1
}

##################################################################################