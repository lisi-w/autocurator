# Copyright (c) 2016      Bryce Adelstein-Lelbach aka wash
# Copyright (c) 2000-2016 Paul Ullrich 
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying 
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

BUILD_TARGETS= src
CLEAN_TARGETS= $(addsuffix .clean,$(BUILD_TARGETS))

.PHONY: all clean $(BUILD_TARGETS) $(CLEAN_TARGETS) setup-build create-feedstock rerender-feedstock build-conda-pkg upload

# Build rules.
all: $(BUILD_TARGETS)

$(BUILD_TARGETS): %:
	cd $*; $(MAKE)

# Clean rules.
clean: $(CLEAN_TARGETS)
	rm -f bin/*

$(CLEAN_TARGETS): %.clean:
	cd $*; $(MAKE) clean

#
# prerequesites for running make to build conda package, has a base conda env activated.
#
# parameters that have to be specified when building conda-package
#    workdir
#    version
#    build_number

branch ?= master

conda ?= $(or $(CONDA_EXE),$(shell find /opt/*conda*/bin $(HOME)/*conda*/bin -type f -iname conda))
conda_bin := $(patsubst %/conda,%,$(conda))
conda_act := $(conda_bin)/activate
conda_act_cmd := source $(conda_act)

build_env ?= build_autocurator

PWD=$(shell pwd)

setup-build:
	$(conda) create -y -n $(build_env) -c conda-forge conda-build conda-smithy anaconda-client

create-feedstock:
	mkdir -p $(workdir)/autocurator-feedstock;
	$(conda_act_cmd) $(build_env) && \
	cd $(workdir)/autocurator-feedstock && $(conda) smithy ci-skeleton $(workdir)/autocurator-feedstock;
	mkdir -p $(workdir)/autocurator-feedstock/recipe 
	cp $(PWD)/recipe/meta.yaml $(workdir)/autocurator-feedstock/recipe/meta.yaml
	cp $(PWD)/recipe/build.sh $(workdir)/autocurator-feedstock/recipe/build.sh
	sed -i "s/VERSION/$(version)/" $(workdir)/autocurator-feedstock/recipe/meta.yaml
	# sed -i "s/BRANCH/$(branch)/" $(workdir)/autocurator-feedstock/recipe/meta.yaml
	sed -i "s/BUILD_NUMBER/$(build_number)/" $(workdir)/autocurator-feedstock/recipe/meta.yaml

rerender-feedstock:
	cd $(workdir)/autocurator-feedstock && \
	$(conda_act_cmd) $(build_env) && \
	$(conda) smithy rerender;

build-conda-pkg:
	cd $(workdir)/autocurator-feedstock && \
	$(conda_act_cmd) $(build_env) && \
	$(conda) build -c conda-forge -m .ci_support/linux_64_python3.7.____cpython.yaml recipe/

clean-build-env:
	$(conda) env remove -n $(build_env) && \
	rm -rf $(workdir)/autocurator-feedstock

# DO NOT DELETE
