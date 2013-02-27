###################################################################
# Project Configuration: 
# 
# Specify the name of the design (project) and the Quartus II
# Settings File (.qsf)
###################################################################

PROJECT = top
ASSIGNMENT_FILES = top.qpf top.qsf
SIM_TB = sggoc_tb

SRC = \
	../rtl/tv80/rtl/core/tv80s.v \
	../rtl/tv80/rtl/core/tv80_reg.v \
	../rtl/tv80/rtl/core/tv80_mcode.v \
	../rtl/tv80/rtl/core/tv80_core.v \
	../rtl/tv80/rtl/core/tv80_alu.v \
	../rtl/tv80/env/async_mem.v \
	../rtl/tv80/env/op_decode.v \
	../rtl/mem_mapper.v \
	../rtl/mmu.v \
	../rtl/vdp.v \
	../rtl/vram.v \
	../rtl/vdp_background.v \
	../rtl/vga_timing.v \
	../rtl/clk_div.v \

SIM_SRC = \
	../sim/mem_mapper_tb.v \
	../sim/z80_vdp_tb.v \
	../sim/z80_tb.v \
	../sim/sggoc_tb.v

VINCDIR = \
	-I../rtl/

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and database
# program: program your device with the compiled design
###################################################################

all: smart.log $(PROJECT).asm.rpt $(PROJECT).sta.rpt 

sim: $(SIM_TB).vcd
view: $(SIM_TB).view

warnings:
	grep Warning *.rpt | grep -Ev "332060|15610|20028|21074|13410|12241|13024|169174|171167|306006|15706|15705|15710|15709|176250|292013"

clean:
	rm -rf *.rpt *.chg smart.log *.htm *.eqn *.pin *.sof *.pof *.done *.jdi db incremental_db \
		*.vvp *.vcd *.log *.list *.smsg

map: smart.log $(PROJECT).map.rpt
fit: smart.log $(PROJECT).fit.rpt
asm: smart.log $(PROJECT).asm.rpt
sta: smart.log $(PROJECT).sta.rpt
smart: smart.log

###################################################################
# Executable Configuration
###################################################################

MAP_ARGS = --family="Cyclone II"
FIT_ARGS = --part=EP2C20F484C7
ASM_ARGS =
STA_ARGS =

CVER=cver
GTKWAVE=gtkwave
IVERILOG=iverilog
VVP=vvp

###################################################################
# Simulation
###################################################################

$(SIM_TB).vvp: $(SRC) $(SIM_SRC)
	rm -f $@.list
	@for i in `echo $^`; do \
	    echo $$i >> $@.list; \
	done
	$(IVERILOG) -Wall -o $@ $(VINCDIR) -c $@.list -s $(@:.vvp=)

%.vcd: %.vvp
	$(VVP) $<

%.view: %.vcd
	$(GTKWAVE) $< $<.save

###################################################################
# Target implementations
###################################################################

STAMP = echo done >

$(PROJECT).map.rpt: map.chg $(SOURCE_FILES) 
	quartus_map $(MAP_ARGS) $(PROJECT)
	$(STAMP) fit.chg

$(PROJECT).fit.rpt: fit.chg $(PROJECT).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT)
	$(STAMP) asm.chg
	$(STAMP) sta.chg

$(PROJECT).asm.rpt: asm.chg $(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT)

$(PROJECT).sta.rpt: sta.chg $(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT) 

smart.log: $(ASSIGNMENT_FILES)
	quartus_sh --determine_smart_action $(PROJECT) > smart.log

###################################################################
# Project initialization
###################################################################

$(ASSIGNMENT_FILES):
	quartus_sh --prepare $(PROJECT)
	
map.chg:
	$(STAMP) map.chg
fit.chg:
	$(STAMP) fit.chg
sta.chg:
	$(STAMP) sta.chg
asm.chg:
	$(STAMP) asm.chg

###################################################################
# Programming the device
###################################################################

program: $(PROJECT).sof
	quartus_pgm --no_banner --mode=jtag -o "P;$(PROJECT).sof"

program_prom: $(PROJECT).pof
	quartus_pgm --no_banner --mode=AS -o "p;${PROJECT}.pof"
