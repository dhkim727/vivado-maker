###############################################################################################
# TCL (VIVADO) for packaging the your_sv_ip_1 SystemVerilog example IP
###############################################################################################

set partNumber $::env(XILINX_PART)
set ipName $::env(PROJECT)
set moduleName $::env(MODULE)

if {[info exists ::env(HDL_SOURCE)]} {
    set hdlSource $::env(HDL_SOURCE)
} else {
    set hdlSource "$ipName.sv"
}

set hdlPath src/$hdlSource
set hdlAbsPath [file normalize $hdlPath]
set hdlExt [string tolower [file extension $hdlSource]]

if {![file exists $hdlAbsPath]} {
    error "HDL source file does not exist: $hdlAbsPath"
}

create_project $ipName . -force -part $partNumber

if {$hdlExt eq ".vhd" || $hdlExt eq ".vhdl"} {
    set_property target_language VHDL [current_project]
} else {
    set_property target_language Verilog [current_project]
}

import_files -norecurse $hdlAbsPath

set hdlFile [get_files -quiet $hdlAbsPath]
if {$hdlFile eq ""} {
    set hdlFile [get_files -quiet $hdlSource]
}
if {$hdlFile eq ""} {
    error "Imported HDL source was not found in the project: $hdlAbsPath"
}

if {$hdlExt eq ".sv"} {
    set_property file_type SystemVerilog $hdlFile
}

set_property top $moduleName [current_fileset]
update_compile_order -fileset sources_1

ipx::package_project -root_dir $ipName -vendor xilinx.com -library user -taxonomy /UserIP
set_property core_revision 1 [ipx::current_core]

ipx::add_file_group -type utility {} [ipx::current_core]
ipx::add_file ../../unisi.png [ipx::get_file_groups xilinx_utilityxitfiles -of_objects [ipx::current_core]]
set_property type image [ipx::get_files ../../unisi.png -of_objects [ipx::get_file_groups xilinx_utilityxitfiles -of_objects [ipx::current_core]]]
set_property type LOGO [ipx::get_files ../../unisi.png -of_objects [ipx::get_file_groups xilinx_utilityxitfiles -of_objects [ipx::current_core]]]

# If your IP has an AXI interface, associate the proper clock here.
# Example:
# ipx::associate_bus_interfaces -busif s_axi_registers -clock clk_i [ipx::current_core]

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

set_property ip_repo_paths $ipName [current_project]
update_ip_catalog
###############################################################################################