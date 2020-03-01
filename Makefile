# -*- mode: makefile; -*-

TARGET = gof
VALGRIND_DIR := build/codetest
DOXYGEN_DIR := doc
COVERAGE_DIR := build
BUILD_DIR := build
INSTALL_DIR := $(HOME)/local
ARG =  -Db_coverage=true $(ASAN) -Dprefix=$(INSTALL_DIR)
LINTER = cclint
# ASAN =-Db_sanitize=address
# CXX = clang++
# CC = g++
OPEN = $(shell which xdg-open || which gnome-open || which open)
PYTHON = /usr/bin/env python3
PIP = /usr/bin/env pip3
R = /usr/bin/env R --no-save --no-restore
GIT = /usr/bin/env git
CMAKE = /usr/bin/env cmake
GETVER = config/getrversion.py
R_DEP = 1
TEST = test
BUILD=debug
#BUILD=release

default: build runr

all: clean run

##################################################

.PHONY: clean
clean: cleanr cleanpy
	@rm -Rf $(BUILD_DIR) $(VALGRIND_DIR) $(DOXYGEN_DIR)/html $(COVERAGE_DIR)

.PHONY: init init-submodules
init: clean
	@$(CMAKE) -G Ninja -B build

init-submodules:
	@if [ -z "`find \"lib/armadillo\" -mindepth 1 -exec echo notempty \; -quit`" ]; then \
	git submodule init && git submodule update; fi

.PHONY: run
run: init-submodules
	@if [ ! -d "$(BUILD_DIR)" ]; then $(MAKE) --no-print-directory init; fi
	@$(MAKE) --no-print-directory build # > /dev/null
	@printf "\n-----\n"
	@find build/ -maxdepth 1 -iname "*demo" -executable -type f -exec {} \; 

.PHONY: build
build:
	@ninja -C $(BUILD_DIR) -v

.PHONY: install
install:
	ninja -C $(BUILD_DIR) install

.PHONY: uninstall
uninstall:
	ninja -C $(BUILD_DIR) uninstall

##################################################
## R package
##################################################

.PHONY: r cleanr buildr runr testr roxygen

buildr: cleanr
	@$(R) --slave -e "source('config/utilities.R'); \
	load_packages(c('Rcpp', 'RcppArmadillo', 'lava', 'optimx', 'futile.logger'))"
	@$(R) --slave -e "Rcpp::compileAttributes('R-package')"
	@$(R) CMD INSTALL R-package

testr:
	@$(R) -e 'testthat::test_package("R-package")'

runr:
	@cd misc; $(R) --silent -f $(TEST).R

roxygen:
	@$(R) -e 'roxygen2::roxygenize("R-package")'

exportr:
	@rm -Rf $(BUILD_DIR)/R/$(TARGET)
	@mkdir -p $(BUILD_DIR)/R/$(TARGET)
	cd R-package; $(GIT) archive HEAD | (cd ../$(BUILD_DIR)/R/$(TARGET); tar x)
	cp src/*.cpp $(BUILD_DIR)/R/$(TARGET)/src
	cp src/*.hpp $(BUILD_DIR)/R/$(TARGET)/inst/include
	sed -i '/^OBJECTS\|SOURCES/d' $(BUILD_DIR)/R/$(TARGET)/src/Makevars
	cd $(BUILD_DIR)/R; $(R) CMD build $(TARGET) --compact-vignettes=gs+qpdf --resave-data=best

checkr: exportr
	cd $(BUILD_DIR)/R; $(R) CMD check `../../$(GETVER) $(TARGET)` --timings --as-cran --no-multiarch --run-donttest

r: buildr runr

cleanr:
	@rm -Rf R-package/src/*.o R-package/src/*.so

##################################################
## Python package
##################################################

.PHONY: py cleanpy buildpy runpy testpy

buildpy:
	@cd python-package; $(PYTHON) setup.py install

testpy:
	@cd python-package; $(MAKE) test

runpy:
	@$(PYTHON) misc/$(TEST).py

py: buildpy runpy

cleanpy:
	@cd python-package; $(MAKE) --no-print-directory clean

##################################################
## Documentation
##################################################

.PHONY: docs doc
docs:
	@cd $(DOXYGEN_DIR); doxygen

doc:	docs
	@$(OPEN) $(DOXYGEN_DIR)/html/index.html

##################################################
## Unit tests
##################################################

.PHONY: t test testall
t:	run
	@ninja -C $(BUILD_DIR) test

test:	build
	build/$(TARGET)_test -s

testall: test r py testr testpy

##################################################
## Code coverage
##################################################
.PHONY: coverage
coverage:
	rm -Rf build/coverage
	mkdir -p build/coverage
	cd build/coverage; cmake -DCMAKE_BUILD_TYPE=Debug -DCOVERAGE_BUILD=1 ../../ && make coverage
	$(OPEN) build/coverage/coverage/index.html

##################################################
## Debugging, profiling, and memory inspection
##################################################

.PHONY: check
check:
	-cclint src/*.cpp src/*.h
	-cppcheck --enable=all src/

.PHONY: valgrind
## Alternatively, enable Address Sanitizer (ASAN argument)
valgrind:
	@ninja -C build test_memcheck

##################################################
## Docker
##################################################

.PHONY: dockerbuild docker export
dockerbuild:
	@docker build . -t $(TARGET)_test

export:
	@rm -Rf ${PWD}/tmp/$(TARGET)
	@mkdir -p ${PWD}/tmp/$(TARGET)
	@git archive HEAD | (cd ${PWD}/tmp/$(TARGET); tar x)
	@git submodule foreach 'curdir=${PWD} cd ${PWD}/$$path; git archive HEAD | tar -x -C ${PWD}/tmp/$(TARGET)/$$path'
	@echo "Exported to '${PWD}/tmp/$(TARGET)'"

dockerrun: 
	docker run -ti --rm --privileged -v ${PWD}/tmp/$(TARGET):/data $(TARGET)_test ${CMD}

docker: dockerbuild export dockerrun

