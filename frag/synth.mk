# Written by dustin richmond at UCSC for CSE x25
# Path to the repository root
REPO_ROOT ?= $(shell git rev-parse --show-toplevel)

# If you have the tools installed in a non-standard path,
# you can override these to specify the path to the executable.
YOSYS ?= yosys
NETLISTSVG ?= netlistsvg

# This is a little bit hacky, but sufficient. In order to make sure
# that students can edit the filelist, that make knows about updates
# to that filelist *and* the files themselves, and that pytest can
# read the filelist, we store the listlist in a json file. We then
# read the json file while checking dependencies.
SYNTH_SOURCES = $(shell python3 $(REPO_ROOT)/hdl_source/util/get_filelist.py)
SYNTH_SOURCES := $(addprefix $(REPO_ROOT)/,$(SYNTH_SOURCES))
ABSTRACT_TOP = $(shell python3 $(REPO_ROOT)/hdl_source/util/get_top.py)

# The ice40 commands will only work if top.sv is provided, i.e. if
# there is a design for the FPGA.
ice40.svg: ice40.json
	$(NETLISTSVG) $< -o $@
synth-ice40: ice40.json
ice40.json: top.sv filelist.json $(SYNTH_SOURCES)
	$(YOSYS) -ql ice40.yslog -p 'synth_ice40 -top top -json $@' top.sv $(SYNTH_SOURCES)

# These commands will always work.
mapped.svg: mapped.json
	$(NETLISTSVG) $< -o $@
synth-mapped: mapped.json
mapped.json: filelist.json $(SYNTH_SOURCES)
	$(YOSYS) -ql mapped.yslog -p 'synth_ice40 -top $(ABSTRACT_TOP) -json $@' $(SYNTH_SOURCES)

# These commands will always work.
abstract.svg: abstract.json
	$(NETLISTSVG) $< -o $@
synth-abstract: abstract.json
abstract.json: filelist.json $(SYNTH_SOURCES)
	$(YOSYS) -ql abstract.yslog -p 'synth -top $(ABSTRACT_TOP) -flatten; json -o abstract.json ' $(SYNTH_SOURCES) 

synth-clean:
	rm -rf ice40.json
	rm -rf ice40.yslog
	rm -rf ice40.svg

	rm -rf abstract.json
	rm -rf abstract.yslog
	rm -rf abstract.svg

synth-help:
	@echo "  synth-ice40: Synthesize the circuit for the ICE40 FPGA, with a top level"
	@echo "  ice40.svg: Generate the .png file for the ICE40 circuit, with a top level"
	@echo "  synth-mapped: Synthesize the circuit for the ICE40 FPGA, without a top level"
	@echo "  mapped.svg: Generate the .png file for the ICE40 circuit, without a top level"
	@echo "  synth-abstract: Synthesize the circuit for abstract boolean gates"
	@echo "  abstract.svg: Generate the .png file for the ICE40 circuit"

synth-vars-help:
	@echo "    YOSYS: Override this variable to set the location of your yosys executable."

clean: synth-clean
targets-help: synth-help
vars-help: synth-vars-help

.PHONY: synth-clean synth-help synth-vars-help vars-help targets-help clean
