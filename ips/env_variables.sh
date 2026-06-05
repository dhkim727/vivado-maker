################################################
# AUTHOR: FARNAM KHALILI MAYBODI
# DATE: 2021/10/20
# COMPANY: UNISI 
#
################################################
export BOARD=m1p
export XILINX_PART=xcku060-ffva1156-1-i
export VIVADO_VERSION=2025.2
echo chosen fpga part number = $XILINX_PART
echo Vivado Version = $VIVADO_VERSION
export CLK_PERIOD_NS=10
export HDL_LANGUAGE=verilog

echo chosen board = $BOARD
echo set clock period for hls ips = $CLK_PERIOD_NS ns
echo set generated rtl language for hls ips = $HDL_LANGUAGE

