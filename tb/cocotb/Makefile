SIM ?= verilator
TOPLEVEL_LANG ?= verilog

REPO_ROOT := $(abspath ../..)

VERILOG_SOURCES := $(REPO_ROOT)/rtl/configurable_lfsr.sv
TOPLEVEL := configurable_lfsr
MODULE := test_configurable_lfsr

export PYTHONPATH := $(REPO_ROOT)/tb:$(PYTHONPATH)

include $(shell cocotb-config --makefiles)/Makefile.sim

