SIM ?= verilator
TOPLEVEL_LANG ?= verilog

REPO_ROOT := $(abspath ../..)

VERILOG_SOURCES := \
  $(REPO_ROOT)/rtl/uart_tx.sv \
  $(REPO_ROOT)/rtl/uart_rx.sv \
  $(REPO_ROOT)/rtl/uart_echo.sv

TOPLEVEL := uart_echo
MODULE := test_uart_echo

COMPILE_ARGS += -GCLKS_PER_BIT=4
export PYTHONPATH := $(REPO_ROOT)/tb:$(PYTHONPATH)

include $(shell cocotb-config --makefiles)/Makefile.sim

