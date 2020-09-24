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

#
# for upload-pkg
#
organization ?= esgf-forge
label ?= main

PWD=$(shell pwd)

setup-build: # make setup-build workdir=$WORKDIR
	$(conda) create -y -n $(build_env) -c conda-forge conda-build conda-smithy anaconda-client

create-feedstock: # make create-feedstock workdir=$WORKDIR version=0.1 build_number=0 branch=make_conda_pkg
	mkdir -p $(workdir)/autocurator-feedstock;
	$(conda_act_cmd) $(build_env) && \
	cd $(workdir)/autocurator-feedstock && $(conda) smithy ci-skeleton $(workdir)/autocurator-feedstock;
	mkdir -p $(workdir)/autocurator-feedstock/recipe 
	cp $(PWD)/recipe/meta.yaml $(workdir)/autocurator-feedstock/recipe/meta.yaml
	cp $(PWD)/recipe/build.sh $(workdir)/autocurator-feedstock/recipe/build.sh
	sed -i "s/VERSION/$(version)/" $(workdir)/autocurator-feedstock/recipe/meta.yaml
	sed -i "s/BRANCH/$(branch)/" $(workdir)/autocurator-feedstock/recipe/meta.yaml
	sed -i "s/BUILD_NUMBER/$(build_number)/" $(workdir)/autocurator-feedstock/recipe/meta.yaml

rerender-feedstock: # make rerender-feedstock workdir=$WORKDIR
	cd $(workdir)/autocurator-feedstock && \
	$(conda_act_cmd) $(build_env) && \
	$(conda) smithy rerender;

build-conda-pkg: # make build-conda-pkg workdir=$WORKDIR python=3.8
	cd $(workdir)/autocurator-feedstock && \
	$(conda_act_cmd) $(build_env) && \
	$(conda) build -c conda-forge -m .ci_support/linux_64_python$(python).____cpython.yaml recipe/

upload-pkg: # make upload-pkg workdir=$WORKDIR python=3.8
	cd $(workdir)/autocurator-feedstock && \
	$(conda_act_cmd) $(build_env) && \
	output_file=$$(conda build --output -c conda-forge -m .ci_support/linux_64_python$(python).____cpython.yaml recipe/) && \
	anaconda -t $(CONDA_UPLOAD_TOKEN) upload -u $(organization) -l $(label) $$output_file

clean-build-env: # make clean-build-env workdir=$WORKDIR
	$(conda) env remove -n $(build_env) && \
	rm -rf $(workdir)/autocurator-feedstock

# DO NOT DELETE
