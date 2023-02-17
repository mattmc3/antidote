# Do not remove ##? comments. They are used by 'help' to construct the help docs.
##? antidote - the cure to slow zsh plugin management
##?
##? Usage:  make <command>"
##?
##? Commands:

.DEFAULT_GOAL := help
all : build buildman test bump-maj bump-min bump-rev help
.PHONY : all

##? help        display this makefile's help information
help:
	@grep "^##?" makefile | cut -c 5-

##? build       run build tasks like generating man pages
build:
	./tools/buildman
	./tools/runtests
	./tools/bumpver revision

##? buildman    rebuild man pages
buildman:
	./tools/buildman

##? test        run tests
test:
	./tools/run-clitests

##? bump-maj    bump the major version (X.0.0)
bump-maj:
	./tools/bumpver major

##? bump-man    bump the minor version (0.X.0)
bump-min:
	./tools/bumpver minor

##? bump-rev    bump the revision version (0.0.X)
bump-rev:
	./tools/bumpver revision
