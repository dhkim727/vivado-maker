################################################################################
# Minimal constraints for m1p synthesis with the example block design.
#
# This file intentionally contains only a clock constraint so the design can be
# synthesized without requiring the full board pinout. Add PACKAGE_PIN and
# IOSTANDARD constraints before implementation/bitstream generation.
################################################################################

create_clock -period 10.000 -name clk_i [get_ports clk_i]