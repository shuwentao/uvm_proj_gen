# @P@ —— 由 uvm_proj_gen/create_project.sh 生成
export VCS_HOME   ?= /mnt/data1/synopsys/vcs-mx/O-2018.09-SP2
export VERDI_HOME ?= /mnt/data1/synopsys/verdi/Verdi_O-2018.09-SP2

# 本 Makefile 位于 sim/ 下，make 也在 sim/ 目录运行
UVM_BASE ?= ../lib/uvm_base
TEST ?= @P@_test
UVM_VER ?= uvm-1.2
SEED ?= 1
VERB ?= UVM_MEDIUM
WAVE ?= fsdb
DUMP ?= 1
COV  ?= 0

# 由 create_project.sh 按所选仓库生成（各仓库的 <name>.mk 片段）
-include mk_config.mk

DEFS = @DEFS@
PLUS = @PLUS@

RUN = FILELIST=./filelist.f TOP=@P@_top TEST=$(TEST) UVM_VER=$(UVM_VER) \
      SEED=$(SEED) VERB=$(VERB) WAVE=$(WAVE) DUMP=$(DUMP) COV=$(COV) OUT=simv \
      VCS_CC="$(VCS_CC)" VCS_CXX="$(VCS_CXX)" \
      DEFS="$(DEFS)" PLUS="$(PLUS)" bash $(UVM_BASE)/scripts/run_vcs.sh

.PHONY : all comp run check verdi clean help

all : check

check : comp run

comp :
	@mkdir -p logs waves
	@COMP_ONLY=1 $(RUN)

run :
	@mkdir -p logs waves
	@RUN_ONLY=1 $(RUN)

verdi :
	@FILELIST=./filelist.f TOP=@P@_top WAVE=waves/@P@_top.fsdb DEFS="$(DEFS)" bash ../lib/uvm_base/scripts/run_verdi.sh

clean :
	@bash $(UVM_BASE)/scripts/clean.sh

help :
	@echo "make check  [TEST=@P@_test]"
