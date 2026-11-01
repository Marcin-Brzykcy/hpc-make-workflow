# Local orchestration for projects built and run on a Slurm cluster.
.DEFAULT_GOAL := help
-include .env

REMOTE_DIR ?= hpc-make-workflow
SRC_DIR ?= examples/hello
PARTITION ?= $(CLUSTER)
COMPILER ?= gcc
COMPILER_FLAGS ?=
LINKER_FLAGS ?=
BUILD_ARGS ?=
BUILD_TIME ?= 00:05:00
SRUN_CMD ?= srun
MODULES ?=
SLURM_SCRIPT ?= slurm.sl
PULL_FROM ?= $(SRC_DIR)/output.txt
PULL_TO ?= downloads
PERSIST ?= 2h

SSH_CFG := $(CURDIR)/.hpc/ssh_config
SSH = ssh -F $(SSH_CFG)
ACCOUNT_ARG = $(if $(strip $(HPC_ACCOUNT)),--account=$(HPC_ACCOUNT),)
PARTITION_ARG = $(if $(strip $(PARTITION)),--partition=$(PARTITION),)
MODULE_LOAD = $(if $(strip $(MODULES)),module load $(MODULES) && ,)
empty :=
space := $(empty) $(empty)
escape_spaces = $(subst $(space),\ ,$(strip $(1)))
CFLAGS_ARG = $(if $(strip $(COMPILER_FLAGS)),CFLAGS=$(call escape_spaces,$(COMPILER_FLAGS)),)
LDFLAGS_ARG = $(if $(strip $(LINKER_FLAGS)),LDFLAGS=$(call escape_spaces,$(LINKER_FLAGS)),)
TARGET_ARG = $(if $(strip $(TARGET)),TARGET=$(TARGET),)

.PHONY: help check cfg login logout status sync build run all ls exec pull queue cancel shell clean-remote
help:
	@echo 'Targets: login, sync, build, run, all, pull, queue, cancel, shell, status, logout, ls, exec, clean-remote'
	@echo 'Copy .env.example to .env and configure your cluster; see README.md.'

check:
	@test -n "$(HPC_USER)" || { echo 'Set HPC_USER in .env'; exit 1; }
	@test -n "$(HPC_CENTRAL)" || { echo 'Set HPC_CENTRAL in .env'; exit 1; }
	@test -n "$(CLUSTER)" || { echo 'Set CLUSTER in .env'; exit 1; }

cfg: check
	@mkdir -p "$(CURDIR)/.hpc" "$(HOME)/.ssh"
	@{ \
	  echo 'Host hpc-central'; \
	  echo '  HostName $(HPC_CENTRAL)'; \
	  echo '  User $(HPC_USER)'; \
	  echo '  ControlMaster auto'; \
	  echo '  ControlPath ~/.ssh/cm-%C'; \
	  echo '  ControlPersist $(PERSIST)'; \
	  echo 'Host hpc-cluster'; \
	  echo '  HostName $(CLUSTER)'; \
	  echo '  User $(HPC_USER)'; \
	  echo '  ProxyCommand ssh -F $(SSH_CFG) -W %h:%p hpc-central'; \
	  echo '  ControlMaster auto'; \
	  echo '  ControlPath ~/.ssh/cm-%C'; \
	  echo '  ControlPersist $(PERSIST)'; \
	} > "$(SSH_CFG)"

login: cfg
	$(SSH) hpc-central true
	$(SSH) hpc-cluster true
logout: cfg
	-$(SSH) -O exit hpc-cluster
	-$(SSH) -O exit hpc-central
status: cfg
	-$(SSH) -O check hpc-central
	-$(SSH) -O check hpc-cluster
sync: cfg
	$(SSH) hpc-cluster "mkdir -p $(REMOTE_DIR)/$(SRC_DIR)"
	rsync -avz --exclude 'output.txt' -e "$(SSH)" "$(SRC_DIR)/" "hpc-cluster:$(REMOTE_DIR)/$(SRC_DIR)/"
build: cfg
	$(SSH) hpc-cluster "cd $(REMOTE_DIR)/$(SRC_DIR) && $(SRUN_CMD) $(PARTITION_ARG) $(ACCOUNT_ARG) --nodes=1 --ntasks=1 --time=$(BUILD_TIME) bash -lc '$(MODULE_LOAD)make CC=$(COMPILER) $(CFLAGS_ARG) $(LDFLAGS_ARG) $(TARGET_ARG) $(BUILD_ARGS)'"
run: cfg
	$(SSH) hpc-cluster "cd $(REMOTE_DIR)/$(SRC_DIR) && bash -lc '$(MODULE_LOAD)sbatch --wait $(PARTITION_ARG) $(ACCOUNT_ARG) $(SLURM_SCRIPT)'"
# Recursive calls guarantee ordering, including when invoked with make -j.
all:
	+$(MAKE) sync
	+$(MAKE) build
	+$(MAKE) run
ls: cfg
	$(SSH) hpc-cluster "ls -lht $(REMOTE_DIR)"
exec: cfg
	@test -n "$(CMD)" || { echo 'Usage: make exec CMD="command"'; exit 1; }
	$(SSH) hpc-cluster "cd $(REMOTE_DIR) && $(CMD)"
pull: cfg
	@mkdir -p "$(PULL_TO)"
	rsync -avz -e "$(SSH)" "hpc-cluster:$(REMOTE_DIR)/$(PULL_FROM)" "$(PULL_TO)/"
queue: cfg
	$(SSH) hpc-cluster "squeue -u $(HPC_USER)"
cancel: cfg
	@test -n "$(JOB_ID)" || { echo 'Set JOB_ID to the job to cancel'; exit 1; }
	$(SSH) hpc-cluster "scancel $(JOB_ID)"
shell: cfg
	$(SSH) -t hpc-cluster
clean-remote: cfg
	$(SSH) hpc-cluster "cd $(REMOTE_DIR)/$(SRC_DIR) && make clean"
