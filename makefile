# Do not remove ##? comments. They are used by 'help' to construct the help docs.
##? antidote - the cure to slow zsh plugin management
##?
##? Usage:  make <command>"
##?
##? Commands:

.DEFAULT_GOAL := help
all : build buildman test unittest bump-maj bump-min bump-rev help
.PHONY : all

##? help        display this makefile's help information
help:
	@grep "^##?" makefile | cut -c 5-

##? build       run build tasks like generating man pages
build:
	./tools/buildman
	./tools/run-clitests
	./tools/bumpver revision

##? buildman    rebuild man pages
buildman:
	./tools/buildman

##? test        run tests
test:
	./tools/run-clitests

##? unittest    run only unittests
unittest:
	./tools/run-clitests --unit

##? bump-maj    bump the major version (X.0.0)
bump-maj:
	./tools/bumpver major

##? bump-min    bump the minor version (0.X.0)
bump-min:
	./tools/bumpver minor

##? bump-rev    bump the revision version (0.0.X)
bump-rev:
	./tools/bumpver revision

##? bumpber     bump the revision version (0.0.X)
bumpver:
	./tools/bumpver revision
