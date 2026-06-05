#####################################################################################################
# DATE: 2021/01/15
# AUTHOR: FARNAM KHALILI MAYBODI
# DESCRIPTION: 
# Universal Makefile for handling a vivado project from IP design, generation,
# packaging IPs, vivado project creation, IP OOC (Out of Context) runs, synthesize
# implementation, bitstream generation, report generation, for target board defined
# by the user through the $BOARD.
# The following environment variable can be set by the user:
BOARD			?= m1p
DESIGN			?= system
export VIVADO_VERSION  ?=2025.2
# VIVADO_VERSION  ?=2020.2
HDL_LANGUAGE    ?= VERILOG
OOC_JOBS        ?= 16
# setting additional xilinx board parameters for the selected board
ifeq ($(BOARD), m1p)
	XILINX_PART 			 := xcku060-ffva1156-1-i
	CLK_PERIOD_NS			 := 10
else ifeq  ($(BOARD), m1)
	XILINX_PART 			 := xcau25p-ffvb676-2-i
	CLK_PERIOD_NS			 := 10
else
$(error Unknown board - please specify a supported FPGA board)
endif
######################################################################################################


######################################################################################################
# Do not touch from here:
######################################################################################################
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
export ROOT_PATH   := $(dir $(MKFILE_PATH))

HLS_IP_DIR := hls-ips
VHD_IP_DIR := vhd-ips
VIVADO_WORK_ROOT := vivado-prj
VIVADO_WORK_DIR := $(VIVADO_WORK_ROOT)/$(BOARD)/$(DESIGN)
VIVADO_PROJECT_NAME := $(BOARD)-$(DESIGN)-vivado
BD_TCL_DIR := tcls/bd/$(BOARD)/$(DESIGN)
BD_TCL_FILE := $(BD_TCL_DIR)/design-bd-src.tcl

export HLS_IP_DIR
export VHD_IP_DIR
export XILINX_PART
export BOARD
export DESIGN
export VIVADO_WORK_ROOT
export VIVADO_WORK_DIR
export VIVADO_PROJECT_NAME
export BD_TCL_DIR
export BD_TCL_FILE
export HDL_LANGUAGE
export OOC_JOBS

all: impl
 
vivado: custom_ips 
	@echo Creating Vivado Project 
	@mkdir -p ${VIVADO_WORK_DIR}
	@cd ${VIVADO_WORK_DIR} 
	vivado -mode batch -source tcls/run-vivado-prj.tcl  -nolog -nojournal 
	@mkdir -p ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.srcs/sources_1/bd/${DESIGN}/ui
	@if [ -d srcs/stored_ui/${BOARD}/${DESIGN} ]; then cp srcs/stored_ui/${BOARD}/${DESIGN}/* ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.srcs/sources_1/bd/${DESIGN}/ui/ 2>/dev/null || true; fi

update_tcl:
	@echo Updating ${BD_TCL_FILE}
	@cd ${VIVADO_WORK_DIR}
	@mkdir -p srcs/bd_old/${BOARD}/${DESIGN}
	@mkdir -p srcs/stored_ui/${BOARD}/${DESIGN}
	cp ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.srcs/sources_1/bd/${DESIGN}/${DESIGN}.bd srcs/bd_old/${BOARD}/${DESIGN}/
	@if [ -d ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.srcs/sources_1/bd/${DESIGN}/ui ]; then cp ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.srcs/sources_1/bd/${DESIGN}/ui/* srcs/stored_ui/${BOARD}/${DESIGN}/ 2>/dev/null || true; fi
	vivado -mode batch -source tcls/gen-bd-tcl.tcl  -nolog -nojournal

ip_ooc: vivado
	@echo Synthesizing the project
	@cd ${VIVADO_WORK_DIR}
	vivado -mode batch -source tcls/run-ooc.tcl -nolog -nojournal 
	wait; 

synth: ip_ooc
	@echo Synthesizing the project
	vivado -mode batch -source tcls/run-synth.tcl -nolog -nojournal 

impl: synth
	@echo Implementating the project
	vivado -mode batch -source tcls/run-impl.tcl -nolog -nojournal



hdf:
	@echo Exporting HDF file ....
	@test -s ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.runs/impl_1/${DESIGN}_wrapper.sysdef || { echo "system definistion file does not exist! Exiting..."; false; } && \
	                 mkdir -p ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.sdk && \
	                 cp ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.runs/impl_1/${DESIGN}_wrapper.sysdef ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.sdk/${DESIGN}_wrapper.hdf
	@echo HDF file is created as ${VIVADO_WORK_DIR}/${VIVADO_PROJECT_NAME}.sdk/${DESIGN}_wrapper.hdf


custom_ips:
	@echo Make IPs which are located into the folder "ips" 
	@cd ips && make all 

clean:
	@echo Clean ...
	rm -rf *.log *.jou .Xil 
	@cd ips && make clean
       	
########################################################################################################
